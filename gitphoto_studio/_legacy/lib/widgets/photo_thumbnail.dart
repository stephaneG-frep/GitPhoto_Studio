import 'dart:io' show File;
/// Widget PhotoThumbnail amélioré avec animations pour GitPhoto Studio

import 'package:flutter/material.dart';
import '../core/models/photo_model.dart';
import 'animations/photo_animations.dart';
import '../core/config/animation_config.dart';

/// Widget de miniature de photo avec animations et interactions
class PhotoThumbnail extends StatefulWidget {
  /// La photo à afficher
  final Photo photo;

  /// Taille de la miniature
  final double size;

  /// Largeur (si différente de size)
  final double? width;

  /// Hauteur (si différente de size)
  final double? height;

  /// Mode d'affichage (cover, contain, fitWidth, fitHeight)
  final BoxFit fit;

  /// Indique si la photo est sélectionnée
  final bool isSelected;

  /// Indique si la photo est en mode sélectionnable
  final bool selectable;

  /// Callback lors de la sélection
  final ValueChanged<bool>? onSelected;

  /// Callback lors d'un tap
  final VoidCallback? onTap;

  /// Callback lors d'un double tap
  final VoidCallback? onDoubleTap;

  /// Callback lors d'un long press
  final VoidCallback? onLongPress;

  /// Couleur de bordure
  final Color? borderColor;

  /// Épaisseur de la bordure
  final double borderWidth;

  /// Rayon de la bordure
  final double borderRadius;

  /// Ombre
  final BoxShadow? shadow;

  /// Affiche l'indicateur de favori
  final bool showFavoriteIndicator;

  /// Affiche les tags
  final bool showTags;

  /// Nombre maximum de tags à afficher
  final int maxTags;

  /// Mode hover (pour desktop)
  final bool enableHover;

  /// Affiche le nom
  final bool showName;

  /// Affiche le badge favoris
  final bool showFavoriteBadge;

  /// Cache
  final bool cacheImage;

  /// Placeholder
  final Widget? placeholder;

  /// Erreur
  final Widget? errorWidget;

  /// Constructeur
  const PhotoThumbnail({
    super.key,
    required this.photo,
    this.size = 150,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isSelected = false,
    this.selectable = false,
    this.onSelected,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = 8,
    this.shadow,
    this.showFavoriteIndicator = true,
    this.showTags = false,
    this.maxTags = 3,
    this.enableHover = true,
    this.showName = false,
    this.showFavoriteBadge = true,
    this.cacheImage = true,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<PhotoThumbnail>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _selectionController;
  late Animation<double> _selectionScale;
  late Animation<Color?> _selectionBorderColor;
  late Animation<double> _selectionBorderWidth;

  @override
  void initState() {
    super.initState();
    
    _selectionController = AnimationController(
      duration: AnimationConfig.selectionDuration,
      vsync: this,
    );

    _selectionScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _selectionController,
        curve: AnimationConfig.selectionCurve,
      ),
    );

    _selectionBorderColor = ColorTween(
      begin: Colors.transparent,
      end: widget.borderColor ?? AnimationConfig.selectionColor,
    ).animate(_selectionController);

    _selectionBorderWidth = Tween<double>(
      begin: widget.borderWidth,
      end: widget.borderWidth + (widget.isSelected ? AnimationConfig.selectionBorderWidth : 0),
    ).animate(_selectionController);

    // Initialiser selon l'état
    if (widget.isSelected) {
      _selectionController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PhotoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      widget.isSelected 
          ? _selectionController.forward() 
          : _selectionController.reverse();
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _selectionController,
      builder: (context, child) {
        return MouseRegion(
          cursor: widget.enableHover 
              ? SystemMouseCursors.click 
              : MouseCursor.defer,
          onEnter: widget.enableHover 
              ? (_) => setState(() => _isHovered = true)
              : null,
          onExit: widget.enableHover 
              ? (_) => setState(() => _isHovered = false)
              : null,
          child: GestureDetector(
            onTap: () {
              if (widget.onSelected != null && widget.selectable) {
                widget.onSelected!(!widget.isSelected);
              }
              widget.onTap?.call();
            },
            onDoubleTap: widget.onDoubleTap,
            onLongPress: widget.onLongPress,
            child: _buildThumbnailContainer(),
          ),
        );
      },
    );
  }

  Widget _buildThumbnailContainer() {
    final effectiveBorderColor = _selectionBorderColor.value ?? 
        (widget.isSelected 
            ? (widget.borderColor ?? AnimationConfig.selectionColor)
            : Colors.transparent);
    
    final effectiveBorderWidth = _selectionBorderWidth.value;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        border: Border.all(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.shadow != null || _isHovered
            ? [
                widget.shadow ?? const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image principale
            _buildPhotoImage(),
            
            // Overlay de sélection
            if (widget.selectable)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: AnimationConfig.selectionDuration,
                  decoration: BoxDecoration(
                    color: widget.isSelected 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
              ),
            
            // Indicateur de favori
            if (widget.showFavoriteIndicator && widget.photo.isFavorite)
              Positioned(
                top: 4,
                right: 4,
                child: FavoriteAnimation(
                  isFavorite: widget.photo.isFavorite,
                  size: 20,
                  onToggle: () {
                    // Ne pas changer ici, juste pour l'animation
                  },
                ),
              ),
            
            // Tags
            if (widget.showTags && widget.photo.tags.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: widget.photo.tags
                        .take(widget.maxTags)
                        .map((tag) => Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ))
                        .toList(),
                  ),
                ),
              ),
            
            // Indice de sélection
            if (widget.selectable && widget.isSelected)
              Positioned(
                top: 4,
                left: 4,
                child: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoImage() {
    final imageProvider = _getImageProvider();
    
    return AnimatedScale(
      duration: AnimationConfig.hoverDuration,
      scale: widget.enableHover && _isHovered ? 1.05 : 1.0,
      child: Image(
        image: imageProvider,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return PhotoLoadingAnimation(
            size: widget.size * 0.5,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? Center(
            child: Icon(
              Icons.image_not_supported,
              size: widget.size * 0.3,
              color: Colors.grey,
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return FadeInPhoto(
              child: child,
              duration: AnimationConfig.fadeInDuration,
            );
          }
          return child;
        },
      ),
    );
  }

  ImageProvider<Object> _getImageProvider() {
    // Utiliser FileImage directement
    return FileImage(
      File(widget.photo.path),
    );
  }
}

/// Grille de miniatures avec animations
class PhotoThumbnailGrid extends StatelessWidget {
  final List<Photo> photos;
  final int crossAxisCount;
  final double thumbnailSize;
  final double spacing;
  final BoxFit fit;
  final bool selectable;
  final List<String>? selectedPhotoIds;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onTap;
  final bool enableHover;

  const PhotoThumbnailGrid({
    super.key,
    required this.photos,
    this.crossAxisCount = 3,
    this.thumbnailSize = 150,
    this.spacing = 16,
    this.fit = BoxFit.cover,
    this.selectable = false,
    this.selectedPhotoIds,
    this.onSelected,
    this.onTap,
    this.enableHover = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = selectedPhotoIds?.contains(photo.id) ?? false;

        return StaggeredAnimationBuilder.staggeredBuilder(
          context,
          index,
          (context, innerIndex) => PhotoThumbnail(
            photo: photo,
            size: thumbnailSize,
            fit: fit,
            isSelected: isSelected,
            selectable: selectable,
            enableHover: enableHover,
            onSelected: selectable ? (selected) {
              onSelected?.call(photo.id);
            } : null,
            onTap: onTap != null ? () => onTap!(photo.id) : null,
            showFavoriteIndicator: true,
          ),
        );
      },
    );
  }
}

/// Liste de miniatures avec animations
class PhotoThumbnailList extends StatelessWidget {
  final List<Photo> photos;
  final double thumbnailSize;
  final double spacing;
  final BoxFit fit;
  final Axis scrollDirection;
  final bool selectable;
  final List<String>? selectedPhotoIds;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onTap;

  const PhotoThumbnailList({
    super.key,
    required this.photos,
    this.thumbnailSize = 100,
    this.spacing = 8,
    this.fit = BoxFit.cover,
    this.scrollDirection = Axis.horizontal,
    this.selectable = false,
    this.selectedPhotoIds,
    this.onSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = selectedPhotoIds?.contains(photo.id) ?? false;

        return StaggeredAnimationBuilder.staggeredBuilder(
          context,
          index,
          (context, innerIndex) => Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : spacing,
              right: index == photos.length - 1 ? 0 : spacing,
            ),
            child: PhotoThumbnail(
              photo: photo,
              size: thumbnailSize,
              fit: fit,
              isSelected: isSelected,
              selectable: selectable,
              onSelected: selectable ? (selected) {
                onSelected?.call(photo.id);
              } : null,
              onTap: onTap != null ? () => onTap!(photo.id) : null,
            ),
          ),
        );
      },
    );
  }
}

/// Miniature avec menu contextuel
class PhotoThumbnailWithMenu extends StatelessWidget {
  final Photo photo;
  final double size;
  final List<PopupMenuEntry> menuItems;
  final VoidCallback? onTap;

  const PhotoThumbnailWithMenu({
    super.key,
    required this.photo,
    this.size = 150,
    required this.menuItems,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoThumbnail(
      photo: photo,
      size: size,
      onTap: onTap,
      onLongPress: () {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            size * 0.5,
            size * 0.5,
            size * 0.5,
            size * 0.5,
          ),
          items: menuItems,
        );
      },
    );
  }
}
