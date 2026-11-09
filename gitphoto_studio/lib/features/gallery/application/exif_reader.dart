import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ExifSummary {
  const ExifSummary({
    this.takenAt,
    this.cameraModel,
    this.orientation,
    this.hasGps = false,
  });

  final DateTime? takenAt;
  final String? cameraModel;
  final int? orientation;
  final bool hasGps;
}

/// Lit les métadonnées EXIF d'un JPEG (en-tête uniquement : les données EXIF
/// se trouvent au début du fichier, dans un segment de 64 Kio maximum).
Future<ExifSummary?> readJpegExif(String path) async {
  try {
    final raf = await File(path).open();
    late Uint8List head;
    try {
      head = await raf.read(256 * 1024);
    } finally {
      await raf.close();
    }
    final exif = img.decodeJpgExif(head);
    if (exif == null || exif.isEmpty) return null;
    return summarizeExif(exif);
  } on Exception {
    return null;
  }
}

ExifSummary summarizeExif(img.ExifData exif) {
  final make = exif.imageIfd.make?.trim();
  final model = exif.imageIfd.model?.trim();
  String? camera;
  if (model != null && model.isNotEmpty) {
    camera = make != null && make.isNotEmpty && !model.startsWith(make)
        ? '$make $model'
        : model;
  }
  final taken =
      exif.exifIfd[0x9003]?.toString() ?? // DateTimeOriginal
      exif.imageIfd[0x0132]?.toString(); // DateTime
  return ExifSummary(
    takenAt: parseExifDate(taken),
    cameraModel: camera,
    orientation: exif.imageIfd.orientation,
    hasGps: !exif.gpsIfd.isEmpty,
  );
}

/// Format EXIF : `AAAA:MM:JJ HH:MM:SS` (heure locale de l'appareil).
DateTime? parseExifDate(String? value) {
  if (value == null) return null;
  final m = RegExp(
    r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(value.trim());
  if (m == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) int.parse(m[i]!)];
  if (parts[0] < 1900 || parts[1] < 1 || parts[1] > 12) return null;
  if (parts[2] < 1 || parts[2] > 31) return null;
  return DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
}
