import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../gallery/application/gallery_providers.dart';
import '../../gallery/application/media_importer.dart';
import '../../gallery/data/album_repository.dart';
import '../../gallery/domain/media_item.dart';
import '../../gallery/domain/media_query.dart';
import '../../github/application/github_session.dart';
import '../../github/data/github_exception.dart';
import '../../github/domain/github_models.dart';
import '../../media_editor/application/editor_providers.dart';
import '../../media_editor/domain/optimization.dart';
import '../../publishing/application/publication_analyzer.dart';
import '../../publishing/application/publish_controller.dart';
import '../../publishing/application/publish_queue.dart';
import '../../publishing/data/operations_repository.dart';
import '../../publishing/domain/publish_plan.dart';

/// Tout ce que l'agent peut consulter ou faire, et rien d'autre : chaque
/// méthode correspond à une fonction existante de l'application. Aucune ne
/// supprime de donnée, ne remplace un fichier distant ni n'exécute de
/// commande.
abstract interface class AgentEnvironment {
  // --- Consultation ---------------------------------------------------------
  List<MediaItem> listMedia();
  MediaItem? media(int id);
  List<Album> albums();
  Set<int> selection();
  Future<List<List<MediaItem>>> similarGroups();

  /// `null` : pas de session GitHub active.
  String? githubLogin();

  /// Dépôts accessibles (lève une [GithubException] hors connexion).
  Future<List<GithubRepo>> repositories();
  ({String owner, String name, String? defaultBranch})? activeRepository();
  List<OperationRecord> operations({int limit = 20});
  bool get videoConversionSupported;

  /// Analyse sans effet (lecture de l'arborescence distante).
  Future<PublishPlan> analyzePublication({
    required GithubRepo repo,
    required String branch,
    required String folder,
    required List<MediaItem> media,
    List<ExtraPublishFile> extraFiles = const [],
  });

  // --- Actions (après confirmation de l'utilisateur) ------------------------
  void moveToAlbum(List<int> mediaIds, String album);

  Future<ImportItemResult> optimizeImage(MediaItem image, ImagePreset preset);

  Future<ImportItemResult> convertVideo(
    MediaItem video,
    VideoPreset preset, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  });

  /// Écrit un document produit par l'application (README) dans son dossier
  /// privé et renvoie son chemin.
  Future<String> writeDocument(String fileName, String content);

  Future<QueueOutcome> publish({
    required GithubRepo repo,
    required String branch,
    required String message,
    required PublishPlan plan,
  });
}

/// Suffixes des versions optimisées (identiques à l'éditeur).
const optimizeSuffix = {
  ImagePreset.web: 'web',
  ImagePreset.light: 'leger',
  ImagePreset.thumbnail: 'miniature',
};

/// Implémentation réelle, branchée sur les services de l'application.
class AppAgentEnvironment implements AgentEnvironment {
  AppAgentEnvironment(this._ref, {Future<String> Function()? documentsDir})
    : _documentsDir = documentsDir;

  final Ref _ref;
  final Future<String> Function()? _documentsDir;

  @override
  List<MediaItem> listMedia() =>
      _ref.read(mediaRepositoryProvider).list(const MediaListQuery());

  @override
  MediaItem? media(int id) => _ref.read(mediaRepositoryProvider).findById(id);

  @override
  List<Album> albums() => _ref.read(albumRepositoryProvider).list();

  @override
  Set<int> selection() => _ref.read(gallerySelectionProvider);

  @override
  Future<List<List<MediaItem>>> similarGroups() =>
      _ref.read(similarGroupsProvider.future);

  GithubConnected? get _session =>
      switch (_ref.read(githubSessionProvider).value) {
        final GithubConnected s => s,
        _ => null,
      };

  @override
  String? githubLogin() => _session?.user.login;

  @override
  Future<List<GithubRepo>> repositories() {
    final session = _session;
    if (session == null) {
      throw const GithubException(
        GithubErrorKind.unauthorized,
        'Aucune session GitHub',
      );
    }
    return session.api.listRepos();
  }

  @override
  ({String owner, String name, String? defaultBranch})? activeRepository() =>
      _ref.read(activeRepositoryProvider);

  @override
  List<OperationRecord> operations({int limit = 20}) =>
      _ref.read(operationsRepositoryProvider).list(limit: limit);

  @override
  bool get videoConversionSupported =>
      _ref.read(videoTranscoderProvider).isSupported;

  @override
  Future<PublishPlan> analyzePublication({
    required GithubRepo repo,
    required String branch,
    required String folder,
    required List<MediaItem> media,
    List<ExtraPublishFile> extraFiles = const [],
  }) {
    final session = _session;
    if (session == null) {
      throw const GithubException(
        GithubErrorKind.unauthorized,
        'Aucune session GitHub',
      );
    }
    return _ref
        .read(publicationAnalyzerProvider)
        .analyze(
          api: session.api,
          owner: repo.owner,
          repo: repo.name,
          branch: branch,
          folder: folder,
          media: media,
          extraFiles: extraFiles,
        );
  }

  @override
  void moveToAlbum(List<int> mediaIds, String album) {
    final albumId = _ref.read(albumRepositoryProvider).findOrCreate(album);
    _ref.read(mediaRepositoryProvider).setAlbum(mediaIds, albumId);
    refreshLibrary(_ref);
  }

  @override
  Future<ImportItemResult> optimizeImage(
    MediaItem image,
    ImagePreset preset,
  ) async {
    final r = await _ref
        .read(mediaVersionServiceProvider)
        .saveImageVersion(
          image,
          imagePresets[preset]!,
          suffix: optimizeSuffix[preset]!,
        );
    refreshLibrary(_ref);
    return r;
  }

  @override
  Future<ImportItemResult> convertVideo(
    MediaItem video,
    VideoPreset preset, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final r = await _ref
        .read(mediaVersionServiceProvider)
        .saveVideoVersion(
          video,
          preset,
          onProgress: onProgress,
          isCancelled: isCancelled,
        );
    refreshLibrary(_ref);
    return r;
  }

  @override
  Future<String> writeDocument(String fileName, String content) async {
    final base =
        await (_documentsDir?.call() ??
            getApplicationSupportDirectory().then((d) => d.path));
    // Un dossier par document : le nom publié reste « README.md ».
    final dir = Directory(
      p.join(
        base,
        'agent_documents',
        '${DateTime.now().microsecondsSinceEpoch}',
      ),
    )..createSync(recursive: true);
    final file = File(p.join(dir.path, p.basename(fileName)));
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  @override
  Future<QueueOutcome> publish({
    required GithubRepo repo,
    required String branch,
    required String message,
    required PublishPlan plan,
  }) => _ref
      .read(publishQueueProvider.notifier)
      .enqueue(repo: repo, branch: branch, message: message, plan: plan);
}

final agentEnvironmentProvider = Provider<AgentEnvironment>(
  AppAgentEnvironment.new,
);
