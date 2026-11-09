import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/photo_model.dart';

/// Service pour gérer les images (affichage, cache, traitement)
class ImageService {
  static final ImageService _instance = ImageService._internal();
  
  factory ImageService() => _instance;
  
  ImageService._internal();

  // Cache manager
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  // Répertoire de cache des miniatures
  Directory? _thumbnailsDir;

  /// Initialise le service
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _thumbnailsDir = Directory('${appDir.path}/thumbnails');
    
    if (!await _thumbnailsDir!.exists()) {
      await _thumbnailsDir!.create(recursive: true);
    }
  }

  /// Obtient le répertoire des miniatures
  Directory getThumbnailsDirectory() {
    return _thumbnailsDir ?? Directory('');
  }

  // ==================== GESTION DES MINIATURES ====================

  /// Génère une miniature pour une photo
  Future<File> createThumbnail(Photo photo, {int maxWidth = 300, int maxHeight = 300}) async {
    try {
      final sourceFile = File(photo.path);
      if (!await sourceFile.exists()) {
        throw Exception('Fichier source introuvable: ${photo.path}');
      }

      final thumbnailPath = getThumbnailPath(photo.id);
      final thumbnailFile = File(thumbnailPath);
      
      // Pour l'instant, on copie simplement le fichier
      // Dans une implémentation complète, on redimensionnerait l'image
      final bytes = await sourceFile.readAsBytes();
      await thumbnailFile.writeAsBytes(bytes);
      
      return thumbnailFile;
    } catch (e) {
      throw Exception('Erreur lors de la création de la miniature: $e');
    }
  }

  /// Obtient le chemin de la miniature
  String getThumbnailPath(String photoId) {
    return '${_thumbnailsDir?.path}/thumb_$photoId.jpg';
  }

  /// Récupère la miniature d'une photo
  Future<File?> getThumbnail(Photo photo) async {
    final thumbnailPath = getThumbnailPath(photo.id);
    final thumbnailFile = File(thumbnailPath);
    
    if (await thumbnailFile.exists()) {
      return thumbnailFile;
    }
    
    // Si la miniature n'existe pas, on la crée
    try {
      return await createThumbnail(photo);
    } catch (e) {
      return null;
    }
  }

  /// Supprime la miniature d'une photo
  Future<void> deleteThumbnail(String photoId) async {
    final thumbnailPath = getThumbnailPath(photoId);
    final thumbnailFile = File(thumbnailPath);
    
    if (await thumbnailFile.exists()) {
      await thumbnailFile.delete();
    }
  }

  /// Nettoie le cache des miniatures
  Future<int> clearThumbnailCache() async {
    if (_thumbnailsDir == null || !await _thumbnailsDir!.exists()) {
      return 0;
    }
    
    int deletedCount = 0;
    final files = await _thumbnailsDir!.list().toList();
    
    for (final file in files) {
      if (file is File) {
        await file.delete();
        deletedCount++;
      }
    }
    
    return deletedCount;
  }

  // ==================== GESTION DU CACHE ====================

  /// Obtient une image depuis le cache
  Future<File?> getCachedImage(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Met une image dans le cache
  Future<void> cacheImage(String url) async {
    try {
      await _cacheManager.downloadFile(url);
    } catch (e) {
      // Ignore les erreurs de cache
    }
  }

  /// Nettoie le cache
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Obtient les statistiques du cache
  Future<StorageStats> getThumbnailCacheStats() async {
    if (_thumbnailsDir == null || !await _thumbnailsDir!.exists()) {
      return StorageStats(totalSizeBytes: 0, fileCount: 0);
    }
    
    int totalSize = 0;
    int fileCount = 0;
    
    final files = await _thumbnailsDir!.list().toList();
    
    for (final file in files) {
      if (file is File) {
        final stat = await file.stat();
        totalSize += stat.size;
        fileCount++;
      }
    }
    
    return StorageStats(
      totalSizeBytes: totalSize,
      fileCount: fileCount,
    );
  }

  /// Récupère les dimensions d'une image
  Future<Size> getImageDimensions(File file) async {
    // Pour l'instant, on utilise les dimensions de la Photo
    // Dans une implémentation complète, on utiliserait le package image
    // pour lire les dimensions réelles
    try {
      // Méthode simple : décoder l'image
      // Note: Cela peut être lent pour les grandes images
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      return const Size(0, 0);
    }
  }

  /// Redimensionne une image
  Future<Uint8List?> resizeImage(Uint8List imageBytes, int maxWidth, int maxHeight) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      final width = image.width;
      final height = image.height;
      
      // Calcul des nouvelles dimensions
      final ratio = width / height;
      int newWidth, newHeight;
      
      if (width > maxWidth || height > maxHeight) {
        if (ratio > 1) {
          newWidth = maxWidth;
          newHeight = (maxWidth / ratio).floor();
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * ratio).floor();
        }
      } else {
        newWidth = width;
        newHeight = height;
      }
      
      // Resize (nécessite le package image pour une implémentation complète)
      // Pour l'instant, on retourne l'image originale
      return imageBytes;
    } catch (e) {
      return null;
    }
  }

  /// Convertit une image en base64
  String bytesToBase64(Uint8List bytes) {
    return base64.encode(bytes);
  }

  /// Convertit base64 en Uint8List
  Uint8List base64ToBytes(String base64) {
    return base64Decode(base64);
  }

  /// Vérifie si un fichier est une image valide
  Future<bool> isValidImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      await ui.instantiateImageCodec(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Statistiques de stockage
class StorageStats {
  final int totalSizeBytes;
  final int fileCount;

  const StorageStats({required this.totalSizeBytes, required this.fileCount});

  double get totalSizeInMb => totalSizeBytes / (1024 * 1024);
  double get totalSizeInGb => totalSizeBytes / (1024 * 1024 * 1024);
  
  @override
  String toString() => '$fileCount files, ${totalSizeInMb.toStringAsFixed(2)} Mo';
}
