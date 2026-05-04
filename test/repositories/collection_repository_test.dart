import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection_app/core/repositories/collection_repository.dart';
import '../test_helper.dart';

void main() {
  late CollectionRepository repo;
  late Database db;

  setUpAll(() async {
    db = await setupTestDatabase();
  });

  setUp(() {
    repo = CollectionRepository();
  });

  group('CollectionRepository', () {
    test('create — creates a collection with defaults', () async {
      final col = await repo.create('Test Collection');

      expect(col.name, 'Test Collection');
      expect(col.id.isNotEmpty, isTrue);
      expect(col.itemCount, 0);
      expect(col.version, 1);
      expect(col.sourceUrl, isNull);
    });

    test('create — stores sourceUrl', () async {
      final col = await repo.create('With Source',
          sourceUrl: 'https://example.com/data.json');

      expect(col.sourceUrl, 'https://example.com/data.json');
    });

    test('getAll — returns collections ordered by created_at DESC', () async {
      await repo.create('First');
      await Future.delayed(const Duration(milliseconds: 5));
      await repo.create('Second');

      final all = await repo.getAll();

      expect(all.length, greaterThanOrEqualTo(2));
      // Second should be first (DESC order)
      final names = all.map((c) => c.name).toList();
      expect(names[0], 'Second');
    });

    test('getById — returns existing collection', () async {
      final created = await repo.create('Find Me');
      final found = await repo.getById(created.id);

      expect(found, isNotNull);
      expect(found!.name, 'Find Me');
    });

    test('getById — returns null for unknown id', () async {
      final found = await repo.getById('nonexistent');
      expect(found, isNull);
    });

    test('update — updates fields', () async {
      final created = await repo.create('Original');
      final updated = created.copyWith(name: 'Updated', itemCount: 42);

      await repo.update(updated);
      final fetched = await repo.getById(created.id);

      expect(fetched!.name, 'Updated');
      expect(fetched.itemCount, 42);
    });

    test('delete — removes collection and cascades', () async {
      final created = await repo.create('To Delete');
      await repo.delete(created.id);

      final found = await repo.getById(created.id);
      expect(found, isNull);
    });

    test('updateItemCount — counts base + custom items', () async {
      final col = await repo.create('Count Test');
      // Insert a base item directly
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('items', {
        'id': 'item-1',
        'base_id': col.id,
        'name': 'Test Item',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('custom_items', {
        'id': 'custom-1',
        'name': 'Custom Item',
        'collection_id': col.id,
        'created_at': now,
      });

      await repo.updateItemCount(col.id);
      final updated = await repo.getById(col.id);

      expect(updated!.itemCount, 2);
    });
  });
}
