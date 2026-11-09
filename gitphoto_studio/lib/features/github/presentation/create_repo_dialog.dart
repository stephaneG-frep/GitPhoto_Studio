import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/github_session.dart';
import 'github_error_text.dart';

final _repoNamePattern = RegExp(r'^[A-Za-z0-9._-]{1,100}$');

bool isValidRepoName(String name) =>
    _repoNamePattern.hasMatch(name) && name != '.' && name != '..';

/// Création d'un dépôt. Privé par défaut ; un dépôt public exige une
/// seconde confirmation explicite.
Future<void> showCreateRepoDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _CreateRepoDialog(),
  );
}

class _CreateRepoDialog extends ConsumerStatefulWidget {
  const _CreateRepoDialog();

  @override
  ConsumerState<_CreateRepoDialog> createState() => _CreateRepoDialogState();
}

class _CreateRepoDialogState extends ConsumerState<_CreateRepoDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _private = true;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (!isValidRepoName(name)) return;
    if (!_private) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.public),
          title: Text(l10n.ghNewRepoPublicConfirmTitle),
          content: Text(l10n.ghNewRepoPublicConfirmBody(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.ghNewRepoPublicConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final api = ref.read(githubApiProvider);
    if (api == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = await api.createRepo(
        name: name,
        isPrivate: _private,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      );
      ref.read(githubRefreshProvider.notifier).bump();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ghNewRepoCreated(repo.fullName))),
      );
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final nameError = name.isNotEmpty && !isValidRepoName(name)
        ? l10n.ghNewRepoNameInvalid
        : null;
    return AlertDialog(
      title: Text(l10n.ghNewRepo),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                enabled: !_busy,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.ghNewRepoName,
                  errorText: nameError,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: l10n.ghNewRepoDescription,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<bool>(
                groupValue: _private,
                onChanged: (v) {
                  if (!_busy && v != null) setState(() => _private = v);
                },
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      value: true,
                      title: Text(l10n.ghPrivate),
                      subtitle: Text(l10n.ghNewRepoPrivate),
                      secondary: const Icon(Icons.lock_outline),
                    ),
                    RadioListTile<bool>(
                      value: false,
                      title: Text(l10n.ghPublic),
                      subtitle: Text(l10n.ghNewRepoPublic),
                      secondary: const Icon(Icons.public),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Text(
                  describeError(context, _error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _busy || !isValidRepoName(name) ? null : _create,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.ghNewRepoCreate),
        ),
      ],
    );
  }
}
