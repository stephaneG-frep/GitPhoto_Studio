import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../gallery/domain/media_item.dart';
import '../../github/application/github_session.dart';
import '../../github/domain/github_models.dart';
import '../data/operations_repository.dart';
import '../domain/publish_plan.dart';
export 'publication_analyzer.dart' show PublishPreferenceKeys;

import 'publication_analyzer.dart';
import 'publish_queue.dart';
import 'publisher.dart';

final operationsRepositoryProvider = Provider<OperationsRepository>(
  (ref) => OperationsRepository(ref.watch(appDatabaseProvider)),
);

/// Incrémenté quand l'historique ou le dépôt actif change.
class OperationsRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final operationsRevisionProvider = NotifierProvider<OperationsRevision, int>(
  OperationsRevision.new,
);

final operationsProvider = Provider<List<OperationRecord>>((ref) {
  ref.watch(operationsRevisionProvider);
  return ref.watch(operationsRepositoryProvider).list();
});

final activeRepositoryProvider =
    Provider<({String owner, String name, String? defaultBranch})?>((ref) {
      ref.watch(operationsRevisionProvider);
      return ref.watch(operationsRepositoryProvider).activeRepository();
    });

/// Destination choisie dans l'assistant.
class PublishTarget {
  const PublishTarget({
    required this.repo,
    required this.branch,
    required this.folder,
  });

  final GithubRepo repo;
  final String branch;
  final String folder;
}

sealed class PublishState {
  const PublishState();
}

class PublishIdle extends PublishState {
  const PublishIdle();
}

class PublishAnalyzing extends PublishState {
  const PublishAnalyzing(this.done, this.total);

  final int done;
  final int total;
}

class PublishPlanned extends PublishState {
  const PublishPlanned(this.target, this.plan);

  final PublishTarget target;
  final PublishPlan plan;
}

class PublishRunning extends PublishState {
  const PublishRunning(
    this.target,
    this.plan,
    this.step,
    this.done,
    this.total,
  );

  final PublishTarget target;
  final PublishPlan plan;
  final PublishStep step;
  final int done;
  final int total;
}

class PublishSucceeded extends PublishState {
  const PublishSucceeded(this.target, this.plan, this.result);

  final PublishTarget target;
  final PublishPlan plan;
  final PublishResult result;
}

class PublishFailed extends PublishState {
  const PublishFailed(this.error, {this.target, this.plan});

  final Object error;
  final PublishTarget? target;
  final PublishPlan? plan;
}

class PublishController extends Notifier<PublishState> {
  @override
  PublishState build() => const PublishIdle();

  bool get isBusy => state is PublishAnalyzing || state is PublishRunning;

  void reset() {
    if (!isBusy) state = const PublishIdle();
  }

  Future<void> analyze({
    required List<MediaItem> media,
    required PublishTarget target,
    ConflictPolicy policy = ConflictPolicy.rename,
    Set<int> overwriteMediaIds = const {},
  }) async {
    final api = ref.read(githubApiProvider);
    if (api == null || isBusy) return;
    state = PublishAnalyzing(0, media.length);
    try {
      final plan = await ref
          .read(publicationAnalyzerProvider)
          .analyze(
            api: api,
            owner: target.repo.owner,
            repo: target.repo.name,
            branch: target.branch,
            folder: target.folder,
            media: media,
            policy: policy,
            overwriteMediaIds: overwriteMediaIds,
            onProgress: (done, total) {
              if (ref.mounted) state = PublishAnalyzing(done, total);
            },
          );
      if (ref.mounted) state = PublishPlanned(target, plan);
    } on Object catch (e) {
      ref.read(loggerProvider).warning('Analyse de publication : $e');
      if (ref.mounted) state = PublishFailed(e, target: target);
    }
  }

  /// Met la publication en file d'attente persistante et suit son
  /// exécution. L'opération continue même si l'utilisateur quitte l'écran.
  Future<void> publish(String message) async {
    final current = state;
    if (current is! PublishPlanned) return;
    final target = current.target;
    final plan = current.plan;
    int? operationId;
    state = PublishRunning(target, plan, PublishStep.uploading, 0, 1);
    final sub = ref.listen(publishQueueProvider, (_, progress) {
      if (progress != null &&
          progress.operationId == operationId &&
          ref.mounted) {
        state = PublishRunning(
          target,
          plan,
          progress.step,
          progress.done,
          progress.total,
        );
      }
    });
    try {
      final outcome = await ref
          .read(publishQueueProvider.notifier)
          .enqueue(
            repo: target.repo,
            branch: target.branch,
            message: message,
            plan: plan,
            onQueued: (id) => operationId = id,
          );
      if (!ref.mounted) return;
      if (outcome.result case final result?) {
        state = PublishSucceeded(target, plan, result);
      } else if (outcome.cancelled) {
        state = PublishFailed(
          const PublishCancelled(),
          target: target,
          plan: plan,
        );
      } else {
        state = PublishFailed(outcome.error!, target: target, plan: plan);
      }
    } on Object catch (e) {
      if (ref.mounted) state = PublishFailed(e, target: target, plan: plan);
    } finally {
      sub.close();
    }
  }
}

final publishControllerProvider =
    NotifierProvider<PublishController, PublishState>(PublishController.new);
