import 'dart:io';
import 'dart:typed_data';

import 'package:gitphoto_studio/features/gallery/application/media_inspectors.dart';
import 'package:gitphoto_studio/features/gallery/application/media_picker.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/core/platform/external_opener.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Fichiers et doublures RÉSERVÉS AUX TESTS. Aucune de ces classes n'est
/// utilisée par l'application ni ne constitue une preuve de fonctionnement
/// sur appareil réel.

Uint8List makePng({int width = 40, int height = 20, int seed = 0}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(seed % 256, 120, 200));
  return img.encodePng(image);
}

Uint8List makeJpeg({
  int width = 40,
  int height = 20,
  int seed = 0,
  String? make,
  String? model,
  String? dateTimeOriginal,
  int? orientation,
  bool gps = false,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, seed % 256, 50));
  if (make != null) image.exif.imageIfd['Make'] = make;
  if (model != null) image.exif.imageIfd['Model'] = model;
  if (orientation != null) image.exif.imageIfd['Orientation'] = orientation;
  if (dateTimeOriginal != null) {
    image.exif.exifIfd['DateTimeOriginal'] = dateTimeOriginal;
  }
  if (gps) image.exif.gpsIfd[0x0001] = img.IfdValueAscii('N');
  return img.encodeJpg(image);
}

/// En-tête MP4 minimal (boîte « ftyp ») : suffisant pour la détection de
/// type, pas pour la lecture.
Uint8List makeFakeMp4() => Uint8List.fromList([
  0,
  0,
  0,
  0x18,
  ...'ftypmp42'.codeUnits,
  0,
  0,
  0,
  0,
  ...'mp42isom'.codeUnits,
  ...List.filled(64, 0),
]);

File writeFile(Directory dir, String name, List<int> bytes) {
  final f = File(p.join(dir.path, name))..createSync(recursive: true);
  f.writeAsBytesSync(bytes);
  return f;
}

class FakeImageInspector implements ImageInspector {
  FakeImageInspector({this.width = 40, this.height = 20, this.throws = false});

  final int width;
  final int height;
  final bool throws;

  @override
  Future<ImageInspection?> inspect(
    String path, {
    String? thumbnailPath,
    int maxSize = 320,
  }) async {
    if (throws) throw StateError('échec simulé');
    if (thumbnailPath != null) {
      File(thumbnailPath).writeAsBytesSync(makePng(width: 8, height: 4));
    }
    return ImageInspection(
      width: width,
      height: height,
      thumbnailWritten: thumbnailPath != null,
    );
  }
}

class FakeMediaPicker implements MediaPicker {
  FakeMediaPicker(this.files);

  final List<ImportCandidate> files;
  int calls = 0;

  @override
  Future<List<ImportCandidate>> pick() async {
    calls++;
    return files;
  }
}

class FakeExternalOpener implements ExternalOpener {
  final opened = <String>[];

  @override
  bool get isSupported => true;

  @override
  Future<bool> open(String path) async {
    opened.add(path);
    return true;
  }
}
