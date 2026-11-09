import 'package:hive/hive.dart';
import 'album_model.dart';

/// Adapter Hive pour Album
/// Utilisé pour sauvegarder les albums dans la base de données Hive
@HiveType(typeId: 1)
class HiveAlbum {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int createdAtMs;

  @HiveField(3)
  final int updatedAtMs;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final String? coverPhotoId;

  @HiveField(6)
  final int? photoCount;

  @HiveField(7)
  final String? color;

  @HiveField(8)
  final bool isSmartAlbum;

  // Note: smartAlbumCriteria n'est pas inclus car trop complexe pour Hive
  // Il peut être stocké séparément si nécessaire

  HiveAlbum({
    required this.id,
    required this.name,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.description,
    this.coverPhotoId,
    this.photoCount,
    this.color,
    this.isSmartAlbum = false,
  });

  /// Convertit un Album en HiveAlbum
  factory HiveAlbum.fromAlbum(Album album) {
    return HiveAlbum(
      id: album.id,
      name: album.name,
      createdAtMs: album.createdAt.millisecondsSinceEpoch,
      updatedAtMs: album.updatedAt.millisecondsSinceEpoch,
      description: album.description,
      coverPhotoId: album.coverPhotoId,
      photoCount: album.photoCount,
      color: album.color,
      isSmartAlbum: album.isSmartAlbum,
    );
  }

  /// Convertit un HiveAlbum en Album
  Album toAlbum() {
    return Album(
      id: id,
      name: name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
      description: description,
      coverPhotoId: coverPhotoId,
      photoCount: photoCount,
      color: color,
      isSmartAlbum: isSmartAlbum,
    );
  }

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is HiveAlbum && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HiveAlbum(id: $id, name: $name)';
}
