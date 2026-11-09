import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/destinations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../application/agent_controller.dart';
import '../application/agent_tools.dart';
import '../application/ai_settings.dart';
import 'agent_error_text.dart';
import 'plan_card.dart';

String toolLabel(AppLocalizations l10n, String tool) => switch (tool) {
  AgentToolNames.getSelection => l10n.toolGetSelection,
  AgentToolNames.searchMedia => l10n.toolSearchMedia,
  AgentToolNames.listAlbums => l10n.toolListAlbums,
  AgentToolNames.findSimilar => l10n.toolFindSimilar,
  AgentToolNames.githubStatus => l10n.toolGithubStatus,
  AgentToolNames.recentOperations => l10n.toolRecentOperations,
  AgentToolNames.previewPublication => l10n.toolPreviewPublication,
  _ => tool,
};

class AgentScreen extends ConsumerWidget {
  const AgentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(aiSettingsProvider);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: switch (settings) {
            AsyncData(:final value) when !value.enabled => _Gate(
              title: l10n.agentDisabledTitle,
              body: l10n.agentDisabledBody,
            ),
            AsyncData(:final value) when value.needsKey => _Gate(
              title: value.descriptor.displayName,
              body: l10n.agentNeedsKey(value.descriptor.displayName),
            ),
            AsyncData(:final value) when !value.isConfigured => _Gate(
              title: value.descriptor.displayName,
              body: l10n.agentNeedsModel,
            ),
            AsyncData(:final value) when !value.consent => _Consent(
              providerName: value.descriptor.displayName,
            ),
            AsyncData() => const _Conversation(),
            AsyncError(:final error) => _Gate(
              title: l10n.navAgent,
              body: describeAgentError(context, error),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

/// Écran d'attente : IA désactivée ou incomplètement configurée.
class _Gate extends StatelessWidget {
  const _Gate({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: PixelMascot(size: 72)),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(body, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: () => context.go(AppDestination.settings.path),
            icon: const Icon(Icons.settings),
            label: Text(l10n.agentOpenSettings),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.agentSafetyNote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Accord explicite avant tout envoi à un fournisseur.
class _Consent extends ConsumerWidget {
  const _Consent({required this.providerName});

  final String providerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined),
                    const SizedBox(width: 8),
                    Text(
                      l10n.agentConsentTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.agentConsentBody(providerName)),
                const SizedBox(height: 12),
                Text(
                  l10n.agentSafetyNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => ref
                          .read(aiSettingsProvider.notifier)
                          .setConsent(true),
                      child: Text(l10n.agentConsentAccept),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppDestination.settings.path),
                      child: Text(l10n.agentOpenSettings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Conversation extends ConsumerStatefulWidget {
  const _Conversation();

  @override
  ConsumerState<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends ConsumerState<_Conversation> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    _input.clear();
    ref.read(agentControllerProvider.notifier).send(t);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(agentControllerProvider);
    ref.listen(
      agentControllerProvider.select((s) => s.entries.length),
      (_, _) => _scrollToEnd(),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.agentSafetyNote,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                tooltip: l10n.agentNewConversation,
                onPressed: state.busy || state.entries.isEmpty
                    ? null
                    : () => ref
                          .read(agentControllerProvider.notifier)
                          .newConversation(),
                icon: const Icon(Icons.add_comment_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.entries.isEmpty
              ? _Examples(onPick: _send)
              : ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final e in state.entries) _EntryView(entry: e),
                  ],
                ),
        ),
        if (state.thinking)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.lastTool == null
                        ? l10n.agentThinking
                        : l10n.agentConsulting(
                            toolLabel(l10n, state.lastTool!),
                          ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(agentControllerProvider.notifier).cancel(),
                  child: Text(l10n.agentStop),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 4000,
                  enabled: !state.busy,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: l10n.agentInputHint,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: l10n.agentSend,
                onPressed: state.busy ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Examples extends StatelessWidget {
  const _Examples({required this.onPick});

  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PixelTip(message: l10n.agentIntro),
        const SizedBox(height: 16),
        Text(
          l10n.agentExamplesTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ex in l10n.agentExamples.split('\n'))
              ActionChip(label: Text(ex), onPressed: () => onPick(ex)),
          ],
        ),
      ],
    );
  }
}

class _EntryView extends StatelessWidget {
  const _EntryView({required this.entry});

  final ChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    Widget bubble(Widget child, {required bool mine, Color? color}) => Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                color ??
                (mine
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ),
    );

    return switch (entry) {
      UserEntry(:final text) => bubble(SelectableText(text), mine: true),
      AssistantEntry(:final text, :final toolsUsed) => bubble(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text),
            if (toolsUsed.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l10n.agentToolsUsed(
                  toolsUsed.map((t) => toolLabel(l10n, t)).toSet().join(', '),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: studio.accent,
                ),
              ),
            ],
          ],
        ),
        mine: false,
      ),
      final PlanEntry p => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: PlanCard(entry: p),
      ),
      ArchivedPlanEntry(:final summary) => bubble(
        Text(l10n.planArchived(summary), style: theme.textTheme.bodySmall),
        mine: false,
      ),
      ErrorEntry(:final error) => bubble(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(describeAgentError(context, error))),
          ],
        ),
        mine: false,
        color: theme.colorScheme.errorContainer,
      ),
    };
  }
}
