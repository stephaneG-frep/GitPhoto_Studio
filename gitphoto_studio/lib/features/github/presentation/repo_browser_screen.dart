import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/byte_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/open_url.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../../publishing/application/publish_controller.dart';
import '../application/github_session.dart';
import '../data/github_exception.dart';
import '../domain/github_models.dart';
import 'github_error_text.dart';

/// Navigation dans un dépôt : branches, dossiers, commits.
class RepoBrowserScreen extends ConsumerStatefulWidget {
  const RepoBrowserScreen({super.key, required this.owner, required this.name});

  final String owner;
  final String name;

  @override
  ConsumerState<RepoBrowserScreen> createState() => _RepoBrowserScreenState();
}

class _RepoBrowserScreenState extends ConsumerState<RepoBrowserScreen> {
  String? _branch;
  String _path = '';

  GithubRepo? get _repo {
    final repos = ref.watch(githubReposProvider).value ?? const [];
    for (final r in repos) {
      if (r.owner == widget.owner && r.name == widget.name) return r;
    }
    return null;
  }

  void _setActive(GithubRepo repo) {
    final l10n = AppLocalizations.of(context);
    final ops = ref.read(operationsRepositoryProvider);
    final id = ops.upsertRepository(
      owner: repo.owner,
      name: repo.name,
      defaultBranch: repo.defaultBranch,
      isPrivate: repo.isPrivate,
      htmlUrl: repo.htmlUrl,
    );
    ops.setActiveRepository(id);
    ref.read(operationsRevisionProvider.notifier).bump();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.ghActiveSet(repo.fullName))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = _repo;
    final repoRef = (owner: widget.owner, name: widget.name);
    final branches = ref.watch(githubBranchesProvider(repoRef));
    final branch =
        _branch ?? repo?.defaultBranch ?? branches.value?.firstOrNull ?? 'main';
    final active = ref.watch(activeRepositoryProvider);
    final isActive =
        active != null &&
        active.owner == widget.owner &&
        active.name == widget.name;

    return ScreenFrame(
      title: '${widget.owner}/${widget.name}',
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.commonBack,
              onPressed: () => context.go('/github'),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                '${widget.owner}/${widget.name}',
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (branches.value case final list? when list.isNotEmpty)
              DropdownMenu<String>(
                label: Text(l10n.ghBranch),
                initialSelection: list.contains(branch) ? branch : list.first,
                onSelected: (b) => setState(() {
                  _branch = b;
                  _path = '';
                }),
                dropdownMenuEntries: [
                  for (final b in list) DropdownMenuEntry(value: b, label: b),
                ],
              ),
            if (repo != null) ...[
              FilledButton.icon(
                onPressed: repo.canPush
                    ? () => context.go(
                        Uri(
                          path: '/publish',
                          queryParameters: {
                            'owner': repo.owner,
                            'repo': repo.name,
                            'branch': branch,
                            'folder': _path,
                          },
                        ).toString(),
                      )
                    : null,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(l10n.ghPublishHere),
              ),
              if (!isActive)
                OutlinedButton.icon(
                  onPressed: () => _setActive(repo),
                  icon: const Icon(Icons.star_outline),
                  label: Text(l10n.ghSetActive),
                ),
              TextButton.icon(
                onPressed: () => openUrl(context, repo.htmlUrl),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.commonOpenInBrowser),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _Breadcrumbs(path: _path, onNavigate: (p) => setState(() => _path = p)),
        _ContentsList(
          contents: (
            owner: widget.owner,
            name: widget.name,
            branch: branch,
            path: _path,
          ),
          onOpenDir: (p) => setState(() => _path = p),
        ),
        SectionTitle(l10n.ghCommits),
        _CommitsList(
          branchRef: (owner: widget.owner, name: widget.name, branch: branch),
        ),
      ],
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.path, required this.onNavigate});

  final String path;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final parts = path.isEmpty ? <String>[] : path.split('/');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => onNavigate(''),
          icon: const Icon(Icons.home_outlined, size: 18),
          label: Text(AppLocalizations.of(context).ghRoot),
        ),
        for (var i = 0; i < parts.length; i++) ...[
          const Icon(Icons.chevron_right, size: 18),
          TextButton(
            onPressed: () => onNavigate(parts.sublist(0, i + 1).join('/')),
            child: Text(parts[i]),
          ),
        ],
      ],
    );
  }
}

class _ContentsList extends ConsumerWidget {
  const _ContentsList({required this.contents, required this.onOpenDir});

  final ContentsRef contents;
  final ValueChanged<String> onOpenDir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final async = ref.watch(githubContentsProvider(contents));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(
            e is GithubException &&
                    (e.kind == GithubErrorKind.emptyRepository ||
                        (e.kind == GithubErrorKind.notFound &&
                            contents.path.isEmpty))
                ? l10n.ghRepoEmpty
                : describeError(context, e),
          ),
        ),
      ),
      data: (entries) => Card(
        child: entries.isEmpty
            ? ListTile(title: Text(l10n.ghFolderEmpty))
            : Column(
                children: [
                  for (final e in entries)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        e.type == ContentType.dir
                            ? Icons.folder_outlined
                            : Icons.insert_drive_file_outlined,
                      ),
                      title: Text(e.name),
                      trailing: e.type == ContentType.file
                          ? Text(formatBytes(e.size, locale: locale))
                          : const Icon(Icons.chevron_right),
                      onTap: switch (e.type) {
                        ContentType.dir => () => onOpenDir(e.path),
                        _ when e.htmlUrl != null => () => openUrl(
                          context,
                          e.htmlUrl!,
                        ),
                        _ => null,
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

class _CommitsList extends ConsumerWidget {
  const _CommitsList({required this.branchRef});

  final BranchRef branchRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(githubCommitsProvider(branchRef));
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).add_Hm();
    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(
            e is GithubException &&
                    (e.kind == GithubErrorKind.emptyRepository ||
                        e.kind == GithubErrorKind.conflict)
                ? l10n.ghRepoEmpty
                : describeError(context, e),
          ),
        ),
      ),
      data: (commits) => Card(
        child: Column(
          children: [
            for (final c in commits)
              ListTile(
                dense: true,
                leading: const Icon(Icons.commit),
                title: Text(c.title, maxLines: 2),
                subtitle: Text(
                  [
                    c.shortSha,
                    ?c.author,
                    if (c.date != null) dateFormat.format(c.date!),
                  ].join(' · '),
                ),
                onTap: () => openUrl(context, c.htmlUrl),
              ),
          ],
        ),
      ),
    );
  }
}
