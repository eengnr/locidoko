import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart';
import 'home.dart';
import 'license.dart';
import 'localization.dart';

void main() {
  LicenseRegistry.addLicense(() {
    return Stream<LicenseEntry>.value(
      LicenseEntryWithLineBreaks(
        <String>['Locidoko'],
        licenses['gpl3']!,
      ),
    );
  });
  LicenseRegistry.addLicense(() {
    return Stream<LicenseEntry>.value(
      LicenseEntryWithLineBreaks(
        <String>['Phosphor Icons'],
        licenses['mit_phosphor']!,
      ),
    );
  });
  LicenseRegistry.addLicense(() {
    return Stream<LicenseEntry>.value(
      LicenseEntryWithLineBreaks(
        <String>['Material Symbols'],
        licenses['apache2']!,
      ),
    );
  });
  LicenseRegistry.addLicense(() {
    return Stream<LicenseEntry>.value(
      LicenseEntryWithLineBreaks(
        <String>['Noto Emoji'],
        licenses['apache2']!,
      ),
    );
  });

  runApp(
    GetMaterialApp(
      home: const MyApp(),
      translations: AppTranslations(),
      locale: Get.deviceLocale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('fr', 'FR'),
        Locale('it', 'IT'),
      ],
      fallbackLocale: const Locale('en', 'US'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightScheme, ColorScheme? darkScheme) {
        // Get persisted data
        // If not available, show auth page
        // If available, show home page
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (
            BuildContext context,
            AsyncSnapshot<SharedPreferences> snapshot,
          ) {
            bool showAuth = true;
            if (snapshot.data != null &&
                snapshot.data!.containsKey('access_token') &&
                snapshot.data!.containsKey('instance_url')) {
              final logger = Logger();
              try {
                final String? instanceUrl =
                    snapshot.data!.getString('instance_url');
                logger.d('Instance $instanceUrl');
                final String? accessToken =
                    snapshot.data!.getString('access_token');
                if (instanceUrl != null && accessToken != null) {
                  logger.d('Auth not necessary');
                  logger.d(Get.deviceLocale);
                  showAuth = false;
                }
              } catch (e) {
                logger.e(e.toString());
              }
            }

            return MaterialApp(
              title: 'Locidoko',
              theme: lightScheme != null
                  ? ThemeData.from(colorScheme: lightScheme)
                  : ThemeData(
                      colorScheme:
                          ColorScheme.fromSeed(seedColor: Colors.orange),
                      useMaterial3: true,
                    ),
              darkTheme: darkScheme != null
                  ? ThemeData.from(colorScheme: darkScheme)
                  : ThemeData(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: const Color.fromARGB(255, 82, 49, 0),
                      ),
                      useMaterial3: true,
                    ),
              home: showAuth
                  ? const AuthPage(title: 'SID_AUTH_TITLE')
                  : const HomePage(title: 'SID_HOME_TITLE'),
            );
          },
        );
      },
    );
  }
}
