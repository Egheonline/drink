import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:drink/widgets/hydration_bottom_nav_bar.dart';
import 'package:drink/scheduledreminder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:drink/theme_provider.dart';
import 'package:drink/nativead.dart';
import 'package:confetti/confetti.dart';

class HydrationVisualizerScreen extends StatefulWidget {
  final void Function(bool)? onThemeChanged;
  const HydrationVisualizerScreen({super.key, this.onThemeChanged});

  @override
  State<HydrationVisualizerScreen> createState() =>
      _HydrationVisualizerScreenState();
}

class _HydrationVisualizerScreenState extends State<HydrationVisualizerScreen>
    with TickerProviderStateMixin {
  double totalIntake = 0;
  int weightKg = 0;
  double goalIntake = 0;
  String? _gender;
  String _intakeUnit = 'ml';

  late AnimationController _bobController;
  late AnimationController _percentageController;
  late Animation<double> _percentageAnimation;
  late ConfettiController _confettiController;
  bool goalCelebrated = false;

  @override
  void initState() {
    super.initState();
    totalIntake = 0;
    _loadFromPreferences();
    _loadGender();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _percentageController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _percentageAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_percentageController);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _requestPermissions();
    _loadIntake();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('batteryDialogShown') ?? false;
      if (!shown) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await showOptimizationDialog(context);
          await prefs.setBool('batteryDialogShown', true);
        }
      }
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      weightKg = prefs.getInt('weight') ?? 0;
      goalIntake = prefs.getInt('goalIntake')?.toDouble() ?? 0;
      _intakeUnit = prefs.getString('intakeUnit') ?? 'ml';
    });
    _loadIntake();
  }

  Future<void> _loadGender() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gender = prefs.getString('gender');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFromPreferences();
  }

  @override
  void dispose() {
    _bobController.dispose();
    _percentageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadIntake() async {
    final prefs = await SharedPreferences.getInstance();
    double savedIntake = prefs.getDouble('totalIntake') ?? 0;

    setState(() {
      totalIntake = savedIntake;
    });

    double targetPercentage = goalIntake == 0
        ? 0
        : (totalIntake / goalIntake).clamp(0.0, 1.0);

    _percentageAnimation = Tween<double>(begin: 0, end: targetPercentage)
        .animate(
          CurvedAnimation(parent: _percentageController, curve: Curves.easeOut),
        );

    _percentageController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);

    // --- Only this line for consumed amount is new ---
    double Consumed = totalIntake;

    return AnimatedBuilder(
      animation: _percentageController,
      builder: (context, child) {
        double animatedPercentage = _percentageAnimation.value;
        double waveHeight =
            MediaQuery.of(context).size.height * 0.5 * animatedPercentage;
        int percentValue = (animatedPercentage * 100).round();

        String displayVolume(double ml) {
          if (_intakeUnit == 'ml') return '${ml.toStringAsFixed(0)} ml';
          return '${(ml / 29.5735).toStringAsFixed(1)} fl oz';
        }

        // --- Gender image selection with breastfeeding/pregnant support ---
        String? genderImage;
        if (_gender?.toLowerCase() == 'male') {
          genderImage = 'assets/mandancing.png';
        } else if (_gender?.toLowerCase() == 'female') {
          genderImage = 'assets/womandancing.png';
        } else if (_gender?.toLowerCase() == 'pregnant woman') {
          genderImage = 'assets/pregnant.png';
        } else if (_gender?.toLowerCase() == 'breastfeeding mother') {
          genderImage = 'assets/breastfeeding.png';
        } else {
          genderImage = 'assets/womandancing.png';
        }
        // ---------------------------------------------------------------

        // --- Confetti trigger logic ---
        if (goalIntake > 0 && totalIntake >= goalIntake && !goalCelebrated) {
          _confettiController.play();
          goalCelebrated = true;
        }
        if (goalCelebrated && totalIntake < goalIntake) {
          goalCelebrated = false;
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: goalIntake == 0
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            displayVolume(Consumed),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'left'.tr(
                                        namedArgs: {
                                          'amount': displayVolume(
                                            goalIntake - totalIntake,
                                          ),
                                        },
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'consumed'.tr(
                                        namedArgs: {
                                          'amount': displayVolume(totalIntake),
                                        },
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 340,
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          // --- Animation and confetti changes only ---
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            height: waveHeight,
                                            child: Opacity(
                                              opacity: 0.7,
                                              child: WaveWidget(
                                                config: CustomConfig(
                                                  gradients: [
                                                    [
                                                      Colors.blueAccent,
                                                      Colors.blue.shade300,
                                                    ],
                                                    [
                                                      Colors.blue.shade200,
                                                      Colors.blueAccent,
                                                    ],
                                                  ],
                                                  durations: [32000, 18000],
                                                  heightPercentages: [
                                                    0.25,
                                                    0.26,
                                                  ],
                                                  blur: MaskFilter.blur(
                                                    BlurStyle.solid,
                                                    2,
                                                  ),
                                                  gradientBegin:
                                                      Alignment.bottomLeft,
                                                  gradientEnd:
                                                      Alignment.topRight,
                                                ),
                                                waveAmplitude: 0,
                                                size: const Size(
                                                  double.infinity,
                                                  double.infinity,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 50,
                                            child: SlideTransition(
                                              position:
                                                  Tween<Offset>(
                                                    begin: const Offset(0, 0),
                                                    end: const Offset(0, 0.02),
                                                  ).animate(
                                                    CurvedAnimation(
                                                      parent: _bobController,
                                                      curve: Curves.easeInOut,
                                                    ),
                                                  ),
                                              child: Image.asset(
                                                genderImage!,
                                                height: 440,
                                                width: 228,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 16,
                                            left: 20,
                                            child: Row(
                                              children: [
                                                Text(
                                                  '$percentValue%',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                      ),
                                                ),
                                                const SizedBox(width: 6),
                                                Icon(
                                                  Icons.water_drop,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  size: 22,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topCenter,
                                            child: ConfettiWidget(
                                              confettiController:
                                                  _confettiController,
                                              blastDirectionality:
                                                  BlastDirectionality.explosive,
                                              shouldLoop: false,
                                              colors: const [
                                                Colors.blue,
                                                Colors.green,
                                                Colors.pink,
                                                Colors.orange,
                                                Colors.purple,
                                              ],
                                              emissionFrequency: 0.05,
                                              numberOfParticles: 20,
                                              maxBlastForce: 20,
                                              minBlastForce: 8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // --- End animation/confetti/consumed changes ---

                                    // ...rest of your unchanged UI code (ads, buttons, etc.)...
                                    const SizedBox(height: 16),
                                    const NativeAdContainer(),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ScheduledRemindersScreen(),
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.schedule,
                                            color: Colors.lightBlue,
                                            size: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.access_time),
                                            label: Text(
                                              'set_water_reminder'.tr(),
                                            ),
                                            onPressed: () =>
                                                _showTimePickerAndScheduleReminder(
                                                  context,
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          // ElevatedButton.icon(
                                          //   icon: const Icon(
                                          //     Icons.calendar_today,
                                          //   ),
                                          //   label: Text(
                                          //     "set_daily_reminders".tr(),
                                          //   ),
                                          //   onPressed: () async {
                                          //     await _scheduleDailyRemindersFromWakeBed();
                                          //   },
                                          // ),
                                          // const SizedBox(height: 10),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.cancel),
                                            label: Text(
                                              "cancel_all_reminders".tr(),
                                            ),
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                          title: const Text(
                                                            "Cancel All Reminders?",
                                                          ),
                                                          content: Text(
                                                            "cancel_prompt"
                                                                .tr(),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              child: Text(
                                                                "no".tr(),
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                            ),
                                                            TextButton(
                                                              child: Text(
                                                                "yes".tr(),
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                              if (confirm != true) return;
                                              try {
                                                await AwesomeNotifications()
                                                    .cancelAllSchedules();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "All reminders cancelled",
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "failed_to_cancel: $e"
                                                            .tr(),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            bottomNavigationBar: HydrationBottomNavBar(
              currentIndex: 0,
              parentContext: context,
            ),
          ),
        );
      },
    );
  }

  // --- Restore manual scheduling to previous working state ---
  Future<void> _showTimePickerAndScheduleReminder(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;

    final now = DateTime.now();
    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _scheduleHydrationReminder(
      time: picked,
      id: scheduled.millisecondsSinceEpoch.remainder(100000),
      title: 'hydration_reminder_title(S)'.tr(),
      body: 'hydration_reminder_body'.tr(),
      repeatDaily: true, // <-- set to true for daily reminders
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'reminder_set_for'.tr(namedArgs: {'time': picked.format(context)}),
        ),
      ),
    );
  }

  Future<void> _scheduleHydrationReminder({
    required TimeOfDay time,
    int? id,
    String? title,
    String? body,
    bool repeatDaily = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final channelKey =
        prefs.getString('notificationChannel') ?? 'hydration_water';
    final selectedSound = prefs.getString('selectedSound') ?? 'Default';

    // Cancel any existing notification with this id to avoid duplicates
    if (id != null) {
      await AwesomeNotifications().cancelSchedule(id);
    }

    try {
      DateTime newDateTime = DateTime.now();
      newDateTime = DateTime(
        newDateTime.year,
        newDateTime.month,
        newDateTime.day,
        time.hour,
        time.minute,
      );

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: 'hydration_reminder_title(S)'.tr(),
          body: 'hydration_reminder_body'.tr(),
          notificationLayout: NotificationLayout.Default,
          customSound: (selectedSound == 'Default')
              ? null
              : 'resource://raw/${selectedSound.toLowerCase()}',
          payload: {'type': 'manual'},
        ),
        schedule: NotificationCalendar(
          year: newDateTime.year, // <-- set the picked date for manual reminder
          month: newDateTime.month,
          day: newDateTime.day,
          hour: newDateTime.hour,
          minute: newDateTime.minute,
          second: 0,
          millisecond: 0,
          repeats: false, // <-- manual reminders should not repeat
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to schedule reminder: $e")),
        );
      }
    }
  }

  // ignore: unused_element
  // // // Future<void> _scheduleDailyRemindersFromWakeBed() async {
  // // //   final prefs = await SharedPreferences.getInstance();
  // // //   final wakeTimeStr = prefs.getString('wakeTime');
  // // //   final bedTimeStr = prefs.getString('bedTime');
  // // //   if (wakeTimeStr == null || bedTimeStr == null) {
  // // //     ScaffoldMessenger.of(context).showSnackBar(
  // // //       SnackBar(
  // // //         content: Text("set_wakeuptime_and_bedtime_in_settings_first".tr()),
  // // //       ),
  // // //     );
  // // //     return;
  // // //   }

  // //   final wakeTime = _parseTimeOfDay(wakeTimeStr);
  // //   final bedTime = _parseTimeOfDay(bedTimeStr);

  // //   final now = DateTime.now();
  // //   final times = [
  // //     {
  // //       'time': wakeTime,
  // //       'title': 'waking_time_heading'.tr(),
  // //       'body': 'waking_time_body'.tr(),
  // //     },
  // //     {
  // //       'time': bedTime,
  // //       'title': 'bed_time_heading'.tr(),
  // //       'body': 'bed_time_body'.tr(),
  // //     },
  // //   ];

  //   final existing = await AwesomeNotifications().listScheduledNotifications();
  //   bool anyAlreadySet = false;

  //   for (var entry in times) {
  //     final time = entry['time'] as TimeOfDay;
  //     final title = entry['title'] as String;
  //     final body = entry['body'] as String;

  //     DateTime scheduled = DateTime(
  //       now.year,
  //       now.month,
  //       now.day,
  //       time.hour,
  //       time.minute,
  //     );
  //     if (scheduled.isBefore(now)) {
  //       scheduled = scheduled.add(const Duration(days: 1));
  //     }

  //     final alreadyExists = existing.any((n) {
  //       final cal = n.schedule;
  //       return n.content?.payload?['type'] == 'manual' &&
  //           cal is NotificationCalendar &&
  //           cal.year == scheduled.year &&
  //           cal.month == scheduled.month &&
  //           cal.day == scheduled.day &&
  //           cal.hour == scheduled.hour &&
  //           cal.minute == scheduled.minute;
  //     });

  //     if (alreadyExists) {
  //       anyAlreadySet = true;
  //       continue;
  //     }

  //     await AwesomeNotifications().createNotification(
  //       content: NotificationContent(
  //         id: scheduled.millisecondsSinceEpoch.remainder(100000),
  //         channelKey: 'hydration_water',
  //         title: title,
  //         body: body,
  //         notificationLayout: NotificationLayout.Default,
  //         payload: {'type': 'manual'},
  //       ),
  //       schedule: NotificationCalendar(
  //         year: scheduled.year,
  //         month: scheduled.month,
  //         day: scheduled.day,
  //         hour: scheduled.hour,
  //         minute: scheduled.minute,
  //         second: 0,
  //         millisecond: 0,
  //         repeats: false,
  //         timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
  //       ),
  //     );
  //   }

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         anyAlreadySet ? "reminder_already_set".tr() : "reminder_set".tr(),
  //       ),
  //     ),
  //   );
  // }

  // Helper to parse TimeOfDay from string
}

Future<void> requestNotificationPermission() async {
  if (!Platform.isAndroid) return;

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}

Future<void> openExactAlarmPermission() async {
  final intent = AndroidIntent(
    action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  );
  await intent.launch();
}

Future<void> openBatteryOptimizationSettings() async {
  final intent = AndroidIntent(
    action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
    data: 'package:com.example.drink', // Replace with your actual package name
    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  );
  await intent.launch();
}

Future<void> showOptimizationDialog(BuildContext context) async {
  final shouldOpen = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text("allow_background_services".tr()),
      content: Text("background_services_note".tr()),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(false); // Cancel button
          },
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(true); // Open settings
          },
          child: Text('open_settings'.tr()),
        ),
      ],
    ),
  );

  if (shouldOpen == true) {
    await openExactAlarmPermission();
    await Future.delayed(const Duration(seconds: 1));
    await openBatteryOptimizationSettings();
  }
}

Future<void> promptAllStartupPermissionsOnce(BuildContext context) async {
  if (!Platform.isAndroid) return;

  final prefs = await SharedPreferences.getInstance();
  final prompted = prefs.getBool('startupPermissionsPrompted') ?? false;

  if (!prompted) {
    await prefs.setBool(
      'startupPermissionsPrompted',
      true,
    ); // set early to avoid re-show

    // 1. Request notification permission
    await requestNotificationPermission();

    // 2. Wait briefly, then show optimization dialog
    await Future.delayed(const Duration(seconds: 1));
    await showOptimizationDialog(context);
  }
}
