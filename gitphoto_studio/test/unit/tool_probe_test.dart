import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';

void main() {
  test('ne lance aucune commande sur mobile', () async {
    var calls = 0;
    final probe = ToolProbe(
      isDesktop: false,
      runner: (_, _) async {
        calls++;
        return 'x';
      },
    );
    final result = await probe.probe();
    expect(result.supportsExternalTools, isFalse);
    expect(result.hasGit, isFalse);
    expect(calls, 0);
  });

  test('détecte Git et Git LFS avec des commandes fixes', () async {
    final seen = <String>[];
    final probe = ToolProbe(
      isDesktop: true,
      runner: (exe, args) async {
        seen.add('$exe ${args.join(' ')}');
        if (exe == 'ffmpeg') return 'ffmpeg version 4.4.2\nbuilt with gcc';
        return args.first == 'lfs' ? 'git-lfs/3.4.0' : 'git version 2.34.1';
      },
    );
    final result = await probe.probe();
    expect(seen, ['git --version', 'git lfs version', 'ffmpeg -version']);
    expect(result.hasGit, isTrue);
    expect(result.hasGitLfs, isTrue);
    expect(result.ffmpegVersion, 'ffmpeg version 4.4.2');
  });

  test('sans Git, Git LFS n\'est pas interrogé', () async {
    final seen = <String>[];
    final probe = ToolProbe(
      isDesktop: true,
      runner: (exe, args) async {
        seen.add(args.join(' '));
        return null;
      },
    );
    final result = await probe.probe();
    expect(seen, ['--version', '-version']);
    expect(result.hasFfmpeg, isFalse);
    expect(result.hasGit, isFalse);
    expect(result.hasGitLfs, isFalse);
  });

  test('une commande introuvable renvoie null sans exception', () async {
    expect(
      await runSystemCommand('commande-inexistante-gitphoto', const []),
      isNull,
    );
  });
}
