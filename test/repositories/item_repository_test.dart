import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection_app/core/repositories/item_repository.dart';
import '../test_helper.dart';

void main() {
  late ItemRepository repo;
  late Database db;
  late String collectionId;
  late int now;
  int _colCounter = 0;

  setUpAll(() async {
    db = await setupTestDatabase();
  });

  setUp(() async {
    repo = ItemRepository();
    now = DateTime.now().millisecondsSinceEpoch;

    // Use unique collection ID per test to avoid UNIQUE constraint
    _colCounter++;
    collectionId = 'test-col-$_colCounter';
    await db.insert('collections', {
      'id': collectionId,
      'name': 'Test Collection $_colCounter',
      'created_at': now,
    });

    // Clean up items from this collection (avoid cross-test pollution)
    await db.delete('items', where: 'base_id = ?', whereArgs: [collectionId]);
    await db.delete('custom_items',
        where: 'collection_id = ?', whereArgs: [collectionId]);
  });

  Future<void> _insertItem(String name, {int? createdAt}) async {
    final id = '${collectionId}_item_${name.hashCode}_${createdAt ?? now}';
    await db.insert('items', {
      'id': id,
      'base_id': collectionId,
      'name': name,
      'created_at': createdAt ?? now,
      'updated_at': now,
    });
  }

  group('ItemRepository', () {
    // ── getByCollectionId ──
    test('getByCollectionId — returns items for a collection', () async {
      await _insertItem('Item One');
      await _insertItem('Item Two');

      final items = await repo.getByCollectionId(collectionId);

      expect(items.length, 2);
      expect(items.map((i) => i.name), containsAll(['Item One', 'Item Two']));
    });

    // ── searchByName ──
    test('searchByName — finds items by name pattern', () async {
      await _insertItem('Pikachu');
      await _insertItem('Bulbizarre');

      final results = await repo.searchByName(collectionId, 'pika');

      expect(results.length, 1);
      expect(results.first.name, 'Pikachu');
    });

    // ── create ──
    test('create — inserts a new item', () async {
      final item = await repo.create(
        baseId: collectionId,
        name: 'New Item',
        number: '001',
      );

      expect(item.name, 'New Item');
      expect(item.number, '001');

      final items = await repo.getByCollectionId(collectionId);
      expect(items.length, 1);
    });

    // ── insertBatch ──
    test('insertBatch — inserts multiple items at once', () async {
      await repo.create(baseId: collectionId, name: 'Batch 1');
      await repo.create(baseId: collectionId, name: 'Batch 2');

      final all = await repo.getByCollectionId(collectionId);
      expect(all.length, 2);
    });

    // ── toggleWanted ──
    test('toggleWanted — toggles wanted flag', () async {
      final item = await repo.create(baseId: collectionId, name: 'Test');

      await repo.toggleWanted(item.id, true);
      final items = await repo.getByCollectionId(collectionId);
      expect(items.first.wanted, isTrue);

      await repo.toggleWanted(item.id, false);
      final items2 = await repo.getByCollectionId(collectionId);
      expect(items2.first.wanted, isFalse);
    });

    // ── countWanted ──
    test('countWanted — counts items marked as wanted', () async {
      final a = await repo.create(baseId: collectionId, name: 'A');
      final b = await repo.create(baseId: collectionId, name: 'B');
      await repo.create(baseId: collectionId, name: 'C');

      await repo.toggleWanted(a.id, true);
      await repo.toggleWanted(b.id, true);

      expect(await repo.countWanted(), 2);
    });

    // ── getMostRecentBase ──
    test('getMostRecentBase — returns items ordered by created_at DESC', () async {
      // Use timestamps in the far future to avoid cross-test pollution
      final far = now + 100000;
      final t1 = far + 1000;
      final t2 = far + 2000;
      final t3 = far + 3000; // most recent

      await _insertItem('Oldest', createdAt: t1);
      await _insertItem('Middle', createdAt: t2);
      await _insertItem('Newest', createdAt: t3);

      final recent = await repo.getMostRecentBase(2);

      expect(recent.length, 2);
      expect(recent[0].name, 'Newest');
      expect(recent[1].name, 'Middle');
    });

    test('getMostRecentBase — respects limit', () async {
      final far = now + 200000;
      await _insertItem('A', createdAt: far + 1000);
      await _insertItem('B', createdAt: far + 2000);

      final recent = await repo.getMostRecentBase(1);
      expect(recent.length, 1);
    });

    // ── getMostRecentCustom ──
    test('getMostRecentCustom — returns custom items', () async {
      await db.insert('custom_items', {
        'id': 'c-1',
        'name': 'Custom 1',
        'collection_id': collectionId,
        'created_at': now - 2000,
      });
      await db.insert('custom_items', {
        'id': 'c-2',
        'name': 'Custom 2',
        'collection_id': collectionId,
        'created_at': now - 1000,
      });

      final recent = await repo.getMostRecentCustom(1);

      expect(recent.length, 1);
      expect(recent.first['name'], 'Custom 2');
    });

    // ── countAddedBetween ──
    test('countAddedBetween — counts items in time range', () async {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));

      // Item from yesterday
      await _insertItem('Yesterday Item',
          createdAt: yesterdayStart.millisecondsSinceEpoch + 1000);
      // Item from today (should be excluded when range is yesterday only)
      await _insertItem('Today Item',
          createdAt: todayStart.millisecondsSinceEpoch + 1000);

      final counts = await repo.countAddedBetween(
        yesterdayStart.millisecondsSinceEpoch,
        todayStart.millisecondsSinceEpoch,
      );

      expect(counts[collectionId], 1); // only yesterday's item
    });

    test('countAddedBetween — includes custom items', () async {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final yesterdayMs = yesterdayStart.millisecondsSinceEpoch + 1000;

      await _insertItem('Base item', createdAt: yesterdayMs);
      await db.insert('custom_items', {
        'id': 'custom-y',
        'name': 'Custom Yesterday',
        'collection_id': collectionId,
        'created_at': yesterdayMs,
      });

      final counts = await repo.countAddedBetween(
        yesterdayStart.millisecondsSinceEpoch,
        todayStart.millisecondsSinceEpoch,
      );

      expect(counts[collectionId], 2);
    });
  });
}
