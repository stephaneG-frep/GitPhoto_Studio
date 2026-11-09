import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/app.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/migrations.dart';
import 'package:gitphoto_studio/features/gallery/application/gallery_providers.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/shared/widgets/screen_frame.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

/// Test d'intégration sur plateforme réelle (Linux ou Android) :
/// base SQLite sur disque, détection réelle des outils, réouverture.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('démarrage, préférence persistée et réouverture', (tester) async {
    final dir = Directory.systemTemp.createTempSync('gitphoto_it_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final dbPath = p.join(dir.path, 'app.db');

    Future<AppDatabase> launch() async {
      final db = AppDatabase.open(dbPath);
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            libraryPathsProvider.overrideWithValue(
              LibraryPaths(root: dir.path, temporaryDir: null),
            ),
          ],
          child: const GitPhotoStudioApp(initialLocation: '/settings'),
        ),
      );
      await tester.pumpAndSettle();
      return db;
    }

    // Premier lancement : choix du thème sombre.
    final first = await launch();
    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    first.close();

    // Réouverture : le thème est restauré depuis le fichier SQLite.
    final second = await launch();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    await tester.scrollUntilVisible(
      find.text('Schéma v$latestSchemaVersion'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ScreenFrame),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Schéma v$latestSchemaVersion'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    second.close();
  });
}
