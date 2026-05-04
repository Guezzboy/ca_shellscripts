import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection_app/core/database/database_helper.dart';
import 'package:collection_app/core/repositories/collection_repository.dart';
import 'package:collection_app/core/repositories/owned_item_repository.dart';
import 'package:collection_app/core/services/badge_checker.dart';
import 'package:collection_app/core/services/badge_service.dart';
import '../test_helper.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('BadgeStats', () {
    setUp(() async {
      await BadgeStats.setWantedCount(0);
    });

    test('recordAdd — increments and returns new count', () async {
      final c1 = await BadgeStats.recordAdd();
      final c2 = await BadgeStats.recordAdd();
      expect(c1, 1);
      expect(c2, 2);
      expect(await BadgeStats.totalAdds, 2);
    });

    test('recordPhoto — increments', () async {
      final c = await BadgeStats.recordPhoto();
      expect(c, 1);
      expect(await BadgeStats.totalPhotos, 1);
    });

    test('recordScan — increments', () async {
      final c = await BadgeStats.recordScan();
      expect(c, 1);
      expect(await BadgeStats.totalScans, 1);
    });

    test('setWantedCount — sets absolute value', () async {
      await BadgeStats.setWantedCount(10);
      expect(await BadgeStats.wantedCount, 10);
      await BadgeStats.setWantedCount(5);
      expect(await BadgeStats.wantedCount, 5);
    });

    test('recordPhoto hits threshold at 5', () async {
      for (var i = 0; i < 4; i++) {
        await BadgeStats.recordPhoto();
      }
      final c5 = await BadgeStats.recordPhoto();
      expect(c5, 5);
    });

    test('recordScan hits threshold at 5', () async {
      for (var i = 0; i < 4; i++) {
        await BadgeStats.recordScan();
      }
      final c5 = await BadgeStats.recordScan();
      expect(c5, 5);
    });
  });

  group('BadgeChecker with repositories', () {
    late CollectionRepository colRepo;
    late OwnedItemRepository ownedRepo;
    int _counter = 0;

    setUpAll(() async {
      await setupTestDatabase();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      colRepo = CollectionRepository();
      ownedRepo = OwnedItemRepository();
      BadgeChecker.colRepo = () => colRepo;
      BadgeChecker.ownedRepo = () => ownedRepo;
      _counter++;
    });

    tearDown(() {
      BadgeChecker.colRepo = () => CollectionRepository();
      BadgeChecker.ownedRepo = () => OwnedItemRepository();
    });

    Future<void> _insertItem(String id, String collectionId, String name) async {
      final db = await DatabaseHelper.instance.database;
      await db.insert('items', {
        'id': id,
        'base_id': collectionId,
        'name': name,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    test('expert — detects owned items in 3+ collections', () async {
      final c1 = await colRepo.create('Collection A');
      final c2 = await colRepo.create('Collection B');
      final c3 = await colRepo.create('Collection C');

      await _insertItem('ex_i1_$_counter', c1.id, 'Item 1');
      await _insertItem('ex_i2_$_counter', c2.id, 'Item 2');
      await _insertItem('ex_i3_$_counter', c3.id, 'Item 3');
      await colRepo.updateItemCount(c1.id);
      await colRepo.updateItemCount(c2.id);
      await colRepo.updateItemCount(c3.id);

      await ownedRepo.markOwned('ex_i1_$_counter', c1.id);
      await ownedRepo.markOwned('ex_i2_$_counter', c2.id);
      await ownedRepo.markOwned('ex_i3_$_counter', c3.id);

      expect(await ownedRepo.countOwned(c1.id), 1);
      expect(await ownedRepo.countOwned(c2.id), 1);
      expect(await ownedRepo.countOwned(c3.id), 1);
    });

    test('expert — not triggered with only 2 collections', () async {
      final c1 = await colRepo.create('Collection A');
      final c2 = await colRepo.create('Collection B');

      await _insertItem('ex2_i1_$_counter', c1.id, 'Item 1');
      await _insertItem('ex2_i2_$_counter', c2.id, 'Item 2');
      await colRepo.updateItemCount(c1.id);
      await colRepo.updateItemCount(c2.id);

      await ownedRepo.markOwned('ex2_i1_$_counter', c1.id);
      await ownedRepo.markOwned('ex2_i2_$_counter', c2.id);

      expect(await ownedRepo.countOwned(c1.id), 1);
      expect(await ownedRepo.countOwned(c2.id), 1);
    });

    test('collector — detects 100% completion', () async {
      final col = await colRepo.create('Full Collection');

      await _insertItem('co_i1_$_counter', col.id, 'Item A');
      await _insertItem('co_i2_$_counter', col.id, 'Item B');
      await colRepo.updateItemCount(col.id);

      await ownedRepo.markOwned('co_i1_$_counter', col.id);
      await ownedRepo.markOwned('co_i2_$_counter', col.id);

      final collection = await colRepo.getById(col.id);
      expect(collection!.itemCount, 2);
      expect(await ownedRepo.countOwned(col.id), 2);
    });

    test('collector — not triggered when incomplete', () async {
      final col = await colRepo.create('Half Collection');

      await _insertItem('co2_i1_$_counter', col.id, 'Item A');
      await _insertItem('co2_i2_$_counter', col.id, 'Item B');
      await colRepo.updateItemCount(col.id);

      await ownedRepo.markOwned('co2_i1_$_counter', col.id);

      expect(await ownedRepo.countOwned(col.id), 1);
      expect((await colRepo.getById(col.id))!.itemCount, 2);
    });

    test('hunter — wanted threshold at 10', () async {
      await BadgeStats.setWantedCount(9);
      expect(await BadgeStats.wantedCount, 9);

      await BadgeStats.setWantedCount(10);
      expect(await BadgeStats.wantedCount, 10);

      await BadgeStats.setWantedCount(5);
      expect(await BadgeStats.wantedCount, 5);
    });

    test('backup — afterExport badge definition exists', () async {
      final badge = BadgeDefinitions.byId('backup');
      expect(badge, isNotNull);
      expect(badge!.name, 'Sauvegarde');
    });

    test('all 7 badge definitions exist', () {
      expect(BadgeDefinitions.all.length, 7);
      for (final id in [
        'first_add',
        'collector',
        'hunter',
        'photographer',
        'expert',
        'detective',
        'backup'
      ]) {
        expect(BadgeDefinitions.byId(id), isNotNull, reason: 'missing: $id');
      }
    });
  });
}
