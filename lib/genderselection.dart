import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weightinput.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? _gender;

  void _choose(String gender) {
    setState(() => _gender = gender);
  }

  void _next() async {
    if (_gender != null) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('gender', _gender!);

      int weight = prefs.getInt('weight') ?? 70;
      await prefs.setInt('weight', weight);

      int goalIntake = _calculateGoalIntake(weight, _gender!);
      await prefs.setInt('goalIntake', goalIntake);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeightInputScreen()),
      );
    }
  }

  int _calculateGoalIntake(int weightKg, String gender) {
    int base = weightKg * 35;
    if (gender == 'Male') return base + 1000;
    if (gender == 'Pregnant Woman') return base + 500;
    if (gender == 'Breastfeeding Mother') return base + 800;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'select_gender'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            // ✅ Watermark background image
            Positioned.fill(
              child: Opacity(
                opacity: 0.07,
                child: Image.asset('assets/drink_icon.png', fit: BoxFit.cover),
              ),
            ),
            // ✅ Foreground content
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _genderOption(
                            icon: Icons.man,
                            label: 'is_male'.tr(),
                            value: 'Male',
                            activeColor: Colors.blue,
                          ),
                          _genderOption(
                            icon: Icons.woman,
                            label: 'is_female'.tr(),
                            value: 'Female',
                            activeColor: Colors.pink,
                          ),
                          _genderOption(
                            icon: Icons.pregnant_woman,
                            label: 'pregnant_woman'.tr(),
                            value: 'Pregnant Woman',
                            activeColor: Colors.orange,
                          ),
                          _genderOption(
                            icon: Icons.child_friendly,
                            label: 'breast_feeding'.tr(),
                            value: 'Breastfeeding Mother',
                            activeColor: Colors.green,
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _gender == null ? null : _next,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('next'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderOption({
    required IconData icon,
    required String label,
    required String value,
    required Color activeColor,
  }) {
    final isSelected = _gender == value;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? activeColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          size: 40,
          color: isSelected ? activeColor : Colors.grey,
        ),
        title: Text(label),
        onTap: () => _choose(value),
      ),
    );
  }
}
