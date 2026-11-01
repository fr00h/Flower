class ListQuery {
  static const _keys = {'search', 'sort', 'page', 'size'};

  final String path;
  final String defaultSort;
  final bool defaultAscending;
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final Map<String, String> filters;

  const ListQuery({
    required this.path,
    required this.defaultSort,
    this.defaultAscending = true,
    this.search = '',
    required this.sortField,
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.filters = const {},
  });

  String get pbSort => sortAscending ? sortField : '-$sortField';

  String filter(String key) => filters[key] ?? '';

  ListQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    Map<String, String>? filters,
  }) {
    return ListQuery(
      path: path,
      defaultSort: defaultSort,
      defaultAscending: defaultAscending,
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      filters: filters ?? this.filters,
    );
  }

  ListQuery withFilter(String key, String value) {
    final next = {...filters};
    value.isEmpty ? next.remove(key) : next[key] = value;
    return copyWith(filters: next);
  }

  factory ListQuery.fromParams(
    String path,
    String defaultSort,
    Map<String, String> p, {
    bool defaultAscending = true,
  }) {
    final sort =
        (p['sort'] ?? '$defaultSort,${defaultAscending ? 'asc' : 'desc'}')
            .split(',');
    return ListQuery(
      path: path,
      defaultSort: defaultSort,
      defaultAscending: defaultAscending,
      search: p['search'] ?? '',
      sortField: sort.first,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: int.tryParse(p['page'] ?? '') ?? 1,
      size: int.tryParse(p['size'] ?? '') ?? 10,
      filters: {
        for (final e in p.entries)
          if (!_keys.contains(e.key) && e.value.isNotEmpty) e.key: e.value,
      },
    );
  }

  Map<String, String> toParams() => {
    if (search.isNotEmpty) 'search': search,
    ...filters,
    if (sortField != defaultSort || sortAscending != defaultAscending)
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    if (page != 1) 'page': '$page',
    if (size != 10) 'size': '$size',
  };

  String get location {
    final params = toParams();
    if (params.isEmpty) return path;
    final query = params.entries
        .map(
          (e) =>
              '${e.key}=${Uri.encodeComponent(e.value).replaceAll('%2C', ',')}',
        )
        .join('&');
    return '$path?$query';
  }
}
