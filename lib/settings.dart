import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cache.dart';
import 'constants.dart';
import 'home.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final logger = Logger();

  Future<void> _logout() async {
    SharedPreferences persistency = await SharedPreferences.getInstance();
    bool clear = await persistency.clear();
    getCacheManager().emptyCache();
    if (clear) {
      _jumpBack();
    }
  }

  void _jumpBack() {
    Navigator.of(context).pop();
    /* Trigger reload */
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(
          title: 'SID_HOME_TITLE',
        ),
      ),
    );
  }

  final overpassUrlController = TextEditingController();

  Future<void> _saveOverpassUrl() async {
    final prefs = await SharedPreferences.getInstance();
    logger.d('Persisting ${overpassUrlController.text}');
    prefs.setString('overpass_url', overpassUrlController.text);
  }

  Future<void> _loadOverpassUrl() async {
    final prefs = await SharedPreferences.getInstance();
    overpassUrlController.text =
        prefs.getString('overpass_url') ?? overpassDefaultUrl;
  }

  @override
  void initState() {
    super.initState();
    initCacheManager();
    _loadOverpassUrl();
    overpassUrlController.addListener(_saveOverpassUrl);
  }

  @override
  void dispose() {
    overpassUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        bool loggedIn = false;
        if (snapshot.data != null &&
            snapshot.data!.containsKey('access_token')) {
          loggedIn = true;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title.tr),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
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
                        const Text(
                          'Locidoko',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'SID_ABOUT_LICENSE'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'SID_ABOUT_LICENSE_TEXT'.tr,
                          style: const TextStyle(
                            fontSize: (16.0),
                          ),
                        ),
                        ListTile(
                          onTap: () {
                            showLicensePage(
                              context: context,
                              applicationName: 'Locidoko',
                              applicationVersion: '1.0.0',
                              applicationIcon: SizedBox(
                                width: 80,
                                height: 80,
                                child: SvgPicture.asset(
                                  'assets/ph--map-pin-fill.svg',
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            );
                          },
                          leading: const Icon(
                            Icons.text_snippet_outlined,
                          ),
                          title: Text(
                            'SID_ABOUT_OSS_LICENSES'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListTile(
                          onTap: () async {
                            final url = Uri.parse(
                              repoUrl,
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                              );
                            }
                          },
                          leading: const Icon(
                            Icons.code_rounded,
                          ),
                          title: Text(
                            'SID_ABOUT_CODE'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text('SID_ABOUT_OSM_NOTICE'.tr),
                    const SizedBox(height: 10),
                    Text('SID_ABOUT_OSM_CONTRIBUTE'.tr),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(
                          'https://www.openstreetmap.org',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('www.openstreetmap.org'),
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(
                          BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        // Necessary for TextField!
                        Expanded(
                          child: TextField(
                            controller: overpassUrlController,
                            decoration: InputDecoration(
                              labelText: 'SID_SETTINGS_OVERPASS_DOMAIN'.tr,
                              hintText: 'SID_SETTINGS_ENTER_OVERPASS_DOMAIN'.tr,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                  width: 5.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton.outlined(
                          onPressed: () async {
                            final url = Uri.parse(
                              '$repoUrl?tab=readme-ov-file#overpass-api',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                              );
                            }
                          },
                          icon: Icon(
                            Icons.question_mark_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    /*Expanded(
                    child: Container(),
                  ),*/
                    loggedIn
                        ? ElevatedButton.icon(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onError,
                            ),
                            icon: Icon(
                              Icons.logout_outlined,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                            label: Text(
                              'SID_ABOUT_BUTTON_LOGOUT'.tr,
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
