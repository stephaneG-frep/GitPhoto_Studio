import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';
import 'package:gitphoto_studio/features/publishing/domain/transport_selector.dart';

const mib = 1024 * 1024;

const android = ToolAvailability(supportsExternalTools: false);
const desktopGit = ToolAvailability(
  supportsExternalTools: true,
  gitVersion: 'git 2.34',
);

void main() {
  const selector = TransportSelector();

  test('petit fichier : API GitHub par défaut, partout', () {
    for (final tools in [android, desktopGit]) {
      final d = selector.select(fileSizeBytes: 2 * mib, tools: tools);
      expect(d.strategy, PublishStrategy.githubApi);
      expect(d.warnings, isEmpty);
    }
  });

  test('Git natif seulement si demandé et réellement installé', () {
    expect(
      selector
          .select(fileSizeBytes: mib, tools: desktopGit, preferNativeGit: true)
          .strategy,
      PublishStrategy.nativeGit,
    );
    expect(
      selector
          .select(fileSizeBytes: mib, tools: android, preferNativeGit: true)
          .strategy,
      PublishStrategy.githubApi,
    );
  });

  test('au-delà de 50 Mio : Git LFS sur toutes les plateformes', () {
    for (final tools in [android, desktopGit]) {
      for (final size in [51 * mib, 500 * mib]) {
        expect(
          selector
              .select(fileSizeBytes: size, tools: tools, preferNativeGit: true)
              .strategy,
          PublishStrategy.gitLfs,
        );
      }
    }
  });

  test('LFS désactivé : avertissement jusqu\'à 100 Mio, puis refus', () {
    final mid = selector.select(
      fileSizeBytes: 60 * mib,
      tools: android,
      lfsEnabled: false,
    );
    expect(mid.strategy, PublishStrategy.githubApi);
    expect(mid.warnings, {TransportWarning.largeFile});
    final big = selector.select(
      fileSizeBytes: 101 * mib,
      tools: android,
      lfsEnabled: false,
    );
    expect(big.unavailableReason, TransportUnavailableReason.requiresGitLfs);
  });

  test('au-delà de 2 Gio : refusé même avec LFS', () {
    final d = selector.select(
      fileSizeBytes: 2 * 1024 * mib + 1,
      tools: desktopGit,
    );
    expect(d.unavailableReason, TransportUnavailableReason.tooLargeForLfs);
  });

  test('bornes incluses du côté le plus permissif', () {
    expect(
      selector.select(fileSizeBytes: 50 * mib, tools: android).strategy,
      PublishStrategy.githubApi,
    );
    expect(
      selector
          .select(fileSizeBytes: 2 * 1024 * mib, tools: android)
          .isAvailable,
      isTrue,
    );
  });

  test('Git LFS sans Git n\'est pas considéré disponible (outil)', () {
    const lfsOnly = ToolAvailability(
      supportsExternalTools: true,
      gitLfsVersion: 'git-lfs/3.0',
    );
    expect(lfsOnly.hasGitLfs, isFalse);
  });
}
