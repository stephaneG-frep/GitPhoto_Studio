import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/destinations.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_tools.dart';
import 'package:gitphoto_studio/features/ai_agent/application/ai_settings.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:flutter/material.dart';

import '../support/fake_ai.dart';
import '../support/fake_secret_store.dart';

import 'test_app.dart';

/// Contrôles d'accessibilité de Flutter sur chaque écran, en thème clair et
/// sombre, sur téléphone.
void main() {
  for (final theme in ['light', 'dark']) {
    for (final d in AppDestination.values) {
      testWidgets('[$theme] ${d.name} : contraste, cibles, libellés', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final db = AppDatabase.inMemory();
        PreferencesRepository(db).write(PreferenceKeys.themeMode, theme);
        await pumpStudio(tester, location: d.path, database: db);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  for (final d in AppDestination.values) {
    testWidgets('texte agrandi à 200 % : ${d.name} sans débordement', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpStudio(tester, location: d.path);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> checkAll(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  int addMedia(AppDatabase db, String name, MediaKind kind) =>
      MediaRepository(db).insert(
        NewMedia(
          fileName: name,
          storedPath: '/nulle-part/$name',
          sourcePath: '/nulle-part/$name',
          kind: kind,
          sizeBytes: 2048,
          sha256: name,
          importedAt: DateTime(2025),
          hasGps: true,
        ),
      );

  testWidgets('écrans remplis : galerie, paramètres IA, rubrique, plan', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = AppDatabase.inMemory();
    final a = addMedia(db, 'plage.jpg', MediaKind.image);
    addMedia(db, 'clip.mp4', MediaKind.video);
    PreferencesRepository(db)
      ..write(AiPreferenceKeys.enabled, 'true')
      ..write(AiPreferenceKeys.consent(AiProviderId.mistral), 'true');
    final store = FakeSecretStore()
      ..values[SecretKeys.aiProviderKey('mistral')] = 'cle';
    final provider = ScriptedProvider([
      calls(AgentToolNames.proposePlan, {
        'summary': 'Ranger la photo',
        'steps': [
          {
            'type': 'move_to_album',
            'media_ids': [a],
            'album': 'Été',
          },
        ],
      }),
    ]);
    Future<void> open(String location) => pumpStudio(
      tester,
      location: location,
      database: db,
      secretStore: store,
      extraOverrides: [
        aiProviderFactoryProvider.overrideWithValue((_, _, _) => provider),
      ],
    );

    await open('/gallery');
    await checkAll(tester);
    await open('/settings');
    await checkAll(tester);
    await open('/help/connexion-github');
    await checkAll(tester);
    await open('/agent');
    await tester.enterText(find.byType(TextField), 'Range');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.text('Plan proposé'), findsOneWidget);
    await checkAll(tester);
    handle.dispose();
  });
}
