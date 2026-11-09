import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/logging/app_logger.dart';
import '../../../core/security/path_validator.dart';
import '../data/library_paths.dart';
import '../data/media_repository.dart';
import '../domain/media_item.dart';
import '../../media_editor/domain/perceptual_hash.dart';
import 'exif_reader.dart';
import 'file_fingerprint.dart';
import 'media_inspectors.dart';
import 'media_type_detector.dart';

/// Fichier proposé à l'import (sélecteur ou glisser-déposer).
class ImportCandidate {
  const ImportCandidate(this.path, {String? displayName})
    : displayName = displayName ?? '';

  final String path;

  /// Nom d'origine affiché par le sélecteur ; à défaut, nom du fichier.
  final String displayName;

  String get name => displayName.isNotEmpty ? displayName : p.basename(path);
}

enum ImportOutcome { imported, duplicate, unsupported, failed }

class ImportItemResult {
  const ImportItemResult(this.name, this.outcome, {this.mediaId, this.error});

  final String name;
  final ImportOutcome outcome;
  final int? mediaId;
  final String? error;
}

class ImportReport {
  const ImportReport(this.items, {this.cancelled = false});

  final List<ImportItemResult> items;
  final bool cancelled;

  int count(ImportOutcome outcome) =>
      items.where((i) => i.outcome == outcome).length;
}

typedef ImportProgress = void Function(int done, int total, String current);

/// Importe des médias dans la bibliothèque du studio.
///
/// Garanties :
/// - l'original n'est jamais modifié ni supprimé ; seule une copie temporaire
///   créée par le sélecteur dans le cache de l'application peut être effacée ;
/// - un fichier déjà présent (même empreinte SHA-256) n'est pas réimporté ;
/// - en cas d'échec, les fichiers partiellement créés sont nettoyés.
class MediaImporter {
  MediaImporter({
    required this.repository,
    required this.paths,
    required this.imageInspector,
    required this.videoInspector,
    this.logger,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final MediaRepository repository;
  final LibraryPaths paths;
  final ImageInspector imageInspector;
  final VideoInspector videoInspector;
  final AppLogger? logger;
  final DateTime Function() _clock;

  static const thumbnailMaxSize = 320;

  Future<ImportReport> importAll(
    List<ImportCandidate> candidates, {
    ImportProgress? onProgress,
    bool Function()? isCancelled,
  }) async {
    paths.ensureCreated();
    final results = <ImportItemResult>[];
    for (var i = 0; i < candidates.length; i++) {
      if (isCancelled?.call() ?? false) {
        return ImportReport(results, cancelled: true);
      }
      final candidate = candidates[i];
      onProgress?.call(i, candidates.length, candidate.name);
      final result = await importOne(candidate);
      results.add(result);
      if (result.outcome == ImportOutcome.failed) {
        logger?.warning('Import échoué « ${result.name} » : ${result.error}');
      }
    }
    onProgress?.call(candidates.length, candidates.length, '');
    return ImportReport(results);
  }

  Future<ImportItemResult> importOne(ImportCandidate candidate) async {
    final name = PathValidator.sanitizeFileName(candidate.name);
    final source = File(candidate.path);
    final createdFiles = <File>[];
    try {
      if (!source.existsSync()) {
        return ImportItemResult(
          name,
          ImportOutcome.failed,
          error: 'fichier introuvable',
        );
      }
      final type = detectMediaType(candidate.path, displayName: name);
      if (type == null) {
        return ImportItemResult(name, ImportOutcome.unsupported);
      }

      final hash = await sha256OfFile(candidate.path);
      final existing = repository.findBySha256(hash);
      if (existing != null) {
        _discardTemporaryCopy(candidate.path);
        return ImportItemResult(
          name,
          ImportOutcome.duplicate,
          mediaId: existing.id,
        );
      }

      final ext = storedExtension(name, type.mimeType);
      final stored = File(p.join(paths.mediaDir, '$hash.$ext'));
      final partial = File('${stored.path}.part');
      createdFiles.add(partial);
      await source.copy(partial.path);
      await partial.rename(stored.path);
      createdFiles
        ..remove(partial)
        ..add(stored);

      final media = type.kind == MediaKind.image
          ? await _describeImage(stored.path, hash, createdFiles)
          : await _describeVideo(stored.path, hash, createdFiles);

      final isTemporary = paths.isTemporaryCopy(candidate.path);
      final id = repository.insert(
        NewMedia(
          fileName: name,
          storedPath: stored.path,
          sourcePath: candidate.path,
          kind: type.kind,
          mimeType: type.mimeType,
          sizeBytes: stored.lengthSync(),
          sha256: hash,
          importedAt: _clock(),
          thumbnailPath: media.thumbnailPath,
          thumbnailBytes: media.thumbnailBytes,
          width: media.width,
          height: media.height,
          durationMs: media.durationMs,
          // La date de modification d'une copie temporaire est celle de la
          // copie, pas celle du média : on ne s'en sert pas.
          takenAt:
              media.takenAt ?? (isTemporary ? null : source.lastModifiedSync()),
          cameraModel: media.cameraModel,
          hasGps: media.hasGps,
        ),
      );
      _discardTemporaryCopy(candidate.path);
      // Empreinte visuelle (doublons probables) : facultative, un échec ne
      // remet pas l'import en cause.
      if (media.thumbnailPath case final thumb?) {
        final phash = await differenceHashOfFile(thumb);
        if (phash != null) repository.setPhash(id, phash);
      }
      return ImportItemResult(name, ImportOutcome.imported, mediaId: id);
    } on Object catch (e) {
      for (final f in createdFiles) {
        if (f.existsSync()) f.deleteSync();
      }
      return ImportItemResult(name, ImportOutcome.failed, error: '$e');
    }
  }

  Future<_Description> _describeImage(
    String path,
    String hash,
    List<File> created,
  ) async {
    final thumb = File(p.join(paths.thumbnailDir, '$hash.png'));
    created.add(thumb);
    final inspection = await imageInspector.inspect(
      path,
      thumbnailPath: thumb.path,
      maxSize: thumbnailMaxSize,
    );
    // Le décodeur du moteur applique déjà l'orientation EXIF : les
    // dimensions renvoyées sont celles de l'image affichée.
    final exif = await readJpegExif(path);
    final hasThumb = inspection?.thumbnailWritten ?? false;
    return _Description(
      width: inspection?.width,
      height: inspection?.height,
      thumbnailPath: hasThumb ? thumb.path : null,
      thumbnailBytes: hasThumb ? thumb.lengthSync() : 0,
      takenAt: exif?.takenAt,
      cameraModel: exif?.cameraModel,
      hasGps: exif?.hasGps ?? false,
    );
  }

  Future<_Description> _describeVideo(
    String path,
    String hash,
    List<File> created,
  ) async {
    if (!videoInspector.isSupported) return const _Description();
    final thumb = File(p.join(paths.thumbnailDir, '$hash.jpg'));
    created.add(thumb);
    final inspection = await videoInspector.inspect(
      path,
      thumbnailPath: thumb.path,
      maxSize: thumbnailMaxSize,
    );
    final hasThumb =
        (inspection?.thumbnailWritten ?? false) && thumb.existsSync();
    return _Description(
      width: inspection?.width,
      height: inspection?.height,
      durationMs: inspection?.durationMs,
      thumbnailPath: hasThumb ? thumb.path : null,
      thumbnailBytes: hasThumb ? thumb.lengthSync() : 0,
    );
  }

  /// Supprime uniquement une copie temporaire située dans le cache de
  /// l'application ; tout autre fichier est laissé intact.
  void _discardTemporaryCopy(String path) {
    if (!paths.isTemporaryCopy(path)) return;
    try {
      File(path).deleteSync();
    } on FileSystemException {
      // Sans conséquence : le système videra le cache.
    }
  }

  /// Retire des médias de la bibliothèque et efface leurs copies de travail.
  /// Les fichiers hors des dossiers gérés ne sont jamais supprimés.
  List<MediaItem> remove(Iterable<int> ids) {
    final removed = repository.deleteByIds(ids);
    for (final m in removed) {
      for (final path in [m.storedPath, m.thumbnailPath]) {
        if (path == null || path.isEmpty || !paths.isManaged(path)) continue;
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      }
    }
    return removed;
  }
}

class _Description {
  const _Description({
    this.width,
    this.height,
    this.durationMs,
    this.thumbnailPath,
    this.thumbnailBytes = 0,
    this.takenAt,
    this.cameraModel,
    this.hasGps = false,
  });

  final int? width;
  final int? height;
  final int? durationMs;
  final String? thumbnailPath;
  final int thumbnailBytes;
  final DateTime? takenAt;
  final String? cameraModel;
  final bool hasGps;
}
