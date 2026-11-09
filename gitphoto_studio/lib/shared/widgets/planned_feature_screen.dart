import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'screen_frame.dart';

/// Écran d'une fonctionnalité pas encore implémentée.
///
/// Il décrit honnêtement ce qui est prévu et dans quelle phase, sans aucun
/// bouton factice.
class PlannedFeatureScreen extends StatelessWidget {
  const PlannedFeatureScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.intro,
    required this.features,
    required this.phase,
    required this.phaseName,
  });

  final String title;
  final IconData icon;
  final String intro;

  /// Liste des fonctionnalités, une par ligne.
  final String features;
  final int phase;
  final String phaseName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);

    return ScreenFrame(
      title: title,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: studio.heroGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 48, color: studio.accent),
              const SizedBox(width: 20),
              Expanded(child: Text(intro, style: theme.textTheme.titleMedium)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.construction, color: studio.creative),
                    const SizedBox(width: 8),
                    Text(l10n.plannedTitle, style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.plannedPhase(phase, phaseName),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final line in features.split('\n'))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.radio_button_unchecked,
                          size: 18,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(line)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  l10n.plannedHonesty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
