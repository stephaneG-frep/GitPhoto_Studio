import '../../gallery/application/media_importer.dart';
import '../../gallery/domain/media_item.dart';
import '../../publishing/application/publication_analyzer.dart';
import '../../publishing/application/publisher.dart';
import '../../publishing/domain/publish_plan.dart';
import '../domain/agent_plan.dart';
import 'agent_environment.dart';

enum StepStatus { done, partial, failed, skipped, cancelled }

/// Compte rendu vérifié d'une action.
class StepReport {
  const StepReport({
    required this.index,
    required this.status,
    this.affected = 0,
    this.produced = const [],
    this.failures = const [],
    this.albums = const [],
    this.publishResult,
    this.alreadyPublished = false,
    this.renamed = 0,
    this.skippedIdentical = 0,
    this.error,
  });

  final int index;
  final StepStatus status;

  /// Médias traités (rangés, optimisés, publiés…).
  final int affected;

  /// Médias créés par l'action (versions optimisées ou converties).
  final List<int> produced;

  /// `nom : raison` des éléments en échec.
  final List<String> failures;

  /// Albums utilisés (rangement).
  final List<String> albums;
  final PublishResult? publishResult;
  final bool alreadyPublished;
  final int renamed;
  final int skippedIdentical;
  final Object? error;
}

class PlanReport {
  const PlanReport(this.steps, {this.cancelled = false});

  final List<StepReport> steps;
  final bool cancelled;

  bool get succeeded => steps.every(
    (s) => s.status == StepStatus.done || s.status == StepStatus.partial,
  );

  /// Résumé factuel transmis au modèle au message suivant.
  String describeForModel() {
    final b = StringBuffer();
    for (final s in steps) {
      b.write('Étape ${s.index + 1} : ${s.status.name}');
      if (s.affected > 0) b.write(', ${s.affected} élément(s)');
      if (s.produced.isNotEmpty) {
        b.write(', copies créées (ids) : ${s.produced.join(', ')}');
      }
      if (s.albums.isNotEmpty) b.write(', albums : ${s.albums.join(', ')}');
      if (s.publishResult case final r?) {
        b.write(
          ', commit ${r.commitSha.substring(0, 7)}'
          '${r.verified ? ' vérifié' : ' non vérifié'}',
        );
      }
      if (s.alreadyPublished) b.write(', déjà publié');
      if (s.failures.isNotEmpty) b.write(', échecs : ${s.failures.join('; ')}');
      if (s.error != null) b.write(', erreur : ${s.error}');
      b.writeln();
    }
    return b.toString();
  }
}

typedef StepProgress =
    void Function(int stepIndex, int done, int total, String? current);

/// Exécute un plan **déjà validé et confirmé**, action par action, avec les
/// services de l'application. S'arrête à la première action en échec (les
/// suivantes sont marquées non exécutées), vérifie chaque résultat.
class PlanExecutor {
  PlanExecutor(this.env);

  final AgentEnvironment env;

  Future<PlanReport> run(
    AgentPlan plan, {
    StepProgress? onProgress,
    bool Function()? isCancelled,
  }) async {
    final reports = <StepReport>[];
    final produced = <int, List<int>>{};
    var stop = false;
    var cancelled = false;
    for (final (i, action) in plan.actions.indexed) {
      if (stop) {
        reports.add(StepReport(index: i, status: StepStatus.skipped));
        continue;
      }
      if (isCancelled?.call() ?? false) {
        cancelled = true;
        stop = true;
        reports.add(StepReport(index: i, status: StepStatus.cancelled));
        continue;
      }
      StepReport report;
      try {
        report = await _run(i, action, produced, onProgress, isCancelled);
      } on PublishCancelled {
        report = StepReport(index: i, status: StepStatus.cancelled);
      } on Object catch (e) {
        report = StepReport(index: i, status: StepStatus.failed, error: e);
      }
      produced[i] = report.produced;
      reports.add(report);
      if (report.status == StepStatus.failed ||
          report.status == StepStatus.cancelled) {
        stop = true;
        cancelled = report.status == StepStatus.cancelled;
      }
    }
    return PlanReport(reports, cancelled: cancelled);
  }

  List<MediaItem> _resolve(MediaRefs refs, Map<int, List<int>> produced) {
    final ids = <int>{
      ...refs.mediaIds,
      for (final s in refs.fromSteps) ...?produced[s],
    };
    final out = <MediaItem>[];
    for (final id in ids) {
      final m = env.media(id);
      if (m == null) {
        throw StateError('Le média $id a été retiré de la bibliothèque');
      }
      out.add(m);
    }
    return out;
  }

  Future<StepReport> _run(
    int i,
    AgentAction action,
    Map<int, List<int>> produced,
    StepProgress? onProgress,
    bool Function()? isCancelled,
  ) async {
    switch (action) {
      case MoveToAlbumAction(:final refs, :final album):
        final media = _resolve(refs, produced);
        if (media.isEmpty) return _nothing(i);
        onProgress?.call(i, 0, 1, album);
        env.moveToAlbum([for (final m in media) m.id], album);
        return _verifyAlbums(i, {album: media});

      case OrganizeByDateAction(:final refs, :final granularity):
        final media = _resolve(refs, produced);
        if (media.isEmpty) return _nothing(i);
        final groups = <String, List<MediaItem>>{};
        for (final m in media) {
          final d = m.takenAt ?? m.importedAt;
          final name = granularity == DateGranularity.year
              ? '${d.year}'
              : '${d.year}-${d.month.toString().padLeft(2, '0')}';
          (groups[name] ??= []).add(m);
        }
        var done = 0;
        for (final e in groups.entries) {
          onProgress?.call(i, done++, groups.length, e.key);
          env.moveToAlbum([for (final m in e.value) m.id], e.key);
        }
        return _verifyAlbums(i, groups);

      case OptimizeImagesAction(:final mediaIds, :final preset):
        final media = _resolve(MediaRefs(mediaIds: mediaIds), produced);
        final out = <int>[];
        final failures = <String>[];
        for (final (k, m) in media.indexed) {
          if (isCancelled?.call() ?? false) {
            return StepReport(
              index: i,
              status: StepStatus.cancelled,
              produced: out,
              affected: out.length,
            );
          }
          onProgress?.call(i, k, media.length, m.fileName);
          try {
            _collect(await env.optimizeImage(m, preset), out, failures);
          } on Object catch (e) {
            failures.add('${m.fileName} : $e');
          }
        }
        return _versions(i, out, failures);

      case ConvertVideosAction(:final mediaIds, :final preset):
        if (!env.videoConversionSupported) {
          return StepReport(
            index: i,
            status: StepStatus.failed,
            error: 'Conversion vidéo indisponible sur cet appareil',
          );
        }
        final media = _resolve(MediaRefs(mediaIds: mediaIds), produced);
        final out = <int>[];
        final failures = <String>[];
        for (final (k, m) in media.indexed) {
          onProgress?.call(i, k, media.length, m.fileName);
          try {
            _collect(
              await env.convertVideo(m, preset, isCancelled: isCancelled),
              out,
              failures,
            );
          } on Object catch (e) {
            if (isCancelled?.call() ?? false) {
              return StepReport(
                index: i,
                status: StepStatus.cancelled,
                produced: out,
                affected: out.length,
              );
            }
            failures.add('${m.fileName} : $e');
          }
        }
        return _versions(i, out, failures);

      case PublishAction():
        return _publish(i, action, produced, onProgress);
    }
  }

  StepReport _nothing(int i) => StepReport(
    index: i,
    status: StepStatus.failed,
    error: 'Aucun média à traiter (les étapes précédentes n’ont rien produit)',
  );

  void _collect(ImportItemResult r, List<int> out, List<String> failures) {
    // Une version identique déjà présente est réutilisée.
    if ((r.outcome == ImportOutcome.imported ||
            r.outcome == ImportOutcome.duplicate) &&
        r.mediaId != null) {
      out.add(r.mediaId!);
    } else {
      failures.add('${r.name} : ${r.error ?? r.outcome.name}');
    }
  }

  StepReport _versions(int i, List<int> out, List<String> failures) {
    // Vérification : chaque version annoncée existe dans la bibliothèque.
    final missing = out.where((id) => env.media(id) == null).toList();
    if (missing.isNotEmpty) {
      failures.add('versions introuvables après création : $missing');
    }
    final ok = out.where((id) => env.media(id) != null).toList();
    return StepReport(
      index: i,
      status: ok.isEmpty
          ? StepStatus.failed
          : failures.isEmpty
          ? StepStatus.done
          : StepStatus.partial,
      affected: ok.length,
      produced: ok,
      failures: failures,
    );
  }

  StepReport _verifyAlbums(int i, Map<String, List<MediaItem>> groups) {
    final albumIds = {for (final a in env.albums()) a.name.toLowerCase(): a.id};
    final failures = <String>[];
    var ok = 0;
    for (final e in groups.entries) {
      final id = albumIds[e.key.toLowerCase()];
      for (final m in e.value) {
        if (id != null && env.media(m.id)?.albumId == id) {
          ok++;
        } else {
          failures.add('${m.fileName} : non rangé dans « ${e.key} »');
        }
      }
    }
    return StepReport(
      index: i,
      status: failures.isEmpty ? StepStatus.done : StepStatus.failed,
      affected: ok,
      failures: failures,
      albums: groups.keys.toList(),
    );
  }

  Future<StepReport> _publish(
    int i,
    PublishAction a,
    Map<int, List<int>> produced,
    StepProgress? onProgress,
  ) async {
    final media = _resolve(a.refs, produced);
    final extra = <ExtraPublishFile>[];
    if (a.readme != null) {
      final path = await env.writeDocument('README.md', a.readme!);
      extra.add(ExtraPublishFile(fileName: 'README.md', localPath: path));
    }
    if (media.isEmpty && extra.isEmpty) return _nothing(i);
    onProgress?.call(i, 0, 1, a.repo.fullName);
    // Analyse au moment de l'exécution : l'état du dépôt a pu changer.
    // Politique « renommer » : aucun fichier existant n'est remplacé.
    final plan = await env.analyzePublication(
      repo: a.repo,
      branch: a.branch,
      folder: a.folder,
      media: media,
      extraFiles: extra,
    );
    final blocked = plan.files.where((f) => f.action == PlannedAction.blocked);
    if (blocked.isNotEmpty) {
      return StepReport(
        index: i,
        status: StepStatus.failed,
        failures: [
          for (final f in blocked)
            '${f.candidate.fileName} : ${f.blockReason?.name ?? 'bloqué'}',
        ],
        error: 'Fichiers impossibles à publier : rien n’a été envoyé',
      );
    }
    final renamed = plan.count(PlannedAction.renamed);
    final identical = plan.count(PlannedAction.skipIdentical);
    if (plan.uploads.isEmpty) {
      return StepReport(
        index: i,
        status: StepStatus.done,
        alreadyPublished: true,
        skippedIdentical: identical,
      );
    }
    final outcome = await env.publish(
      repo: a.repo,
      branch: a.branch,
      message: a.message,
      plan: plan,
    );
    if (outcome.cancelled) {
      return StepReport(index: i, status: StepStatus.cancelled);
    }
    final result = outcome.result;
    if (result == null) {
      return StepReport(
        index: i,
        status: StepStatus.failed,
        error: outcome.error,
      );
    }
    return StepReport(
      index: i,
      // Commit créé mais contenu distant non confirmé : signalé.
      status: result.verified ? StepStatus.done : StepStatus.partial,
      affected: plan.uploads.length,
      publishResult: result,
      alreadyPublished: outcome.alreadyPublished,
      renamed: renamed,
      skippedIdentical: identical,
      failures: result.verified ? const [] : const ['vérification distante'],
    );
  }
}
