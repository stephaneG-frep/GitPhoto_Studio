import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/gallery/application/media_inspectors.dart';
import 'package:path/path.dart' as p;

import '../../support/media_fixtures.dart';

/// Décodeur réel du moteur Flutter (pas de doublure).
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('gitphoto_eng_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<(int, int)> sizeOf(String path) async {
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    final frame = await codec.getNextFrame();
    final r = (frame.image.width, frame.image.height);
    frame.image.dispose();
    codec.dispose();
    return r;
  }

  testWidgets('dimensions et miniature réduite d\'un PNG', (tester) async {
    await tester.runAsync(() async {
      final f = writeFile(tmp, 'big.png', makePng(width: 1600, height: 800));
      final thumb = p.join(tmp.path, 'thumb.png');
      final r = (await const EngineImageInspector().inspect(
        f.path,
        thumbnailPath: thumb,
        maxSize: 320,
      ))!;
      expect((r.width, r.height), (1600, 800));
      expect(r.thumbnailWritten, isTrue);
      expect(await sizeOf(thumb), (320, 160));
    });
  });

  testWidgets('petite image : miniature non agrandie', (tester) async {
    await tester.runAsync(() async {
      final f = writeFile(tmp, 'small.jpg', makeJpeg(width: 100, height: 50));
      final thumb = p.join(tmp.path, 'thumb.png');
      final r = (await const EngineImageInspector().inspect(
        f.path,
        thumbnailPath: thumb,
      ))!;
      expect((r.width, r.height), (100, 50));
      expect(await sizeOf(thumb), (100, 50));
    });
  });

  testWidgets('orientation EXIF appliquée aux dimensions et à la miniature', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Pixels stockés en 400×200, orientation 6 (rotation d'un quart de
      // tour) : l'image affichée mesure 200×400.
      final f = writeFile(
        tmp,
        'portrait.jpg',
        makeJpeg(width: 400, height: 200, orientation: 6),
      );
      final thumb = p.join(tmp.path, 'thumb.png');
      final r = (await const EngineImageInspector().inspect(
        f.path,
        thumbnailPath: thumb,
        maxSize: 100,
      ))!;
      expect((r.width, r.height), (200, 400));
      expect(await sizeOf(thumb), (50, 100));
    });
  });

  testWidgets('fichier non décodable : null, sans exception', (tester) async {
    await tester.runAsync(() async {
      final f = writeFile(tmp, 'faux.jpg', 'pas une image'.codeUnits);
      expect(await const EngineImageInspector().inspect(f.path), isNull);
    });
  });
}
