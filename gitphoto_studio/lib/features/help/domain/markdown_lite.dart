/// Sous-ensemble de Markdown utilisé par le mode d'emploi intégré :
/// titres (`#`, `##`, `###`), paragraphes, listes à puces (`- `), listes
/// numérotées (`1. `), encadrés (`> `), blocs de code (```), et en ligne :
/// **gras**, `code` et liens `[texte](cible)`.
///
/// Volontairement minimal : les textes sont écrits par l'équipe et livrés
/// avec l'application, jamais téléchargés.
library;

sealed class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  const MdHeading(this.level, this.text);

  final int level;
  final List<MdInline> text;
}

class MdParagraph extends MdBlock {
  const MdParagraph(this.text);

  final List<MdInline> text;
}

class MdList extends MdBlock {
  const MdList(this.items, {required this.ordered});

  final List<MdItem> items;

  /// Liste numérotée au premier niveau.
  final bool ordered;
}

/// Élément de liste : `depth` 0 (premier niveau) ou 1 (sous-liste
/// indentée) ; `number` conservé tel qu'écrit pour une liste numérotée.
class MdItem {
  const MdItem(this.text, {this.depth = 0, this.number});

  final List<MdInline> text;
  final int depth;
  final int? number;
}

/// Encadré (conseil, avertissement).
class MdQuote extends MdBlock {
  const MdQuote(this.text);

  final List<MdInline> text;
}

class MdCode extends MdBlock {
  const MdCode(this.code);

  final String code;
}

sealed class MdInline {
  const MdInline(this.text);

  final String text;
}

class MdText extends MdInline {
  const MdText(super.text);
}

class MdBold extends MdInline {
  const MdBold(super.text);
}

class MdCodeSpan extends MdInline {
  const MdCodeSpan(super.text);
}

class MdLink extends MdInline {
  const MdLink(super.text, this.target);

  /// `https://…`, `app:/chemin` (écran de l'application) ou
  /// `help:rubrique` (autre rubrique du mode d'emploi).
  final String target;
}

final _inline = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|\[([^\]]+)\]\(([^)\s]+)\)');

List<MdInline> parseInline(String s) {
  final out = <MdInline>[];
  var pos = 0;
  for (final m in _inline.allMatches(s)) {
    if (m.start > pos) out.add(MdText(s.substring(pos, m.start)));
    if (m[1] != null) {
      out.add(MdBold(m[1]!));
    } else if (m[2] != null) {
      out.add(MdCodeSpan(m[2]!));
    } else {
      out.add(MdLink(m[3]!, m[4]!));
    }
    pos = m.end;
  }
  if (pos < s.length) out.add(MdText(s.substring(pos)));
  return out;
}

final _ordered = RegExp(r'^(\d+)\.\s+');

List<MdBlock> parseMarkdown(String source) {
  final blocks = <MdBlock>[];
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final para = <String>[];
  final quote = <String>[];
  List<MdItem>? items;
  var ordered = false;

  void flush() {
    if (para.isNotEmpty) {
      blocks.add(MdParagraph(parseInline(para.join(' '))));
      para.clear();
    }
    if (quote.isNotEmpty) {
      blocks.add(MdQuote(parseInline(quote.join(' '))));
      quote.clear();
    }
    if (items != null) {
      blocks.add(MdList(items!, ordered: ordered));
      items = null;
    }
  }

  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final line = raw.trim();
    if (line.startsWith('```')) {
      flush();
      final code = <String>[];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        code.add(lines[i]);
        i++;
      }
      blocks.add(MdCode(code.join('\n')));
      continue;
    }
    if (line.isEmpty) {
      flush();
      continue;
    }
    final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      flush();
      blocks.add(MdHeading(heading[1]!.length, parseInline(heading[2]!)));
      continue;
    }
    if (line.startsWith('> ') || line == '>') {
      if (para.isNotEmpty || items != null) flush();
      quote.add(line.substring(1).trim());
      continue;
    }
    final isBullet = line.startsWith('- ') || line.startsWith('* ');
    final number = _ordered.firstMatch(line);
    if (isBullet || number != null) {
      final indented = raw.startsWith('  ') && items != null;
      if (para.isNotEmpty || quote.isNotEmpty) flush();
      if (!indented && items != null && ordered != (number != null)) flush();
      if (items == null) {
        items = [];
        ordered = number != null;
      }
      items!.add(
        MdItem(
          parseInline(
            isBullet
                ? line.substring(2).trim()
                : line.replaceFirst(_ordered, ''),
          ),
          depth: indented ? 1 : 0,
          number: number == null ? null : int.parse(number[1]!),
        ),
      );
      continue;
    }
    // Ligne indentée qui prolonge l'élément de liste précédent.
    if (items != null && raw.startsWith('  ')) {
      final last = items!.removeLast();
      items!.add(
        MdItem(
          [...last.text, const MdText(' '), ...parseInline(line)],
          depth: last.depth,
          number: last.number,
        ),
      );
      continue;
    }
    if (quote.isNotEmpty) {
      quote.add(line);
      continue;
    }
    if (items != null) flush();
    para.add(line);
  }
  flush();
  return blocks;
}

/// Texte brut d'une liste d'éléments en ligne (recherche, accessibilité).
String plainText(List<MdInline> inlines) => inlines.map((i) => i.text).join();

/// Titre d'une rubrique : premier titre de niveau 1.
String? titleOf(List<MdBlock> blocks) {
  for (final b in blocks) {
    if (b is MdHeading && b.level == 1) return plainText(b.text);
  }
  return null;
}
