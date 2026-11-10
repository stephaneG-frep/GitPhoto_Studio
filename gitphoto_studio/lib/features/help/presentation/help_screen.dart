import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../application/guided_tour.dart';
import '../application/help_content.dart';
import '../domain/help_topics.dart';
import 'help_markdown.dart';

/// Sommaire du mode d'emploi : parcours guidé, recherche, rubriques.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final library = ref.watch(helpLibraryProvider(lang));
    return ScreenFrame(
      title: l10n.navHelp,
      children: [
        PixelTip(message: l10n.helpIntro),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.helpSearchHint,
            border: const OutlineInputBorder(),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.commonClear,
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                    }),
                  ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        ...switch (library) {
          AsyncData(:final value) when _query.trim().length >= 2 => _results(
            context,
            searchHelp(value, _query),
          ),
          AsyncData(:final value) => [
            const _GuidedTour(),
            SectionTitle(l10n.helpTopics),
            Card(
              child: Column(
                children: [
                  for (final d in value)
                    ListTile(
                      leading: Icon(d.topic.icon),
                      title: Text(d.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/help/${d.topic.id}'),
                    ),
                ],
              ),
            ),
          ],
          AsyncError(:final error) => [Text(l10n.commonError('$error'))],
          _ => [const Center(child: CircularProgressIndicator())],
        },
      ],
    );
  }

  List<Widget> _results(BuildContext context, List<HelpSearchHit> hits) {
    final l10n = AppLocalizations.of(context);
    if (hits.isEmpty) return [Text(l10n.helpNoResults)];
    return [
      Card(
        child: Column(
          children: [
            for (final h in hits)
              ListTile(
                leading: Icon(h.document.topic.icon),
                title: Text(h.document.title),
                subtitle: Text(
                  h.snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.go('/help/${h.document.topic.id}'),
              ),
          ],
        ),
      ),
    ];
  }
}

class _GuidedTour extends ConsumerWidget {
  const _GuidedTour();

  static (String, String) texts(AppLocalizations l10n, TourStep s) =>
      switch (s) {
        TourStep.importMedia => (l10n.tourImportTitle, l10n.tourImportBody),
        TourStep.connectGithub => (l10n.tourGithubTitle, l10n.tourGithubBody),
        TourStep.chooseRepository => (l10n.tourRepoTitle, l10n.tourRepoBody),
        TourStep.optimize => (l10n.tourOptimizeTitle, l10n.tourOptimizeBody),
        TourStep.publish => (l10n.tourPublishTitle, l10n.tourPublishBody),
        TourStep.checkHistory => (l10n.tourHistoryTitle, l10n.tourHistoryBody),
        TourStep.configureAi => (l10n.tourAiTitle, l10n.tourAiBody),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final items = ref.watch(guidedTourProvider);
    final required = items.where((i) => !i.optional);
    final done = required.where((i) => i.done).length;
    // Première étape obligatoire restant à faire.
    final next = required.where((i) => !i.done).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: studio.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.tourTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(l10n.tourProgress(done, required.length)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.tourIntro, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: required.isEmpty ? 1 : done / required.length,
            ),
            const SizedBox(height: 8),
            for (final (i, item) in items.indexed)
              _TourTile(
                number: i + 1,
                item: item,
                texts: texts(l10n, item.step),
                highlighted: identical(item, next),
              ),
            if (next == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.tourDone,
                  style: TextStyle(color: studio.success),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TourTile extends StatelessWidget {
  const _TourTile({
    required this.number,
    required this.item,
    required this.texts,
    required this.highlighted,
  });

  final int number;
  final TourItem item;
  final (String, String) texts;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final (title, body) = texts;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: highlighted
            ? studio.accent.withValues(alpha: 0.10)
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: item.done ? studio.success : theme.colorScheme.outline,
            semanticLabel: item.done ? l10n.tourStepDone : l10n.tourStepTodo,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title${item.optional ? ' · ${l10n.tourOptional}' : ''}',
                  style: theme.textTheme.titleSmall,
                ),
                Text(body, style: theme.textTheme.bodySmall),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => context.go(item.destination.path),
                      child: Text(l10n.tourGo),
                    ),
                    TextButton(
                      onPressed: () => context.go('/help/${item.topic.id}'),
                      child: Text(l10n.tourRead),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une rubrique du mode d'emploi.
class HelpTopicScreen extends ConsumerWidget {
  const HelpTopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final topic = HelpTopic.byId(topicId);
    final lang = Localizations.localeOf(context).languageCode;
    final back = Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.go('/help'),
        icon: const Icon(Icons.arrow_back),
        label: Text(l10n.helpContents),
      ),
    );
    if (topic == null) {
      return ScreenFrame(
        title: l10n.navHelp,
        children: [back, Text(l10n.helpUnknownTopic)],
      );
    }
    final doc = ref.watch(helpDocumentProvider((topic, lang)));
    final index = HelpTopic.values.indexOf(topic);
    final next = index + 1 < HelpTopic.values.length
        ? HelpTopic.values[index + 1]
        : null;
    return ScreenFrame(
      title: doc.value?.title ?? l10n.navHelp,
      children: [
        back,
        const SizedBox(height: 8),
        switch (doc) {
          AsyncData(:final value) => HelpMarkdown(blocks: value.blocks),
          AsyncError(:final error) => Text(l10n.commonError('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
        if (next != null) ...[
          const Divider(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/help/${next.id}'),
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.helpNextTopic),
            ),
          ),
        ],
      ],
    );
  }
}
