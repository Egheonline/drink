import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:drink/splashscreen.dart';
import 'package:drink/theme_provider.dart';
import 'package:drink/notification_router_screen.dart';
import 'package:drink/utils/reminder_utils.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const midnightTask = "midnight_refresh";

// ✅ Cleaned & filtered background task dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    const allowedTasks = {'midnight_refresh', 'tenMinuteRefresh'};

    if (allowedTasks.contains(task)) {
      try {
        debugPrint("✅ Running background task: $task");
        await ReminderUtils.reschedulePreservingManualIfNeeded();
      } catch (e, s) {
        debugPrint("❌ Error in task $task: $e\n$s");
      }
    } else {
      debugPrint("⚠️ Ignored unknown background task: $task");
    }

    return Future.value(true);
  });
}

// Helper to calculate initial delay to next midnight
int calculateInitialDelayToMidnight() {
  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  return nextMidnight.difference(now).inMilliseconds;
}

Future<void> _checkIfNewDayAndRefreshReminders() async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final lastRefreshStr = prefs.getString('lastReminderRefreshDateTime');
  final lastRefresh = lastRefreshStr != null
      ? DateTime.tryParse(lastRefreshStr)
      : null;

  bool shouldRefresh = false;

  if (lastRefresh == null) {
    shouldRefresh = true;
  } else if (now.isBefore(lastRefresh)) {
    shouldRefresh = true;
  } else if (now.difference(lastRefresh).inHours >= 12 ||
      now.day != lastRefresh.day) {
    shouldRefresh = true;
  }

  if (shouldRefresh) {
    await ReminderUtils.reschedulePreservingManualIfNeeded();
    await prefs.setString('lastReminderRefreshDateTime', now.toIso8601String());
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // ✅ Initialize Workmanager cleanly
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().cancelAll(); // 🧹 Prevent weird tasks showing on install

  // 🕛 Midnight reminder task
  await Workmanager().registerPeriodicTask(
    'midnightTaskId',
    'midnight_refresh',
    frequency: const Duration(hours: 24),
    initialDelay: Duration(milliseconds: calculateInitialDelayToMidnight()),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
    ),
  );

  // 🔁 10-minute hydration refresh
  await Workmanager().registerPeriodicTask(
    'tenMinuteRefreshId',
    'tenMinuteRefresh',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
    ),
  );

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  // ✅ Setup Awesome Notifications
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'hydration_default',
      channelName: 'Default Reminder',
      channelDescription: 'Uses the system default notification sound',
      defaultColor: Colors.blue,
      ledColor: Colors.blue,
      importance: NotificationImportance.High,
      soundSource: null,
    ),
    NotificationChannel(
      channelKey: 'hydration_water',
      channelName: 'Water Reminder',
      channelDescription: 'Water sound for reminders',
      defaultColor: Colors.blue,
      ledColor: Colors.blue,
      importance: NotificationImportance.High,
      soundSource: 'resource://raw/water',
    ),
    NotificationChannel(
      channelKey: 'hydration_bell',
      channelName: 'Bell Reminder',
      channelDescription: 'Bell sound for reminders',
      defaultColor: Colors.blue,
      ledColor: Colors.blue,
      importance: NotificationImportance.High,
      soundSource: 'resource://raw/bell',
    ),
    NotificationChannel(
      channelKey: 'hydration_chime',
      channelName: 'Chime Reminder',
      channelDescription: 'Chime sound for reminders',
      defaultColor: Colors.blue,
      ledColor: Colors.blue,
      importance: NotificationImportance.High,
      soundSource: 'resource://raw/chime',
    ),
    NotificationChannel(
      channelKey: 'hydration_custom',
      channelName: 'Custom Reminder',
      channelDescription: 'User-selected custom sound',
      defaultColor: Colors.blue,
      ledColor: Colors.blue,
      importance: NotificationImportance.High,
      soundSource: null,
    ),
  ], debug: true);

  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  final ReceivedAction? initialAction = await AwesomeNotifications()
      .getInitialNotificationAction(removeFromActionEvents: false);

  AwesomeNotifications().setListeners(
    onNotificationDisplayedMethod: (ReceivedNotification notification) async {
      final id = notification.id;
      if (id != null) {
        await AwesomeNotifications().cancelSchedule(id);
      }
    },
    onActionReceivedMethod: (ReceivedAction action) async {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => NotificationRouterScreen(action: action),
        ),
        (route) => false,
      );
    },
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
        Locale('yo'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ChangeNotifierProvider.value(
        value: themeProvider,
        child: MyApp(initialAction: initialAction),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final ReceivedAction? initialAction;
  const MyApp({super.key, required this.initialAction});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      await _checkIfNewDayAndRefreshReminders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkIfNewDayAndRefreshReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Hydration App',
          color: Colors.white,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          themeMode: themeProvider.currentThemeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromARGB(255, 48, 135, 178),
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ),
          home: widget.initialAction != null
              ? NotificationRouterScreen(action: widget.initialAction!)
              : const Splashscreen(),
        );
      },
    );
  }
}
