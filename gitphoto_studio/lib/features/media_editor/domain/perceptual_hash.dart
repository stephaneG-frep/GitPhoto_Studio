import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Empreinte visuelle « dHash » (64 bits) : deux images visuellement proches
/// (redimensionnées, recompressées) ont des empreintes voisines, contrairement
/// au SHA-256 qui change au moindre octet.
String? differenceHash(Uint8List encodedImage) {
  final decoded = img.decodeImage(encodedImage);
  if (decoded == null) return null;
  final small = img.copyResize(
    img.grayscale(decoded),
    width: 9,
    height: 8,
    interpolation: img.Interpolation.average,
  );
  var bits = BigInt.zero;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final left = small.getPixel(x, y).r;
      final right = small.getPixel(x + 1, y).r;
      bits = (bits << 1) | (left > right ? BigInt.one : BigInt.zero);
    }
  }
  return bits.toRadixString(16).padLeft(16, '0');
}

/// Calcule l'empreinte d'un fichier image dans un isolat.
Future<String?> differenceHashOfFile(String path) => Isolate.run(() {
  try {
    return differenceHash(File(path).readAsBytesSync());
  } on Object {
    return null;
  }
});

/// Nombre de bits différents entre deux empreintes.
int hammingDistance(String a, String b) {
  var x = BigInt.parse(a, radix: 16) ^ BigInt.parse(b, radix: 16);
  var count = 0;
  while (x > BigInt.zero) {
    if (x & BigInt.one == BigInt.one) count++;
    x >>= 1;
  }
  return count;
}

/// Regroupe les éléments dont les empreintes sont à au plus [threshold] bits
/// les unes des autres (regroupement transitif). Seuls les groupes d'au
/// moins deux éléments sont renvoyés.
List<List<T>> groupSimilar<T>(
  List<T> items,
  String Function(T) hashOf, {
  int threshold = 6,
}) {
  final parent = List<int>.generate(items.length, (i) => i);
  int find(int i) {
    while (parent[i] != i) {
      parent[i] = parent[parent[i]];
      i = parent[i];
    }
    return i;
  }

  for (var i = 0; i < items.length; i++) {
    for (var j = i + 1; j < items.length; j++) {
      if (hammingDistance(hashOf(items[i]), hashOf(items[j])) <= threshold) {
        parent[find(i)] = find(j);
      }
    }
  }
  final groups = <int, List<T>>{};
  for (var i = 0; i < items.length; i++) {
    groups.putIfAbsent(find(i), () => []).add(items[i]);
  }
  return groups.values.where((g) => g.length > 1).toList();
}
