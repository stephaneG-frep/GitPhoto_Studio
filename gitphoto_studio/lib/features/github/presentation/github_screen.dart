import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/open_url.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../../publishing/application/publish_controller.dart';
import '../application/github_session.dart';
import '../data/device_flow.dart';
import '../domain/github_models.dart';
import 'create_repo_dialog.dart';
import 'github_error_text.dart';

const _tokenSettingsUrl =
    'https://github.com/settings/personal-access-tokens/new';
const _tokenListUrl = 'https://github.com/settings/tokens';

/// Identifiant client fourni à la compilation (`--dart-define`), sinon saisi
/// par l'utilisateur. Ce n'est pas un secret.
const _buildClientId = String.fromEnvironment('GITHUB_CLIENT_ID');
const _clientIdKey = 'github.client_id';

class GithubScreen extends ConsumerWidget {
  const GithubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(githubSessionProvider);
    return ScreenFrame(
      title: l10n.navGithub,
      children: [
        ...session.when(
          loading: () => [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
          error: (e, _) => [_ErrorCard(error: e)],
          data: (s) => switch (s) {
            GithubDisconnected(:final storeUnavailable) =>
              storeUnavailable
                  ? [PixelTip(message: l10n.ghStoreUnavailable)]
                  : const [_ConnectSection()],
            GithubSessionError(:final error) => [
              _ErrorCard(error: error, title: l10n.ghSessionError),
              const SizedBox(height: 16),
              const _ConnectSection(),
            ],
            GithubConnected(:final user) => [
              _AccountCard(user: user),
              const _RepoSection(),
            ],
          },
        ),
      ],
    );
  }
}

class _ErrorCard extends ConsumerWidget {
  const _ErrorCard({required this.error, this.title});

  final Object error;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? l10n.pubFailed,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(describeError(context, error)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    ref.read(githubSessionProvider.notifier).retry(),
                child: Text(l10n.commonRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectSection extends ConsumerStatefulWidget {
  const _ConnectSection();

  @override
  ConsumerState<_ConnectSection> createState() => _ConnectSectionState();
}

class _ConnectSectionState extends ConsumerState<_ConnectSection> {
  final _token = TextEditingController();
  late final _clientId = TextEditingController(
    text: _buildClientId.isNotEmpty
        ? _buildClientId
        : ref.read(preferencesProvider).read(_clientIdKey) ?? '',
  );
  bool _obscure = true;
  bool _busy = false;
  Object? _error;
  DeviceCode? _deviceCode;
  bool _cancelDevice = false;

  @override
  void dispose() {
    _cancelDevice = true;
    _token.dispose();
    _clientId.dispose();
    super.dispose();
  }

  Future<void> _connectWithToken() async {
    if (_token.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(githubSessionProvider.notifier).connect(_token.text);
      _token.clear();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connectWithDevice() async {
    final clientId = _clientId.text.trim();
    if (clientId.isEmpty) return;
    ref.read(preferencesProvider).write(_clientIdKey, clientId);
    setState(() {
      _busy = true;
      _error = null;
      _cancelDevice = false;
    });
    try {
      final flow = GithubDeviceFlow(clientId: clientId);
      final code = await flow.start();
      if (!mounted) return;
      setState(() => _deviceCode = code);
      await openUrl(context, code.verificationUri);
      final token = await flow.poll(code, isCancelled: () => _cancelDevice);
      if (!mounted) return;
      await ref.read(githubSessionProvider.notifier).connect(token);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _deviceCode = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final code = _deviceCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelTip(message: l10n.ghConnectIntro),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                describeError(context, _error!),
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        ],
        SectionTitle(l10n.ghPatTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.ghPatHelp),
                TextButton.icon(
                  onPressed: () => openUrl(context, _tokenSettingsUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.ghPatCreate),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _token,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: !_busy,
                  onSubmitted: (_) => _connectWithToken(),
                  decoration: InputDecoration(
                    labelText: l10n.ghPatField,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _connectWithToken,
                    icon: _busy && code == null
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(l10n.ghPatConnect),
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(l10n.ghDeviceTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.ghDeviceHelp),
                const SizedBox(height: 12),
                if (code == null) ...[
                  TextField(
                    controller: _clientId,
                    enabled: !_busy,
                    autocorrect: false,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.ghDeviceClientId,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _busy || _clientId.text.trim().isEmpty
                          ? null
                          : _connectWithDevice,
                      icon: const Icon(Icons.open_in_browser),
                      label: Text(l10n.ghDeviceStart),
                    ),
                  ),
                ] else ...[
                  Text(l10n.ghDeviceCodeIntro),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SelectableText(
                        code.userCode,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          letterSpacing: 4,
                          color: StudioColors.of(context).accent,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.commonCopy,
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: code.userCode),
                        ),
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => openUrl(context, code.verificationUri),
                    child: Text(code.verificationUri),
                  ),
                  Row(
                    children: [
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.ghDeviceWaiting)),
                      TextButton(
                        onPressed: () => _cancelDevice = true,
                        child: Text(l10n.commonCancel),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.user});

  final GithubUser user;

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: Text(l10n.ghDisconnectTitle),
        content: Text(l10n.ghDisconnectBody),
        actions: [
          TextButton(
            onPressed: () => openUrl(context, _tokenListUrl),
            child: Text(l10n.ghRevokePage),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ghDisconnect),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(githubSessionProvider.notifier).disconnect();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scopes = user.scopes;
    final details = <String>[
      if (user.name != null) user.name!,
      scopes == null
          ? l10n.ghTokenFineGrained
          : l10n.ghTokenScopes(scopes.isEmpty ? '—' : scopes.join(', ')),
      if (user.tokenExpiration != null)
        l10n.ghTokenExpires(user.tokenExpiration!),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              foregroundImage: user.avatarUrl == null
                  ? null
                  : NetworkImage(user.avatarUrl!),
              child: const Icon(Icons.person),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ghConnectedAs(user.login),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final d in details)
                    Text(d, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => openUrl(context, user.htmlUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(l10n.commonOpenInBrowser),
                      ),
                      TextButton.icon(
                        onPressed: () => _disconnect(context, ref),
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.ghDisconnect),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepoSection extends ConsumerStatefulWidget {
  const _RepoSection();

  @override
  ConsumerState<_RepoSection> createState() => _RepoSectionState();
}

class _RepoSectionState extends ConsumerState<_RepoSection> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repos = ref.watch(githubReposProvider);
    final active = ref.watch(activeRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.ghRepos,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.commonRefresh,
                onPressed: () =>
                    ref.read(githubRefreshProvider.notifier).bump(),
                icon: const Icon(Icons.refresh),
              ),
              FilledButton.tonalIcon(
                onPressed: () => showCreateRepoDialog(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.ghNewRepo),
              ),
            ],
          ),
        ),
        TextField(
          onChanged: (v) => setState(() => _filter = v.trim().toLowerCase()),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.ghReposSearch,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 8),
        repos.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(describeError(context, e)),
              trailing: TextButton(
                onPressed: () =>
                    ref.read(githubRefreshProvider.notifier).bump(),
                child: Text(l10n.commonRetry),
              ),
            ),
          ),
          data: (list) {
            final shown = list
                .where((r) => r.fullName.toLowerCase().contains(_filter))
                .toList();
            if (shown.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.ghReposEmpty),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (final r in shown)
                    ListTile(
                      leading: Icon(
                        r.isPrivate ? Icons.lock_outline : Icons.public,
                      ),
                      title: Text(r.fullName),
                      subtitle: r.description == null
                          ? null
                          : Text(
                              r.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (active != null &&
                              active.owner == r.owner &&
                              active.name == r.name)
                            Chip(label: Text(l10n.ghActive)),
                          if (!r.canPush) Chip(label: Text(l10n.ghReadOnly)),
                        ],
                      ),
                      onTap: () => context.go(
                        '/github/repo/${Uri.encodeComponent(r.owner)}/'
                        '${Uri.encodeComponent(r.name)}',
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
