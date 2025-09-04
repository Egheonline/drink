import 'package:drink/hydration_quote_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:drink/theme_provider.dart';
import 'package:drink/lib/utils/sound_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:drink/utils/reminder_utils.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String? wakeUpTime, bedTime, gender;
  int? weightKg, goalIntakeMl;
  String weightUnit = 'kg';
  String intakeUnit = 'ml';

  String _selectedFlag = '🇺🇸';
  final TextEditingController _donationController = TextEditingController();
  String _selectedCurrency = 'USD';
  final List<String> _currencies = ['USD', 'EUR', 'NGN'];

  List<String> availableSounds = [
    'Default',
    'Water',
    'Bell',
    'Chime',
    'Custom',
  ];
  String? selectedSound;

  final Map<String, Map<String, dynamic>> languageMap = {
    'English': {'flag': '🇺🇸', 'locale': const Locale('en')},
    'French': {'flag': '🇫🇷', 'locale': const Locale('fr')},
    'Arabic': {'flag': '🇸🇦', 'locale': const Locale('ar')},
  };

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _loadSavedLanguage();
    _loadSelectedSound();
    _loadLastDonation();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language') ?? 'English';
    setState(() {
      _selectedFlag = languageMap[savedLang]!['flag'];
    });
    context.setLocale(languageMap[savedLang]!['locale']);
  }

  Future<void> _saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  Future<void> _loadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWeight = prefs.getInt('weight') ?? 70;
    final savedGoal = prefs.getInt('goalIntake');
    final savedGender = prefs.getString('gender');

    setState(() {
      wakeUpTime = prefs.getString('wakeTime');
      bedTime = prefs.getString('bedTime');
      gender = savedGender;
      weightKg = savedWeight;
      weightUnit = prefs.getString('weightUnit') ?? 'kg';
      intakeUnit = prefs.getString('intakeUnit') ?? 'ml';
      goalIntakeMl =
          savedGoal ?? _calculateGoalIntake(savedWeight, savedGender);
    });
  }

  int _calculateGoalIntake(int weightKg, String? gender) {
    int base = weightKg * 35;
    if (gender == 'Male') return base + 1000;
    if (gender == 'Pregnant Woman') return base + 500;
    if (gender == 'Breastfeeding Mother') return base + 800;
    return base;
  }

  String _formattedWeight() {
    if (weightKg == null) return 'Not set';
    if (weightUnit == 'kg') return '$weightKg kg';
    final lbs = weightKg! * 2.20462;
    return '${lbs.toStringAsFixed(1)} lbs';
  }

  String _formattedIntake() {
    if (goalIntakeMl == null) return 'Not set';
    if (intakeUnit == 'ml') return '$goalIntakeMl ml';
    final flOz = goalIntakeMl! * 0.033814;
    return '${flOz.toStringAsFixed(1)} fl oz';
  }

  Future<void> _loadLastDonation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _donationController.text = prefs.getString('lastDonation') ?? '';
      _selectedCurrency = prefs.getString('donationCurrency') ?? 'USD';
    });
  }

  Future<void> _saveLastDonation(String amount, String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDonation', amount);
    await prefs.setString('donationCurrency', currency);
  }

  Future<void> _donateViaPayPal() async {
    final amount = _donationController.text.trim();
    final double? parsedAmount = double.tryParse(amount);

    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("invalid_donation").tr()));
      return;
    }

    await _saveLastDonation(amount, _selectedCurrency);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayPalWebView(
          amount: _donationController.text.trim(),
          currency: _selectedCurrency,
        ),
      ),
    );
  }

  Future<void> _pickTime(String key) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final formatted = picked.format(context);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        formatted,
      ); // <-- key should match 'wakeTime' or 'bedTime'
      setState(() {
        if (key == 'wakeTime') wakeUpTime = formatted;
        if (key == 'bedTime') bedTime = formatted;
      });
    }
  }

  Future<void> _pickCustomSound() async {
    final selected = await SoundManager.pickAndSaveCustomSound();
    if (selected != null) {
      setState(() => selectedSound = selected);
      await _saveSelectedSound(
        'Custom',
      ); // This can just save, no need to play again
    }
  }

  Future<void> _loadSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSound = prefs.getString('selectedSound') ?? 'Default';
    });
  }

  Future<void> _saveSelectedSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();

    final soundChannelMap = {
      'Default': 'hydration_water',
      'Water': 'hydration_water',
      'Bell': 'hydration_bell',
      'Chime': 'hydration_chime',
      'Custom': 'hydration_custom',
    };

    final previewAssetMap = {
      'Water': 'assets/water.mp3',
      'Bell': 'assets/bell.mp3',
      'Chime': 'assets/chime.mp3',
    };

    final selectedChannel = soundChannelMap[sound] ?? 'hydration_water';
    final previewAsset = previewAssetMap[sound];

    await prefs.setString('notificationChannel', selectedChannel);
    await prefs.setString('selectedSound', sound);

    setState(() {
      selectedSound = sound;
    });

    if (sound == 'Custom') {
      await SoundManager.playSelected('Custom');
    } else if (previewAsset != null) {
      await SoundManager.playSelected(sound);
    }

    // Cancel and reschedule all automatic reminders
    await ReminderUtils.reschedulePreservingManualIfNeeded();
  }

  Future<void> _editNumberDialog({
    required String title,
    required int? currentValue,
    required ValueChanged<int> onSaved,
    String? unit,
  }) async {
    final controller = TextEditingController(
      text: currentValue?.toString() ?? '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: '$title (${unit ?? ''})'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      onSaved(result);
    }
  }

  Future<void> _showGenderDialog() async {
    final genders = [
      'is_male'.tr(),
      'is_female'.tr(),
      'pregnant_woman'.tr(),
      'breast_feeding'.tr(),
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('select_gender').tr(),
        children: genders
            .map(
              (g) => RadioListTile<String>(
                value: g,
                groupValue: gender,
                title: Text(g),
                onChanged: (val) {
                  Navigator.pop(context, val);
                },
              ),
            )
            .toList(),
      ),
    );

    if (selected != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gender', selected);
      final newGoal = weightKg != null
          ? _calculateGoalIntake(weightKg!, selected)
          : null;

      setState(() {
        gender = selected;
        if (newGoal != null) goalIntakeMl = newGoal;
      });

      if (newGoal != null) {
        await prefs.setInt('goalIntake', newGoal);
      }
    }
  }

  Future<void> _resetInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      wakeUpTime = null;
      bedTime = null;
      gender = null;
      weightKg = null;
      goalIntakeMl = null;
      weightUnit = 'kg';
      intakeUnit = 'ml';
    });

    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('restart_required').tr(),
        content: const Text('reset_app').tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('cancel').tr(),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('restart').tr(),
          ),
        ],
      ),
    );

    if (shouldRestart == true) {
      SchedulerBinding.instance.addPostFrameCallback((_) => exit(0));
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('privacy_policy').tr(),
        content: const Text('privacy_policy_content').tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('user_info'),
          style: TextStyle(
            fontWeight: FontWeight.w600, // <-- Make main title bold
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip),
            onPressed: _showPrivacyPolicy,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 🔻 Hydration quote (moved to the top)
              const HydrationQuoteWidget(),

              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: Text(
                  tr('wake_time'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, // <-- Bold subheading
                  ),
                ),
                subtitle: Text(wakeUpTime ?? 'Not set'),
                onTap: () => _pickTime('wakeTime'), // <-- use 'wakeTime'
              ),
              ListTile(
                leading: const Icon(Icons.nights_stay),
                title: Text(
                  tr('bed_time'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, // <-- Bold subheading
                  ),
                ),
                subtitle: Text(bedTime ?? 'Not set'),
                onTap: () => _pickTime('bedTime'), // <-- use 'bedTime'
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  tr('gender'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, // <-- Bold subheading
                  ),
                ),
                subtitle: Text(gender ?? 'Not set'),
                onTap: _showGenderDialog,
              ),
              ListTile(
                leading: const Icon(Icons.monitor_weight),
                title: Text(
                  tr('weight'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, // <-- Bold subheading
                  ),
                ),
                subtitle: Text(_formattedWeight()),
                onTap: () => _editNumberDialog(
                  title: 'Weight',
                  currentValue: weightUnit == 'kg'
                      ? weightKg
                      : weightKg != null
                      ? (weightKg! * 2.20462).round()
                      : null,
                  unit: weightUnit,
                  onSaved: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    final newWeightKg = weightUnit == 'kg'
                        ? value
                        : (value / 2.20462).round();
                    final newGoalMl = _calculateGoalIntake(newWeightKg, gender);
                    setState(() {
                      weightKg = newWeightKg;
                      goalIntakeMl = newGoalMl;
                    });
                    await prefs.setInt('weight', newWeightKg);
                    await prefs.setInt('goalIntake', newGoalMl);
                  },
                ),
                trailing: DropdownButton<String>(
                  value: weightUnit,
                  items: ['kg', 'lbs']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (newUnit) async {
                    final prefs = await SharedPreferences.getInstance();
                    if (newUnit != null && newUnit != weightUnit) {
                      setState(() => weightUnit = newUnit);
                      await prefs.setString('weightUnit', newUnit);
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.local_drink),
                title: Text(
                  tr('goal_intake'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, // <-- Bold subheading
                  ),
                ),
                subtitle: Text(_formattedIntake()),
                onTap: () => _editNumberDialog(
                  title: 'goal_intake'.tr(),
                  currentValue: intakeUnit == 'ml'
                      ? goalIntakeMl
                      : goalIntakeMl != null
                      ? (goalIntakeMl! * 0.033814).round()
                      : null,
                  unit: intakeUnit,
                  onSaved: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    final intakeMl = intakeUnit == 'ml'
                        ? value
                        : (value / 0.033814).round();
                    setState(() => goalIntakeMl = intakeMl);
                    await prefs.setInt('goalIntake', intakeMl);
                  },
                ),
                trailing: DropdownButton<String>(
                  value: intakeUnit,
                  items: ['ml', 'fl oz']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (newUnit) async {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() => intakeUnit = newUnit!);
                    await prefs.setString('intakeUnit', newUnit!);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(
                  tr('notification_sound'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, // <-- Bold subheading
                  ),
                ),
                subtitle: Text(selectedSound ?? 'Default'),
                onTap: () async {
                  final chosen = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('choose_sound').tr(),
                      children: [
                        ...availableSounds.map(
                          (sound) => SimpleDialogOption(
                            child: Text(sound),
                            onPressed: () => Navigator.pop(context, sound),
                          ),
                        ),
                        const Divider(),
                        SimpleDialogOption(
                          child: Row(
                            children: [
                              const Icon(Icons.add),
                              const SizedBox(width: 8),
                              Text('add_from_device').tr(),
                            ],
                          ),
                          onPressed: () =>
                              Navigator.pop(context, 'add_from_device'),
                        ),
                      ],
                    ),
                  );
                  if (chosen == 'add_from_device') {
                    await _pickCustomSound();
                  } else if (chosen != null &&
                      availableSounds.contains(chosen)) {
                    await _saveSelectedSound(chosen);
                  }
                },
              ),

              ListTile(
                leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                title: Text(
                  tr('theme'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(() {
                  switch (themeProvider.appThemeMode) {
                    case AppThemeMode.auto:
                      return tr('auto');
                    case AppThemeMode.dark:
                      return tr('dark');
                    case AppThemeMode.light:
                      return tr('light');
                  }
                }(), style: Theme.of(context).textTheme.bodySmall),
                onTap: () async {
                  final selected = await showDialog<AppThemeMode>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: Text(tr('choose_theme')),
                      children: [
                        RadioListTile<AppThemeMode>(
                          value: AppThemeMode.auto,
                          groupValue: themeProvider.appThemeMode,
                          title: Text(tr('auto')),
                          onChanged: (val) => Navigator.pop(context, val),
                        ),
                        RadioListTile<AppThemeMode>(
                          value: AppThemeMode.light,
                          groupValue: themeProvider.appThemeMode,
                          title: Text(tr('light')),
                          onChanged: (val) => Navigator.pop(context, val),
                        ),
                        RadioListTile<AppThemeMode>(
                          value: AppThemeMode.dark,
                          groupValue: themeProvider.appThemeMode,
                          title: Text(tr('dark')),
                          onChanged: (val) => Navigator.pop(context, val),
                        ),
                      ],
                    ),
                  );

                  if (selected != null) {
                    await themeProvider.setThemeMode(selected);
                  }
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('reset_all_info').tr(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: _resetInfo,
              ),
              const SizedBox(height: 24),

              // 🔻 Donation Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr("support_water_project"),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _donationController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: tr("donation_amount"),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          items: _currencies
                              .map(
                                (cur) => DropdownMenuItem(
                                  value: cur,
                                  child: Text(cur),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCurrency = val);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: tr("currency"),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.favorite),
                      label: Text(tr("donate")),
                      onPressed: _donateViaPayPal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 16, // <-- changed from right: 16 to left: 16
            child: FloatingActionButton.extended(
              onPressed: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('select_language').tr(),
                    children: languageMap.keys.map((lang) {
                      String langKey = 'language_${lang.toLowerCase()}';
                      return SimpleDialogOption(
                        child: Text(
                          '${languageMap[lang]!['flag']} ${tr(langKey)}',
                        ),
                        onPressed: () => Navigator.pop(context, lang),
                      );
                    }).toList(),
                  ),
                );

                if (selected != null) {
                  // ignore: unused_local_variable
                  final prefs = await SharedPreferences.getInstance();
                  setState(
                    () => _selectedFlag = languageMap[selected]!['flag'],
                  );

                  // Set locale
                  await context.setLocale(languageMap[selected]!['locale']);

                  // Save language selection
                  await _saveLanguage(selected);

                  await ReminderUtils.reschedulePreservingManualIfNeeded();
                }
              },

              label: Text(_selectedFlag),
              icon: const Icon(Icons.language),
            ),
          ),
        ],
      ),
    );
  }
}

class PayPalWebView extends StatefulWidget {
  final String amount;
  final String currency;

  const PayPalWebView({
    super.key,
    required this.amount,
    required this.currency,
  });

  @override
  State<PayPalWebView> createState() => _PayPalWebViewState();
}

class _PayPalWebViewState extends State<PayPalWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final String url = "https://paypal.me/HydratePal/${widget.amount}";
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donate via PayPal")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
