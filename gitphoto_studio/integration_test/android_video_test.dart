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
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/gallery/presentation/media_tile.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Android uniquement : canal natif MediaMetadataRetriever et lecture
/// `video_player` sur une vraie vidéo.
///
/// Préparation (le fichier n'est pas versionné) :
///   adb shell mkdir -p /sdcard/Android/data/com.nabu.gitphoto.gitphoto_studio/files
///   adb push VIDEO.mp4 /sdcard/Android/data/com.nabu.gitphoto.gitphoto_studio/files/test_video.mp4
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'vidéo réelle : métadonnées, miniature et lecture',
    skip: !Platform.isAndroid,
    (tester) async {
      final external = await getExternalStorageDirectory();
      final video = File(p.join(external!.path, 'test_video.mp4'));
      expect(
        video.existsSync(),
        isTrue,
        reason: 'Déposer test_video.mp4 avec adb (voir en-tête du fichier)',
      );

      final work = Directory(
        p.join((await getTemporaryDirectory()).path, 'gitphoto_it_video'),
      );
      if (work.existsSync()) work.deleteSync(recursive: true);
      work.createSync(recursive: true);
      addTearDown(() => work.deleteSync(recursive: true));

      final db = AppDatabase.open(p.join(work.path, 'app.db'));
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          libraryPathsProvider.overrideWithValue(
            LibraryPaths(root: work.path, temporaryDir: null)..ensureCreated(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GitPhotoStudioApp(initialLocation: '/gallery'),
        ),
      );
      await tester.pumpAndSettle();

      final report = await container
          .read(importControllerProvider.notifier)
          .importFiles([ImportCandidate(video.path)]);
      expect(report!.count(ImportOutcome.imported), 1);
      expect(video.existsSync(), isTrue, reason: 'original intact');

      final item = MediaRepository(db).findById(report.items.single.mediaId!)!;
      expect(item.kind, MediaKind.video);
      expect(item.durationMs, greaterThan(0));
      expect(item.width, greaterThan(0));
      expect(item.height, greaterThan(0));
      expect(File(item.thumbnailPath!).lengthSync(), greaterThan(0));
      debugPrint(
        'VIDEO ${item.mimeType} ${item.width}x${item.height} '
        '${item.durationMs} ms, miniature ${item.thumbnailBytes} o',
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(MediaGridTile));
      for (
        var i = 0;
        i < 50 && find.byType(VideoPlayer).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(VideoPlayer), findsOneWidget);
      // Fin de la transition d'ouverture avant d'interagir.
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Lecture'));
      for (
        var i = 0;
        i < 50 && find.byTooltip('Pause').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final controller = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller;
      debugPrint(
        'PLAYER initialisé=${controller.value.isInitialized} '
        'lecture=${controller.value.isPlaying} '
        'position=${controller.value.position.inMilliseconds} ms '
        'erreur=${controller.value.errorDescription}',
      );
      expect(controller.value.isPlaying, isTrue);
      expect(find.byTooltip('Pause'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );
}
