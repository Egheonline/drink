import 'package:workmanager/workmanager.dart';
import 'package:flutter/widgets.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/reminder_utils.dart';

const String dailyTaskId = "dailyMidnightReminder";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (taskName == dailyTaskId) {
      final prefs = await SharedPreferences.getInstance();
      final preserveManual = prefs.getBool('preserveManualReminders') ?? false;

      if (preserveManual) {
        final existing = await AwesomeNotifications()
            .listScheduledNotifications();
        final autoIds = existing
            .where((n) => n.content?.payload?['type'] != 'manual')
            .map((n) => n.content?.id)
            .whereType<int>();
        for (final id in autoIds) {
          await AwesomeNotifications().cancelSchedule(id);
        }
      } else {
        await AwesomeNotifications().cancelAllSchedules();
      }

      await prefs.setBool('remindersScheduled', false);
      await ReminderUtils.scheduleAutomaticReminders();

      return Future.value(true);
    }

    return Future.value(false);
  });
}
