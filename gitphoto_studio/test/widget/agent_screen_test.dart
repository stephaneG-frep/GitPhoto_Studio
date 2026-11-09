import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/destinations.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_tools.dart';
import 'package:gitphoto_studio/features/ai_agent/application/ai_settings.dart';
import 'package:gitphoto_studio/features/ai_agent/data/conversation_repository.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';

import '../support/fake_ai.dart';
import '../support/fake_secret_store.dart';
import 'test_app.dart';

void main() {
  late AppDatabase db;
  late FakeSecretStore store;
  late ScriptedProvider provider;
  late List<String?> keysUsed;

  setUp(() {
    db = AppDatabase.inMemory();
    store = FakeSecretStore();
    keysUsed = [];
  });

  void configure({
    bool enabled = true,
    bool key = true,
    bool consent = true,
    bool save = false,
  }) {
    final prefs = PreferencesRepository(db);
    prefs.write(AiPreferenceKeys.enabled, '$enabled');
    prefs.write(AiPreferenceKeys.consent(AiProviderId.mistral), '$consent');
    prefs.write(AiPreferenceKeys.saveConversations, '$save');
    if (key) {
      store.values[SecretKeys.aiProviderKey('mistral')] = 'cle-mistral-test';
    }
  }

  int addMedia(String name) => MediaRepository(db).insert(
    NewMedia(
      fileName: name,
      storedPath: '/nulle-part/$name',
      sourcePath: '/nulle-part/$name',
      kind: MediaKind.image,
      sizeBytes: 10,
      sha256: name,
      importedAt: DateTime(2025),
    ),
  );

  Future<void> open(WidgetTester tester, {Size size = desktopSize}) =>
      pumpStudio(
        tester,
        size: size,
        location: AppDestination.agent.path,
        database: db,
        secretStore: store,
        extraOverrides: [
          aiProviderFactoryProvider.overrideWithValue((id, url, key) {
            keysUsed.add(key);
            return provider;
          }),
        ],
      );

  testWidgets('IA désactivée par défaut : explication, aucun envoi possible', (
    tester,
  ) async {
    provider = ScriptedProvider([]);
    await open(tester);
    expect(find.text("L'assistant IA est désactivé"), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text("Ouvrir les paramètres de l'IA"), findsOneWidget);
  });

  testWidgets('clé manquante : demandée avant tout dialogue', (tester) async {
    provider = ScriptedProvider([]);
    configure(key: false);
    await open(tester);
    expect(find.textContaining("clé d'API pour Mistral AI"), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('accord explicite exigé avant le premier envoi', (tester) async {
    provider = ScriptedProvider([says('Bonjour')]);
    configure(consent: false);
    await open(tester);
    expect(find.text('Avant de commencer'), findsOneWidget);
    expect(find.textContaining('Aucune image ni vidéo'), findsOneWidget);
    expect(provider.requests, isEmpty);
    await tester.tap(find.text("J'accepte"));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      PreferencesRepository(
        db,
      ).read(AiPreferenceKeys.consent(AiProviderId.mistral)),
      'true',
    );
  });

  testWidgets('question simple : réponse affichée, outils consultés signalés', (
    tester,
  ) async {
    addMedia('a.jpg');
    provider = ScriptedProvider([
      calls(AgentToolNames.searchMedia, {'type': 'image'}),
      says('Vous avez 1 photo.'),
    ]);
    configure();
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Combien de photos ?');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(find.text('Combien de photos ?'), findsOneWidget);
    expect(find.text('Vous avez 1 photo.'), findsOneWidget);
    expect(find.text('Informations consultées : bibliothèque'), findsOneWidget);
    // La clé lue dans le trousseau n'est transmise qu'à l'adaptateur.
    expect(keysUsed, ['cle-mistral-test']);
    expect(
      provider.requests.first.messages.map((m) => m.content).join(),
      isNot(contains('cle-mistral-test')),
    );
  });

  testWidgets('plan proposé : refus → rien n’est fait, le modèle est informé', (
    tester,
  ) async {
    final a = addMedia('a.jpg');
    provider = ScriptedProvider([
      calls(AgentToolNames.proposePlan, {
        'summary': 'Ranger la photo dans Été',
        'steps': [
          {
            'type': 'move_to_album',
            'media_ids': [a],
            'album': 'Été',
          },
        ],
      }),
      says('D’accord.'),
    ]);
    configure();
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Range-la');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(find.text('Plan proposé'), findsOneWidget);
    expect(find.text("Ranger 1 média dans l'album « Été »"), findsOneWidget);
    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();
    expect(find.text("Plan refusé : rien n'a été fait."), findsOneWidget);
    expect(MediaRepository(db).findById(a)!.albumId, isNull);

    await tester.enterText(find.byType(TextField), 'Merci');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    final last = provider.requests.last.messages.last.content;
    expect(last, contains('refusé le plan'));
    expect(last, endsWith('Merci'));
  });

  testWidgets(
    'plan confirmé : boîte de confirmation, exécution, résultat vérifié',
    (tester) async {
      final a = addMedia('a.jpg');
      final b = addMedia('b.jpg');
      provider = ScriptedProvider([
        calls(AgentToolNames.proposePlan, {
          'summary': 'Ranger deux photos',
          'steps': [
            {
              'type': 'move_to_album',
              'media_ids': [a, b],
              'album': 'Voyage',
            },
          ],
        }),
      ]);
      configure();
      await open(tester);
      await tester.enterText(find.byType(TextField), 'Range-les');
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exécuter le plan'));
      await tester.pumpAndSettle();
      // Confirmation explicite : annuler ne fait rien.
      expect(find.text('Exécuter ce plan ?'), findsOneWidget);
      await tester.tap(find.text('Retour'));
      await tester.pumpAndSettle();
      expect(MediaRepository(db).findById(a)!.albumId, isNull);

      await tester.tap(find.text('Exécuter le plan'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Exécuter le plan').last,
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan exécuté et vérifié.'), findsOneWidget);
      expect(find.text('2 éléments traités'), findsOneWidget);
      final albumId = MediaRepository(db).findById(a)!.albumId;
      expect(albumId, isNotNull);
      expect(MediaRepository(db).findById(b)!.albumId, albumId);
      // Le plan n'est plus confirmable.
      expect(find.text('Exécuter le plan'), findsNothing);
    },
  );

  testWidgets('nouvelle demande : l’ancien plan ne peut plus être exécuté', (
    tester,
  ) async {
    final a = addMedia('a.jpg');
    provider = ScriptedProvider([
      calls(AgentToolNames.proposePlan, {
        'summary': 'Plan 1',
        'steps': [
          {
            'type': 'move_to_album',
            'media_ids': [a],
            'album': 'A',
          },
        ],
      }),
      says('Autre chose ?'),
    ]);
    configure();
    await open(tester);
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'y');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Plan non confirmé, remplacé par votre nouvelle demande.'),
      findsOneWidget,
    );
    expect(find.text('Exécuter le plan'), findsNothing);
  });

  testWidgets('erreur du fournisseur : message compréhensible', (tester) async {
    provider = ScriptedProvider([
      (_) => throw const AiException(AiErrorKind.unauthorized, 'Unauthorized'),
    ]);
    configure();
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Bonjour');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Clé d'API refusée par le fournisseur. Vérifiez-la dans les paramètres.",
      ),
      findsOneWidget,
    );
    // Le champ reste utilisable.
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets(
    'conversations : non enregistrées par défaut, restaurées si autorisé',
    (tester) async {
      provider = ScriptedProvider([says('Réponse 1')]);
      configure();
      await open(tester);
      await tester.enterText(find.byType(TextField), 'Question 1');
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
      expect(ConversationRepository(db).count(), 0);

      provider = ScriptedProvider([says('Réponse 2')]);
      configure(save: true);
      await open(tester);
      await tester.enterText(find.byType(TextField), 'Question 2');
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
      expect(ConversationRepository(db).count(), 1);

      // Nouvelle ouverture de l'application : conversation restaurée.
      provider = ScriptedProvider([says('Réponse 3')]);
      await open(tester);
      expect(find.text('Question 2'), findsOneWidget);
      expect(find.text('Réponse 2'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Question 3');
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
      // L'historique restauré est transmis au modèle.
      final contents = provider.requests.single.messages.map((m) => m.content);
      expect(
        contents,
        containsAllInOrder(['Question 2', 'Réponse 2', 'Question 3']),
      );
    },
  );

  testWidgets('téléphone : saisie et exemples accessibles', (tester) async {
    provider = ScriptedProvider([says('ok')]);
    configure();
    await open(tester, size: phoneSize);
    expect(find.text('Exemples de demandes'), findsOneWidget);
    await tester.tap(find.byType(ActionChip).first);
    await tester.pumpAndSettle();
    expect(find.text('ok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'paramètres : clé dans le trousseau uniquement, test de connexion, suppression',
    (tester) async {
      provider = ScriptedProvider([]);
      PreferencesRepository(db).write(AiPreferenceKeys.enabled, 'true');
      await pumpStudio(
        tester,
        size: desktopSize,
        location: AppDestination.settings.path,
        database: db,
        secretStore: store,
        extraOverrides: [
          aiProviderFactoryProvider.overrideWithValue((id, url, key) {
            keysUsed.add(key);
            return provider;
          }),
        ],
      );
      final keyField = find.widgetWithText(TextField, 'Collez votre clé ici');
      await tester.scrollUntilVisible(
        keyField,
        200,
        scrollable: contentScrollable(),
      );
      await tester.enterText(keyField, '  ma-cle-secrete-123456  ');
      await tester.ensureVisible(find.text('Enregistrer la clé'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer la clé'));
      await tester.pumpAndSettle();

      expect(
        store.values[SecretKeys.aiProviderKey('mistral')],
        'ma-cle-secrete-123456',
      );
      expect(
        find.text('Clé enregistrée dans le trousseau du système'),
        findsOneWidget,
      );
      // Rien dans SQLite : ni préférences, ni ailleurs.
      for (final table in ['preferences', 'ai_messages', 'operations']) {
        final dump = db.raw.select('SELECT * FROM $table').toString();
        expect(dump, isNot(contains('ma-cle-secrete')), reason: table);
      }
      // Le champ est vidé et masqué.
      expect(tester.widget<TextField>(keyField).obscureText, isTrue);
      expect(tester.widget<TextField>(keyField).controller!.text, isEmpty);

      final test = find.text('Tester la connexion');
      await tester.ensureVisible(test);
      await tester.tap(test);
      await tester.pumpAndSettle();
      expect(find.text('Connexion réussie — 1 modèle'), findsOneWidget);
      expect(keysUsed, ['ma-cle-secrete-123456']);

      await tester.ensureVisible(find.text('Supprimer la clé'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer la clé'));
      await tester.pumpAndSettle();
      expect(store.values[SecretKeys.aiProviderKey('mistral')], isNull);
      expect(find.text('Aucune clé enregistrée'), findsOneWidget);
    },
  );
}
