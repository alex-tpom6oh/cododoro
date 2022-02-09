import 'dart:async';

import 'package:cododoro/models/ElapsedTimeModel.dart';
import 'package:cododoro/storage/HistoryRepository.dart';
import 'package:cododoro/storage/ThemeSettings.dart';
import 'package:cododoro/widgets/IdleScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:mixpanel_analytics/mixpanel_analytics.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:platform_info/platform_info.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'models/TimerModel.dart';
import 'storage/Settings.dart';
import 'widgets/TimerScreen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}

MixpanelAnalytics? mixpanel;

Future<bool> mixpanelTrack(
    {required String eventName, Map<String, dynamic> params = const {}}) async {
  String? deviceId;
  try {
    deviceId = await PlatformDeviceId.getDeviceId;
  } on PlatformException {
    deviceId = 'Failed to get deviceId.';
  }

  final os = Platform.instance.operatingSystem.toString().split('.').last;

  return mixpanel?.track(
          event: eventName,
          properties: {"distinct_id": deviceId, "OS": os}..addAll(params)) ??
      Future.value(false);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureLocalTimeZone();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final IOSInitializationSettings initializationSettingsIOS =
      IOSInitializationSettings();
  const MacOSInitializationSettings initializationSettingsMacOS =
      MacOSInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    macOS: initializationSettingsMacOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeSettings themeSettings = ThemeSettings();

  bool isIdle = true;

  @override
  void initState() {
    mixpanel = MixpanelAnalytics(
        token: "e526e2811ef8cf92c6a18dcbc889f12b",
        verbose: false,
        shouldAnonymize: true,
        shaFn: (value) => value,
        onError: (e) {
          print("mixpanel error");
        });

    trackAppOpened();

    themeSettings.addListener(() {
      setState(() {
        _themeSetting = themeSettings.currentThemeSetting;
      });
    });

    themeSettings.init();

    super.initState();
  }

  void trackAppOpened() async {
    mixpanelTrack(eventName: 'App Opened');
  }

  ThemeSetting _themeSetting = ThemeSetting.system;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (BuildContext context,
            AsyncSnapshot<SharedPreferences> sharedPrefsSnapshot) {
          final sharedPrefs = sharedPrefsSnapshot.data;

          return sharedPrefs != null && !isIdle
              ? timerScreen(sharedPrefs)
              : idleScreen(sharedPrefs);
        });
  }

  MaterialApp idleScreen(SharedPreferences? sharedPrefs) {
    return MaterialApp(
        theme: _themeSetting == ThemeSetting.dark ? darkTheme : lightTheme,
        darkTheme: _themeSetting == ThemeSetting.light ? lightTheme : darkTheme,
        home: IdleScreen(
            sharedPrefs: sharedPrefs,
            themeSetting: _themeSetting,
            showTimerScreen: () {
              setState(() {
                isIdle = false;
              });
            }));
  }

  MultiProvider timerScreen(SharedPreferences sharedPrefs) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => TimerStateModel()),
          ChangeNotifierProvider(
              create: (context) => Settings(prefs: sharedPrefs)),
          ChangeNotifierProvider(create: (context) => ElapsedTimeModel()),
          ChangeNotifierProvider(
              create: (context) => HistoryRepository(prefs: sharedPrefs)),
          ChangeNotifierProvider(create: (context) => themeSettings)
        ],
        child: MaterialApp(
            title: 'Cododoro App',
            theme: _themeSetting == ThemeSetting.dark ? darkTheme : lightTheme,
            darkTheme:
                _themeSetting == ThemeSetting.light ? lightTheme : darkTheme,
            home: TimerScreen(showIdleScreen: () {
              setState(() {
                isIdle = true;
              });
            })));
  }
}
