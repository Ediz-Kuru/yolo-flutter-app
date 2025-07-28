import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/l10n/app_localizations.dart';

class AppRoutes {
  static const String mainPage = '/';
  static const String singleImagePage = '/single-image';
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.onPrimaryContainer,
                  child: ClipOval(
                    child: Image.asset(
                      fit: BoxFit.cover,
                      'assets/img.png'
                          '',
                      width: 64,
                      height: 64,
                    ),
                  ),
                  // child: Icon(Icons.sunny, size: 40, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  AppLocalizations.of(context)!.leafDetectorTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.camera,
                  label: AppLocalizations.of(context)!.detector,
                  selected: currentRoute == AppRoutes.mainPage,
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.mainPage));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.image,
                  label: AppLocalizations.of(context)!.singleImageDetectionTitle,
                  selected: currentRoute == AppRoutes.singleImagePage,
                  onTap: () {
                    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.mainPage));
                    Navigator.pushNamed(context, AppRoutes.singleImagePage);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required bool selected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    final bool isDisabled = selected; // disable tap when selected

    // Use onSurface with alpha for disabled color
    final Color disabledColor = theme.colorScheme.onSurface.withAlpha((0.38 * 255).round());

    final Color iconColor = isDisabled ? disabledColor : theme.colorScheme.primary;
    final Color textColor = isDisabled ? disabledColor : theme.colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: textColor,
        ),
      ),
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withAlpha((0.12 * 255).round()),
      hoverColor: theme.colorScheme.primary.withAlpha((0.08 * 255).round()),
      onTap: isDisabled ? null : onTap,
    );
  }


}
