/// Animations pour les photos dans GitPhoto Studio
/// Inclut les animations de sélection, de transition, et d'effets visuels

import 'package:flutter/material.dart';
import '../../core/models/photo_model.dart';

/// Animation de sélection multiple
class SelectionAnimation extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Duration duration;
  final VoidCallback? onSelected;

  const SelectionAnimation({
    super.key,
    required this.child,
    required this.isSelected,
    this.duration = const Duration(milliseconds: 200),
    this.onSelected,
  });

  @override
  State<SelectionAnimation> createState() => _SelectionAnimationState();
}

class _SelectionAnimationState extends State<SelectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _borderWidthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _borderColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.blue,
    ).animate(_controller);

    _borderWidthAnimation = Tween<double>(begin: 0, end: 3).animate(_controller);

    // Démarrer l'animation selon l'état initial
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SelectionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      widget.isSelected ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onSelected,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _borderColorAnimation.value ?? Colors.transparent,
                width: _borderWidthAnimation.value,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Animation de survol (hover) pour les photos
class HoverAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scale;

  const HoverAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
    this.scale = 1.05,
  });

  @override
  State<HoverAnimation> createState() => _HoverAnimationState();
}

class _HoverAnimationState extends State<HoverAnimation> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: widget.duration,
        scale: _isHovered ? widget.scale : 1.0,
        child: widget.child,
      ),
    );
  }
}

/// Animation de chargement pour les photos
class PhotoLoadingAnimation extends StatelessWidget {
  final double size;
  final Color color;

  const PhotoLoadingAnimation({
    super.key,
    this.size = 50,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Arrière-plan
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Animation de chargement
          Center(
            child: SizedBox(
              width: size * 0.6,
              height: size * 0.6,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animation d'apparence progressive pour les photos
class FadeInPhoto extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const FadeInPhoto({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 20,
  });

  @override
  State<FadeInPhoto> createState() => _FadeInPhotoState();
}

class _FadeInPhotoState extends State<FadeInPhoto>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animation de like/favorite
class FavoriteAnimation extends StatefulWidget {
  final bool isFavorite;
  final Duration duration;
  final VoidCallback onToggle;
  final double size;
  final Color? color;

  const FavoriteAnimation({
    super.key,
    required this.isFavorite,
    this.duration = const Duration(milliseconds: 300),
    required this.onToggle,
    this.size = 24,
    this.color,
  });

  @override
  State<FavoriteAnimation> createState() => _FavoriteAnimationState();
}

class _FavoriteAnimationState extends State<FavoriteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: widget.color ?? Colors.red,
    ).animate(_controller);

    if (widget.isFavorite) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FavoriteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            widget.onToggle();
            _controller.forward(from: 0);
          },
          child: Icon(
            Icons.favorite,
            size: widget.size,
            color: widget.isFavorite
                ? (widget.color ?? Colors.red)
                : Colors.grey,
          ),
        );
      },
    );
  }
}

/// Animation de transition entre pages (pour la galerie)
class PageTransitionAnimation extends PageRouteBuilder {
  final Widget child;

  PageTransitionAnimation({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOut;

            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Animation de charnement de la galerie
class GalleryLoadAnimation extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration duration;

  const GalleryLoadAnimation({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<GalleryLoadAnimation> createState() => _GalleryLoadAnimationState();
}

class _GalleryLoadAnimationState extends State<GalleryLoadAnimation> {
  final List<bool> _visibleItems = [];
  late Duration _staggeredDuration;

  @override
  void initState() {
    super.initState();
    _visibleItems.addAll(List.filled(widget.itemCount, false));
    _staggeredDuration = Duration(
      milliseconds: widget.duration.inMilliseconds ~/ widget.itemCount,
    );

    // Démarrer les animations de manière décalée
    Future.delayed(Duration.zero, () {
      for (int i = 0; i < widget.itemCount; i++) {
        Future.delayed(
          Duration(milliseconds: i * 50),
          () {
            if (mounted) {
              setState(() => _visibleItems[i] = true);
            }
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return _visibleItems[index]
            ? widget.itemBuilder(context, index)
            : const SizedBox();
      },
    );
  }
}

/// Animation de suppression
class DeleteAnimation extends StatefulWidget {
  final Widget child;
  final bool isDeleting;
  final Duration duration;
  final VoidCallback? onDeleteComplete;

  const DeleteAnimation({
    super.key,
    required this.child,
    this.isDeleting = false,
    this.duration = const Duration(milliseconds: 300),
    this.onDeleteComplete,
  });

  @override
  State<DeleteAnimation> createState() => _DeleteAnimationState();
}

class _DeleteAnimationState extends State<DeleteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);

    if (widget.isDeleting) {
      _controller.forward().then((_) {
        widget.onDeleteComplete?.call();
      });
    }
  }

  @override
  void didUpdateWidget(DeleteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeleting != oldWidget.isDeleting && widget.isDeleting) {
      _controller.forward().then((_) {
        widget.onDeleteComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Animation de drag & drop
class DragDropAnimation extends StatefulWidget {
  final Widget child;
  final bool isDraggingOver;
  final Duration duration;

  const DragDropAnimation({
    super.key,
    required this.child,
    this.isDraggingOver = false,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<DragDropAnimation> createState() => _DragDropAnimationState();
}

class _DragDropAnimationState extends State<DragDropAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _borderWidthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _backgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.blue.withOpacity(0.1),
    ).animate(_controller);

    _borderWidthAnimation = Tween<double>(begin: 0, end: 2).animate(_controller);

    if (widget.isDraggingOver) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(DragDropAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDraggingOver != oldWidget.isDraggingOver) {
      widget.isDraggingOver ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _backgroundColorAnimation.value,
            border: Border.all(
              color: Colors.blue,
              width: _borderWidthAnimation.value,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Animation de feedback pour les actions
class FeedbackAnimation extends StatefulWidget {
  final Widget child;
  final bool showFeedback;
  final IconData feedbackIcon;
  final Color feedbackColor;

  const FeedbackAnimation({
    super.key,
    required this.child,
    this.showFeedback = false,
    this.feedbackIcon = Icons.check,
    this.feedbackColor = Colors.green,
  });

  @override
  State<FeedbackAnimation> createState() => _FeedbackAnimationState();
}

class _FeedbackAnimationState extends State<FeedbackAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    if (widget.showFeedback) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FeedbackAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFeedback != oldWidget.showFeedback && widget.showFeedback) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (widget.showFeedback)
          Positioned.fill(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  widget.feedbackIcon,
                  size: 40,
                  color: widget.feedbackColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Animation de chargement pour les opérations IA
class AILoadingAnimation extends StatelessWidget {
  final double size;
  final Color color;

  const AILoadingAnimation({
    super.key,
    this.size = 40,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Cercle 1
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: size * 0.8,
                height: size * 0.8,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(size * 0.4),
                ),
              ),
            ),
          ),
          // Cercle 2 (animation)
          Center(
            child: SizedBox(
              width: size * 0.6,
              height: size * 0.6,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          // Icône IA
          Center(
            child: Icon(
              Icons.auto_awesome,
              size: size * 0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animation de prograssion pour les opérations batch
class BatchProgressAnimation extends StatefulWidget {
  final int current;
  final int total;
  final Duration duration;

  const BatchProgressAnimation({
    super.key,
    required this.current,
    required this.total,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<BatchProgressAnimation> createState() => _BatchProgressAnimationState();
}

class _BatchProgressAnimationState extends State<BatchProgressAnimation> {
  @override
  Widget build(BuildContext context) {
    final progress = widget.total > 0 ? widget.current / widget.total : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.current}/${widget.total} (${(progress * 100).toStringAsFixed(0)}%)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
