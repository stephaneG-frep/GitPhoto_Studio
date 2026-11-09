import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../models/hive_photo.dart';
import '../models/hive_album.dart';
import '../models/hive_adapters.dart';

/// Service de base de données Hive pour GitPhoto Studio
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() => _instance;
  
  DatabaseService._internal();

  // Noms des boxes
  static const String _photosBoxName = 'photos_box';
  static const String _albumsBoxName = 'albums_box';
  static const String _settingsBoxName = 'settings_box';

  // Boxes
  Box<HivePhoto>? _photosBox;
  Box<HiveAlbum>? _albumsBox;
  Box<Map<String, dynamic>>? _settingsBox;

  // Statut d'initialisation
  bool _isInitialized = false;

  /// Initialise la base de données
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialise les adapters Hive
      HiveAdapters.initialize();

      // Récupère le répertoire des documents
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = appDir.path;

      // Initialise Hive
      Hive.init(dbPath);

      // Ouvre les boxes
      _photosBox = await Hive.openBox<HivePhoto>(_photosBoxName);
      _albumsBox = await Hive.openBox<HiveAlbum>(_albumsBoxName);
      _settingsBox = await Hive.openBox<Map<String, dynamic>>(_settingsBoxName);

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize database: ${e.toString()}');
    }
  }

  /// Vérifie si la base de données est initialisée
  bool get isInitialized => _isInitialized;

  /// Vérifie que la base de données est initialisée
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Fermeture de la base de données
  Future<void> close() async {
    if (_photosBox != null) await _photosBox!.close();
    if (_albumsBox != null) await _albumsBox!.close();
    if (_settingsBox != null) await _settingsBox!.close();
    _isInitialized = false;
  }

  // ==================== PHOTOS ====================

  /// Sauvegarde une photo
  Future<void> savePhoto(Photo photo) async {
    await _ensureInitialized();
    final hivePhoto = HivePhoto.fromPhoto(photo);
    await _photosBox!.put(hivePhoto.id, hivePhoto);
  }

  /// Sauvegarde plusieurs photos
  Future<void> savePhotos(List<Photo> photos) async {
    await _ensureInitialized();
    for (final photo in photos) {
      final hivePhoto = HivePhoto.fromPhoto(photo);
      await _photosBox!.put(hivePhoto.id, hivePhoto);
    }
  }

  /// Récupère toutes les photos
  Future<List<Photo>> getAllPhotos() async {
    await _ensureInitialized();
    final hivePhotos = _photosBox!.values.toList();
    return hivePhotos.map((hivePhoto) => hivePhoto.toPhoto()).toList();
  }

  /// Récupère une photo par ID
  Future<Photo?> getPhotoById(String id) async {
    await _ensureInitialized();
    final hivePhoto = _photosBox!.get(id);
    if (hivePhoto == null) return null;
    return hivePhoto.toPhoto();
  }

  /// Récupère les photos d'un album
  Future<List<Photo>> getPhotosInAlbum(String albumId) async {
    await _ensureInitialized();
    final allPhotos = await getAllPhotos();
    return allPhotos.where((photo) => photo.albumId == albumId).toList();
  }

  /// Récupère les photos favorites
  Future<List<Photo>> getFavoritePhotos() async {
    await _ensureInitialized();
    final allPhotos = await getAllPhotos();
    return allPhotos.where((photo) => photo.isFavorite).toList();
  }

  /// Récupère les photos par tag
  Future<List<Photo>> getPhotosByTag(String tag) async {
    await _ensureInitialized();
    final allPhotos = await getAllPhotos();
    return allPhotos.where((photo) => photo.tags?.contains(tag) ?? false).toList();
  }

  /// Recherche des photos par nom
  Future<List<Photo>> searchPhotosByName(String query) async {
    await _ensureInitialized();
    final allPhotos = await getAllPhotos();
    final lowerQuery = query.toLowerCase();
    return allPhotos.where((photo) => 
      photo.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Recherche des photos par tag
  Future<List<Photo>> searchPhotosByTag(String query) async {
    await _ensureInitialized();
    final allPhotos = await getAllPhotos();
    final lowerQuery = query.toLowerCase();
    return allPhotos.where((photo) => 
      photo.tags?.any((tag) => tag.toLowerCase().contains(lowerQuery)) ?? false
    ).toList();
  }

  /// Met à jour une photo
  Future<void> updatePhoto(Photo photo) async {
    await _ensureInitialized();
    final hivePhoto = HivePhoto.fromPhoto(photo);
    await _photosBox!.put(hivePhoto.id, hivePhoto);
  }

  /// Supprime une photo
  Future<void> deletePhoto(String photoId) async {
    await _ensureInitialized();
    await _photosBox!.delete(photoId);
  }

  /// Vérifie si une photo existe
  Future<bool> photoExists(String photoId) async {
    await _ensureInitialized();
    return _photosBox!.containsKey(photoId);
  }

  /// Compte le nombre de photos
  Future<int> getPhotoCount() async {
    await _ensureInitialized();
    return _photosBox!.length;
  }

  // ==================== ALBUMS ====================

  /// Sauvegarde un album
  Future<void> saveAlbum(Album album) async {
    await _ensureInitialized();
    final hiveAlbum = HiveAlbum.fromAlbum(album);
    await _albumsBox!.put(hiveAlbum.id, hiveAlbum);
  }

  /// Sauvegarde plusieurs albums
  Future<void> saveAlbums(List<Album> albums) async {
    await _ensureInitialized();
    for (final album in albums) {
      final hiveAlbum = HiveAlbum.fromAlbum(album);
      await _albumsBox!.put(hiveAlbum.id, hiveAlbum);
    }
  }

  /// Récupère tous les albums
  Future<List<Album>> getAllAlbums() async {
    await _ensureInitialized();
    final hiveAlbums = _albumsBox!.values.toList();
    return hiveAlbums.map((hiveAlbum) => hiveAlbum.toAlbum()).toList();
  }

  /// Récupère un album par ID
  Future<Album?> getAlbumById(String id) async {
    await _ensureInitialized();
    final hiveAlbum = _albumsBox!.get(id);
    if (hiveAlbum == null) return null;
    return hiveAlbum.toAlbum();
  }

  /// Met à jour un album
  Future<void> updateAlbum(Album album) async {
    await _ensureInitialized();
    final hiveAlbum = HiveAlbum.fromAlbum(album);
    await _albumsBox!.put(hiveAlbum.id, hiveAlbum);
  }

  /// Supprime un album
  Future<void> deleteAlbum(String albumId) async {
    await _ensureInitialized();
    await _albumsBox!.delete(albumId);
  }

  /// Vérifie si un album existe
  Future<bool> albumExists(String albumId) async {
    await _ensureInitialized();
    return _albumsBox!.containsKey(albumId);
  }

  /// Compte le nombre d'albums
  Future<int> getAlbumCount() async {
    await _ensureInitialized();
    return _albumsBox!.length;
  }

  // ==================== PARAMÈTRES ====================

  /// Sauvegarde un paramètre
  Future<void> saveSetting(String key, dynamic value) async {
    await _ensureInitialized();
    await _settingsBox!.put(key, value);
  }

  /// Récupère un paramètre
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox?.get(key) ?? defaultValue;
  }

  /// Supprime un paramètre
  Future<void> deleteSetting(String key) async {
    await _ensureInitialized();
    await _settingsBox!.delete(key);
  }

  /// Vérifie si un paramètre existe
  bool hasSetting(String key) {
    return _settingsBox?.containsKey(key) ?? false;
  }

  /// Nettoie tous les paramètres
  Future<void> clearSettings() async {
    await _ensureInitialized();
    await _settingsBox!.clear();
  }

  // ==================== STATISTIQUES ====================

  /// Obtient les statistiques de la base de données
  Future<Map<String, dynamic>> getDatabaseStats() async {
    await _ensureInitialized();
    return {
      'photoCount': await getPhotoCount(),
      'albumCount': await getAlbumCount(),
      'settingsCount': _settingsBox?.length ?? 0,
    };
  }

  // ==================== NETTOYAGE ====================

  /// Nettoie toutes les données
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _photosBox!.clear();
    await _albumsBox!.clear();
    await _settingsBox!.clear();
  }

  /// Supprime toutes les données et les boxes
  Future<void> deleteAllData() async {
    await close();
    await Hive.deleteBoxFromDisk(_photosBoxName);
    await Hive.deleteBoxFromDisk(_albumsBoxName);
    await Hive.deleteBoxFromDisk(_settingsBoxName);
    _isInitialized = false;
  }
}
