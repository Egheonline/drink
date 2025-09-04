import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:drink/theme_provider.dart';
import 'package:drink/utils/reminder_utils.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:workmanager/workmanager.dart';

class ScheduledRemindersScreen extends StatefulWidget {
  const ScheduledRemindersScreen({super.key});

  @override
  State<ScheduledRemindersScreen> createState() =>
      _ScheduledRemindersScreenState();
}

class _ScheduledRemindersScreenState extends State<ScheduledRemindersScreen>
    with WidgetsBindingObserver {
  List<NotificationModel> _reminders = [];
  bool _loading = true;
  String? _error;
  final Set<int> _disabledIds = {};
  bool _preserveManualReminders = true;
  Duration _interval = const Duration(minutes: 90);

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    _initializeScreen();
    _scheduleAutoRefresh();
  }

  void _scheduleAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
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
        await prefs.setString(
          'lastReminderRefreshDateTime',
          now.toIso8601String(),
        );
        await _fetchReminders();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
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
        await prefs.setString(
          'lastReminderRefreshDateTime',
          now.toIso8601String(),
        );
        await _fetchReminders();
      } else {}
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _initializeScreen() async {
    final prefs = await SharedPreferences.getInstance();

    _preserveManualReminders =
        prefs.getBool('preserveManualReminders') ?? false;
    final savedInterval = prefs.getInt('reminderInterval');
    if (savedInterval != null) _interval = Duration(minutes: savedInterval);

    final lastRefreshString = prefs.getString('lastReminderRefreshDate');
    if (lastRefreshString != null) {}

    await _maybeScheduleReminders();
    await _fetchReminders();
    await scheduleMidnightReminderRescheduler();
  }

  Future<void> _maybeScheduleReminders() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('remindersScheduled') ?? false)) {
      await _scheduleAutomaticReminders();
      await prefs.setBool('remindersScheduled', true);
    }
  }

  Future<void> _fetchReminders() async {
    try {
      final scheduled = await AwesomeNotifications()
          .listScheduledNotifications();
      final now = DateTime.now();

      // Delete any one-time notification after its scheduled time has passed
      for (var r in scheduled) {
        if (r.schedule is NotificationCalendar) {
          final cal = r.schedule as NotificationCalendar;
          final scheduledTime = DateTime(
            cal.year ?? now.year,
            cal.month ?? now.month,
            cal.day ?? now.day,
            cal.hour ?? 0,
            cal.minute ?? 0,
          );
          if (!cal.repeats && scheduledTime.isBefore(now)) {
            final id = r.content?.id;
            if (id != null) await AwesomeNotifications().cancelSchedule(id);
          }
        }
      }

      scheduled.sort((a, b) => _getDate(a).compareTo(_getDate(b)));
      if (!mounted) return;
      setState(() {
        _reminders = scheduled;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load reminders: $e";
        _loading = false;
      });
    }
  }

  DateTime _getDate(NotificationModel r) {
    if (r.schedule is NotificationCalendar) {
      final cal = r.schedule as NotificationCalendar;
      return DateTime(
        cal.year ?? 0,
        cal.month ?? 1,
        cal.day ?? 1,
        cal.hour ?? 0,
        cal.minute ?? 0,
      );
    }
    return DateTime(0);
  }

  Future<void> _cancelReminder(int id) async {
    try {
      await AwesomeNotifications().cancelSchedule(id);
      setState(() => _reminders.removeWhere((r) => r.content?.id == id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('reminder_cancelled'.tr())));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cancelling: $e")));
    }
  }

  Future<void> _scheduleAutomaticReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final preserveManual = _preserveManualReminders;

    final existing = await AwesomeNotifications().listScheduledNotifications();

    if (preserveManual) {
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
    } else {
      await AwesomeNotifications().cancelAllSchedules();
    }

    final wakeTimeStr = prefs.getString('wakeTime');
    final bedTimeStr = prefs.getString('bedTime');
    final selectedSound = prefs.getString('selectedSound') ?? 'default';
    final channelKey = getChannelKeyFromSelectedSound(selectedSound);

    if (wakeTimeStr == null || bedTimeStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("set_wakeuptime_and_bedtime_in_settings_first".tr()),
        ),
      );
      return;
    }

    // 👇 Get the current locale from EasyLocalization
    final currentLocale =
        EasyLocalization.of(context)?.locale.languageCode ?? 'en';

    // 👇 Manually load translations from the asset
    final reminderTitle = await getTranslation(
      'hydration_reminder_title',
      currentLocale,
    );
    final reminderBody = await getTranslation(
      'hydration_reminder_body',
      currentLocale,
    );

    final wakeTime = _parseTimeOfDay(wakeTimeStr);
    final bedTime = _parseTimeOfDay(bedTimeStr);
    final reminderTimes = _generateReminderTimes(wakeTime, bedTime, _interval);

    final now = DateTime.now();
    final baseId = now.millisecondsSinceEpoch.remainder(100000);

    for (int i = 0; i < reminderTimes.length; i++) {
      final time = reminderTimes[i];
      final scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (scheduled.isBefore(now)) continue;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseId + i,
          channelKey: channelKey ?? 'hydration_default',
          title: reminderTitle,
          body: reminderBody,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          hour: scheduled.hour,
          minute: scheduled.minute,
          second: 0,
          millisecond: 0,
          repeats: false,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        ),
      );
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final format = timeStr.contains('AM') || timeStr.contains('PM')
        ? DateFormat.jm()
        : DateFormat.Hm();
    final dt = format.parse(timeStr);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  List<TimeOfDay> _generateReminderTimes(
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

  Future<void> _setReminderInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final options = [30, 60, 90, -1];
    int? selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Select Interval (minutes)"),
          children: options.map((min) {
            return SimpleDialogOption(
              onPressed: () async {
                if (min == -1) {
                  final controller = TextEditingController();
                  final custom = await showDialog<int>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Enter Custom Interval (minutes)"),
                      content: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: "E.g. 45"),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            final parsed = int.tryParse(controller.text);
                            Navigator.pop(context, parsed);
                          },
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                  Navigator.pop(context, custom);
                } else {
                  Navigator.pop(context, min);
                }
              },
              child: Text(min == -1 ? "Custom..." : "$min minutes"),
            );
          }).toList(),
        );
      },
    );
    if (selected != null && selected > 0) {
      setState(() => _interval = Duration(minutes: selected));
      await prefs.setInt('reminderInterval', selected);
      await prefs.setBool('remindersScheduled', false);
      await _maybeScheduleReminders();
      await _fetchReminders();
    }
  }

  Future<void> _togglePreserveManualReminders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _preserveManualReminders = !_preserveManualReminders);
    await prefs.setBool('preserveManualReminders', _preserveManualReminders);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "scheduled_reminders".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Image.asset('assets/drink_icon.png', fit: BoxFit.cover),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "preserve_manual_reminders_description".tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _preserveManualReminders,
                      onChanged: (_) => _togglePreserveManualReminders(),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _setReminderInterval,
                child: Text("set_reminder_interval".tr()),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : _reminders.isEmpty
                    ? Center(child: Text("no_scheduled_reminders".tr()))
                    : ListView.builder(
                        itemCount: _reminders.length,
                        itemBuilder: (context, index) {
                          final r = _reminders[index];
                          final id = r.content?.id ?? 0;
                          final isDisabled = _disabledIds.contains(id);
                          String timeString = 'Unknown';

                          if (r.schedule is NotificationCalendar) {
                            final cal = r.schedule as NotificationCalendar;
                            if (cal.repeats == true) {
                              // Repeating daily reminder: show only time
                              timeString = DateFormat.Hm().format(
                                DateTime(
                                  0,
                                  1,
                                  1,
                                  cal.hour ?? 0,
                                  cal.minute ?? 0,
                                ),
                              );
                            } else {
                              // One-time/manual reminder: show full date and time
                              final dt = DateTime(
                                cal.year ?? DateTime.now().year,
                                cal.month ?? DateTime.now().month,
                                cal.day ?? DateTime.now().day,
                                cal.hour ?? 0,
                                cal.minute ?? 0,
                              );
                              timeString = DateFormat.yMMMMd(
                                context.locale.toLanguageTag(),
                              ).add_Hm().format(dt);
                            }
                          }

                          return ListTile(
                            title: Text(
                              r.content?.payload?['type'] == 'manual'
                                  ? ((r.content?.title != null
                                        ? (r.content!.title!).tr()
                                        : 'Reminder'.tr()))
                                  : 'hydration_reminder_title'.tr(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              "Time: $timeString\n${r.content?.payload?['type'] == 'manual' ? (r.content?.body != null ? (r.content!.body!).tr() : '') : 'hydration_reminder_body'.tr()}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: !isDisabled,
                                  onChanged: (value) async {
                                    setState(() {
                                      if (!value) {
                                        _disabledIds.add(id);
                                        AwesomeNotifications().cancelSchedule(
                                          id,
                                        );
                                      } else {
                                        _disabledIds.remove(id);
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  onPressed: () async {
                                    if (r.schedule is NotificationCalendar) {
                                      final cal =
                                          r.schedule as NotificationCalendar;
                                      final initialTime = TimeOfDay(
                                        hour: cal.hour ?? 0,
                                        minute: cal.minute ?? 0,
                                      );
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime: initialTime,
                                      );
                                      if (pickedTime != null) {
                                        final now = DateTime.now();
                                        final newDateTime = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                        await AwesomeNotifications()
                                            .cancelSchedule(id);

                                        // Get selected sound and channel for manual reminders
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        final selectedSound =
                                            prefs.getString('selectedSound') ??
                                            'default';
                                        final channelKey =
                                            getChannelKeyFromSelectedSound(
                                              selectedSound,
                                            );

                                        await AwesomeNotifications().createNotification(
                                          content: NotificationContent(
                                            id: id,
                                            channelKey:
                                                channelKey ??
                                                'hydration_default', // <-- Use selected channel for manual reminders
                                            title: 'hydration_reminder_title'
                                                .tr(),
                                            body: 'hydration_reminder_body'
                                                .tr(),
                                            notificationLayout:
                                                NotificationLayout.Default,
                                            payload: {'type': 'manual'},
                                          ),
                                          schedule: NotificationCalendar(
                                            year: newDateTime.year,
                                            month: newDateTime.month,
                                            day: newDateTime.day,
                                            hour: newDateTime.hour,
                                            minute: newDateTime.minute,
                                            second: 0,
                                            millisecond: 0,
                                            repeats: false,
                                            timeZone: await AwesomeNotifications()
                                                .getLocalTimeZoneIdentifier(),
                                          ),
                                        );
                                        await _fetchReminders();
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.cancel,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: () => _cancelReminder(id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remindersScheduled', false);
          await _maybeScheduleReminders();
          await _fetchReminders();
        },
        tooltip: 'Reschedule',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// Top-level, synchronous callback for AndroidAlarmManager
@pragma('vm:entry-point')
void midnightReminderRescheduler() {
  // Only set a flag in SharedPreferences
  SharedPreferences.getInstance().then((prefs) {
    prefs.setBool('midnightRescheduleNeeded', true);
  });
}

Future<void> scheduleMidnightReminderRescheduler() async {}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Only run for your own tasks
    const allowedTasks = [
      'midnightReminder',
      'reminderBackgroundRefresh',
      'tenMinuteRefresh',
    ];
    if (allowedTasks.contains(task)) {
      await ReminderUtils.reschedulePreservingManualIfNeeded();
    }
    // Always return true
    return Future.value(true);
  });
}

String? getChannelKeyFromSelectedSound(String sound) {
  switch (sound.toLowerCase()) {
    case 'bell':
      return 'hydration_bell';
    case 'chime':
      return 'hydration_chime';
    case 'custom':
      return 'hydration_custom';
    case 'default':
      return null; // Use system default sound/channel
    case 'water':
      return 'hydration_water';
    default:
      return null;
  }
}

Future<String> getTranslation(String key, String locale) async {
  final String jsonString = await rootBundle.loadString(
    'assets/translations/$locale.json',
  );
  final Map<String, dynamic> translations = json.decode(jsonString);
  return translations[key] ?? key;
}
