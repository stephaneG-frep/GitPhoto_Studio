import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Les neuf écrans de l'application, dans l'ordre du menu.
enum AppDestination {
  dashboard('/', Icons.space_dashboard_outlined, Icons.space_dashboard),
  gallery('/gallery', Icons.photo_library_outlined, Icons.photo_library),
  editor('/editor', Icons.auto_fix_high_outlined, Icons.auto_fix_high),
  github('/github', Icons.hub_outlined, Icons.hub),
  publish('/publish', Icons.cloud_upload_outlined, Icons.cloud_upload),
  agent('/agent', Icons.smart_toy_outlined, Icons.smart_toy),
  history('/history', Icons.history_outlined, Icons.history),
  settings('/settings', Icons.settings_outlined, Icons.settings),
  help('/help', Icons.menu_book_outlined, Icons.menu_book);

  const AppDestination(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// Destinations de la barre inférieure sur téléphone ; les autres sont
  /// accessibles par l'entrée « Plus ».
  static const primary = [dashboard, gallery, publish, agent];

  String label(AppLocalizations l10n) => switch (this) {
    dashboard => l10n.navDashboard,
    gallery => l10n.navGallery,
    editor => l10n.navEditor,
    github => l10n.navGithub,
    publish => l10n.navPublish,
    agent => l10n.navAgent,
    history => l10n.navHistory,
    settings => l10n.navSettings,
    help => l10n.navHelp,
  };

  static AppDestination fromLocation(String location) {
    for (final d in values) {
      if (d != dashboard &&
          (location == d.path || location.startsWith('${d.path}/'))) {
        return d;
      }
    }
    return dashboard;
  }
}
