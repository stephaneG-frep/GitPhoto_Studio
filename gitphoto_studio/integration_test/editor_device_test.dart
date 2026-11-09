import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/application/media_inspectors.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/media_editor/application/media_version_service.dart';
import 'package:gitphoto_studio/features/media_editor/application/video_transcoder.dart';
import 'package:gitphoto_studio/features/media_editor/domain/optimization.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Moteurs réels sur la plateforme cible : optimisation d'image, et
/// conversion vidéo (Media3 Transformer sous Android, ffmpeg sous Linux).
///
/// Vidéo sous Android (fichier non versionné) :
///   adb push VIDEO.mp4 /sdcard/Android/data/com.nabu.gitphoto.gitphoto_studio/files/test_video.mp4
///   flutter test integration_test/editor_device_test.dart -d APPAREIL --no-uninstall
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory work;
  late AppDatabase db;
  late MediaRepository repo;
  late MediaImporter importer;
  late LibraryPaths paths;

  setUp(() async {
    work = Directory(
      p.join((await getTemporaryDirectory()).path, 'gitphoto_it_editor'),
    );
    if (work.existsSync()) work.deleteSync(recursive: true);
    work.createSync(recursive: true);
    db = AppDatabase.inMemory();
    repo = MediaRepository(db);
    paths = LibraryPaths(
      root: p.join(work.path, 'support'),
      temporaryDir: p.join(work.path, 'cache'),
    )..ensureCreated();
    importer = MediaImporter(
      repository: repo,
      paths: paths,
      imageInspector: const EngineImageInspector(),
      videoInspector: Platform.isAndroid
          ? const AndroidVideoInspector()
          : const FfmpegVideoInspector(),
    );
  });
  tearDown(() {
    db.close();
    work.deleteSync(recursive: true);
  });

  testWidgets('image : version web réelle', (tester) async {
    final photo = img.Image(width: 4000, height: 3000);
    for (var y = 0; y < 3000; y += 10) {
      img.drawLine(
        photo,
        x1: 0,
        y1: y,
        x2: 3999,
        y2: 2999 - y,
        color: img.ColorRgb8(y % 256, 100, 200),
      );
    }
    final src = File(p.join(work.path, 'Photo.jpg'))
      ..writeAsBytesSync(img.encodeJpg(photo, quality: 95));
    final report = await importer.importAll([ImportCandidate(src.path)]);
    final source = repo.findById(report.items.single.mediaId!)!;

    final service = MediaVersionService(
      importer: importer,
      repository: repo,
      paths: paths,
      videoTranscoder: const UnavailableVideoTranscoder(),
    );
    final r = await service.saveImageVersion(
      source,
      imagePresets[ImagePreset.web]!,
      suffix: 'web',
    );
    final version = repo.findById(r.mediaId!)!;
    debugPrint(
      'IMAGE ${source.sizeBytes} o -> ${version.sizeBytes} o, '
      '${version.width}x${version.height}',
    );
    expect((version.width, version.height), (1920, 1440));
    expect(version.sizeBytes, lessThan(source.sizeBytes));
    expect(version.derivedFrom, source.id);
  });

  testWidgets('vidéo : conversion réelle 480p', (tester) async {
    late final String input;
    late final VideoTranscoder transcoder;
    if (Platform.isAndroid) {
      input = p.join(
        (await getExternalStorageDirectory())!.path,
        'test_video.mp4',
      );
      transcoder = const AndroidVideoTranscoder();
    } else {
      final tools = await ToolProbe().probe();
      if (!tools.hasFfmpeg) {
        markTestSkipped('ffmpeg absent');
        return;
      }
      input = Platform.environment['GITPHOTO_TEST_VIDEO'] ?? '';
      if (input.isEmpty) {
        markTestSkipped('GITPHOTO_TEST_VIDEO non défini');
        return;
      }
      transcoder = const FfmpegVideoTranscoder(available: true);
    }
    expect(File(input).existsSync(), isTrue, reason: 'vidéo de test absente');
    final inputBytes = File(input).lengthSync();

    final report = await importer.importAll([ImportCandidate(input)]);
    final source = repo.findById(report.items.single.mediaId!)!;
    final service = MediaVersionService(
      importer: importer,
      repository: repo,
      paths: paths,
      videoTranscoder: transcoder,
    );
    final progress = <double>[];
    final before = db.count('media');
    try {
      final r = await service.saveVideoVersion(
        source,
        VideoPreset.light,
        onProgress: progress.add,
      );
      final version = repo.findById(r.mediaId!)!;
      debugPrint(
        'VIDEO ${transcoder.engineName} ${source.width}x${source.height} '
        '${source.durationMs} ms ${source.sizeBytes} o -> '
        '${version.width}x${version.height} ${version.durationMs} ms '
        '${version.sizeBytes} o, ${version.mimeType}',
      );
      expect(version.mimeType, 'video/mp4');
      expect(version.fileName, endsWith('-480p.mp4'));
      expect(
        [version.width!, version.height!].reduce((a, b) => a < b ? a : b),
        480,
      );
      expect(version.durationMs, closeTo(source.durationMs!, 300));
      expect(version.thumbnailPath, isNotNull);
      expect(version.sizeBytes, lessThan(source.sizeBytes));
    } on VideoNotSmallerException catch (e) {
      // Garantie vérifiée : version plus lourde refusée, rien d'ajouté,
      // aucun fichier de travail laissé.
      debugPrint(
        'VIDEO ${transcoder.engineName} refusée (non allégée) : '
        '${e.sourceBytes} -> ${e.outputBytes} o',
      );
      expect(db.count('media'), before);
      final workDir = Directory(p.join(paths.temporaryDir!, 'gitphoto_work'));
      expect(workDir.listSync(), isEmpty);
    }
    expect(progress.last, 1.0);
    expect(File(input).lengthSync(), inputBytes, reason: 'original intact');
  });

  testWidgets(
    'vidéo : conversion 720p d\'une source lourde',
    skip: !Platform.isAndroid,
    (tester) async {
      // Source lourde produite sur l'appareil : 1080p à débit élevé.
      final input = p.join(
        (await getExternalStorageDirectory())!.path,
        'test_video.mp4',
      );
      final heavy = p.join(work.path, 'lourde.mp4');
      await const AndroidVideoTranscoder().transcode(
        input: input,
        output: heavy,
        preset: VideoPreset.p1080,
        videoBitrate: 12000000,
      );
      final report = await importer.importAll([ImportCandidate(heavy)]);
      final source = repo.findById(report.items.single.mediaId!)!;
      final service = MediaVersionService(
        importer: importer,
        repository: repo,
        paths: paths,
        videoTranscoder: const AndroidVideoTranscoder(),
      );
      final r = await service.saveVideoVersion(source, VideoPreset.p720);
      final version = repo.findById(r.mediaId!)!;
      debugPrint(
        'VIDEO-LOURDE ${source.width}x${source.height} ${source.sizeBytes} o -> '
        '${version.width}x${version.height} ${version.sizeBytes} o',
      );
      expect(
        [version.width!, version.height!].reduce((a, b) => a < b ? a : b),
        720,
      );
      expect(version.sizeBytes, lessThan(source.sizeBytes));
      expect(version.derivedFrom, source.id);
    },
  );

  testWidgets('vidéo : annulation propre', skip: !Platform.isAndroid, (
    tester,
  ) async {
    final input = p.join(
      (await getExternalStorageDirectory())!.path,
      'test_video.mp4',
    );
    final out = p.join(work.path, 'annule.mp4');
    await expectLater(
      const AndroidVideoTranscoder().transcode(
        input: input,
        output: out,
        preset: VideoPreset.p1080,
        isCancelled: () => true,
      ),
      throwsA(isA<TranscodeCancelled>()),
    );
    expect(File(out).existsSync(), isFalse);
    if (kDebugMode) debugPrint('ANNULATION ok');
  });
}
