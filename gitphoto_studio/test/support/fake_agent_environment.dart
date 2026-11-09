// ENVIRONNEMENT D'AGENT SIMULÉ — RÉSERVÉ AUX TESTS (validation, outils,
// boucle). L'exécution réelle est testée avec AppAgentEnvironment.
import 'package:gitphoto_studio/features/ai_agent/application/agent_environment.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/data/album_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';
import 'package:gitphoto_studio/features/github/domain/github_models.dart';
import 'package:gitphoto_studio/features/media_editor/domain/optimization.dart';
import 'package:gitphoto_studio/features/publishing/application/publication_analyzer.dart';
import 'package:gitphoto_studio/features/publishing/application/publish_queue.dart';
import 'package:gitphoto_studio/features/publishing/data/operations_repository.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';

MediaItem fakeMedia(
  int id, {
  String? name,
  MediaKind kind = MediaKind.image,
  bool gps = false,
  DateTime? taken,
  int? albumId,
}) => MediaItem(
  id: id,
  fileName: name ?? 'photo$id.jpg',
  storedPath: '/nulle-part/$id',
  sourcePath: '/nulle-part/$id',
  kind: kind,
  sizeBytes: 1000 * id,
  sha256: 'sha$id',
  importedAt: DateTime(2025, 1, 1),
  takenAt: taken,
  hasGps: gps,
  albumId: albumId,
);

class FakeAgentEnvironment implements AgentEnvironment {
  FakeAgentEnvironment({
    List<MediaItem> media = const [],
    this.repos = const [],
    this.login = 'testeur',
    this.videoSupported = true,
  }) : _media = {for (final m in media) m.id: m};

  final Map<int, MediaItem> _media;
  final List<GithubRepo> repos;
  final String? login;
  final bool videoSupported;
  Set<int> selected = {};
  final albumList = <Album>[];
  final actions = <String>[];
  int repoCalls = 0;

  @override
  List<MediaItem> listMedia() => _media.values.toList();

  @override
  MediaItem? media(int id) => _media[id];

  @override
  List<Album> albums() => albumList;

  @override
  Set<int> selection() => selected;

  @override
  Future<List<List<MediaItem>>> similarGroups() async => const [];

  @override
  String? githubLogin() => login;

  @override
  Future<List<GithubRepo>> repositories() async {
    repoCalls++;
    if (login == null) {
      throw const GithubException(GithubErrorKind.unauthorized, 'hors ligne');
    }
    return repos;
  }

  @override
  ({String owner, String name, String? defaultBranch})? activeRepository() =>
      null;

  @override
  List<OperationRecord> operations({int limit = 20}) => const [];

  @override
  bool get videoConversionSupported => videoSupported;

  @override
  Future<PublishPlan> analyzePublication({
    required GithubRepo repo,
    required String branch,
    required String folder,
    required List<MediaItem> media,
    List<ExtraPublishFile> extraFiles = const [],
  }) async {
    actions.add('analyze ${repo.fullName}@$branch:$folder');
    return const PublishPlan(
      files: [],
      folder: '',
      repositoryIsEmpty: false,
      remoteTreeTruncated: false,
    );
  }

  @override
  void moveToAlbum(List<int> mediaIds, String album) =>
      actions.add('album $album $mediaIds');

  @override
  Future<ImportItemResult> optimizeImage(
    MediaItem image,
    ImagePreset preset,
  ) async {
    actions.add('optimize ${image.id}');
    return ImportItemResult(image.fileName, ImportOutcome.failed);
  }

  @override
  Future<ImportItemResult> convertVideo(
    MediaItem video,
    VideoPreset preset, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    actions.add('convert ${video.id}');
    return ImportItemResult(video.fileName, ImportOutcome.failed);
  }

  @override
  Future<String> writeDocument(String fileName, String content) async =>
      '/nulle-part/$fileName';

  @override
  Future<QueueOutcome> publish({
    required GithubRepo repo,
    required String branch,
    required String message,
    required PublishPlan plan,
  }) async {
    actions.add('publish');
    return const QueueOutcome.failure('non simulé');
  }
}

const publicRepo = GithubRepo(
  owner: 'testeur',
  name: 'Portfolio',
  isPrivate: false,
  htmlUrl: 'https://github.com/testeur/Portfolio',
  canPush: true,
  defaultBranch: 'main',
);

const readOnlyRepo = GithubRepo(
  owner: 'autre',
  name: 'lecture',
  isPrivate: true,
  htmlUrl: 'https://github.com/autre/lecture',
  canPush: false,
  defaultBranch: 'main',
);
