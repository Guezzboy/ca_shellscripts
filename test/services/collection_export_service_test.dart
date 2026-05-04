import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:collection_app/core/database/database_helper.dart';
import 'package:collection_app/core/repositories/collection_repository.dart';
import 'package:collection_app/core/repositories/item_repository.dart';
import 'package:collection_app/core/repositories/owned_item_repository.dart';
import 'package:collection_app/core/services/collection_export_service.dart';
import '../test_helper.dart';

void main() {
  late CollectionExportService exportService;
  late CollectionRepository colRepo;
  late ItemRepository itemRepo;
  late OwnedItemRepository ownedRepo;
  int _counter = 0;

  setUpAll(() async {
    await setupTestDatabase();
  });

  setUp(() async {
    colRepo = CollectionRepository();
    itemRepo = ItemRepository();
    ownedRepo = OwnedItemRepository();
    exportService = CollectionExportService(
        collectionRepo: colRepo, itemRepo: itemRepo);
    _counter++;
    // Clean up any leftover data from previous tests
    final db = await DatabaseHelper.instance.database;
    await db.delete('owned_items');
    await db.delete('custom_items');
    await db.delete('items');
    await db.delete('collections');
  });

  Future<String> _insertItem(String collectionId, String name,
      {String? number}) async {
    final db = await DatabaseHelper.instance.database;
    final id = 'exp_${name.hashCode}_$_counter';
    await db.insert('items', {
      'id': id,
      'base_id': collectionId,
      'name': name,
      'number': number,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  test('exportAllCollections — produces valid JSON', () async {
    final col = await colRepo.create('Test Export');

    await _insertItem(col.id, 'Item 1', number: '001');
    await _insertItem(col.id, 'Item 2');
    await colRepo.updateItemCount(col.id);

    final json = await exportService.exportAllCollections();
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['version'], 1);
    expect(decoded['exported_at'], isNotNull);
    expect(decoded['collections'], isA<List>());
    expect((decoded['collections'] as List).length, 1);

    final colData = (decoded['collections'] as List).first;
    expect(colData['name'], 'Test Export');
    expect(colData['items'], isA<List>());
  });

  test('exportAllCollections — includes owned state', () async {
    final col = await colRepo.create('Owned Export');

    final id1 = await _insertItem(col.id, 'Owned Item');
    final id2 = await _insertItem(col.id, 'Unwanted Item');
    await colRepo.updateItemCount(col.id);

    await ownedRepo.markOwned(id1, col.id);

    final json = await exportService.exportAllCollections();
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final colData = (decoded['collections'] as List).first;

    final items = colData['items'] as List;
    expect(items.length, 2);

    final ownedItem = items.firstWhere(
        (i) => (i as Map)['_state'] is Map && (i['_state'] as Map)['owned'] == true);
    expect(ownedItem, isNotNull);
  });

  test('exportAllCollections — empty when no collections', () async {
    final json = await exportService.exportAllCollections();
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['version'], 1);
    expect(decoded['collections'], isEmpty);
  });

  test('exportAllCollections — preserves item metadata', () async {
    final col = await colRepo.create('Metadata Export');

    final db = await DatabaseHelper.instance.database;
    await db.insert('items', {
      'id': 'meta_item_$_counter',
      'base_id': col.id,
      'name': 'Book Item',
      'isbn': '9781234567890',
      'author': 'Test Author',
      'publisher': 'Test Pub',
      'publish_year': '2023',
      'metadata': jsonEncode({'year': '2023', 'series': 'Series A'}),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    await colRepo.updateItemCount(col.id);

    final json = await exportService.exportAllCollections();
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final items = (decoded['collections'] as List).first['items'] as List;

    final item = items.firstWhere(
        (i) => (i as Map)['id'] == 'meta_item_$_counter');
    expect(item['isbn'], '9781234567890');
    expect(item['author'], 'Test Author');
    expect(item['publisher'], 'Test Pub');
    expect(item['publish_year'], '2023');
    expect(item['year'], '2023');
  });
}
