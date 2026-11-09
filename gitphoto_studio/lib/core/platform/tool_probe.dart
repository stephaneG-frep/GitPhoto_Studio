import 'dart:io';

/// Exécute une commande fixe et renvoie sa sortie standard, ou `null` si la
/// commande est introuvable ou échoue. Injectable pour les tests.
typedef CommandRunner =
    Future<String?> Function(String executable, List<String> arguments);

Future<String?> runSystemCommand(String executable, List<String> args) async {
  try {
    final result = await Process.run(
      executable,
      args,
    ).timeout(const Duration(seconds: 5));
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trim();
  } on ProcessException {
    return null;
  } on Exception {
    return null;
  }
}

/// Outils externes détectés sur la machine.
class ToolAvailability {
  const ToolAvailability({
    required this.supportsExternalTools,
    this.gitVersion,
    this.gitLfsVersion,
    this.ffmpegVersion,
  });

  /// `false` sur Android : Git n'y est jamais supposé installé.
  final bool supportsExternalTools;
  final String? gitVersion;
  final String? gitLfsVersion;

  /// Première ligne de `ffmpeg -version` (conversion vidéo sous Linux).
  final String? ffmpegVersion;

  bool get hasGit => gitVersion != null;
  bool get hasGitLfs => hasGit && gitLfsVersion != null;
  bool get hasFfmpeg => ffmpegVersion != null;
}

/// Détecte Git et Git LFS uniquement par des commandes fixes et connues :
/// aucune commande n'est construite à partir d'une saisie ou d'un modèle IA.
class ToolProbe {
  ToolProbe({CommandRunner? runner, bool? isDesktop})
    : _runner = runner ?? runSystemCommand,
      _isDesktop =
          isDesktop ??
          (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  final CommandRunner _runner;
  final bool _isDesktop;

  Future<ToolAvailability> probe() async {
    if (!_isDesktop) {
      return const ToolAvailability(supportsExternalTools: false);
    }
    final git = await _runner('git', ['--version']);
    final lfs = git == null ? null : await _runner('git', ['lfs', 'version']);
    final ffmpeg = await _runner('ffmpeg', ['-version']);
    return ToolAvailability(
      supportsExternalTools: true,
      gitVersion: git,
      gitLfsVersion: lfs,
      ffmpegVersion: ffmpeg?.split('\n').first,
    );
  }
}
