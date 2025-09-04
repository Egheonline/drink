import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drink/utils/reminder_utils.dart';
import 'package:workmanager/workmanager.dart';

/// This ID must be unique and non-zero to avoid silent failures.
const int midnightAlarmId = 999;
const String midnightWorkTask = 'midnight_reschedule';

/// Schedules a task to run at 00:00 (midnight) every day.
/// This function should be called once during app initialization.
Future<void> scheduleMidnightReminderRescheduler() async {
  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);

  // Cancel any existing alarm with the same ID to avoid duplication
  await AndroidAlarmManager.cancel(midnightAlarmId);

  await AndroidAlarmManager.oneShotAt(
    nextMidnight,
    midnightAlarmId,
    midnightReminderRescheduler,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );
}

/// This is the callback that will be triggered by the alarm at midnight.
/// It must be a **top-level function**, and should not be inside any class.
void midnightReminderRescheduler() {
  // Schedule Workmanager task for background-safe execution
  Workmanager().registerOneOffTask(
    '${midnightWorkTask}_$midnightAlarmId', // unique name
    midnightWorkTask,
    initialDelay: Duration(seconds: 1),
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
