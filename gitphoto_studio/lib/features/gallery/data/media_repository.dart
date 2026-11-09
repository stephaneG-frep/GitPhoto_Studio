import '../../../core/database/app_database.dart';
import '../domain/media_item.dart';
import '../domain/media_query.dart';

/// Données d'un média à enregistrer (avant attribution d'un identifiant).
class NewMedia {
  const NewMedia({
    required this.fileName,
    required this.storedPath,
    required this.sourcePath,
    required this.kind,
    required this.sizeBytes,
    required this.sha256,
    required this.importedAt,
    this.mimeType,
    this.thumbnailPath,
    this.thumbnailBytes = 0,
    this.width,
    this.height,
    this.durationMs,
    this.takenAt,
    this.cameraModel,
    this.hasGps = false,
    this.derivedFrom,
    this.phash,
    this.albumId,
  });

  final String fileName;
  final String storedPath;
  final String sourcePath;
  final MediaKind kind;
  final int sizeBytes;
  final String sha256;
  final DateTime importedAt;
  final String? mimeType;
  final String? thumbnailPath;
  final int thumbnailBytes;
  final int? width;
  final int? height;
  final int? durationMs;
  final DateTime? takenAt;
  final String? cameraModel;
  final bool hasGps;
  final int? derivedFrom;
  final String? phash;
  final int? albumId;
}

class MediaRepository {
  MediaRepository(this._db);

  final AppDatabase _db;

  int insert(NewMedia m) {
    _db.raw.execute(
      'INSERT INTO media(source_path, file_name, mime_type, size_bytes, '
      'sha256, width, height, duration_ms, taken_at, imported_at, '
      'stored_path, thumbnail_path, thumbnail_bytes, media_kind, '
      'camera_model, has_gps, derived_from, phash, album_id) '
      'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        m.sourcePath,
        m.fileName,
        m.mimeType,
        m.sizeBytes,
        m.sha256,
        m.width,
        m.height,
        m.durationMs,
        m.takenAt?.millisecondsSinceEpoch,
        m.importedAt.millisecondsSinceEpoch,
        m.storedPath,
        m.thumbnailPath,
        m.thumbnailBytes,
        m.kind.name,
        m.cameraModel,
        m.hasGps ? 1 : 0,
        m.derivedFrom,
        m.phash,
        m.albumId,
      ],
    );
    return _db.raw.lastInsertRowId;
  }

  MediaItem? findBySha256(String sha256) {
    final rows = _db.raw.select('SELECT * FROM media WHERE sha256 = ?', [
      sha256,
    ]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  MediaItem? findById(int id) {
    final rows = _db.raw.select('SELECT * FROM media WHERE id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  List<MediaItem> list(MediaListQuery query) {
    final where = <String>['stored_path IS NOT NULL'];
    final args = <Object?>[];
    switch (query.filter) {
      case MediaFilter.all:
        break;
      case MediaFilter.images:
        where.add("media_kind = 'image'");
      case MediaFilter.videos:
        where.add("media_kind = 'video'");
    }
    if (query.albumId case final album?) {
      where.add('album_id = ?');
      args.add(album);
    }
    final search = query.search.trim();
    if (search.isNotEmpty) {
      where.add(r"file_name LIKE ? ESCAPE '\'");
      args.add('%${_escapeLike(search)}%');
    }
    final dir = query.ascending ? 'ASC' : 'DESC';
    final order = switch (query.sort) {
      MediaSort.date => 'COALESCE(taken_at, imported_at) $dir',
      MediaSort.name => 'file_name COLLATE NOCASE $dir',
      MediaSort.type => 'media_kind $dir, mime_type $dir',
      MediaSort.size => 'size_bytes $dir',
    };
    final rows = _db.raw.select(
      'SELECT * FROM media WHERE ${where.join(' AND ')} '
      'ORDER BY $order, id $dir',
      args,
    );
    return rows.map(_fromRow).toList();
  }

  /// Supprime les enregistrements ; renvoie les médias supprimés afin que
  /// l'appelant efface les copies de travail correspondantes.
  List<MediaItem> deleteByIds(Iterable<int> ids) {
    final idList = ids.toList();
    if (idList.isEmpty) return const [];
    final placeholders = List.filled(idList.length, '?').join(', ');
    final rows = _db.raw.select(
      'SELECT * FROM media WHERE id IN ($placeholders)',
      idList,
    );
    _db.raw.execute('DELETE FROM media WHERE id IN ($placeholders)', idList);
    return rows.map(_fromRow).toList();
  }

  /// Renomme le média (nom affiché et nom de publication). Le fichier de
  /// travail, nommé par son empreinte, n'est pas touché.
  void rename(int id, String fileName) {
    _db.raw.execute('UPDATE media SET file_name = ? WHERE id = ?', [
      fileName,
      id,
    ]);
  }

  void setPhash(int id, String phash) {
    _db.raw.execute('UPDATE media SET phash = ? WHERE id = ?', [phash, id]);
  }

  void setDerivedFrom(int id, int sourceId) {
    _db.raw.execute('UPDATE media SET derived_from = ? WHERE id = ?', [
      sourceId,
      id,
    ]);
  }

  /// Range des médias dans un album (`null` : hors album).
  void setAlbum(Iterable<int> ids, int? albumId) {
    final list = ids.toList();
    if (list.isEmpty) return;
    final placeholders = List.filled(list.length, '?').join(', ');
    _db.raw.execute(
      'UPDATE media SET album_id = ? WHERE id IN ($placeholders)',
      [albumId, ...list],
    );
  }

  /// Médias sans empreinte visuelle mais dotés d'une miniature.
  List<MediaItem> missingPhash() => _db.raw
      .select(
        'SELECT * FROM media WHERE phash IS NULL '
        'AND thumbnail_path IS NOT NULL AND stored_path IS NOT NULL',
      )
      .map(_fromRow)
      .toList();

  List<MediaItem> withPhash() => _db.raw
      .select(
        'SELECT * FROM media WHERE phash IS NOT NULL '
        'AND stored_path IS NOT NULL ORDER BY id',
      )
      .map(_fromRow)
      .toList();

  /// Octets occupés par les copies de travail et miniatures.
  int librarySizeBytes() {
    final row = _db.raw
        .select(
          'SELECT COALESCE(SUM(size_bytes + thumbnail_bytes), 0) AS n '
          'FROM media WHERE stored_path IS NOT NULL',
        )
        .first;
    return row['n'] as int;
  }

  static String _escapeLike(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  static DateTime? _date(Object? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms as int);

  static MediaItem _fromRow(Map<String, Object?> r) {
    return MediaItem(
      id: r['id']! as int,
      fileName: r['file_name']! as String,
      storedPath: (r['stored_path'] as String?) ?? '',
      sourcePath: r['source_path']! as String,
      kind: r['media_kind'] == 'video' ? MediaKind.video : MediaKind.image,
      sizeBytes: r['size_bytes']! as int,
      sha256: (r['sha256'] as String?) ?? '',
      importedAt: _date(r['imported_at'])!,
      mimeType: r['mime_type'] as String?,
      thumbnailPath: r['thumbnail_path'] as String?,
      thumbnailBytes: r['thumbnail_bytes'] as int? ?? 0,
      width: r['width'] as int?,
      height: r['height'] as int?,
      durationMs: r['duration_ms'] as int?,
      takenAt: _date(r['taken_at']),
      cameraModel: r['camera_model'] as String?,
      hasGps: r['has_gps'] == 1,
      derivedFrom: r['derived_from'] as int?,
      phash: r['phash'] as String?,
      albumId: r['album_id'] as int?,
    );
  }
}
