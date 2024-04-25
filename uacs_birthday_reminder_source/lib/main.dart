// Ignore the unused_import warning because it's a false positive here.
// ignore: unused_import
import 'platform_check.dart'
  if (dart.library.io) 'platform_check_io.dart'
  if (dart.library.html) 'platform_check_web.dart';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/home_page.dart'; 
import 'utilities/birthday_data.dart'; 
import 'utilities/notification_manager.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  initializeNotificationSystem();
  await initializeDataSystem().then((value) => FlutterNativeSplash.remove());

  runApp(MaterialApp(
    home: const BDReminderApp(),
    title: "UACS B-Day",
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en', ''),
      Locale('mk', ''),
      Locale('de', ''),
    ],
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    navigatorKey: navigatorKey,
  ));
}

class BDReminderApp extends StatefulWidget {
  const BDReminderApp({super.key});

  @override
  State<BDReminderApp> createState() => _BDReminderAppState();
}

class _BDReminderAppState extends State<BDReminderApp> {
  @override
  void dispose() {
    AwesomeNotifications().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    if (isIOS) {
      AwesomeNotifications().getGlobalBadgeCounter().then((value) {
        AwesomeNotifications().setGlobalBadgeCounter(value - 1);
      });
    }

    return const HomePage();
  }
}
