enum MediaKind { image, video }

/// Média enregistré dans la bibliothèque du studio.
///
/// [storedPath] désigne la copie de travail gérée par l'application ;
/// [sourcePath] indique d'où le fichier a été importé (information seule :
/// l'original n'est jamais modifié ni supprimé).
class MediaItem {
  const MediaItem({
    required this.id,
    required this.fileName,
    required this.storedPath,
    required this.sourcePath,
    required this.kind,
    required this.sizeBytes,
    required this.sha256,
    required this.importedAt,
    this.mimeType,
    this.thumbnailPath,
    this.thumbnailBytes = 0,
    this.width,
    this.height,
    this.durationMs,
    this.takenAt,
    this.cameraModel,
    this.hasGps = false,
    this.derivedFrom,
    this.phash,
    this.albumId,
  });

  final int id;
  final String fileName;
  final String storedPath;
  final String sourcePath;
  final MediaKind kind;
  final int sizeBytes;
  final String sha256;
  final DateTime importedAt;
  final String? mimeType;
  final String? thumbnailPath;
  final int thumbnailBytes;
  final int? width;
  final int? height;
  final int? durationMs;
  final DateTime? takenAt;
  final String? cameraModel;
  final bool hasGps;

  /// Média d'origine si celui-ci en est une version (optimisée, convertie).
  final int? derivedFrom;

  /// Empreinte visuelle (dHash) pour les doublons probables.
  final String? phash;
  final int? albumId;

  bool get isVideo => kind == MediaKind.video;

  /// Date de référence pour le tri : prise de vue si connue, sinon import.
  DateTime get displayDate => takenAt ?? importedAt;
}
