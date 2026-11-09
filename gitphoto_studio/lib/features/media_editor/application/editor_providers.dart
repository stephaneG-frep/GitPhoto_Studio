import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../dashboard/application/dashboard_stats.dart';
import '../../gallery/application/gallery_providers.dart';
import '../../gallery/application/media_importer.dart';
import '../../gallery/data/album_repository.dart';
import '../../gallery/domain/media_item.dart';
import '../domain/optimization.dart';
import '../domain/perceptual_hash.dart';
import 'image_optimizer.dart';
import 'media_version_service.dart';
import 'video_transcoder.dart';

final imageOptimizerProvider = Provider<ImageOptimizer>(
  (ref) => const ImageOptimizer(),
);

/// Android : Media3 Transformer. Linux : ffmpeg s'il est installé.
final videoTranscoderProvider = Provider<VideoTranscoder>((ref) {
  if (Platform.isAndroid) return const AndroidVideoTranscoder();
  if (Platform.isLinux) {
    final tools = ref.watch(toolAvailabilityProvider).value;
    return FfmpegVideoTranscoder(available: tools?.hasFfmpeg ?? false);
  }
  return const UnavailableVideoTranscoder();
});

final mediaVersionServiceProvider = Provider<MediaVersionService>(
  (ref) => MediaVersionService(
    importer: ref.watch(mediaImporterProvider),
    repository: ref.watch(mediaRepositoryProvider),
    paths: ref.watch(libraryPathsProvider),
    imageOptimizer: ref.watch(imageOptimizerProvider),
    videoTranscoder: ref.watch(videoTranscoderProvider),
  ),
);

final albumRepositoryProvider = Provider<AlbumRepository>(
  (ref) => AlbumRepository(ref.watch(appDatabaseProvider)),
);

final albumsProvider = Provider<List<Album>>((ref) {
  ref.watch(libraryRevisionProvider);
  return ref.watch(albumRepositoryProvider).list();
});

/// Notifie toute modification de la bibliothèque (galerie, accueil…).
void refreshLibrary(Ref ref) {
  ref.read(libraryRevisionProvider.notifier).bump();
  ref.invalidate(dashboardStatsProvider);
}

/// Même chose depuis un widget.
void refreshLibraryFromWidget(WidgetRef ref) {
  ref.read(libraryRevisionProvider.notifier).bump();
  ref.invalidate(dashboardStatsProvider);
}

/// Groupes de doublons probables (empreinte visuelle proche). Les empreintes
/// manquantes (médias importés avant la phase 4) sont calculées au passage.
final similarGroupsProvider = FutureProvider<List<List<MediaItem>>>((
  ref,
) async {
  ref.watch(libraryRevisionProvider);
  final repo = ref.watch(mediaRepositoryProvider);
  for (final m in repo.missingPhash()) {
    final hash = await differenceHashOfFile(m.thumbnailPath!);
    if (hash != null) repo.setPhash(m.id, hash);
  }
  final items = repo.withPhash();
  return groupSimilar(items, (m) => m.phash!);
}, retry: (retryCount, error) => null);

sealed class VersionJobState {
  const VersionJobState();
}

class VersionJobIdle extends VersionJobState {
  const VersionJobIdle();
}

class VersionJobRunning extends VersionJobState {
  const VersionJobRunning(this.done, this.total, this.progress, this.current);

  final int done;
  final int total;

  /// Progression du fichier en cours (0–1), `null` si inconnue.
  final double? progress;
  final String current;
}

class VersionJobFinished extends VersionJobState {
  const VersionJobFinished(this.results, {this.cancelled = false, this.error});

  final List<ImportItemResult> results;
  final bool cancelled;
  final Object? error;

  int get created =>
      results.where((r) => r.outcome == ImportOutcome.imported).length;
}

/// Traitements longs (optimisation par lot, conversion vidéo) : progression,
/// annulation entre deux fichiers (ou en cours pour la vidéo).
class VersionJobController extends Notifier<VersionJobState> {
  bool _cancel = false;

  @override
  VersionJobState build() => const VersionJobIdle();

  bool get isRunning => state is VersionJobRunning;

  void cancel() => _cancel = true;

  void acknowledge() {
    if (!isRunning) state = const VersionJobIdle();
  }

  Future<VersionJobFinished?> optimizeImages(
    List<MediaItem> items,
    ImageOptimizeOptions options, {
    required String suffix,
  }) async {
    final images = items.where((m) => !m.isVideo).toList();
    if (images.isEmpty || isRunning) return null;
    _cancel = false;
    final service = ref.read(mediaVersionServiceProvider);
    final results = <ImportItemResult>[];
    for (var i = 0; i < images.length; i++) {
      if (_cancel) return _finish(results, cancelled: true);
      state = VersionJobRunning(i, images.length, null, images[i].fileName);
      try {
        results.add(
          await service.saveImageVersion(images[i], options, suffix: suffix),
        );
      } on Object catch (e) {
        results.add(
          ImportItemResult(
            images[i].fileName,
            ImportOutcome.failed,
            error: '$e',
          ),
        );
      }
    }
    return _finish(results);
  }

  Future<VersionJobFinished?> convertVideo(
    MediaItem video,
    VideoPreset preset, {
    bool removeAudio = false,
  }) async {
    if (!video.isVideo || isRunning) return null;
    _cancel = false;
    state = VersionJobRunning(0, 1, 0, video.fileName);
    try {
      final r = await ref
          .read(mediaVersionServiceProvider)
          .saveVideoVersion(
            video,
            preset,
            removeAudio: removeAudio,
            onProgress: (p) {
              if (ref.mounted) {
                state = VersionJobRunning(0, 1, p, video.fileName);
              }
            },
            isCancelled: () => _cancel,
          );
      return _finish([r]);
    } on TranscodeCancelled {
      return _finish(const [], cancelled: true);
    } on Object catch (e) {
      ref.read(loggerProvider).warning('Conversion vidéo : $e');
      return _finish(const [], error: e);
    }
  }

  VersionJobFinished? _finish(
    List<ImportItemResult> results, {
    bool cancelled = false,
    Object? error,
  }) {
    if (!ref.mounted) return null;
    refreshLibrary(ref);
    final finished = VersionJobFinished(
      results,
      cancelled: cancelled,
      error: error,
    );
    state = finished;
    return finished;
  }
}

final versionJobProvider =
    NotifierProvider<VersionJobController, VersionJobState>(
      VersionJobController.new,
    );
