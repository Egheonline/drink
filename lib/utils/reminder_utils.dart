import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ReminderUtils {
  static Future<void> reschedulePreservingManualIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final preserveManual = prefs.getBool('preserveManualReminders') ?? false;

    if (!preserveManual) {
      await AwesomeNotifications().cancelAllSchedules();
    } else {
      final existing = await AwesomeNotifications()
          .listScheduledNotifications();
      final autoIds = existing
          .where(
            (n) =>
                n.content?.payload == null ||
                n.content?.payload?['type'] != 'manual',
          )
          .map((n) => n.content?.id)
          .whereType<int>();
      for (final id in autoIds) {
        await AwesomeNotifications().cancelSchedule(id);
      }
    }

    await scheduleAutomaticReminders();
    await prefs.setBool('remindersScheduled', false);
  }

  static String getChannelKeyFromSelectedSound(String sound) {
    switch (sound.toLowerCase()) {
      case 'bell':
        return 'hydration_bell';
      case 'chime':
        return 'hydration_chime';
      case 'custom':
        return 'hydration_custom';
      case 'default':
        return 'hydration_default'; // Make sure this channel is defined in main.dart
      case 'water':
      default:
        return 'hydration_water';
    }
  }

  static Future<void> scheduleAutomaticReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final wakeTimeStr = prefs.getString('wakeTime');
    final bedTimeStr = prefs.getString('bedTime');
    final selectedSound = prefs.getString('selectedSound') ?? 'default';
    final channelKey = getChannelKeyFromSelectedSound(selectedSound);
    final locale = prefs.getString('locale') ?? 'en';

    if (wakeTimeStr == null || bedTimeStr == null) {
      return;
    }

    final wakeTime = _parseTimeOfDay(wakeTimeStr);
    final bedTime = _parseTimeOfDay(bedTimeStr);
    final reminderTimes = _generateReminderTimes(
      wakeTime,
      bedTime,
      const Duration(hours: 1, minutes: 30),
    );
    final baseId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    for (int i = 0; i < reminderTimes.length; i++) {
      final time = reminderTimes[i];
      final title = await getTranslation('hydration_reminder_title', locale);
      final body = await getTranslation('hydration_reminder_body', locale);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseId + i,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: {'type': 'auto'},
          customSound:
              (selectedSound.toLowerCase() == 'default' ||
                  selectedSound.toLowerCase() == 'custom')
              ? null
              : 'resource://raw/${selectedSound.toLowerCase()}',
        ),
        schedule: NotificationCalendar(
          hour: time.hour,
          minute: time.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        ),
      );
    }

    await prefs.setBool('remindersScheduled', true);
  }

  static TimeOfDay _parseTimeOfDay(String timeStr) {
    final format = timeStr.contains('AM') || timeStr.contains('PM')
        ? DateFormat.jm()
        : DateFormat.Hm();
    final dt = format.parse(timeStr);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  static List<TimeOfDay> _generateReminderTimes(
    TimeOfDay start,
    TimeOfDay end,
    Duration interval,
  ) {
    final times = <TimeOfDay>[];
    final now = DateTime.now();
    DateTime current = DateTime(
      now.year,
      now.month,
      now.day,
      start.hour,
      start.minute,
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      end.hour,
      end.minute,
    );

    while (current.isBefore(endTime)) {
      times.add(TimeOfDay(hour: current.hour, minute: current.minute));
      current = current.add(interval);
    }
    return times;
  }
}

Future<String> getTranslation(String key, String locale) async {
  final String jsonString = await rootBundle.loadString(
    'assets/translations/$locale.json',
  );
  final Map<String, dynamic> translations = json.decode(jsonString);
  return translations[key] ?? key;
}

Future<void> setLocale(BuildContext context, String locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('locale', locale);
  context.setLocale(Locale(locale));
}
