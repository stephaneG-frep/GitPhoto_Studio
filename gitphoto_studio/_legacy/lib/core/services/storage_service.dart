import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/photo_model.dart';

/// Service pour gérer le stockage des photos et albums
class StorageService {
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() => _instance;
  
  StorageService._internal();

  Directory? _appDocumentsDir;
  Directory? _photosDir;
  Directory? _thumbnailsDir;

  /// Initialise les répertoires de stockage
  Future<void> initialize() async {
    _appDocumentsDir = await getApplicationDocumentsDirectory();
    _photosDir = Directory('${_appDocumentsDir!.path}/photos');
    _thumbnailsDir = Directory('${_appDocumentsDir!.path}/thumbnails');

    // Crée les répertoires s'ils n'existent pas
    if (!await _photosDir!.exists()) {
      await _photosDir!.create(recursive: true);
    }
    
    if (!await _thumbnailsDir!.exists()) {
      await _thumbnailsDir!.create(recursive: true);
    }
  }

  /// Vérifie que les répertoires sont initialisés
  Future<void> _ensureInitialized() async {
    if (_appDocumentsDir == null) {
      await initialize();
    }
  }

  /// Obtient le répertoire des photos
  Directory get photosDirectory => _photosDir!;

  /// Obtient le répertoire des miniatures
  Directory get thumbnailsDirectory => _thumbnailsDir!;

  // ==================== GESTION DES PHOTOS ====================

  /// Sauvegarde une photo dans le stockage
  Future<Photo> savePhoto({
    required File sourceFile,
    String? albumId,
  }) async {
    await _ensureInitialized();
    
    try {
      // Génère un ID unique
      final photoId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Crée le chemin de destination
      final extension = _getFileExtension(sourceFile.path);
      final destinationPath = '${_photosDir!.path}/$photoId$extension';
      final destinationFile = File(destinationPath);
      
      // Copie le fichier
      await sourceFile.copy(destinationFile.path);
      
      // Récupère les métadonnées du fichier
      final stat = await sourceFile.stat();
      final dateCreated = DateTime.now();
      final dateModified = DateTime.now();
      
      // Crée l'objet Photo
      return Photo(
        id: photoId,
        path: destinationPath,
        name: _getFileNameWithoutExtension(sourceFile.path),
        dateCreated: dateCreated,
        dateModified: dateModified,
        sizeBytes: stat.size,
        width: 0,
        height: 0,
        albumId: albumId,
        isFavorite: false,
        rating: 0,
      );
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la photo: $e');
    }
  }

  /// Liste toutes les photos
  Future<List<Photo>> listAllPhotos() async {
    await _ensureInitialized();
    
    try {
      final files = await _photosDir!.list().toList();
      final photos = <Photo>[];
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final photoId = _getFileNameWithoutExtension(file.path);
          
          // Note: On utilise la date de modification comme date de création
          // pour simplifier
          photos.add(Photo(
            id: photoId,
            path: file.path,
            name: _getFileNameWithoutExtension(file.path),
            dateCreated: stat.modified,
            dateModified: stat.modified,
            sizeBytes: stat.size,
            width: 0,
            height: 0,
            albumId: null,
            isFavorite: false,
            rating: 0,
          ));
        }
      }
      
      return photos;
    } catch (e) {
      throw Exception('Erreur lors du listage des photos: $e');
    }
  }

  /// Supprime une photo
  Future<bool> deletePhoto(Photo photo) async {
    await _ensureInitialized();
    
    try {
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Supprime toutes les photos
  Future<int> deleteAllPhotos() async {
    await _ensureInitialized();
    
    try {
      final files = await _photosDir!.list().toList();
      int deletedCount = 0;
      
      for (final file in files) {
        if (file is File) {
          await file.delete();
          deletedCount++;
        }
      }
      
      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  // ==================== GESTION DES ALBUMS ====================

  /// Crée un répertoire pour un album
  Future<Directory> createAlbumDirectory(String albumId) async {
    await _ensureInitialized();
    
    final albumDir = Directory('${_photosDir!.path}/$albumId');
    
    if (!await albumDir.exists()) {
      await albumDir.create(recursive: true);
    }
    
    return albumDir;
  }

  /// Liste tous les albums (répertoires)
  Future<List<String>> listAllAlbums() async {
    await _ensureInitialized();
    
    try {
      final dirs = await _photosDir!.list().toList();
      final albumIds = <String>[];
      
      for (final dir in dirs) {
        if (dir is Directory) {
          final dirName = _getFileNameWithoutExtension(dir.path);
          // Ignore les répertoires système
          if (dirName.isNotEmpty && !dirName.startsWith('.')) {
            albumIds.add(dirName);
          }
        }
      }
      
      return albumIds;
    } catch (e) {
      return [];
    }
  }

  /// Supprime un répertoire d'album
  Future<bool> deleteAlbumDirectory(String albumId) async {
    await _ensureInitialized();
    
    try {
      final albumDir = Directory('${_photosDir!.path}/$albumId');
      
      if (await albumDir.exists()) {
        await albumDir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== STATISTIQUES ====================

  /// Récupère les statistiques de stockage
  Future<StorageStats> getStorageStats() async {
    await _ensureInitialized();
    
    try {
      int totalSize = 0;
      int photoCount = 0;
      
      final files = await _photosDir!.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
          photoCount++;
        }
      }
      
      return StorageStats(
        totalSizeBytes: totalSize,
        fileCount: photoCount,
      );
    } catch (e) {
      return StorageStats(totalSizeBytes: 0, fileCount: 0);
    }
  }

  // ==================== UTILITAIRES ====================

  /// Extrait le nom de fichier sans extension
  String _getFileNameWithoutExtension(String path) {
    final fileName = path.split('/').last;
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  /// Extrait l'extension du fichier
  String _getFileExtension(String path) {
    final fileName = path.split('/').last;
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(lastDot);
    }
    return '';
  }

  /// Vérifie si un fichier existe
  Future<bool> fileExists(String path) async {
    final file = File(path);
    return await file.exists();
  }
}

/// Statistiques de stockage
class StorageStats {
  final int totalSizeBytes;
  final int fileCount;

  StorageStats({required this.totalSizeBytes, required this.fileCount});

  double get totalSizeInMb => totalSizeBytes / (1024 * 1024);
  double get totalSizeInGb => totalSizeBytes / (1024 * 1024 * 1024);
  
  @override
  String toString() => '$fileCount files, ${totalSizeInMb.toStringAsFixed(2)} Mo';
}
