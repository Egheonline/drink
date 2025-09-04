import 'package:flutter/material.dart';
import '../../hydration_screen.dart';
import '../../hydrationvisualizerscreen.dart';

class HydrationBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final BuildContext parentContext;

  const HydrationBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.parentContext,
  });

  void _onTap(int index) {
    if (index == currentIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        parentContext,
        MaterialPageRoute(builder: (_) => const HydrationVisualizerScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        parentContext,
        MaterialPageRoute(builder: (_) => const HydrationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: _onTap,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop, size: 30),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_drink, size: 28),
          label: '',
        ),
      ],
    );
  }
}
