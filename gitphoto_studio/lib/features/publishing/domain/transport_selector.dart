import '../../../core/platform/tool_probe.dart';

/// Stratégies de publication prévues par le cahier des charges.
enum PublishStrategy {
  /// A — API REST GitHub (toutes plateformes).
  githubApi,

  /// B — Git en ligne de commande (bureau, si Git est installé).
  nativeGit,

  /// C — Git LFS : protocole HTTP de GitHub, implémenté par l'application
  /// (toutes plateformes, sans l'outil `git-lfs`).
  gitLfs,
}

enum TransportWarning {
  /// Fichier au-delà du seuil d'avertissement de GitHub.
  largeFile,
}

enum TransportUnavailableReason {
  /// Fichier ordinaire au-delà de 100 Mio alors que Git LFS est désactivé.
  requiresGitLfs,

  /// Au-delà de la taille maximale d'un fichier Git LFS chez GitHub.
  tooLargeForLfs,
}

class TransportDecision {
  const TransportDecision.available(
    PublishStrategy this.strategy, {
    this.warnings = const {},
  }) : unavailableReason = null;

  const TransportDecision.unavailable(
    TransportUnavailableReason this.unavailableReason,
  ) : strategy = null,
      warnings = const {};

  final PublishStrategy? strategy;
  final TransportUnavailableReason? unavailableReason;
  final Set<TransportWarning> warnings;

  bool get isAvailable => strategy != null;
}

/// Seuils de taille, d'après la documentation GitHub : avertissement à
/// 50 Mio et refus au-delà de 100 Mio pour un fichier ordinaire ; 2 Gio par
/// fichier Git LFS pour un compte gratuit.
class PublishLimits {
  const PublishLimits({
    this.warnBytes = 50 * 1024 * 1024,
    this.hardLimitBytes = 100 * 1024 * 1024,
    this.lfsThresholdBytes = 50 * 1024 * 1024,
    this.lfsMaxBytes = 2 * 1024 * 1024 * 1024,
  });

  final int warnBytes;
  final int hardLimitBytes;

  /// Au-delà, un fichier passe par Git LFS (si activé).
  final int lfsThresholdBytes;
  final int lfsMaxBytes;
}

/// Choisit une stratégie de transport. Logique pure, sans effet de bord.
class TransportSelector {
  const TransportSelector({this.limits = const PublishLimits()});

  final PublishLimits limits;

  TransportDecision select({
    required int fileSizeBytes,
    required ToolAvailability tools,
    bool preferNativeGit = false,
    bool lfsEnabled = true,
  }) {
    if (fileSizeBytes > limits.lfsMaxBytes) {
      return const TransportDecision.unavailable(
        TransportUnavailableReason.tooLargeForLfs,
      );
    }
    if (fileSizeBytes > limits.lfsThresholdBytes) {
      if (lfsEnabled) {
        return const TransportDecision.available(PublishStrategy.gitLfs);
      }
      if (fileSizeBytes > limits.hardLimitBytes) {
        return const TransportDecision.unavailable(
          TransportUnavailableReason.requiresGitLfs,
        );
      }
    }
    final warnings = fileSizeBytes > limits.warnBytes
        ? const {TransportWarning.largeFile}
        : const <TransportWarning>{};
    if (preferNativeGit && tools.hasGit) {
      return TransportDecision.available(
        PublishStrategy.nativeGit,
        warnings: warnings,
      );
    }
    return TransportDecision.available(
      PublishStrategy.githubApi,
      warnings: warnings,
    );
  }
}
