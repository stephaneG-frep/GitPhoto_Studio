import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/models/photo_model.dart';
import '../../core/models/album_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/photo_manager_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/photo_thumbnail.dart';
import '../../widgets/file_drop_zone.dart';
import '../../widgets/animations/photo_animations.dart';
import '../../core/config/animation_config.dart';
import '../ai_analysis/ai_analysis_page.dart';
import '../home/home_page.dart';
import 'photo_viewer.dart';

/// Page de la galerie photo
class GalleryPage extends ConsumerStatefulWidget {
  final String? albumId;

  const GalleryPage({super.key, this.albumId});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  String _viewMode = 'grid';
  String _filter = 'all';
  final Set<String> _selectedPhotos = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Charge les données initiales
  void _loadData() async {
    await ref.refresh(photosProvider);
    await ref.refresh(albumsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(photosProvider);
    final albumsAsync = ref.watch(albumsProvider);

    return FileDropZone(
      onFilesDropped: _handleFilesDropped,
      dropZoneColor: Colors.blue,
      dropZoneBorderColor: AppTheme.primaryColor,
      dropZoneText: 'Déposez les images ici pour les importer',
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Barre d'outils
            if (!_isSelectionMode) _buildToolbar(),
            
            // Filtres
            if (!_isSelectionMode) _buildFilters(),
            
            // Liste des photos
            Expanded(
              child: photosAsync.when(
                loading: () => _buildLoading(),
                error: (error, stack) => _buildError(error.toString()),
                data: (photos) => _buildPhotoThumbnailGridWithAnimations(photos, albumsAsync),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// Gère les fichiers déposés via Drag & Drop
  Future<void> _handleFilesDropped(List<File> files) async {
    final photoManager = PhotoManagerService();
    await photoManager.initialize();
    
    int importedCount = 0;
    
    for (final file in files) {
      // Vérifie que c'est une image (par extension)
      final extension = file.path.split('.').last.toLowerCase();
      final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff'];
      
      if (imageExtensions.contains(extension)) {
        try {
          // Importe le fichier
          final photo = await photoManager.savePhoto(
            sourceFile: file,
            albumId: widget.albumId,
          );
          
          if (photo != null) {
            importedCount++;
          }
        } catch (e) {
          // Ignore les erreurs pour un fichier
        }
      }
    }
    
    // Rafraîchit la liste
    ref.refresh(photosProvider);
    
    if (importedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$importedCount image(s) importée(s) par Drag & Drop'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune image valide trouvée'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Construit l'AppBar
  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        title: Text('${_selectedPhotos.length} sélectionné(s)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSelectedPhotos,
            tooltip: 'Supprimer la sélection',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Partager les photos sélectionnées
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage à implémenter')),
              );
            },
            tooltip: 'Partager',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() {
              _selectedPhotos.clear();
              _isSelectionMode = false;
            }),
            tooltip: 'Annuler la sélection',
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text(widget.albumId == null ? 'Toutes les photos' : 'Album'),
        actions: [
          IconButton(
            icon: Icon(_viewMode == 'grid' ? Icons.view_list : Icons.view_module),
            onPressed: () => setState(() => _viewMode = _viewMode == 'grid' ? 'list' : 'grid'),
            tooltip: _viewMode == 'grid' ? 'Vue liste' : 'Vue grille',
          ),
        ],
      );
    }
  }

  /// Construit la barre d'outils
  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Bouton de menu
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 16),
          
          // Titre
          Expanded(
            child: Text(
              widget.albumId == null ? 'Toutes les photos' : 'Album',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Selecteur de vue
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.view_module),
                onPressed: () => setState(() => _viewMode = 'grid'),
                color: _viewMode == 'grid' ? AppTheme.primaryColor : Colors.grey,
                tooltip: 'Vue grille',
              ),
              IconButton(
                icon: const Icon(Icons.view_list),
                onPressed: () => setState(() => _viewMode = 'list'),
                color: _viewMode == 'list' ? AppTheme.primaryColor : Colors.grey,
                tooltip: 'Vue liste',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit les filtres
  Widget _buildFilters() {
    final albumsAsync = ref.watch(albumsProvider);
    
    return albumsAsync.when(
      loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
      error: (error, stack) => const SizedBox(height: 50),
      data: (albums) => SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildFilterChip('Toutes', 'all'),
            _buildFilterChip('Favoris', 'favorites'),
            _buildFilterChip('Récents', 'recent'),
            const SizedBox(width: 8),
            // Albums
            ...albums.take(5).map((album) => 
              _buildFilterChip(album.name, album.id)
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un chip de filtre
  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (selected) => setState(() => _filter = selected ? value : 'all'),
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: _filter == value ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  /// Construit l'affichage de chargement
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des photos...'),
        ],
      ),
    );
  }

  /// Construit l'affichage d'erreur
  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erreur: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(photosProvider),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// Construit la grille de photos avec animations
  Widget _buildPhotoThumbnailGridWithAnimations(List<Photo> photos, AsyncValue<List<Album>> albumsAsync) {
    List<Photo> filteredPhotos = _filterPhotos(photos);
    
    if (filteredPhotos.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedSwitcher(
      duration: AnimationConfig.normal,
      child: _viewMode == 'grid' 
          ? _buildGridViewWithAnimations(filteredPhotos)
          : _buildListView(filteredPhotos),
      switchInCurve: AnimationConfig.easeInOut,
      switchOutCurve: AnimationConfig.easeInOut,
    );
  }

  /// Construit la grille de photos avec animations
  Widget _buildGridViewWithAnimations(List<Photo> photos) {
    return PhotoThumbnailGrid(
      photos: photos,
      crossAxisCount: 3,
      thumbnailSize: 150,
      spacing: 16,
      fit: BoxFit.cover,
      selectable: _isSelectionMode,
      selectedPhotoIds: _selectedPhotos.toList(),
      onSelected: (photoId) => _handlePhotoSelection(photoId),
      onTap: (photoId) => _handlePhotoTapById(photoId, photos),
      enableHover: true,
    );
  }

  /// Filtre les photos
  List<Photo> _filterPhotos(List<Photo> photos) {
    switch (_filter) {
      case 'favorites':
        return photos.where((photo) => photo.isFavorite).toList();
      case 'recent':
        return photos
            .where((photo) => photo.dateCreated.isAfter(
              DateTime.now().subtract(const Duration(days: 7))
            ))
            .toList();
      default:
        if (_filter != 'all' && widget.albumId == null) {
          return photos.where((photo) => photo.albumId == _filter).toList();
        }
        if (widget.albumId != null) {
          return photos.where((photo) => photo.albumId == widget.albumId).toList();
        }
        return photos;
    }
  }

  /// Construit l'affichage vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _filter == 'all' 
                ? 'Aucune photo trouvée' 
                : 'Aucune photo dans cette catégorie',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (_filter == 'all')
            const Text(
              'Appuyez sur + pour importer une photo',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  /// Construit la vue grille
  Widget _buildGridView(List<Photo> photos) {
    return PhotoThumbnailGrid(
      photos: photos,
      crossAxisCount: 3,
      spacing: 16.0,
      showFavoriteIndicator: true,
      showName: false,
      onPhotoTap: (photo) => _handlePhotoTap(photo),
      onPhotoLongPress: (photo) => _handlePhotoLongPress(photo),
    );
  }

  /// Construit la vue liste
  Widget _buildListView(List<Photo> photos) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = _selectedPhotos.contains(photo.id);
        
        return GestureDetector(
          onTap: () => _handlePhotoTap(photo),
          onLongPress: () => _handlePhotoLongPress(photo),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: isSelected ? 8 : 2,
            borderOnForeground: isSelected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected 
                  ? BorderSide(color: AppTheme.primaryColor, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Miniature
                  PhotoThumbnail(
                    photo: photo,
                    width: 80,
                    height: 80,
                    showFavoriteIndicator: false,
                    showName: false,
                    onTap: null,
                    onLongPress: null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${photo.dateCreated.toString().split(' ').first}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${photo.width}x${photo.height} - ${photo.sizeInMb.toStringAsFixed(2)} Mo',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge favoris
                  if (photo.isFavorite)
                    const Icon(Icons.favorite, color: Colors.red),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Gère le tap sur une photo par ID
  void _handlePhotoTapById(String photoId, List<Photo> photos) {
    final photo = photos.firstWhere((p) => p.id == photoId);
    _handlePhotoTap(photo);
  }

  /// Gère la sélection d'une photo
  void _handlePhotoSelection(String photoId) {
    setState(() {
      if (_selectedPhotos.contains(photoId)) {
        _selectedPhotos.remove(photoId);
        if (_selectedPhotos.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPhotos.add(photoId);
        _isSelectionMode = true;
      }
    });
  }

  /// Gère le tap sur une photo
  void _handlePhotoTap(Photo photo) {
    if (_isSelectionMode) {
      _handlePhotoSelection(photo.id);
    } else {
      _showPhotoDetails(photo);
    }
  }

  /// Gère le long press sur une photo
  void _handlePhotoLongPress(Photo photo) {
    setState(() {
      _isSelectionMode = true;
      _selectedPhotos.add(photo.id);
    });
  }

  /// Affiche les détails d'une photo
  void _showPhotoDetails(Photo photo) {
    ref.read(selectedPhotoProvider.notifier).state = photo;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewer(
          photo: photo,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// Affiche les options pour une photo
  void _showPhotoOptions(Photo photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Options de la photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                title: Text(photo.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'),
                onTap: () {
                  _toggleFavorite(photo);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analyse IA'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    PageTransitionAnimation(
                      child: AIAnalysisPage(photoId: photo.id),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  _deletePhoto(photo);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Basculer le favori
  void _toggleFavorite(Photo photo) async {
    final photoManager = PhotoManagerService();
    await photoManager.initialize();
    
    final updatedPhoto = await photoManager.toggleFavorite(photo);
    
    ref.read(selectedPhotoProvider.notifier).state = updatedPhoto;
    ref.refresh(photosProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedPhoto.isFavorite 
            ? 'Ajouté aux favoris' 
            : 'Retiré des favoris',
        ),
      ),
    );
  }

  /// Supprime une photo
  void _deletePhoto(Photo photo) async {
    final photoManager = PhotoManagerService();
    await photoManager.initialize();
    
    // Demande confirmation
    if (!(await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${photo.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ))) {
      return;
    }
    
    final success = await photoManager.deletePhoto(photo);
    
    if (success) {
      ref.refresh(photosProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo supprimée'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la suppression'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Supprime les photos sélectionnées
  void _deleteSelectedPhotos() async {
    final photoManager = PhotoManagerService();
    await photoManager.initialize();
    
    final photos = await ref.read(photosProvider.future);
    
    final photosToDelete = photos.where((p) => _selectedPhotos.contains(p.id)).toList();
    
    if (photosToDelete.isEmpty) return;
    
    // Demande confirmation
    if (!(await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${photosToDelete.length} photo(s)'),
        content: const Text('Êtes-vous sûr de vouloir supprimer les photos sélectionnées ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ))) {
      return;
    }
    
    final successCount = await photoManager.deleteMultiplePhotos(photosToDelete);
    
    setState(() {
      _selectedPhotos.clear();
      _isSelectionMode = false;
    });
    
    ref.refresh(photosProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$successCount photo(s) supprimée(s)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Construit le FAB
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showImportOptions();
      },
      tooltip: 'Importer',
      child: const Icon(Icons.add),
    );
  }

  /// Affiche les options d'import
  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Importer une photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Depuis la galerie'),
                subtitle: const Text('Sélectionner une photo existante'),
                onTap: () {
                  Navigator.pop(context);
                  _importFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Utiliser la caméra'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Importe depuis la galerie
  void _importFromGallery() async {
    final photoManager = PhotoManagerService();
    await photoManager.initialize();
    
    try {
      final photo = await photoManager.importFromGallery(
        albumId: widget.albumId,
      );
      
      if (photo != null) {
        ref.refresh(photosProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo importée: ${photo.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Prend une photo
  void _takePhoto() async {
    final photoManager = PhotoManagerService();
    await photoManager.initialize();
    
    try {
      final photo = await photoManager.takePhoto(
        albumId: widget.albumId,
      );
      
      if (photo != null) {
        ref.refresh(photosProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo prise: ${photo.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
