import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/app.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';
import 'package:gitphoto_studio/features/gallery/application/gallery_providers.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/github/application/github_session.dart';

import '../support/fake_github_server.dart';
import '../support/fake_secret_store.dart';
import 'package:gitphoto_studio/shared/widgets/screen_frame.dart';

const phoneSize = Size(400, 860);
const desktopSize = Size(1280, 860);

/// Lance l'application complète avec une base en mémoire et une détection
/// d'outils simulée (aucun processus externe dans les tests de widgets).
Future<AppDatabase> pumpStudio(
  WidgetTester tester, {
  Size size = phoneSize,
  String location = '/',
  AppDatabase? database,
  Override? toolsOverride,
  List<Override> extraOverrides = const [],
  LibraryPaths? libraryPaths,
  FakeSecretStore? secretStore,
  FakeGithubServer? github,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = database ?? AppDatabase.inMemory();
  addTearDown(db.close);
  final paths = libraryPaths ?? createTestLibraryPaths();

  await tester.pumpWidget(
    ProviderScope(
      // Clé unique : chaque appel démarre une application neuve.
      key: UniqueKey(),
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        libraryPathsProvider.overrideWithValue(paths),
        // Jamais de vrai trousseau ni de vrai réseau dans les tests d'écran.
        secretStoreProvider.overrideWithValue(secretStore ?? FakeSecretStore()),
        githubApiFactoryProvider.overrideWithValue(
          (github ?? FakeGithubServer()).api,
        ),
        ...extraOverrides,
        toolsOverride ??
            toolAvailabilityProvider.overrideWith(
              (ref) async => const ToolAvailability(
                supportsExternalTools: true,
                gitVersion: 'git version 2.34.1',
              ),
            ),
      ],
      child: GitPhotoStudioApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Zone défilante du contenu de l'écran (hors menu latéral).
Finder contentScrollable() => find
    .descendant(of: find.byType(ScreenFrame), matching: find.byType(Scrollable))
    .first;

/// Bibliothèque dans un dossier temporaire, supprimé après le test.
LibraryPaths createTestLibraryPaths() {
  final root = Directory.systemTemp.createTempSync('gitphoto_lib_');
  addTearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });
  return LibraryPaths(root: root.path, temporaryDir: '${root.path}/cache')
    ..ensureCreated();
}
