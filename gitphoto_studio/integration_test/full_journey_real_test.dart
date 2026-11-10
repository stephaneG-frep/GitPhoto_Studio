import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_controller.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_environment.dart';
import 'package:gitphoto_studio/features/ai_agent/application/ai_settings.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/agent_plan.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';
import 'package:gitphoto_studio/features/gallery/application/gallery_providers.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/github/application/github_session.dart';
import 'package:gitphoto_studio/features/github/data/github_api.dart';
import 'package:gitphoto_studio/features/github/data/lfs_client.dart';
import 'package:gitphoto_studio/features/media_editor/application/editor_providers.dart';
import 'package:gitphoto_studio/features/media_editor/domain/optimization.dart';
import 'package:gitphoto_studio/features/publishing/application/publish_controller.dart';
import 'package:gitphoto_studio/features/publishing/application/publish_queue.dart';
import 'package:gitphoto_studio/features/publishing/data/operations_repository.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../test/support/fake_secret_store.dart';
import '../test/support/media_fixtures.dart';

/// Parcours complets RÉELS (phase 8), sur le dépôt de test autorisé :
///   flutter test integration_test/full_journey_real_test.dart -d linux \
///     --dart-define=GITPHOTO_TEST_REPO=proprietaire/depot-de-test
/// Jeton : ~/.config/gitphoto/test_token ; clé Mistral :
/// ~/.config/gitphoto/mistral_key (gardés en mémoire, jamais dans le
/// trousseau réel). Les fichiers publiés vont dans gitphoto-tests/.
/// Aucun nouvel objet Git LFS n'est créé.
const _repo = String.fromEnvironment('GITPHOTO_TEST_REPO');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final home = Platform.environment['HOME'] ?? '';
  final tokenFile = File(p.join(home, '.config/gitphoto/test_token'));
  final keyFile = File(p.join(home, '.config/gitphoto/mistral_key'));
  final configured = _repo.contains('/') && tokenFile.existsSync();

  late String token;
  late String owner;
  late String name;
  late GithubApi api;
  late Directory root;
  late AppDatabase db;
  late ProviderContainer container;
  late String stamp;

  setUp(() async {
    if (!configured) return;
    token = tokenFile.readAsStringSync().trim();
    [owner, name] = _repo.split('/');
    api = GithubApi(token: token);
    root = Directory.systemTemp.createTempSync('gitphoto_journey_');
    db = AppDatabase.open(p.join(root.path, 'app.db'));
    stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final store = FakeSecretStore()..values[SecretKeys.githubToken] = token;
    if (keyFile.existsSync()) {
      store.values[SecretKeys.aiProviderKey('mistral')] = keyFile
          .readAsStringSync()
          .trim();
    }
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        libraryPathsProvider.overrideWithValue(
          LibraryPaths(
            root: p.join(root.path, 'support'),
            temporaryDir: p.join(root.path, 'cache'),
          )..ensureCreated(),
        ),
        secretStoreProvider.overrideWithValue(store),
        toolAvailabilityProvider.overrideWith(
          (ref) async => const ToolAvailability(supportsExternalTools: false),
        ),
        agentEnvironmentProvider.overrideWith(
          (ref) => AppAgentEnvironment(
            ref,
            documentsDir: () async => p.join(root.path, 'docs'),
          ),
        ),
      ],
    );
    container.listen(publishQueueProvider, (_, _) {});
    await container.read(toolAvailabilityProvider.future);
    expect(
      await container.read(githubSessionProvider.future),
      isA<GithubConnected>(),
    );
  });

  tearDown(() {
    if (!configured) return;
    container.dispose();
    db.close();
    root.deleteSync(recursive: true);
  });

  Future<int> importPhoto(String fileName, {bool gps = false}) async {
    final src = writeFile(
      Directory(p.join(root.path, 'src')),
      fileName,
      makeJpeg(
        width: 1600,
        height: 1200,
        seed: stamp.hashCode,
        gps: gps,
        dateTimeOriginal: '2024:07:14 10:00:00',
      ),
    );
    final r = await container
        .read(mediaImporterProvider)
        .importOne(ImportCandidate(src.path));
    expect(r.outcome, ImportOutcome.imported, reason: r.error);
    return r.mediaId!;
  }

  Future<Map<String, String>> remoteFiles() async {
    final head = await api.getBranchHead(owner, name, 'main');
    return (await api.getTree(
      owner,
      name,
      await api.getCommitTree(owner, name, head),
    )).files;
  }

  testWidgets('Git LFS (lecture seule) : objet existant reconnu', (
    tester,
  ) async {
    final files = await remoteFiles();
    final attributes = files['.gitattributes'];
    expect(attributes, isNotNull, reason: 'aucun fichier LFS publié');
    final rules = utf8.decode(await api.getBlob(owner, name, attributes!));
    final lfsPath = rules
        .split('\n')
        .where((l) => l.contains('filter=lfs'))
        // Règle ancrée : « /chemin exact », espaces échappés.
        .map((l) => l.split(' ').first.replaceAll(r'\ ', ' '))
        .map((path) => path.startsWith('/') ? path.substring(1) : path)
        .firstWhere(files.containsKey);
    final pointer = utf8.decode(
      await api.getBlob(owner, name, files[lfsPath]!),
    );
    final oid = RegExp(r'oid sha256:([0-9a-f]{64})').firstMatch(pointer)![1]!;
    final size = int.parse(RegExp(r'size (\d+)').firstMatch(pointer)![1]!);
    final lfs = LfsClient(token: token);
    expect(await lfs.exists(owner, name, LfsObject(oid, size)), isTrue);
    expect(await lfs.exists(owner, name, LfsObject('0' * 64, 1)), isFalse);
  }, skip: !configured);

  testWidgets(
    'parcours classique : import, optimisation, publication, historique',
    (tester) async {
      final original = await importPhoto('vacances-$stamp.jpg', gps: true);
      final media = container.read(mediaRepositoryProvider);
      expect(media.findById(original)!.hasGps, isTrue);

      // Optimisation réelle : copie plus légère, sans position GPS.
      final version = await container
          .read(mediaVersionServiceProvider)
          .saveImageVersion(
            media.findById(original)!,
            imagePresets[ImagePreset.light]!,
            suffix: 'leger',
          );
      final copy = media.findById(version.mediaId!)!;
      expect(copy.hasGps, isFalse);
      expect(copy.sizeBytes, lessThan(media.findById(original)!.sizeBytes));

      final repo = (await api.listRepos()).firstWhere(
        (r) => r.fullName.toLowerCase() == _repo.toLowerCase(),
      );
      final folder = 'gitphoto-tests/phase8-$stamp';
      final controller = container.read(publishControllerProvider.notifier);
      await controller.analyze(
        media: [copy],
        target: PublishTarget(repo: repo, branch: 'main', folder: folder),
      );
      final planned = container.read(publishControllerProvider);
      expect(planned, isA<PublishPlanned>());
      expect((planned as PublishPlanned).plan.uploads, hasLength(1));
      await controller.publish('Phase 8 : parcours complet $stamp');
      final done = container.read(publishControllerProvider);
      expect(done, isA<PublishSucceeded>(), reason: '$done');
      final result = (done as PublishSucceeded).result;
      expect(result.verified, isTrue);

      // Contenu exact sur GitHub.
      final remote = await remoteFiles();
      expect(
        remote['$folder/${copy.fileName}'],
        gitBlobSha(File(copy.storedPath).readAsBytesSync()),
      );
      // Historique.
      final op = OperationsRepository(db).list().first;
      expect(op.status, OperationStatus.success);
      expect(op.commitSha, result.commitSha);

      // Republier : déjà présent, aucun envoi.
      await controller.analyze(
        media: [copy],
        target: PublishTarget(repo: repo, branch: 'main', folder: folder),
      );
      final again = container.read(publishControllerProvider) as PublishPlanned;
      expect(again.plan.uploads, isEmpty);
      expect(again.plan.count(PlannedAction.skipIdentical), 1);
      // ignore: avoid_print
      print('Parcours classique : commit ${result.commitSha.substring(0, 7)}');
    },
    skip: !configured,
  );

  testWidgets(
    'parcours IA : Mistral propose, l’utilisateur confirme, GitHub vérifié',
    (tester) async {
      final id = await importPhoto('agent-$stamp.jpg');
      container.read(gallerySelectionProvider.notifier).selectAll([id]);
      PreferencesRepository(db)
        ..write(AiPreferenceKeys.enabled, 'true')
        ..write(AiPreferenceKeys.consent(AiProviderId.mistral), 'true')
        ..write(
          AiPreferenceKeys.model(AiProviderId.mistral),
          'mistral-small-latest',
        );
      container.invalidate(aiSettingsProvider);
      final folder = 'gitphoto-tests/phase8-ia-$stamp';
      final agent = container.read(agentControllerProvider.notifier);
      await agent.send(
        'Publie la photo sélectionnée dans le dépôt $_repo, branche main, '
        'dans le dossier $folder, avec le message « Test agent $stamp ». '
        'Ne l’optimise pas.',
      );
      final entries = container.read(agentControllerProvider).entries;
      final errors = entries.whereType<ErrorEntry>();
      expect(errors, isEmpty, reason: '${errors.map((e) => e.error)}');
      for (final e in entries.whereType<AssistantEntry>()) {
        // ignore: avoid_print
        print('Agent : ${e.text.replaceAll('\n', ' ⏎ ')} (outils : ${e.toolsUsed})');
      }
      final planEntry = entries.whereType<PlanEntry>().single;
      final publish = planEntry.plan.actions.whereType<PublishAction>().single;
      expect(publish.repo.fullName.toLowerCase(), _repo.toLowerCase());
      expect(publish.folder, folder);
      expect(publish.refs.mediaIds, [id]);
      // Rien n'a été publié avant la confirmation.
      expect(OperationsRepository(db).list(), isEmpty);

      final report = await agent.confirm(planEntry.id);
      expect(report!.succeeded, isTrue, reason: report.describeForModel());
      final step = report.steps.single;
      expect(step.publishResult!.verified, isTrue);
      final m = container.read(mediaRepositoryProvider).findById(id)!;
      final remote = await remoteFiles();
      expect(
        remote['$folder/${m.fileName}'],
        gitBlobSha(File(m.storedPath).readAsBytesSync()),
      );
      // ignore: avoid_print
      print(
        'Parcours IA : plan « ${planEntry.plan.summary} », commit '
        '${step.publishResult!.commitSha.substring(0, 7)}',
      );
    },
    skip: !configured || !keyFile.existsSync(),
  );
}
