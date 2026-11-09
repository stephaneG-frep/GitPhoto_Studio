import 'package:file_selector/file_selector.dart';

import 'media_importer.dart';

/// Source de fichiers à importer. Implémentation réelle : sélecteur système.
abstract interface class MediaPicker {
  /// Liste vide si l'utilisateur annule.
  Future<List<ImportCandidate>> pick();
}

/// Sélecteur système via `file_selector` : dialogue GTK sous Linux,
/// sélecteur de documents sous Android (aucune permission de stockage).
class FileSelectorMediaPicker implements MediaPicker {
  const FileSelectorMediaPicker();

  static const _group = XTypeGroup(
    label: 'Photos et vidéos',
    mimeTypes: ['image/*', 'video/*'],
    extensions: [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
      'tif',
      'tiff',
      'mp4',
      'mov',
      'm4v',
      'webm',
      'mkv',
      '3gp',
      'avi',
    ],
  );

  @override
  Future<List<ImportCandidate>> pick() async {
    final files = await openFiles(acceptedTypeGroups: const [_group]);
    return [
      for (final f in files) ImportCandidate(f.path, displayName: f.name),
    ];
  }
}
