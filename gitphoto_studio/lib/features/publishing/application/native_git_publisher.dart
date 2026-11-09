import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:path/path.dart' as p;

import '../../../core/security/secret_redactor.dart';
import '../../github/data/github_api.dart';
import '../../github/data/github_exception.dart';
import '../domain/publish_plan.dart';
import 'publisher.dart';

/// Stratégie B — publication par Git en ligne de commande (Linux).
///
/// - Clone partiel sans contenus (`--filter=blob:none`, profondeur 1) dans un
///   dossier temporaire, supprimé ensuite ;
/// - commit construit avec les commandes de bas niveau (aucune extraction de
///   l'arborescence) puis `push` **sans forçage** ;
/// - arguments fixes, aucun shell ; le jeton est transmis par variable
///   d'environnement à un script `GIT_ASKPASS` privé, jamais dans l'URL ni
///   dans les arguments, et les assistants d'identifiants de l'utilisateur
///   sont neutralisés pour qu'il ne soit jamais enregistré.
///
/// Git LFS n'est pas géré par cette stratégie : les fichiers LFS passent par
/// le [Publisher] HTTP.
class NativeGitPublisher {
  NativeGitPublisher({
    required this.api,
    required String token,
    required this.workRoot,
    required this.authorName,
    required this.authorEmail,
    this.remoteUrlOverride,
    this.beforePush,
  }) : _token = token;

  /// Tests uniquement : exécuté juste avant le `push`.
  @visibleForTesting
  final Future<void> Function()? beforePush;

  /// Tests : dépôt Git local à la place de GitHub (vérification par l'API
  /// alors ignorée).
  final String? remoteUrlOverride;

  final GithubApi api;
  final String _token;
  final String workRoot;
  final String authorName;
  final String authorEmail;

  /// Options ajoutées à chaque commande Git.
  static const _safeConfig = [
    '-c', 'credential.helper=', // Aucun enregistrement du jeton.
    '-c', 'core.askPass=',
    '-c', 'protocol.version=2',
  ];

  Future<PublishResult> publish({
    required String owner,
    required String repo,
    required String branch,
    required String message,
    required PublishPlan plan,
    PublishHooks hooks = const PublishHooks(),
  }) async {
    final uploads = plan.uploads.toList();
    if (uploads.isEmpty || plan.usesLfs || plan.repositoryIsEmpty) {
      throw const GithubException(
        GithubErrorKind.validation,
        'Plan incompatible avec Git natif',
      );
    }
    final dir = Directory(
      p.join(workRoot, 'gitphoto_git_${DateTime.now().microsecondsSinceEpoch}'),
    )..createSync(recursive: true);
    final askPass = File(p.join(dir.path, 'askpass.sh'))
      ..writeAsStringSync(
        '#!/bin/sh\n'
        'case "\$1" in\n'
        '  *sername*) echo x-access-token ;;\n'
        '  *) echo "\$GITPHOTO_GIT_TOKEN" ;;\n'
        'esac\n',
      );
    await Process.run('chmod', ['700', askPass.path]);
    final repoDir = p.join(dir.path, 'repo');
    final env = {
      'GIT_ASKPASS': askPass.path,
      'GIT_TERMINAL_PROMPT': '0',
      'GITPHOTO_GIT_TOKEN': _token,
      'GIT_AUTHOR_NAME': authorName,
      'GIT_AUTHOR_EMAIL': authorEmail,
      'GIT_COMMITTER_NAME': authorName,
      'GIT_COMMITTER_EMAIL': authorEmail,
      'LC_ALL': 'C',
    };

    Future<String> git(List<String> args, {String? cwd}) async {
      final r = await Process.run('git', [
        ..._safeConfig,
        if (cwd != null) ...['-C', cwd],
        ...args,
      ], environment: env);
      if (r.exitCode != 0) {
        throw _mapError(SecretRedactor.redact('${r.stderr}'.trim()));
      }
      return '${r.stdout}'.trim();
    }

    try {
      hooks.onProgress?.call(PublishStep.uploading, 0, uploads.length);
      final url =
          remoteUrlOverride ??
          'https://github.com/${Uri.encodeComponent(owner)}/'
              '${Uri.encodeComponent(repo)}.git';
      await git([
        'clone',
        '--quiet',
        '--depth=1',
        '--filter=blob:none',
        '--no-checkout',
        '--single-branch',
        '--branch=$branch',
        url,
        repoDir,
      ]);
      final parent = await git(['rev-parse', 'HEAD'], cwd: repoDir);
      await git(['read-tree', 'HEAD'], cwd: repoDir);

      for (var i = 0; i < uploads.length; i++) {
        if (hooks.isCancelled?.call() ?? false) throw const PublishCancelled();
        hooks.onProgress?.call(PublishStep.uploading, i, uploads.length);
        final f = uploads[i];
        final sha = await git([
          'hash-object',
          '-w',
          // Contenu brut : aucune conversion de fin de ligne de l'utilisateur.
          '--no-filters',
          '--',
          f.candidate.localPath,
        ], cwd: repoDir);
        if (sha != f.expectedTreeSha) {
          throw GithubException(
            GithubErrorKind.unknown,
            'Empreinte inattendue pour ${f.remotePath}',
          );
        }
        await git([
          'update-index',
          '--add',
          '--cacheinfo',
          '100644,$sha,${f.remotePath}',
        ], cwd: repoDir);
      }
      hooks.onProgress?.call(PublishStep.committing, 0, 1);
      final tree = await git(['write-tree'], cwd: repoDir);
      final commit = await git([
        'commit-tree',
        tree,
        '-p',
        parent,
        '-m',
        message,
      ], cwd: repoDir);

      if (hooks.isCancelled?.call() ?? false) throw const PublishCancelled();
      hooks.onProgress?.call(PublishStep.updatingBranch, 0, 1);
      await beforePush?.call();
      // Sans forçage : refusé si la branche a avancé depuis le clone.
      await git([
        'push',
        '--quiet',
        'origin',
        '$commit:refs/heads/$branch',
      ], cwd: repoDir);

      hooks.onProgress?.call(PublishStep.verifying, 0, 1);
      final verified =
          remoteUrlOverride == null &&
          await _verify(owner, repo, branch, commit, uploads);
      return PublishResult(
        commitSha: commit,
        htmlUrl:
            'https://github.com/${Uri.encodeComponent(owner)}/'
            '${Uri.encodeComponent(repo)}/commit/$commit',
        verified: verified,
        commitCount: 1,
      );
    } finally {
      dir.deleteSync(recursive: true);
    }
  }

  Future<bool> _verify(
    String owner,
    String repo,
    String branch,
    String commit,
    List<PlannedFile> files,
  ) async {
    try {
      if (await api.getBranchHead(owner, repo, branch) != commit) return false;
      final tree = await api.getTree(
        owner,
        repo,
        await api.getCommitTree(owner, repo, commit),
      );
      return files.every((f) => tree.files[f.remotePath] == f.expectedTreeSha);
    } on GithubException {
      return false;
    }
  }

  static GithubException _mapError(String stderr) {
    final s = stderr.toLowerCase();
    final kind = switch (s) {
      _ when s.contains('non-fast-forward') || s.contains('fetch first') =>
        GithubErrorKind.conflict,
      // Branche protégée, règle du dépôt, hook : refus, pas un conflit.
      _
          when s.contains('remote rejected') ||
              s.contains('protected branch') ||
              s.contains('declined') =>
        GithubErrorKind.forbidden,
      _
          when s.contains('authentication failed') ||
              s.contains('could not read username') ||
              s.contains('invalid username or password') =>
        GithubErrorKind.unauthorized,
      _ when s.contains('permission') && s.contains('denied') =>
        GithubErrorKind.forbidden,
      _ when s.contains('not found') || s.contains('remote branch') =>
        GithubErrorKind.notFound,
      _
          when s.contains('could not resolve host') ||
              s.contains('unable to access') ||
              s.contains('timed out') =>
        GithubErrorKind.network,
      _ => GithubErrorKind.unknown,
    };
    final lines = stderr
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    // Ligne la plus parlante : refus détaillé (« ! [rejected] … »), message
    // du serveur, sinon la dernière.
    final detail =
        lines.where((l) => l.startsWith('!')).firstOrNull ??
        lines.where((l) => l.startsWith('remote:')).firstOrNull ??
        lines.lastOrNull ??
        '?';
    return GithubException(kind, 'Git : $detail');
  }
}
