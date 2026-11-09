enum ImageOutputFormat { jpeg, png }

enum MetadataPolicy {
  /// Aucune métadonnée dans la version produite (recommandé pour publier).
  stripAll,

  /// Conserve date de prise de vue et appareil, jamais la position GPS.
  keepDateAndCamera,
}

class ImageOptimizeOptions {
  const ImageOptimizeOptions({
    this.maxDimension,
    this.format = ImageOutputFormat.jpeg,
    this.quality = 82,
    this.metadata = MetadataPolicy.stripAll,
  });

  /// Plus grand côté en pixels ; `null` = dimensions d'origine.
  final int? maxDimension;
  final ImageOutputFormat format;

  /// Qualité JPEG (1–100).
  final int quality;
  final MetadataPolicy metadata;

  String get extension => format == ImageOutputFormat.jpeg ? 'jpg' : 'png';

  ImageOptimizeOptions copyWith({
    int? Function()? maxDimension,
    ImageOutputFormat? format,
    int? quality,
    MetadataPolicy? metadata,
  }) => ImageOptimizeOptions(
    maxDimension: maxDimension == null ? this.maxDimension : maxDimension(),
    format: format ?? this.format,
    quality: quality ?? this.quality,
    metadata: metadata ?? this.metadata,
  );
}

enum ImagePreset { web, light, thumbnail, custom }

const imagePresets = {
  ImagePreset.web: ImageOptimizeOptions(maxDimension: 1920, quality: 82),
  ImagePreset.light: ImageOptimizeOptions(maxDimension: 1280, quality: 75),
  ImagePreset.thumbnail: ImageOptimizeOptions(maxDimension: 400, quality: 80),
};

class ImageOptimizeResult {
  const ImageOptimizeResult({
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  final int width;
  final int height;
  final int sizeBytes;
}

/// Préréglages vidéo : hauteur cible et débits (H.264 + AAC, MP4).
enum VideoPreset {
  p720(720, 2500000),
  p1080(1080, 5000000),
  light(480, 1000000);

  const VideoPreset(this.height, this.videoBitrate);

  final int height;
  final int videoBitrate;

  static const audioBitrate = 128000;

  /// Débit plancher : en dessous, l'image se dégrade fortement.
  static const minVideoBitrate = 300000;

  /// Débit vidéo effectif : celui du préréglage, sans jamais dépasser le
  /// débit global de la source (sinon la « version allégée » serait plus
  /// lourde que l'original).
  int effectiveVideoBitrate({int? sourceBytes, int? durationMs}) {
    if (sourceBytes == null || durationMs == null || durationMs <= 0) {
      return videoBitrate;
    }
    final sourceBitrate = sourceBytes * 8 * 1000 ~/ durationMs;
    final cap = sourceBitrate * 85 ~/ 100;
    return cap < videoBitrate
        ? (cap < minVideoBitrate ? minVideoBitrate : cap)
        : videoBitrate;
  }

  /// Taille estimée (débit × durée, + ~2 %).
  int estimateBytes(
    int durationMs, {
    bool removeAudio = false,
    int? sourceBytes,
  }) {
    final video = effectiveVideoBitrate(
      sourceBytes: sourceBytes,
      durationMs: durationMs,
    );
    final bitrate = video + (removeAudio ? 0 : audioBitrate);
    return (bitrate / 8 * durationMs / 1000 * 1.02).round();
  }
}
