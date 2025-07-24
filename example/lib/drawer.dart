// drawer.dart
import 'package:flutter/material.dart';
// Define route names for clarity and maintainability
class AppRoutes {
  static const String mainPage = '/'; // Or '/main' if you have a splash screen, etc.
  static const String waqiPage = '/waqi';
  static const String singleImagePage = '/single-image';
// Add other routes here
// static const String settingsPage = '/settings';
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Drawer Header'),
          ),
          ListTile(
            enabled: currentRoute != AppRoutes.mainPage,
            title: const Text('Detector'),
            onTap: () {
              // Update the state of the app.
              Navigator.popUntil(context, ModalRoute.withName(AppRoutes.mainPage));              // ...
            },
          ),
          ListTile(
            enabled: currentRoute != AppRoutes.singleImagePage,
            title: const Text('Single Image Detection'),
            onTap: () {
              Navigator.popUntil(context, ModalRoute.withName(AppRoutes.mainPage));
              Navigator.pushNamed(context, AppRoutes.singleImagePage);},
          ),
          ListTile(
            enabled: currentRoute != AppRoutes.waqiPage,
            title: const Text('Air Quality'),
            onTap: () {
              Navigator.popUntil(context, ModalRoute.withName(AppRoutes.mainPage));
              Navigator.pushNamed(context, AppRoutes.waqiPage);
            },
          ),
        ],
      ),
    );
  }
}
