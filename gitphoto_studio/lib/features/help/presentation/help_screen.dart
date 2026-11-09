import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/planned_feature_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlannedFeatureScreen(
      title: l10n.navHelp,
      icon: Icons.menu_book,
      intro: l10n.helpIntro,
      features: l10n.helpFeatures,
      phase: 7,
      phaseName: l10n.phaseDocumentation,
    );
  }
}
