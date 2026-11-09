import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// Empreinte Git d'un contenu : SHA-1 de `blob <taille>\0<contenu>`.
/// Permet de savoir sans téléchargement si un fichier distant est identique.
String gitBlobSha(List<int> bytes) {
  final header = utf8.encode('blob ${bytes.length}\u0000');
  return sha1.convert([...header, ...bytes]).toString();
}

/// Même calcul, en flux et dans un isolat, pour un fichier sur disque.
Future<String> gitBlobShaOfFile(String path) {
  return Isolate.run(() async {
    final file = File(path);
    final length = await file.length();
    final output = _DigestSink();
    final input = sha1.startChunkedConversion(output)
      ..add(utf8.encode('blob $length\u0000'));
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return output.value.toString();
  });
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
