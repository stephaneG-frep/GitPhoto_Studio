import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/preferences_repository.dart';
import '../../../core/platform/external_opener.dart';
import '../../dashboard/application/dashboard_stats.dart';
import '../data/library_paths.dart';
import '../data/media_repository.dart';
import '../domain/media_item.dart';
import '../domain/media_query.dart';
import 'media_importer.dart';
import 'media_inspectors.dart';
import 'media_picker.dart';

/// Fourni au démarrage (voir `main.dart`) ; remplacé dans les tests.
final libraryPathsProvider = Provider<LibraryPaths>(
  (ref) => throw UnimplementedError('libraryPathsProvider doit être fourni'),
);

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(ref.watch(appDatabaseProvider)),
);

final imageInspectorProvider = Provider<ImageInspector>(
  (ref) => const EngineImageInspector(),
);

/// Android : canal natif. Linux : ffprobe/ffmpeg s'ils sont installés.
final videoInspectorProvider = Provider<VideoInspector>((ref) {
  if (Platform.isAndroid) return const AndroidVideoInspector();
  final tools = ref.watch(toolAvailabilityProvider).value;
  return tools != null && tools.hasFfmpeg
      ? const FfmpegVideoInspector()
      : const UnavailableVideoInspector();
});

final mediaPickerProvider = Provider<MediaPicker>(
  (ref) => const FileSelectorMediaPicker(),
);

final mediaImporterProvider = Provider<MediaImporter>(
  (ref) => MediaImporter(
    repository: ref.watch(mediaRepositoryProvider),
    paths: ref.watch(libraryPathsProvider),
    imageInspector: ref.watch(imageInspectorProvider),
    videoInspector: ref.watch(videoInspectorProvider),
    logger: ref.watch(loggerProvider),
  ),
);

/// Incrémenté à chaque modification de la bibliothèque.
class LibraryRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final libraryRevisionProvider = NotifierProvider<LibraryRevision, int>(
  LibraryRevision.new,
);

abstract final class _Keys {
  static const filter = 'gallery.filter';
  static const sort = 'gallery.sort';
  static const ascending = 'gallery.ascending';
  static const viewMode = 'gallery.view_mode';
}

/// Filtre, tri et recherche ; filtre et tri sont mémorisés.
class GalleryQueryController extends Notifier<MediaListQuery> {
  @override
  MediaListQuery build() {
    final prefs = ref.watch(preferencesProvider);
    return MediaListQuery(
      filter:
          MediaFilter.values.asNameMap()[prefs.read(_Keys.filter)] ??
          MediaFilter.all,
      sort:
          MediaSort.values.asNameMap()[prefs.read(_Keys.sort)] ??
          MediaSort.date,
      ascending: prefs.read(_Keys.ascending) == 'true',
    );
  }

  PreferencesRepository get _prefs => ref.read(preferencesProvider);

  void setFilter(MediaFilter filter) {
    _prefs.write(_Keys.filter, filter.name);
    state = state.copyWith(filter: filter);
  }

  void setSort(MediaSort sort) {
    _prefs.write(_Keys.sort, sort.name);
    state = state.copyWith(sort: sort);
  }

  void toggleDirection() {
    _prefs.write(_Keys.ascending, '${!state.ascending}');
    state = state.copyWith(ascending: !state.ascending);
  }

  void setSearch(String search) => state = state.copyWith(search: search);

  void setAlbum(int? albumId) => state = state.copyWith(albumId: () => albumId);
}

final galleryQueryProvider =
    NotifierProvider<GalleryQueryController, MediaListQuery>(
      GalleryQueryController.new,
    );

class GalleryViewModeController extends Notifier<GalleryViewMode> {
  @override
  GalleryViewMode build() =>
      GalleryViewMode.values.asNameMap()[ref
          .watch(preferencesProvider)
          .read(_Keys.viewMode)] ??
      GalleryViewMode.grid;

  void set(GalleryViewMode mode) {
    ref.read(preferencesProvider).write(_Keys.viewMode, mode.name);
    state = mode;
  }
}

final galleryViewModeProvider =
    NotifierProvider<GalleryViewModeController, GalleryViewMode>(
      GalleryViewModeController.new,
    );

final mediaListProvider = Provider<List<MediaItem>>((ref) {
  ref.watch(libraryRevisionProvider);
  return ref
      .watch(mediaRepositoryProvider)
      .list(ref.watch(galleryQueryProvider));
});

final mediaByIdProvider = Provider.family<MediaItem?, int>((ref, id) {
  ref.watch(libraryRevisionProvider);
  return ref.watch(mediaRepositoryProvider).findById(id);
});

/// Sélection multiple (identifiants des médias).
class GallerySelection extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void toggle(int id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void selectAll(Iterable<int> ids) => state = ids.toSet();

  void clear() => state = const {};
}

final gallerySelectionProvider = NotifierProvider<GallerySelection, Set<int>>(
  GallerySelection.new,
);

sealed class ImportState {
  const ImportState();
}

class ImportIdle extends ImportState {
  const ImportIdle();
}

class ImportRunning extends ImportState {
  const ImportRunning(this.done, this.total, this.current);

  final int done;
  final int total;
  final String current;
}

class ImportFinished extends ImportState {
  const ImportFinished(this.report);

  final ImportReport report;
}

class ImportController extends Notifier<ImportState> {
  bool _cancelRequested = false;

  @override
  ImportState build() => const ImportIdle();

  bool get isRunning => state is ImportRunning;

  Future<ImportReport?> importFiles(List<ImportCandidate> candidates) async {
    if (candidates.isEmpty || isRunning) return null;
    _cancelRequested = false;
    state = ImportRunning(0, candidates.length, candidates.first.name);
    final report = await ref
        .read(mediaImporterProvider)
        .importAll(
          candidates,
          onProgress: (done, total, current) {
            if (ref.mounted) state = ImportRunning(done, total, current);
          },
          isCancelled: () => _cancelRequested,
        );
    if (ref.mounted) {
      _refreshLibrary(ref);
      state = ImportFinished(report);
    }
    return report;
  }

  /// L'annulation prend effet entre deux fichiers : le fichier en cours est
  /// terminé ou nettoyé, jamais laissé à moitié copié.
  void cancel() => _cancelRequested = true;

  void acknowledge() => state = const ImportIdle();

  int removeMedia(Iterable<int> ids) {
    final removed = ref.read(mediaImporterProvider).remove(ids);
    ref.read(gallerySelectionProvider.notifier).clear();
    _refreshLibrary(ref);
    return removed.length;
  }
}

void _refreshLibrary(Ref ref) {
  ref.read(libraryRevisionProvider.notifier).bump();
  ref.invalidate(dashboardStatsProvider);
}

final importControllerProvider =
    NotifierProvider<ImportController, ImportState>(ImportController.new);

final externalOpenerProvider = Provider<ExternalOpener>(
  (ref) => const SystemExternalOpener(),
);

/// Lecture vidéo intégrée : `video_player` ne prend en charge que les
/// plateformes mobiles et macOS (pas Linux).
final inAppVideoSupportedProvider = Provider<bool>(
  (ref) => Platform.isAndroid || Platform.isIOS || Platform.isMacOS,
);
