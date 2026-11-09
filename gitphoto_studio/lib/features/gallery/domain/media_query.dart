enum MediaFilter { all, images, videos }

enum MediaSort { date, name, type, size }

enum GalleryViewMode { grid, list }

class MediaListQuery {
  const MediaListQuery({
    this.filter = MediaFilter.all,
    this.sort = MediaSort.date,
    this.ascending = false,
    this.search = '',
    this.albumId,
  });

  final MediaFilter filter;
  final MediaSort sort;
  final bool ascending;
  final String search;

  /// Filtre par album ; `null` = tous.
  final int? albumId;

  MediaListQuery copyWith({
    MediaFilter? filter,
    MediaSort? sort,
    bool? ascending,
    String? search,
    int? Function()? albumId,
  }) {
    return MediaListQuery(
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
      search: search ?? this.search,
      albumId: albumId == null ? this.albumId : albumId(),
    );
  }
}
