import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';
import 'package:gitphoto_studio/features/github/data/github_api.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';
import 'package:gitphoto_studio/features/github/data/lfs_client.dart';
import 'package:gitphoto_studio/features/github/domain/github_models.dart';
import 'package:gitphoto_studio/features/publishing/application/native_git_publisher.dart';
import 'package:gitphoto_studio/features/publishing/application/publisher.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:gitphoto_studio/features/publishing/domain/transport_selector.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

/// Tests RÉELS de la phase 5 sur un dépôt de test autorisé :
///   flutter test integration_test/github_real_phase5_test.dart -d linux \
///     --dart-define=GITPHOTO_TEST_REPO=proprietaire/depot-de-test
/// Jeton : ~/.config/gitphoto/test_token. Un objet Git LFS de ~10 Ko est
/// créé (consomme un peu de quota LFS, non supprimable sans supprimer le
/// dépôt).
const _repo = String.fromEnvironment('GITPHOTO_TEST_REPO');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Linux : ~/.config/gitphoto/test_token. Android : fichier déposé
  // temporairement par adb dans le dossier externe privé de l'application,
  // puis effacé après le test.
  final tokenFile = File(
    Platform.isAndroid
        ? '/sdcard/Android/data/com.nabu.gitphoto.gitphoto_studio/files/test_token'
        : p.join(
            Platform.environment['HOME'] ?? '',
            '.config/gitphoto/test_token',
          ),
  );
  final configured = _repo.contains('/') && tokenFile.existsSync();
  late String token;
  late String owner;
  late String name;
  late GithubApi api;
  late Directory work;
  late String stamp;

  setUp(() {
    token = tokenFile.readAsStringSync().trim();
    [owner, name] = _repo.split('/');
    api = GithubApi(token: token);
    work = Directory.systemTemp.createTempSync('gitphoto_gh5_');
    stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
  });
  tearDown(() => work.deleteSync(recursive: true));

  Future<RemoteTree> remoteTree(String branch) async => api.getTree(
    owner,
    name,
    await api.getCommitTree(
      owner,
      name,
      await api.getBranchHead(owner, name, branch),
    ),
  );

  testWidgets(
    'Git LFS réel (HTTP) : objet stocké, pointeur, .gitattributes',
    skip: !configured,
    (tester) async {
      final repo = await api.getRepo(owner, name);
      final branch = repo.defaultBranch ?? 'main';
      final random = Random(DateTime.now().microsecondsSinceEpoch);
      final bytes = List<int>.generate(10 * 1024, (_) => random.nextInt(256));
      final f = File(p.join(work.path, 'lfs-$stamp.bin'))
        ..writeAsBytesSync(bytes);
      final candidate = PublishCandidate(
        mediaId: 1,
        fileName: p.basename(f.path),
        localPath: f.path,
        sizeBytes: bytes.length,
        gitBlobSha: gitBlobSha(bytes),
        contentSha256: sha256.convert(bytes).toString(),
      );
      // Seuil abaissé : ce petit fichier passe par Git LFS.
      const planner = PublishPlanner(
        selector: TransportSelector(
          limits: PublishLimits(lfsThresholdBytes: 1024, warnBytes: 1024),
        ),
      );
      final folder = 'gitphoto-tests/lfs-$stamp';
      final plan = planner.plan(
        candidates: [candidate],
        folder: folder,
        remote: await remoteTree(branch),
        repositoryIsEmpty: false,
      );
      expect(plan.files.single.isLfs, isTrue);

      final lfs = LfsClient(token: token);
      final result = await Publisher(api, lfs: lfs).publish(
        owner: owner,
        repo: name,
        branch: branch,
        message: 'Test automatique Git LFS ($stamp)',
        plan: plan,
      );
      debugPrint('LFS commit=${result.commitSha} vérifié=${result.verified}');
      expect(result.verified, isTrue);

      final object = LfsObject(candidate.contentSha256!, candidate.sizeBytes);
      expect(await lfs.exists(owner, name, object), isTrue);
      final tree = await remoteTree(branch);
      final path = '$folder/${candidate.fileName}';
      expect(tree.files[path], object.pointerBlobSha);
      final attributes = utf8.decode(
        await api.getBlob(owner, name, tree.files['.gitattributes']!),
      );
      expect(
        attributes,
        contains('${escapeAttributesPattern(path)} filter=lfs'),
      );

      // Republication : pointeur reconnu, aucun envoi.
      final again = planner.plan(
        candidates: [candidate],
        folder: folder,
        remote: tree,
        repositoryIsEmpty: false,
      );
      expect(again.files.single.action, PlannedAction.skipIdentical);
    },
  );

  testWidgets(
    'Git natif réel : push sans forçage, vérifié par l\'API',
    skip: !configured || Platform.isAndroid,
    (tester) async {
      final repo = await api.getRepo(owner, name);
      final branch = repo.defaultBranch ?? 'main';
      final user = await api.getUser();
      final content = 'Test Git natif GitPhoto Studio $stamp\n';
      final f = File(p.join(work.path, 'git-$stamp.txt'))
        ..writeAsStringSync(content);
      final plan = const PublishPlanner().plan(
        candidates: [
          PublishCandidate(
            mediaId: 1,
            fileName: p.basename(f.path),
            localPath: f.path,
            sizeBytes: f.lengthSync(),
            gitBlobSha: gitBlobSha(utf8.encode(content)),
          ),
        ],
        folder: 'gitphoto-tests/git-$stamp',
        remote: await remoteTree(branch),
        repositoryIsEmpty: false,
        tools: const _GitTools(),
        preferNativeGit: true,
      );
      expect(plan.usesNativeGit, isTrue);
      final result =
          await NativeGitPublisher(
            api: api,
            token: token,
            workRoot: work.path,
            authorName: user.name ?? user.login,
            authorEmail: user.noreplyEmail,
          ).publish(
            owner: owner,
            repo: name,
            branch: branch,
            message: 'Test automatique Git natif ($stamp)',
            plan: plan,
          );
      debugPrint('GIT commit=${result.commitSha} vérifié=${result.verified}');
      expect(result.verified, isTrue);
      final commits = await api.listCommits(owner, name, branch: branch);
      expect(commits.first.sha, result.commitSha);
      expect(commits.first.author, user.name ?? user.login);
      // Aucun reste du clone temporaire.
      expect(work.listSync().whereType<Directory>(), isEmpty);
    },
  );

  testWidgets(
    'Git natif réel : jeton invalide refusé proprement',
    skip: !configured || Platform.isAndroid,
    (tester) async {
      final f = File(p.join(work.path, 'x.txt'))..writeAsStringSync('x');
      final plan = PublishPlan(
        files: [
          PlannedFile(
            candidate: PublishCandidate(
              mediaId: 1,
              fileName: 'x.txt',
              localPath: f.path,
              sizeBytes: 1,
              gitBlobSha: gitBlobSha(utf8.encode('x')),
            ),
            remotePath: 'gitphoto-tests/x.txt',
            action: PlannedAction.add,
            strategy: PublishStrategy.nativeGit,
          ),
        ],
        folder: '',
        repositoryIsEmpty: false,
        remoteTreeTruncated: false,
      );
      await expectLater(
        NativeGitPublisher(
          api: api,
          token: 'ghp_invalide_pour_le_test',
          workRoot: work.path,
          authorName: 't',
          authorEmail: 't@users.noreply.github.com',
        ).publish(
          owner: owner,
          repo: name,
          branch: 'main',
          message: 'm',
          plan: plan,
        ),
        throwsA(isA<GithubException>()),
      );
    },
  );
}

class _GitTools extends ToolAvailabilityForTest {
  const _GitTools();
}

/// Git est présent sur la machine de test (vérifié par le test lui-même).
class ToolAvailabilityForTest extends ToolAvailability {
  const ToolAvailabilityForTest()
    : super(supportsExternalTools: true, gitVersion: 'git');
}
