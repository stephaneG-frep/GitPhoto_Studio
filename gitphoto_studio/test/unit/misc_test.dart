import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/app_info.dart';
import 'package:gitphoto_studio/app/destinations.dart';
import 'package:gitphoto_studio/core/utils/byte_format.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';

void main() {
  test('la version affichée correspond au pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\S+)\+(\d+)',
      multiLine: true,
    ).firstMatch(pubspec)!;
    expect(AppInfo.version, match[1]);
    expect(AppInfo.buildNumber, int.parse(match[2]!));
  });

  test('Mistral est le fournisseur IA prioritaire', () {
    expect(defaultAiProvider, AiProviderId.mistral);
    expect(
      aiProviderCatalog.map((d) => d.id).toSet(),
      AiProviderId.values.toSet(),
    );
    final ollama = aiProviderCatalog.firstWhere(
      (d) => d.id == AiProviderId.ollama,
    );
    expect(ollama.isLocal, isTrue);
    expect(ollama.requiresApiKey, isFalse);
  });

  test('résolution des destinations depuis l\'URL', () {
    expect(AppDestination.fromLocation('/'), AppDestination.dashboard);
    expect(AppDestination.fromLocation('/gallery'), AppDestination.gallery);
    expect(AppDestination.fromLocation('/github/a/b'), AppDestination.github);
    expect(AppDestination.fromLocation('/inconnu'), AppDestination.dashboard);
    expect(
      AppDestination.values.map((d) => d.path).toSet(),
      hasLength(AppDestination.values.length),
    );
  });

  test('formatage des tailles', () {
    expect(formatBytes(0), '0 o');
    expect(formatBytes(1023), '1023 o');
    expect(formatBytes(1536), '1,5 Kio');
    expect(formatBytes(1536, locale: 'en'), '1.5 Kio');
    expect(formatBytes(50 * 1024 * 1024), '50 Mio');
  });
}
