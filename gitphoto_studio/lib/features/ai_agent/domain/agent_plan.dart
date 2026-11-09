import '../../github/domain/github_models.dart';
import '../../media_editor/domain/optimization.dart';

/// Médias visés par une action : identifiants de la bibliothèque et/ou
/// versions produites par des actions précédentes du même plan.
class MediaRefs {
  const MediaRefs({this.mediaIds = const [], this.fromSteps = const []});

  final List<int> mediaIds;

  /// Indices (à partir de 0) d'actions d'optimisation ou de conversion
  /// antérieures dont les versions produites sont reprises.
  final List<int> fromSteps;

  bool get isEmpty => mediaIds.isEmpty && fromSteps.isEmpty;
}

enum DateGranularity { year, month }

/// Action d'un plan, **validée** par l'application : chaque champ a été
/// contrôlé (médias existants, dépôt accessible, chemins sûrs…). Aucune
/// action n'est destructive : rien n'est supprimé ni écrasé.
sealed class AgentAction {
  const AgentAction({this.note});

  /// Explication courte rédigée par le modèle (affichée telle quelle,
  /// jamais interprétée).
  final String? note;
}

/// Range des médias dans un album (créé s'il n'existe pas).
class MoveToAlbumAction extends AgentAction {
  const MoveToAlbumAction({
    required this.refs,
    required this.album,
    super.note,
  });

  final MediaRefs refs;
  final String album;
}

/// Range des médias dans des albums « 2024 » ou « 2024-03 » selon la date
/// de prise de vue (à défaut, la date d'import).
class OrganizeByDateAction extends AgentAction {
  const OrganizeByDateAction({
    required this.refs,
    required this.granularity,
    super.note,
  });

  final MediaRefs refs;
  final DateGranularity granularity;
}

/// Crée des versions optimisées (les originaux sont conservés).
class OptimizeImagesAction extends AgentAction {
  const OptimizeImagesAction({
    required this.mediaIds,
    required this.preset,
    super.note,
  });

  final List<int> mediaIds;
  final ImagePreset preset;
}

/// Crée des versions vidéo converties (les originaux sont conservés).
class ConvertVideosAction extends AgentAction {
  const ConvertVideosAction({
    required this.mediaIds,
    required this.preset,
    super.note,
  });

  final List<int> mediaIds;
  final VideoPreset preset;
}

/// Publie dans un dépôt GitHub en un commit, sans jamais remplacer un
/// fichier existant (renommage en cas de conflit).
class PublishAction extends AgentAction {
  const PublishAction({
    required this.refs,
    required this.repo,
    required this.branch,
    required this.folder,
    required this.message,
    this.readme,
    super.note,
  });

  final MediaRefs refs;
  final GithubRepo repo;
  final String branch;
  final String folder;
  final String message;

  /// Contenu Markdown d'un `README.md` ajouté au même commit.
  final String? readme;
}

class AgentPlan {
  const AgentPlan({
    required this.summary,
    required this.actions,
    this.warnings = const [],
  });

  final String summary;
  final List<AgentAction> actions;

  /// Avertissements calculés par l'application (position GPS, dépôt
  /// public…), jamais par le modèle.
  final List<PlanWarning> warnings;

  bool get publishes => actions.any((a) => a is PublishAction);

  bool get publishesToPublicRepo =>
      actions.any((a) => a is PublishAction && !a.repo.isPrivate);
}

enum PlanWarningKind {
  /// Des originaux avec position GPS seraient publiés.
  gpsInPublishedFiles,

  /// Publication dans un dépôt public.
  publicRepository,

  /// Conversion vidéo indisponible sur cet appareil.
  videoConversionUnavailable,
}

class PlanWarning {
  const PlanWarning(this.kind, {this.step, this.count = 0, this.detail});

  final PlanWarningKind kind;
  final int? step;
  final int count;
  final String? detail;
}
