import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/app.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_tools.dart';
import 'package:gitphoto_studio/features/ai_agent/application/ai_settings.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';
import 'package:gitphoto_studio/features/gallery/application/gallery_providers.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/github/application/github_session.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../test/support/fake_ai.dart';
import '../test/support/fake_secret_store.dart';

/// Écran de l'agent sur appareil réel (affichage, saisie, plan, dialogue de
/// confirmation, exécution). Le FOURNISSEUR EST SIMULÉ : ce test ne prouve
/// rien sur Mistral. Base et bibliothèque temporaires : les données de
/// l'utilisateur ne sont jamais touchées.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('conversation, plan confirmé et exécuté', (tester) async {
    final dir = Directory.systemTemp.createTempSync('gitphoto_agent_it_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final db = AppDatabase.open(p.join(dir.path, 'app.db'));
    addTearDown(db.close);
    final prefs = PreferencesRepository(db)
      ..write(AiPreferenceKeys.enabled, 'true')
      ..write(AiPreferenceKeys.consent(AiProviderId.mistral), 'true');
    expect(prefs.read(AiPreferenceKeys.enabled), 'true');
    final store = FakeSecretStore()
      ..values[SecretKeys.aiProviderKey('mistral')] = 'cle-simulee';
    final ids = [
      for (final n in ['a.jpg', 'b.jpg'])
        MediaRepository(db).insert(
          NewMedia(
            fileName: n,
            storedPath: p.join(dir.path, n),
            sourcePath: p.join(dir.path, n),
            kind: MediaKind.image,
            sizeBytes: 10,
            sha256: n,
            importedAt: DateTime(2025),
          ),
        ),
    ];
    final provider = ScriptedProvider([
      calls(AgentToolNames.searchMedia, {'type': 'image'}),
      calls(AgentToolNames.proposePlan, {
        'summary': 'Ranger les deux photos dans « Voyage »',
        'steps': [
          {'type': 'move_to_album', 'media_ids': ids, 'album': 'Voyage'},
        ],
      }, id: 'c2'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          libraryPathsProvider.overrideWithValue(
            LibraryPaths(root: dir.path, temporaryDir: null)..ensureCreated(),
          ),
          secretStoreProvider.overrideWithValue(store),
          aiProviderFactoryProvider.overrideWithValue((_, _, _) => provider),
        ],
        child: const GitPhotoStudioApp(initialLocation: '/agent'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exemples de demandes'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Range mes photos');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('Plan proposé'), findsOneWidget);
    await tester.ensureVisible(find.text('Exécuter le plan'));
    await tester.tap(find.text('Exécuter le plan'));
    await tester.pumpAndSettle();
    expect(find.text('Exécuter ce plan ?'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Exécuter le plan').last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan exécuté et vérifié.'), findsOneWidget);
    final album = MediaRepository(db).findById(ids.first)!.albumId;
    expect(album, isNotNull);
    expect(MediaRepository(db).findById(ids.last)!.albumId, album);
    expect(tester.takeException(), isNull);
  });
}
