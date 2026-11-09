import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../services/storage_service.dart';
import '../services/photo_service.dart';
import '../services/album_service.dart';
import '../services/ai_service.dart';
import '../services/photo_manager_service.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';

/// Fournisseur pour les services de l'application
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final photoManagerServiceProvider = Provider<PhotoManagerService>((ref) {
  return PhotoManagerService(
    storageService: ref.watch(storageServiceProvider),
    databaseService: ref.watch(databaseServiceProvider),
    imageService: ref.watch(imageServiceProvider),
    aiService: ref.watch(aiServiceProvider),
  );
});

final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService(
    storageService: ref.watch(storageServiceProvider),
  );
});

final albumServiceProvider = Provider<AlbumService>((ref) {
  return AlbumService(
    storageService: ref.watch(storageServiceProvider),
  );
});

/// État pour les photos
final photosProvider = FutureProvider<List<Photo>>((ref) async {
  final photoManager = ref.watch(photoManagerServiceProvider);
  await photoManager.initialize();
  return await photoManager.getAllPhotos();
});

/// État pour les albums
final albumsProvider = FutureProvider<List<Album>>((ref) async {
  final albumService = ref.watch(albumServiceProvider);
  await albumService.initialize();
  return albumService.getAllAlbums();
});

/// État pour la photo sélectionnée
final selectedPhotoProvider = StateProvider<Photo?>((ref) => null);

/// État pour l'album sélectionné
final selectedAlbumProvider = StateProvider<Album?>((ref) => null);

/// État pour le mode d'affichage (grille/liste)
final viewModeProvider = StateProvider<String>((ref) => 'grid');

/// État pour le filtre de photos
final photoFilterProvider = StateProvider<String>((ref) => 'all');

/// État pour la barre de recherche
final searchQueryProvider = StateProvider<String>((ref) => '');

/// État pour le mode sombre
final darkModeProvider = StateProvider<bool>((ref) => false);

/// État pour la langue
final localeProvider = StateProvider<String>((ref) => 'fr');

/// État pour la connectivité IA
final aiConnectedProvider = StateProvider<bool>((ref) => false);

/// État pour le chargement
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// État pour les erreurs
final errorMessageProvider = StateProvider<String?>((ref) => null);
