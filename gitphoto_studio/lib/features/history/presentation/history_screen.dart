import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/byte_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/open_url.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../../github/presentation/github_error_text.dart';
import '../../publishing/application/publish_controller.dart';
import '../../publishing/application/publish_queue.dart';
import '../../publishing/application/publisher.dart';
import '../../publishing/data/operations_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final operations = ref.watch(operationsProvider);
    return ScreenFrame(
      title: l10n.navHistory,
      children: [
        if (operations.isEmpty)
          PixelTip(message: l10n.histEmpty)
        else
          for (final op in operations) OperationCard(op: op),
        const SizedBox(height: 16),
        Text(l10n.histRetryNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class OperationCard extends ConsumerWidget {
  const OperationCard({super.key, required this.op});

  final OperationRecord op;

  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final outcome = await ref.read(publishQueueProvider.notifier).resume(op.id);
    if (!context.mounted) return;
    final text = switch (outcome) {
      QueueOutcome(:final result?) => l10n.pubCommit(result.commitSha),
      QueueOutcome(cancelled: true) => l10n.pubCancelled,
      QueueOutcome(:final error) => describeError(context, error ?? '?'),
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.histCancelTitle),
        content: Text(l10n.histCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.histCancel),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(publishQueueProvider.notifier).cancel(op.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();
    final progress = ref.watch(publishQueueProvider);
    final running = progress?.operationId == op.id ? progress : null;

    final (label, icon, color) = switch (op.status) {
      OperationStatus.queued => (
        l10n.histStatusQueued,
        Icons.schedule,
        studio.accent,
      ),
      OperationStatus.running => (
        l10n.histStatusRunning,
        Icons.sync,
        studio.accent,
      ),
      OperationStatus.success => (
        l10n.histStatusSuccess,
        Icons.check_circle,
        studio.success,
      ),
      OperationStatus.failed => (
        l10n.histStatusFailed,
        Icons.error,
        theme.colorScheme.error,
      ),
      OperationStatus.interrupted => (
        l10n.histStatusInterrupted,
        Icons.help_outline,
        studio.creative,
      ),
      OperationStatus.cancelled => (
        l10n.histStatusCancelled,
        Icons.cancel_outlined,
        theme.colorScheme.outline,
      ),
    };

    String entryLabel(EntryStatus s) => switch (s) {
      EntryStatus.pending => l10n.entryPending,
      EntryStatus.uploaded => l10n.entryUploaded,
      EntryStatus.done => l10n.entryDone,
      EntryStatus.skipped => l10n.entrySkipped,
      EntryStatus.failed => l10n.entryFailed,
      EntryStatus.cancelled => l10n.entryCancelled,
    };
    String strategyLabel(String s) => switch (s) {
      'gitLfs' => l10n.strategyLfs,
      'nativeGit' => l10n.strategyGit,
      _ => l10n.strategyApi,
    };

    final canCancel = op.isActive || op.isResumable;
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: color, semanticLabel: label),
        title: Text(op.commitMessage ?? op.kind),
        subtitle: Text(
          [
            dateFormat.format(op.createdAt),
            if (op.repository != null) '${op.repository} · ${op.branch}',
            l10n.histFiles(op.files.length),
            [
              label,
              if (op.attempts > 1) l10n.histAttempts(op.attempts),
            ].join(' · '),
          ].join('\n'),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (running != null) ...[
            Text(switch (running.step) {
              PublishStep.uploading => l10n.pubStepUploading(
                running.done,
                running.total,
              ),
              PublishStep.committing => l10n.pubStepCommitting,
              PublishStep.updatingBranch => l10n.pubStepUpdating,
              PublishStep.verifying => l10n.pubStepVerifying,
            }),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: running.step == PublishStep.uploading && running.total > 0
                  ? running.done / running.total
                  : null,
            ),
            const SizedBox(height: 8),
          ],
          if (op.entries.isEmpty)
            for (final f in op.files)
              Text('• ${f.remotePath}', style: theme.textTheme.bodySmall)
          else
            for (final e in op.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${e.remotePath} — ${entryLabel(e.status)} · '
                  '${strategyLabel(e.strategy)}'
                  '${e.sizeBytes == null ? '' : ' · ${formatBytes(e.sizeBytes!, locale: locale)}'}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          if (op.commitSha != null) ...[
            const SizedBox(height: 8),
            SelectableText(l10n.pubCommit(op.commitSha!)),
          ],
          if (op.status == OperationStatus.interrupted) ...[
            const SizedBox(height: 8),
            Text(l10n.histInterruptedHelp),
          ],
          if (op.error != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.histError} : ${op.error}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (op.isResumable) ...[
            const SizedBox(height: 8),
            Text(l10n.histResumeNote, style: theme.textTheme.bodySmall),
          ],
          Wrap(
            spacing: 8,
            children: [
              if (op.isResumable)
                FilledButton.tonalIcon(
                  onPressed: () => _resume(context, ref),
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.histResume),
                ),
              if (canCancel)
                TextButton.icon(
                  onPressed: () => _cancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.histCancel),
                ),
              if (op.htmlUrl != null)
                TextButton.icon(
                  onPressed: () => openUrl(context, op.htmlUrl!),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.commonOpenInBrowser),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
