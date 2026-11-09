import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/gallery/application/drop_expansion.dart';
import 'package:gitphoto_studio/features/gallery/application/exif_reader.dart';
import 'package:gitphoto_studio/features/gallery/application/file_fingerprint.dart';
import 'package:gitphoto_studio/features/gallery/application/media_type_detector.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:path/path.dart' as p;

import '../../support/media_fixtures.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('gitphoto_t_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  group('parseExifDate', () {
    test('format EXIF standard', () {
      expect(
        parseExifDate('2024:07:14 10:30:05'),
        DateTime(2024, 7, 14, 10, 30, 5),
      );
    });
    test('valeurs absentes ou invalides', () {
      expect(parseExifDate(null), isNull);
      expect(parseExifDate('0000:00:00 00:00:00'), isNull);
      expect(parseExifDate('2024:13:01 00:00:00'), isNull);
      expect(parseExifDate('n/a'), isNull);
    });
  });

  test(
    'lecture EXIF d\'un vrai JPEG : date, appareil, orientation, GPS',
    () async {
      final f = writeFile(
        tmp,
        'photo.jpg',
        makeJpeg(
          make: 'Studio',
          model: 'Pixel Cam',
          dateTimeOriginal: '2024:07:14 10:30:00',
          orientation: 6,
          gps: true,
        ),
      );
      final exif = (await readJpegExif(f.path))!;
      expect(exif.takenAt, DateTime(2024, 7, 14, 10, 30));
      expect(exif.cameraModel, 'Studio Pixel Cam');
      expect(exif.orientation, 6);
      expect(exif.hasGps, isTrue);
    },
  );

  test('JPEG sans GPS et PNG sans EXIF', () async {
    final jpg = writeFile(tmp, 'a.jpg', makeJpeg(model: 'X'));
    expect((await readJpegExif(jpg.path))!.hasGps, isFalse);
    final png = writeFile(tmp, 'a.png', makePng());
    expect(await readJpegExif(png.path), isNull);
  });

  group('detectMediaType', () {
    test('par signature, même sans extension', () {
      final f = writeFile(tmp, 'sans_extension', makePng());
      final t = detectMediaType(f.path)!;
      expect(t.kind, MediaKind.image);
      expect(t.mimeType, 'image/png');
    });
    test('vidéo MP4', () {
      final f = writeFile(tmp, 'clip.mp4', makeFakeMp4());
      expect(detectMediaType(f.path)!.kind, MediaKind.video);
    });
    test('refuse les fichiers non multimédias et absents', () {
      final f = writeFile(tmp, 'notes.txt', 'bonjour'.codeUnits);
      expect(detectMediaType(f.path), isNull);
      expect(detectMediaType(p.join(tmp.path, 'absent.jpg')), isNull);
    });
    test('le nom affiché sert d\'indice (copie temporaire sans extension)', () {
      final f = writeFile(tmp, 'tmp123', makeJpeg());
      expect(
        detectMediaType(f.path, displayName: 'photo.jpg')!.mimeType,
        'image/jpeg',
      );
    });
  });

  test('extension de la copie de travail', () {
    expect(storedExtension('IMG.JPG', 'image/jpeg'), 'jpg');
    expect(storedExtension('sans', 'image/png'), 'png');
    expect(storedExtension('x.\u0000bad', 'image/png'), 'png');
  });

  test('empreinte SHA-256 conforme', () async {
    final f = writeFile(tmp, 'abc.txt', 'abc'.codeUnits);
    expect(
      await sha256OfFile(f.path),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  group('expandDroppedPaths', () {
    test('fichiers et dossiers récursifs, fichiers cachés ignorés', () {
      final a = writeFile(tmp, 'a.jpg', makeJpeg());
      writeFile(tmp, 'album/b.jpg', makeJpeg());
      writeFile(tmp, 'album/sous/c.png', makePng());
      writeFile(tmp, 'album/.cache/d.jpg', makeJpeg());
      writeFile(tmp, 'album/.e.jpg', makeJpeg());
      final names = expandDroppedPaths([
        a.path,
        p.join(tmp.path, 'album'),
        p.join(tmp.path, 'inexistant'),
      ]).map((c) => p.relative(c.path, from: tmp.path)).toList();
      expect(names, ['a.jpg', 'album/b.jpg', 'album/sous/c.png']);
    });

    test('ne suit pas les liens symboliques de dossiers', () {
      final outside = Directory.systemTemp.createTempSync('gitphoto_out_');
      addTearDown(() => outside.deleteSync(recursive: true));
      writeFile(outside, 'secret.jpg', makeJpeg());
      Directory(p.join(tmp.path, 'album')).createSync();
      Link(p.join(tmp.path, 'album', 'lien')).createSync(outside.path);
      expect(expandDroppedPaths([p.join(tmp.path, 'album')]), isEmpty);
    });

    test('respecte la limite de fichiers', () {
      for (var i = 0; i < 5; i++) {
        writeFile(tmp, 'd/$i.jpg', makeJpeg());
      }
      expect(
        expandDroppedPaths([p.join(tmp.path, 'd')], maxFiles: 3),
        hasLength(3),
      );
    });
  });
}
