import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/destinations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/byte_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../../../shared/open_url.dart';
import '../../github/application/github_session.dart';
import '../../github/presentation/github_error_text.dart';
import '../../publishing/application/publish_controller.dart';
import '../application/dashboard_stats.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    ref.watch(operationsRevisionProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return ScreenFrame(
      title: l10n.navDashboard,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: studio.heroGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(l10n.appTagline, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.hub_outlined, color: studio.accent),
                  const SizedBox(width: 8),
                  // Un seul texte qui passe à la ligne si les caractères
                  // sont agrandis (accessibilité).
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${l10n.dashActiveRepo} : ',
                            style: theme.textTheme.titleSmall,
                          ),
                          TextSpan(
                            text: stats.activeRepository ?? l10n.dashNoRepo,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Les trois compteurs partagent toujours une ligne, quelle que soit
        // la largeur de l'écran.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatTile(
                icon: Icons.photo_library_outlined,
                label: l10n.dashLocalMedia,
                value: '${stats.mediaCount}',
                color: studio.accent,
              ),
              _StatTile(
                icon: Icons.pending_actions_outlined,
                label: l10n.dashPending,
                value: '${stats.pendingCount}',
                color: studio.creative,
              ),
              _StatTile(
                icon: Icons.storage_outlined,
                label: l10n.dashLocalStorage,
                value: formatBytes(stats.localBytes, locale: locale),
                color: studio.success,
              ),
            ],
          ),
        ),
        SectionTitle(l10n.dashTransfers),
        _InfoCard(icon: Icons.swap_vert, text: l10n.dashNoTransfers),
        SectionTitle(l10n.dashRecentCommits),
        const _RecentCommits(),
        SectionTitle(l10n.dashShortcuts),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in AppDestination.values)
              if (d != AppDestination.dashboard)
                ActionChip(
                  avatar: Icon(d.icon, size: 18),
                  label: Text(d.label(l10n)),
                  onPressed: () => context.go(d.path),
                ),
          ],
        ),
        const SizedBox(height: 24),
        PixelTip(message: l10n.pixelWelcome),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: theme.textTheme.headlineSmall),
                ),
                Text(label, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(text)),
    );
  }
}

/// Derniers commits du dépôt actif (si connecté).
class _RecentCommits extends ConsumerWidget {
  const _RecentCommits();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeRepositoryProvider);
    final api = ref.watch(githubApiProvider);
    if (active == null || api == null) {
      return _InfoCard(icon: Icons.commit, text: l10n.dashNoCommitsConnect);
    }
    final commits = ref.watch(
      githubCommitsProvider((
        owner: active.owner,
        name: active.name,
        branch: active.defaultBranch,
      )),
    );
    return commits.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          _InfoCard(icon: Icons.error_outline, text: describeError(context, e)),
      data: (list) => Card(
        child: Column(
          children: [
            for (final c in list.take(5))
              ListTile(
                dense: true,
                leading: const Icon(Icons.commit),
                title: Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${c.shortSha} · ${c.author ?? ''}'),
                onTap: () => openUrl(context, c.htmlUrl),
              ),
          ],
        ),
      ),
    );
  }
}
