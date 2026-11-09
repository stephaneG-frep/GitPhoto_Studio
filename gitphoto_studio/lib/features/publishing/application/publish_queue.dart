import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers.dart';
import '../../../core/security/secret_redactor.dart';
import '../../dashboard/application/dashboard_stats.dart';
import '../../gallery/application/gallery_providers.dart';
import '../../github/application/github_session.dart';
import '../../github/data/github_exception.dart';
import '../../github/domain/github_models.dart';
import '../data/operations_repository.dart';
import '../domain/publish_plan.dart';
import '../domain/transport_selector.dart';
import 'native_git_publisher.dart';
import 'publish_controller.dart'
    show operationsRepositoryProvider, operationsRevisionProvider;
import 'publisher.dart';

/// Résultat d'une opération de la file.
class QueueOutcome {
  const QueueOutcome.success(
    PublishResult this.result, {
    this.alreadyPublished = false,
  }) : error = null,
       cancelled = false;

  const QueueOutcome.failure(Object this.error)
    : result = null,
      cancelled = false,
      alreadyPublished = false;

  const QueueOutcome.cancelled()
    : result = null,
      error = null,
      cancelled = true,
      alreadyPublished = false;

  final PublishResult? result;
  final Object? error;
  final bool cancelled;

  /// Reprise d'une opération dont tous les fichiers étaient déjà sur GitHub.
  final bool alreadyPublished;
}

/// Avancement de l'opération en cours.
class QueueProgress {
  const QueueProgress(this.operationId, this.step, this.done, this.total);

  final int operationId;
  final PublishStep step;
  final int done;
  final int total;
}

/// Le même contenu est déjà en attente d'envoi vers le même chemin.
class DuplicatePublicationException implements Exception {
  const DuplicatePublicationException(this.remotePath);

  final String remotePath;

  @override
  String toString() =>
      '« $remotePath » est déjà en attente de publication vers ce dépôt.';
}

/// Erreurs passagères : nouvel essai automatique.
bool isTransient(Object e) =>
    e is GithubException &&
    (e.kind == GithubErrorKind.network ||
        e.kind == GithubErrorKind.server ||
        e.kind == GithubErrorKind.rateLimited);

/// File d'attente persistante des publications (SQLite).
///
/// Une opération à la fois. Avant chaque exécution ou reprise, l'état réel
/// du dépôt est relu : les fichiers déjà publiés sont ignorés, un chemin
/// modifié entre-temps par quelqu'un d'autre arrête l'opération.
class PublishQueue extends Notifier<QueueProgress?> {
  final _waiters = <int, Completer<QueueOutcome>>{};
  final _cancelRequested = <int>{};
  final _autoRetries = <int, int>{};
  bool _processing = false;

  /// Délais avant les nouveaux essais automatiques (perte de connexion).
  List<Duration> retryDelays = const [
    Duration(seconds: 5),
    Duration(seconds: 30),
  ];

  @override
  QueueProgress? build() {
    // Les opérations confirmées et encore en file reprennent dès qu'une
    // session GitHub est disponible.
    ref.listen(githubSessionProvider, (_, next) {
      if (next.value is GithubConnected) unawaited(kick());
    });
    return null;
  }

  OperationsRepository get _ops => ref.read(operationsRepositoryProvider);

  void _bump() {
    if (!ref.mounted) return;
    ref.read(operationsRevisionProvider.notifier).bump();
    ref.invalidate(dashboardStatsProvider);
  }

  /// Met une publication analysée en file et renvoie son résultat final.
  Future<QueueOutcome> enqueue({
    required GithubRepo repo,
    required String branch,
    required String message,
    required PublishPlan plan,
    void Function(int operationId)? onQueued,
  }) {
    final repoId = _ops.upsertRepository(
      owner: repo.owner,
      name: repo.name,
      defaultBranch: repo.defaultBranch,
      isPrivate: repo.isPrivate,
      htmlUrl: repo.htmlUrl,
    );
    for (final f in plan.uploads) {
      if (_ops.hasActiveDuplicate(
        repositoryId: repoId,
        branch: branch,
        remotePath: f.remotePath,
        gitBlobSha: f.candidate.gitBlobSha,
      )) {
        return Future.error(DuplicatePublicationException(f.remotePath));
      }
    }
    final id = _ops.enqueue(
      repositoryId: repoId,
      branch: branch,
      commitMessage: message,
      entries: [
        for (final f in plan.uploads)
          QueueEntryInput(
            mediaId: f.candidate.mediaId,
            localPath: f.candidate.localPath,
            remotePath: f.remotePath,
            strategy: f.strategy.name,
            gitBlobSha: f.candidate.gitBlobSha,
            sizeBytes: f.candidate.sizeBytes,
            overwrite: f.action == PlannedAction.overwrite,
          ),
      ],
    );
    onQueued?.call(id);
    _bump();
    final completer = _waiters[id] = Completer<QueueOutcome>();
    unawaited(kick());
    return completer.future;
  }

  /// Reprend une opération échouée ou interrompue.
  Future<QueueOutcome> resume(int operationId) {
    if (!_ops.requeue(operationId)) {
      return Future.error(StateError('Opération non reprenable'));
    }
    _autoRetries.remove(operationId);
    _bump();
    final completer = _waiters[operationId] = Completer<QueueOutcome>();
    unawaited(kick());
    return completer.future;
  }

  /// Annule : immédiatement si l'opération attend, sinon entre deux fichiers
  /// (avant l'avancée de la branche).
  void cancel(int operationId) {
    if (state?.operationId == operationId) {
      _cancelRequested.add(operationId);
      return;
    }
    if (_ops.cancel(operationId)) {
      _complete(operationId, const QueueOutcome.cancelled());
      _bump();
    }
  }

  /// Traite les opérations en file, une à la fois.
  Future<void> kick() async {
    if (_processing || !ref.mounted) return;
    final session = ref.read(githubSessionProvider).value;
    if (session is! GithubConnected) return;
    _processing = true;
    try {
      while (ref.mounted) {
        final id = _ops.nextQueued();
        if (id == null) break;
        await _process(id, session);
      }
    } finally {
      _processing = false;
      if (ref.mounted) state = null;
    }
  }

  Future<void> _process(int id, GithubConnected session) async {
    final op = _ops.find(id);
    if (op == null || op.repository == null) return;
    final [owner, name] = op.repository!.split('/');
    final branch = op.branch!;
    _ops.setStatus(id, OperationStatus.running);
    _bump();
    state = QueueProgress(id, PublishStep.uploading, 0, op.entries.length);

    try {
      final plan = await _replan(session, owner, name, branch, op.entries);
      final pending = plan.uploads.toList();
      final skipped = plan.files.where(
        (f) => f.action == PlannedAction.skipIdentical,
      );
      final entryByPath = {for (final e in op.entries) e.remotePath: e};
      for (final f in skipped) {
        _ops.setEntry(entryByPath[f.remotePath]!.id, EntryStatus.skipped);
      }

      if (pending.isEmpty) {
        // Tout est déjà sur GitHub (reprise après une publication aboutie
        // dont le résultat n'avait pas pu être enregistré) : rien à envoyer.
        final head = await session.api.getBranchHead(owner, name, branch);
        final result = PublishResult(
          commitSha: head,
          htmlUrl: 'https://github.com/$owner/$name/commit/$head',
          verified: true,
          commitCount: 0,
        );
        _ops.finish(
          id,
          status: OperationStatus.success,
          commitSha: head,
          htmlUrl: result.htmlUrl,
        );
        _complete(id, QueueOutcome.success(result, alreadyPublished: true));
        return;
      }

      final hooks = PublishHooks(
        onProgress: (step, done, total) {
          if (ref.mounted) state = QueueProgress(id, step, done, total);
        },
        onUploaded: (path, sha) {
          final entry = entryByPath[path];
          if (entry != null) {
            _ops.setEntry(entry.id, EntryStatus.uploaded, uploadedSha: sha);
          }
        },
        isCancelled: () => _cancelRequested.contains(id),
        alreadyUploaded: {
          for (final e in op.entries)
            if (e.uploadedSha != null) e.remotePath: e.uploadedSha!,
        },
      );

      final PublishResult result;
      if (plan.usesNativeGit && !plan.usesLfs && !plan.repositoryIsEmpty) {
        result =
            await NativeGitPublisher(
              api: session.api,
              token: session.token,
              workRoot: p.join(
                ref.read(libraryPathsProvider).temporaryDir ??
                    ref.read(libraryPathsProvider).mediaDir,
                'git',
              ),
              authorName: session.user.name ?? session.user.login,
              authorEmail: session.user.noreplyEmail,
            ).publish(
              owner: owner,
              repo: name,
              branch: branch,
              message: op.commitMessage ?? 'GitPhoto Studio',
              plan: plan,
              hooks: hooks,
            );
      } else {
        result =
            await Publisher(
              session.api,
              lfs: ref.read(lfsClientFactoryProvider)(session.token),
            ).publish(
              owner: owner,
              repo: name,
              branch: branch,
              message: op.commitMessage ?? 'GitPhoto Studio',
              plan: plan,
              hooks: hooks,
            );
      }
      for (final f in pending) {
        _ops.setEntry(entryByPath[f.remotePath]!.id, EntryStatus.done);
      }
      _ops.finish(
        id,
        status: OperationStatus.success,
        commitSha: result.commitSha,
        htmlUrl: result.htmlUrl,
        error: result.verified ? null : 'Vérification distante incomplète',
      );
      ref
          .read(loggerProvider)
          .info('Publication $owner/$name@$branch : ${result.commitSha}');
      if (ref.mounted) ref.read(githubRefreshProvider.notifier).bump();
      _complete(id, QueueOutcome.success(result));
    } on PublishCancelled {
      // Repasse par « échouée » pour que l'annulation marque aussi les
      // fichiers de la file.
      _ops
        ..setStatus(id, OperationStatus.failed)
        ..cancel(id);
      _complete(id, const QueueOutcome.cancelled());
    } on Object catch (e) {
      final message = SecretRedactor.redact('$e');
      ref.read(loggerProvider).warning('Publication échouée : $message');
      _ops.finish(id, status: OperationStatus.failed, error: message);
      for (final entry in _ops.entries(id)) {
        if (entry.status == EntryStatus.pending) {
          _ops.setEntry(entry.id, EntryStatus.failed, error: message);
        }
      }
      final tries = _autoRetries[id] ?? 0;
      if (isTransient(e) && tries < retryDelays.length) {
        // Perte de connexion ou indisponibilité passagère : nouvel essai
        // automatique, la reprise ne renvoyant que le nécessaire.
        _autoRetries[id] = tries + 1;
        Timer(retryDelays[tries], () {
          if (!ref.mounted) return;
          if (_ops.requeue(id)) {
            _bump();
            unawaited(kick());
          }
        });
      } else {
        _complete(id, QueueOutcome.failure(e));
      }
    } finally {
      _cancelRequested.remove(id);
      _bump();
    }
  }

  /// Reconstruit le plan depuis la file et l'état actuel du dépôt.
  Future<PublishPlan> _replan(
    GithubConnected session,
    String owner,
    String name,
    String branch,
    List<QueueEntry> entries,
  ) async {
    final media = ref.read(mediaRepositoryProvider);
    final list =
        <
          ({
            PublishCandidate candidate,
            String remotePath,
            PublishStrategy strategy,
            bool overwrite,
          })
        >[];
    for (final e in entries) {
      if (e.status == EntryStatus.done || e.status == EntryStatus.cancelled) {
        continue;
      }
      final PublishCandidate candidate;
      final m = e.mediaId == null ? null : media.findById(e.mediaId!);
      if (m != null) {
        candidate = PublishCandidate(
          mediaId: m.id,
          fileName: m.fileName,
          localPath: m.storedPath,
          sizeBytes: m.sizeBytes,
          gitBlobSha: e.gitBlobSha!,
          contentSha256: m.sha256,
          hasGps: m.hasGps,
        );
      } else if (e.mediaId == null &&
          e.localPath != null &&
          File(e.localPath!).existsSync()) {
        // Fichier produit par l'application (README) : publié tel quel.
        candidate = PublishCandidate(
          fileName: p.basename(e.remotePath),
          localPath: e.localPath!,
          sizeBytes: File(e.localPath!).lengthSync(),
          gitBlobSha: e.gitBlobSha!,
        );
      } else if (e.localPath == null) {
        throw StateError(
          '« ${e.remotePath} » : le média a été retiré de la bibliothèque',
        );
      } else {
        throw StateError('« ${e.remotePath} » : le fichier local a été retiré');
      }
      list.add((
        candidate: candidate,
        remotePath: e.remotePath,
        strategy:
            PublishStrategy.values.asNameMap()[e.strategy] ??
            PublishStrategy.githubApi,
        overwrite: e.overwrite,
      ));
    }
    var empty = false;
    var remote = RemoteTree.empty;
    try {
      final head = await session.api.getBranchHead(owner, name, branch);
      remote = await session.api.getTree(
        owner,
        name,
        await session.api.getCommitTree(owner, name, head),
      );
    } on GithubException catch (e) {
      if (e.kind != GithubErrorKind.emptyRepository) rethrow;
      empty = true;
    }
    return const PublishPlanner().replan(
      entries: list,
      folder: '',
      remote: remote,
      repositoryIsEmpty: empty,
    );
  }

  void _complete(int id, QueueOutcome outcome) {
    final c = _waiters.remove(id);
    if (c != null && !c.isCompleted) c.complete(outcome);
  }
}

final publishQueueProvider = NotifierProvider<PublishQueue, QueueProgress?>(
  PublishQueue.new,
);
