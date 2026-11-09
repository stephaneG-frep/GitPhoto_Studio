import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../media_editor/application/video_transcoder.dart' show ffprobeVideo;

/// Dimensions d'une image et éventuelle miniature produite.
class ImageInspection {
  const ImageInspection({
    required this.width,
    required this.height,
    required this.thumbnailWritten,
  });

  final int width;
  final int height;
  final bool thumbnailWritten;
}

abstract interface class ImageInspector {
  /// Renvoie `null` si le format n'est pas décodable sur cette plateforme.
  Future<ImageInspection?> inspect(
    String path, {
    String? thumbnailPath,
    int maxSize,
  });
}

/// Utilise les décodeurs natifs du moteur Flutter : JPEG, PNG, GIF, WebP,
/// BMP partout ; HEIC/HEIF en plus sous Android.
class EngineImageInspector implements ImageInspector {
  const EngineImageInspector();

  @override
  Future<ImageInspection?> inspect(
    String path, {
    String? thumbnailPath,
    int maxSize = 320,
  }) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      var written = false;
      if (thumbnailPath != null && width > 0 && height > 0) {
        final scale = math.min(1.0, maxSize / math.max(width, height));
        codec = await descriptor.instantiateCodec(
          targetWidth: math.max(1, (width * scale).round()),
          targetHeight: math.max(1, (height * scale).round()),
        );
        image = (await codec.getNextFrame()).image;
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (png != null) {
          await File(thumbnailPath).writeAsBytes(png.buffer.asUint8List());
          written = true;
        }
      }
      return ImageInspection(
        width: width,
        height: height,
        thumbnailWritten: written,
      );
    } on Exception {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}

class VideoInspection {
  const VideoInspection({
    this.durationMs,
    this.width,
    this.height,
    this.thumbnailWritten = false,
  });

  final int? durationMs;
  final int? width;
  final int? height;
  final bool thumbnailWritten;
}

abstract interface class VideoInspector {
  /// `false` lorsque la plateforme ne dispose d'aucun moteur vidéo.
  bool get isSupported;

  Future<VideoInspection?> inspect(
    String path, {
    String? thumbnailPath,
    int maxSize,
  });
}

/// Android : `MediaMetadataRetriever` via un canal natif (MainActivity.kt).
class AndroidVideoInspector implements VideoInspector {
  const AndroidVideoInspector();

  static const _channel = MethodChannel('gitphoto/video');

  @override
  bool get isSupported => true;

  @override
  Future<VideoInspection?> inspect(
    String path, {
    String? thumbnailPath,
    int maxSize = 320,
  }) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('probe', {
        'path': path,
        'thumbnailPath': thumbnailPath,
        'maxSize': maxSize,
      });
      if (r == null) return null;
      return VideoInspection(
        durationMs: (r['durationMs'] as num?)?.toInt(),
        width: (r['width'] as num?)?.toInt(),
        height: (r['height'] as num?)?.toInt(),
        thumbnailWritten: r['thumbnail'] == true,
      );
    } on PlatformException {
      return null;
    }
  }
}

/// Plateformes sans moteur vidéo intégré (Linux sans ffmpeg) : aucune
/// métadonnée ni miniature, la vidéo est tout de même importée.
class UnavailableVideoInspector implements VideoInspector {
  const UnavailableVideoInspector();

  @override
  bool get isSupported => false;

  @override
  Future<VideoInspection?> inspect(
    String path, {
    String? thumbnailPath,
    int maxSize = 320,
  }) async => null;
}

/// Linux avec ffmpeg installé : ffprobe (métadonnées) et ffmpeg (miniature).
class FfmpegVideoInspector implements VideoInspector {
  const FfmpegVideoInspector();

  @override
  bool get isSupported => true;

  @override
  Future<VideoInspection?> inspect(
    String path, {
    String? thumbnailPath,
    int maxSize = 320,
  }) async {
    final info = await ffprobeVideo(path);
    if (info == null) return null;
    var written = false;
    if (thumbnailPath != null) {
      final atMs = (info.durationMs ?? 0) >= 2000 ? 1000 : 0;
      try {
        final r = await Process.run('ffmpeg', [
          '-hide_banner',
          '-nostdin',
          '-y',
          '-ss',
          (atMs / 1000).toStringAsFixed(3),
          '-i',
          path,
          '-frames:v',
          '1',
          '-vf',
          'scale=w=$maxSize:h=$maxSize:force_original_aspect_ratio=decrease',
          thumbnailPath,
        ]).timeout(const Duration(seconds: 30));
        written = r.exitCode == 0 && File(thumbnailPath).existsSync();
      } on Object {
        written = false;
      }
    }
    return VideoInspection(
      durationMs: info.durationMs,
      width: info.width,
      height: info.height,
      thumbnailWritten: written,
    );
  }
}
