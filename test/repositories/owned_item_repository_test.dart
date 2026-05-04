import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection_app/core/repositories/owned_item_repository.dart';
import '../test_helper.dart';

void main() {
  late OwnedItemRepository repo;
  late Database db;
  late String collectionId;
  late String itemId;
  late int now;
  int _colCounter = 0;

  setUpAll(() async {
    db = await setupTestDatabase();
  });

  setUp(() async {
    repo = OwnedItemRepository();
    now = DateTime.now().millisecondsSinceEpoch;

    _colCounter++;
    collectionId = 'test-col-$_colCounter';
    itemId = 'item-$_colCounter';
    await db.insert('collections', {
      'id': collectionId,
      'name': 'Test Collection $_colCounter',
      'created_at': now,
    });
    await db.insert('items', {
      'id': itemId,
      'base_id': collectionId,
      'name': 'Test Item $_colCounter',
      'created_at': now,
      'updated_at': now,
    });
  });

  group('OwnedItemRepository', () {
    test('markOwned — marks an item as owned', () async {
      final record = await repo.markOwned(itemId, collectionId);

      expect(record.owned, isTrue);
      expect(record.itemId, itemId);
      expect(record.collectionId, collectionId);
      expect(record.id.isNotEmpty, isTrue);
    });

    test('countOwned — returns 0 when nothing owned', () async {
      final count = await repo.countOwned(collectionId);
      expect(count, 0);
    });

    test('countOwned — returns owned count including custom items', () async {
      await repo.markOwned(itemId, collectionId);

      await db.insert('custom_items', {
        'id': 'custom-$_colCounter',
        'name': 'Custom Item',
        'collection_id': collectionId,
        'created_at': now,
      });

      final count = await repo.countOwned(collectionId);
      expect(count, 2); // 1 owned + 1 custom
    });

    test('markUnowned — removes owned record', () async {
      final record = await repo.markOwned(itemId, collectionId);
      await repo.markUnowned(record.id);

      final count = await repo.countOwned(collectionId);
      expect(count, 0);
    });

    test('countOwned — handles multiple collections separately', () async {
      final col2 = 'other-col-$_colCounter';
      await db.insert('collections', {
        'id': col2,
        'name': 'Other Collection',
        'created_at': now,
      });
      final item2 = 'item-2-$_colCounter';
      await db.insert('items', {
        'id': item2,
        'base_id': col2,
        'name': 'Item in col2',
        'created_at': now,
        'updated_at': now,
      });

      await repo.markOwned(itemId, collectionId);
      await repo.markOwned(item2, col2);

      expect(await repo.countOwned(collectionId), 1);
      expect(await repo.countOwned(col2), 1);
    });
  });
}
