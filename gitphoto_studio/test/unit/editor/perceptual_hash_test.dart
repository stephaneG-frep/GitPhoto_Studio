import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/media_editor/domain/perceptual_hash.dart';
import 'package:image/image.dart' as img;

/// Image de test avec un motif (dégradé + disque), pas un aplat uniforme.
img.Image scene({int w = 320, int h = 200, bool mirrored = false}) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final xx = mirrored ? w - 1 - x : x;
      image.setPixelRgb(x, y, (xx * 255 ~/ w), (y * 255 ~/ h), 90);
    }
  }
  img.fillCircle(
    image,
    x: mirrored ? w * 3 ~/ 4 : w ~/ 4,
    y: h ~/ 2,
    radius: h ~/ 4,
    color: img.ColorRgb8(250, 250, 250),
  );
  return image;
}

String hashOf(Uint8List bytes) => differenceHash(bytes)!;

void main() {
  final original = hashOf(img.encodePng(scene()));

  test('format : 16 chiffres hexadécimaux', () {
    expect(original, matches(RegExp(r'^[0-9a-f]{16}$')));
  });

  test('même image redimensionnée et recompressée : empreinte proche', () {
    final smaller = img.copyResize(scene(), width: 160);
    final recompressed = hashOf(img.encodeJpg(smaller, quality: 50));
    expect(hammingDistance(original, recompressed), lessThanOrEqualTo(6));
  });

  test('image différente : empreinte éloignée', () {
    final other = hashOf(img.encodePng(scene(mirrored: true)));
    expect(hammingDistance(original, other), greaterThan(10));
  });

  test('fichier non décodable', () {
    expect(differenceHash(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('distance de Hamming', () {
    expect(hammingDistance('0000000000000000', '0000000000000000'), 0);
    expect(hammingDistance('0000000000000000', 'ffffffffffffffff'), 64);
    expect(hammingDistance('0000000000000001', '0000000000000003'), 1);
  });

  test('regroupement transitif, éléments isolés exclus', () {
    final groups = groupSimilar(
      ['a', 'b', 'c', 'd'],
      (s) => {
        'a': '0000000000000000',
        'b': '000000000000000f', // 4 bits de a
        'c': '00000000000000ff', // 4 bits de b, 8 de a
        'd': 'ffffffffffffffff',
      }[s]!,
      threshold: 4,
    );
    expect(groups, [
      ['a', 'b', 'c'],
    ]);
  });
}
