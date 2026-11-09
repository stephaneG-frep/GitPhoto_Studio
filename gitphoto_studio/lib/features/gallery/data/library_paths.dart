import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/security/path_validator.dart';

/// Emplacements gérés par l'application.
///
/// - [mediaDir] : copies de travail des médias importés ;
/// - [thumbnailDir] : miniatures ;
/// - [temporaryDir] : cache de l'application. Sous Android, le sélecteur
///   système y dépose une copie des fichiers choisis ; seules ces copies
///   temporaires peuvent être supprimées après import.
class LibraryPaths {
  LibraryPaths({required String root, required this.temporaryDir})
    : mediaDir = p.join(root, 'library', 'media'),
      thumbnailDir = p.join(root, 'library', 'thumbnails');

  final String mediaDir;
  final String thumbnailDir;
  final String? temporaryDir;

  void ensureCreated() {
    Directory(mediaDir).createSync(recursive: true);
    Directory(thumbnailDir).createSync(recursive: true);
  }

  bool isManaged(String path) =>
      PathValidator.isWithinDirectory(mediaDir, path) ||
      PathValidator.isWithinDirectory(thumbnailDir, path);

  bool isTemporaryCopy(String path) {
    final tmp = temporaryDir;
    return tmp != null && PathValidator.isWithinDirectory(tmp, path);
  }
}
