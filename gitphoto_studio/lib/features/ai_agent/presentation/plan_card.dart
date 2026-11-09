import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/open_url.dart';
import '../../media_editor/domain/optimization.dart';
import '../application/agent_controller.dart';
import '../application/plan_executor.dart';
import '../domain/agent_plan.dart';
import 'agent_error_text.dart';

String imagePresetLabel(AppLocalizations l10n, ImagePreset p) => switch (p) {
  ImagePreset.web => l10n.presetWeb,
  ImagePreset.light => l10n.presetLight,
  ImagePreset.thumbnail => l10n.presetThumbnail,
  ImagePreset.custom => l10n.presetCustom,
};

String videoPresetLabel(AppLocalizations l10n, VideoPreset p) => switch (p) {
  VideoPreset.p720 => l10n.videoPreset720,
  VideoPreset.p1080 => l10n.videoPreset1080,
  VideoPreset.light => l10n.videoPresetLight,
};

String refsLabel(AppLocalizations l10n, MediaRefs refs) => [
  if (refs.mediaIds.isNotEmpty) l10n.planMediaCount(refs.mediaIds.length),
  for (final s in refs.fromSteps) l10n.planFromStep(s + 1),
].join(' + ');

/// Libellé d'une action, construit par l'application à partir des champs
/// validés (jamais à partir d'un texte libre du modèle).
String actionLabel(AppLocalizations l10n, AgentAction a) => switch (a) {
  MoveToAlbumAction(:final refs, :final album) => l10n.planStepMove(
    refsLabel(l10n, refs),
    album,
  ),
  OrganizeByDateAction(:final refs, :final granularity) =>
    granularity == DateGranularity.year
        ? l10n.planStepOrganizeYear(refsLabel(l10n, refs))
        : l10n.planStepOrganizeMonth(refsLabel(l10n, refs)),
  OptimizeImagesAction(:final mediaIds, :final preset) => l10n.planStepOptimize(
    mediaIds.length,
    imagePresetLabel(l10n, preset),
  ),
  ConvertVideosAction(:final mediaIds, :final preset) => l10n.planStepConvert(
    mediaIds.length,
    videoPresetLabel(l10n, preset),
  ),
  PublishAction(:final refs, :final repo, :final branch) =>
    l10n.planStepPublish(
      refs.isEmpty ? l10n.planReadmeOnly : refsLabel(l10n, refs),
      repo.fullName,
      branch,
    ),
};

class PlanCard extends ConsumerWidget {
  const PlanCard({super.key, required this.entry});

  final PlanEntry entry;

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final plan = entry.plan;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.planConfirmBody(plan.actions.length)),
            if (plan.publishes) ...[
              const SizedBox(height: 8),
              Text(l10n.planConfirmPublish),
            ],
            for (final w in plan.warnings) ...[
              const SizedBox(height: 8),
              Text(
                _warning(l10n, w),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.planExecute),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(agentControllerProvider.notifier).confirm(entry.id);
    }
  }

  static String _warning(AppLocalizations l10n, PlanWarning w) =>
      switch (w.kind) {
        PlanWarningKind.gpsInPublishedFiles => l10n.planWarnGps(w.count),
        PlanWarningKind.publicRepository => l10n.planWarnPublic(w.detail ?? ''),
        PlanWarningKind.videoConversionUnavailable => l10n.planWarnVideo,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final plan = entry.plan;
    final report = entry.report;
    final busy = ref.watch(agentControllerProvider.select((s) => s.busy));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: studio.accent.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: studio.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.planTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(plan.summary),
            const SizedBox(height: 12),
            for (final (i, a) in plan.actions.indexed)
              _StepTile(
                index: i,
                action: a,
                report: report?.steps.elementAtOrNull(i),
                progress: entry.progress?.step == i ? entry.progress : null,
              ),
            for (final w in plan.warnings) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _warning(l10n, w),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            switch (entry.status) {
              PlanStatus.proposed => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : () => _confirm(context, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.planExecute),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(agentControllerProvider.notifier)
                        .reject(entry.id),
                    icon: const Icon(Icons.close),
                    label: Text(l10n.planReject),
                  ),
                ],
              ),
              PlanStatus.running => Row(
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.planStatusRunning)),
                  TextButton(
                    onPressed: () =>
                        ref.read(agentControllerProvider.notifier).cancel(),
                    child: Text(l10n.agentStop),
                  ),
                ],
              ),
              PlanStatus.rejected => Text(
                l10n.planStatusRejected,
                style: theme.textTheme.bodySmall,
              ),
              PlanStatus.expired => Text(
                l10n.planStatusExpired,
                style: theme.textTheme.bodySmall,
              ),
              PlanStatus.finished => _Outcome(report: report!),
            },
          ],
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.report});

  final PlanReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final studio = StudioColors.of(context);
    final theme = Theme.of(context);
    final partial = report.steps.any((s) => s.status == StepStatus.partial);
    final (text, icon, color) = report.cancelled
        ? (
            l10n.planDoneCancelled,
            Icons.pause_circle,
            theme.colorScheme.outline,
          )
        : !report.succeeded
        ? (l10n.planDoneFailed, Icons.error, theme.colorScheme.error)
        : partial
        ? (l10n.planDonePartial, Icons.info, studio.creative)
        : (l10n.planDoneOk, Icons.check_circle, studio.success);
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.action,
    this.report,
    this.progress,
  });

  final int index;
  final AgentAction action;
  final StepReport? report;
  final PlanProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final a = action;
    final r = report;
    final details = <String>[
      if (a is PublishAction) ...[
        a.folder.isEmpty
            ? l10n.planPublishRoot
            : l10n.planPublishFolder(a.folder),
        l10n.planPublishMessage(a.message),
        if (a.readme != null) l10n.planPublishReadme,
        l10n.planPublishSafety,
      ],
      if (a.note != null && a.note!.isNotEmpty) a.note!,
    ];
    final (statusText, statusColor) = switch (r?.status) {
      null => (null, null),
      StepStatus.done => (l10n.stepDone, studio.success),
      StepStatus.partial => (l10n.stepPartial, studio.creative),
      StepStatus.failed => (l10n.stepFailed, theme.colorScheme.error),
      StepStatus.skipped => (l10n.stepSkipped, theme.colorScheme.outline),
      StepStatus.cancelled => (l10n.stepCancelled, theme.colorScheme.outline),
    };
    final result = <String>[
      if (r != null) ...[
        if (r.produced.isNotEmpty)
          l10n.stepProduced(r.produced.length)
        else if (r.affected > 0)
          l10n.stepAffected(r.affected),
        if (r.alreadyPublished && r.publishResult == null)
          l10n.stepAlreadyPublished,
        if (r.renamed > 0) l10n.stepRenamed(r.renamed),
        if (r.publishResult case final p?) ...[
          '${p.commitSha.substring(0, 7)} — '
              '${p.verified ? l10n.stepVerified : l10n.stepNotVerified}',
        ],
        ...r.failures,
      ],
    ];
    final p = progress;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: statusColor ?? theme.colorScheme.primaryContainer,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                color: statusColor == null
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actionLabel(l10n, a)),
                for (final d in details)
                  Text(d, style: theme.textTheme.bodySmall),
                if (a is PublishAction && a.readme != null)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('README.md', style: theme.textTheme.bodySmall),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: SelectableText(
                          a.readme!,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                if (p != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.planProgress(index + 1, p.done, p.total) +
                        (p.current == null ? '' : ' · ${p.current}'),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                    value: p.total > 0 ? p.done / p.total : null,
                  ),
                ],
                if (statusText != null)
                  Text(
                    statusText,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
                for (final line in result)
                  Text(line, style: theme.textTheme.bodySmall),
                if (r?.error case final e?)
                  Text(
                    describeAgentError(context, e),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                if (r?.publishResult case final pr?)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => openUrl(context, pr.htmlUrl),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.commonOpenInBrowser),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
