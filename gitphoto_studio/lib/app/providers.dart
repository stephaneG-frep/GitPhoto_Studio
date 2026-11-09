import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/database/preferences_repository.dart';
import '../core/logging/app_logger.dart';
import '../core/platform/tool_probe.dart';

/// Base ouverte au démarrage (voir `main.dart`) ; remplacée dans les tests.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider doit être fourni'),
);

final preferencesProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(ref.watch(appDatabaseProvider)),
);

final loggerProvider = Provider<AppLogger>((ref) => AppLogger());

final toolProbeProvider = Provider<ToolProbe>((ref) => ToolProbe());

/// Pas de nouvelle tentative automatique : l'utilisateur relance lui-même
/// la détection depuis l'écran de diagnostic.
final toolAvailabilityProvider = FutureProvider<ToolAvailability>(
  (ref) => ref.watch(toolProbeProvider).probe(),
  retry: (retryCount, error) => null,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref
        .watch(preferencesProvider)
        .read(PreferenceKeys.themeMode);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  void set(ThemeMode mode) {
    ref.read(preferencesProvider).write(PreferenceKeys.themeMode, mode.name);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Langues proposées ; le français est la langue par défaut.
const supportedLanguageCodes = ['fr', 'en'];

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final stored = ref.watch(preferencesProvider).read(PreferenceKeys.locale);
    return Locale(supportedLanguageCodes.contains(stored) ? stored! : 'fr');
  }

  void set(Locale locale) {
    ref
        .read(preferencesProvider)
        .write(PreferenceKeys.locale, locale.languageCode);
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
