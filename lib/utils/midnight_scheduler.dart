import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'reminder_utils.dart';

/// Unique alarm ID for midnight reminder rescheduling
const int midnightAlarmId = 1;
const String midnightWorkTask = 'midnight_reschedule';

/// Schedule the alarm to trigger every day at 00:00 (midnight)
Future<void> scheduleMidnightReminderRescheduler() async {
  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);

  await AndroidAlarmManager.cancel(midnightAlarmId); // cancel any existing

  await AndroidAlarmManager.oneShotAt(
    nextMidnight,
    midnightAlarmId,
    midnightReminderRescheduler,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );
}

/// Top-level callback to run at midnight to reschedule reminders
void midnightReminderRescheduler(int id) {
  // Schedule Workmanager task for background-safe execution
  Workmanager().registerOneOffTask(
    '${midnightWorkTask}_$id', // unique name
    midnightWorkTask,
    initialDelay: Duration(seconds: 1), // run almost immediately
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresBatteryNotLow: false,
      requiresStorageNotLow: false,
    ),
  );

  // Schedule again for the next midnight
  scheduleMidnightReminderRescheduler();
}

// In your main.dart, ensure you have this Workmanager dispatcher:
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == midnightWorkTask) {
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
    }
    return Future.value(true);
  });
}
