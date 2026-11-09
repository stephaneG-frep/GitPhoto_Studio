import 'package:flutter/material.dart';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';

/// Widget pour gérer le Drag & Drop de fichiers images
/// Utilise le package desktop_drop pour une intégration native
/// Fonctionne sur Desktop (Linux, Windows, macOS) et Android
class FileDropZone extends StatefulWidget {
  final Widget child;
  final Function(List<File>) onFilesDropped;
  final Color dropZoneColor;
  final Color dropZoneBorderColor;
  final double dropZoneBorderWidth;
  final String dropZoneText;
  final TextStyle? dropZoneTextStyle;
  final bool enabled;

  const FileDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
    this.dropZoneColor = Colors.blue,
    this.dropZoneBorderColor = Colors.blue,
    this.dropZoneBorderWidth = 2.0,
    this.dropZoneText = 'Déposez les images ici',
    this.dropZoneTextStyle,
    this.enabled = true,
  });

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    // Sur mobile (Android/iOS), desktop_drop ne fonctionne pas
    // On retourne juste le child
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                   defaultTargetPlatform == TargetPlatform.iOS)) {
      return widget.child;
    }

    // Pour Desktop (Linux, Windows, macOS) et Web
    return DropTarget(
      enable: widget.enabled,
      onDragEntered: (details) {
        setState(() => _isDraggingOver = true);
      },
      onDragExited: (details) {
        setState(() => _isDraggingOver = false);
      },
      onDragDone: (details) async {
        setState(() => _isDraggingOver = false);
        
        // Convertit XFile en File
        final files = <File>[];
        
        for (final xFile in details.files) {
          try {
            // Sur desktop, on peut obtenir le path
            final path = xFile.path;
            if (path != null) {
              final file = File(path);
              if (await file.exists() && await file.stat().then((stat) => stat.type == FileSystemEntityType.file)) {
                files.add(file);
              }
            }
          } catch (e) {
            // Ignore les erreurs pour un fichier
          }
        }
        
        // Si des fichiers ont été déposés, notifie le callback
        if (files.isNotEmpty) {
          widget.onFilesDropped(files);
        }
      },
      child: Stack(
        children: [
          widget.child,
          // Overlay de drop zone
          if (_isDraggingOver)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.dropZoneColor.withOpacity(0.2),
                  border: Border.all(
                    color: widget.dropZoneBorderColor,
                    width: widget.dropZoneBorderWidth,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 64,
                        color: widget.dropZoneBorderColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.dropZoneText,
                        style: widget.dropZoneTextStyle ?? TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.dropZoneBorderColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Glissez depuis votre explorateur de fichiers',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.dropZoneBorderColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Nettoyage automatique géré par DropTarget
    super.dispose();
  }
}

/// Représente un fichier de plateforme pour la compatibilité
/// (utilisé pour les tests et la compatibilité arrière)
class PlatformFile {
  final String? path;
  final String? name;
  final int? size;

  PlatformFile({this.path, this.name, this.size});
}
