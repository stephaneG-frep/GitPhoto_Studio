import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/secrets/platform_secret_store.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/github/data/github_api.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';
import 'package:gitphoto_studio/features/github/domain/github_models.dart';
import 'package:gitphoto_studio/features/publishing/application/publisher.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

/// Test RÉEL contre GitHub, sur un dépôt de test explicitement autorisé.
///
/// Lancement (Linux) :
///   flutter test integration_test/github_real_test.dart -d linux \
///     --dart-define=GITPHOTO_TEST_REPO=proprietaire/depot-de-test
///
/// Le jeton est lu dans ~/.config/gitphoto/test_token (droits 600). Il n'est
/// ni affiché, ni journalisé, ni enregistré dans le trousseau.
/// Le test ajoute des commits dans le dossier `gitphoto-tests/` du dépôt.
const _repo = String.fromEnvironment('GITPHOTO_TEST_REPO');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final tokenFile = File(
    p.join(Platform.environment['HOME'] ?? '', '.config/gitphoto/test_token'),
  );
  final configured = _repo.contains('/') && tokenFile.existsSync();

  testWidgets('trousseau réel : écriture, lecture, effacement', (tester) async {
    const store = PlatformSecretStore();
    expect(await store.status(), SecretStoreStatus.available);
    const key = 'gitphoto.integration.probe';
    await store.write(key, 'valeur-de-test');
    expect(await store.read(key), 'valeur-de-test');
    await store.delete(key);
    expect(await store.read(key), isNull);
  });

  testWidgets(
    'GitHub réel : compte, dépôt, publication vérifiée, republication',
    skip: !configured,
    (tester) async {
      final token = tokenFile.readAsStringSync().trim();
      final [owner, name] = _repo.split('/');
      final api = GithubApi(token: token);

      // Un jeton invalide est refusé avec le bon type d'erreur.
      await expectLater(
        GithubApi(token: 'ghp_invalide_pour_le_test').getUser(),
        throwsA(
          isA<GithubException>().having(
            (e) => e.kind,
            'kind',
            GithubErrorKind.unauthorized,
          ),
        ),
      );

      final user = await api.getUser();
      debugPrint('GITHUB compte=${user.login}');
      final repo = await api.getRepo(owner, name);
      expect(repo.canPush, isTrue, reason: 'le jeton doit pouvoir écrire');
      final branch = repo.defaultBranch ?? 'main';

      // Deux vraies images générées, dans un dossier unique.
      final work = Directory.systemTemp.createTempSync('gitphoto_gh_');
      addTearDown(() => work.deleteSync(recursive: true));
      final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        RegExp(r'[:.]'),
        '-',
      );
      final folder = 'gitphoto-tests/$stamp';
      final candidates = <PublishCandidate>[];
      for (var i = 0; i < 2; i++) {
        final image = img.Image(width: 64, height: 64);
        img.fill(image, color: img.ColorRgb8(40 * i, 160, 220));
        final bytes = img.encodePng(image);
        final f = File(p.join(work.path, 'test-$i.png'))
          ..writeAsBytesSync(bytes);
        candidates.add(
          PublishCandidate(
            mediaId: i,
            fileName: 'test-$i.png',
            localPath: f.path,
            sizeBytes: bytes.length,
            gitBlobSha: gitBlobSha(bytes),
          ),
        );
      }

      Future<PublishPlan> plan() async {
        try {
          final head = await api.getBranchHead(owner, name, branch);
          final tree = await api.getTree(
            owner,
            name,
            await api.getCommitTree(owner, name, head),
          );
          return const PublishPlanner().plan(
            candidates: candidates,
            folder: folder,
            remote: tree,
            repositoryIsEmpty: false,
          );
        } on GithubException catch (e) {
          if (e.kind != GithubErrorKind.emptyRepository) rethrow;
          return const PublishPlanner().plan(
            candidates: candidates,
            folder: folder,
            remote: RemoteTree.empty,
            repositoryIsEmpty: true,
          );
        }
      }

      final first = await plan();
      expect(first.uploads, hasLength(2));
      final result = await Publisher(api).publish(
        owner: owner,
        repo: name,
        branch: branch,
        message: 'Test automatique GitPhoto Studio ($stamp)',
        plan: first,
      );
      debugPrint(
        'GITHUB commit=${result.commitSha} vérifié=${result.verified} '
        'commits=${result.commitCount}',
      );
      expect(result.verified, isTrue);

      // Vérification indépendante : le commit est en tête et visible.
      expect(await api.getBranchHead(owner, name, branch), result.commitSha);
      final commits = await api.listCommits(owner, name, branch: branch);
      expect(commits.first.sha, result.commitSha);
      final listing = await api.getContents(
        owner,
        name,
        path: folder,
        ref: branch,
      );
      expect(listing.map((e) => e.name).toSet(), {'test-0.png', 'test-1.png'});

      // Republication : rien à envoyer, aucun doublon.
      final second = await plan();
      expect(
        second.files.every((f) => f.action == PlannedAction.skipIdentical),
        isTrue,
      );
      expect(second.uploads, isEmpty);
    },
  );
}
