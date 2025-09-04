import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drink/theme_provider.dart';
import 'package:drink/getstarted.dart';
import 'package:drink/genderselection.dart';
import 'package:drink/weightinput.dart';
import 'package:drink/wakeuptime.dart';
import 'package:drink/bedtimescreen.dart';
import 'package:drink/hydration_screen.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  bool _navigated = false;
  String splashText = "HydratePal";
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });

    // Safety fallback: navigate even if animation fails
    Future.delayed(const Duration(seconds: 6), () {
      if (!_navigated && _initialized) _onLottieComplete();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/splash_text.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final locale = Localizations.localeOf(context).languageCode;
      final localizedText = jsonMap[locale] ?? jsonMap['en'] ?? "HydratePal";

      if (mounted) {
        setState(() {
          splashText = localizedText;
          _initialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          splashText = "HydratePal";
          _initialized = true;
        });
      }
    }
  }

  Future<void> _onLottieComplete() async {
    if (_navigated || !_initialized) return;
    _navigated = true;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

    Widget nextScreen;
    if (!onboardingComplete) {
      nextScreen = Getstarted(
        onFinish: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HydrationScreen()),
          );
        },
      );
    } else {
      final gender = prefs.getString('gender');
      final weight = prefs.getInt('weight');
      final wakeTime = prefs.getString('wakeTime');
      final bedTime = prefs.getString('bedTime');

      if (gender == null) {
        nextScreen = const GenderSelectionScreen();
      } else if (weight == null) {
        nextScreen = const WeightInputScreen();
      } else if (wakeTime == null) {
        nextScreen = const TimeSelectionScreen();
      } else if (bedTime == null) {
        nextScreen = const BedTimeScreen();
      } else {
        nextScreen = const HydrationScreen();
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/cup.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                Future.delayed(composition.duration, () {
                  if (_initialized) {
                    _onLottieComplete();
                  } else {
                    Future.delayed(
                      const Duration(milliseconds: 800),
                      _onLottieComplete,
                    );
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              splashText,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.lightBlue[100]
                    : Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
