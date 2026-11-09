import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'migrations.dart';

/// Accès à la base SQLite locale de l'application.
class AppDatabase {
  AppDatabase._(this._db, this.path);

  /// Ouvre (ou crée) la base au chemin donné et applique les migrations.
  factory AppDatabase.open(String path, {List<Migration>? migrationList}) {
    final db = sqlite3.open(path);
    return AppDatabase._(db, path).._prepare(migrationList ?? migrations);
  }

  /// Base en mémoire, réservée aux tests.
  factory AppDatabase.inMemory({List<Migration>? migrationList}) {
    final db = sqlite3.openInMemory();
    return AppDatabase._(db, null).._prepare(migrationList ?? migrations);
  }

  final Database _db;

  /// Chemin du fichier, `null` pour une base en mémoire.
  final String? path;

  Database get raw => _db;

  int get schemaVersion => _db.userVersion;

  void _prepare(List<Migration> migrationList) {
    _db.execute('PRAGMA foreign_keys = ON');
    _migrate(migrationList);
  }

  void _migrate(List<Migration> migrationList) {
    final current = _db.userVersion;
    final latest = migrationList.isEmpty ? 0 : migrationList.last.version;
    if (current > latest) {
      throw StateError(
        'La base locale (schéma v$current) provient d\'une version plus '
        'récente de l\'application (schéma v$latest).',
      );
    }
    for (final migration in migrationList) {
      if (migration.version <= current) continue;
      _db.execute('BEGIN');
      try {
        for (final statement in migration.statements) {
          _db.execute(statement);
        }
        _db.userVersion = migration.version;
        _db.execute('COMMIT');
      } catch (_) {
        _db.execute('ROLLBACK');
        rethrow;
      }
    }
  }

  /// Taille du fichier de base sur le disque, en octets.
  int fileSizeBytes() {
    final p = path;
    if (p == null) return 0;
    final file = File(p);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  /// Sauvegarde cohérente de la base vers [destinationPath].
  ///
  /// Le fichier de destination ne doit pas exister : aucune sauvegarde
  /// existante n'est écrasée.
  void backupTo(String destinationPath) {
    if (File(destinationPath).existsSync()) {
      throw FileSystemException(
        'Le fichier de sauvegarde existe déjà',
        destinationPath,
      );
    }
    _db.execute('VACUUM INTO ?', [destinationPath]);
  }

  int count(String table, {String? where, List<Object?> args = const []}) {
    final sql = StringBuffer('SELECT COUNT(*) AS n FROM $table');
    if (where != null) sql.write(' WHERE $where');
    return _db.select(sql.toString(), args).first['n'] as int;
  }

  void close() => _db.close();
}
