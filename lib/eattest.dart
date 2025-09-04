import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Lagos'));

  // Request notification permission
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Initialize plugin
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: android, iOS: ios);

  await notificationsPlugin.initialize(initSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: EatReminderScreen());
  }
}

class EatReminderScreen extends StatelessWidget {
  const EatReminderScreen({super.key});

  Future<void> _scheduleNotification(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await notificationsPlugin.zonedSchedule(
      100,
      'Time to Eat!',
      'Don’t forget to eat something 🍽️',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'eat_channel',
          'Meal Reminders',
          channelDescription: 'Meal reminder channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scheduled for ${pickedTime.format(context)}')),
    );
  }

  Future<void> _testImmediateNotification() async {
    await notificationsPlugin.show(
      0,
      'Test Immediate Notification',
      'This is a test 🔔',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          channelDescription: 'Test immediate notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eat Reminder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _scheduleNotification(context),
              child: const Text('Set Meal Reminder'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testImmediateNotification,
              child: const Text('Send Test Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
