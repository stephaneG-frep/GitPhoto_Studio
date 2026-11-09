import 'dart:io';

/// Modèle représentant une photo dans l'application
typedef PhotoId = String;

class Photo {
  final PhotoId id;
  final String path;
  final String name;
  final DateTime dateCreated;
  final DateTime dateModified;
  final int sizeBytes;
  final int width;
  final int height;
  final String? description;
  final List<String>? tags;
  final String? albumId;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final Map<String, dynamic>? aiMetadata;
  final bool isFavorite;
  final int rating;

  Photo({
    required this.id,
    required this.path,
    required this.name,
    required this.dateCreated,
    required this.dateModified,
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
    this.aiMetadata,
    this.isFavorite = false,
    this.rating = 0,
  });

  /// Créer une Photo à partir d'un fichier
  factory Photo.fromFile(File file, {
    String? albumId,
    List<String>? tags,
    String? description,
  }) {
    final stat = file.statSync();
    return Photo(
      id: _generateId(file.path),
      path: file.path,
      name: file.path.split('/').last,
      dateCreated: stat.changed,
      dateModified: stat.modified,
      sizeBytes: stat.size,
      width: 0, // À mettre à jour après lecture de l'image
      height: 0,
      description: description,
      tags: tags ?? [],
      albumId: albumId,
      isFavorite: false,
      rating: 0,
    );
  }

  /// Génère un ID unique basé sur le chemin
  static String _generateId(String path) {
    // Simple hash based on path
    return path.hashCode.toString().replaceAll('-', '_');
  }

  /// Vérifie si la photo a des métadonnées IA
  bool get hasAiMetadata => aiMetadata != null && aiMetadata!.isNotEmpty;

  /// Récupère les tags formatés
  String get formattedTags => tags?.join(', ') ?? 'Aucun tag';

  /// Taille en Mo
  double get sizeInMb => sizeBytes / (1024 * 1024);

  /// Ratio de l'image
  double get aspectRatio => width > 0 && height > 0 ? width / height : 1.0;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'name': name,
    'dateCreated': dateCreated.toIso8601String(),
    'dateModified': dateModified.toIso8601String(),
    'sizeBytes': sizeBytes,
    'width': width,
    'height': height,
    'description': description,
    'tags': tags,
    'albumId': albumId,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'country': country,
    'aiMetadata': aiMetadata,
    'isFavorite': isFavorite,
    'rating': rating,
  };

  /// Create from JSON
  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'] as String,
    path: json['path'] as String,
    name: json['name'] as String,
    dateCreated: DateTime.parse(json['dateCreated'] as String),
    dateModified: DateTime.parse(json['dateModified'] as String),
    sizeBytes: json['sizeBytes'] as int,
    width: json['width'] as int,
    height: json['height'] as int,
    description: json['description'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    albumId: json['albumId'] as String?,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    city: json['city'] as String?,
    country: json['country'] as String?,
    aiMetadata: json['aiMetadata'] as Map<String, dynamic>?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    rating: json['rating'] as int? ?? 0,
  );

  Photo copyWith({
    PhotoId? id,
    String? path,
    String? name,
    DateTime? dateCreated,
    DateTime? dateModified,
    int? sizeBytes,
    int? width,
    int? height,
    String? description,
    List<String>? tags,
    String? albumId,
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    Map<String, dynamic>? aiMetadata,
    bool? isFavorite,
    int? rating,
  }) {
    return Photo(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      albumId: albumId ?? this.albumId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
    );
  }

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is Photo && 
     other.id == id &&
     other.path == path);

  @override
  int get hashCode => id.hashCode ^ path.hashCode;

  @override
  String toString() => 'Photo(id: $id, name: $name, path: $path)';
}
