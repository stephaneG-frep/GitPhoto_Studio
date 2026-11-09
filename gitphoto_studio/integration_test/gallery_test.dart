import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/app.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/features/gallery/application/gallery_providers.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_query.dart';
import 'package:gitphoto_studio/features/gallery/presentation/media_tile.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Import réel sur la plateforme cible : copie, empreinte, décodeur natif,
/// EXIF, base SQLite sur disque, puis réouverture de l'application.
/// Seul le sélecteur de fichiers (dialogue système) n'est pas automatisable :
/// les fichiers sont transmis directement à l'importateur réel.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('import réel puis réouverture', (tester) async {
    final base = await getTemporaryDirectory();
    final work = Directory(p.join(base.path, 'gitphoto_it_gallery'));
    if (work.existsSync()) work.deleteSync(recursive: true);
    work.createSync(recursive: true);
    addTearDown(() => work.deleteSync(recursive: true));

    final photo = img.Image(width: 1200, height: 800);
    img.fill(photo, color: img.ColorRgb8(30, 140, 220));
    photo.exif.imageIfd['Model'] = 'Test Cam';
    photo.exif.exifIfd['DateTimeOriginal'] = '2023:05:06 07:08:09';
    final source = File(p.join(work.path, 'Plage.jpg'))
      ..writeAsBytesSync(img.encodeJpg(photo));
    final sourceBytes = source.readAsBytesSync();

    final dbPath = p.join(work.path, 'app.db');
    final paths = LibraryPaths(
      root: p.join(work.path, 'support'),
      temporaryDir: p.join(work.path, 'cache'),
    )..ensureCreated();

    Future<(AppDatabase, ProviderContainer)> launch() async {
      final db = AppDatabase.open(dbPath);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          libraryPathsProvider.overrideWithValue(paths),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          key: UniqueKey(),
          container: container,
          child: const GitPhotoStudioApp(initialLocation: '/gallery'),
        ),
      );
      await tester.pumpAndSettle();
      return (db, container);
    }

    var (db, container) = await launch();
    final report = await container
        .read(importControllerProvider.notifier)
        .importFiles([ImportCandidate(source.path)]);
    await tester.pumpAndSettle();

    expect(report!.count(ImportOutcome.imported), 1);
    expect(source.readAsBytesSync(), sourceBytes, reason: 'original intact');
    final item = MediaRepository(db).list(const MediaListQuery()).single;
    expect((item.width, item.height), (1200, 800));
    expect(item.cameraModel, 'Test Cam');
    expect(item.takenAt, DateTime(2023, 5, 6, 7, 8, 9));
    expect(File(item.thumbnailPath!).existsSync(), isTrue);
    expect(find.byType(MediaGridTile), findsOneWidget);

    // Réimport : doublon détecté.
    final again = await container
        .read(importControllerProvider.notifier)
        .importFiles([ImportCandidate(source.path)]);
    expect(again!.count(ImportOutcome.duplicate), 1);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    db.close();

    // Réouverture : le média est toujours là.
    (db, container) = await launch();
    expect(find.byType(MediaGridTile), findsOneWidget);
    await tester.tap(find.byType(MediaGridTile));
    await tester.pumpAndSettle();
    expect(find.text('Plage.jpg'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    db.close();
  });
}
