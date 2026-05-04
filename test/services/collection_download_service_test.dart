import 'package:flutter_test/flutter_test.dart';
import 'package:collection_app/core/services/collection_download_service.dart';
import '../test_helper.dart';

void main() {
  late CollectionDownloadService service;

  setUpAll(() async {
    await setupTestDatabase();
  });

  setUp(() {
    service = CollectionDownloadService();
  });

  group('CollectionDownloadService.importJson', () {
    // ── Standard format ──
    test('standard format — imports items correctly', () async {
      final data = {
        'id': 'test-col',
        'name': 'Test Collection',
        'version': 2,
        'items': [
          {
            'id': 'item-1',
            'name': 'First Item',
            'number': '001',
            'image_url': 'https://example.com/img.png',
          },
          {
            'id': 'item-2',
            'name': 'Second Item',
            'number': '002',
          },
        ],
      };

      final result = await service.importJson(data);

      expect(result.itemCount, 2);
      expect(result.collectionId.isNotEmpty, isTrue);
    });

    // ── Structured format ──
    test('structured format — imports items from collection+items', () async {
      final data = {
        'collection': {
          'id': 'struct-col',
          'name': 'Structured Collection',
          'totalItems': 3,
        },
        'items': [
          {
            'id': 's1',
            'name': 'Item S1',
            'subtitle': 'Sub',
            'year': '2020',
            'images': ['https://example.com/i1.png'],
          },
          {
            'id': 's2',
            'name': 'Item S2',
          },
        ],
      };

      final result = await service.importJson(data);

      expect(result.itemCount, 2);
    });

    // ── Amora format ──
    test('amora format — imports from collection.verres', () async {
      final data = {
        'collection': {
          'nom': 'Verres Pokémon',
          'marque': 'Amora',
          'licence': 'Pokémon',
          'verres': [
            {
              'id': 1,
              'pokemon': 'Pikachu',
              'type': 'Électrik',
              'serie': 'Vague 1',
            },
            {
              'id': 2,
              'pokemon': 'Bulbizarre',
              'type': 'Plante',
              'serie': 'Vague 1',
            },
          ],
        },
      };

      final result = await service.importJson(data);

      expect(result.itemCount, 2);
    });

    // ── Export format (round-trip) ──
    test('export format — restores collections with owned/wanted state', () async {
      final data = {
        'version': 1,
        'exported_at': '2026-04-19T12:00:00Z',
        'collections': [
          {
            'name': 'Roundtrip Collection',
            'version': 3,
            'source_url': 'https://example.com/source.json',
            'items': [
              {
                'id': 'rt-1',
                'name': 'RT Item 1',
                'number': '001',
                '_state': {'owned': true, 'wanted': false},
              },
              {
                'id': 'rt-2',
                'name': 'RT Item 2',
                'number': '002',
                '_state': {'owned': false, 'wanted': true},
              },
              {
                'id': 'rt-3',
                'name': 'RT Item 3',
                'number': '003',
                '_state': {'owned': true, 'wanted': true},
              },
            ],
          }
        ],
      };

      final result = await service.importJson(data);

      expect(result.itemCount, 3);
      expect(result.collectionId.isNotEmpty, isTrue);
    });
  });
}
