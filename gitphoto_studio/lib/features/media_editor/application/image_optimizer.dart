import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../domain/optimization.dart';

/// Produit une version optimisée d'une image dans un NOUVEAU fichier.
/// L'image source n'est jamais modifiée.
///
/// Décodage : décodeur natif du moteur (orientation EXIF appliquée, HEIC sous
/// Android) avec réduction directe à la taille cible. Encodage : paquet
/// `image`, dans un isolat pour ne pas figer l'interface.
class ImageOptimizer {
  const ImageOptimizer();

  Future<ImageOptimizeResult> optimize({
    required String sourcePath,
    required String outputPath,
    required ImageOptimizeOptions options,
  }) async {
    final pixels = await _decode(sourcePath, options.maxDimension);
    Uint8List? exifSource;
    if (options.metadata == MetadataPolicy.keepDateAndCamera) {
      final raf = await File(sourcePath).open();
      try {
        exifSource = await raf.read(256 * 1024);
      } finally {
        await raf.close();
      }
    }
    final bytes = await Isolate.run(() => _encode(pixels, options, exifSource));
    await File(outputPath).writeAsBytes(bytes, flush: true);
    return ImageOptimizeResult(
      width: pixels.width,
      height: pixels.height,
      sizeBytes: bytes.length,
    );
  }

  static Future<_Pixels> _decode(String path, int? maxDimension) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final w = descriptor.width;
      final h = descriptor.height;
      final scale = maxDimension == null
          ? 1.0
          : math.min(1.0, maxDimension / math.max(w, h));
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (w * scale).round()),
        targetHeight: math.max(1, (h * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (data == null) throw StateError('Décodage impossible');
      return _Pixels(image.width, image.height, data.buffer.asUint8List());
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static Uint8List _encode(
    _Pixels pixels,
    ImageOptimizeOptions options,
    Uint8List? exifSource,
  ) {
    var image = img.Image.fromBytes(
      width: pixels.width,
      height: pixels.height,
      bytes: pixels.rgba.buffer,
      numChannels: 4,
    );
    if (options.format == ImageOutputFormat.jpeg) {
      // Le JPEG n'a pas de transparence : composition sur fond blanc.
      final background = img.Image(width: image.width, height: image.height);
      img.fill(background, color: img.ColorRgb8(255, 255, 255));
      image = img.compositeImage(background, image);
    }
    image.exif = img.ExifData();
    if (exifSource != null) {
      final source = img.decodeJpgExif(exifSource);
      if (source != null) {
        for (final tag in ['Make', 'Model', 'DateTime']) {
          final v = source.imageIfd[tag];
          if (v != null) image.exif.imageIfd[tag] = v;
        }
        final taken = source.exifIfd['DateTimeOriginal'];
        if (taken != null) image.exif.exifIfd['DateTimeOriginal'] = taken;
        // Pas d'orientation : les pixels sont déjà orientés. Pas de GPS.
      }
    }
    return options.format == ImageOutputFormat.jpeg
        ? img.encodeJpg(image, quality: options.quality.clamp(1, 100))
        : img.encodePng(image, level: 6);
  }
}

class _Pixels {
  const _Pixels(this.width, this.height, this.rgba);

  final int width;
  final int height;
  final Uint8List rgba;
}
