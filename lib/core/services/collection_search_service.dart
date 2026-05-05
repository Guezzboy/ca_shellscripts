import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── DTOs ──────────────────────────────────────────────────────────────────────

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

// ── Service ───────────────────────────────────────────────────────────────────

class CollectionSearchService {
  static const _defaultProxyUrl = 'http://10.0.2.2:3000';
  static const _prefsKey = 'search_proxy_url';

  final Dio _dio;

  CollectionSearchService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 8),
            headers: {'Content-Type': 'application/json'},
          ));

  /// Retourne l'URL du proxy (depuis shared_preferences ou défaut).
  Future<String> _proxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? _defaultProxyUrl;
  }

  /// Vérifie si le proxy de recherche est disponible.
  Future<bool> isProxyAvailable() async {
    try {
      final base = await _proxyUrl();
      final resp = await _dio.get('$base/health',
          options: Options(
            sendTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 2),
          ));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Recherche une collection par nom.
  /// Retourne null si le proxy est injoignable ou en cas d'erreur.
  Future<CollectionSearchResult?> searchCollection(String query) async {
    final base = await _proxyUrl();
    try {
      final resp = await _dio.post(
        '$base/api/search-collection',
        data: json.encode({'query': query.trim()}),
      );
      if (resp.statusCode == 200 && resp.data != null) {
        return CollectionSearchResult.fromJson(
            resp.data as Map<String, dynamic>);
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
