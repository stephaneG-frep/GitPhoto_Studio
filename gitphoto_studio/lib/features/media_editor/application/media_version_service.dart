import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/security/path_validator.dart';
import '../../gallery/application/media_importer.dart';
import '../../gallery/data/library_paths.dart';
import '../../gallery/data/media_repository.dart';
import '../../gallery/domain/media_item.dart';
import '../domain/optimization.dart';
import 'image_optimizer.dart';
import 'video_transcoder.dart';

/// La conversion a produit un fichier au moins aussi lourd que l'original :
/// la version n'est pas conservée.
class VideoNotSmallerException implements Exception {
  const VideoNotSmallerException(this.sourceBytes, this.outputBytes);

  final int sourceBytes;
  final int outputBytes;

  @override
  String toString() =>
      'La conversion ne réduit pas la taille ($sourceBytes → $outputBytes o)';
}

class PreviewResult {
  const PreviewResult(this.path, this.result);

  final String path;
  final ImageOptimizeResult result;
}

/// Création de versions dérivées (optimisées, converties) d'un média.
///
/// Garanties : le média d'origine et sa copie de travail ne sont jamais
/// modifiés ; chaque version est un nouveau média de la bibliothèque, lié à
/// son origine et rangé dans le même album.
class MediaVersionService {
  MediaVersionService({
    required this.importer,
    required this.repository,
    required this.paths,
    this.imageOptimizer = const ImageOptimizer(),
    required this.videoTranscoder,
  });

  final MediaImporter importer;
  final MediaRepository repository;
  final LibraryPaths paths;
  final ImageOptimizer imageOptimizer;
  final VideoTranscoder videoTranscoder;

  int _counter = 0;

  /// Dossier de travail temporaire. Dans le cache de l'application, les
  /// fichiers produits sont effacés automatiquement après import.
  Directory get _workDir {
    final base = paths.temporaryDir ?? Directory.systemTemp.path;
    return Directory(p.join(base, 'gitphoto_work'))
      ..createSync(recursive: true);
  }

  String _workFile(String extension) => p.join(
    _workDir.path,
    'w${DateTime.now().microsecondsSinceEpoch}_${_counter++}.$extension',
  );

  /// Nom de la version : `plage.jpg` + `web` → `plage-web.jpg`.
  static String versionName(String original, String suffix, String extension) {
    final base = p.basenameWithoutExtension(original);
    return PathValidator.sanitizeFileName('$base-$suffix.$extension');
  }

  /// Aperçu : fichier temporaire, non ajouté à la bibliothèque.
  Future<PreviewResult> previewImage(
    MediaItem source,
    ImageOptimizeOptions options,
  ) async {
    final out = _workFile(options.extension);
    final result = await imageOptimizer.optimize(
      sourcePath: source.storedPath,
      outputPath: out,
      options: options,
    );
    return PreviewResult(out, result);
  }

  Future<ImportItemResult> saveImageVersion(
    MediaItem source,
    ImageOptimizeOptions options, {
    required String suffix,
  }) async {
    final out = _workFile(options.extension);
    try {
      await imageOptimizer.optimize(
        sourcePath: source.storedPath,
        outputPath: out,
        options: options,
      );
      return await _register(
        source,
        out,
        versionName(source.fileName, suffix, options.extension),
      );
    } finally {
      _delete(out);
    }
  }

  Future<ImportItemResult> saveVideoVersion(
    MediaItem source,
    VideoPreset preset, {
    bool removeAudio = false,
    void Function(double)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final out = _workFile('mp4');
    try {
      await videoTranscoder.transcode(
        input: source.storedPath,
        output: out,
        preset: preset,
        removeAudio: removeAudio,
        videoBitrate: preset.effectiveVideoBitrate(
          sourceBytes: source.sizeBytes,
          durationMs: source.durationMs,
        ),
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
      // Garantie : une « version allégée » plus lourde n'est jamais ajoutée
      // (les encodeurs matériels peuvent ignorer une consigne de débit basse).
      final outputBytes = File(out).lengthSync();
      if (outputBytes >= source.sizeBytes) {
        throw VideoNotSmallerException(source.sizeBytes, outputBytes);
      }
      return await _register(
        source,
        out,
        versionName(source.fileName, '${preset.height}p', 'mp4'),
      );
    } finally {
      _delete(out);
    }
  }

  Future<ImportItemResult> _register(
    MediaItem source,
    String produced,
    String name,
  ) async {
    final result = await importer.importOne(
      ImportCandidate(produced, displayName: name),
    );
    final id = result.mediaId;
    if (result.outcome == ImportOutcome.imported && id != null) {
      repository.setDerivedFrom(id, source.id);
      if (source.albumId != null) repository.setAlbum([id], source.albumId);
    }
    return result;
  }

  /// Supprime un aperçu devenu inutile.
  void discard(String path) => _delete(path);

  static void _delete(String path) {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  }
}
