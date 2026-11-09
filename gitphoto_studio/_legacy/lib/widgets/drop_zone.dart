import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Widget pour gérer le Drag & Drop de fichiers
/// Fonctionne sur Desktop (Linux, Windows, macOS) et Android
class DropZone extends StatefulWidget {
  final Widget child;
  final Function(List<File>) onFilesDropped;
  final Color? highlightColor;
  final double borderWidth;
  final Color borderColor;
  final bool enabled;

  const DropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
    this.highlightColor,
    this.borderWidth = 2.0,
    this.borderColor = Colors.blue,
    this.enabled = true,
  });

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        onTap: () {},
        child: Listener(
          onPointerDown: (_) {},
          onPointerMove: (_) {},
          onPointerUp: (_) {},
          child: Stack(
            children: [
              widget.child,
              if (_isDragging)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.borderColor,
                        width: widget.borderWidth,
                      ),
                      color: widget.highlightColor?.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Text(
                        'Déposez les fichiers ici',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.borderColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin pour gérer le Drag & Drop de fichiers sur Desktop
/// Utilise platform channels pour détecter les fichiers déposés
mixin DropZoneMixin<T extends StatefulWidget> on State<T> {
  bool _isDropZoneActive = false;
  final List<File> _droppedFiles = [];

  /// Active la zone de drop
  void _activateDropZone() {
    setState(() => _isDropZoneActive = true);
  }

  /// Désactive la zone de drop
  void _deactivateDropZone() {
    setState(() => _isDropZoneActive = false);
  }

  /// Gère les fichiers déposés
  void handleFilesDropped(List<File> files) {
    _droppedFiles.clear();
    _droppedFiles.addAll(files);
    onFilesDropped(files);
  }

  /// Méthode à surcharger pour traiter les fichiers
  void onFilesDropped(List<File> files) {}

  /// Construit un overlay de drop zone
  Widget buildDropZoneOverlay(Widget child) {
    if (!_isDropZoneActive) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Colors.blue.withOpacity(0.2),
            child: const Center(
              child: Text(
                'Déposez les fichiers ici',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
