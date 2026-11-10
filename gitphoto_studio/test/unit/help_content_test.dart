import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/destinations.dart';
import 'package:gitphoto_studio/core/logging/app_logger.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';
import 'package:gitphoto_studio/features/help/application/help_content.dart';
import 'package:gitphoto_studio/features/help/domain/help_topics.dart';
import 'package:gitphoto_studio/features/help/domain/markdown_lite.dart';
import 'package:gitphoto_studio/features/settings/application/diagnostics.dart';

List<MdBlock> load(HelpTopic t, String lang) =>
    parseMarkdown(File(t.assetPath(lang)).readAsStringSync());

Iterable<MdInline> inlinesOf(List<MdBlock> blocks) sync* {
  for (final b in blocks) {
    switch (b) {
      case MdHeading(:final text) ||
          MdParagraph(:final text) ||
          MdQuote(:final text):
        yield* text;
      case MdList(:final items):
        for (final i in items) {
          yield* i.text;
        }
      case MdCode():
        break;
    }
  }
}

void main() {
  group('Markdown du mode d’emploi', () {
    test('titres, paragraphes, listes, encadrés, code', () {
      final blocks = parseMarkdown('''
# Titre

Un paragraphe
sur deux lignes.

- un
- deux **gras**
  suite

1. premier
2. second

> Conseil `code`

```
sudo apt install ffmpeg
```
''');
      expect(blocks.map((b) => b.runtimeType), [
        MdHeading,
        MdParagraph,
        MdList,
        MdList,
        MdQuote,
        MdCode,
      ]);
      expect(
        plainText((blocks[1] as MdParagraph).text),
        'Un paragraphe sur deux lignes.',
      );
      final bullets = blocks[2] as MdList;
      expect(bullets.ordered, isFalse);
      expect(plainText(bullets.items[1].text), 'deux gras suite');
      expect(bullets.items[1].text.whereType<MdBold>().single.text, 'gras');
      expect((blocks[3] as MdList).ordered, isTrue);
      expect((blocks[5] as MdCode).code, 'sudo apt install ffmpeg');
      expect(titleOf(blocks), 'Titre');
    });

    test('sous-liste dans une liste numérotée : numéros conservés', () {
      final blocks = parseMarkdown('''
1. Ouvrir
2. Choisir :
   - Privé
   - Public
3. Créer
''');
      expect(blocks, hasLength(1));
      final list = blocks.single as MdList;
      expect(list.ordered, isTrue);
      expect(list.items.map((i) => (i.depth, i.number)), [
        (0, 1),
        (0, 2),
        (1, null),
        (1, null),
        (0, 3),
      ]);
    });

    test('liens : texte et cible', () {
      final i = parseInline(
        'Voir [la galerie](app:/gallery) et [LFS](help:git-lfs).',
      );
      final links = i.whereType<MdLink>().toList();
      expect(links.map((l) => l.target), ['app:/gallery', 'help:git-lfs']);
      expect(plainText(i), 'Voir la galerie et LFS.');
    });
  });

  group('contenu livré', () {
    final routes = {for (final d in AppDestination.values) d.path, '/help'};

    for (final lang in helpLanguages) {
      test(
        '[$lang] chaque rubrique existe, a un titre et des liens valides',
        () {
          for (final t in HelpTopic.values) {
            final file = File(t.assetPath(lang));
            expect(file.existsSync(), isTrue, reason: file.path);
            final blocks = load(t, lang);
            expect(blocks.first, isA<MdHeading>(), reason: '${t.id} : titre');
            expect((blocks.first as MdHeading).level, 1);
            for (final link in inlinesOf(blocks).whereType<MdLink>()) {
              final target = link.target;
              if (target.startsWith('help:')) {
                expect(
                  HelpTopic.byId(target.substring(5)),
                  isNotNull,
                  reason: '${t.id} → $target',
                );
              } else if (target.startsWith('app:')) {
                expect(
                  routes,
                  contains(target.substring(4)),
                  reason: '${t.id} → $target',
                );
              } else {
                expect(
                  target,
                  startsWith('https://'),
                  reason: '${t.id} → $target',
                );
              }
            }
            // Jamais de secret d'exemple réaliste dans l'aide.
            final raw = file.readAsStringSync();
            expect(
              raw,
              isNot(matches(RegExp(r'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_'))),
            );
          }
        },
      );
    }

    test(
      'français et anglais ont la même structure (sections de niveau 2)',
      () {
        for (final t in HelpTopic.values) {
          int h2(String lang) => load(
            t,
            lang,
          ).whereType<MdHeading>().where((h) => h.level == 2).length;
          expect(h2('en'), h2('fr'), reason: t.id);
        }
      },
    );

    test('rubriques exigées par le cahier des charges', () {
      // Premiers pas, connexion, dépôt, photo, vidéo, commits, branches,
      // LFS, agent IA, erreurs, FAQ, glossaire (+ fournisseurs IA).
      expect(HelpTopic.values.length, greaterThanOrEqualTo(13));
      for (final d in AppDestination.values) {
        if (d != AppDestination.help) {
          expect(contextualTopic(d), isNotNull, reason: d.name);
        }
      }
    });

    test(
      'recherche : sans accents ni casse, tous les mots, titre prioritaire',
      () {
        final docs = [
          for (final t in HelpTopic.values) HelpDocument(t, load(t, 'fr')),
        ];
        final lfs = searchHelp(docs, 'lfs');
        expect(lfs.first.document.topic, HelpTopic.gitLfs);
        final jeton = searchHelp(docs, 'JETON fine-grained');
        expect(jeton.first.document.topic, HelpTopic.githubLogin);
        expect(
          searchHelp(docs, 'depot prive').map((h) => h.document.topic),
          contains(HelpTopic.createRepo),
        );
        expect(searchHelp(docs, 'zzzintrouvable'), isEmpty);
        expect(searchHelp(docs, 'a'), isEmpty);
      },
    );
  });

  group('diagnostic', () {
    test('export : seules les préférences non sensibles', () {
      final json = exportSettings({
        'ui.theme_mode': 'dark',
        'publish.lfs_enabled': 'true',
        'ai.mistral.model': 'mistral-small-latest',
        'github.client_id': 'Iv1.abcdef',
        'ai.mistral.key': 'ne-doit-jamais-sortir',
        'autre.token': 'x',
      }, appVersion: '0.1.0+1');
      expect(json, contains('"ui.theme_mode": "dark"'));
      expect(json, contains('ai.mistral.model'));
      expect(json, isNot(contains('client_id')));
      expect(json, isNot(contains('ne-doit-jamais-sortir')));
      expect(json, isNot(contains('autre.token')));
    });

    test('rapport : compteurs et états, sans contenu du journal', () {
      final report = buildDiagnosticReport(
        DiagnosticInput(
          appVersion: '0.1.0+1',
          platform: 'linux',
          osVersion: 'Ubuntu',
          locale: 'fr',
          schemaVersion: 5,
          mediaCount: 3,
          libraryBytes: 1234,
          operationsByStatus: {'success': 2, 'failed': 1},
          queuedEntries: 0,
          tools: const ToolAvailability(
            supportsExternalTools: true,
            gitVersion: 'git version 2.34.1',
          ),
          githubConnected: true,
          secretStoreAvailable: true,
          aiEnabled: true,
          aiProvider: 'Mistral AI',
          aiModel: 'mistral-small-latest',
          aiHasKey: true,
          aiConsent: true,
          log: [
            LogEntry(
              DateTime(2026),
              LogLevel.warning,
              'Publication alice/vacances@main : photo-de-moi.jpg',
            ),
          ],
        ),
      );
      expect(report, contains('schéma v5'));
      expect(report, contains('success 2, failed 1'));
      expect(report, contains('git version 2.34.1'));
      expect(report, contains('Git LFS (outil) : non détecté'));
      expect(report, contains('Clé IA enregistrée : oui'));
      expect(report, contains('warning 1'));
      // Noms de compte, de dépôt et de fichier absents.
      expect(report, isNot(contains('alice')));
      expect(report, isNot(contains('photo-de-moi')));
    });
  });

  test('guides de docs/ à jour avec le mode d’emploi intégré', () {
    final script = File('scripts/generate_guides.py').readAsStringSync();
    // Même ordre que le sommaire de l'application.
    final order = RegExp(r'"([a-z-]+)"')
        .allMatches(
          script.substring(script.indexOf('ORDER'), script.indexOf(']')),
        )
        .map((m) => m[1])
        .toList();
    expect(order, [for (final t in HelpTopic.values) t.id]);
    final r = Process.runSync('python3', [
      'scripts/generate_guides.py',
      '--check',
    ]);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
  });
}
