typedef AlbumId = String;

class Album {
  final AlbumId id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? coverPhotoId;
  final int? photoCount;
  final String? color;
  final bool isSmartAlbum;
  final Map<String, dynamic>? smartAlbumCriteria;

  Album({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.coverPhotoId,
    this.photoCount,
    this.color,
    this.isSmartAlbum = false,
    this.smartAlbumCriteria,
  });

  /// Créer un nouvel album
  factory Album.newAlbum({
    required String name,
    String? description,
    String? color,
  }) {
    return Album(
      id: _generateId(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      color: color ?? getRandomColor(),
      isSmartAlbum: false,
      photoCount: 0,
    );
  }

  /// Album "Tous les médias"
  static Album get allMediaAlbum {
    return Album(
      id: 'all_media',
      name: 'Tous les médias',
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
      isSmartAlbum: true,
    );
  }

  /// Album "Favoris"
  static Album get favoritesAlbum {
    return Album(
      id: 'favorites',
      name: 'Favoris',
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
      isSmartAlbum: true,
    );
  }

  /// Génère un ID unique
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Génère une couleur aléatoire pour l'album
  static String getRandomColor() {
    final colors = [
      '#FF6B6B', // Rouge
      '#4ECDC4', // Turquoise
      '#45B7D1', // Bleu
      '#96CEB4', // Vert
      '#FFEAA7', // Jaune
      '#DDA0DD', // Violet
      '#98D8C8', // Vert clair
      '#F7DC6F', // Jaune doré
      '#BB8FCE', // Lilas
      '#85C1E9', // Bleu ciel
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }

  /// Vérifie si c'est un album système
  bool get isSystemAlbum => id == 'all_media' || id == 'favorites';

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'description': description,
    'coverPhotoId': coverPhotoId,
    'photoCount': photoCount,
    'color': color,
    'isSmartAlbum': isSmartAlbum,
    'smartAlbumCriteria': smartAlbumCriteria,
  };

  /// Create from JSON
  factory Album.fromJson(Map<String, dynamic> json) => Album(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    description: json['description'] as String?,
    coverPhotoId: json['coverPhotoId'] as String?,
    photoCount: json['photoCount'] as int?,
    color: json['color'] as String?,
    isSmartAlbum: json['isSmartAlbum'] as bool? ?? false,
    smartAlbumCriteria: json['smartAlbumCriteria'] as Map<String, dynamic>?,
  );

  Album copyWith({
    AlbumId? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? coverPhotoId,
    int? photoCount,
    String? color,
    bool? isSmartAlbum,
    Map<String, dynamic>? smartAlbumCriteria,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      coverPhotoId: coverPhotoId ?? this.coverPhotoId,
      photoCount: photoCount ?? this.photoCount,
      color: color ?? this.color,
      isSmartAlbum: isSmartAlbum ?? this.isSmartAlbum,
      smartAlbumCriteria: smartAlbumCriteria ?? this.smartAlbumCriteria,
    );
  }

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is Album && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Album(id: $id, name: $name)';
}
