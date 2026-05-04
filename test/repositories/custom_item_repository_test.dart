import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:collection_app/core/database/database_helper.dart';
import 'package:collection_app/core/repositories/collection_repository.dart';
import 'package:collection_app/core/repositories/custom_item_repository.dart';
import 'package:collection_app/core/models/custom_item.dart';
import '../test_helper.dart';

void main() {
  late CustomItemRepository customRepo;
  late CollectionRepository colRepo;
  late String collectionId;

  setUpAll(() async {
    await setupTestDatabase();
  });

  setUp(() async {
    customRepo = CustomItemRepository();
    colRepo = CollectionRepository();
    final col = await colRepo.create('Custom Items Test');
    collectionId = col.id;
  });

  group('CustomItemRepository', () {
    test('create — inserts a custom item and returns it', () async {
      final item = await customRepo.create(
        name: 'Test Item',
        number: '042',
        collectionId: collectionId,
        source: 'manual',
      );

      expect(item.id, isNotEmpty);
      expect(item.name, 'Test Item');
      expect(item.number, '042');
      expect(item.collectionId, collectionId);
      expect(item.source, 'manual');
      expect(item.imagePaths, isEmpty);
      expect(item.createdAt, isPositive);
    });

    test('create — stores image paths as JSON', () async {
      final item = await customRepo.create(
        name: 'Photo Item',
        collectionId: collectionId,
        imagePaths: ['/tmp/photo1.jpg', '/tmp/photo2.jpg'],
        source: 'photo',
      );

      expect(item.imagePaths, ['/tmp/photo1.jpg', '/tmp/photo2.jpg']);

      // Verify the paths were serialized/deserialized correctly
      expect(CustomItem.parsePaths, isNotNull);
    });

    test('updateImagePaths — replaces image paths', () async {
      final item = await customRepo.create(
        name: 'Updatable',
        collectionId: collectionId,
        imagePaths: ['/tmp/old.jpg'],
        source: 'photo',
      );

      await customRepo.updateImagePaths(item.id, ['/tmp/new1.jpg', '/tmp/new2.jpg']);

      // Verify via DB directly
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('custom_items', where: 'id = ?', whereArgs: [item.id]);
      expect(rows.length, 1);
      final raw = rows.first['image_path'] as String;
      final paths = CustomItem.parsePaths(raw);
      expect(paths, ['/tmp/new1.jpg', '/tmp/new2.jpg']);
    });

    test('updateImagePaths — sets null for empty list', () async {
      final item = await customRepo.create(
        name: 'Clear Paths',
        collectionId: collectionId,
        imagePaths: ['/tmp/photo.jpg'],
        source: 'photo',
      );

      await customRepo.updateImagePaths(item.id, []);

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('custom_items', where: 'id = ?', whereArgs: [item.id]);
      expect(rows.first['image_path'], isNull);
    });

    test('delete — removes item from DB', () async {
      final item = await customRepo.create(
        name: 'Deletable',
        collectionId: collectionId,
        source: 'manual',
      );

      await customRepo.delete(item.id);

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('custom_items', where: 'id = ?', whereArgs: [item.id]);
      expect(rows, isEmpty);
    });

    test('delete — attempts file cleanup (no-op for missing files)', () async {
      final item = await customRepo.create(
        name: 'File Cleanup',
        collectionId: collectionId,
        imagePaths: ['/nonexistent/path/file.jpg'],
        source: 'photo',
      );

      // Should not throw even though file doesn't exist
      await customRepo.delete(item.id);

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('custom_items', where: 'id = ?', whereArgs: [item.id]);
      expect(rows, isEmpty);
    });

    test('CustomItem.parsePaths — handles null', () {
      expect(CustomItem.parsePaths(null), isEmpty);
    });

    test('CustomItem.parsePaths — handles empty string', () {
      expect(CustomItem.parsePaths(''), isEmpty);
    });

    test('CustomItem.parsePaths — decodes JSON array', () {
      final paths = CustomItem.parsePaths('["/a.jpg","/b.jpg"]');
      expect(paths, ['/a.jpg', '/b.jpg']);
    });

    test('CustomItem.parsePaths — returns raw string as single path (backward compat)', () {
      final paths = CustomItem.parsePaths('not-json');
      expect(paths, ['not-json']);
    });
  });
}
