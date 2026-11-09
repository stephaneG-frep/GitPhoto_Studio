import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/byte_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/gallery_providers.dart';
import '../domain/media_item.dart';
import 'media_tile.dart' show formatDuration;
import 'video_view.dart';

class MediaViewerScreen extends ConsumerWidget {
  const MediaViewerScreen({super.key, required this.mediaId});

  final int mediaId;

  Future<void> _openExternally(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) async {
    final ok = await ref.read(externalOpenerProvider).open(item.storedPath);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).viewerOpenExternalFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(mediaByIdProvider(mediaId));
    final opener = ref.watch(externalOpenerProvider);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.viewerNotFound)),
      );
    }

    final fileExists = File(item.storedPath).existsSync();
    final Widget content;
    if (!fileExists) {
      content = _Message(
        icon: Icons.broken_image_outlined,
        text: l10n.viewerFileMissing,
      );
    } else if (item.isVideo) {
      content = ref.watch(inAppVideoSupportedProvider)
          ? VideoView(path: item.storedPath)
          : _Message(
              icon: Icons.movie_outlined,
              text: l10n.viewerVideoUnavailable,
              action: opener.isSupported
                  ? FilledButton.icon(
                      onPressed: () => _openExternally(context, ref, item),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l10n.viewerOpenExternal),
                    )
                  : null,
            );
    } else {
      content = InteractiveViewer(
        maxScale: 8,
        child: Center(
          child: Image.file(
            File(item.storedPath),
            fit: BoxFit.contain,
            semanticLabel: item.fileName,
            errorBuilder: (_, _, _) => _Message(
              icon: Icons.image_not_supported_outlined,
              text: l10n.viewerPreviewUnavailable,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          if (opener.isSupported && fileExists)
            IconButton(
              tooltip: l10n.viewerOpenExternal,
              onPressed: () => _openExternally(context, ref, item),
              icon: const Icon(Icons.open_in_new),
            ),
          IconButton(
            tooltip: l10n.viewerEdit,
            onPressed: () => context.go('/editor/${item.id}'),
            icon: const Icon(Icons.auto_fix_high),
          ),
          IconButton(
            tooltip: l10n.viewerInfo,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => MediaMetadataSheet(item: item),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(child: content),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class MediaMetadataSheet extends ConsumerWidget {
  const MediaMetadataSheet({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();
    final unknown = l10n.metaUnknown;
    final videoMetaUnavailable =
        item.isVideo && !ref.watch(videoInspectorProvider).isSupported;

    final rows = <(String, String)>[
      (l10n.metaFileName, item.fileName),
      (l10n.metaType, item.mimeType ?? unknown),
      (l10n.metaSize, formatBytes(item.sizeBytes, locale: locale)),
      (
        l10n.metaDimensions,
        item.width != null && item.height != null
            ? '${item.width} × ${item.height}'
            : unknown,
      ),
      if (item.isVideo)
        (
          l10n.metaDuration,
          item.durationMs == null ? unknown : formatDuration(item.durationMs!),
        ),
      (
        l10n.metaTakenAt,
        item.takenAt == null ? unknown : dateFormat.format(item.takenAt!),
      ),
      if (item.cameraModel != null) (l10n.metaCamera, item.cameraModel!),
      if (!item.isVideo)
        (l10n.metaGps, item.hasGps ? l10n.metaGpsPresent : l10n.metaGpsAbsent),
      if (item.derivedFrom case final sourceId?)
        (
          l10n.metaVersionOf,
          ref.watch(mediaByIdProvider(sourceId))?.fileName ?? '#$sourceId',
        ),
      (l10n.metaImportedAt, dateFormat.format(item.importedAt)),
      (l10n.metaSource, item.sourcePath),
      (l10n.metaSha256, item.sha256),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.viewerInfo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (videoMetaUnavailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.metaVideoUnavailable),
              ),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      SelectableText(value),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
