import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// Empreinte SHA-256 d'un fichier, calculée en flux dans un isolat pour ne
/// pas bloquer l'interface, même pour une vidéo volumineuse.
Future<String> sha256OfFile(String path) {
  return Isolate.run(() async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  });
}
