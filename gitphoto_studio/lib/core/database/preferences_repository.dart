import 'app_database.dart';

/// Préférences non sensibles stockées dans SQLite.
///
/// Ne jamais y enregistrer de jeton, mot de passe ou clé API.
class PreferencesRepository {
  PreferencesRepository(this._database);

  final AppDatabase _database;

  String? read(String key) {
    final rows = _database.raw.select(
      'SELECT value FROM preferences WHERE key = ?',
      [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  void write(String key, String value) {
    _database.raw.execute(
      'INSERT INTO preferences(key, value) VALUES(?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }

  Map<String, String> readAll() {
    final rows = _database.raw.select(
      'SELECT key, value FROM preferences ORDER BY key',
    );
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }
}

abstract final class PreferenceKeys {
  static const themeMode = 'ui.theme_mode';
  static const locale = 'ui.locale';
}
