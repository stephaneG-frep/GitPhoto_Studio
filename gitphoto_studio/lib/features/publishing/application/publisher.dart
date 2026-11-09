import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../github/data/github_api.dart';
import '../../github/data/github_exception.dart';
import '../../github/data/lfs_client.dart';
import '../../github/domain/github_models.dart';
import '../domain/publish_plan.dart';

enum PublishStep { uploading, committing, updatingBranch, verifying }

typedef PublishProgress = void Function(PublishStep step, int done, int total);

class PublishResult {
  const PublishResult({
    required this.commitSha,
    required this.htmlUrl,
    required this.verified,
    required this.commitCount,
    this.retriedAfterConflict = 0,
  });

  final String commitSha;
  final String htmlUrl;

  /// Les fichiers (et objets LFS) ont été relus sur GitHub.
  final bool verified;

  /// 1 en temps normal ; 2 au plus pour un dépôt vide.
  final int commitCount;

  /// Nouveaux essais automatiques après une avancée concurrente de la
  /// branche ne touchant pas aux mêmes chemins.
  final int retriedAfterConflict;
}

/// L'utilisateur a annulé avant l'avancée de la branche : rien n'est publié.
class PublishCancelled implements Exception {
  const PublishCancelled();

  @override
  String toString() => 'Publication annulée : rien n\'a été publié.';
}

/// Rappels permettant à la file d'attente de mémoriser l'avancement.
class PublishHooks {
  const PublishHooks({
    this.onProgress,
    this.onUploaded,
    this.isCancelled,
    this.alreadyUploaded = const {},
  });

  final PublishProgress? onProgress;

  /// Fichier envoyé : chemin distant et empreinte du blob créé.
  final void Function(String remotePath, String blobSha)? onUploaded;
  final bool Function()? isCancelled;

  /// Reprise : blobs déjà envoyés lors d'une tentative précédente.
  final Map<String, String> alreadyUploaded;
}

/// Exécute un [PublishPlan] avec l'API GitHub (et Git LFS en HTTP).
///
/// - Dépôt non vide : **un seul commit** (blobs → arbre → commit → avancée
///   de branche sans forçage). Si la branche a avancé entre-temps sans
///   toucher aux mêmes chemins, le commit est reconstruit sur la nouvelle
///   tête (2 essais au plus) ; sinon, rien n'est publié.
/// - Dépôt vide : un premier commit l'initialise (API Contents), un second
///   regroupe le reste.
/// - Fichiers Git LFS : contenu envoyé en flux au stockage LFS, puis pointeur
///   et règle `.gitattributes` ajoutés au même commit.
class Publisher {
  Publisher(this.api, {this.lfs, this.maxConflictRetries = 2});

  final GithubApi api;
  final LfsClient? lfs;
  final int maxConflictRetries;

  static const _gitattributes = '.gitattributes';

  Future<PublishResult> publish({
    required String owner,
    required String repo,
    required String branch,
    required String message,
    required PublishPlan plan,
    PublishProgress? onProgress,
    PublishHooks hooks = const PublishHooks(),
  }) async {
    final uploads = plan.uploads.toList();
    if (uploads.isEmpty) {
      throw const GithubException(
        GithubErrorKind.validation,
        'Aucun fichier à publier',
      );
    }
    if (plan.usesLfs && lfs == null) {
      throw const GithubException(
        GithubErrorKind.unknown,
        'Client Git LFS non configuré',
      );
    }
    final h = PublishHooks(
      onProgress: hooks.onProgress ?? onProgress,
      onUploaded: hooks.onUploaded,
      isCancelled: hooks.isCancelled,
      alreadyUploaded: hooks.alreadyUploaded,
    );
    final ctx = _Ctx(owner, repo, branch, h);

    var initialCommits = 0;
    var remaining = uploads;
    if (plan.repositoryIsEmpty) {
      remaining = await _initializeEmpty(ctx, message, uploads);
      initialCommits = 1;
      if (remaining.isEmpty) {
        final head = await api.getBranchHead(owner, repo, branch);
        final verified = await _verify(ctx, head, uploads);
        return PublishResult(
          commitSha: head,
          htmlUrl: _commitUrl(owner, repo, head),
          verified: verified,
          commitCount: 1,
        );
      }
    }

    final blobs = await _uploadAll(ctx, remaining);
    _checkCancelled(ctx);

    var retries = 0;
    while (true) {
      final head = await api.getBranchHead(owner, repo, branch);
      final baseTree = await api.getCommitTree(owner, repo, head);
      // La branche a pu avancer depuis l'analyse : on refuse d'écraser un
      // chemin visé qui aurait été modifié par quelqu'un d'autre.
      final current = await api.getTree(owner, repo, baseTree);
      _checkPaths(current, remaining);
      final treeEntries = {...blobs};
      if (remaining.any((f) => f.isLfs)) {
        final attributes = await _gitattributesUpdate(
          ctx,
          current,
          remaining.where((f) => f.isLfs).map((f) => f.remotePath),
        );
        if (attributes != null) treeEntries[_gitattributes] = attributes;
      }

      h.onProgress?.call(PublishStep.committing, 0, 1);
      final tree = await _createTree(ctx, baseTree, treeEntries, remaining);
      final commit = await api.createCommit(
        owner,
        repo,
        message: plan.repositoryIsEmpty ? '$message (2/2)' : message,
        tree: tree,
        parents: [head],
      );

      _checkCancelled(ctx);
      h.onProgress?.call(PublishStep.updatingBranch, 0, 1);
      try {
        await api.updateBranch(owner, repo, branch, commit);
      } on GithubException catch (e) {
        if (e.kind != GithubErrorKind.conflict ||
            retries >= maxConflictRetries) {
          rethrow;
        }
        // La branche a avancé : nouvel essai sur la nouvelle tête ; la
        // vérification des chemins en tête de boucle arrête tout si l'autre
        // auteur a touché aux mêmes fichiers.
        retries++;
        continue;
      }

      final verified = await _verify(ctx, commit, uploads);
      return PublishResult(
        commitSha: commit,
        htmlUrl: _commitUrl(owner, repo, commit),
        verified: verified,
        commitCount: initialCommits + 1,
        retriedAfterConflict: retries,
      );
    }
  }

  /// Dépôt vide : premier commit par l'API Contents (`.gitattributes` si
  /// des fichiers LFS sont prévus, sinon le premier fichier ordinaire).
  Future<List<PlannedFile>> _initializeEmpty(
    _Ctx ctx,
    String message,
    List<PlannedFile> uploads,
  ) async {
    final lfsPaths = uploads.where((f) => f.isLfs).map((f) => f.remotePath);
    if (lfsPaths.isNotEmpty) {
      await api.putFile(
        ctx.owner,
        ctx.repo,
        path: _gitattributes,
        bytes: Uint8List.fromList(utf8.encode(withLfsRules(null, lfsPaths)!)),
        message: '$message (1/2)',
      );
      return uploads;
    }
    final first = uploads.first;
    ctx.hooks.onProgress?.call(PublishStep.uploading, 0, uploads.length);
    await api.putFile(
      ctx.owner,
      ctx.repo,
      path: first.remotePath,
      bytes: await File(first.candidate.localPath).readAsBytes(),
      message: uploads.length == 1 ? message : '$message (1/2)',
    );
    ctx.hooks.onUploaded?.call(first.remotePath, first.candidate.gitBlobSha);
    return uploads.sublist(1);
  }

  Future<Map<String, String>> _uploadAll(
    _Ctx ctx,
    List<PlannedFile> files, {
    bool ignorePrevious = false,
  }) async {
    final blobs = <String, String>{};
    for (var i = 0; i < files.length; i++) {
      _checkCancelled(ctx);
      ctx.hooks.onProgress?.call(PublishStep.uploading, i, files.length);
      final f = files[i];
      final previous = ignorePrevious
          ? null
          : ctx.hooks.alreadyUploaded[f.remotePath];
      if (previous != null && previous == f.expectedTreeSha) {
        blobs[f.remotePath] = previous;
        continue;
      }
      final String sha;
      if (f.isLfs) {
        final object = LfsObject(
          f.candidate.contentSha256!,
          f.candidate.sizeBytes,
        );
        await lfs!.upload(ctx.owner, ctx.repo, f.candidate.localPath, object);
        sha = await api.createBlob(
          ctx.owner,
          ctx.repo,
          Uint8List.fromList(utf8.encode(object.pointer)),
        );
      } else {
        sha = await api.createBlob(
          ctx.owner,
          ctx.repo,
          await File(f.candidate.localPath).readAsBytes(),
        );
      }
      if (sha != f.expectedTreeSha) {
        throw GithubException(
          GithubErrorKind.unknown,
          'Empreinte inattendue pour ${f.remotePath} : le fichier local a '
          'peut-être changé pendant la publication.',
        );
      }
      blobs[f.remotePath] = sha;
      ctx.hooks.onUploaded?.call(f.remotePath, sha);
    }
    ctx.hooks.onProgress?.call(
      PublishStep.uploading,
      files.length,
      files.length,
    );
    return blobs;
  }

  /// Crée l'arbre ; si un blob d'une tentative précédente a disparu de
  /// GitHub, tout est renvoyé une fois.
  Future<String> _createTree(
    _Ctx ctx,
    String baseTree,
    Map<String, String> entries,
    List<PlannedFile> files,
  ) async {
    try {
      return await api.createTree(
        ctx.owner,
        ctx.repo,
        baseTree: baseTree,
        blobsByPath: entries,
      );
    } on GithubException catch (e) {
      if (e.kind != GithubErrorKind.validation ||
          ctx.hooks.alreadyUploaded.isEmpty) {
        rethrow;
      }
      final fresh = await _uploadAll(ctx, files, ignorePrevious: true);
      return api.createTree(
        ctx.owner,
        ctx.repo,
        baseTree: baseTree,
        blobsByPath: {...entries, ...fresh},
      );
    }
  }

  Future<String?> _gitattributesUpdate(
    _Ctx ctx,
    RemoteTree tree,
    Iterable<String> lfsPaths,
  ) async {
    final existingSha = tree.files[_gitattributes];
    final current = existingSha == null
        ? null
        : utf8.decode(
            await api.getBlob(ctx.owner, ctx.repo, existingSha),
            allowMalformed: true,
          );
    final updated = withLfsRules(current, lfsPaths);
    if (updated == null) return null;
    return api.createBlob(
      ctx.owner,
      ctx.repo,
      Uint8List.fromList(utf8.encode(updated)),
    );
  }

  /// Chaque chemin visé doit être tel qu'à l'analyse (ou déjà contenir
  /// exactement notre contenu) ; sinon, conflit et rien n'est publié.
  static void _checkPaths(RemoteTree tree, List<PlannedFile> files) {
    for (final f in files) {
      final now = tree.files[f.remotePath];
      if (now != f.remoteShaAtAnalysis && now != f.expectedTreeSha) {
        throw GithubException(
          GithubErrorKind.conflict,
          '« ${f.remotePath} » a été modifié sur GitHub pendant la '
          'publication',
        );
      }
    }
  }

  void _checkCancelled(_Ctx ctx) {
    if (ctx.hooks.isCancelled?.call() ?? false) throw const PublishCancelled();
  }

  /// Relit la branche, l'arborescence du commit et les objets LFS.
  Future<bool> _verify(_Ctx ctx, String commit, List<PlannedFile> files) async {
    ctx.hooks.onProgress?.call(PublishStep.verifying, 0, 1);
    try {
      final head = await api.getBranchHead(ctx.owner, ctx.repo, ctx.branch);
      if (head != commit) return false;
      final tree = await api.getTree(
        ctx.owner,
        ctx.repo,
        await api.getCommitTree(ctx.owner, ctx.repo, commit),
      );
      for (final f in files) {
        if (tree.files[f.remotePath] != f.expectedTreeSha) return false;
        if (f.isLfs) {
          final object = LfsObject(
            f.candidate.contentSha256!,
            f.candidate.sizeBytes,
          );
          if (!await lfs!.exists(ctx.owner, ctx.repo, object)) return false;
        }
      }
      return true;
    } on GithubException {
      return false;
    }
  }

  static String _commitUrl(String owner, String repo, String sha) =>
      'https://github.com/${Uri.encodeComponent(owner)}/'
      '${Uri.encodeComponent(repo)}/commit/$sha';
}

class _Ctx {
  const _Ctx(this.owner, this.repo, this.branch, this.hooks);

  final String owner;
  final String repo;
  final String branch;
  final PublishHooks hooks;
}
