import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../domain/media_item.dart';

class DetectedType {
  const DetectedType(this.kind, this.mimeType);

  final MediaKind kind;
  final String mimeType;
}

/// Détermine le type d'un fichier à partir de sa signature binaire, puis de
/// son extension. Renvoie `null` pour tout ce qui n'est ni image ni vidéo.
DetectedType? detectMediaType(String path, {String? displayName}) {
  List<int> header = const [];
  try {
    final raf = File(path).openSync();
    try {
      header = raf.readSync(defaultMagicNumbersMaxLength);
    } finally {
      raf.closeSync();
    }
  } on FileSystemException {
    return null;
  }
  final mime =
      lookupMimeType(displayName ?? path, headerBytes: header) ??
      lookupMimeType(path, headerBytes: header);
  if (mime == null) return null;
  if (mime.startsWith('image/')) return DetectedType(MediaKind.image, mime);
  if (mime.startsWith('video/')) return DetectedType(MediaKind.video, mime);
  return null;
}

/// Extension sûre pour la copie de travail (minuscules, alphanumérique).
String storedExtension(String fileName, String mimeType) {
  final fromName = p.extension(fileName).replaceFirst('.', '').toLowerCase();
  if (RegExp(r'^[a-z0-9]{1,8}$').hasMatch(fromName)) return fromName;
  return extensionFromMime(mimeType) ?? 'bin';
}
