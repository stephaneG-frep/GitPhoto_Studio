import 'dart:io';

import 'package:path/path.dart' as p;

import 'media_importer.dart';

/// Transforme des chemins déposés (fichiers ou dossiers) en candidats à
/// l'import. Les dossiers sont parcourus récursivement, sans suivre les liens
/// symboliques ; les fichiers cachés sont ignorés.
List<ImportCandidate> expandDroppedPaths(
  Iterable<String> paths, {
  int maxFiles = 5000,
}) {
  final result = <ImportCandidate>[];
  for (final path in paths) {
    if (result.length >= maxFiles) break;
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.file) {
      result.add(ImportCandidate(path));
    } else if (type == FileSystemEntityType.directory) {
      final files =
          Directory(path)
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where(
                (f) => !p
                    .split(p.relative(f.path, from: path))
                    .any((part) => part.startsWith('.')),
              )
              .map((f) => f.path)
              .toList()
            ..sort();
      for (final f in files) {
        if (result.length >= maxFiles) break;
        result.add(ImportCandidate(f));
      }
    }
  }
  return result;
}
