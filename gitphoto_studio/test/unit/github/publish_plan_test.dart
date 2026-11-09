import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/github/data/lfs_client.dart';
import 'package:gitphoto_studio/features/github/domain/github_models.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:gitphoto_studio/features/publishing/domain/transport_selector.dart';

const mib = 1024 * 1024;

PublishCandidate c(int id, String name, {String? sha, int size = 1000}) =>
    PublishCandidate(
      mediaId: id,
      fileName: name,
      localPath: '/lib/$name',
      sizeBytes: size,
      gitBlobSha: sha ?? 'sha-$id',
    );

void main() {
  group('empreinte Git', () {
    test('identique à « git hash-object »', () {
      expect(
        gitBlobSha(utf8.encode('hello\n')),
        'ce013625030ba8dba906f756967f9e9ca394464a',
      );
      expect(gitBlobSha([]), 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391');
    });

    test('version fichier en flux = version mémoire', () async {
      final dir = Directory.systemTemp.createTempSync('gitphoto_blob_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final bytes = List<int>.generate(300000, (i) => i % 251);
      final f = File('${dir.path}/x.bin')..writeAsBytesSync(bytes);
      expect(await gitBlobShaOfFile(f.path), gitBlobSha(bytes));
    });
  });

  group('normalizeFolder', () {
    test('nettoie les barres et accepte la racine', () {
      expect(PublishPlanner.normalizeFolder(' /photos/2024/ '), 'photos/2024');
      expect(PublishPlanner.normalizeFolder(''), '');
      expect(PublishPlanner.normalizeFolder('/'), '');
    });
    test('refuse les chemins dangereux', () {
      for (final bad in ['../x', 'a/../b', '.git', 'a//b', 'a?b']) {
        expect(PublishPlanner.normalizeFolder(bad), isNull, reason: bad);
      }
    });
  });

  const planner = PublishPlanner();

  test('nouveaux fichiers, identiques et conflits', () {
    final plan = planner.plan(
      candidates: [
        c(1, 'a.jpg'),
        c(2, 'b.jpg', sha: 'same'),
        c(3, 'c.jpg'),
      ],
      folder: 'photos',
      remote: const RemoteTree({
        'photos/b.jpg': 'same',
        'photos/c.jpg': 'different',
        'photos/c (2).jpg': 'autre',
      }),
      repositoryIsEmpty: false,
    );
    expect(plan.files.map((f) => (f.remotePath, f.action)).toList(), [
      ('photos/a.jpg', PlannedAction.add),
      ('photos/b.jpg', PlannedAction.skipIdentical),
      ('photos/c (3).jpg', PlannedAction.renamed),
    ]);
    expect(plan.uploads, hasLength(2));
    expect(plan.uploadBytes, 2000);
  });

  test('écrasement uniquement sur demande explicite', () {
    PlannedAction actionFor({
      ConflictPolicy policy = ConflictPolicy.rename,
      Set<int> ids = const {},
    }) => planner
        .plan(
          candidates: [c(1, 'a.jpg')],
          folder: '',
          remote: const RemoteTree({'a.jpg': 'old'}),
          repositoryIsEmpty: false,
          policy: policy,
          overwriteMediaIds: ids,
        )
        .files
        .single
        .action;
    expect(actionFor(), PlannedAction.renamed);
    expect(actionFor(ids: {1}), PlannedAction.overwrite);
    expect(
      actionFor(policy: ConflictPolicy.overwrite),
      PlannedAction.overwrite,
    );
  });

  test('deux médias de même nom dans un lot : aucun ne s\'écrase', () {
    final plan = planner.plan(
      candidates: [c(1, 'IMG.jpg'), c(2, 'img.JPG')],
      folder: 'p',
      remote: RemoteTree.empty,
      repositoryIsEmpty: true,
    );
    final paths = plan.files.map((f) => f.remotePath).toList();
    expect(paths, ['p/IMG.jpg', 'p/img (2).JPG']);
    expect(plan.repositoryIsEmpty, isTrue);
  });

  test('tailles : Git LFS au-delà de 50 Mio, refus au-delà de 2 Gio', () {
    PublishCandidate big(int id, int size) => PublishCandidate(
      mediaId: id,
      fileName: 'v$id.mp4',
      localPath: '/lib/v$id.mp4',
      sizeBytes: size,
      gitBlobSha: 'g$id',
      contentSha256: 'a' * 64,
    );
    final plan = planner.plan(
      candidates: [
        big(1, 60 * mib),
        big(2, 3 * 1024 * mib),
        c(3, 'sans-empreinte.mp4', size: 60 * mib),
      ],
      folder: '',
      remote: RemoteTree.empty,
      repositoryIsEmpty: false,
    );
    expect(plan.files[0].action, PlannedAction.add);
    expect(plan.files[0].strategy, PublishStrategy.gitLfs);
    expect(plan.files[0].expectedTreeSha, lfsPointerSha('a' * 64, 60 * mib));
    expect(plan.files[1].blockReason, BlockReason.tooLargeForLfs);
    // Pas d'empreinte SHA-256 : LFS impossible, donc bloqué.
    expect(plan.files[2].blockReason, BlockReason.requiresGitLfs);
    expect(plan.usesLfs, isTrue);
  });

  test('LFS : pointeur identique déjà présent sur GitHub → ignoré', () {
    final sha = 'b' * 64;
    final plan = planner.plan(
      candidates: [
        PublishCandidate(
          mediaId: 1,
          fileName: 'v.mp4',
          localPath: '/l/v.mp4',
          sizeBytes: 60 * mib,
          gitBlobSha: 'x',
          contentSha256: sha,
        ),
      ],
      folder: 'videos',
      remote: RemoteTree({'videos/v.mp4': lfsPointerSha(sha, 60 * mib)}),
      repositoryIsEmpty: false,
    );
    expect(plan.files.single.action, PlannedAction.skipIdentical);
  });

  test('pointeur LFS conforme à la spécification', () {
    final o = LfsObject('c' * 64, 1234);
    expect(
      o.pointer,
      'version https://git-lfs.github.com/spec/v1\noid sha256:${'c' * 64}\n'
      'size 1234\n',
    );
    expect(o.pointerBlobSha, lfsPointerSha('c' * 64, 1234));
  });

  group('reprise (replan)', () {
    ({
      PublishCandidate candidate,
      String remotePath,
      PublishStrategy strategy,
      bool overwrite,
    })
    e(String path, String sha, {bool overwrite = false}) => (
      candidate: c(1, path, sha: sha),
      remotePath: path,
      strategy: PublishStrategy.githubApi,
      overwrite: overwrite,
    );

    test('déjà publié → ignoré ; absent → ajouté', () {
      final plan = planner.replan(
        entries: [e('p/a.jpg', 'A'), e('p/b.jpg', 'B')],
        folder: '',
        remote: const RemoteTree({'p/a.jpg': 'A'}),
        repositoryIsEmpty: false,
      );
      expect(plan.files.map((f) => f.action), [
        PlannedAction.skipIdentical,
        PlannedAction.add,
      ]);
    });

    test('chemin modifié par un autre auteur : conflit', () {
      expect(
        () => planner.replan(
          entries: [e('p/a.jpg', 'A')],
          folder: '',
          remote: const RemoteTree({'p/a.jpg': 'AUTRE'}),
          repositoryIsEmpty: false,
        ),
        throwsA(isA<PublishConflictException>()),
      );
    });

    test('remplacement décidé à l\'analyse : conservé', () {
      final plan = planner.replan(
        entries: [e('p/a.jpg', 'A', overwrite: true)],
        folder: '',
        remote: const RemoteTree({'p/a.jpg': 'ANCIEN'}),
        repositoryIsEmpty: false,
      );
      expect(plan.files.single.action, PlannedAction.overwrite);
    });
  });

  group('.gitattributes', () {
    test('règles ajoutées sans doublon, contenu existant conservé', () {
      final updated = withLfsRules('*.psd binary\n', [
        'videos/été 2024.mp4',
        'videos/été 2024.mp4',
      ])!;
      expect(
        updated,
        '*.psd binary\n'
        '/videos/été[[:space:]]2024.mp4 filter=lfs diff=lfs merge=lfs -text\n',
      );
      expect(withLfsRules(updated, ['videos/été 2024.mp4']), isNull);
    });

    test('caractères spéciaux échappés', () {
      expect(escapeAttributesPattern('a/[x]#1!.mp4'), r'/a/\[x\]\#1\!.mp4');
      expect(
        withLfsRules(null, ['v.mp4']),
        '/v.mp4 filter=lfs diff=lfs merge=lfs -text\n',
      );
    });
  });

  test('noms nettoyés avant publication', () {
    final plan = planner.plan(
      candidates: [c(1, 'photo?.jpg')],
      folder: '',
      remote: RemoteTree.empty,
      repositoryIsEmpty: false,
    );
    expect(plan.files.single.remotePath, 'photo_.jpg');
  });
}
