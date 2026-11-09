import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/features/gallery/data/album_repository.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_query.dart';
import 'package:gitphoto_studio/features/gallery/presentation/media_tile.dart';

import '../support/media_fixtures.dart';
import 'test_app.dart';

Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 300 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

int addImage(
  AppDatabase db,
  LibraryPaths paths,
  String name, {
  String? phash,
  DateTime? takenAt,
  int width = 1600,
  int height = 1000,
}) {
  final f = writeFile(
    Directory(paths.mediaDir),
    '$name.jpg',
    makeJpeg(width: width, height: height, seed: name.hashCode),
  );
  return MediaRepository(db).insert(
    NewMedia(
      fileName: name,
      storedPath: f.path,
      sourcePath: '/src/$name',
      kind: MediaKind.image,
      mimeType: 'image/jpeg',
      sizeBytes: f.lengthSync(),
      sha256: 'sha-$name',
      importedAt: DateTime(2025, 1, 1),
      takenAt: takenAt,
      width: width,
      height: height,
      phash: phash,
    ),
  );
}

void main() {
  late AppDatabase db;
  late LibraryPaths paths;

  setUp(() => db = AppDatabase.inMemory());

  Future<void> open(WidgetTester tester, String location) async {
    paths = paths;
    await pumpStudio(
      tester,
      size: desktopSize,
      location: location,
      database: db,
      libraryPaths: paths,
    );
  }

  testWidgets('doublons probables : groupe affiché et retrait confirmé', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    addImage(db, paths, 'plage.jpg', phash: '0f0f0f0f0f0f0f0f');
    final copy = addImage(
      db,
      paths,
      'plage-copie.jpg',
      phash: '0f0f0f0f0f0f0f0e',
    );
    addImage(db, paths, 'montagne.jpg', phash: 'f0f0f0f0f0f0f0f0');
    await open(tester, '/editor');
    await tester.pumpAndSettle();

    expect(find.text('2 images semblables'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('plage-copie.jpg'),
      200,
      scrollable: contentScrollable(),
    );
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'plage-copie.jpg'),
        matching: find.text('Retirer'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retirer « plage-copie.jpg » ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Retirer'));
    await tester.pumpAndSettle();
    expect(MediaRepository(db).findById(copy), isNull);
    expect(find.text('Aucun doublon probable.'), findsOneWidget);
  });

  testWidgets('albums : création et classement par année et mois', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    addImage(db, paths, 'a.jpg', takenAt: DateTime(2024, 7, 14));
    addImage(db, paths, 'b.jpg', takenAt: DateTime(2024, 7, 20));
    addImage(db, paths, 'c.jpg', takenAt: DateTime(2025, 1, 2));
    await open(tester, '/editor');

    await tester.scrollUntilVisible(
      find.text('Classer par année et mois'),
      200,
      scrollable: contentScrollable(),
    );
    await tester.tap(find.text('Classer par année et mois'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 médias hors album'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Classer par année et mois'),
    );
    await tester.pumpAndSettle();

    final albums = AlbumRepository(db).list();
    expect(albums.map((a) => (a.name, a.count)), [
      ('2024-07', 2),
      ('2025-01', 1),
    ]);
    expect(find.text('3 médias classés'), findsOneWidget);

    await tester.tap(find.text('Nouvel album'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'Voyage');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Créer'));
    await tester.pumpAndSettle();
    expect(AlbumRepository(db).list().map((a) => a.name), contains('Voyage'));
  });

  testWidgets('retouche : renommage puis nouvelle version optimisée', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    final id = addImage(db, paths, 'IMG_001.jpg', width: 3000, height: 2000);
    await open(tester, '/editor/$id');

    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du fichier'),
      'plage/../x.jpg',
    );
    await tester.pump();
    expect(find.text('Nom de fichier invalide.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du fichier'),
      'plage.jpg',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Renommer'));
    await tester.pumpAndSettle();
    expect(MediaRepository(db).findById(id)!.fileName, 'plage.jpg');

    await tester.scrollUntilVisible(
      find.text('Enregistrer comme nouvelle version'),
      200,
      scrollable: contentScrollable(),
    );
    await tester.tap(find.text('Enregistrer comme nouvelle version'));
    await settleUntil(
      tester,
      () => find.textContaining('Nouvelle version créée').evaluate().isNotEmpty,
    );
    expect(find.text('Nouvelle version créée : plage-web.jpg'), findsOneWidget);
    final all = MediaRepository(db).list(const MediaListQuery());
    final version = all.firstWhere((m) => m.fileName == 'plage-web.jpg');
    expect(version.derivedFrom, id);
    expect((version.width, version.height), (1920, 1280));
  });

  testWidgets('aperçu : comparaison de taille avant enregistrement', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    final id = addImage(db, paths, 'grande.jpg', width: 3000, height: 2000);
    await open(tester, '/editor/$id');
    await tester.tap(find.text('Miniature (400 px)'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Aperçu'),
      200,
      scrollable: contentScrollable(),
    );
    await tester.tap(find.text('Aperçu'));
    await settleUntil(
      tester,
      () => find.textContaining('→').evaluate().isNotEmpty,
    );
    expect(find.textContaining('Résultat · 400×267'), findsOneWidget);
    expect(find.textContaining('%)'), findsOneWidget);
    expect(db.count('media'), 1, reason: 'un aperçu n\'ajoute rien');
  });

  testWidgets('vidéo sous Linux sans ffmpeg : explication d\'installation', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    final f = writeFile(Directory(paths.mediaDir), 'v.mp4', makeFakeMp4());
    final id = MediaRepository(db).insert(
      NewMedia(
        fileName: 'clip.mp4',
        storedPath: f.path,
        sourcePath: '/s/clip.mp4',
        kind: MediaKind.video,
        sizeBytes: 100,
        sha256: 'v',
        importedAt: DateTime(2025),
      ),
    );
    await open(tester, '/editor/$id');
    expect(find.textContaining('sudo apt install ffmpeg'), findsOneWidget);
    expect(find.text('Convertir en MP4'), findsNothing);
  }, skip: !Platform.isLinux);

  testWidgets('galerie : ranger la sélection dans un nouvel album et filtrer', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    addImage(db, paths, 'a.jpg');
    addImage(db, paths, 'b.jpg');
    await open(tester, '/gallery');

    await tester.longPress(find.byType(MediaGridTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ranger dans un album'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvel album'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Été',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Créer'));
    await tester.pumpAndSettle();
    expect(find.text('1 média rangé dans « Été »'), findsOneWidget);

    await tester.tap(find.text('Tous les albums'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Été').last);
    await tester.pumpAndSettle();
    expect(find.byType(MediaGridTile), findsOneWidget);
  });
}
