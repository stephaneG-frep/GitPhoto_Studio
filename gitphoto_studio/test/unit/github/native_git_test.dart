import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/github/data/github_api.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';
import 'package:gitphoto_studio/features/publishing/application/native_git_publisher.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:gitphoto_studio/features/publishing/domain/transport_selector.dart';
import 'package:path/path.dart' as p;

/// Vrai programme `git`, dépôt « distant » local (aucun réseau).
void main() {
  late Directory root;
  late String remote;

  Future<String> git(List<String> args, {String? cwd}) async {
    final r = await Process.run('git', args, workingDirectory: cwd);
    if (r.exitCode != 0) fail('git ${args.join(' ')} : ${r.stderr}');
    return '${r.stdout}'.trim();
  }

  setUp(() async {
    root = Directory.systemTemp.createTempSync('gitphoto_native_');
    remote = p.join(root.path, 'remote.git');
    await git(['init', '--bare', '--initial-branch=main', remote]);
    final seed = p.join(root.path, 'seed');
    await git(['clone', remote, seed]);
    File(p.join(seed, 'README.md')).writeAsStringSync('# test\n');
    await git(['add', '.'], cwd: seed);
    await git([
      '-c',
      'user.name=t',
      '-c',
      'user.email=t@t',
      'commit',
      '-m',
      'init',
    ], cwd: seed);
    await git(['push', 'origin', 'main'], cwd: seed);
  });
  tearDown(() => root.deleteSync(recursive: true));

  PlannedFile planned(String name, String content, {String folder = 'photos'}) {
    final f = File(p.join(root.path, name))..writeAsStringSync(content);
    final sha = gitBlobSha(f.readAsBytesSync());
    return PlannedFile(
      candidate: PublishCandidate(
        mediaId: 1,
        fileName: name,
        localPath: f.path,
        sizeBytes: f.lengthSync(),
        gitBlobSha: sha,
      ),
      remotePath: '$folder/$name',
      action: PlannedAction.add,
      strategy: PublishStrategy.nativeGit,
    );
  }

  NativeGitPublisher publisher() => NativeGitPublisher(
    api: GithubApi(token: 'inutilise'),
    token: 'ghp_ne_doit_jamais_etre_enregistre_00000000',
    workRoot: p.join(root.path, 'work'),
    authorName: 'Testeur',
    authorEmail: '1+testeur@users.noreply.github.com',
    remoteUrlOverride: remote,
  );

  test(
    'un seul commit, contenu exact, auteur noreply, dossier nettoyé',
    () async {
      final plan = PublishPlan(
        files: [planned('a b.jpg', 'AAA'), planned('c.png', 'CCC')],
        folder: 'photos',
        repositoryIsEmpty: false,
        remoteTreeTruncated: false,
      );
      final result = await publisher().publish(
        owner: 'o',
        repo: 'r',
        branch: 'main',
        message: 'Ajout natif',
        plan: plan,
      );
      final log = await git([
        '--git-dir',
        remote,
        'log',
        '--format=%H|%s|%an|%ae',
        'main',
      ]);
      final lines = log.split('\n');
      expect(lines, hasLength(2));
      expect(
        lines.first,
        '${result.commitSha}|Ajout natif|Testeur|1+testeur@users.noreply.github.com',
      );
      expect(
        await git(['--git-dir', remote, 'show', 'main:photos/a b.jpg']),
        'AAA',
      );
      expect(
        await git(['--git-dir', remote, 'show', 'main:README.md']),
        '# test',
      );
      expect(result.verified, isFalse, reason: 'pas d\'API GitHub en local');
      expect(Directory(p.join(root.path, 'work')).listSync(), isEmpty);
    },
  );

  test(
    "branche avancée juste avant le push : refus (conflit), rien d'écrasé",
    () async {
      final other = p.join(root.path, 'other');
      await git(['clone', remote, other]);
      File(p.join(other, 'x.txt')).writeAsStringSync('x');
      await git(['add', '.'], cwd: other);
      await git([
        '-c',
        'user.name=o',
        '-c',
        'user.email=o@o',
        'commit',
        '-m',
        'autre',
      ], cwd: other);

      final plan = PublishPlan(
        files: [planned('a.jpg', 'AAA')],
        folder: 'photos',
        repositoryIsEmpty: false,
        remoteTreeTruncated: false,
      );
      final concurrent = NativeGitPublisher(
        api: GithubApi(token: 'inutilise'),
        token: 'ghp_x',
        workRoot: p.join(root.path, 'work'),
        authorName: 'Testeur',
        authorEmail: 't@users.noreply.github.com',
        remoteUrlOverride: remote,
        // Un autre auteur pousse pendant notre publication.
        beforePush: () => git(['push', 'origin', 'main'], cwd: other),
      );
      await expectLater(
        concurrent.publish(
          owner: 'o',
          repo: 'r',
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
      final log = await git([
        '--git-dir',
        remote,
        'log',
        '--format=%s',
        'main',
      ]);
      expect(log.split('\n'), ['autre', 'init']);
      expect(Directory(p.join(root.path, 'work')).listSync(), isEmpty);
    },
  );

  test(
    'push refusé par une règle du dépôt : « interdit », pas « conflit »',
    () async {
      final hook = File(p.join(remote, 'hooks', 'pre-receive'))
        ..writeAsStringSync('#!/bin/sh\necho "branche protégée" >&2\nexit 1\n');
      await Process.run('chmod', ['+x', hook.path]);
      final plan = PublishPlan(
        files: [planned('a.jpg', 'AAA')],
        folder: 'photos',
        repositoryIsEmpty: false,
        remoteTreeTruncated: false,
      );
      await expectLater(
        publisher().publish(
          owner: 'o',
          repo: 'r',
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
    },
  );

  test(
    'le jeton n\'est jamais écrit sur le disque ni dans la configuration',
    () async {
      final plan = PublishPlan(
        files: [planned('a.jpg', 'AAA')],
        folder: 'photos',
        repositoryIsEmpty: false,
        remoteTreeTruncated: false,
      );
      await publisher().publish(
        owner: 'o',
        repo: 'r',
        branch: 'main',
        message: 'm',
        plan: plan,
      );
      final config = File(p.join(remote, 'config')).readAsStringSync();
      expect(config, isNot(contains('ghp_ne_doit')));
      final home = Platform.environment['HOME']!;
      final credentials = File(p.join(home, '.git-credentials'));
      if (credentials.existsSync()) {
        expect(credentials.readAsStringSync(), isNot(contains('ghp_ne_doit')));
      }
    },
  );

  test('plan incompatible (LFS ou dépôt vide) refusé', () async {
    final lfsFile = PlannedFile(
      candidate: const PublishCandidate(
        mediaId: 1,
        fileName: 'v.mp4',
        localPath: '/x',
        sizeBytes: 1,
        gitBlobSha: 'x',
        contentSha256: 'aa',
      ),
      remotePath: 'v.mp4',
      action: PlannedAction.add,
      strategy: PublishStrategy.gitLfs,
    );
    await expectLater(
      publisher().publish(
        owner: 'o',
        repo: 'r',
        branch: 'main',
        message: 'm',
        plan: PublishPlan(
          files: [lfsFile],
          folder: '',
          repositoryIsEmpty: false,
          remoteTreeTruncated: false,
        ),
      ),
      throwsA(isA<GithubException>()),
    );
  });
}
