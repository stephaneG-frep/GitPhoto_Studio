import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';
import 'storage_service.dart';

/// Service pour gérer les photos
class PhotoService {
  final StorageService _storageService;
  
  PhotoService({StorageService? storageService}) 
      : _storageService = storageService ?? StorageService();

  /// Charge toutes les photos depuis le stockage local
  Future<List<Photo>> loadAllPhotos() async {
    await _storageService.initialize();
    return await _storageService.listAllPhotos();
  }

  /// Charge les photos depuis la galerie du téléphone
  Future<List<Photo>> loadPhotosFromGallery() async {
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    
    if (albums.isEmpty) return [];
    
    final recentAlbum = albums.first;
    final recentAssets = await recentAlbum.getAssetListRange(
      start: 0,
      end: 100,
      type: RequestType.image,
    );
    
    return recentAssets.map((asset) => _assetToPhoto(asset)).toList();
  }

  /// Convertit un Asset en Photo
  Photo _assetToPhoto(AssetEntity asset) {
    // Pour l'instant, créons une photo factice avec les infos disponibles
    return Photo(
      id: asset.id,
      path: '/storage/emulated/0/DCIM/${asset.title ?? 'photo_${asset.id}'}',
      name: asset.title ?? 'Photo ${asset.id}',
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
      sizeBytes: 0,
      width: 0,
      height: 0,
      isFavorite: false,
      rating: 0,
    );
  }

  /// Importe une photo depuis la galerie
  Future<Photo?> importPhotoFromGallery() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    
    if (result != null) {
      final file = File(result.path);
      return await _storageService.savePhoto(sourceFile: file);
    }
    return null;
  }

  /// Prend une photo avec la caméra
  Future<Photo?> takePhotoWithCamera() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera);
    
    if (result != null) {
      final file = File(result.path);
      return await _storageService.savePhoto(sourceFile: file);
    }
    return null;
  }

  /// Supprime une photo
  Future<bool> deletePhoto(Photo photo) async {
    return await _storageService.deletePhoto(photo);
  }

  /// Met à jour une photo
  Future<Photo> updatePhoto(Photo photo, {
    String? description,
    List<String>? tags,
    String? albumId,
    bool? isFavorite,
    int? rating,
  }) async {
    return photo.copyWith(
      description: description ?? photo.description,
      tags: tags ?? photo.tags,
      albumId: albumId ?? photo.albumId,
      isFavorite: isFavorite ?? photo.isFavorite,
      rating: rating ?? photo.rating,
    );
  }

  /// Recherche des photos par tag
  Future<List<Photo>> searchPhotosByTag(String tag) async {
    final allPhotos = await loadAllPhotos();
    return allPhotos
        .where((photo) => 
          photo.tags != null && 
          photo.tags!.any((t) => t.toLowerCase().contains(tag.toLowerCase()))
        )
        .toList();
  }

  /// Recherche des photos par nom
  Future<List<Photo>> searchPhotosByName(String query) async {
    final allPhotos = await loadAllPhotos();
    return allPhotos
        .where((photo) => 
          photo.name.toLowerCase().contains(query.toLowerCase())
        )
        .toList();
  }

  /// Récupère les photos favorites
  Future<List<Photo>> getFavoritePhotos() async {
    final allPhotos = await loadAllPhotos();
    return allPhotos.where((photo) => photo.isFavorite).toList();
  }

  /// Récupère les photos par album
  Future<List<Photo>> getPhotosByAlbum(String albumId) async {
    final allPhotos = await loadAllPhotos();
    return allPhotos.where((photo) => photo.albumId == albumId).toList();
  }

  /// Trie les photos par date
  List<Photo> sortPhotosByDate(List<Photo> photos, {bool descending = true}) {
    return photos.toList()
      ..sort((a, b) => descending 
          ? b.dateCreated.compareTo(a.dateCreated) 
          : a.dateCreated.compareTo(b.dateCreated));
  }

  /// Trie les photos par nom
  List<Photo> sortPhotosByName(List<Photo> photos, {bool descending = false}) {
    return photos.toList()
      ..sort((a, b) => descending 
          ? b.name.compareTo(a.name) 
          : a.name.compareTo(b.name));
  }

  /// Trie les photos par taille
  List<Photo> sortPhotosBySize(List<Photo> photos, {bool descending = true}) {
    return photos.toList()
      ..sort((a, b) => descending 
          ? b.sizeBytes.compareTo(a.sizeBytes) 
          : a.sizeBytes.compareTo(b.sizeBytes));
  }

  /// Trie les photos par note
  List<Photo> sortPhotosByRating(List<Photo> photos, {bool descending = true}) {
    return photos.toList()
      ..sort((a, b) => descending 
          ? b.rating.compareTo(a.rating) 
          : a.rating.compareTo(b.rating));
  }
}
