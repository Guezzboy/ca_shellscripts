import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection_app/core/services/collection_search_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late CollectionSearchService service;

  setUp(() async {
    dio = MockDio();
    SharedPreferences.setMockInitialValues({});
    service = CollectionSearchService(dio: dio);
  });

  group('CollectionSearchService — proxy health', () {
    test('isProxyAvailable returns true on 200', () async {
      when(() => dio.get(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ));

      final ok = await service.isProxyAvailable();
      expect(ok, isTrue);
    });

    test('isProxyAvailable returns false on 500', () async {
      when(() => dio.get(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
          ));

      final ok = await service.isProxyAvailable();
      expect(ok, isFalse);
    });

    test('isProxyAvailable returns false on DioException', () async {
      when(() => dio.get(
            any(),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ));

      final ok = await service.isProxyAvailable();
      expect(ok, isFalse);
    });
  });

  group('CollectionSearchService — search', () {
    final sampleResponse = {
      'collection': {
        'id': 'col-1',
        'name': 'Verres Test',
        'description': 'Une collection de test',
        'totalItems': 10,
      },
      'items': [
        {
          'id': 'item-001',
          'name': 'Item 1',
          'subtitle': 'Sous-titre',
          'year': '2024',
          'series': 'Série A',
          'description': 'Description 1',
          'images': ['https://example.com/img1.png'],
        },
        {
          'id': 'item-002',
          'name': 'Item 2',
          'images': [],
        },
      ],
      '_meta': {
        'source': 'proxy',
        'imageCompleteness': 0.8,
        'searchMs': 42,
      },
    };

    test('searchCollection returns parsed result on success', () async {
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: sampleResponse,
          ));

      final result = await service.searchCollection('test');
      expect(result, isNotNull);
      expect(result!.collection.name, 'Verres Test');
      expect(result.collection.totalItems, 10);
      expect(result.items.length, 2);
      expect(result.items.first.name, 'Item 1');
      expect(result.items.first.images, ['https://example.com/img1.png']);
      expect(result.meta.source, 'proxy');
      expect(result.meta.imageCompleteness, 0.8);
    });

    test('searchCollection returns null on DioException', () async {
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ));

      final result = await service.searchCollection('test');
      expect(result, isNull);
    });

    test('searchCollection returns null on non-200', () async {
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ));

      final result = await service.searchCollection('test');
      expect(result, isNull);
    });
  });

  group('DTO — CollectionMeta', () {
    test('fromJson with all fields', () {
      final meta = CollectionMeta.fromJson({
        'id': 'abc',
        'name': 'Test Collection',
        'description': 'A test',
        'totalItems': 42,
      });
      expect(meta.id, 'abc');
      expect(meta.name, 'Test Collection');
      expect(meta.description, 'A test');
      expect(meta.totalItems, 42);
    });

    test('fromJson with missing fields', () {
      final meta = CollectionMeta.fromJson({});
      expect(meta.id, '');
      expect(meta.name, 'Collection inconnue');
      expect(meta.description, '');
      expect(meta.totalItems, 0);
    });

    test('toJson round-trip', () {
      final meta = const CollectionMeta(
        id: 'x',
        name: 'Y',
        description: 'Z',
        totalItems: 10,
      );
      final json = meta.toJson();
      expect(json['id'], 'x');
      expect(json['name'], 'Y');
      expect(json['totalItems'], 10);
    });
  });

  group('DTO — SearchResultItem', () {
    test('fromJson with all fields', () {
      final item = SearchResultItem.fromJson({
        'id': 'i1',
        'name': 'Item Name',
        'subtitle': 'Sub',
        'year': '2025',
        'series': 'Series X',
        'description': 'Desc',
        'images': ['img1.png', 'img2.png'],
      });
      expect(item.id, 'i1');
      expect(item.name, 'Item Name');
      expect(item.subtitle, 'Sub');
      expect(item.year, '2025');
      expect(item.series, 'Series X');
      expect(item.description, 'Desc');
      expect(item.images, ['img1.png', 'img2.png']);
    });

    test('fromJson with missing fields', () {
      final item = SearchResultItem.fromJson({});
      expect(item.id, '');
      expect(item.name, '');
      expect(item.subtitle, '');
      expect(item.year, isNull);
      expect(item.images, isEmpty);
    });

    test('toJson round-trip', () {
      final item = const SearchResultItem(
        id: 'x',
        name: 'y',
        images: ['a'],
        year: '2025',
      );
      final json = item.toJson();
      expect(json['id'], 'x');
      expect(json['images'], ['a']);
      expect(json['year'], '2025');
    });
  });

  group('DTO — CollectionSearchResult', () {
    final sampleJson = {
      'collection': {
        'id': 'c1',
        'name': 'Test',
        'description': '',
        'totalItems': 5,
      },
      'items': [],
      '_meta': {
        'source': 'test',
        'imageCompleteness': 1.0,
        'searchMs': 10,
      },
    };

    test('fromJson parses full response', () {
      final result = CollectionSearchResult.fromJson(sampleJson);
      expect(result.collection.name, 'Test');
      expect(result.collection.totalItems, 5);
      expect(result.items, isEmpty);
      expect(result.meta.source, 'test');
    });

    test('fromJson with empty data', () {
      final result = CollectionSearchResult.fromJson({});
      expect(result.collection.name, 'Collection inconnue');
      expect(result.items, isEmpty);
      expect(result.meta.source, 'unknown');
    });

    test('toImportJson produces structured format', () {
      final result = CollectionSearchResult(
        collection: const CollectionMeta(
          id: 'c1',
          name: 'Test',
          totalItems: 3,
        ),
        items: const [
          SearchResultItem(id: 'i1', name: 'Item 1'),
        ],
        meta: const SearchMeta(source: 'test', imageCompleteness: 0.5),
      );
      final json = result.toImportJson();
      expect(json['collection']['id'], 'c1');
      expect(json['collection']['name'], 'Test');
      expect(json['items'].length, 1);
      expect(json['items'][0]['id'], 'i1');
      expect(json['_meta']['source'], 'test');
    });
  });
}
