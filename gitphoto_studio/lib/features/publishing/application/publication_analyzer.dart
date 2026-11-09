import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/platform/tool_probe.dart';
import '../../gallery/application/file_fingerprint.dart';
import '../../gallery/domain/media_item.dart';
import '../../github/data/github_api.dart';
import '../../github/data/github_exception.dart';
import '../../github/domain/github_models.dart';
import '../domain/git_blob_hash.dart';
import '../domain/publish_plan.dart';

/// Préférences de publication (Paramètres).
abstract final class PublishPreferenceKeys {
  /// `false` pour désactiver Git LFS (défaut : activé).
  static const lfsEnabled = 'publish.lfs_enabled';

  /// `true` pour publier par Git natif quand il est installé (Linux).
  static const preferNativeGit = 'publish.prefer_native_git';
}

/// Fichier produit par l'application, hors bibliothèque (README…).
class ExtraPublishFile {
  const ExtraPublishFile({required this.fileName, required this.localPath});

  final String fileName;
  final String localPath;
}

/// Analyse une publication **sans rien modifier** : empreintes locales,
/// lecture de l'arborescence distante, puis plan (ajouts, fichiers
/// identiques ignorés, renommages, transport, blocages).
///
/// Utilisée par l'assistant de publication et par l'agent IA.
class PublicationAnalyzer {
  PublicationAnalyzer(this._ref);

  final Ref _ref;

  /// Empreintes Git déjà calculées (identifiant du média → empreinte).
  final Map<int, String> _blobShaCache = {};

  Future<PublishPlan> analyze({
    required GithubApi api,
    required String owner,
    required String repo,
    required String branch,
    required String folder,
    required List<MediaItem> media,
    List<ExtraPublishFile> extraFiles = const [],
    ConflictPolicy policy = ConflictPolicy.rename,
    Set<int> overwriteMediaIds = const {},
    void Function(int done, int total)? onProgress,
  }) async {
    final prefs = _ref.read(preferencesProvider);
    final total = media.length + extraFiles.length;
    final candidates = <PublishCandidate>[];
    for (var i = 0; i < media.length; i++) {
      final m = media[i];
      final sha = _blobShaCache[m.id] ??= await gitBlobShaOfFile(m.storedPath);
      candidates.add(
        PublishCandidate(
          mediaId: m.id,
          fileName: m.fileName,
          localPath: m.storedPath,
          sizeBytes: m.sizeBytes,
          gitBlobSha: sha,
          contentSha256: m.sha256,
          hasGps: m.hasGps,
        ),
      );
      onProgress?.call(i + 1, total);
    }
    for (final (i, f) in extraFiles.indexed) {
      candidates.add(
        PublishCandidate(
          fileName: f.fileName,
          localPath: f.localPath,
          sizeBytes: await File(f.localPath).length(),
          gitBlobSha: await gitBlobShaOfFile(f.localPath),
          contentSha256: await sha256OfFile(f.localPath),
        ),
      );
      onProgress?.call(media.length + i + 1, total);
    }

    var empty = false;
    var remote = RemoteTree.empty;
    try {
      final head = await api.getBranchHead(owner, repo, branch);
      remote = await api.getTree(
        owner,
        repo,
        await api.getCommitTree(owner, repo, head),
      );
    } on GithubException catch (e) {
      if (e.kind != GithubErrorKind.emptyRepository) rethrow;
      empty = true;
    }

    return const PublishPlanner().plan(
      candidates: candidates,
      folder: folder,
      remote: remote,
      repositoryIsEmpty: empty,
      policy: policy,
      overwriteMediaIds: overwriteMediaIds,
      tools:
          _ref.read(toolAvailabilityProvider).value ??
          const ToolAvailability(supportsExternalTools: false),
      preferNativeGit:
          prefs.read(PublishPreferenceKeys.preferNativeGit) == 'true',
      lfsEnabled: prefs.read(PublishPreferenceKeys.lfsEnabled) != 'false',
    );
  }
}

final publicationAnalyzerProvider = Provider<PublicationAnalyzer>(
  PublicationAnalyzer.new,
);
