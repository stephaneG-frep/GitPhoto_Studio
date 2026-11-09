import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:gitphoto_studio/features/gallery/application/gallery_providers.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/gallery/presentation/media_tile.dart';
import 'package:gitphoto_studio/features/gallery/presentation/media_viewer_screen.dart';
import 'package:path/path.dart' as p;

import '../support/media_fixtures.dart';
import 'test_app.dart';

/// Enregistre des médias avec de vrais fichiers dans la bibliothèque.
int addMedia(
  AppDatabase db,
  LibraryPaths paths,
  String name, {
  MediaKind kind = MediaKind.image,
  int size = 100,
  bool gps = false,
  int day = 1,
}) {
  final stored = writeFile(
    Directory(paths.mediaDir),
    '$name.bin',
    kind == MediaKind.image ? makePng(seed: name.hashCode) : makeFakeMp4(),
  );
  return MediaRepository(db).insert(
    NewMedia(
      fileName: name,
      storedPath: stored.path,
      sourcePath: '/photos/$name',
      kind: kind,
      mimeType: kind == MediaKind.image ? 'image/png' : 'video/mp4',
      sizeBytes: size,
      sha256: 'sha-$name',
      importedAt: DateTime(2025, 1, day),
      width: kind == MediaKind.image ? 40 : null,
      height: kind == MediaKind.image ? 20 : null,
      hasGps: gps,
    ),
  );
}

List<String> visibleNames(WidgetTester tester) => tester
    .widgetList<MediaThumbnail>(find.byType(MediaThumbnail))
    .map((t) => t.item.fileName)
    .toList();

void main() {
  late AppDatabase db;
  late LibraryPaths paths;

  setUp(() => db = AppDatabase.inMemory());

  Future<void> openGallery(
    WidgetTester tester, {
    FakeMediaPicker? picker,
    FakeExternalOpener? opener,
    Size size = desktopSize,
  }) async {
    await pumpStudio(
      tester,
      size: size,
      location: '/gallery',
      database: db,
      libraryPaths: paths,
      extraOverrides: [
        imageInspectorProvider.overrideWithValue(FakeImageInspector()),
        if (picker != null) mediaPickerProvider.overrideWithValue(picker),
        if (opener != null) externalOpenerProvider.overrideWithValue(opener),
      ],
    );
  }

  testWidgets('bibliothèque vide : Pixel et bouton d\'import', (tester) async {
    paths = createTestLibraryPaths();
    await openGallery(tester, size: phoneSize);
    expect(find.text('Votre bibliothèque est vide'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Importer'), findsOneWidget);
    expect(find.text('Aucun média'), findsOneWidget);
  });

  testWidgets('recherche, filtre et tri', (tester) async {
    paths = createTestLibraryPaths();
    addMedia(db, paths, 'plage.png', size: 300, day: 1);
    addMedia(db, paths, 'montagne.png', size: 100, day: 3);
    addMedia(db, paths, 'clip.mp4', kind: MediaKind.video, size: 200, day: 2);
    await openGallery(tester);

    expect(find.text('3 médias'), findsOneWidget);
    // Tri par défaut : date décroissante.
    expect(visibleNames(tester), ['montagne.png', 'clip.mp4', 'plage.png']);

    await tester.enterText(find.byType(TextField), 'PLA');
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['plage.png']);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Vidéos'));
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['clip.mp4']);

    await tester.tap(find.text('Tous'));
    await tester.tap(find.byTooltip('Trier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taille').last);
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['plage.png', 'clip.mp4', 'montagne.png']);

    await tester.tap(find.byTooltip('Ordre décroissant'));
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['montagne.png', 'clip.mp4', 'plage.png']);

    // Tri et filtre sont mémorisés.
    final prefs = PreferencesRepository(db);
    expect(prefs.read('gallery.sort'), 'size');
    expect(prefs.read('gallery.ascending'), 'true');
  });

  testWidgets('affichage liste mémorisé, avec indicateur GPS', (tester) async {
    paths = createTestLibraryPaths();
    addMedia(db, paths, 'gps.png', gps: true);
    await openGallery(tester);

    expect(find.byType(MediaGridTile), findsOneWidget);
    await tester.tap(find.byTooltip('Affichage en liste'));
    await tester.pumpAndSettle();
    expect(find.byType(MediaListTile), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(PreferencesRepository(db).read('gallery.view_mode'), 'list');
  });

  testWidgets('sélection multiple et retrait confirmé', (tester) async {
    paths = createTestLibraryPaths();
    final a = addMedia(db, paths, 'a.png');
    addMedia(db, paths, 'b.png');
    final storedA = MediaRepository(db).findById(a)!.storedPath;
    await openGallery(tester);

    await tester.longPress(find.byType(MediaGridTile).first);
    await tester.pumpAndSettle();
    expect(find.text('1 sélectionné'), findsOneWidget);

    await tester.tap(find.byTooltip('Tout sélectionner'));
    await tester.pumpAndSettle();
    expect(find.text('2 sélectionnés'), findsOneWidget);

    // Annulation : rien n'est retiré.
    await tester.tap(find.byTooltip('Retirer de la bibliothèque'));
    await tester.pumpAndSettle();
    expect(find.text('Retirer ces 2 médias ?'), findsOneWidget);
    expect(
      find.textContaining('originaux ne sont pas touchés'),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(db.count('media'), 2);

    await tester.tap(find.byTooltip('Retirer de la bibliothèque'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Retirer'));
    await tester.pumpAndSettle();
    expect(db.count('media'), 0);
    expect(File(storedA).existsSync(), isFalse);
    expect(find.text('2 médias retirés'), findsOneWidget);
    expect(find.text('Votre bibliothèque est vide'), findsOneWidget);
  });

  testWidgets('import via le sélecteur : progression puis rapport', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    final src = Directory.systemTemp.createTempSync('gitphoto_src_');
    addTearDown(() => src.deleteSync(recursive: true));
    final png = makePng(seed: 3);
    final picker = FakeMediaPicker([
      ImportCandidate(writeFile(src, 'a.png', png).path),
      ImportCandidate(writeFile(src, 'copie.png', png).path),
      ImportCandidate(writeFile(src, 'notes.txt', [65]).path),
    ]);
    await openGallery(tester, picker: picker);

    await tester.tap(find.widgetWithText(FilledButton, 'Importer'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // Laisse les entrées-sorties réelles (copie, empreinte dans un isolat)
    // s'exécuter jusqu'à la fin de l'import.
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(
      find.text(
        'Import terminé : 1 importé(s), 1 déjà présent(s), '
        '1 non pris en charge, 0 en échec.',
      ),
      findsOneWidget,
    );
    expect(visibleNames(tester), ['a.png']);

    await tester.tap(find.text('Détails'));
    await tester.pumpAndSettle();
    expect(find.text('Rapport d\'import'), findsOneWidget);
    expect(find.text('Déjà présent dans la bibliothèque'), findsOneWidget);
    expect(find.text('Format non pris en charge'), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
  });

  testWidgets('le message d\'import disparaît de lui-même', (tester) async {
    paths = createTestLibraryPaths();
    final src = Directory.systemTemp.createTempSync('gitphoto_src_');
    addTearDown(() => src.deleteSync(recursive: true));
    final picker = FakeMediaPicker([
      ImportCandidate(writeFile(src, 'a.png', makePng(seed: 4)).path),
    ]);
    await openGallery(tester, picker: picker);
    await tester.tap(find.widgetWithText(FilledButton, 'Importer'));
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.byType(SnackBar).evaluate().isNotEmpty) break;
    }
    expect(find.byType(SnackBar), findsOneWidget);
    // Animation d'apparition, puis délai d'affichage.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('ouvrir un média ferme le message d\'import', (tester) async {
    paths = createTestLibraryPaths();
    final src = Directory.systemTemp.createTempSync('gitphoto_src_');
    addTearDown(() => src.deleteSync(recursive: true));
    final picker = FakeMediaPicker([
      ImportCandidate(writeFile(src, 'a.png', makePng(seed: 5)).path),
    ]);
    await openGallery(tester, picker: picker);
    await tester.tap(find.widgetWithText(FilledButton, 'Importer'));
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.byType(SnackBar).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(find.byType(MediaGridTile));
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('le tableau de bord reflète les médias importés', (tester) async {
    paths = createTestLibraryPaths();
    addMedia(db, paths, 'a.png', size: 2048);
    addMedia(db, paths, 'b.png', size: 2048);
    await pumpStudio(
      tester,
      size: desktopSize,
      database: db,
      libraryPaths: paths,
    );
    expect(
      find.ancestor(of: find.text('2'), matching: find.byType(Card)),
      findsOneWidget,
    );
  });

  testWidgets('visionneuse : image, métadonnées et avertissement GPS', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    addMedia(db, paths, 'photo.png', gps: true);
    await openGallery(tester);

    await tester.tap(find.byType(MediaGridTile));
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerScreen), findsOneWidget);
    expect(find.text('photo.png'), findsOneWidget);

    await tester.tap(find.byTooltip('Informations'));
    await tester.pumpAndSettle();
    expect(find.text('40 × 20'), findsOneWidget);
    expect(find.textContaining('visible par tous'), findsOneWidget);
    expect(find.text('sha-photo.png'), findsOneWidget);

    // Fermeture de la fiche puis retour à la galerie par le bouton retour.
    Navigator.of(tester.element(find.byType(MediaMetadataSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(MediaMetadataSheet), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewerScreen), findsNothing);
  });

  testWidgets('vidéo sous Linux : explication et ouverture par le système', (
    tester,
  ) async {
    paths = createTestLibraryPaths();
    final id = addMedia(db, paths, 'clip.mp4', kind: MediaKind.video);
    final opener = FakeExternalOpener();
    await openGallery(tester, opener: opener);

    await tester.tap(find.byType(MediaGridTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('pas disponible sous Linux'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(
        FilledButton,
        'Ouvrir avec l\'application du système',
      ),
    );
    await tester.pumpAndSettle();
    expect(opener.opened, [MediaRepository(db).findById(id)!.storedPath]);
  }, skip: !Platform.isLinux);

  testWidgets('visionneuse : copie de travail manquante', (tester) async {
    paths = createTestLibraryPaths();
    final id = addMedia(db, paths, 'perdu.png');
    File(MediaRepository(db).findById(id)!.storedPath).deleteSync();
    await openGallery(tester);
    await tester.tap(find.byType(MediaGridTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('introuvable'), findsOneWidget);
  });

  test('chemins de test isolés', () {
    expect(p.isAbsolute(Directory.systemTemp.path), isTrue);
  });
}
