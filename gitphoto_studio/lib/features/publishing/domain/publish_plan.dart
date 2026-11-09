import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../../core/platform/tool_probe.dart';
import '../../../core/security/path_validator.dart';
import '../../github/domain/github_models.dart';
import 'git_blob_hash.dart';
import 'transport_selector.dart';

/// Fichier local candidat à la publication.
class PublishCandidate {
  const PublishCandidate({
    this.mediaId,
    required this.fileName,
    required this.localPath,
    required this.sizeBytes,
    required this.gitBlobSha,
    this.contentSha256,
    this.hasGps = false,
  });

  /// `null` : fichier produit par l'application hors bibliothèque (README).
  final int? mediaId;
  final String fileName;
  final String localPath;
  final int sizeBytes;
  final String gitBlobSha;

  /// SHA-256 du contenu (calculé à l'import) : identifiant Git LFS.
  final String? contentSha256;
  final bool hasGps;
}

enum PlannedAction {
  /// Nouveau fichier.
  add,

  /// Un fichier identique existe déjà à cet emplacement : rien à envoyer.
  skipIdentical,

  /// Un fichier différent existe : publié sous un autre nom.
  renamed,

  /// Un fichier différent existe et l'utilisateur a choisi de le remplacer.
  overwrite,

  /// Publication impossible (taille, chemin…).
  blocked,
}

enum BlockReason { invalidPath, requiresGitLfs, tooLargeForLfs }

enum ConflictPolicy { rename, overwrite }

class PlannedFile {
  const PlannedFile({
    required this.candidate,
    required this.remotePath,
    required this.action,
    this.strategy = PublishStrategy.githubApi,
    this.remoteShaAtAnalysis,
    this.blockReason,
    this.warnings = const {},
  });

  final PublishCandidate candidate;
  final String remotePath;
  final PlannedAction action;
  final PublishStrategy strategy;

  /// Contenu présent à ce chemin lors de l'analyse (`null` : chemin libre).
  /// Sert à détecter qu'un autre auteur a modifié ce chemin entre-temps.
  final String? remoteShaAtAnalysis;

  bool get isLfs => strategy == PublishStrategy.gitLfs;

  /// Empreinte Git attendue dans l'arborescence : le contenu, ou le fichier
  /// pointeur pour Git LFS.
  String get expectedTreeSha => isLfs
      ? lfsPointerSha(candidate.contentSha256!, candidate.sizeBytes)
      : candidate.gitBlobSha;
  final BlockReason? blockReason;
  final Set<TransportWarning> warnings;

  bool get willUpload =>
      action == PlannedAction.add ||
      action == PlannedAction.renamed ||
      action == PlannedAction.overwrite;
}

class PublishPlan {
  const PublishPlan({
    required this.files,
    required this.folder,
    required this.repositoryIsEmpty,
    required this.remoteTreeTruncated,
  });

  final List<PlannedFile> files;
  final String folder;

  /// Dépôt sans commit : un premier commit l'initialise, puis un second
  /// regroupe le reste (l'API Git ne crée pas de premier commit).
  final bool repositoryIsEmpty;

  /// Arborescence distante incomplète : certains conflits peuvent avoir
  /// échappé à l'analyse (GitHub refusera alors tout écrasement silencieux).
  final bool remoteTreeTruncated;

  Iterable<PlannedFile> get uploads => files.where((f) => f.willUpload);

  int get uploadBytes =>
      uploads.fold(0, (sum, f) => sum + f.candidate.sizeBytes);

  int count(PlannedAction a) => files.where((f) => f.action == a).length;

  bool get usesLfs => uploads.any((f) => f.isLfs);

  bool get usesNativeGit =>
      uploads.any((f) => f.strategy == PublishStrategy.nativeGit);
}

/// Empreinte Git du fichier pointeur LFS d'un contenu.
String lfsPointerSha(String sha256Hex, int size) => gitBlobSha(
  utf8.encode(
    'version https://git-lfs.github.com/spec/v1\noid sha256:$sha256Hex\n'
    'size $size\n',
  ),
);

/// Planification pure (sans réseau) d'une publication.
class PublishPlanner {
  const PublishPlanner({this.selector = const TransportSelector()});

  final TransportSelector selector;

  /// Normalise un dossier saisi par l'utilisateur (`/photos/2024/` →
  /// `photos/2024`) ; renvoie `null` s'il est invalide. Chaîne vide = racine.
  static String? normalizeFolder(String input) {
    final trimmed = input.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (trimmed.isEmpty) return '';
    return PathValidator.validateRepoPath(trimmed).isValid ? trimmed : null;
  }

  PublishPlan plan({
    required List<PublishCandidate> candidates,
    required String folder,
    required RemoteTree remote,
    required bool repositoryIsEmpty,
    ConflictPolicy policy = ConflictPolicy.rename,
    Set<int> overwriteMediaIds = const {},
    ToolAvailability tools = const ToolAvailability(
      supportsExternalTools: false,
    ),
    bool preferNativeGit = false,
    bool lfsEnabled = true,
  }) {
    final taken = {...remote.files.keys.map((k) => k.toLowerCase())};
    final planned = <PlannedFile>[];

    for (final c in candidates) {
      final name = PathValidator.sanitizeFileName(c.fileName);
      final path = folder.isEmpty ? name : '$folder/$name';
      if (!PathValidator.validateRepoPath(path).isValid) {
        planned.add(
          PlannedFile(
            candidate: c,
            remotePath: path,
            action: PlannedAction.blocked,
            blockReason: BlockReason.invalidPath,
          ),
        );
        continue;
      }

      var decision = selector.select(
        fileSizeBytes: c.sizeBytes,
        tools: tools,
        preferNativeGit: preferNativeGit,
        lfsEnabled: lfsEnabled,
      );
      // Git LFS exige l'empreinte SHA-256 du contenu.
      if (decision.strategy == PublishStrategy.gitLfs &&
          c.contentSha256 == null) {
        decision = const TransportDecision.unavailable(
          TransportUnavailableReason.requiresGitLfs,
        );
      }
      if (!decision.isAvailable) {
        planned.add(
          PlannedFile(
            candidate: c,
            remotePath: path,
            action: PlannedAction.blocked,
            blockReason: switch (decision.unavailableReason!) {
              TransportUnavailableReason.requiresGitLfs =>
                BlockReason.requiresGitLfs,
              TransportUnavailableReason.tooLargeForLfs =>
                BlockReason.tooLargeForLfs,
            },
          ),
        );
        continue;
      }
      final strategy = decision.strategy!;
      final expected = strategy == PublishStrategy.gitLfs
          ? lfsPointerSha(c.contentSha256!, c.sizeBytes)
          : c.gitBlobSha;

      final existing = remote.files[path];
      PlannedAction action;
      var target = path;
      if (existing == null) {
        if (taken.contains(path.toLowerCase())) {
          // Même nom (à la casse près) qu'un autre fichier : on renomme pour
          // rester clonable sur les systèmes insensibles à la casse.
          target = _freeName(path, taken);
          action = PlannedAction.renamed;
        } else {
          action = PlannedAction.add;
        }
      } else if (existing == expected) {
        action = PlannedAction.skipIdentical;
      } else if (policy == ConflictPolicy.overwrite ||
          overwriteMediaIds.contains(c.mediaId)) {
        action = PlannedAction.overwrite;
      } else {
        target = _freeName(path, taken);
        action = PlannedAction.renamed;
      }
      taken.add(target.toLowerCase());
      planned.add(
        PlannedFile(
          candidate: c,
          remotePath: target,
          action: action,
          strategy: strategy,
          remoteShaAtAnalysis: remote.files[target],
          warnings: decision.warnings,
        ),
      );
    }

    return PublishPlan(
      files: planned,
      folder: folder,
      repositoryIsEmpty: repositoryIsEmpty,
      remoteTreeTruncated: remote.truncated,
    );
  }

  /// Reprise : chemins et décisions déjà fixés, revérifiés face à l'état
  /// actuel du dépôt. Un fichier identique déjà présent est ignoré (pas de
  /// double publication) ; un fichier différent apparu entre-temps à un
  /// chemin qui devait être libre bloque l'opération (conflit).
  PublishPlan replan({
    required List<
      ({
        PublishCandidate candidate,
        String remotePath,
        PublishStrategy strategy,
        bool overwrite,
      })
    >
    entries,
    required String folder,
    required RemoteTree remote,
    required bool repositoryIsEmpty,
  }) {
    final files = <PlannedFile>[];
    for (final e in entries) {
      final c = e.candidate;
      final expected = e.strategy == PublishStrategy.gitLfs
          ? lfsPointerSha(c.contentSha256!, c.sizeBytes)
          : c.gitBlobSha;
      final existing = remote.files[e.remotePath];
      final PlannedAction action;
      if (existing == null) {
        action = PlannedAction.add;
      } else if (existing == expected) {
        action = PlannedAction.skipIdentical;
      } else if (e.overwrite) {
        action = PlannedAction.overwrite;
      } else {
        throw PublishConflictException(e.remotePath);
      }
      files.add(
        PlannedFile(
          candidate: c,
          remotePath: e.remotePath,
          action: action,
          strategy: e.strategy,
          remoteShaAtAnalysis: existing,
        ),
      );
    }
    return PublishPlan(
      files: files,
      folder: folder,
      repositoryIsEmpty: repositoryIsEmpty,
      remoteTreeTruncated: remote.truncated,
    );
  }

  static String _freeName(String path, Set<String> taken) {
    final dir = p.posix.dirname(path);
    final base = p.posix.basenameWithoutExtension(path);
    final ext = p.posix.extension(path);
    for (var i = 2; ; i++) {
      final name = '$base ($i)$ext';
      final candidate = dir == '.' ? name : '$dir/$name';
      if (!taken.contains(candidate.toLowerCase())) return candidate;
    }
  }
}

/// Un chemin cible a été modifié par quelqu'un d'autre depuis l'analyse.
class PublishConflictException implements Exception {
  const PublishConflictException(this.remotePath);

  final String remotePath;

  @override
  String toString() =>
      'Conflit : « $remotePath » a été modifié sur GitHub depuis l\'analyse';
}
