import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/security/path_validator.dart';
import '../../../core/utils/byte_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../../gallery/application/gallery_providers.dart';
import '../../gallery/application/media_importer.dart';
import '../../gallery/domain/media_item.dart';
import '../../gallery/presentation/media_tile.dart';
import '../application/editor_providers.dart';
import '../application/media_version_service.dart';
import '../domain/optimization.dart';

/// Retouche d'un média : renommage, album, optimisation d'image avec aperçu,
/// préparation vidéo. Toute production est une nouvelle version.
class MediaEditPage extends ConsumerWidget {
  const MediaEditPage({super.key, required this.mediaId});

  final int mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(mediaByIdProvider(mediaId));
    if (item == null) {
      return ScreenFrame(
        title: l10n.navEditor,
        children: [Text(l10n.viewerNotFound)],
      );
    }
    final source = item.derivedFrom == null
        ? null
        : ref.watch(mediaByIdProvider(item.derivedFrom!));
    return ScreenFrame(
      title: item.fileName,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.commonBack,
              onPressed: () => context.go('/editor'),
              icon: const Icon(Icons.arrow_back),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: 64,
                child: MediaThumbnail(item: item, size: 128),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    [
                      formatBytes(
                        item.sizeBytes,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                      if (item.width != null) '${item.width}×${item.height}',
                      if (item.durationMs != null)
                        formatDuration(item.durationMs!),
                    ].join(' · '),
                  ),
                  if (source != null)
                    Text(
                      l10n.editorVersionOf(source.fileName),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _RenameAndAlbum(key: ValueKey('meta-${item.id}'), item: item),
        const VersionJobBanner(),
        if (item.isVideo)
          _VideoSection(item: item)
        else
          _ImageSection(key: ValueKey('img-${item.id}'), item: item),
      ],
    );
  }
}

class _RenameAndAlbum extends ConsumerStatefulWidget {
  const _RenameAndAlbum({super.key, required this.item});

  final MediaItem item;

  @override
  ConsumerState<_RenameAndAlbum> createState() => _RenameAndAlbumState();
}

class _RenameAndAlbumState extends ConsumerState<_RenameAndAlbum> {
  late final _name = TextEditingController(text: widget.item.fileName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid {
    final n = _name.text.trim();
    return n.isNotEmpty && PathValidator.validateFileName(n).isValid;
  }

  void _rename() {
    final l10n = AppLocalizations.of(context);
    ref.read(mediaRepositoryProvider).rename(widget.item.id, _name.text.trim());
    refreshLibraryFromWidget(ref);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.editorRenamed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final albums = ref.watch(albumsProvider);
    final changed = _name.text.trim() != widget.item.fileName;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.editorFileName,
                      errorText: _valid ? null : l10n.editorRenameInvalid,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.tonal(
                    onPressed: _valid && changed ? _rename : null,
                    child: Text(l10n.editorRename),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownMenu<int?>(
              key: ValueKey('album-${widget.item.albumId}-${albums.length}'),
              expandedInsets: EdgeInsets.zero,
              label: Text(l10n.editorAlbum),
              initialSelection: widget.item.albumId,
              onSelected: (albumId) {
                ref.read(mediaRepositoryProvider).setAlbum([
                  widget.item.id,
                ], albumId);
                refreshLibraryFromWidget(ref);
              },
              dropdownMenuEntries: [
                DropdownMenuEntry(value: null, label: l10n.editorNoAlbum),
                for (final a in albums)
                  DropdownMenuEntry(value: a.id, label: a.name),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Progression et résultat des traitements longs.
class VersionJobBanner extends ConsumerWidget {
  const VersionJobBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(versionJobProvider);
    return switch (state) {
      VersionJobIdle() => const SizedBox.shrink(),
      VersionJobRunning(:final done, :final total, :final progress) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progress != null && total == 1
                          ? l10n.videoConverting((progress * 100).round())
                          : l10n.jobBatchProgress(done, total),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(versionJobProvider.notifier).cancel(),
                    child: Text(l10n.jobStop),
                  ),
                ],
              ),
              LinearProgressIndicator(
                value: progress ?? (total == 0 ? null : done / total),
              ),
            ],
          ),
        ),
      ),
      VersionJobFinished(:final cancelled, :final error, :final results) =>
        Card(
          child: ListTile(
            leading: Icon(
              error == null && !cancelled
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
            ),
            title: Text(
              error is VideoNotSmallerException
                  ? l10n.videoNotSmaller(
                      formatBytes(
                        error.sourceBytes,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                      formatBytes(
                        error.outputBytes,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                    )
                  : error != null
                  ? l10n.jobFailed('$error')
                  : cancelled
                  ? l10n.jobCancelled
                  : results.any((r) => r.outcome == ImportOutcome.duplicate)
                  ? l10n.editorVersionDuplicate
                  : l10n.jobDone(state.created),
            ),
            trailing: IconButton(
              tooltip: l10n.commonClose,
              onPressed: () =>
                  ref.read(versionJobProvider.notifier).acknowledge(),
              icon: const Icon(Icons.close),
            ),
          ),
        ),
    };
  }
}

class _ImageSection extends ConsumerStatefulWidget {
  const _ImageSection({super.key, required this.item});

  final MediaItem item;

  @override
  ConsumerState<_ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends ConsumerState<_ImageSection> {
  ImagePreset _preset = ImagePreset.web;
  ImageOptimizeOptions _custom = const ImageOptimizeOptions(maxDimension: 2048);
  MetadataPolicy _metadata = MetadataPolicy.stripAll;
  PreviewResult? _preview;
  bool _busy = false;
  Object? _error;
  late final MediaVersionService _service = ref.read(
    mediaVersionServiceProvider,
  );

  ImageOptimizeOptions get _options =>
      (_preset == ImagePreset.custom ? _custom : imagePresets[_preset]!)
          .copyWith(metadata: _metadata);

  String get _suffix => switch (_preset) {
    ImagePreset.web => 'web',
    ImagePreset.light => 'leger',
    ImagePreset.thumbnail => 'miniature',
    ImagePreset.custom => 'optimise',
  };

  @override
  void initState() {
    super.initState();
    _service; // Résolu tant que `ref` est utilisable.
  }

  @override
  void dispose() {
    _discardPreview();
    super.dispose();
  }

  void _discardPreview() {
    final p = _preview;
    if (p != null) _service.discard(p.path);
    _preview = null;
  }

  void _changed(VoidCallback update) {
    setState(() {
      update();
      _discardPreview();
      _error = null;
    });
  }

  Future<void> _makePreview() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await _service.previewImage(widget.item, _options);
      if (!mounted) {
        _service.discard(p.path);
        return;
      }
      setState(() {
        _discardPreview();
        _preview = p;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(versionJobProvider.notifier)
        .optimizeImages([widget.item], _options, suffix: _suffix);
    final r = result?.results.firstOrNull;
    if (r != null && r.outcome == ImportOutcome.imported) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.editorVersionSaved(r.name)),
          action: r.mediaId == null
              ? null
              : SnackBarAction(
                  label: l10n.viewerEdit,
                  onPressed: () {
                    if (mounted) context.go('/editor/${r.mediaId}');
                  },
                ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final running = ref.watch(versionJobProvider) is VersionJobRunning;
    final preview = _preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.editorImageSection),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (p, label) in [
              (ImagePreset.web, l10n.presetWeb),
              (ImagePreset.light, l10n.presetLight),
              (ImagePreset.thumbnail, l10n.presetThumbnail),
              (ImagePreset.custom, l10n.presetCustom),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _preset == p,
                onSelected: (_) => _changed(() => _preset = p),
              ),
          ],
        ),
        if (_preset == ImagePreset.custom) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.editorKeepDimensions),
            value: _custom.maxDimension == null,
            onChanged: (keep) => _changed(
              () => _custom = _custom.copyWith(
                maxDimension: () => keep ? null : 2048,
              ),
            ),
          ),
          if (_custom.maxDimension != null) ...[
            Text(l10n.editorMaxDimension(_custom.maxDimension!)),
            Slider(
              min: 256,
              max: 4096,
              divisions: 30,
              value: _custom.maxDimension!.toDouble(),
              label: '${_custom.maxDimension}',
              onChanged: (v) => _changed(
                () => _custom = _custom.copyWith(maxDimension: () => v.round()),
              ),
            ),
          ],
          Text(l10n.editorFormat),
          const SizedBox(height: 4),
          SegmentedButton<ImageOutputFormat>(
            segments: const [
              ButtonSegment(value: ImageOutputFormat.jpeg, label: Text('JPEG')),
              ButtonSegment(value: ImageOutputFormat.png, label: Text('PNG')),
            ],
            selected: {_custom.format},
            onSelectionChanged: (s) =>
                _changed(() => _custom = _custom.copyWith(format: s.first)),
          ),
          if (_custom.format == ImageOutputFormat.jpeg) ...[
            const SizedBox(height: 8),
            Text(l10n.editorQuality(_custom.quality)),
            Slider(
              min: 40,
              max: 100,
              divisions: 12,
              value: _custom.quality.toDouble(),
              label: '${_custom.quality}',
              onChanged: (v) => _changed(
                () => _custom = _custom.copyWith(quality: v.round()),
              ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        Text(l10n.editorMetadata),
        RadioGroup<MetadataPolicy>(
          groupValue: _metadata,
          onChanged: (v) {
            if (v != null) _changed(() => _metadata = v);
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy || running ? null : _makePreview,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.preview_outlined),
              label: Text(_busy ? l10n.editorPreviewing : l10n.editorPreview),
            ),
            FilledButton.icon(
              onPressed: _busy || running ? null : _save,
              icon: const Icon(Icons.save_alt),
              label: Text(l10n.editorSaveVersion),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.jobFailed('$_error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.editorSizeChange(
              formatBytes(widget.item.sizeBytes, locale: locale),
              formatBytes(preview.result.sizeBytes, locale: locale),
              _percentChange(widget.item.sizeBytes, preview.result.sizeBytes),
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              color: preview.result.sizeBytes <= widget.item.sizeBytes
                  ? StudioColors.of(context).success
                  : StudioColors.of(context).creative,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 600;
              final children = [
                _ComparePane(
                  label:
                      '${l10n.editorOriginal} · ${widget.item.width ?? '?'}×${widget.item.height ?? '?'}',
                  path: widget.item.storedPath,
                ),
                _ComparePane(
                  label:
                      '${l10n.editorResult} · ${preview.result.width}×${preview.result.height}',
                  path: preview.path,
                ),
              ];
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final c in children)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: c,
                            ),
                          ),
                      ],
                    )
                  : Column(children: children);
            },
          ),
        ],
      ],
    );
  }
}

String _percentChange(int before, int after) {
  if (before == 0) return '—';
  final pct = ((after - before) / before * 100).round();
  return pct <= 0 ? '$pct %' : '+$pct %';
}

class _ComparePane extends StatelessWidget {
  const _ComparePane({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: InteractiveViewer(
              maxScale: 8,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                cacheWidth: 1600,
                errorBuilder: (_, _, _) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoSection extends ConsumerStatefulWidget {
  const _VideoSection({required this.item});

  final MediaItem item;

  @override
  ConsumerState<_VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends ConsumerState<_VideoSection> {
  VideoPreset _preset = VideoPreset.p720;
  bool _removeAudio = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final transcoder = ref.watch(videoTranscoderProvider);
    final running = ref.watch(versionJobProvider) is VersionJobRunning;
    final duration = widget.item.durationMs;

    if (!transcoder.isSupported) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(l10n.editorVideoSection),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                Platform.isLinux
                    ? l10n.videoUnavailableLinux
                    : l10n.videoUnavailable,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.editorVideoSection),
        Wrap(
          spacing: 8,
          children: [
            for (final (p, label) in [
              (VideoPreset.light, l10n.videoPresetLight),
              (VideoPreset.p720, l10n.videoPreset720),
              (VideoPreset.p1080, l10n.videoPreset1080),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _preset == p,
                onSelected: (_) => setState(() => _preset = p),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.videoRemoveAudio),
          value: _removeAudio,
          onChanged: (v) => setState(() => _removeAudio = v),
        ),
        Text(
          duration == null
              ? l10n.videoEstimateUnknown
              : l10n.videoEstimate(
                  formatBytes(
                    _preset.estimateBytes(
                      duration,
                      removeAudio: _removeAudio,
                      sourceBytes: widget.item.sizeBytes,
                    ),
                    locale: locale,
                  ),
                  formatBytes(widget.item.sizeBytes, locale: locale),
                ),
        ),
        Text(
          l10n.videoEngine(transcoder.engineName),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: running
                ? null
                : () => ref
                      .read(versionJobProvider.notifier)
                      .convertVideo(
                        widget.item,
                        _preset,
                        removeAudio: _removeAudio,
                      ),
            icon: const Icon(Icons.movie_edit),
            label: Text(l10n.videoConvert),
          ),
        ),
      ],
    );
  }
}
