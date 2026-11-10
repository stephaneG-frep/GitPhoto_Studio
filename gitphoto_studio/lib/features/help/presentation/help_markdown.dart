import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/open_url.dart';
import '../domain/markdown_lite.dart';

/// Affiche une rubrique du mode d'emploi. Les liens `app:/…` ouvrent un écran
/// de l'application, `help:…` une autre rubrique, `https://…` le navigateur.
class HelpMarkdown extends StatefulWidget {
  const HelpMarkdown({super.key, required this.blocks});

  final List<MdBlock> blocks;

  @override
  State<HelpMarkdown> createState() => _HelpMarkdownState();
}

class _HelpMarkdownState extends State<HelpMarkdown> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _open(String target) {
    if (target.startsWith('app:')) {
      context.go(target.substring(4));
    } else if (target.startsWith('help:')) {
      context.go('/help/${target.substring(5)}');
    } else if (target.startsWith('https://')) {
      openUrl(context, target);
    }
  }

  TextSpan _spans(List<MdInline> inlines, TextStyle? base) {
    final theme = Theme.of(context);
    final link = TextStyle(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return TextSpan(
      style: base,
      children: [
        for (final i in inlines)
          switch (i) {
            MdText() => TextSpan(text: i.text),
            MdBold() => TextSpan(
              text: i.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            MdCodeSpan() => TextSpan(
              text: i.text,
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            MdLink(:final target) => TextSpan(
              text: i.text,
              style: link,
              recognizer: (TapGestureRecognizer()..onTap = () => _open(target))
                ..also(_recognizers.add),
            ),
          },
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final children = <Widget>[];
    for (final b in widget.blocks) {
      switch (b) {
        case MdHeading(:final level, text: final t):
          children.add(
            Padding(
              padding: EdgeInsets.only(top: level == 1 ? 0 : 20, bottom: 8),
              child: Semantics(
                header: true,
                child: Text.rich(
                  _spans(t, switch (level) {
                    1 => text.headlineSmall,
                    2 => text.titleLarge,
                    _ => text.titleMedium,
                  }),
                ),
              ),
            ),
          );
        case MdParagraph(text: final t):
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text.rich(_spans(t, text.bodyLarge)),
            ),
          );
        case MdList(:final items):
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in items)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: 4,
                        left: item.depth * 28.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              item.number == null ? '•' : '${item.number}.',
                              style: text.bodyLarge,
                            ),
                          ),
                          Expanded(
                            child: Text.rich(_spans(item.text, text.bodyLarge)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        case MdQuote(text: final t):
          children.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StudioColors.of(context).accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: StudioColors.of(context).accent,
                    width: 4,
                  ),
                ),
              ),
              child: Text.rich(_spans(t, text.bodyMedium)),
            ),
          );
        case MdCode(:final code):
          children.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

extension<T> on T {
  T also(void Function(T) f) {
    f(this);
    return this;
  }
}
