import 'package:drink/wakeuptime.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:drink/theme_provider.dart';

class WeightInputScreen extends StatefulWidget {
  const WeightInputScreen({super.key});

  @override
  _WeightInputScreenState createState() => _WeightInputScreenState();
}

class _WeightInputScreenState extends State<WeightInputScreen> {
  String _weightUnit = 'kg';
  double _weight = 70;

  @override
  void initState() {
    super.initState();
    _loadWeightUnit();
  }

  Future<void> _loadWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weightUnit = prefs.getString('weightUnit') ?? 'kg';
      _weight = _weightUnit == 'kg' ? 70 : 154;
    });
  }

  Future<void> _setWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    double newWeight = _weight;

    if (unit != _weightUnit) {
      if (unit == 'kg') {
        newWeight = (_weight / 2.20462).clamp(30, 150);
      } else {
        newWeight = (_weight * 2.20462).clamp(66, 330);
      }
    }

    await prefs.setString('weightUnit', unit);
    setState(() {
      _weightUnit = unit;
      _weight = newWeight;
    });
  }

  void _next() async {
    final prefs = await SharedPreferences.getInstance();
    final weightInKg = _weightUnit == 'kg' ? _weight : (_weight / 2.20462);
    final gender = prefs.getString('gender');
    final goalIntake = _calculateGoalIntake(weightInKg.round(), gender);

    await prefs.setInt('weight', weightInKg.round());
    await prefs.setString('weightUnit', _weightUnit);
    await prefs.setInt('goalIntake', goalIntake);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimeSelectionScreen()),
    );
  }

  int _calculateGoalIntake(int weightKg, String? gender) {
    int base = weightKg * 35;
    if (gender == 'Male') return base + 1000;
    if (gender == 'Pregnant Woman') return base + 500;
    if (gender == 'Breastfeeding Mother') return base + 800;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'your_weight'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ✅ Watermark background image fills the screen
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "unit",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ).tr(),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: _weightUnit,
                            underline: Container(
                              height: 1,
                              color: theme.colorScheme.primary,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'kg', child: Text('kg')),
                              DropdownMenuItem(
                                value: 'lbs',
                                child: Text('lbs'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) _setWeightUnit(value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_weight.toInt()} $_weightUnit',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: isDark
                              ? Colors.lightBlue[100]
                              : theme.textTheme.headlineMedium?.color,
                        ),
                      ),
                      Slider(
                        min: _weightUnit == 'kg' ? 30 : 66,
                        max: _weightUnit == 'kg' ? 150 : 330,
                        value: _weight,
                        label: '${_weight.toInt()} $_weightUnit',
                        onChanged: (v) => setState(() => _weight = v),
                        activeColor: theme.colorScheme.primary,
                        inactiveColor: theme.disabledColor.withOpacity(0.3),
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
                    style: ElevatedButton.styleFrom(),
                    onPressed: _next,
                    child: Text('next'.tr()),
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
