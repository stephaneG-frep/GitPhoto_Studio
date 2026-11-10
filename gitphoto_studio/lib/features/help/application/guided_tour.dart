import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/destinations.dart';
import '../../ai_agent/application/ai_settings.dart';
import '../../gallery/application/gallery_providers.dart';
import '../../gallery/domain/media_query.dart';
import '../../github/application/github_session.dart';
import '../../publishing/application/publish_controller.dart';
import '../../publishing/data/operations_repository.dart';
import '../domain/help_topics.dart';

enum TourStep {
  importMedia,
  connectGithub,
  chooseRepository,
  optimize,
  publish,
  checkHistory,
  configureAi,
}

class TourItem {
  const TourItem({
    required this.step,
    required this.done,
    required this.destination,
    required this.topic,
    this.optional = false,
  });

  final TourStep step;

  /// Calculé à partir de l'état réel de l'application, jamais déclaré par
  /// l'utilisateur.
  final bool done;
  final AppDestination destination;
  final HelpTopic topic;
  final bool optional;
}

/// Parcours guidé pour débutants : chaque étape est cochée d'après les
/// données de l'application (bibliothèque, session GitHub, historique…).
final guidedTourProvider = Provider<List<TourItem>>((ref) {
  ref.watch(libraryRevisionProvider);
  // Toute la bibliothèque (la liste de la galerie dépend des filtres).
  final all = ref.watch(mediaRepositoryProvider).list(const MediaListQuery());
  final session = ref.watch(githubSessionProvider).value;
  final active = ref.watch(activeRepositoryProvider);
  final ops = ref.watch(operationsProvider);
  final ai = ref.watch(aiSettingsProvider).value;
  final hasVersion = all.any((m) => m.derivedFrom != null);
  final published = ops.any((o) => o.status == OperationStatus.success);
  return [
    TourItem(
      step: TourStep.importMedia,
      done: all.isNotEmpty,
      destination: AppDestination.gallery,
      topic: HelpTopic.gettingStarted,
    ),
    TourItem(
      step: TourStep.connectGithub,
      done: session is GithubConnected,
      destination: AppDestination.github,
      topic: HelpTopic.githubLogin,
    ),
    TourItem(
      step: TourStep.chooseRepository,
      done: active != null,
      destination: AppDestination.github,
      topic: HelpTopic.createRepo,
    ),
    TourItem(
      step: TourStep.optimize,
      done: hasVersion,
      destination: AppDestination.gallery,
      topic: HelpTopic.editor,
      optional: true,
    ),
    TourItem(
      step: TourStep.publish,
      done: published,
      destination: AppDestination.publish,
      topic: HelpTopic.publishPhoto,
    ),
    TourItem(
      step: TourStep.checkHistory,
      done: published,
      destination: AppDestination.history,
      topic: HelpTopic.history,
    ),
    TourItem(
      step: TourStep.configureAi,
      done: ai?.isConfigured ?? false,
      destination: AppDestination.settings,
      topic: HelpTopic.aiProviders,
      optional: true,
    ),
  ];
});
