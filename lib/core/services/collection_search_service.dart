// ── DTOs pour les résultats de recherche de collections ──────────────────────

class CollectionMeta {
  final String id;
  final String name;
  final String description;
  final int totalItems;

  const CollectionMeta({
    required this.id,
    required this.name,
    this.description = '',
    required this.totalItems,
  });

  factory CollectionMeta.fromJson(Map<String, dynamic> json) => CollectionMeta(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Collection inconnue',
        description: json['description'] as String? ?? '',
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'totalItems': totalItems,
      };
}

class SearchResultItem {
  final String id;
  final String name;
  final String subtitle;
  final String? year;
  final String? series;
  final String description;
  final List<String> images;

  const SearchResultItem({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.year,
    this.series,
    this.description = '',
    this.images = const [],
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? [];
    return SearchResultItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      year: json['year'] as String?,
      series: json['series'] as String?,
      description: json['description'] as String? ?? '',
      images: images.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'year': year,
        'series': series,
        'description': description,
        'images': images,
      };
}

class SearchMeta {
  final String source;
  final double imageCompleteness;
  final int searchMs;

  const SearchMeta({
    this.source = 'unknown',
    this.imageCompleteness = 0.0,
    this.searchMs = 0,
  });

  factory SearchMeta.fromJson(Map<String, dynamic> json) => SearchMeta(
        source: json['source'] as String? ?? 'unknown',
        imageCompleteness:
            (json['imageCompleteness'] as num?)?.toDouble() ?? 0.0,
        searchMs: (json['searchMs'] as num?)?.toInt() ?? 0,
      );
}

class CollectionSearchResult {
  final CollectionMeta collection;
  final List<SearchResultItem> items;
  final SearchMeta meta;

  const CollectionSearchResult({
    required this.collection,
    required this.items,
    required this.meta,
  });

  factory CollectionSearchResult.fromJson(Map<String, dynamic> json) {
    final col = json['collection'] as Map<String, dynamic>? ?? {};
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final metaRaw = json['_meta'] as Map<String, dynamic>? ?? {};

    return CollectionSearchResult(
      collection: CollectionMeta.fromJson(col),
      items: rawItems
          .map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: SearchMeta.fromJson(metaRaw),
    );
  }

  /// Convertit le résultat en format compatible avec
  /// CollectionDownloadService.importJson() (format structuré).
  Map<String, dynamic> toImportJson() => {
        'collection': collection.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        '_meta': {
          'source': meta.source,
          'imageCompleteness': meta.imageCompleteness,
          'searchMs': meta.searchMs,
        },
      };
}
