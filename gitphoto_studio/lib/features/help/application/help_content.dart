import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/help_topics.dart';
import '../domain/markdown_lite.dart';

class HelpDocument {
  HelpDocument(this.topic, this.blocks)
    : title = titleOf(blocks) ?? topic.id,
      plain = _plain(blocks);

  final HelpTopic topic;
  final List<MdBlock> blocks;
  final String title;

  /// Texte brut pour la recherche.
  final String plain;

  static String _plain(List<MdBlock> blocks) => blocks
      .map(
        (b) => switch (b) {
          MdHeading(:final text) ||
          MdParagraph(:final text) ||
          MdQuote(:final text) => plainText(text),
          MdList(:final items) =>
            items.map((i) => plainText(i.text)).join('\n'),
          MdCode(:final code) => code,
        },
      )
      .join('\n');
}

/// Source des textes (remplaçable dans les tests).
final helpBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

/// Rubrique dans la langue demandée ; repli sur le français si elle manque.
final helpDocumentProvider =
    FutureProvider.family<HelpDocument, (HelpTopic, String)>((ref, key) async {
      final (topic, lang) = key;
      final bundle = ref.watch(helpBundleProvider);
      final language = helpLanguages.contains(lang) ? lang : 'fr';
      String source;
      try {
        // Pas de cache du paquet : le fournisseur garde déjà la rubrique.
        source = await bundle.loadString(
          topic.assetPath(language),
          cache: false,
        );
      } on Object {
        source = await bundle.loadString(topic.assetPath('fr'), cache: false);
      }
      return HelpDocument(topic, parseMarkdown(source));
    }, retry: (_, _) => null);

/// Toutes les rubriques d'une langue, dans l'ordre du sommaire.
final helpLibraryProvider = FutureProvider.family<List<HelpDocument>, String>((
  ref,
  lang,
) async {
  return [
    for (final t in HelpTopic.values)
      await ref.watch(helpDocumentProvider((t, lang)).future),
  ];
}, retry: (_, _) => null);

class HelpSearchHit {
  const HelpSearchHit(this.document, this.snippet);

  final HelpDocument document;
  final String snippet;
}

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a', //
  'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', //
  'œ': 'oe', 'æ': 'ae', '’': "'",
};

String _fold(String s) =>
    s.toLowerCase().split('').map((c) => _accents[c] ?? c).join();

/// Recherche insensible à la casse et aux accents ; tous les mots doivent
/// apparaître dans la rubrique. Le titre compte plus que le texte.
List<HelpSearchHit> searchHelp(List<HelpDocument> docs, String query) {
  final words = _fold(
    query,
  ).split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
  if (words.isEmpty) return const [];
  final scored = <(int, HelpSearchHit)>[];
  for (final d in docs) {
    final title = _fold(d.title);
    final body = _fold(d.plain);
    if (!words.every((w) => title.contains(w) || body.contains(w))) continue;
    final score =
        words.where(title.contains).length * 10 +
        words
            .map((w) => w.allMatches(body).length)
            .fold<int>(0, (a, b) => a + b);
    // Extrait autour de la première occurrence.
    final lines = d.plain.split('\n');
    final line = lines.firstWhere(
      (l) => _fold(l).contains(words.first),
      orElse: () => lines.length > 1 ? lines[1] : '',
    );
    final snippet = line.length > 160 ? '${line.substring(0, 157)}…' : line;
    scored.add((score, HelpSearchHit(d, snippet)));
  }
  scored.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final s in scored) s.$2];
}
