import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'constants.dart';
import 'helpers.dart';
import 'home.dart';
import 'icons.dart';
import 'osmshorturl.dart';

class PostStatusPage extends StatefulWidget {
  const PostStatusPage({super.key, required this.title, required this.poi});

  final String title;
  final dynamic poi;

  @override
  State<PostStatusPage> createState() => _PostStatusPageState();
}

class _PostStatusPageState extends State<PostStatusPage> {
  final logger = Logger();
  dynamic get poi => widget.poi;

  final _postTextController = TextEditingController();
  final _imageAltTextController = TextEditingController();

  bool _isBlurred = false;

  dynamic _pickedImage;

  @override
  void dispose() {
    _postTextController.dispose();
    _imageAltTextController.dispose();
    super.dispose();
  }

  void _toggleBlur() {
    if (mounted) {
      setState(() {
        _isBlurred = !_isBlurred;
      });
    }
  }

  void _showError() {
    showPopup(context, mounted, ['SID_POSTSTATUS_ERROR'.tr], ['😿']);
  }

  Future<void> _postCheckin() async {
    if (_isBlurred == false) {
      _toggleBlur();
      try {
        SharedPreferences persistency = await SharedPreferences.getInstance();

        final instanceUrl = persistency.getString('instance_url');
        final accessToken = persistency.getString('access_token');

        String checkinStatus = '';
        final checkinHeader = '🌐 ${'SID_POSTSTATUS_HEADER'.tr}';
        checkinStatus +=
            '$checkinHeader\n\n${poiEmoji(poi['category'])} ${poi['name']}\n\n';
        final checkinText = _postTextController.text;
        if (checkinText != '') {
          checkinStatus += '$checkinText\n\n'; //'🗨️ $checkinText\n\n';
        }
        checkinStatus +=
            '🗺️ https://osm.org/go/${makeSafeShortCode(poi['lat'], poi['lon'], 19)}?m=';

        logger.d(checkinStatus);

        // Post status

        String statusVisibility =
            'unlisted'; //'unlisted' by default, 'direct' for testing

        // Change visibility in debug mode
        if (!kReleaseMode) {
          statusVisibility = 'direct';
        }

        final newStatus = {
          'status': checkinStatus,
          'media_ids': [],
          'visibility': statusVisibility,
        };

        String? language = Get.deviceLocale?.languageCode;
        if (language != null) {
          newStatus['language'] = language;
        }

        // Upload image first if one is set
        if (_pickedImage != null) {
          final imagePostRequest = http.MultipartRequest(
            'POST',
            Uri.parse('https://$instanceUrl/api/v2/media'),
          );
          imagePostRequest.headers.addAll({
            'Authorization': 'Bearer $accessToken',
            'User-Agent': locidokoUserAgent,
          });
          imagePostRequest.files.add(
            await http.MultipartFile.fromPath('file', _pickedImage.path),
          );
          if (_imageAltTextController.text != '') {
            imagePostRequest.fields['description'] =
                _imageAltTextController.text;
          }
          final imagePostResult = await imagePostRequest.send().timeout(
            const Duration(seconds: 120),
            onTimeout: () async {
              throw Exception('Timed out after 120 seconds');
            },
          );

          if (imagePostResult.statusCode == 200 ||
              imagePostResult.statusCode == 202) {
            String imageResult = await imagePostResult.stream.bytesToString();
            dynamic jsonData = jsonDecode(imageResult);

            newStatus['media_ids'] = [jsonData['id']];
          }
        }

        final postResult = await http.post(
          Uri.parse('https://$instanceUrl/api/v1/statuses'),
          body: jsonEncode(newStatus),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Idempotency-Key': const Uuid().v4(),
            'Content-Type': 'application/json',
            'User-Agent': locidokoUserAgent,
          },
        ).timeout(
          const Duration(seconds: 45),
          onTimeout: () async {
            throw Exception('Timed out after 45 seconds');
          },
        );
        if (postResult.statusCode == 200) {
          logger.i('Success!');
          logger.d(jsonDecode(postResult.body));
          final jsonResult = jsonDecode(postResult.body);
          // Wait aditionally, otherwise the home page loads too fast and doesn't show the checkin
          await Future.delayed(
            const Duration(
              seconds: 5,
            ),
          );
          _toggleBlur();
          _jumpBack(
            jsonResult['id'],
          ); // Handover the id of the new checkin to the homepage
        } else {
          throw Exception('postResult.statusCode: ${postResult.statusCode}');
        }
      } catch (e) {
        logger.e(e);
        _toggleBlur();
        if (mounted) {
          /*ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
              duration: Duration(seconds: 10),
            ),
          );*/
          _showError();
        }
      }
    }
  }

  void _jumpBack(dynamic postId) {
    if (mounted) {
      Navigator.of(context)
        ..pop()
        ..pop();
      /* Trigger reload */
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            title: 'SID_HOME_TITLE',
            fromCheckin: true,
            lastPostId: postId,
          ),
        ),
      );
    }
  }

  int _getMaxInputLength(poi, maxChars) {
    final int lenghtHeaderText = 'SID_POSTSTATUS_HEADER'.tr.length;
    final String poiName = poi['name'];
    final int poiNameLength = poiName.length;
    final String poiUrl =
        'https://osm.org/go/${makeSafeShortCode(poi['lat'], poi['lon'], 19)}?m=';
    logger.d(poiUrl);
    final int poiUrlLength = poiUrl.length;

    final int maxCharsFinal =
        maxChars - lenghtHeaderText - poiNameLength - poiUrlLength - 10;
    return (maxCharsFinal ~/ 10) * 10;
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        logger.d(pickedImage.path);
        _pickedImage = pickedImage;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        String avatarUrl = '';
        int maxInstanceChars = 500;
        int maxChars = 500;
        if (snapshot.data != null &&
            snapshot.data!.containsKey('account_avatar')) {
          avatarUrl = snapshot.data!.getString('account_avatar') ?? '';
        }
        if (snapshot.data != null &&
            snapshot.data!.containsKey('instance_max_characters')) {
          maxInstanceChars =
              snapshot.data!.getInt('instance_max_characters') ?? 500;
        }
        maxChars = _getMaxInputLength(poi, maxInstanceChars);

        logger.d('Running as release: $kReleaseMode');

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.close,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
            ),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(
              poi['name'] ?? widget.title.tr,
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Padding(
                // To avoid covering navigation bar
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context)
                      .viewPadding
                      .bottom, // Adjust bottom padding
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 20.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          avatarUrl.contains('http')
                              ? CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                    avatarUrl,
                                    headers: {
                                      'User-Agent': locidokoUserAgent,
                                    },
                                  ),
                                )
                              : Icon(
                                  size: 30,
                                  Icons.person_outline_rounded,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          SizedBox(
                            height: 60,
                            width: 60,
                            child: SvgPicture.string(
                              poiSvg(poi['category']),
                            ),
                            //),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Scrollbar(
                          child: TextField(
                            maxLength: maxChars,
                            controller: _postTextController,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none, //OutlineInputBorder(),
                              labelText: 'SID_POSTSTATUS_TEXT'.tr,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _pickedImage != null
                        ? Container(
                            padding: const EdgeInsets.all(2.0),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                    child: Image.file(
                                      File(_pickedImage.path),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Scrollbar(
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 300),
                                      width: MediaQuery.of(context).size.width,
                                      child: TextField(
                                        maxLength: maxInstanceChars,
                                        controller: _imageAltTextController,
                                        maxLines: 1,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          labelText:
                                              'SID_POSTSTATUS_IMAGEALTTEXT'.tr,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(),
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            // Set larger size of touch area for photo pick icon
                            width: 80,
                            height: 40,
                            child: InkWell(
                              child: Container(
                                alignment: Alignment.centerLeft,
                                child: _pickedImage == null
                                    ? Icon(
                                        Icons.add_a_photo_outlined,
                                        size: (DefaultTextStyle.of(context)
                                                    .style
                                                    .fontSize ??
                                                16.0) *
                                            0.7,
                                      )
                                    : Icon(
                                        Icons.no_photography_outlined,
                                        size: (DefaultTextStyle.of(context)
                                                    .style
                                                    .fontSize ??
                                                16.0) *
                                            0.7,
                                      ),
                              ),
                              onTap: () {
                                if (_pickedImage == null) {
                                  _pickImage();
                                } else {
                                  _removeImage();
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: Container(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Icon(
                                kReleaseMode
                                    ? Icons.lock_open_outlined
                                    : Icons.lock_outline_rounded,
                                size: (DefaultTextStyle.of(context)
                                            .style
                                            .fontSize ??
                                        16.0) *
                                    0.7,
                              ),
                              Text(
                                kReleaseMode
                                    ? 'SID_POSTSTATUS_VISIBILITY'.tr
                                    : 'DEBUG',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ButtonStyle(
                                side: WidgetStateProperty.all(
                                  BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                'SID_POSTSTATUS_BUTTON_CANCEL'.tr.toUpperCase(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                _postCheckin();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                              child: Text(
                                'SID_POSTSTATUS_BUTTON_CHECKIN'
                                    .tr
                                    .toUpperCase(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isBlurred)
                Container(
                  color: Colors.black.withAlpha(128),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
