import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/gallery/application/gallery_providers.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/github/application/github_session.dart';
import 'package:gitphoto_studio/features/github/domain/github_models.dart';
import 'package:gitphoto_studio/features/publishing/application/publish_controller.dart';
import 'package:gitphoto_studio/features/publishing/application/publish_queue.dart';
import 'package:gitphoto_studio/features/publishing/data/operations_repository.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:path/path.dart' as p;

import '../../support/fake_github_server.dart';
import '../../support/fake_secret_store.dart';

void main() {
  late Directory root;
  late AppDatabase db;
  late FakeGithubServer server;
  late FakeSecretStore store;
  late ProviderContainer container;
  late FakeRepo repo;

  const ghRepo = GithubRepo(
    owner: 'testeur',
    name: 'album',
    isPrivate: true,
    htmlUrl: 'https://github.com/testeur/album',
    canPush: true,
    defaultBranch: 'main',
  );

  Future<void> start({bool connected = true}) async {
    if (connected) store.values[SecretKeys.githubToken] = server.validToken;
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        libraryPathsProvider.overrideWithValue(
          LibraryPaths(root: root.path, temporaryDir: p.join(root.path, 'tmp'))
            ..ensureCreated(),
        ),
        secretStoreProvider.overrideWithValue(store),
        githubApiFactoryProvider.overrideWithValue(server.api),
        lfsClientFactoryProvider.overrideWithValue(server.lfs),
      ],
    );
    container.listen(publishQueueProvider, (_, _) {});
    container.read(publishQueueProvider.notifier).retryDelays = const [
      Duration(milliseconds: 10),
      Duration(milliseconds: 10),
    ];
    await container.read(githubSessionProvider.future);
  }

  int addMedia(String name, String content) {
    final f = File(p.join(root.path, name))..writeAsStringSync(content);
    return MediaRepository(db).insert(
      NewMedia(
        fileName: name,
        storedPath: f.path,
        sourcePath: f.path,
        kind: MediaKind.image,
        sizeBytes: content.length,
        sha256: sha256.convert(utf8.encode(content)).toString(),
        importedAt: DateTime(2025),
      ),
    );
  }

  Future<PublishPlan> planFor(List<int> mediaIds) async {
    final api = server.api();
    final head = await api.getBranchHead('testeur', 'album', 'main');
    final tree = await api.getTree(
      'testeur',
      'album',
      await api.getCommitTree('testeur', 'album', head),
    );
    final media = MediaRepository(db);
    return const PublishPlanner().plan(
      candidates: [
        for (final id in mediaIds)
          if (media.findById(id) case final m?)
            PublishCandidate(
              mediaId: m.id,
              fileName: m.fileName,
              localPath: m.storedPath,
              sizeBytes: m.sizeBytes,
              gitBlobSha: gitBlobSha(File(m.storedPath).readAsBytesSync()),
              contentSha256: m.sha256,
            ),
      ],
      folder: 'p',
      remote: tree,
      repositoryIsEmpty: false,
    );
  }

  OperationsRepository ops() => OperationsRepository(db);

  setUp(() {
    root = Directory.systemTemp.createTempSync('gitphoto_queue_');
    db = AppDatabase.inMemory();
    server = FakeGithubServer();
    store = FakeSecretStore();
    repo = server.addRepo('testeur', 'album');
  });
  tearDown(() {
    container.dispose();
    db.close();
    root.deleteSync(recursive: true);
  });

  test(
    'publication par la file : un commit, fichiers marqués publiés',
    () async {
      await start();
      final a = addMedia('a.jpg', 'AAA');
      final b = addMedia('b.jpg', 'BBB');
      final outcome = await container
          .read(publishQueueProvider.notifier)
          .enqueue(
            repo: ghRepo,
            branch: 'main',
            message: 'Lot',
            plan: await planFor([a, b]),
          );

      expect(outcome.result!.verified, isTrue);
      expect(repo.filesOf('main').keys, containsAll(['p/a.jpg', 'p/b.jpg']));
      final op = ops().list().single;
      expect(op.status, OperationStatus.success);
      expect(op.commitSha, repo.branches['main']);
      expect(op.entries.map((e) => e.status), everyElement(EntryStatus.done));
      expect(op.attempts, 1);
    },
  );

  test(
    'file conservée hors connexion ; doublon refusé ; reprise à la connexion',
    () async {
      await start(connected: false);
      final a = addMedia('a.jpg', 'AAA');
      final plan = await planFor([a]);
      final queue = container.read(publishQueueProvider.notifier);
      final first = queue.enqueue(
        repo: ghRepo,
        branch: 'main',
        message: 'm',
        plan: plan,
      );
      expect(ops().list().single.status, OperationStatus.queued);

      await expectLater(
        queue.enqueue(repo: ghRepo, branch: 'main', message: 'm', plan: plan),
        throwsA(isA<DuplicatePublicationException>()),
      );

      // Connexion : la file reprend d'elle-même.
      await container
          .read(githubSessionProvider.notifier)
          .connect(server.validToken);
      final outcome = await first;
      expect(outcome.result, isNotNull);
      expect(repo.filesOf('main').containsKey('p/a.jpg'), isTrue);
    },
  );

  test('reprise après interruption : publication déjà aboutie reconnue, '
      'aucun nouveau commit', () async {
    await start();
    final a = addMedia('a.jpg', 'AAA');
    final plan = await planFor([a]);
    final repoId = ops().upsertRepository(owner: 'testeur', name: 'album');
    final id = ops().enqueue(
      repositoryId: repoId,
      branch: 'main',
      commitMessage: 'm',
      entries: [
        for (final f in plan.uploads)
          QueueEntryInput(
            mediaId: f.candidate.mediaId,
            remotePath: f.remotePath,
            strategy: f.strategy.name,
            gitBlobSha: f.candidate.gitBlobSha,
            sizeBytes: f.candidate.sizeBytes,
          ),
      ],
    );
    // Le commit a abouti sur GitHub, puis l'application a été fermée.
    ops().setStatus(id, OperationStatus.running);
    repo.commitFiles({'p/a.jpg': utf8.encode('AAA')}, 'm');
    final commits = repo.commits.length;
    expect(ops().markInterrupted(), 1);

    final outcome = await container
        .read(publishQueueProvider.notifier)
        .resume(id);
    expect(outcome.alreadyPublished, isTrue);
    expect(repo.commits.length, commits, reason: 'aucun doublon');
    final op = ops().find(id)!;
    expect(op.status, OperationStatus.success);
    expect(op.entries.single.status, EntryStatus.skipped);
  });

  test('perte de connexion : nouvel essai automatique puis succès', () async {
    await start();
    final a = addMedia('a.jpg', 'AAA');
    server.overrides[RegExp(r'^POST .*/git/blobs$')] = () =>
        FakeGithubServer.json(502, {'message': 'Bad gateway'});
    final outcome = await container
        .read(publishQueueProvider.notifier)
        .enqueue(
          repo: ghRepo,
          branch: 'main',
          message: 'm',
          plan: await planFor([a]),
        );
    expect(outcome.result, isNotNull);
    final op = ops().list().single;
    expect(op.status, OperationStatus.success);
    expect(op.attempts, 2);
  });

  test('annulation d\'une opération en attente', () async {
    await start(connected: false);
    final a = addMedia('a.jpg', 'AAA');
    final queue = container.read(publishQueueProvider.notifier);
    final pending = queue.enqueue(
      repo: ghRepo,
      branch: 'main',
      message: 'm',
      plan: await planFor([a]),
    );
    final id = ops().list().single.id;
    queue.cancel(id);
    expect((await pending).cancelled, isTrue);
    final op = ops().find(id)!;
    expect(op.status, OperationStatus.cancelled);
    expect(op.entries.single.status, EntryStatus.cancelled);
    expect(repo.filesOf('main').containsKey('p/a.jpg'), isFalse);
  });

  test(
    'conflit à l\'exécution : rien de publié, opération reprenable',
    () async {
      await start(connected: false);
      final a = addMedia('a.jpg', 'AAA');
      final queue = container.read(publishQueueProvider.notifier);
      final pending = queue.enqueue(
        repo: ghRepo,
        branch: 'main',
        message: 'm',
        plan: await planFor([a]),
      );
      // Quelqu'un publie un autre contenu au même chemin entre-temps.
      repo.commitFiles({'p/a.jpg': utf8.encode('AUTRE')}, 'autre');
      await container
          .read(githubSessionProvider.notifier)
          .connect(server.validToken);
      final outcome = await pending;
      expect(outcome.error, isA<PublishConflictException>());
      expect(utf8.decode(repo.filesOf('main')['p/a.jpg']!), 'AUTRE');
      final op = ops().list().single;
      expect(op.status, OperationStatus.failed);
      expect(op.isResumable, isTrue);
    },
  );

  test(
    'média retiré de la bibliothèque avant l\'envoi : échec explicite',
    () async {
      await start(connected: false);
      final a = addMedia('a.jpg', 'AAA');
      final queue = container.read(publishQueueProvider.notifier);
      final pending = queue.enqueue(
        repo: ghRepo,
        branch: 'main',
        message: 'm',
        plan: await planFor([a]),
      );
      MediaRepository(db).deleteByIds([a]);
      await container
          .read(githubSessionProvider.notifier)
          .connect(server.validToken);
      final outcome = await pending;
      expect('${outcome.error}', contains('retiré de la bibliothèque'));
    },
  );

  test('le compteur « en attente » suit la file', () async {
    await start(connected: false);
    final a = addMedia('a.jpg', 'AAA');
    final b = addMedia('b.jpg', 'BBB');
    container
        .read(publishQueueProvider.notifier)
        .enqueue(
          repo: ghRepo,
          branch: 'main',
          message: 'm',
          plan: await planFor([a, b]),
        );
    expect(
      db.count('transfer_queue', where: "status IN ('pending', 'uploaded')"),
      2,
    );
    expect(
      container.read(operationsRepositoryProvider).nextQueued(),
      isNotNull,
    );
  });
}
