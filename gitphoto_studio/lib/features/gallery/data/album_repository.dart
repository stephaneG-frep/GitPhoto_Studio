import '../../../core/database/app_database.dart';

class Album {
  const Album({required this.id, required this.name, required this.count});

  final int id;
  final String name;
  final int count;
}

/// Albums : regroupements logiques de médias (un album par média). Supprimer
/// un album ne supprime aucun média.
class AlbumRepository {
  AlbumRepository(this._db);

  final AppDatabase _db;

  List<Album> list() => [
    for (final r in _db.raw.select(
      'SELECT a.id, a.name, COUNT(m.id) AS n FROM albums a '
      'LEFT JOIN media m ON m.album_id = a.id AND m.stored_path IS NOT NULL '
      'GROUP BY a.id ORDER BY a.name COLLATE NOCASE',
    ))
      Album(
        id: r['id']! as int,
        name: r['name']! as String,
        count: r['n']! as int,
      ),
  ];

  /// Renvoie l'album existant de même nom (casse ignorée) ou le crée.
  int findOrCreate(String name) {
    final trimmed = name.trim();
    final existing = _db.raw.select(
      'SELECT id FROM albums WHERE name = ? COLLATE NOCASE',
      [trimmed],
    );
    if (existing.isNotEmpty) return existing.first['id']! as int;
    _db.raw.execute('INSERT INTO albums(name, created_at) VALUES(?, ?)', [
      trimmed,
      DateTime.now().millisecondsSinceEpoch,
    ]);
    return _db.raw.lastInsertRowId;
  }

  void rename(int id, String name) {
    _db.raw.execute('UPDATE albums SET name = ? WHERE id = ?', [
      name.trim(),
      id,
    ]);
  }

  /// Les médias de l'album restent dans la bibliothèque, hors album.
  void delete(int id) {
    _db.raw.execute('BEGIN');
    try {
      _db.raw.execute('UPDATE media SET album_id = NULL WHERE album_id = ?', [
        id,
      ]);
      _db.raw.execute('DELETE FROM albums WHERE id = ?', [id]);
      _db.raw.execute('COMMIT');
    } catch (_) {
      _db.raw.execute('ROLLBACK');
      rethrow;
    }
  }
}
