import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/security/path_validator.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/application/media_inspectors.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:path/path.dart' as p;

import '../../support/media_fixtures.dart';

void main() {
  late Directory root;
  late Directory sources;
  late AppDatabase db;
  late MediaRepository repo;
  late LibraryPaths paths;

  MediaImporter importer({ImageInspector? inspector}) => MediaImporter(
    repository: repo,
    paths: paths,
    imageInspector: inspector ?? FakeImageInspector(width: 40, height: 20),
    videoInspector: const UnavailableVideoInspector(),
    clock: () => DateTime(2025, 6, 1, 9),
  );

  List<String> filesIn(String dir) =>
      Directory(dir).listSync().map((e) => p.basename(e.path)).toList()..sort();

  setUp(() {
    root = Directory.systemTemp.createTempSync('gitphoto_imp_');
    sources = Directory(p.join(root.path, 'photos'))..createSync();
    paths = LibraryPaths(
      root: p.join(root.path, 'support'),
      temporaryDir: p.join(root.path, 'cache'),
    );
    db = AppDatabase.inMemory();
    repo = MediaRepository(db);
  });
  tearDown(() {
    db.close();
    root.deleteSync(recursive: true);
  });

  test('importe une copie de travail et laisse l\'original intact', () async {
    final bytes = makeJpeg(
      model: 'Pixel Cam',
      dateTimeOriginal: '2024:07:14 10:30:00',
      orientation: 6,
      gps: true,
    );
    final original = writeFile(sources, 'Vacances.JPG', bytes);
    final modifiedBefore = original.lastModifiedSync();

    final report = await importer().importAll([ImportCandidate(original.path)]);

    expect(report.count(ImportOutcome.imported), 1);
    expect(original.readAsBytesSync(), bytes);
    expect(original.lastModifiedSync(), modifiedBefore);

    final m = repo.findById(report.items.single.mediaId!)!;
    expect(m.fileName, 'Vacances.JPG');
    expect(m.kind, MediaKind.image);
    expect(m.mimeType, 'image/jpeg');
    expect(m.sizeBytes, bytes.length);
    expect(p.isWithin(paths.mediaDir, m.storedPath), isTrue);
    expect(p.basename(m.storedPath), '${m.sha256}.jpg');
    expect(File(m.storedPath).readAsBytesSync(), bytes);
    expect(File(m.thumbnailPath!).existsSync(), isTrue);
    expect(m.thumbnailBytes, greaterThan(0));
    // Dimensions telles que rapportées par l'inspecteur (qui applique
    // l'orientation : voir engine_inspector_test.dart).
    expect((m.width, m.height), (40, 20));
    expect(m.takenAt, DateTime(2024, 7, 14, 10, 30));
    expect(m.cameraModel, 'Pixel Cam');
    expect(m.hasGps, isTrue);
    expect(m.importedAt, DateTime(2025, 6, 1, 9));
    expect(m.sourcePath, original.path);
    expect(filesIn(paths.mediaDir), hasLength(1)); // aucun « .part »
  });

  test('doublons détectés par empreinte, même sous un autre nom', () async {
    final bytes = makePng(seed: 7);
    final a = writeFile(sources, 'a.png', bytes);
    final b = writeFile(sources, 'copie de a.png', bytes);
    final c = writeFile(sources, 'c.png', makePng(seed: 8));

    final report = await importer().importAll([
      ImportCandidate(a.path),
      ImportCandidate(b.path),
      ImportCandidate(c.path),
    ]);

    expect(report.items.map((i) => i.outcome).toList(), [
      ImportOutcome.imported,
      ImportOutcome.duplicate,
      ImportOutcome.imported,
    ]);
    expect(report.items[1].mediaId, report.items[0].mediaId);
    expect(db.count('media'), 2);
    expect(b.existsSync(), isTrue);
  });

  test('formats non pris en charge et fichiers absents', () async {
    final txt = writeFile(sources, 'notes.txt', 'texte'.codeUnits);
    final report = await importer().importAll([
      ImportCandidate(txt.path),
      ImportCandidate(p.join(sources.path, 'absent.jpg')),
    ]);
    expect(report.items[0].outcome, ImportOutcome.unsupported);
    expect(report.items[1].outcome, ImportOutcome.failed);
    expect(db.count('media'), 0);
    expect(filesIn(paths.mediaDir), isEmpty);
  });

  test('vidéo importée même sans moteur vidéo (sans métadonnées)', () async {
    final v = writeFile(sources, 'clip.mp4', makeFakeMp4());
    final report = await importer().importAll([ImportCandidate(v.path)]);
    final m = repo.findById(report.items.single.mediaId!)!;
    expect(m.kind, MediaKind.video);
    expect(m.thumbnailPath, isNull);
    expect(m.durationMs, isNull);
  });

  test('en cas d\'échec, aucun fichier partiel ne subsiste', () async {
    final f = writeFile(sources, 'a.png', makePng());
    final report = await importer(
      inspector: FakeImageInspector(throws: true),
    ).importAll([ImportCandidate(f.path)]);
    expect(report.items.single.outcome, ImportOutcome.failed);
    expect(report.items.single.error, contains('échec simulé'));
    expect(filesIn(paths.mediaDir), isEmpty);
    expect(filesIn(paths.thumbnailDir), isEmpty);
    expect(db.count('media'), 0);
    expect(f.existsSync(), isTrue);
  });

  test('image non décodable : importée sans miniature ni dimensions', () async {
    final f = writeFile(sources, 'a.png', makePng());
    final report = await importer(
      inspector: _NullInspector(),
    ).importAll([ImportCandidate(f.path)]);
    final m = repo.findById(report.items.single.mediaId!)!;
    expect(m.thumbnailPath, isNull);
    expect(m.width, isNull);
  });

  test('seule une copie temporaire du cache de l\'app est supprimée', () async {
    final cache = Directory(paths.temporaryDir!)..createSync();
    final temp = writeFile(cache, 'tmp_1', makePng(seed: 1));
    final kept = writeFile(sources, 'b.png', makePng(seed: 2));

    final report = await importer().importAll([
      ImportCandidate(temp.path, displayName: 'IMG_0001.png'),
      ImportCandidate(kept.path),
    ]);

    expect(report.count(ImportOutcome.imported), 2);
    expect(temp.existsSync(), isFalse);
    expect(kept.existsSync(), isTrue);
    final fromTemp = repo.findById(report.items.first.mediaId!)!;
    expect(fromTemp.fileName, 'IMG_0001.png');
    // La date d'une copie temporaire n'est pas une date de prise de vue.
    expect(fromTemp.takenAt, isNull);
    final fromDisk = repo.findById(report.items.last.mediaId!)!;
    // Stockée à la milliseconde près.
    expect(
      fromDisk.takenAt!.millisecondsSinceEpoch,
      kept.lastModifiedSync().millisecondsSinceEpoch,
    );
  });

  test('noms dangereux nettoyés', () async {
    final f = writeFile(sources, 'x.png', makePng());
    final report = await importer().importAll([
      ImportCandidate(f.path, displayName: '../../etc/pa:ss?.png'),
    ]);
    final m = repo.findById(report.items.single.mediaId!)!;
    expect(m.fileName, isNot(contains('/')));
    expect(PathValidator.validateFileName(m.fileName).isValid, isTrue);
  });

  test('annulation entre deux fichiers et progression', () async {
    final files = [
      for (var i = 0; i < 3; i++)
        writeFile(sources, '$i.png', makePng(seed: i)),
    ];
    final progress = <int>[];
    var cancel = false;
    final report = await importer().importAll(
      [for (final f in files) ImportCandidate(f.path)],
      onProgress: (done, total, _) {
        progress.add(done);
        if (done == 1) cancel = true;
      },
      isCancelled: () => cancel,
    );
    // Le fichier en cours (le 2e) est terminé, le 3e n'est pas commencé.
    expect(report.cancelled, isTrue);
    expect(report.items, hasLength(2));
    expect(progress, [0, 1]);
    expect(db.count('media'), 2);
  });

  test(
    'retrait : efface les copies gérées, jamais un fichier extérieur',
    () async {
      final f = writeFile(sources, 'a.png', makePng());
      final imp = importer();
      final report = await imp.importAll([ImportCandidate(f.path)]);
      final m = repo.findById(report.items.single.mediaId!)!;

      // Enregistrement forgé pointant hors de la bibliothèque.
      final outside = writeFile(sources, 'externe.png', makePng(seed: 9));
      final forged = repo.insert(
        NewMedia(
          fileName: 'externe.png',
          storedPath: outside.path,
          sourcePath: outside.path,
          kind: MediaKind.image,
          sizeBytes: 1,
          sha256: 'forge',
          importedAt: DateTime(2025),
          thumbnailPath: outside.path,
        ),
      );

      final removed = imp.remove([m.id, forged]);
      expect(removed, hasLength(2));
      expect(File(m.storedPath).existsSync(), isFalse);
      expect(File(m.thumbnailPath!).existsSync(), isFalse);
      expect(outside.existsSync(), isTrue);
      expect(f.existsSync(), isTrue);
      expect(db.count('media'), 0);
    },
  );
}

class _NullInspector implements ImageInspector {
  @override
  Future<ImageInspection?> inspect(
    String path, {
    String? thumbnailPath,
    int maxSize = 320,
  }) async => null;
}
