import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hydrationvisualizerscreen.dart';
import 'package:provider/provider.dart';
import 'package:drink/theme_provider.dart';

class BedTimeScreen extends StatefulWidget {
  const BedTimeScreen({super.key});

  @override
  _BedTimeScreenState createState() => _BedTimeScreenState();
}

class _BedTimeScreenState extends State<BedTimeScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 22, minute: 0);

  void _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.scaffoldBackgroundColor,
              hourMinuteTextColor: theme.colorScheme.primary,
              dayPeriodTextColor: theme.colorScheme.primary,
              dialHandColor: theme.colorScheme.primary,
              entryModeIconColor: theme.colorScheme.primary,
            ),
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: theme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bedTime', _selectedTime.format(context));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HydrationVisualizerScreen(onThemeChanged: (theme) {}),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'select_bed_time'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ✅ Background image as watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Image.asset('assets/drink_icon.png', fit: BoxFit.cover),
            ),
          ),
          // ✅ Foreground content fills the screen
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'bed_time_with_value'.tr(
                          namedArgs: {'time': _selectedTime.format(context)},
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: isDark
                              ? Colors.lightBlue[100]
                              : theme.textTheme.headlineSmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _pickTime,
                          child: Text('choose_time'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _finish,
                    child: Text('finish_setup'.tr()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
