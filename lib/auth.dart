import 'dart:core';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'home.dart';
import 'settings.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.title});

  final String title;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final logger = Logger();

  String _input = '';
  String _instance = '';
  String _error = '';

  bool _isValidDomain(String domain) {
    final RegExp domainRegex = RegExp(
      r'^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$',
      caseSensitive: false,
    );
    logger.d('$domain ${domainRegex.hasMatch(domain)}');
    return domainRegex.hasMatch(domain);
  }

  _readInput() async {
    setState(() {
      _error = '';
      _instance = '';
    });
    _input = instanceController.text;
    if (!_isValidDomain(_input)) {
      logger.w('Invalid domain');
      setState(() {
        _error = 'SID_AUTH_ERROR_NO_INSTANCE';
      });
      return;
    }
    setState(() {
      _input = instanceController.text;
      _instance = _input;
      _loginApp(_instance);
    });
  }

  final instanceController = TextEditingController();

  @override
  void dispose() {
    instanceController.dispose();
    super.dispose();
  }

  bool loading = false;

  Future<void> _persistInstanceInfos() async {
    SharedPreferences persistency = await SharedPreferences.getInstance();

    final instanceUrl = persistency.getString('instance_url');
    if (instanceUrl == null) {
      throw Exception('No instance url');
    }
    final instanceInfoResult = await http.get(
      Uri.parse('https://$instanceUrl/api/v2/instance'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': locidokoUserAgent,
      },
    ).timeout(
      const Duration(seconds: 45),
      onTimeout: () async {
        throw Exception('Timed out after 45 seconds');
      },
    );

    if (instanceInfoResult.statusCode == 200) {
      final instanceInfo = jsonDecode(instanceInfoResult.body);
      await persistency.setString(
        'instance_sw_version',
        instanceInfo['version'],
      );
      await persistency.setInt(
        'instance_max_characters',
        instanceInfo['configuration']['statuses']['max_characters'],
      );
    } else {
      throw Exception(
        'Instance infos failed with code ${instanceInfoResult.statusCode}',
      );
    }
  }

  Future<void> _registerClient() async {
    logger.i('Register new app client');

    SharedPreferences persistency = await SharedPreferences.getInstance();

    final instanceUrl = persistency.getString('instance_url');
    if (instanceUrl == null) {
      throw Exception('No instance url');
    }
    final appDetails = jsonEncode({
      'client_name': 'Locidoko',
      'redirect_uris': 'loci.doko.locidoko://oauth2redirect/',
      'scopes': 'read write',
      'website': repoUrl,
    });
    final newAppResponse = await http
        .post(
      Uri.parse('https://$instanceUrl/api/v1/apps'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': locidokoUserAgent,
      },
      body: appDetails,
    )
        .timeout(
      const Duration(seconds: 45),
      onTimeout: () async {
        throw Exception(
          'Timed out after 45 seconds when registering new app client',
        );
      },
    );
    logger.d(appDetails);
    logger.d(newAppResponse.body);
    if (newAppResponse.statusCode == 200) {
      logger.d('New app client successfully created');
      final newApp = jsonDecode(newAppResponse.body);
      await persistency.setString('client_id', newApp['client_id']);
      await persistency.setString('client_secret', newApp['client_secret']);
    } else {
      throw Exception(
        'Error during creation of new app client, ${newAppResponse.statusCode}',
      );
    }
  }

  Future<void> _requestCode() async {
    SharedPreferences persistency = await SharedPreferences.getInstance();

    final instanceUrl = persistency.getString('instance_url');
    final clientId = persistency.getString('client_id');
    if (instanceUrl == null || clientId == null) {
      throw Exception('No instance url or client id');
    }
    // Authorize first https://docs.joinmastodon.org/methods/oauth/#authorize
    final authUrl =
        'https://$instanceUrl/oauth/authorize?response_type=code&client_id=$clientId&redirect_uri=${Uri.encodeComponent('loci.doko.locidoko://oauth2redirect/')}&scope=read+write&force_login=false';

    logger.d('authUrl $authUrl');

    final authorizationCodeResponse = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: 'loci.doko.locidoko',
    ).timeout(
      const Duration(seconds: 45),
      onTimeout: () async {
        throw Exception('Timed out after 45 seconds');
      },
    );

    final code = Uri.parse(authorizationCodeResponse).queryParameters['code'];
    if (code != null) {
      persistency.setString('access_code', code);
    }
  }

  Future<void> _persistToken() async {
    logger.i('Request a token');

    SharedPreferences persistency = await SharedPreferences.getInstance();

    final instanceUrl = persistency.getString('instance_url');
    final clientId = persistency.getString('client_id');
    final clientSecret = persistency.getString('client_secret');
    if (instanceUrl == null || clientId == null || clientSecret == null) {
      throw Exception('No instance url, client id or client secret');
    }
    // Request a code to obtain a token
    await _requestCode();
    final code = persistency.getString('access_code');
    if (code == null) {
      throw Exception('No code could be obtained');
    }

    logger.d('code $code');

    // Then get a token https://docs.joinmastodon.org/methods/oauth/#token
    final tokenResponse = await http
        .post(
      Uri.parse('https://$instanceUrl/oauth/token'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': locidokoUserAgent,
      },
      body: jsonEncode({
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': 'loci.doko.locidoko://oauth2redirect/',
        'scope': 'read write',
      }),
    )
        .timeout(
      const Duration(seconds: 45),
      onTimeout: () async {
        throw Exception('Timed out after 45 seconds');
      },
    );

    logger.d('token ${tokenResponse.body}');

    // Store token
    if (tokenResponse.statusCode == 200) {
      final token = jsonDecode(tokenResponse.body);

      await persistency.setString('access_token', token['access_token']);
      await persistency
          .remove('access_code'); // Delete code, not necessary anymore
      logger.d('Token: $token');
      logger.d('Access Token: ${token['access_token']}');
    } else {
      persistency.remove('client_id');
      persistency.remove('client_secret');
      persistency.remove('access_token');
      throw Exception(
        'Error during creation of token, ${tokenResponse.statusCode}',
      );
    }
  }

  Future<void> _persistAccountDetails() async {
    SharedPreferences persistency = await SharedPreferences.getInstance();

    final instanceUrl = persistency.getString('instance_url');
    final accessToken = persistency.getString('access_token');
    if (instanceUrl == null || accessToken == null) {
      throw Exception('No instance url or access token');
    }
    // Get account details from verify endpoint https://docs.joinmastodon.org/methods/accounts/#verify_credentials
    final accountResponse = await http.get(
      Uri.parse('https://$instanceUrl//api/v1/accounts/verify_credentials'),
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

    logger.d('accountResponse ${accountResponse.body}');
    if (accountResponse.statusCode == 200) {
      final account = jsonDecode(accountResponse.body);
      await persistency.setString(
        'account_id',
        account['id'],
      );
      await persistency.setString(
        'account_avatar',
        account['avatar_static'],
      );
      await persistency.setString(
        'account_displayname',
        account['display_name'],
      );
      await persistency.setString(
        'account_handle',
        account['username'],
      );
    } else {
      logger.w('Not authorized, response ${accountResponse.statusCode}');
      persistency.remove('access_token');
      // Start over
      _loginApp(instanceUrl);
    }
  }

  Future<void> _loginApp(String instanceUrl) async {
    setState(() {
      loading = true;
    });
    logger.d(instanceUrl);
    try {
      // Go through the necessary steps to login to the instance
      // Use the shared preferences to persist and read data
      // instead of handing it over from one function to another

      // Create shared preferences to persist and read data
      SharedPreferences persistency = await SharedPreferences.getInstance();

      // Get instance
      await persistency.setString('instance_url', instanceUrl);

      // Persistency contains:
      // - instance_url

      // Get and persist instance infos
      if (!persistency.containsKey('instance_sw_version')) {
        await _persistInstanceInfos();
      }

      // Persistency contains:
      // - instance_url
      // - instance_sw_version
      // - instance_max_characters

      // If client registration doesn't exist yet, start it
      if (!persistency.containsKey('client_id') ||
          !persistency.containsKey('client_secret')) {
        await _registerClient();
      }

      // Persistency contains:
      // - instance_url
      // - instance_sw_version
      // - instance_max_characters
      // - client_id
      // - client_secret

      // Read registerd client from persistency
      final String? clientId = persistency.getString('client_id');
      final String? clientSecret = persistency.getString('client_secret');

      // If clientId and clientSecret exist
      if (clientId != null && clientSecret != null) {
        logger.d('clientId $clientId');
        logger.d('clientSecret $clientSecret');

        // Obtain the OAuth2 token if it does not exist yet
        if (!persistency.containsKey('access_token')) {
          await _persistToken();
        }
      } else {
        throw Exception('No clientID and clientSecret');
      }

      // Persistency contains:
      // - instance_url
      // - instance_sw_version
      // - instance_max_characters
      // - client_id
      // - client_secret
      // - access_token

      // Read token from persistency
      final String? accessToken = persistency.getString('access_token');
      logger.d('accessToken $accessToken');

      // Verify token
      if (accessToken != null) {
        await _persistAccountDetails();

        // Persistency contains:
        // - instance_url
        // - instance_sw_version
        // - instance_max_characters
        // - client_id
        // - client_secret
        // - access_token
        // - account_id
        // - account_avatar
        // - account_displayname
        // - account_handle

        logger.d('Persistency is complete: ${persistency.getKeys()}');

        final String? accountId = persistency.getString('account_id');

        logger.d('account_id ${persistency.getString('account_id')}');

        // Forward to Homepage
        if (mounted && accountId != null) {
          logger.i('DONE, show Home');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(
                title: 'SID_HOME_TITLE',
              ),
            ),
          );
        } else {
          throw Exception('No account id');
        }
      } else {
        throw Exception('No access token');
      }
    } catch (e) {
      _error = 'SID_AUTH_ERROR_NO_TOKEN';
      logger.e(e);
    } finally {
      setState(() {
        loading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title.tr),
      ),
      body: Center(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 32,
                    ),
                    child: TextField(
                      controller: instanceController,
                      decoration: InputDecoration(
                        labelText: 'SID_AUTH_INSTANCE'.tr,
                        hintText: 'SID_AUTH_ENTER_INSTANCE_DOMAIN'.tr,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 5.0),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _readInput,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                  _instance == ''
                      ? const Text(' ')
                      : Text('${'SID_AUTH_CONNECTING_TO'.tr}$_instance...'),
                  _error != ''
                      ? Text(
                          _error.tr,
                          textAlign: TextAlign.center,
                        )
                      : const Text(' '),
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
    );
  }
}
