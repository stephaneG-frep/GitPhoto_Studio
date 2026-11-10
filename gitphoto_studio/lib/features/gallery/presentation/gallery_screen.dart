import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../application/drop_expansion.dart';
import '../application/gallery_providers.dart';
import '../application/media_importer.dart';
import '../domain/media_item.dart';
import '../domain/media_query.dart';
import '../../media_editor/application/editor_providers.dart';
import '../../media_editor/domain/optimization.dart';
import '../../media_editor/presentation/album_dialogs.dart';
import '../../media_editor/presentation/media_edit_page.dart'
    show VersionJobBanner;
import 'import_report_dialog.dart';
import 'media_tile.dart';

bool get _supportsDrop =>
    Platform.isLinux || Platform.isMacOS || Platform.isWindows;

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _search = TextEditingController();
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(galleryQueryProvider).search;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickAndImport() async {
    final l10n = AppLocalizations.of(context);
    final List<ImportCandidate> picked;
    try {
      picked = await ref.read(mediaPickerProvider).pick();
    } on Exception catch (e) {
      if (!mounted) return;
      _snack(l10n.importPickerError('$e'));
      return;
    }
    await ref.read(importControllerProvider.notifier).importFiles(picked);
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    final candidates = expandDroppedPaths(details.files.map((f) => f.path));
    await ref.read(importControllerProvider.notifier).importFiles(candidates);
  }

  void _snack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          // Avec une action, Flutter garde le message affiché par défaut : il
          // masquerait alors les commandes de la visionneuse.
          persist: false,
          duration: const Duration(seconds: 6),
        ),
      );
  }

  void _showReport(ImportReport report) {
    final l10n = AppLocalizations.of(context);
    final text = report.cancelled
        ? l10n.importCancelled(report.count(ImportOutcome.imported))
        : l10n.importSummary(
            report.count(ImportOutcome.imported),
            report.count(ImportOutcome.duplicate),
            report.count(ImportOutcome.unsupported),
            report.count(ImportOutcome.failed),
          );
    _snack(
      text,
      action: SnackBarAction(
        label: l10n.importDetails,
        onPressed: () => showImportReport(context, report),
      ),
    );
  }

  Future<void> _confirmRemove(Set<int> ids) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(l10n.galleryRemoveTitle(ids.length)),
        content: Text(l10n.galleryRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.galleryRemoveConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final count = ref.read(importControllerProvider.notifier).removeMedia(ids);
    _snack(l10n.galleryRemoved(count));
  }

  Future<void> _optimizeSelection(List<MediaItem> selected) async {
    final l10n = AppLocalizations.of(context);
    final images = selected.where((m) => !m.isVideo).toList();
    final choice = await showDialog<(ImagePreset, MetadataPolicy)>(
      context: context,
      builder: (_) => _BatchOptimizeDialog(
        count: images.length,
        hasVideos: images.length != selected.length,
      ),
    );
    if (choice == null || images.isEmpty) return;
    final (preset, metadata) = choice;
    final result = await ref
        .read(versionJobProvider.notifier)
        .optimizeImages(
          images,
          imagePresets[preset]!.copyWith(metadata: metadata),
          suffix: switch (preset) {
            ImagePreset.light => 'leger',
            ImagePreset.thumbnail => 'miniature',
            _ => 'web',
          },
        );
    if (result != null && mounted) {
      ref.read(gallerySelectionProvider.notifier).clear();
      _snack(l10n.jobDone(result.created));
    }
  }

  Future<void> _addToAlbum(Set<int> ids) async {
    final l10n = AppLocalizations.of(context);
    final albums = ref.read(albumsProvider);
    final picked = await showDialog<Object>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.galleryAddToAlbum),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'new'),
            child: ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(l10n.albumNew),
            ),
          ),
          for (final a in albums)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, a.id),
              child: ListTile(
                leading: const Icon(Icons.photo_album_outlined),
                title: Text(a.name),
                subtitle: Text(l10n.albumCount(a.count)),
              ),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final albumRepo = ref.read(albumRepositoryProvider);
    int albumId;
    if (picked == 'new') {
      final name = await showAlbumNameDialog(
        context,
        title: l10n.albumNew,
        action: l10n.albumCreate,
      );
      if (name == null) return;
      albumId = albumRepo.findOrCreate(name);
    } else {
      albumId = picked as int;
    }
    ref.read(mediaRepositoryProvider).setAlbum(ids, albumId);
    final name = ref
        .read(albumRepositoryProvider)
        .list()
        .firstWhere((a) => a.id == albumId)
        .name;
    ref.read(gallerySelectionProvider.notifier).clear();
    refreshLibraryFromWidget(ref);
    _snack(l10n.galleryMovedToAlbum(ids.length, name));
  }

  void _open(MediaItem item) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    context.push('/media/${item.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = ref.watch(mediaListProvider);
    final query = ref.watch(galleryQueryProvider);
    final selection = ref.watch(gallerySelectionProvider);
    final viewMode = ref.watch(galleryViewModeProvider);
    final importState = ref.watch(importControllerProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppTheme.wideBreakpoint;

    ref.listen(importControllerProvider, (previous, next) {
      if (next is ImportFinished) {
        _showReport(next.report);
        ref.read(importControllerProvider.notifier).acknowledge();
      }
    });

    final hasFilters =
        query.search.trim().isNotEmpty || query.filter != MediaFilter.all;

    Widget body = SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isWide ? 32 : 12,
          isWide ? 24 : 12,
          isWide ? 32 : 12,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide) ...[
              Semantics(
                header: true,
                child: Text(
                  l10n.navGallery,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _SearchRow(
              controller: _search,
              importing: importState is ImportRunning,
              onSearch: (v) =>
                  ref.read(galleryQueryProvider.notifier).setSearch(v),
              onImport: _pickAndImport,
            ),
            const SizedBox(height: 8),
            if (selection.isEmpty)
              _FilterRow(query: query, viewMode: viewMode)
            else
              _SelectionRow(
                selection: selection,
                allIds: items.map((m) => m.id),
                onRemove: () => _confirmRemove(selection),
                onOptimize: () => _optimizeSelection(
                  items.where((m) => selection.contains(m.id)).toList(),
                ),
                onAddToAlbum: () => _addToAlbum(selection),
              ),
            if (importState is ImportRunning) _ImportBanner(state: importState),
            const VersionJobBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                l10n.galleryCount(items.length),
                style: theme.textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _EmptyState(filtered: hasFilters)
                  : MediaCollection(
                      items: items,
                      viewMode: viewMode,
                      selection: selection,
                      onOpen: _open,
                      onToggle: (item) => ref
                          .read(gallerySelectionProvider.notifier)
                          .toggle(item.id),
                    ),
            ),
          ],
        ),
      ),
    );

    if (_supportsDrop) {
      body = DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: _onDrop,
        child: Stack(
          children: [
            Positioned.fill(child: body),
            if (_dragging) const Positioned.fill(child: _DropOverlay()),
          ],
        ),
      );
    }
    return body;
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.importing,
    required this.onSearch,
    required this.onImport,
  });

  final TextEditingController controller;
  final bool importing;
  final ValueChanged<String> onSearch;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.gallerySearchHint,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: importing ? null : onImport,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(l10n.galleryImport),
        ),
      ],
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.query, required this.viewMode});

  final MediaListQuery query;
  final GalleryViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(galleryQueryProvider.notifier);
    String sortLabel(MediaSort s) => switch (s) {
      MediaSort.date => l10n.gallerySortDate,
      MediaSort.name => l10n.gallerySortName,
      MediaSort.type => l10n.gallerySortType,
      MediaSort.size => l10n.gallerySortSize,
    };

    final albums = ref.watch(albumsProvider);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (albums.isNotEmpty)
          DropdownButton<int?>(
            value: albums.any((a) => a.id == query.albumId)
                ? query.albumId
                : null,
            underline: const SizedBox.shrink(),
            onChanged: controller.setAlbum,
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.galleryAllAlbums)),
              for (final a in albums)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
          ),
        SegmentedButton<MediaFilter>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: MediaFilter.all,
              label: Text(l10n.galleryFilterAll),
            ),
            ButtonSegment(
              value: MediaFilter.images,
              label: Text(l10n.galleryFilterImages),
            ),
            ButtonSegment(
              value: MediaFilter.videos,
              label: Text(l10n.galleryFilterVideos),
            ),
          ],
          selected: {query.filter},
          onSelectionChanged: (s) => controller.setFilter(s.first),
        ),
        PopupMenuButton<MediaSort>(
          tooltip: l10n.gallerySort,
          initialValue: query.sort,
          onSelected: controller.setSort,
          itemBuilder: (context) => [
            for (final s in MediaSort.values)
              PopupMenuItem(value: s, child: Text(sortLabel(s))),
          ],
          child: Padding(
            // 12 + 24 + 12 : cible tactile de 48 px (accessibilité).
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort),
                const SizedBox(width: 4),
                Text(sortLabel(query.sort)),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: query.ascending
              ? l10n.gallerySortAscending
              : l10n.gallerySortDescending,
          onPressed: controller.toggleDirection,
          icon: Icon(
            query.ascending ? Icons.arrow_upward : Icons.arrow_downward,
          ),
        ),
        IconButton(
          tooltip: viewMode == GalleryViewMode.grid
              ? l10n.galleryViewList
              : l10n.galleryViewGrid,
          onPressed: () => ref
              .read(galleryViewModeProvider.notifier)
              .set(
                viewMode == GalleryViewMode.grid
                    ? GalleryViewMode.list
                    : GalleryViewMode.grid,
              ),
          icon: Icon(
            viewMode == GalleryViewMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
          ),
        ),
      ],
    );
  }
}

class _SelectionRow extends ConsumerWidget {
  const _SelectionRow({
    required this.selection,
    required this.allIds,
    required this.onRemove,
    required this.onOptimize,
    required this.onAddToAlbum,
  });

  final Set<int> selection;
  final Iterable<int> allIds;
  final VoidCallback onRemove;
  final VoidCallback onOptimize;
  final VoidCallback onAddToAlbum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(gallerySelectionProvider.notifier);
    return Row(
      children: [
        IconButton(
          tooltip: l10n.galleryClearSelection,
          onPressed: notifier.clear,
          icon: const Icon(Icons.close),
        ),
        Expanded(
          child: Text(
            l10n.gallerySelectedCount(selection.length),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          tooltip: l10n.gallerySelectAll,
          onPressed: () => notifier.selectAll(allIds),
          icon: const Icon(Icons.select_all),
        ),
        IconButton(
          tooltip: l10n.galleryOptimize,
          onPressed: onOptimize,
          icon: const Icon(Icons.auto_fix_high),
        ),
        IconButton(
          tooltip: l10n.galleryAddToAlbum,
          onPressed: onAddToAlbum,
          icon: const Icon(Icons.photo_album_outlined),
        ),
        IconButton(
          tooltip: l10n.galleryRemove,
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _ImportBanner extends ConsumerWidget {
  const _ImportBanner({required this.state});

  final ImportRunning state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.importProgress(state.done, state.total)),
                      Text(
                        state.current,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(importControllerProvider.notifier).cancel(),
                  child: Text(l10n.importStop),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: state.total == 0 ? null : state.done / state.total,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const PixelMascot(size: 96),
            const SizedBox(height: 16),
            if (filtered)
              Text(l10n.galleryNoResults, textAlign: TextAlign.center)
            else ...[
              Text(
                l10n.galleryEmptyTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(l10n.galleryEmptyBody, textAlign: TextAlign.center),
              ),
              if (_supportsDrop) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.galleryEmptyDropHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final studio = StudioColors.of(context);
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: studio.accent, width: 3),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.file_download_outlined,
                size: 64,
                color: studio.accent,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).galleryDropHere,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchOptimizeDialog extends StatefulWidget {
  const _BatchOptimizeDialog({required this.count, required this.hasVideos});

  final int count;
  final bool hasVideos;

  @override
  State<_BatchOptimizeDialog> createState() => _BatchOptimizeDialogState();
}

class _BatchOptimizeDialogState extends State<_BatchOptimizeDialog> {
  ImagePreset _preset = ImagePreset.web;
  MetadataPolicy _metadata = MetadataPolicy.stripAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.auto_fix_high),
      title: Text(l10n.galleryOptimizeTitle(widget.count)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.editorOriginalsSafe),
            if (widget.hasVideos) ...[
              const SizedBox(height: 8),
              Text(l10n.galleryOptimizeVideosIgnored),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final (p, label) in [
                  (ImagePreset.web, l10n.presetWeb),
                  (ImagePreset.light, l10n.presetLight),
                  (ImagePreset.thumbnail, l10n.presetThumbnail),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _preset == p,
                    onSelected: (_) => setState(() => _preset = p),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RadioGroup<MetadataPolicy>(
              groupValue: _metadata,
              onChanged: (v) {
                if (v != null) setState(() => _metadata = v);
              },
              child: Column(
                children: [
                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: MetadataPolicy.stripAll,
                    title: Text(l10n.metaStripAll),
                  ),
                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: MetadataPolicy.keepDateAndCamera,
                    title: Text(l10n.metaKeepBasic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: widget.count == 0
              ? null
              : () => Navigator.pop(context, (_preset, _metadata)),
          child: Text(l10n.galleryOptimize),
        ),
      ],
    );
  }
}
