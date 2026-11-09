import '../models/album_model.dart';
import 'storage_service.dart';

/// Service pour gérer les albums
class AlbumService {
  final StorageService _storageService;
  
  AlbumService({StorageService? storageService}) 
      : _storageService = storageService ?? StorageService();

  // Liste des albums en mémoire (à remplacer par une base de données)
  final List<Album> _albums = [];

  /// Initialise le service
  Future<void> initialize() async {
    await _storageService.initialize();
    // Charge les albums système
    _albums.addAll([
      Album.allMediaAlbum,
      Album.favoritesAlbum,
    ]);
  }

  /// Crée un nouvel album
  Future<Album> createAlbum({
    required String name,
    String? description,
    String? color,
  }) async {
    final album = Album.newAlbum(
      name: name,
      description: description,
      color: color,
    );
    
    _albums.add(album);
    return album;
  }

  /// Récupère tous les albums
  List<Album> getAllAlbums() {
    return [..._albums];
  }

  /// Récupère un album par ID
  Album? getAlbumById(String id) {
    return _albums.firstWhere((album) => album.id == id);
  }

  /// Met à jour un album
  Future<Album> updateAlbum(String id, {
    String? name,
    String? description,
    String? color,
    String? coverPhotoId,
  }) async {
    final index = _albums.indexWhere((album) => album.id == id);
    if (index == -1) {
      throw Exception('Album not found');
    }

    final updatedAlbum = _albums[index].copyWith(
      name: name ?? _albums[index].name,
      description: description ?? _albums[index].description,
      color: color ?? _albums[index].color,
      coverPhotoId: coverPhotoId ?? _albums[index].coverPhotoId,
      updatedAt: DateTime.now(),
    );

    _albums[index] = updatedAlbum;
    return updatedAlbum;
  }

  /// Supprime un album
  Future<bool> deleteAlbum(String id) async {
    // Ne peut pas supprimer les albums système
    final album = getAlbumById(id);
    if (album?.isSystemAlbum ?? false) {
      return false;
    }

    final index = _albums.indexWhere((album) => album.id == id);
    if (index == -1) return false;

    _albums.removeAt(index);
    return true;
  }

  /// Ajoute une photo à un album
  Future<bool> addPhotoToAlbum(String albumId, String photoId) async {
    final album = getAlbumById(albumId);
    if (album == null || album.isSystemAlbum) {
      return false;
    }

    // Dans une implémentation réelle, on mettrait à jour la base de données
    // et on associerait la photo à l'album
    
    return true;
  }

  /// Retire une photo d'un album
  Future<bool> removePhotoFromAlbum(String albumId, String photoId) async {
    final album = getAlbumById(albumId);
    if (album == null || album.isSystemAlbum) {
      return false;
    }

    return true;
  }

  /// Définit une photo comme couverture d'album
  Future<bool> setAlbumCover(String albumId, String photoId) async {
    final album = getAlbumById(albumId);
    if (album == null) {
      return false;
    }

    await updateAlbum(albumId, coverPhotoId: photoId);
    return true;
  }

  /// Crée un album intelligent
  Future<Album> createSmartAlbum({
    required String name,
    required Map<String, dynamic> criteria,
    String? description,
    String? color,
  }) async {
    final album = Album(
      id: _generateId(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      color: color ?? Album.getRandomColor(),
      isSmartAlbum: true,
      smartAlbumCriteria: criteria,
      photoCount: 0,
    );

    _albums.add(album);
    return album;
  }

  /// Génère un ID unique
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Recherche des albums par nom
  List<Album> searchAlbums(String query) {
    return _albums
        .where((album) => 
          album.name.toLowerCase().contains(query.toLowerCase())
        )
        .toList();
  }

  /// Trie les albums par nom
  List<Album> sortAlbumsByName({bool descending = false}) {
    return _albums.toList()
      ..sort((a, b) => descending 
          ? b.name.compareTo(a.name) 
          : a.name.compareTo(b.name));
  }

  /// Trie les albums par date de création
  List<Album> sortAlbumsByDate({bool descending = true}) {
    return _albums.toList()
      ..sort((a, b) => descending 
          ? b.createdAt.compareTo(a.createdAt) 
          : a.createdAt.compareTo(b.createdAt));
  }

  /// Récupère le nombre de photos dans un album
  Future<int> getPhotoCount(String albumId) async {
    // Dans une implémentation réelle, on compterait les photos associées
    return 0;
  }
}
