import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/byte_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/pixel_mascot.dart';
import '../../../shared/widgets/screen_frame.dart';
import '../../gallery/application/gallery_providers.dart';
import '../../gallery/domain/media_item.dart';
import '../../gallery/domain/media_query.dart';
import '../../gallery/presentation/media_tile.dart';
import '../application/editor_providers.dart';
import 'album_dialogs.dart';

/// Accueil de l'éditeur : choix d'un média, doublons probables, albums.
class MediaEditorScreen extends ConsumerWidget {
  const MediaEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(libraryRevisionProvider);
    final media = ref
        .watch(mediaRepositoryProvider)
        .list(const MediaListQuery());

    return ScreenFrame(
      title: l10n.navEditor,
      children: [
        PixelTip(message: l10n.editorOriginalsSafe),
        SectionTitle(l10n.editorChooseMedia),
        if (media.isEmpty)
          Text(l10n.editorNoMedia)
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => SizedBox(
                width: 120,
                child: MediaGridTile(
                  item: media[i],
                  selected: false,
                  selectionMode: false,
                  onTap: () => context.go('/editor/${media[i].id}'),
                  onLongPress: () => context.go('/editor/${media[i].id}'),
                ),
              ),
            ),
          ),
        SectionTitle(l10n.dupTitle),
        const _DuplicatesSection(),
        SectionTitle(l10n.albumsTitle),
        const _AlbumsSection(),
      ],
    );
  }
}

class _DuplicatesSection extends ConsumerWidget {
  const _DuplicatesSection();

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(l10n.dupRemoveTitle(item.fileName)),
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
    if (ok == true) {
      ref.read(importControllerProvider.notifier).removeMedia({item.id});
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final groups = ref.watch(similarGroupsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.dupHelp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        groups.when(
          loading: () => Row(
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(l10n.dupAnalyzing),
            ],
          ),
          error: (e, _) => Text(l10n.commonError('$e')),
          data: (list) => list.isEmpty
              ? Text(l10n.dupNone)
              : Column(
                  children: [
                    for (final group in list)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.dupGroup(group.length),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              for (final m in group)
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox.square(
                                      dimension: 48,
                                      child: MediaThumbnail(item: m, size: 96),
                                    ),
                                  ),
                                  title: Text(m.fileName),
                                  subtitle: Text(
                                    [
                                      formatBytes(m.sizeBytes, locale: locale),
                                      if (m.width != null)
                                        '${m.width}×${m.height}',
                                    ].join(' · '),
                                  ),
                                  trailing: TextButton(
                                    onPressed: () => _remove(context, ref, m),
                                    child: Text(l10n.dupRemove),
                                  ),
                                  onTap: () => context.push('/media/${m.id}'),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AlbumsSection extends ConsumerWidget {
  const _AlbumsSection();

  Future<void> _autoOrganize(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(mediaRepositoryProvider);
    final loose = repo
        .list(const MediaListQuery())
        .where((m) => m.albumId == null)
        .toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.albumAutoOrganize),
        content: Text(l10n.albumAutoOrganizeBody(loose.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: loose.isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: Text(l10n.albumAutoOrganize),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final albums = ref.read(albumRepositoryProvider);
    final byMonth = <String, List<int>>{};
    for (final m in loose) {
      final d = m.displayDate;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(m.id);
    }
    for (final e in byMonth.entries) {
      repo.setAlbum(e.value, albums.findOrCreate(e.key));
    }
    refreshLibraryFromWidget(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.albumAutoOrganized(loose.length))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final albums = ref.watch(albumsProvider);
    final repo = ref.read(albumRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () async {
                final name = await showAlbumNameDialog(
                  context,
                  title: l10n.albumNew,
                  action: l10n.albumCreate,
                );
                if (name == null) return;
                repo.findOrCreate(name);
                refreshLibraryFromWidget(ref);
              },
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(l10n.albumNew),
            ),
            OutlinedButton.icon(
              onPressed: () => _autoOrganize(context, ref),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(l10n.albumAutoOrganize),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (albums.isEmpty)
          Text(l10n.albumsNone)
        else
          Card(
            child: Column(
              children: [
                for (final a in albums)
                  ListTile(
                    leading: const Icon(Icons.photo_album_outlined),
                    title: Text(a.name),
                    subtitle: Text(l10n.albumCount(a.count)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'rename') {
                          final name = await showAlbumNameDialog(
                            context,
                            initial: a.name,
                            title: l10n.albumRename,
                            action: l10n.albumRename,
                          );
                          if (name == null) return;
                          try {
                            repo.rename(a.id, name);
                          } on Object catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.commonError('$e'))),
                              );
                            }
                          }
                        } else {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.albumDelete),
                              content: Text(l10n.albumDeleteBody(a.name)),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(l10n.commonCancel),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(l10n.albumDelete),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          repo.delete(a.id);
                        }
                        refreshLibraryFromWidget(ref);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text(l10n.albumRename),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.albumDelete),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
