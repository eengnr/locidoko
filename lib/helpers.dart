import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cache.dart';
import 'constants.dart';
import 'icons.dart';

String _buildAddress(poiData) {
  String address = '';
  String city = '';
  String place = '';
  if (poiData['addr:city'] != null) {
    city = poiData['addr:city'];
  }
  if (poiData['addr:postcode'] != null && city != '') {
    city = '${poiData['addr:postcode']} $city';
  }
  if (poiData['addr:place'] != null) {
    place = poiData['addr:place'];
    if (city == '') {
      city = place;
    } else {
      city = '$city\n$place';
    }
  }
  String street = '';
  if (poiData['addr:street'] != null) {
    street = poiData['addr:street'];
  }
  if (poiData['addr:housenumber'] != null && street != '') {
    street = '$street ${poiData['addr:housenumber']}';
  }
  if (city != '' && street != '') {
    address = '$street\n$city';
  } else if (city != '' && street == '') {
    address = city;
  } else if (city == '' && street != '') {
    address = street;
  }
  return address;
}

String formatDay(DateTime timestamp) {
  String locale = Get.deviceLocale.toString();
  String formattedDate = DateFormat.yMMMMd(locale).format(timestamp);
  return formattedDate;
}

String formatTime(DateTime timestamp) {
  String locale = Get.deviceLocale.toString();
  String formattedDate = DateFormat.yMMMMd(locale).format(timestamp);
  String formattedTime = DateFormat.Hm().format(timestamp);
  return '$formattedDate, $formattedTime';
}

// Show a popup on the current state with a big emoji and a text
void showPopup(
  BuildContext context,
  bool mounted,
  List<String> textList,
  List<String> emojiList,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (
      BuildContext buildContext,
      Animation animation,
      Animation secondaryAnimation,
    ) {
      return Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(),
          child: Center(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dismissible(
                key: const Key('Success'),
                direction: DismissDirection.vertical,
                onDismissed: (direction) {
                  if (mounted) {
                    Navigator.pop(buildContext);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    8,
                    20,
                    8,
                    8,
                  ), //EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  width: MediaQuery.of(context).size.width - 30,
                  //height: MediaQuery.of(context).size.height - 300,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - 300,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: SvgPicture.string(
                            emojiSvg(
                              emojiList[Random().nextInt(emojiList.length)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          textList[Random().nextInt(textList.length)],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              Navigator.pop(buildContext);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.surface,
                          ),
                          child: Text(
                            'SID_HOME_POSTPOPUP_CLOSE'.tr,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showPostPopup(context, mounted, post) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (
      BuildContext buildContext,
      Animation animation,
      Animation secondaryAnimation,
    ) {
      return Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(),
          child: Center(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dismissible(
                key: const Key('Status'),
                direction: DismissDirection.vertical,
                onDismissed: (direction) {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  width: MediaQuery.of(context).size.width - 30,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - 200,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          width: MediaQuery.of(context).size.width - 30,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                          child: Text(
                            formatTime(DateTime.parse(post['created_at'])),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: (DefaultTextStyle.of(context)
                                          .style
                                          .fontSize ??
                                      16.0) *
                                  0.3,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                          child: Scrollbar(
                            child: Html(
                              data: post['content'],
                              style: {
                                "body": Style(
                                  fontSize: FontSize(
                                    ((DefaultTextStyle.of(context)
                                                .style
                                                .fontSize ??
                                            16.0) *
                                        0.4),
                                  ),
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                ),
                                "a": Style(
                                  textDecoration: TextDecoration.none,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              },
                              onLinkTap: (url, attributes, element) async {
                                if (url != null) {
                                  final urlUri = Uri.parse(url);
                                  if (await canLaunchUrl(urlUri)) {
                                    await launchUrl(urlUri);
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        post.containsKey('media_attachments') &&
                                post['media_attachments'].length > 0 &&
                                post['media_attachments'][0]
                                    .containsKey('type') &&
                                post['media_attachments'][0]['type'] ==
                                    'image' &&
                                post['media_attachments'][0].containsKey('url')
                            ? Container(
                                padding:
                                    const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                                constraints: const BoxConstraints(
                                  maxWidth: 500,
                                  maxHeight: 500 * 9 / 16,
                                ),
                                width: MediaQuery.of(buildContext).size.width,
                                height: MediaQuery.of(buildContext).size.width *
                                    9 /
                                    16,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          post['media_attachments'][0]['url'],
                                          headers: {
                                            'User-Agent': locidokoUserAgent,
                                          },
                                          cacheManager: getCacheManager(),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.surface,
                            ),
                            child: Text(
                              'SID_HOME_POSTPOPUP_CLOSE'.tr,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showPoiDetailsPopup(context, mounted, poiData) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (
      BuildContext buildContext,
      Animation animation,
      Animation secondaryAnimation,
    ) {
      return Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(),
          child: Center(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dismissible(
                key: const Key('Status'),
                direction: DismissDirection.vertical,
                onDismissed: (direction) {
                  if (mounted) {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  width: MediaQuery.of(context).size.width - 30,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - 300,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          width: MediaQuery.of(context).size.width - 30,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                          child: Text(
                            poiData['name'],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            8.0,
                            16.0,
                            8.0,
                            16.0,
                          ),
                          child: (poiData['description'] != null ||
                                  _buildAddress(poiData) != '' ||
                                  poiData['website'] != null)
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (poiData['description'] != null) ...[
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            Icons.info_outline_rounded,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              poiData['description'],
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    if (_buildAddress(poiData) != '') ...[
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            Icons.pin_drop_rounded,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _buildAddress(poiData),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    if (poiData['website'] != null) ...[
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            Icons.link_rounded,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              poiData['website'],
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            onPressed: () async {
                                              final url = Uri.parse(
                                                poiData['website'],
                                              );
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(
                                                  url,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.open_in_browser_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ],
                                )
                              : Text(
                                  'SID_LOCATIONS_DETAILPOPUP_NODETAILS'.tr,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                        ),
                        poiData['id'] != null && poiData['type'] != null
                            ? Container(
                                padding: const EdgeInsets.fromLTRB(
                                  8.0,
                                  0.0,
                                  8.0,
                                  16.0,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final url = Uri.parse(
                                      'https://openstreetmap.org/${poiData['type']}/${poiData['id']}',
                                    );
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.open_in_browser_rounded,
                                  ),
                                  label: Text(
                                    'SID_LOCATIONS_DETAILPOPUP_OPENOSM'.tr,
                                  ),
                                  style: ButtonStyle(
                                    side: WidgetStateProperty.all(
                                      BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        Container(
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              if (mounted) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.surface,
                            ),
                            child: Text('SID_LOCATIONS_DETAILPOPUP_CLOSE'.tr),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
