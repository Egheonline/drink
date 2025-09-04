import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  /// Call this once (e.g., in `main()`)
  static Future<void> init() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'hydration_drop',
        channelName: 'Hydration Reminder (Drop)',
        channelDescription: 'Reminder with drop sound',
        defaultColor: const Color(0xFF2196F3),
        importance: NotificationImportance.High,
        playSound: true,
        soundSource: 'resource://raw/water',
      ),
      NotificationChannel(
        channelKey: 'hydration_chime',
        channelName: 'Hydration Reminder (Chime)',
        channelDescription: 'Reminder with chime sound',
        defaultColor: const Color(0xFF2196F3),
        importance: NotificationImportance.High,
        playSound: true,
        soundSource: 'resource://raw/chime',
      ),
      NotificationChannel(
        channelKey: 'hydration_alert',
        channelName: 'Hydration Reminder (Alert)',
        channelDescription: 'Reminder with alert sound',
        defaultColor: const Color(0xFF2196F3),
        importance: NotificationImportance.High,
        playSound: true,
        soundSource: 'resource://raw/bell',
      ),
      NotificationChannel(
        channelKey: 'hydration_bell',
        channelName: 'Bell Reminder',
        channelDescription: 'Bell sound for reminders',
        importance: NotificationImportance.High,
        soundSource: 'resource://raw/bell', // No extension
      ),
    ], debug: true);
  }

  /// Schedule multiple hydration reminders between `startHour` and `endHour`
  static Future<void> scheduleHydrationReminders({
    int startHour = 8,
    int endHour = 22,
    Duration interval = const Duration(minutes: 90),
  }) async {
    // Cancel existing reminders
    await AwesomeNotifications().cancelAllSchedules();

    // Get selected notification channel
    final prefs = await SharedPreferences.getInstance();
    String selectedChannel =
        prefs.getString('notificationChannel') ?? 'hydration_drop';

    int id = 0;
    final now = DateTime.now();
    DateTime current = DateTime(now.year, now.month, now.day, startHour);
    final end = DateTime(now.year, now.month, now.day, endHour);

    while (current.isBefore(end)) {
      final scheduledTime = current.isBefore(now)
          ? current.add(const Duration(days: 1))
          : current;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id++,
          channelKey: selectedChannel,
          title: 'hydration_reminder_title'.tr(),
          body: 'hydration_reminder_body'.tr(),
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        ),
      );

      current = current.add(interval);
    }
  }
}
