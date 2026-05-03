import 'dart:async';
import 'package:dio/dio.dart';

class BookData {
  final String? title;
  final String? subtitle;
  final List<String> authors;
  final String? publisher;
  final String? publishDate;
  final String? description;
  final String? coverUrl;
  final int? pageCount;
  final String? isbn13;

  const BookData({
    this.title,
    this.subtitle,
    this.authors = const [],
    this.publisher,
    this.publishDate,
    this.description,
    this.coverUrl,
    this.pageCount,
    this.isbn13,
  });

  String get authorString => authors.join(', ');

  String? get year {
    if (publishDate == null) return null;
    final m = RegExp(r'(\d{4})').firstMatch(publishDate!);
    return m?.group(1);
  }
}

class IsbnLookupService {
  final Dio _dio;

  IsbnLookupService() : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8)));

  Future<BookData?> lookupIsbn(String isbn) async {
    // Clean the ISBN
    final clean = isbn.replaceAll(RegExp(r'[^0-9X]'), '');
    if (clean.isEmpty) return null;

    // Try Open Library first
    final book = await _openLibrary(clean) ?? await _googleBooks(clean);
    return book;
  }

  Future<BookData?> _openLibrary(String isbn) async {
    try {
      final resp = await _dio.get('https://openlibrary.org/isbn/$isbn.json');
      final data = resp.data as Map<String, dynamic>;

      // Fetch additional details
      String? pubDate;
      String? desc;
      if (data['publish_date'] is String) {
        pubDate = data['publish_date'] as String;
      } else if (data['publish_date'] is List) {
        final dates = data['publish_date'] as List;
        pubDate = dates.isNotEmpty ? dates.first.toString() : null;
      }

      if (data['description'] is String) {
        desc = data['description'] as String;
      } else if (data['description'] is Map) {
        final v = (data['description'] as Map)['value'];
        if (v is String) desc = v;
      }

      // Parse authors
      final authors = <String>[];
      if (data['authors'] is List) {
        for (final a in (data['authors'] as List)) {
          if (a is Map && a['name'] != null) {
            authors.add(a['name'].toString());
          } else if (a is String) {
            authors.add(a);
          }
        }
      }

      // Parse publishers
      String? publisher;
      if (data['publishers'] is List) {
        final pubs = data['publishers'] as List;
        publisher = pubs.isNotEmpty ? pubs.first.toString() : null;
      } else if (data['publishers'] is String) {
        publisher = data['publishers'] as String;
      }

      final coverUrl = data['covers'] is List && (data['covers'] as List).isNotEmpty
          ? 'https://covers.openlibrary.org/b/id/${(data['covers'] as List).first}-M.jpg'
          : null;

      return BookData(
        title: data['title']?.toString(),
        subtitle: data['subtitle']?.toString(),
        authors: authors,
        publisher: publisher,
        publishDate: pubDate,
        description: desc,
        coverUrl: coverUrl,
        pageCount: data['number_of_pages'] is int
            ? data['number_of_pages'] as int
            : (data['number_of_pages'] as num?)?.toInt(),
        isbn13: isbn,
      );
    } catch (_) {
      return null;
    }
  }

  Future<BookData?> _googleBooks(String isbn) async {
    try {
      final resp = await _dio.get(
        'https://www.googleapis.com/books/v1/volumes',
        queryParameters: {'q': 'isbn:$isbn'},
      );
      final items = resp.data['items'] as List?;
      if (items == null || items.isEmpty) return null;

      final vol = (items.first as Map)['volumeInfo'] as Map<String, dynamic>;

      // Cover
      String? coverUrl;
      if (vol['imageLinks'] is Map) {
        final imgs = vol['imageLinks'] as Map;
        coverUrl = (imgs['thumbnail'] ?? imgs['smallThumbnail'])?.toString();
      }

      // Publisher
      final pubDate = vol['publishedDate']?.toString();
      final publisher = vol['publisher']?.toString();

      // Authors
      final authors = <String>[];
      if (vol['authors'] is List) {
        for (final a in (vol['authors'] as List)) {
          if (a is String) authors.add(a);
        }
      }

      return BookData(
        title: vol['title']?.toString(),
        subtitle: vol['subtitle']?.toString(),
        authors: authors,
        publisher: publisher,
        publishDate: pubDate,
        description: vol['description']?.toString(),
        coverUrl: coverUrl,
        pageCount: vol['pageCount'] is int
            ? vol['pageCount'] as int
            : (vol['pageCount'] as num?)?.toInt(),
        isbn13: isbn,
      );
    } catch (_) {
      return null;
    }
  }
}
