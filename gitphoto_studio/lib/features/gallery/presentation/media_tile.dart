import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/byte_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/media_item.dart';
import '../domain/media_query.dart';

String formatDuration(int ms) {
  final d = Duration(milliseconds: ms);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '${d.inMinutes}:$s';
}

/// Grille ou liste de médias, avec sélection multiple.
class MediaCollection extends StatelessWidget {
  const MediaCollection({
    super.key,
    required this.items,
    required this.viewMode,
    required this.selection,
    required this.onOpen,
    required this.onToggle,
  });

  final List<MediaItem> items;
  final GalleryViewMode viewMode;
  final Set<int> selection;
  final ValueChanged<MediaItem> onOpen;
  final ValueChanged<MediaItem> onToggle;

  void _tap(MediaItem item) =>
      selection.isEmpty ? onOpen(item) : onToggle(item);

  @override
  Widget build(BuildContext context) {
    if (viewMode == GalleryViewMode.grid) {
      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 170,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return MediaGridTile(
            key: ValueKey(item.id),
            item: item,
            selected: selection.contains(item.id),
            selectionMode: selection.isNotEmpty,
            onTap: () => _tap(item),
            onLongPress: () => onToggle(item),
          );
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return MediaListTile(
          key: ValueKey(item.id),
          item: item,
          selected: selection.contains(item.id),
          selectionMode: selection.isNotEmpty,
          onTap: () => _tap(item),
          onLongPress: () => onToggle(item),
        );
      },
    );
  }
}

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({super.key, required this.item, this.size = 320});

  final MediaItem item;
  final int size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          item.isVideo ? Icons.movie_outlined : Icons.image_outlined,
          size: 36,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    final thumb = item.thumbnailPath;
    if (thumb == null) return placeholder;
    return Image.file(
      File(thumb),
      fit: BoxFit.cover,
      cacheWidth: size,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class MediaGridTile extends StatelessWidget {
  const MediaGridTile({
    super.key,
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: item.isVideo
          ? '${l10n.galleryVideoBadge} ${item.fileName}'
          : item.fileName,
      selected: selected,
      button: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.all(selected ? 8 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(selected ? 10 : 0),
                    child: MediaThumbnail(item: item),
                  ),
                ),
                if (item.isVideo)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: _Badge(
                      icon: Icons.play_arrow,
                      text: item.durationMs == null
                          ? null
                          : formatDuration(item.durationMs!),
                    ),
                  ),
                if (selectionMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected ? scheme.primary : Colors.white,
                      shadows: const [Shadow(blurRadius: 4)],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, this.text});

  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          if (text != null)
            Text(
              text!,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class MediaListTile extends StatelessWidget {
  const MediaListTile({
    super.key,
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final details = <String>[
      item.mimeType ?? '',
      formatBytes(item.sizeBytes, locale: locale),
      if (item.width != null && item.height != null)
        '${item.width}×${item.height}',
      if (item.durationMs != null) formatDuration(item.durationMs!),
      DateFormat.yMd(locale).format(item.displayDate),
    ].where((s) => s.isNotEmpty).join(' · ');

    return ListTile(
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 56,
          child: MediaThumbnail(item: item, size: 112),
        ),
      ),
      title: Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(details, maxLines: 2),
      trailing: selectionMode
          ? Checkbox(value: selected, onChanged: (_) => onLongPress())
          : (item.hasGps ? const Icon(Icons.location_on_outlined) : null),
    );
  }
}
