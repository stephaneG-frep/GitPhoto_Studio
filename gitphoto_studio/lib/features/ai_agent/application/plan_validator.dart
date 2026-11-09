import '../../gallery/domain/media_item.dart';
import '../../github/data/github_exception.dart';
import '../../github/domain/github_models.dart';
import '../../media_editor/domain/optimization.dart';
import '../domain/agent_plan.dart';
import 'agent_environment.dart';
import 'agent_tools.dart';
import 'tool_args.dart';

/// Résultat de la validation d'un plan proposé par le modèle.
sealed class PlanValidation {
  const PlanValidation();
}

class ValidPlan extends PlanValidation {
  const ValidPlan(this.plan);

  final AgentPlan plan;
}

class InvalidPlan extends PlanValidation {
  const InvalidPlan(this.errors);

  /// Messages renvoyés au modèle pour qu'il corrige sa proposition.
  final List<String> errors;
}

/// Valide **chaque champ** d'un plan produit par le modèle avant de le
/// montrer à l'utilisateur : types, bornes, existence des médias, dépôt
/// réellement accessible en écriture, chemins sûrs, références entre étapes.
///
/// Le modèle ne peut exprimer que les cinq actions de [AgentAction] ; aucune
/// suppression, aucun écrasement, aucune commande n'est représentable.
class PlanValidator {
  PlanValidator(this.env);

  final AgentEnvironment env;

  static const maxSteps = 10;
  static const maxMediaPerStep = 500;
  static const maxReadmeChars = 20000;
  static const maxMessageChars = 200;
  static const maxAlbumChars = 60;

  static const _stepTypes = [
    'move_to_album',
    'organize_by_date',
    'optimize_images',
    'convert_videos',
    'publish',
  ];

  Future<PlanValidation> validate(Map<String, Object?> args) async {
    final errors = <String>[];
    String summary = '';
    try {
      summary = reqString(args, 'summary', max: 500);
    } on ToolArgException catch (e) {
      errors.add(e.message);
    }
    final rawSteps = args['steps'];
    if (rawSteps is! List || rawSteps.isEmpty) {
      return InvalidPlan([...errors, '« steps » doit être une liste non vide']);
    }
    if (rawSteps.length > maxSteps) {
      return InvalidPlan([...errors, '$maxSteps étapes au maximum']);
    }

    List<GithubRepo>? repos;
    final actions = <AgentAction>[];
    final warnings = <PlanWarning>[];
    final stepTypes = <String>[];

    for (final (index, raw) in rawSteps.indexed) {
      final n = index + 1;
      if (raw is! Map) {
        errors.add('Étape $n : objet attendu');
        stepTypes.add('');
        continue;
      }
      final step = raw.cast<String, Object?>();
      try {
        final type = optEnum(step, 'type', _stepTypes);
        if (type == null) throw const ToolArgException('« type » est requis');
        stepTypes.add(type);
        final note = optString(step, 'note', max: 300);
        switch (type) {
          case 'move_to_album':
            final refs = _refs(step, index, stepTypes);
            final album = reqString(step, 'album', max: maxAlbumChars);
            actions.add(
              MoveToAlbumAction(refs: refs, album: album, note: note),
            );
          case 'organize_by_date':
            final refs = _refs(step, index, stepTypes);
            final g =
                optEnum(step, 'granularity', const ['year', 'month']) ??
                'month';
            actions.add(
              OrganizeByDateAction(
                refs: refs,
                granularity: DateGranularity.values.byName(g),
                note: note,
              ),
            );
          case 'optimize_images':
            final media = _media(reqIds(step, 'media_ids'));
            final videos = media.where((m) => m.isVideo).map((m) => m.id);
            if (videos.isNotEmpty) {
              throw ToolArgException(
                'optimize_images ne traite que des images ; vidéos : '
                '${videos.join(', ')}',
              );
            }
            final preset =
                optEnum(step, 'preset', const ['web', 'light', 'thumbnail']) ??
                'web';
            actions.add(
              OptimizeImagesAction(
                mediaIds: [for (final m in media) m.id],
                preset: ImagePreset.values.byName(preset),
                note: note,
              ),
            );
          case 'convert_videos':
            final media = _media(reqIds(step, 'media_ids'));
            final images = media.where((m) => !m.isVideo).map((m) => m.id);
            if (images.isNotEmpty) {
              throw ToolArgException(
                'convert_videos ne traite que des vidéos ; images : '
                '${images.join(', ')}',
              );
            }
            final preset = VideoPreset.values.byName(
              optEnum(step, 'preset', [
                    for (final v in VideoPreset.values) v.name,
                  ]) ??
                  VideoPreset.p720.name,
            );
            if (!env.videoConversionSupported) {
              warnings.add(
                PlanWarning(
                  PlanWarningKind.videoConversionUnavailable,
                  step: index,
                ),
              );
            }
            actions.add(
              ConvertVideosAction(
                mediaIds: [for (final m in media) m.id],
                preset: preset,
                note: note,
              ),
            );
          case 'publish':
            final readme = optString(step, 'readme', max: maxReadmeChars);
            final refs = _refs(
              step,
              index,
              stepTypes,
              allowEmpty: readme != null && readme.isNotEmpty,
            );
            final repoName = reqString(step, 'repository', max: 200);
            try {
              repos ??= await env.repositories();
            } on GithubException catch (e) {
              throw ToolArgException(
                'GitHub indisponible (${e.kind.name}) : la publication est '
                'impossible pour le moment',
              );
            }
            final repo = AgentToolbox.findRepo(repos, repoName);
            if (repo == null) {
              throw ToolArgException(
                'dépôt « $repoName » inconnu ou inaccessible (consultez '
                'github_status)',
              );
            }
            if (!repo.canPush) {
              throw ToolArgException(
                'pas de droit d’écriture sur ${repo.fullName}',
              );
            }
            final branch =
                optBranch(step, 'branch') ?? repo.defaultBranch ?? 'main';
            final folder = optFolder(step, 'folder') ?? '';
            final message = reqString(step, 'message', max: maxMessageChars);
            final gps = refs.mediaIds
                .map(env.media)
                .whereType<MediaItem>()
                .where((m) => m.hasGps)
                .length;
            if (gps > 0) {
              warnings.add(
                PlanWarning(
                  PlanWarningKind.gpsInPublishedFiles,
                  step: index,
                  count: gps,
                ),
              );
            }
            if (!repo.isPrivate) {
              warnings.add(
                PlanWarning(
                  PlanWarningKind.publicRepository,
                  step: index,
                  detail: repo.fullName,
                ),
              );
            }
            actions.add(
              PublishAction(
                refs: refs,
                repo: repo,
                branch: branch,
                folder: folder,
                message: message,
                readme: readme == null || readme.isEmpty ? null : readme,
                note: note,
              ),
            );
        }
      } on ToolArgException catch (e) {
        errors.add('Étape $n : ${e.message}');
        if (stepTypes.length <= index) stepTypes.add('');
      }
    }
    if (errors.isNotEmpty) return InvalidPlan(errors);
    return ValidPlan(
      AgentPlan(summary: summary, actions: actions, warnings: warnings),
    );
  }

  List<MediaItem> _media(List<int> ids) {
    if (ids.length > maxMediaPerStep) {
      throw const ToolArgException('$maxMediaPerStep médias au maximum');
    }
    final missing = <int>[];
    final out = <MediaItem>[];
    for (final id in ids) {
      final m = env.media(id);
      if (m == null) {
        missing.add(id);
      } else {
        out.add(m);
      }
    }
    if (missing.isNotEmpty) {
      throw ToolArgException(
        'médias introuvables : ${missing.join(', ')} (utilisez search_media)',
      );
    }
    return out;
  }

  MediaRefs _refs(
    Map<String, Object?> step,
    int index,
    List<String> stepTypes, {
    bool allowEmpty = false,
  }) {
    final ids = optIds(step, 'media_ids', max: maxMediaPerStep) ?? const [];
    _media(ids);
    final from = optIds(step, 'from_steps', max: maxSteps) ?? const [];
    for (final s in from) {
      if (s > index) {
        throw ToolArgException(
          'from_steps : l’étape $s ne précède pas celle-ci',
        );
      }
      final t = stepTypes[s - 1];
      if (t != 'optimize_images' && t != 'convert_videos') {
        throw ToolArgException(
          'from_steps : l’étape $s ne produit pas de copies',
        );
      }
    }
    final refs = MediaRefs(
      mediaIds: ids,
      fromSteps: [for (final s in from) s - 1],
    );
    if (refs.isEmpty && !allowEmpty) {
      throw const ToolArgException('media_ids ou from_steps est requis');
    }
    return refs;
  }
}
