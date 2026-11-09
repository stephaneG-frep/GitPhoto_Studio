import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/application/media_inspectors.dart';
import 'package:gitphoto_studio/features/gallery/data/album_repository.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_query.dart';
import 'package:gitphoto_studio/features/media_editor/application/media_version_service.dart';
import 'package:gitphoto_studio/features/media_editor/application/video_transcoder.dart';
import 'package:gitphoto_studio/features/media_editor/domain/optimization.dart';
import 'package:path/path.dart' as p;

import '../../support/media_fixtures.dart';

void main() {
  late Directory root;
  late AppDatabase db;
  late MediaRepository repo;
  late AlbumRepository albums;
  late LibraryPaths paths;
  late MediaImporter importer;

  setUp(() {
    root = Directory.systemTemp.createTempSync('gitphoto_ver_');
    db = AppDatabase.inMemory();
    repo = MediaRepository(db);
    albums = AlbumRepository(db);
    paths = LibraryPaths(
      root: p.join(root.path, 'support'),
      temporaryDir: p.join(root.path, 'cache'),
    )..ensureCreated();
    importer = MediaImporter(
      repository: repo,
      paths: paths,
      imageInspector: const EngineImageInspector(),
      videoInspector: const UnavailableVideoInspector(),
    );
  });
  tearDown(() {
    db.close();
    root.deleteSync(recursive: true);
  });

  group('albums', () {
    test('création insensible à la casse, renommage, comptage', () {
      final a = albums.findOrCreate('Vacances');
      expect(albums.findOrCreate('  vacances '), a);
      albums.findOrCreate('2024-07');
      albums.rename(a, 'Été');
      expect(albums.list().map((x) => x.name), ['2024-07', 'Été']);
      expect(albums.list().first.count, 0);
    });

    test('supprimer un album ne supprime aucun média', () {
      final a = albums.findOrCreate('A');
      final id = repo.insert(
        NewMedia(
          fileName: 'x.jpg',
          storedPath: '/l/x',
          sourcePath: '/s/x',
          kind: MediaKind.image,
          sizeBytes: 1,
          sha256: 'x',
          importedAt: DateTime(2025),
        ),
      );
      repo.setAlbum([id], a);
      expect(repo.list(MediaListQuery(albumId: a)), hasLength(1));
      expect(albums.list().single.count, 1);
      albums.delete(a);
      expect(albums.list(), isEmpty);
      expect(repo.findById(id)!.albumId, isNull);
      expect(db.count('media'), 1);
    });
  });

  testWidgets('version d\'image : nouveau média lié, original intact', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final srcFile = writeFile(
        root,
        'photos/Plage.jpg',
        makeJpeg(width: 2400, height: 1600, gps: true, model: 'Cam'),
      );
      final report = await importer.importAll([ImportCandidate(srcFile.path)]);
      final original = repo.findById(report.items.single.mediaId!)!;
      expect(
        original.phash,
        isNotNull,
        reason: 'empreinte visuelle à l\'import',
      );
      final album = albums.findOrCreate('Été');
      repo.setAlbum([original.id], album);
      final source = repo.findById(original.id)!;
      final originalBytes = File(source.storedPath).readAsBytesSync();

      final service = MediaVersionService(
        importer: importer,
        repository: repo,
        paths: paths,
        videoTranscoder: const UnavailableVideoTranscoder(),
      );
      final r = await service.saveImageVersion(
        source,
        imagePresets[ImagePreset.light]!,
        suffix: 'leger',
      );
      expect(r.outcome, ImportOutcome.imported);
      final version = repo.findById(r.mediaId!)!;
      expect(version.fileName, 'Plage-leger.jpg');
      expect(version.derivedFrom, source.id);
      expect(version.albumId, album);
      expect((version.width, version.height), (1280, 853));
      expect(version.hasGps, isFalse, reason: 'métadonnées retirées');
      expect(version.sizeBytes, lessThan(source.sizeBytes));
      expect(File(source.storedPath).readAsBytesSync(), originalBytes);
      expect(repo.findById(source.id)!.fileName, 'Plage.jpg');

      // Même traitement : version identique détectée, rien de nouveau.
      final again = await service.saveImageVersion(
        source,
        imagePresets[ImagePreset.light]!,
        suffix: 'leger',
      );
      expect(again.outcome, ImportOutcome.duplicate);
      expect(db.count('media'), 2);

      // Aucun fichier de travail ne subsiste.
      final work = Directory(p.join(paths.temporaryDir!, 'gitphoto_work'));
      expect(work.listSync(), isEmpty);
    });
  });

  test(
    'vidéo : une version plus lourde que l\'original n\'est pas conservée',
    () async {
      final src = writeFile(root, 'clip.mp4', makeFakeMp4());
      final id = repo.insert(
        NewMedia(
          fileName: 'clip.mp4',
          storedPath: src.path,
          sourcePath: src.path,
          kind: MediaKind.video,
          sizeBytes: src.lengthSync(),
          sha256: 'clip',
          importedAt: DateTime(2025),
          durationMs: 1000,
        ),
      );
      final service = MediaVersionService(
        importer: importer,
        repository: repo,
        paths: paths,
        videoTranscoder: _GrowingTranscoder(),
      );
      await expectLater(
        service.saveVideoVersion(repo.findById(id)!, VideoPreset.light),
        throwsA(isA<VideoNotSmallerException>()),
      );
      expect(db.count('media'), 1);
      expect(
        Directory(p.join(paths.temporaryDir!, 'gitphoto_work')).listSync(),
        isEmpty,
      );
    },
  );

  test('renommage : le fichier de travail n\'est pas touché', () {
    final id = repo.insert(
      NewMedia(
        fileName: 'a.jpg',
        storedPath: '/l/abc.jpg',
        sourcePath: '/s/a.jpg',
        kind: MediaKind.image,
        sizeBytes: 1,
        sha256: 'abc',
        importedAt: DateTime(2025),
      ),
    );
    repo.rename(id, 'vacances.jpg');
    final m = repo.findById(id)!;
    expect(m.fileName, 'vacances.jpg');
    expect(m.storedPath, '/l/abc.jpg');
  });

  test('noms de versions sûrs', () {
    expect(
      MediaVersionService.versionName('IMG 1.HEIC', 'web', 'jpg'),
      'IMG 1-web.jpg',
    );
    expect(
      MediaVersionService.versionName('clip.mov', '720p', 'mp4'),
      'clip-720p.mp4',
    );
  });

  group('vidéo', () {
    test('estimation de taille', () {
      // 60 s à 2,5 Mb/s + 128 kb/s ≈ 20 Mo.
      final est = VideoPreset.p720.estimateBytes(60000);
      expect(est, closeTo(20.1e6, 0.3e6));
      expect(
        VideoPreset.p720.estimateBytes(60000, removeAudio: true),
        lessThan(est),
      );
    });

    test('débit plafonné à celui de la source (jamais plus lourd)', () {
      // Source : 500 Ko pour 8,1 s ≈ 494 kb/s → plafond 85 % ≈ 420 kb/s.
      final b = VideoPreset.light.effectiveVideoBitrate(
        sourceBytes: 500254,
        durationMs: 8104,
      );
      expect(b, closeTo(419700, 1000));
      expect(
        VideoPreset.light.estimateBytes(
          8104,
          sourceBytes: 500254,
          removeAudio: true,
        ),
        lessThan(500254),
      );
      // Source très lourde : préréglage inchangé.
      expect(
        VideoPreset.p720.effectiveVideoBitrate(
          sourceBytes: 200000000,
          durationMs: 60000,
        ),
        2500000,
      );
      // Plancher.
      expect(
        VideoPreset.p720.effectiveVideoBitrate(
          sourceBytes: 10000,
          durationMs: 60000,
        ),
        VideoPreset.minVideoBitrate,
      );
      // Durée inconnue : préréglage.
      expect(VideoPreset.p720.effectiveVideoBitrate(), 2500000);
    });

    test('arguments ffmpeg fixes, sans agrandissement ni shell', () {
      final args = FfmpegVideoTranscoder.buildArguments(
        input: '/a/b c.mov',
        output: '/o/x.mp4',
        preset: VideoPreset.p720,
        removeAudio: true,
      );
      expect(args[args.indexOf('-i') + 1], '/a/b c.mov');
      expect(args, contains("scale=-2:'min(720,ih)'"));
      expect(args, contains('-an'));
      expect(args, isNot(contains('-c:a')));
      expect(args.last, '/o/x.mp4');
      expect(args, containsAllInOrder(['-b:v', '2500k']));
      final capped = FfmpegVideoTranscoder.buildArguments(
        input: 'a',
        output: 'b',
        preset: VideoPreset.p720,
        removeAudio: false,
        videoBitrate: 800000,
      );
      expect(capped, containsAllInOrder(['-b:v', '800k']));
      expect(capped, containsAllInOrder(['-c:a', 'aac']));
    });

    test('moteur indisponible : erreur explicite', () {
      expect(
        () => const FfmpegVideoTranscoder(
          available: false,
        ).transcode(input: 'a', output: 'b', preset: VideoPreset.p720),
        throwsA(isA<TranscodeException>()),
      );
    });
  });
}

/// Doublure de test : produit un fichier plus lourd que la source.
class _GrowingTranscoder implements VideoTranscoder {
  @override
  bool get isSupported => true;

  @override
  String get engineName => 'test';

  @override
  Future<void> transcode({
    required String input,
    required String output,
    required VideoPreset preset,
    bool removeAudio = false,
    int? videoBitrate,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    File(output).writeAsBytesSync([
      ...File(input).readAsBytesSync(),
      ...List.filled(1000, 0),
    ]);
  }
}
