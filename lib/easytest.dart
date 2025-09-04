import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'eat_channel',
      channelName: 'Eat Reminders',
      channelDescription: 'Notification channel for meal reminders',
      defaultColor: Colors.teal,
      ledColor: Colors.white,
      importance: NotificationImportance.High,
    ),
  ], debug: true);

  // Request notification permission
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: EatReminderPage());
  }
}

class EatReminderPage extends StatelessWidget {
  const EatReminderPage({super.key});

  void scheduleEatReminder(BuildContext context, TimeOfDay time) {
    final now = DateTime.now();
    final scheduleTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute).add(
          scheduleTimeIsInPast(now, time)
              ? const Duration(days: 1)
              : Duration.zero,
        );

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 101,
        channelKey: 'eat_channel',
        title: '🍽 Time to Eat!',
        body: 'Don’t forget to eat something and stay energized!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: scheduleTime.hour,
        minute: scheduleTime.minute,
        second: 0,
        repeats: true, // daily repeat
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheduled eat reminder at ${time.format(context)}'),
      ),
    );
  }

  bool scheduleTimeIsInPast(DateTime now, TimeOfDay time) {
    return now.hour > time.hour ||
        (now.hour == time.hour && now.minute >= time.minute);
  }

  Future<void> _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      scheduleEatReminder(context, time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Eat Reminder")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _pickTime(context),
          child: const Text("Set Eat Time"),
        ),
      ),
    );
  }
}
