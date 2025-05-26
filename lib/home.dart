import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart';
import 'cache.dart';
import 'constants.dart';
import 'helpers.dart';
import 'icons.dart';
import 'locations.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.title,
    this.fromCheckin = false,
    this.lastPostId,
  });

  final String title;
  final bool fromCheckin;
  final dynamic lastPostId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final logger = Logger();

  bool get fromCheckin => widget.fromCheckin;
  dynamic get lastPostId => widget.lastPostId;

  List<dynamic> statuses = [];
  bool loading = true;

  String _error = '';

  int loadCounter = 0;
  final maxTries = 2;

  void _showSuccess() {
    showPopup(
      context,
      mounted,
      [
        'SID_HOME_CHECKEDINPOPUP_SUCCESS_1'.tr,
        'SID_HOME_CHECKEDINPOPUP_SUCCESS_2'.tr,
        'SID_HOME_CHECKEDINPOPUP_SUCCESS_3'.tr,
        'SID_HOME_CHECKEDINPOPUP_SUCCESS_4'.tr,
      ],
      [
        '🎉',
        '🥳',
        '🎊',
        '🪅',
      ],
    );
  }

  Future<void> _loadPosts([lastPostId]) async {
    logger.i('Load statuses now');

    setState(() {
      loading = true;
      _error = '';
    });
    SharedPreferences persistency = await SharedPreferences.getInstance();

    final instanceUrl = persistency.getString('instance_url');
    final accessToken = persistency.getString('access_token');
    final accountId = persistency.getString('account_id');
    final instanceVersion = persistency.getString('instance_sw_version') ?? '';

    if (instanceUrl == null || accessToken == null || accountId == null) {
      logger.w('No instance url, access token or account id');
      logger.w('Clear persistency and start over');
      bool clear = await persistency.clear();
      if (clear) {
        _jumpToAuth();
      }
      return;
    }

    try {
      logger.d('Loading');

      logger.d('accessToken $accessToken');
      logger.d('accountId $accountId');
      logger.d('instanceVersion $instanceVersion');

      bool isSearch = true;

      // Load status via search by default, because it returns more results
      String requestUrl =
          'https://$instanceUrl/api/v2/search?q=🌐&account_id=$accountId&type=statuses';
      // Load status list from account instead of search if search does not return results
      // or if in debug mode. Additionally Friendica does not check account_id in request.
      // That's why we need to load the last status instead of searching for checkin status.
      // Was fixed with 2024.03, see https://github.com/friendica/friendica/issues/13897
      // But in 2024.03, no results are returned at all.
      if (instanceVersion.contains('Friendica') || loadCounter >= maxTries) {
        requestUrl = 'https://$instanceUrl/api/v1/accounts/$accountId/statuses';
        isSearch = false;
      }
      logger.d('isSearch $isSearch');
      logger.d('requestUrl $requestUrl');

      final loadedStatuses = await http.get(
        Uri.parse(requestUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': locidokoUserAgent,
        },
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () async {
          throw Exception('Timed out after 45 seconds');
        },
      );
      logger.d(loadedStatuses);
      logger.d('Check statusCode');

      if (loadedStatuses.statusCode == 200) {
        logger.d(loadedStatuses.body);
        /* Convert UTF8 */
        dynamic resultJson = jsonDecode(loadedStatuses.body);
        try {
          // Decode, necessary for Friendica
          dynamic jsonBytes = loadedStatuses.body.codeUnits;
          String decodedJsonString =
              utf8.decode(jsonBytes, allowMalformed: false);
          resultJson = jsonDecode(decodedJsonString);
        } catch (e) {
          // Decoding failed, use direct response, ok for Mastodon
          logger.i(e);
          logger.d('Use direct response instead');
        }
        logger.i('Done');
        logger.d(loadedStatuses.body);
        // Use temporary list if coming from checkin to check if latest checkin is already available
        List<dynamic> statusesToCheck = [];
        statusesToCheck = isSearch ? resultJson['statuses'] : resultJson;
        logger.d('Finished');
        logger.d(loadedStatuses);
        // Remove status without osm.org link or status which are not from the own accountId
        statusesToCheck.removeWhere((item) {
          bool check = item['content'].contains('🌐') &&
              item['content'].contains('osm') &&
              item['account']['id'] == accountId;
          logger.d(check);
          return !check;
        });
        logger.d('Cleaned');
        logger.d(statusesToCheck);
        // If search attempt is empty and not coming from a checkin,
        // try to load posts from profile again.
        // Privacy settings could prevent that posts appear in search.
        if (lastPostId == null && loadCounter == 0 && statusesToCheck.isEmpty) {
          logger.d('No posts found with search, check profile...');
          loadCounter = maxTries + 1;
          _loadPosts();
          return;
        }
        // If lastPostId was given, i.e. a checkin was done before,
        // but lastPostId is not among results, reload the list again after 5 seconds.
        // This could also happen if privay settings prevent that posts appear in search,
        // but then as last resort posts are loaded from profile.
        if (lastPostId != null &&
            loadCounter < maxTries &&
            (statusesToCheck.isEmpty ||
                statusesToCheck[0]['id'] != lastPostId)) {
          loadCounter++;
          logger.d(
            'Still waiting for $lastPostId post to appear... retry $loadCounter...',
          );
          await Future.delayed(const Duration(seconds: 5));
          _loadPosts(lastPostId);
          return;
        }
        statuses = statusesToCheck;
        loadCounter = 0;
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      } else if (loadedStatuses.statusCode == 401) {
        logger.e('Token invalid');
        persistency.remove('access_token');
        setState(() {
          loading = false;
        });
        _jumpToAuth();
      } else {
        logger.w('Loading failed with status ${loadedStatuses.statusCode}');
        throw Exception(
          'Error during loading statuses with status ${loadedStatuses.statusCode}',
        );
      }
    } catch (e) {
      logger.e(e);
      setState(() {
        _error = 'SID_HOME_ERROR_STATUSES_LOAD';
        loading = false;
      });
    }
  }

  void _jumpToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthPage(
          title: 'SID_AUTH_TITLE',
        ),
      ),
    );
  }

  void _jumpToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(
          title: 'SID_ABOUT_TITLE',
        ),
      ),
    );
  }

  Map<String, dynamic> _parseStatus(String status) {
    logger.d('Parsing $status');
    dynamic htmlStatus = parse(status);
    List<html_dom.Element> pElements = htmlStatus.getElementsByTagName('p');
    if (pElements.length > 1) {
      html_dom.Element secondP = pElements[1];
      String location = secondP.innerHtml;
      List<String> parts = location.split(' ');
      String icon = parts[0];
      String locationText = parts.sublist(1).join(' ');
      return {'icon': icon, 'locationText': locationText};
    } else {
      return {'icon': 'i', 'locationText': 'location'};
    }
  }

  void _gotoLocations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPage(
          title: 'SID_LOCATIONS_TITLE',
        ),
      ),
    );
  }

  void _popupPost(post) {
    showPostPopup(context, mounted, post);
  }

  @override
  void initState() {
    super.initState();
    initCacheManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.i('Loading');
      logger.d('From checkin $fromCheckin');
      _loadPosts(lastPostId);
      if (fromCheckin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSuccess();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        String avatarUrl = '';
        if (snapshot.data != null &&
            snapshot.data!.containsKey('account_avatar')) {
          avatarUrl = snapshot.data!.getString('account_avatar') ?? '';
          logger.d(avatarUrl);
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title.tr),
          ),
          body: Column(
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      iconSize: 30,
                      onPressed: _jumpToSettings,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: loading && statuses.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : statuses.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    SizedBox(
                                      height: 250,
                                      child: SvgPicture.string(
                                        emojiSvg(_error == '' ? '🐱' : '😿'),
                                      ),
                                    ),
                                    Text(
                                      _error == ''
                                          ? 'SID_HOME_NO_STATUSES_FOUND'.tr
                                          : _error.tr,
                                      style: const TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: statuses.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    8.0,
                                    8.0,
                                    8.0,
                                    // More padding for last item
                                    index != statuses.length - 1
                                        ? 8.0
                                        : MediaQuery.of(context)
                                                .viewPadding
                                                .bottom +
                                            8.0 +
                                            30.0,
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      _popupPost(statuses[index]);
                                    },
                                    onLongPress: () {
                                      _popupPost(statuses[index]);
                                    },
                                    leading: Container(
                                      width: 54,
                                      height: 54,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Transform.translate(
                                        offset: const Offset(0, 0),
                                        child:
                                            //Text(
                                            SvgPicture.string(
                                          emojiSvg(
                                            _parseStatus(
                                              statuses[index]!['content'],
                                            )['icon'],
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          _parseStatus(
                                            statuses[index]!['content'],
                                          )['locationText'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          formatDay(
                                            DateTime.parse(
                                              statuses[index]!['created_at'],
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize:
                                                (DefaultTextStyle.of(context)
                                                            .style
                                                            .fontSize ??
                                                        16.0) *
                                                    0.9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Divider(),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
          floatingActionButton: SizedBox(
            height: 82,
            width: 82,
            child: FloatingActionButton(
              onPressed: _gotoLocations,
              tooltip: 'SID_HOME_FAB_TOOLTIP'.tr,
              shape: const CircleBorder(),
              child: Transform.scale(
                scale: 0.5,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: SvgPicture.asset(
                    'assets/ph--map-pin-fill.svg',
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onPrimaryContainer,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}
