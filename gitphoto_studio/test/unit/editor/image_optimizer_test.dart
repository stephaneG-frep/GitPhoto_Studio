import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/media_editor/application/image_optimizer.dart';
import 'package:gitphoto_studio/features/media_editor/domain/optimization.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../support/media_fixtures.dart';

/// Décodeur réel du moteur + encodeur réel : aucune doublure.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('gitphoto_opt_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  const optimizer = ImageOptimizer();

  testWidgets('réduction au préréglage web, original intact', (tester) async {
    await tester.runAsync(() async {
      final bytes = makeJpeg(width: 3000, height: 1500);
      final src = writeFile(tmp, 'grande.jpg', bytes);
      final out = p.join(tmp.path, 'out.jpg');
      final r = await optimizer.optimize(
        sourcePath: src.path,
        outputPath: out,
        options: imagePresets[ImagePreset.web]!,
      );
      expect((r.width, r.height), (1920, 960));
      expect(r.sizeBytes, File(out).lengthSync());
      final decoded = img.decodeJpg(File(out).readAsBytesSync())!;
      expect((decoded.width, decoded.height), (1920, 960));
      expect(src.readAsBytesSync(), bytes, reason: 'source inchangée');
    });
  });

  testWidgets('petite image : jamais agrandie', (tester) async {
    await tester.runAsync(() async {
      final src = writeFile(
        tmp,
        'petite.png',
        makePng(width: 300, height: 200),
      );
      final r = await optimizer.optimize(
        sourcePath: src.path,
        outputPath: p.join(tmp.path, 'out.jpg'),
        options: imagePresets[ImagePreset.web]!,
      );
      expect((r.width, r.height), (300, 200));
    });
  });

  testWidgets('PNG transparent vers JPEG : fond blanc', (tester) async {
    await tester.runAsync(() async {
      final transparent = img.Image(width: 20, height: 20, numChannels: 4);
      final src = writeFile(tmp, 't.png', img.encodePng(transparent));
      final out = p.join(tmp.path, 'out.jpg');
      await optimizer.optimize(
        sourcePath: src.path,
        outputPath: out,
        options: const ImageOptimizeOptions(),
      );
      final px = img.decodeJpg(File(out).readAsBytesSync())!.getPixel(10, 10);
      expect(px.r, greaterThan(245));
      expect(px.g, greaterThan(245));
    });
  });

  testWidgets(
    'métadonnées : tout retirer, ou garder date et appareil sans GPS',
    (tester) async {
      await tester.runAsync(() async {
        final src = writeFile(
          tmp,
          'gps.jpg',
          makeJpeg(
            width: 400,
            height: 200,
            make: 'Studio',
            model: 'Cam X',
            dateTimeOriginal: '2024:07:14 10:30:00',
            orientation: 6,
            gps: true,
          ),
        );
        final stripped = p.join(tmp.path, 'a.jpg');
        final r = await optimizer.optimize(
          sourcePath: src.path,
          outputPath: stripped,
          options: const ImageOptimizeOptions(),
        );
        // Orientation appliquée aux pixels (portrait), aucune métadonnée.
        expect((r.width, r.height), (200, 400));
        expect(
          img.decodeJpgExif(File(stripped).readAsBytesSync())?.isEmpty ?? true,
          isTrue,
        );

        final kept = p.join(tmp.path, 'b.jpg');
        await optimizer.optimize(
          sourcePath: src.path,
          outputPath: kept,
          options: const ImageOptimizeOptions(
            metadata: MetadataPolicy.keepDateAndCamera,
          ),
        );
        final exif = img.decodeJpgExif(File(kept).readAsBytesSync())!;
        expect(exif.imageIfd.model, 'Cam X');
        expect(
          exif.exifIfd['DateTimeOriginal'].toString(),
          '2024:07:14 10:30:00',
        );
        expect(exif.gpsIfd.isEmpty, isTrue, reason: 'jamais de GPS');
        expect(
          exif.imageIfd.orientation,
          isNull,
          reason: 'pixels déjà orientés',
        );
      });
    },
  );

  testWidgets('PNG et qualité JPEG', (tester) async {
    await tester.runAsync(() async {
      final src = writeFile(
        tmp,
        's.jpg',
        makeJpeg(width: 800, height: 600, seed: 9),
      );
      final png = p.join(tmp.path, 'o.png');
      await optimizer.optimize(
        sourcePath: src.path,
        outputPath: png,
        options: const ImageOptimizeOptions(format: ImageOutputFormat.png),
      );
      expect(img.decodePng(File(png).readAsBytesSync()), isNotNull);

      final low = p.join(tmp.path, 'low.jpg');
      final high = p.join(tmp.path, 'high.jpg');
      final a = await optimizer.optimize(
        sourcePath: src.path,
        outputPath: low,
        options: const ImageOptimizeOptions(quality: 40),
      );
      final b = await optimizer.optimize(
        sourcePath: src.path,
        outputPath: high,
        options: const ImageOptimizeOptions(quality: 100),
      );
      expect(a.sizeBytes, lessThan(b.sizeBytes));
    });
  });

  testWidgets('fichier non décodable : erreur, aucun fichier produit', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final src = writeFile(tmp, 'faux.jpg', 'pas une image'.codeUnits);
      final out = p.join(tmp.path, 'out.jpg');
      await expectLater(
        optimizer.optimize(
          sourcePath: src.path,
          outputPath: out,
          options: const ImageOptimizeOptions(),
        ),
        throwsA(anything),
      );
      expect(File(out).existsSync(), isFalse);
    });
  });
}
