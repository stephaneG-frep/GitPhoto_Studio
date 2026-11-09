import 'dart:convert';

import 'package:path/path.dart' as p;

/// Problèmes détectables dans un chemin de dépôt ou un nom de fichier.
enum PathIssue {
  empty,
  absolute,
  backslash,
  traversal,
  currentDirSegment,
  emptySegment,
  controlCharacter,
  gitDirectory,
  forbiddenCharacter,
  reservedName,
  trailingDotOrSpace,
  segmentTooLong,
  pathTooLong,
}

class PathValidationResult {
  const PathValidationResult(this.normalized, this.issues);

  /// Chemin normalisé (séparateur `/`), uniquement pertinent si [isValid].
  final String normalized;
  final Set<PathIssue> issues;

  bool get isValid => issues.isEmpty;
}

/// Valide les chemins relatifs destinés à un dépôt GitHub et protège les
/// répertoires de travail locaux contre les traversées de répertoires.
///
/// Les règles sont volontairement plus strictes que Git afin que le dépôt
/// reste clonable sous Linux, Android, macOS et Windows.
abstract final class PathValidator {
  static const maxSegmentBytes = 255;
  static const maxPathBytes = 4096;

  static const _forbiddenChars = '<>:"|?*';
  static final _reservedNames = RegExp(
    r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])(\..*)?$',
    caseSensitive: false,
  );

  /// Valide un chemin relatif à la racine d'un dépôt, ex. `photos/2025/a.jpg`.
  static PathValidationResult validateRepoPath(String input) {
    final issues = <PathIssue>{};
    if (input.trim().isEmpty) {
      return const PathValidationResult('', {PathIssue.empty});
    }
    if (input.contains(r'\')) issues.add(PathIssue.backslash);
    if (input.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(input)) {
      issues.add(PathIssue.absolute);
    }
    if (utf8.encode(input).length > maxPathBytes) {
      issues.add(PathIssue.pathTooLong);
    }

    final segments = input.split('/');
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.isEmpty) {
        // Le premier segment vide correspond au `/` initial déjà signalé.
        if (!(i == 0 && issues.contains(PathIssue.absolute))) {
          issues.add(PathIssue.emptySegment);
        }
        continue;
      }
      issues.addAll(_segmentIssues(segment));
    }
    return PathValidationResult(segments.join('/'), issues);
  }

  /// Valide un nom de fichier seul (sans dossier).
  static PathValidationResult validateFileName(String name) {
    if (name.isEmpty) {
      return const PathValidationResult('', {PathIssue.empty});
    }
    final issues = _segmentIssues(name);
    if (name.contains('/')) issues.add(PathIssue.forbiddenCharacter);
    if (name.contains(r'\')) issues.add(PathIssue.backslash);
    return PathValidationResult(name, issues);
  }

  static Set<PathIssue> _segmentIssues(String segment) {
    final issues = <PathIssue>{};
    if (segment == '..') issues.add(PathIssue.traversal);
    if (segment == '.') issues.add(PathIssue.currentDirSegment);
    if (segment.toLowerCase() == '.git') issues.add(PathIssue.gitDirectory);
    if (segment.runes.any((r) => r < 0x20 || r == 0x7f)) {
      issues.add(PathIssue.controlCharacter);
    }
    if (segment.split('').any(_forbiddenChars.contains)) {
      issues.add(PathIssue.forbiddenCharacter);
    }
    if (_reservedNames.hasMatch(segment)) issues.add(PathIssue.reservedName);
    if (segment != '.' &&
        segment != '..' &&
        (segment.endsWith('.') || segment.endsWith(' '))) {
      issues.add(PathIssue.trailingDotOrSpace);
    }
    if (utf8.encode(segment).length > maxSegmentBytes) {
      issues.add(PathIssue.segmentTooLong);
    }
    return issues;
  }

  /// Propose un nom de fichier sûr dérivé de [name]. Ne garantit pas
  /// l'unicité : la gestion des conflits relève du planificateur.
  static String sanitizeFileName(String name, {String fallback = 'fichier'}) {
    var result = name
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '')
        .replaceAll(RegExp(r'[<>:"|?*/\\]'), '_')
        .trim();
    result = result.replaceAll(RegExp(r'[. ]+$'), '');
    if (result.isEmpty || result == '.' || result == '..') result = fallback;
    if (result.toLowerCase() == '.git') result = '_git';
    if (_reservedNames.hasMatch(result)) result = '_$result';
    while (utf8.encode(result).length > maxSegmentBytes) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Indique si [candidate] se trouve strictement à l'intérieur de [base]
  /// après normalisation (protection contre `..` et chemins absolus).
  ///
  /// Les liens symboliques ne sont pas résolus ici : l'appelant qui manipule
  /// des fichiers réels doit d'abord résoudre les chemins.
  static bool isWithinDirectory(String base, String candidate) {
    final normalizedBase = p.normalize(p.absolute(base));
    final normalizedCandidate = p.normalize(
      p.isAbsolute(candidate) ? candidate : p.join(normalizedBase, candidate),
    );
    return p.isWithin(normalizedBase, normalizedCandidate);
  }
}
