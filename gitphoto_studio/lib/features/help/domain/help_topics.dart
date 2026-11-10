import 'package:flutter/material.dart';

import '../../../app/destinations.dart';

/// Rubriques du mode d'emploi intégré. Chaque rubrique correspond à un
/// fichier `assets/help/<langue>/<id>.md` livré avec l'application.
enum HelpTopic {
  gettingStarted('premiers-pas', Icons.rocket_launch_outlined),
  githubLogin('connexion-github', Icons.key_outlined),
  createRepo('creer-depot', Icons.create_new_folder_outlined),
  publishPhoto('publier-photo', Icons.cloud_upload_outlined),
  publishVideo('publier-video', Icons.movie_outlined),
  editor('optimiser-organiser', Icons.auto_fix_high_outlined),
  commits('commits', Icons.commit),
  branches('branches', Icons.call_split),
  gitLfs('git-lfs', Icons.inventory_2_outlined),
  history('historique-reprise', Icons.history),
  aiAgent('agent-ia', Icons.smart_toy_outlined),
  aiProviders('fournisseurs-ia', Icons.vpn_key_outlined),
  errors('erreurs', Icons.report_problem_outlined),
  privacy('confidentialite', Icons.privacy_tip_outlined),
  faq('faq', Icons.quiz_outlined),
  glossary('glossaire', Icons.translate);

  const HelpTopic(this.id, this.icon);

  final String id;
  final IconData icon;

  static HelpTopic? byId(String id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }

  String assetPath(String languageCode) => 'assets/help/$languageCode/$id.md';
}

/// Rubrique ouverte par le bouton d'aide de chaque écran.
HelpTopic? contextualTopic(AppDestination d) => switch (d) {
  AppDestination.dashboard => HelpTopic.gettingStarted,
  AppDestination.gallery => HelpTopic.gettingStarted,
  AppDestination.editor => HelpTopic.editor,
  AppDestination.github => HelpTopic.githubLogin,
  AppDestination.publish => HelpTopic.publishPhoto,
  AppDestination.agent => HelpTopic.aiAgent,
  AppDestination.history => HelpTopic.history,
  AppDestination.settings => HelpTopic.faq,
  AppDestination.help => null,
};

/// Langues pour lesquelles le mode d'emploi est rédigé.
const helpLanguages = ['fr', 'en'];
