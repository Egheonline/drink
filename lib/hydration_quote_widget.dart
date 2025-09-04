import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HydrationQuoteWidget extends StatefulWidget {
  const HydrationQuoteWidget({super.key});

  @override
  State<HydrationQuoteWidget> createState() => _HydrationQuoteWidgetState();
}

class _HydrationQuoteWidgetState extends State<HydrationQuoteWidget> {
  late String _currentKey;
  final List<String> _quoteKeys = [
    "quote_1",
    "quote_2",
    "quote_3",
    "quote_4",
    "quote_5",
    "quote_6",
    "quote_7",
    "quote_8",
    "quote_9",
    "quote_10",
  ];

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentKey = _quoteKeys[Random().nextInt(_quoteKeys.length)];

    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      setState(() {
        _currentKey = _quoteKeys[Random().nextInt(_quoteKeys.length)];
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        _currentKey.tr(),
        key: ValueKey<String>(_currentKey),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          fontSize: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
