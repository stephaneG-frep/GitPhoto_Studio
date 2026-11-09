import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/photo_model.dart';
import '../models/ai_response_model.dart';
import 'storage_service.dart';
import 'database_service.dart';
import 'image_service.dart';
import 'ai_service.dart';

/// Service centralisé pour gérer toutes les opérations sur les photos
class PhotoManagerService {
  final StorageService _storageService;
  final DatabaseService _databaseService;
  final ImageService _imageService;
  final AiService _aiService;

  PhotoManagerService({
    StorageService? storageService,
    DatabaseService? databaseService,
    ImageService? imageService,
    AiService? aiService,
  })  : _storageService = storageService ?? StorageService(),
        _databaseService = databaseService ?? DatabaseService(),
        _imageService = imageService ?? ImageService(),
        _aiService = aiService ?? AiService();

  /// Initialise tous les services
  Future<void> initialize() async {
    await _storageService.initialize();
    await _databaseService.initialize();
    await _imageService.initialize();
  }

  // ==================== IMPORTATION ====================

  /// Importe une photo depuis la galerie
  Future<Photo?> importFromGallery({String? albumId}) async {
    // Vérifie les permissions
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      throw Exception('Permission refusée pour accéder à la galerie');
    }

    // Sélectionne une image
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    
    if (result != null) {
      final file = File(result.path);
      
      // Copie dans le stockage de l'app
      final photo = await _storageService.savePhoto(
        sourceFile: file,
        albumId: albumId,
      );
      
      // Sauvegarde dans la base de données
      await _databaseService.savePhoto(photo);
      
      return photo;
    }
    return null;
  }

  /// Prend une photo avec la caméra
  Future<Photo?> takePhoto({String? albumId}) async {
    // Vérifie les permissions
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    
    if (!cameraStatus.isGranted || !storageStatus.isGranted) {
      throw Exception('Permission refusée pour la caméra ou le stockage');
    }

    // Prend une photo
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera);
    
    if (result != null) {
      final file = File(result.path);
      
      // Copie dans le stockage de l'app
      final photo = await _storageService.savePhoto(
        sourceFile: file,
        albumId: albumId,
      );
      
      // Sauvegarde dans la base de données
      await _databaseService.savePhoto(photo);
      
      return photo;
    }
    return null;
  }

  /// Sauvegarde une photo depuis un fichier existant
  /// Utilisé pour le Drag & Drop et l'import manuel
  Future<Photo?> savePhoto({
    required File sourceFile,
    String? albumId,
  }) async {
    try {
      // Copie dans le stockage de l'app
      final photo = await _storageService.savePhoto(
        sourceFile: sourceFile,
        albumId: albumId,
      );
      
      // Sauvegarde dans la base de données
      await _databaseService.savePhoto(photo);
      
      return photo;
    } catch (e) {
      return null;
    }
  }

  // ==================== LISTAGE ====================

  /// Récupère toutes les photos
  Future<List<Photo>> getAllPhotos() async {
    // Récupère depuis la base de données
    final dbPhotos = await _databaseService.getAllPhotos();
    
    // Si la base de données est vide, charge depuis le stockage
    if (dbPhotos.isEmpty) {
      final storagePhotos = await _storageService.listAllPhotos();
      // Sauvegarde dans la base de données
      for (final photo in storagePhotos) {
        await _databaseService.savePhoto(photo);
      }
      return storagePhotos;
    }
    
    return dbPhotos;
  }

  /// Récupère une photo par son ID
  Future<Photo?> getPhotoById(String photoId) async {
    final photos = await getAllPhotos();
    try {
      return photos.firstWhere((photo) => photo.id == photoId);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les photos d'un album
  Future<List<Photo>> getPhotosInAlbum(String albumId) async {
    return await _databaseService.getPhotosInAlbum(albumId);
  }

  /// Récupère les photos favorites
  Future<List<Photo>> getFavoritePhotos() async {
    return await _databaseService.getFavoritePhotos();
  }

  /// Recherche des photos
  Future<List<Photo>> searchPhotos(String query) async {
    // Recherche par nom et tag
    final nameResults = await _databaseService.searchPhotosByName(query);
    final tagResults = await _databaseService.searchPhotosByTag(query);
    
    // Fusionne et supprime les doublons
    final allResults = [...nameResults, ...tagResults];
    final uniqueResults = <Photo>{};
    for (final photo in allResults) {
      uniqueResults.add(photo);
    }
    
    return uniqueResults.toList();
  }

  // ==================== MODIFICATION ====================

  /// Met à jour une photo
  Future<Photo> updatePhoto(Photo photo, {
    String? description,
    List<String>? tags,
    String? albumId,
    bool? isFavorite,
    int? rating,
  }) async {
    final updatedPhoto = photo.copyWith(
      description: description ?? photo.description,
      tags: tags ?? photo.tags,
      albumId: albumId ?? photo.albumId,
      isFavorite: isFavorite ?? photo.isFavorite,
      rating: rating ?? photo.rating,
    );
    
    // Met à jour dans la base de données
    await _databaseService.updatePhoto(updatedPhoto);
    
    return updatedPhoto;
  }

  /// Ajoute un tag à une photo
  Future<Photo> addTagToPhoto(Photo photo, String tag) async {
    final tags = [...?photo.tags, tag];
    return await updatePhoto(photo, tags: tags);
  }

  /// Retire un tag d'une photo
  Future<Photo> removeTagFromPhoto(Photo photo, String tag) async {
    final tags = [...?photo.tags]..removeWhere((t) => t == tag);
    return await updatePhoto(photo, tags: tags);
  }

  /// Bascule le favori
  Future<Photo> toggleFavorite(Photo photo) async {
    return await updatePhoto(photo, isFavorite: !photo.isFavorite);
  }

  // ==================== SUPPRESSION ====================

  /// Supprime une photo
  Future<bool> deletePhoto(Photo photo) async {
    try {
      // Supprime du stockage
      final storageSuccess = await _storageService.deletePhoto(photo);
      
      // Supprime de la base de données
      await _databaseService.deletePhoto(photo.id);
      
      // Supprime la miniature
      await _imageService.deleteThumbnail(photo.id);
      
      return storageSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Supprime plusieurs photos
  Future<int> deleteMultiplePhotos(List<Photo> photos) async {
    int successCount = 0;
    for (final photo in photos) {
      final success = await deletePhoto(photo);
      if (success) successCount++;
    }
    return successCount;
  }

  // ==================== IA ====================

  /// Analyse une photo avec IA
  Future<AiResponse> analyzePhotoWithAI(Photo photo, {String? customPrompt}) async {
    return await _aiService.generatePhotoDescription(
      photo: photo,
      customPrompt: customPrompt,
    );
  }

  /// Génère des tags avec IA
  Future<AiResponse> generateTagsWithAI(Photo photo, {int maxTags = 10}) async {
    return await _aiService.generatePhotoTags(
      photo: photo,
      maxTags: maxTags,
    );
  }

  /// Détecte les objets avec IA
  Future<AiResponse> detectObjectsWithAI(Photo photo) async {
    return await _aiService.analyzePhotoObjects(photo: photo);
  }

  // ==================== STATISTIQUES ====================

  /// Récupère les statistiques de stockage
  Future<Map<String, dynamic>> getStorageStats() async {
    final storageStats = await _storageService.getStorageStats();
    final photoCount = await _databaseService.getPhotoCount();
    final albumCount = await _databaseService.getAlbumCount();
    final thumbnailStats = await _imageService.getThumbnailCacheStats();
    
    return {
      'totalPhotos': photoCount,
      'totalAlbums': albumCount,
      'totalSizeBytes': storageStats.totalSizeBytes,
      'totalSizeInMb': storageStats.totalSizeInMb,
      'totalSizeInGb': storageStats.totalSizeInGb,
      'thumbnailCacheSize': thumbnailStats.totalSizeBytes,
      'thumbnailCacheCount': thumbnailStats.fileCount,
    };
  }

  // ==================== UTILITAIRES ====================

  /// Récupère une image pour affichage
  Future<File?> getPhotoForDisplay(Photo photo) async {
    // Vérifie si le fichier existe
    final file = File(photo.path);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Récupère une miniature pour affichage
  Future<File?> getThumbnailForDisplay(Photo photo) async {
    return await _imageService.getThumbnail(photo);
  }

  /// Rafraîchit la liste des photos
  Future<void> refreshPhotos() async {
    // Charge depuis le stockage et met à jour la base de données
    final storagePhotos = await _storageService.listAllPhotos();
    
    // Vérifie quelles photos existent dans la base de données
    final dbPhotos = await _databaseService.getAllPhotos();
    final dbPhotoIds = dbPhotos.map((p) => p.id).toSet();
    
    // Ajoute les nouvelles photos
    for (final photo in storagePhotos) {
      if (!dbPhotoIds.contains(photo.id)) {
        await _databaseService.savePhoto(photo);
      }
    }
    
    // Supprime les photos qui n'existent plus dans le stockage
    for (final photo in dbPhotos) {
      final file = File(photo.path);
      if (!await file.exists()) {
        await _databaseService.deletePhoto(photo.id);
      }
    }
  }
}
