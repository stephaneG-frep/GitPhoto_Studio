import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/byte_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/open_url.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../../gallery/application/gallery_providers.dart';
import '../../gallery/domain/media_item.dart';
import '../../gallery/domain/media_query.dart';
import '../../gallery/presentation/media_tile.dart';
import '../../github/application/github_session.dart';
import '../../github/domain/github_models.dart';
import '../../github/presentation/github_error_text.dart';
import '../application/publish_controller.dart';
import '../application/publish_queue.dart';
import '../application/publisher.dart';
import '../domain/publish_plan.dart';
import '../domain/transport_selector.dart';

/// Assistant de publication. Les paramètres facultatifs présélectionnent la
/// destination (depuis le navigateur de dépôt).
class PublishScreen extends ConsumerWidget {
  const PublishScreen({
    super.key,
    this.owner,
    this.repo,
    this.branch,
    this.folder,
  });

  final String? owner;
  final String? repo;
  final String? branch;
  final String? folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(githubSessionProvider).value;
    final hasMedia = ref
        .watch(mediaRepositoryProvider)
        .list(const MediaListQuery())
        .isNotEmpty;

    if (session is! GithubConnected) {
      return ScreenFrame(
        title: l10n.navPublish,
        children: [
          PixelTip(message: l10n.pubNotConnected),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => context.go('/github'),
              icon: const Icon(Icons.hub_outlined),
              label: Text(l10n.pubGoToGithub),
            ),
          ),
        ],
      );
    }
    if (!hasMedia) {
      return ScreenFrame(
        title: l10n.navPublish,
        children: [PixelTip(message: l10n.pubNoMedia)],
      );
    }
    return _PublishWizard(
      owner: owner,
      repo: repo,
      branch: branch,
      folder: folder,
    );
  }
}

class _PublishWizard extends ConsumerStatefulWidget {
  const _PublishWizard({this.owner, this.repo, this.branch, this.folder});

  final String? owner;
  final String? repo;
  final String? branch;
  final String? folder;

  @override
  ConsumerState<_PublishWizard> createState() => _PublishWizardState();
}

class _PublishWizardState extends ConsumerState<_PublishWizard> {
  static const _stepMedia = 0;
  static const _stepDestination = 1;
  static const _stepAnalysis = 2;
  static const _stepMessage = 3;
  static const _stepReview = 4;
  static const _stepResult = 5;

  int _step = _stepMedia;
  late Set<int> _selected;
  GithubRepo? _repo;
  String? _branch;
  late final _folder = TextEditingController(text: widget.folder ?? 'photos');
  final _message = TextEditingController();
  final Set<int> _overwrite = {};

  @override
  void initState() {
    super.initState();
    _selected = {...ref.read(gallerySelectionProvider)};
    _branch = widget.branch;
    final state = ref.read(publishControllerProvider);
    if (state is PublishRunning) _step = _stepResult;
    if (state is! PublishRunning) {
      Future.microtask(
        () => ref.read(publishControllerProvider.notifier).reset(),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_message.text.isEmpty && _selected.isNotEmpty) {
      _message.text = AppLocalizations.of(
        context,
      ).pubMessageDefault(_selected.length);
    }
  }

  @override
  void dispose() {
    _folder.dispose();
    _message.dispose();
    super.dispose();
  }

  List<MediaItem> get _allMedia => ref
      .read(mediaRepositoryProvider)
      .list(const MediaListQuery(sort: MediaSort.name, ascending: true));

  String? get _normalizedFolder => PublishPlanner.normalizeFolder(_folder.text);

  bool get _destinationValid =>
      _repo != null && _branch != null && _normalizedFolder != null;

  void _analyze() {
    final media = _allMedia.where((m) => _selected.contains(m.id)).toList();
    ref
        .read(publishControllerProvider.notifier)
        .analyze(
          media: media,
          target: PublishTarget(
            repo: _repo!,
            branch: _branch!,
            folder: _normalizedFolder!,
          ),
          overwriteMediaIds: _overwrite,
        );
  }

  Future<void> _confirmAndPublish(PublishPlanned planned) async {
    final l10n = AppLocalizations.of(context);
    final repo = planned.target.repo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_upload_outlined),
        title: Text(l10n.pubConfirmTitle),
        content: Text(
          l10n.pubConfirmBody(
            planned.plan.uploads.length,
            repo.fullName,
            repo.isPrivate ? l10n.ghPrivate : l10n.ghPublic,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.pubConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _step = _stepResult);
    await ref
        .read(publishControllerProvider.notifier)
        .publish(_message.text.trim());
  }

  void _restart() {
    ref.read(publishControllerProvider.notifier).reset();
    setState(() {
      _step = _stepMedia;
      _overwrite.clear();
      _message.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(publishControllerProvider);
    final repos = ref.watch(githubReposProvider);
    final media = _allMedia;

    // Destination présélectionnée.
    if (_repo == null && widget.owner != null && repos.value != null) {
      for (final r in repos.value!) {
        if (r.owner == widget.owner && r.name == widget.repo) _repo = r;
      }
    }
    final planned = state is PublishPlanned ? state : null;
    final busy = state is PublishAnalyzing || state is PublishRunning;

    bool canContinue() => switch (_step) {
      _stepMedia => _selected.isNotEmpty,
      _stepDestination => _destinationValid,
      _stepAnalysis => planned != null && planned.plan.uploads.isNotEmpty,
      _stepMessage => _message.text.trim().isNotEmpty,
      _stepReview =>
        planned != null &&
            planned.plan.uploads.isNotEmpty &&
            _message.text.trim().isNotEmpty,
      _ => false,
    };

    void onContinue() {
      if (_step == _stepDestination) _analyze();
      if (_step == _stepReview && planned != null) {
        _confirmAndPublish(planned);
        return;
      }
      setState(() => _step++);
    }

    StepState stepState(int i) => _step > i
        ? StepState.complete
        : (_step == i ? StepState.editing : StepState.indexed);

    return ScreenFrame(
      title: l10n.navPublish,
      children: [
        Stepper(
          physics: const NeverScrollableScrollPhysics(),
          currentStep: _step,
          onStepTapped: busy || _step == _stepResult
              ? null
              : (i) {
                  if (i < _step) setState(() => _step = i);
                },
          controlsBuilder: (context, details) {
            if (_step == _stepResult) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: !busy && canContinue() ? onContinue : null,
                    child: Text(
                      _step == _stepReview
                          ? l10n.pubConfirm
                          : l10n.commonContinue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_step > 0)
                    TextButton(
                      onPressed: busy ? null : () => setState(() => _step--),
                      child: Text(l10n.commonBack),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text(l10n.pubStepMedia),
              subtitle: Text(l10n.pubSelectedCount(_selected.length)),
              state: stepState(_stepMedia),
              content: _MediaPicker(
                media: media,
                selected: _selected,
                onChanged: (s) => setState(() {
                  _selected = s;
                  _message.text = l10n.pubMessageDefault(s.length);
                }),
              ),
            ),
            Step(
              title: Text(l10n.pubStepDestination),
              subtitle: _repo == null
                  ? null
                  : Text('${_repo!.fullName} · ${_branch ?? ''}'),
              state: stepState(_stepDestination),
              content: _DestinationForm(
                repos: repos,
                repo: _repo,
                branch: _branch,
                folder: _folder,
                onRepo: (r) => setState(() {
                  _repo = r;
                  _branch = r.defaultBranch;
                }),
                onBranch: (b) => setState(() => _branch = b),
                onFolderChanged: () => setState(() {}),
              ),
            ),
            Step(
              title: Text(l10n.pubStepAnalysis),
              state: stepState(_stepAnalysis),
              content: _AnalysisView(
                state: state,
                overwrite: _overwrite,
                onToggleOverwrite: (id, value) {
                  setState(() {
                    value ? _overwrite.add(id) : _overwrite.remove(id);
                  });
                  _analyze();
                },
                onRetry: _analyze,
              ),
            ),
            Step(
              title: Text(l10n.pubStepMessage),
              state: stepState(_stepMessage),
              content: TextField(
                controller: _message,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.pubMessageLabel,
                  errorText: _message.text.trim().isEmpty
                      ? l10n.pubMessageEmpty
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Step(
              title: Text(l10n.pubStepReview),
              state: stepState(_stepReview),
              content: planned == null
                  ? const SizedBox.shrink()
                  : _ReviewView(planned: planned, message: _message.text),
            ),
            Step(
              title: Text(l10n.pubStepResult),
              state: stepState(_stepResult),
              content: _ResultView(state: state, onRestart: _restart),
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaPicker extends StatelessWidget {
  const _MediaPicker({
    required this.media,
    required this.selected,
    required this.onChanged,
  });

  final List<MediaItem> media;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final allSelected = selected.length == media.length;
    return Column(
      children: [
        CheckboxListTile(
          value: allSelected,
          title: Text(l10n.gallerySelectAll),
          onChanged: (v) =>
              onChanged(v == true ? {for (final m in media) m.id} : {}),
        ),
        const Divider(height: 1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final m in media)
                CheckboxListTile(
                  value: selected.contains(m.id),
                  onChanged: (v) => onChanged(
                    v == true
                        ? {...selected, m.id}
                        : ({...selected}..remove(m.id)),
                  ),
                  secondary: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox.square(
                      dimension: 40,
                      child: MediaThumbnail(item: m, size: 80),
                    ),
                  ),
                  title: Text(m.fileName, overflow: TextOverflow.ellipsis),
                  subtitle: Text(formatBytes(m.sizeBytes, locale: locale)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DestinationForm extends ConsumerWidget {
  const _DestinationForm({
    required this.repos,
    required this.repo,
    required this.branch,
    required this.folder,
    required this.onRepo,
    required this.onBranch,
    required this.onFolderChanged,
  });

  final AsyncValue<List<GithubRepo>> repos;
  final GithubRepo? repo;
  final String? branch;
  final TextEditingController folder;
  final ValueChanged<GithubRepo> onRepo;
  final ValueChanged<String> onBranch;
  final VoidCallback onFolderChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final writable = (repos.value ?? const <GithubRepo>[])
        .where((r) => r.canPush)
        .toList();
    final selected = repo;
    final branches = selected == null
        ? null
        : ref.watch(
            githubBranchesProvider((
              owner: selected.owner,
              name: selected.name,
            )),
          );
    final branchList = branches?.value ?? const <String>[];
    final folderValid = PublishPlanner.normalizeFolder(folder.text) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (repos.isLoading) const LinearProgressIndicator(),
        if (repos.hasError) Text(describeError(context, repos.error!)),
        DropdownMenu<GithubRepo>(
          key: ValueKey(selected?.fullName),
          expandedInsets: EdgeInsets.zero,
          label: Text(l10n.pubRepository),
          hintText: l10n.pubChooseRepository,
          initialSelection: selected,
          enableFilter: true,
          requestFocusOnTap: true,
          onSelected: (r) {
            if (r != null) onRepo(r);
          },
          dropdownMenuEntries: [
            for (final r in writable)
              DropdownMenuEntry(
                value: r,
                label: r.fullName,
                leadingIcon: Icon(
                  r.isPrivate ? Icons.lock_outline : Icons.public,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (selected != null) ...[
          if (branches!.isLoading) const LinearProgressIndicator(),
          if (branchList.isNotEmpty)
            DropdownMenu<String>(
              key: ValueKey('${selected.fullName}:$branch'),
              expandedInsets: EdgeInsets.zero,
              label: Text(l10n.ghBranch),
              initialSelection: branchList.contains(branch)
                  ? branch
                  : branchList.first,
              onSelected: (b) {
                if (b != null) onBranch(b);
              },
              dropdownMenuEntries: [
                for (final b in branchList)
                  DropdownMenuEntry(value: b, label: b),
              ],
            )
          else if (!branches.isLoading)
            Text(l10n.pubEmptyRepoNote),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: folder,
          onChanged: (_) => onFolderChanged(),
          decoration: InputDecoration(
            labelText: l10n.pubFolder,
            helperText: l10n.pubFolderHelp,
            helperMaxLines: 3,
            errorText: folderValid ? null : l10n.pubFolderInvalid,
            prefixIcon: const Icon(Icons.folder_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _AnalysisView extends StatelessWidget {
  const _AnalysisView({
    required this.state,
    required this.overwrite,
    required this.onToggleOverwrite,
    required this.onRetry,
  });

  final PublishState state;
  final Set<int> overwrite;
  final void Function(int mediaId, bool value) onToggleOverwrite;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final s = state;

    if (s is PublishAnalyzing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.pubAnalyzing(s.done, s.total)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: s.total == 0 ? null : s.done / s.total,
          ),
        ],
      );
    }
    if (s is PublishFailed && s.plan == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            describeError(context, s.error),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      );
    }
    if (s is! PublishPlanned) return const SizedBox.shrink();

    final plan = s.plan;
    final isPublic = !s.target.repo.isPrivate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pubSummaryCounts(
            plan.uploads.length,
            formatBytes(plan.uploadBytes, locale: locale),
            plan.count(PlannedAction.skipIdentical),
            plan.count(PlannedAction.blocked),
          ),
          style: theme.textTheme.titleSmall,
        ),
        if (plan.repositoryIsEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.pubEmptyRepoNote),
        ],
        if (plan.usesLfs) ...[
          const SizedBox(height: 8),
          Text(l10n.pubLfsQuotaNote),
        ],
        if (plan.remoteTreeTruncated) ...[
          const SizedBox(height: 8),
          Text(l10n.pubTruncatedTree),
        ],
        if (plan.uploads.isEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.pubNothingToUpload),
        ],
        const SizedBox(height: 8),
        for (final f in plan.files)
          _PlannedTile(
            file: f,
            isPublic: isPublic,
            overwrite: overwrite.contains(f.candidate.mediaId),
            // L'assistant de publication ne traite que des médias de la bibliothèque.
            onToggleOverwrite: (v) =>
                onToggleOverwrite(f.candidate.mediaId!, v),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.auto_fix_high_outlined,
              color: studio.creative,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.pubOptimizationNote,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlannedTile extends StatelessWidget {
  const _PlannedTile({
    required this.file,
    required this.isPublic,
    required this.overwrite,
    required this.onToggleOverwrite,
  });

  final PlannedFile file;
  final bool isPublic;
  final bool overwrite;
  final ValueChanged<bool> onToggleOverwrite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final (icon, color, label) = switch (file.action) {
      PlannedAction.add => (
        Icons.add_circle_outline,
        studio.success,
        l10n.pubActionAdd,
      ),
      PlannedAction.skipIdentical => (
        Icons.check_circle_outline,
        theme.colorScheme.outline,
        l10n.pubActionSkip,
      ),
      PlannedAction.renamed => (
        Icons.drive_file_rename_outline,
        studio.accent,
        l10n.pubActionRenamed,
      ),
      PlannedAction.overwrite => (
        Icons.sync_problem,
        studio.creative,
        l10n.pubActionOverwrite,
      ),
      PlannedAction.blocked => (
        Icons.block,
        theme.colorScheme.error,
        switch (file.blockReason) {
          BlockReason.requiresGitLfs => l10n.pubBlockedLfs,
          BlockReason.tooLargeForLfs => l10n.pubBlockedLfsMax,
          _ => l10n.pubBlockedPath,
        },
      ),
    };
    final notes = <String>[
      label,
      if (file.willUpload && file.isLfs) l10n.pubViaLfs,
      if (file.willUpload && file.strategy == PublishStrategy.nativeGit)
        l10n.pubViaGit,
      if (file.warnings.contains(TransportWarning.largeFile)) l10n.pubWarnLarge,
      if (isPublic && file.candidate.hasGps && file.willUpload)
        l10n.pubWarnGpsPublic,
    ];
    final isConflict =
        file.action == PlannedAction.renamed ||
        file.action == PlannedAction.overwrite;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(icon, color: color),
            title: Text(file.remotePath),
            subtitle: Text(notes.join('\n')),
          ),
          if (isConflict && file.remotePath != file.candidate.fileName)
            SwitchListTile(
              dense: true,
              value: overwrite,
              onChanged: onToggleOverwrite,
              title: Text(l10n.pubOverwriteToggle),
            ),
        ],
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.planned, required this.message});

  final PublishPlanned planned;
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = planned.plan;
    final overwrites = plan.count(PlannedAction.overwrite);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pubReviewIntro),
        const SizedBox(height: 8),
        Text(
          l10n.pubReviewTarget(
            planned.target.repo.fullName,
            planned.target.branch,
          ),
          style: theme.textTheme.titleSmall,
        ),
        Text('« $message »', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        for (final f in plan.uploads)
          Text(
            '${f.action == PlannedAction.overwrite ? '↻' : '+'} ${f.remotePath}',
          ),
        const SizedBox(height: 8),
        Text(
          plan.repositoryIsEmpty
              ? l10n.pubEmptyRepoNote
              : l10n.pubReviewSingleCommit,
        ),
        if (overwrites > 0)
          Text(
            l10n.pubReviewOverwriteWarning(overwrites),
            style: TextStyle(color: StudioColors.of(context).creative),
          ),
        const SizedBox(height: 8),
        Text(l10n.pubQueuedNote, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.onRestart});

  final PublishState state;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final s = state;
    switch (s) {
      case PublishRunning(:final step, :final done, :final total):
        final text = switch (step) {
          PublishStep.uploading => l10n.pubStepUploading(done, total),
          PublishStep.committing => l10n.pubStepCommitting,
          PublishStep.updatingBranch => l10n.pubStepUpdating,
          PublishStep.verifying => l10n.pubStepVerifying,
        };
        return Consumer(
          builder: (context, ref, _) {
            final progress = ref.watch(publishQueueProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: step == PublishStep.uploading && total > 0
                      ? done / total
                      : null,
                ),
                const SizedBox(height: 8),
                Text(l10n.pubQueuedNote, style: theme.textTheme.bodySmall),
                if (progress != null &&
                    step != PublishStep.updatingBranch &&
                    step != PublishStep.verifying)
                  TextButton.icon(
                    onPressed: () => ref
                        .read(publishQueueProvider.notifier)
                        .cancel(progress.operationId),
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(l10n.pubCancelRunning),
                  ),
              ],
            );
          },
        );
      case PublishSucceeded(:final result):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: studio.success),
                const SizedBox(width: 8),
                Text(l10n.pubSuccess, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.verified ? l10n.pubVerified : l10n.pubNotVerified),
            SelectableText(l10n.pubCommit(result.commitSha)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => openUrl(context, result.htmlUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.commonOpenInBrowser),
                ),
                TextButton(onPressed: onRestart, child: Text(l10n.pubNew)),
              ],
            ),
          ],
        );
      case PublishFailed(:final error):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(l10n.pubFailed, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(describeError(context, error)),
            TextButton(onPressed: onRestart, child: Text(l10n.pubNew)),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
