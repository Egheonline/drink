import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'package:drink/genderselection.dart';
import 'package:google_fonts/google_fonts.dart';

class Getstarted extends StatefulWidget {
  final VoidCallback onFinish;

  const Getstarted({super.key, required this.onFinish});

  @override
  State<Getstarted> createState() => _GetstartedState();
}

class _GetstartedState extends State<Getstarted> {
  String _selectedLanguage = 'English';
  String _selectedFlag = '🇺🇸';

  final Map<String, Map<String, dynamic>> languageMap = {
    'English': {'flag': '🇺🇸', 'locale': const Locale('en')},
    'French': {'flag': '🇫🇷', 'locale': const Locale('fr')},
    'Arabic': {'flag': '🇸🇦', 'locale': const Locale('ar')},
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language') ?? 'English';
    setState(() {
      _selectedLanguage = savedLang;
      _selectedFlag = languageMap[savedLang]!['flag'];
    });
    context.setLocale(languageMap[savedLang]!['locale']);
  }

  Future<void> _saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  Future<void> _startOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    // Await the result from GenderSelectionScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
    );

    // Optionally, do something with the result
    if (result != null) {
      // e.g., widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: const Text(""),
          actions: [
            Row(
              children: [
                Text(_selectedFlag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    icon: const Icon(Icons.language),
                    items: languageMap.keys.map((String language) {
                      String langKey = 'language_${language.toLowerCase()}';
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(tr(langKey)),
                      );
                    }).toList(),
                    onChanged: (String? newLanguage) {
                      if (newLanguage != null) {
                        setState(() {
                          _selectedLanguage = newLanguage;
                          _selectedFlag = languageMap[newLanguage]!['flag'];
                        });
                        context.setLocale(languageMap[newLanguage]!['locale']);
                        _saveLanguage(newLanguage);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            /// 🔵 Water Wave Background (fixed color)
            Positioned.fill(
              child: WaveWidget(
                config: CustomConfig(
                  gradients: [
                    [Colors.lightBlueAccent, Colors.blueAccent],
                    [
                      Colors.blue.shade200,
                      const Color.fromARGB(255, 50, 154, 240),
                    ],
                  ],
                  durations: [35000, 19440],
                  heightPercentages: [0.20, 0.23],
                  blur: const MaskFilter.blur(BlurStyle.solid, 5),
                  gradientBegin: Alignment.bottomLeft,
                  gradientEnd: Alignment.topRight,
                ),
                size: const Size(double.infinity, double.infinity),
                waveAmplitude: 0,
              ),
            ),

            /// 🟡 Foreground Content (follows system theme)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "welcome_title".tr(),
                      style: GoogleFonts.roboto(
                        textStyle: theme.textTheme.headlineSmall,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "welcome_desc".tr(),
                      style: GoogleFonts.poppins(
                        textStyle: theme.textTheme.bodyMedium,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.cardColor,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _startOnboarding(context),
                      child: Text(
                        "get_started".tr(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
