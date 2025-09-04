import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class CelebrationConfetti extends StatelessWidget {
  final ConfettiController controller;
  const CelebrationConfetti({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirectionality: BlastDirectionality.explosive,
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
    );
  }
}
