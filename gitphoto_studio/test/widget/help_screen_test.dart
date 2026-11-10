import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/destinations.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/help/presentation/help_markdown.dart';

import '../support/fake_secret_store.dart';
import 'test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());

  Future<void> open(
    WidgetTester tester,
    String location, {
    Size size = desktopSize,
    FakeSecretStore? store,
  }) => pumpStudio(
    tester,
    size: size,
    location: location,
    database: db,
    secretStore: store,
  );

  testWidgets('sommaire : parcours guidé reflétant l’état réel, rubriques', (
    tester,
  ) async {
    await open(tester, AppDestination.help.path);
    expect(find.text('Parcours guidé'), findsOneWidget);
    expect(find.text('0 sur 5'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    // Un média importé : l'étape 1 se coche toute seule.
    MediaRepository(db).insert(
      NewMedia(
        fileName: 'a.jpg',
        storedPath: '/x/a.jpg',
        sourcePath: '/x/a.jpg',
        kind: MediaKind.image,
        sizeBytes: 1,
        sha256: 'a',
        importedAt: DateTime(2025),
      ),
    );
    await open(tester, AppDestination.help.path);
    expect(find.text('1 sur 5'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Glossaire'),
      300,
      scrollable: contentScrollable(),
    );
    expect(find.text('Rubriques'), findsOneWidget);
  });

  testWidgets('recherche puis ouverture d’une rubrique et lien interne', (
    tester,
  ) async {
    await open(tester, AppDestination.help.path);
    await tester.enterText(find.byType(TextField), 'fine-grained');
    await tester.pumpAndSettle();
    expect(find.text('Parcours guidé'), findsNothing);
    await tester.tap(find.text('Connexion à GitHub').first);
    await tester.pumpAndSettle();

    expect(find.byType(HelpMarkdown), findsOneWidget);
    expect(
      find.textContaining('Only select repositories', findRichText: true),
      findsWidgets,
    );

    // Lien « Comprendre les erreurs » en fin de rubrique.
    final link = find.textContaining(
      'Comprendre les erreurs',
      findRichText: true,
    );
    await tester.scrollUntilVisible(link, 300, scrollable: contentScrollable());
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tapOnText(
      find.textRange.ofSubstring('Comprendre les erreurs'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('GitHub refuse le jeton', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('Limite de requêtes GitHub', findRichText: true),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Sommaire'),
      -300,
      scrollable: contentScrollable(),
    );
    await tester.tap(find.text('Sommaire'));
    await tester.pumpAndSettle();
    expect(find.text('Parcours guidé'), findsOneWidget);
  });

  testWidgets('recherche sans résultat : message clair', (tester) async {
    await open(tester, AppDestination.help.path);
    await tester.enterText(find.byType(TextField), 'zzzintrouvable');
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune rubrique ne correspond à cette recherche.'),
      findsOneWidget,
    );
  });

  testWidgets('aide contextuelle : bouton « ? » de chaque écran', (
    tester,
  ) async {
    await open(tester, AppDestination.publish.path, size: phoneSize);
    await tester.tap(find.byTooltip('Aide sur cet écran'));
    await tester.pumpAndSettle();
    expect(find.text('Publier une photo'), findsWidgets);

    await open(tester, AppDestination.agent.path);
    await tester.tap(find.byTooltip('Aide sur cet écran'));
    await tester.pumpAndSettle();
    expect(find.text("Utiliser l'agent IA"), findsWidgets);

    await open(tester, AppDestination.help.path);
    expect(find.byTooltip('Aide sur cet écran'), findsNothing);
  });

  testWidgets('rubrique inconnue : message, pas de plantage', (tester) async {
    await open(tester, '/help/nexiste-pas');
    expect(find.text('Rubrique introuvable.'), findsOneWidget);
  });

  testWidgets('en anglais : rubriques anglaises', (tester) async {
    PreferencesRepository(db).write('ui.locale', 'en');
    await open(tester, '/help/git-lfs');
    expect(find.text('Git LFS (large files)'), findsWidgets);
  });

  testWidgets(
    'diagnostic : rapport copié sans secret, export sans clé, journal',
    (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      final store = FakeSecretStore()
        ..values[SecretKeys.aiProviderKey('mistral')] = 'cle-secrete-xyz';
      PreferencesRepository(db)
        ..write('ai.enabled', 'true')
        ..write('github.client_id', 'Iv1.monappli');
      await open(tester, AppDestination.settings.path, store: store);

      final copyReport = find.text('Copier le rapport');
      await tester.scrollUntilVisible(
        copyReport,
        300,
        scrollable: contentScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(copyReport);
      await tester.pumpAndSettle();
      expect(clipboard, contains('rapport de diagnostic'));
      expect(clipboard, contains('Clé IA enregistrée : oui'));
      expect(clipboard, isNot(contains('cle-secrete-xyz')));

      await tester.ensureVisible(find.text('Copier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copier'));
      await tester.pumpAndSettle();
      expect(clipboard, contains('"ai.enabled": "true"'));
      expect(clipboard, isNot(contains('client_id')));
      expect(clipboard, isNot(contains('cle-secrete-xyz')));

      await tester.tap(find.text('Journal technique'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Retour'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
