import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/migrations.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('gitphoto_db_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('applique les migrations jusqu\'à la dernière version', () {
    final db = AppDatabase.inMemory();
    expect(db.schemaVersion, latestSchemaVersion);
    final tables = db.raw
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((r) => r['name'])
        .toSet();
    expect(
      tables,
      containsAll([
        'preferences',
        'albums',
        'media',
        'repositories',
        'operations',
        'operation_files',
        'transfer_queue',
        'ai_conversations',
        'ai_messages',
      ]),
    );
    db.close();
  });

  test('aucune colonne ne semble destinée à stocker un secret', () {
    final db = AppDatabase.inMemory();
    final tables = db.raw
        .select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((r) => r['name'] as String);
    for (final table in tables) {
      for (final col in db.raw.select('PRAGMA table_info($table)')) {
        final name = (col['name'] as String).toLowerCase();
        expect(
          name,
          isNot(matches(RegExp('token|secret|password|api_key'))),
          reason: '$table.$name',
        );
      }
    }
    db.close();
  });

  test(
    'la réouverture conserve les données et ne rejoue pas les migrations',
    () {
      final path = p.join(tmp.path, 'app.db');
      final first = AppDatabase.open(path);
      PreferencesRepository(first).write('ui.theme_mode', 'dark');
      first.close();

      final second = AppDatabase.open(path);
      expect(second.schemaVersion, latestSchemaVersion);
      expect(PreferencesRepository(second).read('ui.theme_mode'), 'dark');
      expect(second.fileSizeBytes(), greaterThan(0));
      second.close();
    },
  );

  test('applique une nouvelle migration sur une base existante', () {
    final path = p.join(tmp.path, 'upgrade.db');
    AppDatabase.open(path).close();
    final upgraded = AppDatabase.open(
      path,
      migrationList: [
        ...migrations,
        Migration(latestSchemaVersion + 1, [
          'ALTER TABLE albums ADD COLUMN cover_media_id INTEGER',
        ]),
      ],
    );
    expect(upgraded.schemaVersion, latestSchemaVersion + 1);
    final cols = upgraded.raw
        .select('PRAGMA table_info(albums)')
        .map((r) => r['name']);
    expect(cols, contains('cover_media_id'));
    upgraded.close();
  });

  test('une migration en échec est annulée entièrement', () {
    final path = p.join(tmp.path, 'rollback.db');
    AppDatabase.open(path).close();
    expect(
      () => AppDatabase.open(
        path,
        migrationList: [
          ...migrations,
          Migration(latestSchemaVersion + 1, [
            'CREATE TABLE extra (id INTEGER)',
            'INSTRUCTION SQL INVALIDE',
          ]),
        ],
      ),
      throwsA(anything),
    );
    final db = AppDatabase.open(path);
    expect(db.schemaVersion, latestSchemaVersion);
    expect(
      db.raw.select("SELECT name FROM sqlite_master WHERE name = 'extra'"),
      isEmpty,
    );
    db.close();
  });

  test('refuse une base issue d\'une version plus récente', () {
    final path = p.join(tmp.path, 'future.db');
    final db = AppDatabase.open(path);
    db.raw.userVersion = latestSchemaVersion + 5;
    db.close();
    expect(() => AppDatabase.open(path), throwsStateError);
  });

  test('sauvegarde sans jamais écraser un fichier existant', () {
    final db = AppDatabase.open(p.join(tmp.path, 'src.db'));
    PreferencesRepository(db).write('k', 'v');
    final backup = p.join(tmp.path, 'backup.db');
    db.backupTo(backup);
    expect(() => db.backupTo(backup), throwsA(isA<FileSystemException>()));
    db.close();

    final restored = AppDatabase.open(backup);
    expect(PreferencesRepository(restored).read('k'), 'v');
    restored.close();
  });

  test('préférences : écriture, mise à jour, lecture globale', () {
    final db = AppDatabase.inMemory();
    final prefs = PreferencesRepository(db);
    expect(prefs.read('absent'), isNull);
    prefs.write('a', '1');
    prefs.write('a', '2');
    prefs.write('b', '3');
    expect(prefs.readAll(), {'a': '2', 'b': '3'});
    db.close();
  });

  test(
    'la file d\'attente refuse deux transferts de même clé d\'idempotence',
    () {
      final db = AppDatabase.inMemory();
      const sql =
          'INSERT INTO transfer_queue(idempotency_key, remote_path, '
          'strategy, status, created_at, updated_at) VALUES(?, ?, ?, ?, 0, 0)';
      db.raw.execute(sql, ['k1', 'a.jpg', 'githubApi', 'pending']);
      expect(
        () => db.raw.execute(sql, ['k1', 'a.jpg', 'githubApi', 'pending']),
        throwsA(anything),
      );
      expect(db.count('transfer_queue'), 1);
      db.close();
    },
  );

  test('mise à niveau v4 → v5 : file existante conservée, colonne ajoutée', () {
    final path = p.join(tmp.path, 'v4.db');
    final v4 = AppDatabase.open(
      path,
      migrationList: migrations.take(4).toList(),
    );
    expect(v4.schemaVersion, 4);
    v4.raw.execute(
      'INSERT INTO transfer_queue(idempotency_key, remote_path, strategy, '
      "status, created_at, updated_at) VALUES('k', 'a.jpg', 'githubApi', "
      "'pending', 0, 0)",
    );
    v4.close();

    final v5 = AppDatabase.open(path);
    expect(v5.schemaVersion, latestSchemaVersion);
    final row = v5.raw
        .select('SELECT remote_path, local_path FROM transfer_queue')
        .single;
    expect(row['remote_path'], 'a.jpg');
    expect(row['local_path'], isNull);
    v5.close();
  });
}
