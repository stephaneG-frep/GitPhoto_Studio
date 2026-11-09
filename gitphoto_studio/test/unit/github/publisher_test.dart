import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';
import 'package:gitphoto_studio/features/github/domain/github_models.dart';
import 'package:gitphoto_studio/features/publishing/application/publisher.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:gitphoto_studio/features/publishing/domain/transport_selector.dart';

import '../../support/fake_github_server.dart';

void main() {
  late Directory dir;
  late FakeGithubServer server;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('gitphoto_pub_');
    server = FakeGithubServer();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  PublishCandidate file(int id, String name, String content) {
    final f = File('${dir.path}/$name')..writeAsStringSync(content);
    final bytes = utf8.encode(content);
    return PublishCandidate(
      mediaId: id,
      fileName: name,
      localPath: f.path,
      sizeBytes: bytes.length,
      gitBlobSha: gitBlobSha(bytes),
    );
  }

  Future<PublishPlan> planFor(
    FakeRepo repo,
    List<PublishCandidate> files,
  ) async {
    final api = server.api();
    if (repo.isEmpty) {
      return const PublishPlanner().plan(
        candidates: files,
        folder: 'photos',
        remote: RemoteTree.empty,
        repositoryIsEmpty: true,
      );
    }
    final head = await api.getBranchHead(repo.owner, repo.name, 'main');
    final tree = await api.getTree(
      repo.owner,
      repo.name,
      await api.getCommitTree(repo.owner, repo.name, head),
    );
    return const PublishPlanner().plan(
      candidates: files,
      folder: 'photos',
      remote: tree,
      repositoryIsEmpty: false,
    );
  }

  test('plusieurs fichiers en un seul commit, vérifié', () async {
    final repo = server.addRepo('testeur', 'album');
    final before = repo.branches['main'];
    final plan = await planFor(repo, [
      file(1, 'a.jpg', 'AAA'),
      file(2, 'b.jpg', 'BBB'),
      file(3, 'c.jpg', 'CCC'),
    ]);
    final steps = <PublishStep>{};

    final result = await Publisher(server.api()).publish(
      owner: 'testeur',
      repo: 'album',
      branch: 'main',
      message: 'Ajout de 3 médias',
      plan: plan,
      onProgress: (s, _, _) => steps.add(s),
    );

    expect(result.verified, isTrue);
    expect(result.commitCount, 1);
    expect(repo.branches['main'], result.commitSha);
    final commit = repo.commits[result.commitSha]!;
    expect(commit.parents, [before]);
    expect(commit.message, 'Ajout de 3 médias');
    final files = repo.filesOf('main');
    expect(utf8.decode(files['photos/b.jpg']!), 'BBB');
    expect(
      files.keys,
      contains('README.md'),
      reason: 'contenu existant conservé',
    );
    expect(steps, PublishStep.values.toSet());
    expect(
      result.htmlUrl,
      'https://github.com/testeur/album/commit/${result.commitSha}',
    );
  });

  test('republier : fichiers identiques ignorés, aucun doublon', () async {
    final repo = server.addRepo('testeur', 'album');
    final files = [file(1, 'a.jpg', 'AAA')];
    await Publisher(server.api()).publish(
      owner: 'testeur',
      repo: 'album',
      branch: 'main',
      message: 'm',
      plan: await planFor(repo, files),
    );
    final commitsAfterFirst = repo.commits.length;
    final second = await planFor(repo, files);
    expect(second.files.single.action, PlannedAction.skipIdentical);
    expect(second.uploads, isEmpty);
    expect(
      () => Publisher(server.api()).publish(
        owner: 'testeur',
        repo: 'album',
        branch: 'main',
        message: 'm',
        plan: second,
      ),
      throwsA(isA<GithubException>()),
    );
    expect(repo.commits.length, commitsAfterFirst);
  });

  test(
    'branche avancée sur un autre fichier : nouvel essai automatique',
    () async {
      final repo = server.addRepo('testeur', 'album');
      final plan = await planFor(repo, [file(1, 'a.jpg', 'AAA')]);
      server.beforeRefUpdate = (r) {
        server.beforeRefUpdate = null;
        r.commitFiles({
          'autre.txt': [1],
        }, 'Commit concurrent');
      };
      final result = await Publisher(server.api()).publish(
        owner: 'testeur',
        repo: 'album',
        branch: 'main',
        message: 'm',
        plan: plan,
      );
      expect(result.retriedAfterConflict, 1);
      expect(result.verified, isTrue);
      final files = repo.filesOf('main');
      expect(files.keys, containsAll(['photos/a.jpg', 'autre.txt']));
      final parent = repo.commits[result.commitSha]!.parents.single;
      expect(repo.commits[parent]!.message, 'Commit concurrent');
    },
  );

  test(
    'même fichier modifié par un autre auteur : conflit, rien de publié',
    () async {
      final repo = server.addRepo('testeur', 'album');
      final plan = await planFor(repo, [file(1, 'a.jpg', 'AAA')]);
      server.afterBlob = (r) {
        server.afterBlob = null;
        r.commitFiles({
          'photos/a.jpg': [9, 9],
        }, 'Commit concurrent');
      };
      await expectLater(
        Publisher(server.api()).publish(
          owner: 'testeur',
          repo: 'album',
          branch: 'main',
          message: 'm',
          plan: plan,
        ),
        throwsA(
          isA<GithubException>().having(
            (e) => e.kind,
            'kind',
            GithubErrorKind.conflict,
          ),
        ),
      );
      expect(repo.filesOf('main')['photos/a.jpg'], [9, 9]);
      expect(repo.commits[repo.branches['main']]!.message, 'Commit concurrent');
    },
  );

  test("annulation avant l'avancée de la branche : rien de publié", () async {
    final repo = server.addRepo('testeur', 'album');
    final before = repo.branches['main'];
    final plan = await planFor(repo, [
      file(1, 'a.jpg', 'A'),
      file(2, 'b.jpg', 'B'),
    ]);
    var uploads = 0;
    await expectLater(
      Publisher(server.api()).publish(
        owner: 'testeur',
        repo: 'album',
        branch: 'main',
        message: 'm',
        plan: plan,
        hooks: PublishHooks(
          onUploaded: (_, _) => uploads++,
          isCancelled: () => uploads >= 1,
        ),
      ),
      throwsA(isA<PublishCancelled>()),
    );
    expect(repo.branches['main'], before);
  });

  test('reprise : blobs déjà envoyés non renvoyés', () async {
    final repo = server.addRepo('testeur', 'album');
    final a = file(1, 'a.jpg', 'AAA');
    final plan = await planFor(repo, [a, file(2, 'b.jpg', 'BBB')]);
    await server.api().createBlob('testeur', 'album', utf8.encode('AAA'));
    server.requests.clear();
    final result = await Publisher(server.api()).publish(
      owner: 'testeur',
      repo: 'album',
      branch: 'main',
      message: 'm',
      plan: plan,
      hooks: PublishHooks(alreadyUploaded: {'photos/a.jpg': a.gitBlobSha}),
    );
    expect(result.verified, isTrue);
    expect(
      server.requests.where((r) => r.endsWith('/git/blobs')),
      hasLength(1),
    );
  });

  test('reprise : blob disparu de GitHub → renvoyé automatiquement', () async {
    final repo = server.addRepo('testeur', 'album');
    final a = file(1, 'a.jpg', 'AAA');
    final plan = await planFor(repo, [a]);
    final result = await Publisher(server.api()).publish(
      owner: 'testeur',
      repo: 'album',
      branch: 'main',
      message: 'm',
      plan: plan,
      hooks: PublishHooks(alreadyUploaded: {'photos/a.jpg': a.gitBlobSha}),
    );
    expect(result.verified, isTrue);
    expect(utf8.decode(repo.filesOf('main')['photos/a.jpg']!), 'AAA');
  });

  group('Git LFS', () {
    PublishCandidate bigFile(int id, String name, int size) {
      final bytes = List<int>.generate(size, (i) => (i * 7 + id) % 256);
      final f = File('${dir.path}/$name')..writeAsBytesSync(bytes);
      return PublishCandidate(
        mediaId: id,
        fileName: name,
        localPath: f.path,
        sizeBytes: bytes.length,
        gitBlobSha: gitBlobSha(bytes),
        contentSha256: sha256.convert(bytes).toString(),
      );
    }

    const planner = PublishPlanner(
      selector: TransportSelector(
        limits: PublishLimits(lfsThresholdBytes: 1000, warnBytes: 1000),
      ),
    );

    Future<PublishPlan> lfsPlan(
      FakeRepo repo,
      List<PublishCandidate> files,
    ) async {
      final api = server.api();
      if (repo.isEmpty) {
        return planner.plan(
          candidates: files,
          folder: 'videos',
          remote: RemoteTree.empty,
          repositoryIsEmpty: true,
        );
      }
      final head = await api.getBranchHead(repo.owner, repo.name, 'main');
      return planner.plan(
        candidates: files,
        folder: 'videos',
        remote: await api.getTree(
          repo.owner,
          repo.name,
          await api.getCommitTree(repo.owner, repo.name, head),
        ),
        repositoryIsEmpty: false,
      );
    }

    test('gros fichier : contenu au stockage LFS, pointeur et .gitattributes '
        'dans le même commit', () async {
      final repo = server.addRepo(
        'testeur',
        'album',
        files: {'.gitattributes': utf8.encode('*.psd binary\n')},
      );
      final big = bigFile(1, 'film 1.mp4', 5000);
      final small = file(2, 'note.txt', 'petit');
      final plan = await lfsPlan(repo, [big, small]);
      expect(plan.files.first.isLfs, isTrue);
      expect(plan.files.last.isLfs, isFalse);

      final result = await Publisher(server.api(), lfs: server.lfs()).publish(
        owner: 'testeur',
        repo: 'album',
        branch: 'main',
        message: 'Vidéo',
        plan: plan,
      );
      expect(result.verified, isTrue);
      expect(result.commitCount, 1);
      expect(server.lfsObjects[big.contentSha256], hasLength(5000));
      final files = repo.filesOf('main');
      final pointer = utf8.decode(files['videos/film 1.mp4']!);
      expect(pointer, startsWith('version https://git-lfs.github.com/spec/v1'));
      expect(pointer, contains('oid sha256:${big.contentSha256}'));
      expect(pointer, contains('size 5000'));
      expect(utf8.decode(files['videos/note.txt']!), 'petit');
      final attributes = utf8.decode(files['.gitattributes']!);
      expect(attributes, startsWith('*.psd binary\n'));
      expect(
        attributes,
        contains(
          '/videos/film[[:space:]]1.mp4 filter=lfs diff=lfs merge=lfs -text',
        ),
      );
    });

    test("republication LFS : pointeur reconnu, rien d'envoyé", () async {
      final repo = server.addRepo('testeur', 'album');
      final big = bigFile(1, 'v.mp4', 3000);
      await Publisher(server.api(), lfs: server.lfs()).publish(
        owner: 'testeur',
        repo: 'album',
        branch: 'main',
        message: 'm',
        plan: await lfsPlan(repo, [big]),
      );
      final again = await lfsPlan(repo, [big]);
      expect(again.files.single.action, PlannedAction.skipIdentical);
    });

    test('dépôt vide avec LFS : .gitattributes puis un seul commit', () async {
      final repo = server.addRepo('testeur', 'vide', empty: true);
      final plan = await lfsPlan(repo, [
        bigFile(1, 'a.mp4', 2000),
        bigFile(2, 'b.mp4', 2500),
      ]);
      final result = await Publisher(server.api(), lfs: server.lfs()).publish(
        owner: 'testeur',
        repo: 'vide',
        branch: 'main',
        message: 'Init',
        plan: plan,
      );
      expect(result.commitCount, 2);
      expect(result.verified, isTrue);
      expect(repo.filesOf('main').keys, {
        '.gitattributes',
        'videos/a.mp4',
        'videos/b.mp4',
      });
      expect(server.lfsObjects, hasLength(2));
    });

    test('jeton refusé par LFS : erreur explicite, rien de publié', () async {
      final repo = server.addRepo('testeur', 'album');
      final before = repo.branches['main'];
      final plan = await lfsPlan(repo, [bigFile(1, 'v.mp4', 3000)]);
      await expectLater(
        Publisher(server.api(), lfs: server.lfs('ghp_mauvais')).publish(
          owner: 'testeur',
          repo: 'album',
          branch: 'main',
          message: 'm',
          plan: plan,
        ),
        throwsA(
          isA<GithubException>().having(
            (e) => e.kind,
            'kind',
            GithubErrorKind.unauthorized,
          ),
        ),
      );
      expect(repo.branches['main'], before);
    });
  });

  test('dépôt vide : initialisation puis un seul commit, vérifié', () async {
    final repo = server.addRepo('testeur', 'vide', empty: true);
    final plan = await planFor(repo, [
      file(1, 'a.jpg', 'AAA'),
      file(2, 'b.jpg', 'BBB'),
    ]);
    final result = await Publisher(server.api()).publish(
      owner: 'testeur',
      repo: 'vide',
      branch: 'main',
      message: 'Premier envoi',
      plan: plan,
    );
    expect(result.commitCount, 2);
    expect(result.verified, isTrue);
    expect(repo.filesOf('main').keys, {'photos/a.jpg', 'photos/b.jpg'});
    expect(repo.commits[result.commitSha]!.message, 'Premier envoi (2/2)');
  });

  test('permissions insuffisantes : erreur explicite', () async {
    final repo = server.addRepo('testeur', 'lecture', canPush: false);
    final plan = await planFor(repo, [file(1, 'a.jpg', 'AAA')]);
    await expectLater(
      Publisher(server.api()).publish(
        owner: 'testeur',
        repo: 'lecture',
        branch: 'main',
        message: 'm',
        plan: plan,
      ),
      throwsA(
        isA<GithubException>().having(
          (e) => e.kind,
          'kind',
          GithubErrorKind.forbidden,
        ),
      ),
    );
  });

  test(
    'fichier local modifié après l\'analyse : publication refusée',
    () async {
      final repo = server.addRepo('testeur', 'album');
      final f = file(1, 'a.jpg', 'AAA');
      final plan = await planFor(repo, [f]);
      File(f.localPath).writeAsStringSync('MODIFIÉ');
      await expectLater(
        Publisher(server.api()).publish(
          owner: 'testeur',
          repo: 'album',
          branch: 'main',
          message: 'm',
          plan: plan,
        ),
        throwsA(isA<GithubException>()),
      );
      expect(repo.filesOf('main').containsKey('photos/a.jpg'), isFalse);
    },
  );
}
