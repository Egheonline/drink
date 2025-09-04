// notification_router_screen.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:drink/hydration_screen.dart';
// import other screens if needed

class NotificationRouterScreen extends StatelessWidget {
  final ReceivedAction? action;
  const NotificationRouterScreen({super.key, this.action});

  @override
  Widget build(BuildContext context) {
    // Decide which screen to show based on payload or other data
    return HydrationScreen(); // or VisualizationScreen
  }
}
