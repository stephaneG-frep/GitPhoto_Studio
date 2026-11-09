import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_info.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../../ai_agent/presentation/ai_settings_section.dart';
import '../../github/application/github_session.dart';
import '../../publishing/application/publish_controller.dart'
    show PublishPreferenceKeys;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return ScreenFrame(
      title: l10n.navSettings,
      children: [
        SectionTitle(l10n.settingsAppearance),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsTheme),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode),
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).set(s.first),
                ),
                const SizedBox(height: 16),
                Text(l10n.settingsLanguage),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'fr',
                      label: Text(l10n.languageFrench),
                    ),
                    ButtonSegment(
                      value: 'en',
                      label: Text(l10n.languageEnglish),
                    ),
                  ],
                  selected: {locale.languageCode},
                  onSelectionChanged: (s) =>
                      ref.read(localeProvider.notifier).set(Locale(s.first)),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(l10n.settingsGithub),
        const _GithubAccountTile(),
        SectionTitle(l10n.settingsPublishing),
        const _PublishingSettings(),
        SectionTitle(l10n.settingsAiProviders),
        const AiSettingsSection(),
        SectionTitle(l10n.settingsDiagnostics),
        const _DiagnosticsCard(),
        const SizedBox(height: 16),
        PixelTip(message: l10n.pixelSettingsHint),
        SectionTitle(l10n.settingsAbout),
        Card(
          child: ListTile(
            leading: const PixelMascot(size: 40),
            title: Text(l10n.appTitle),
            subtitle: Text(
              l10n.settingsVersion('${AppInfo.version}+${AppInfo.buildNumber}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiagnosticsCard extends ConsumerWidget {
  const _DiagnosticsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final db = ref.watch(appDatabaseProvider);
    final tools = ref.watch(toolAvailabilityProvider);
    final success = StudioColors.of(context).success;

    Widget toolTile(String name, String? version, bool applicable) {
      final found = version != null;
      return ListTile(
        leading: Icon(
          found ? Icons.check_circle : Icons.remove_circle_outline,
          color: found ? success : null,
        ),
        title: Text(name),
        subtitle: Text(
          !applicable ? l10n.diagNotApplicable : (version ?? l10n.diagNotFound),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.devices),
            title: Text(l10n.diagPlatform),
            subtitle: Text(defaultTargetPlatform.name),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(l10n.diagDatabase),
            subtitle: Text(l10n.diagSchemaVersion(db.schemaVersion)),
          ),
          ...tools.when(
            data: (t) => [
              toolTile(l10n.diagGit, t.gitVersion, t.supportsExternalTools),
              toolTile(
                l10n.diagGitLfs,
                t.gitLfsVersion,
                t.supportsExternalTools,
              ),
              toolTile(
                l10n.diagFfmpeg,
                t.ffmpegVersion,
                t.supportsExternalTools,
              ),
              if (t.supportsExternalTools)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => ref.invalidate(toolAvailabilityProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRefresh),
                  ),
                ),
            ],
            loading: () => [
              ListTile(
                leading: const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text(l10n.commonLoading),
              ),
            ],
            error: (e, _) => [
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(l10n.commonError('$e')),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(toolAvailabilityProvider),
                  child: Text(l10n.commonRetry),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GithubAccountTile extends ConsumerWidget {
  const _GithubAccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(githubSessionProvider).value;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.hub_outlined),
        title: Text(
          session is GithubConnected
              ? l10n.ghConnectedAs(session.user.login)
              : l10n.settingsGithubNotConnected,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/github'),
      ),
    );
  }
}

class _PublishingSettings extends ConsumerStatefulWidget {
  const _PublishingSettings();

  @override
  ConsumerState<_PublishingSettings> createState() =>
      _PublishingSettingsState();
}

class _PublishingSettingsState extends ConsumerState<_PublishingSettings> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(preferencesProvider);
    final tools = ref.watch(toolAvailabilityProvider).value;
    final hasGit = tools?.hasGit ?? false;
    final lfs = prefs.read(PublishPreferenceKeys.lfsEnabled) != 'false';
    final nativeGit =
        prefs.read(PublishPreferenceKeys.preferNativeGit) == 'true';
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.settingsLfs),
            subtitle: Text(l10n.settingsLfsHelp),
            value: lfs,
            onChanged: (v) => setState(
              () => prefs.write(PublishPreferenceKeys.lfsEnabled, '$v'),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.settingsNativeGit),
            subtitle: Text(
              hasGit
                  ? l10n.settingsNativeGitHelp
                  : l10n.settingsNativeGitUnavailable,
            ),
            value: nativeGit && hasGit,
            onChanged: hasGit
                ? (v) => setState(
                    () => prefs.write(
                      PublishPreferenceKeys.preferNativeGit,
                      '$v',
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
