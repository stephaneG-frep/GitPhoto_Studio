import 'package:hive/hive.dart';
import 'photo_model.dart';

/// Adapter Hive pour Photo
/// Utilisé pour sauvegarder les photos dans la base de données Hive
@HiveType(typeId: 0)
class HivePhoto {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String path;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final int dateCreatedMs;

  @HiveField(4)
  final int dateModifiedMs;

  @HiveField(5)
  final int sizeBytes;

  @HiveField(6)
  final int width;

  @HiveField(7)
  final int height;

  @HiveField(8)
  final String? description;

  @HiveField(9)
  final List<String>? tags;

  @HiveField(10)
  final String? albumId;

  @HiveField(11)
  final double? latitude;

  @HiveField(12)
  final double? longitude;

  @HiveField(13)
  final String? city;

  @HiveField(14)
  final String? country;

  @HiveField(15)
  final bool isFavorite;

  @HiveField(16)
  final int rating;

  // Note: aiMetadata n'est pas inclus car trop complexe pour Hive
  // Il peut être stocké séparément si nécessaire

  HivePhoto({
    required this.id,
    required this.path,
    required this.name,
    required this.dateCreatedMs,
    required this.dateModifiedMs,
    required this.sizeBytes,
    required this.width,
    required this.height,
    this.description,
    this.tags,
    this.albumId,
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    this.isFavorite = false,
    this.rating = 0,
  });

  /// Convertit une Photo en HivePhoto
  factory HivePhoto.fromPhoto(Photo photo) {
    return HivePhoto(
      id: photo.id,
      path: photo.path,
      name: photo.name,
      dateCreatedMs: photo.dateCreated.millisecondsSinceEpoch,
      dateModifiedMs: photo.dateModified.millisecondsSinceEpoch,
      sizeBytes: photo.sizeBytes,
      width: photo.width,
      height: photo.height,
      description: photo.description,
      tags: photo.tags,
      albumId: photo.albumId,
      latitude: photo.latitude,
      longitude: photo.longitude,
      city: photo.city,
      country: photo.country,
      isFavorite: photo.isFavorite,
      rating: photo.rating,
    );
  }

  /// Convertit un HivePhoto en Photo
  Photo toPhoto() {
    return Photo(
      id: id,
      path: path,
      name: name,
      dateCreated: DateTime.fromMillisecondsSinceEpoch(dateCreatedMs),
      dateModified: DateTime.fromMillisecondsSinceEpoch(dateModifiedMs),
      sizeBytes: sizeBytes,
      width: width,
      height: height,
      description: description,
      tags: tags,
      albumId: albumId,
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      isFavorite: isFavorite,
      rating: rating,
    );
  }

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is HivePhoto && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HivePhoto(id: $id, name: $name)';
}
