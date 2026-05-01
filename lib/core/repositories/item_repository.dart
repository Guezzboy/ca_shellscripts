import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/item.dart';
import '../models/display_item.dart';

class ItemRepository {
  final _uuid = const Uuid();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<Item>> getByCollectionId(String collectionId) async {
    final db = await _db;
    final maps = await db.query(
      'items',
      where: 'base_id = ?',
      whereArgs: [collectionId],
      orderBy: 'number ASC, name ASC',
    );
    return maps.map(Item.fromMap).toList();
  }

  Future<List<Item>> searchByName(String collectionId, String query) async {
    final db = await _db;
    final maps = await db.query(
      'items',
      where: 'base_id = ? AND (name LIKE ? OR number LIKE ?)',
      whereArgs: [collectionId, '%$query%', '%$query%'],
      orderBy: 'number ASC, name ASC',
    );
    return maps.map(Item.fromMap).toList();
  }

  Future<void> insertBatch(List<Item> items) async {
    final db = await _db;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Item> create({
    required String baseId,
    required String name,
    String? number,
    String? description,
    String? imageUrl,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = Item(
      id: _uuid.v4(),
      baseId: baseId,
      name: name,
      number: number,
      description: description,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('items', item.toMap());
    return item;
  }

  /// Returns DisplayItems combining base items with owned status.
  Future<List<DisplayItem>> getDisplayItems(String collectionId) async {
    final db = await _db;

    // Base items with left join on owned_items
    final baseRows = await db.rawQuery('''
      SELECT
        i.id, i.name, i.number, i.image_url, i.metadata,
        o.id AS owned_record_id
      FROM items i
      LEFT JOIN owned_items o
        ON o.item_id = i.id AND o.collection_id = ?
      WHERE i.base_id = ?
      ORDER BY CAST(i.number AS INTEGER) ASC, i.name ASC
    ''', [collectionId, collectionId]);

    final baseItems = baseRows.map((row) {
      Map<String, dynamic>? meta;
      final metaRaw = row['metadata'] as String?;
      if (metaRaw != null && metaRaw.isNotEmpty) {
        try {
          meta = json.decode(metaRaw) as Map<String, dynamic>;
        } catch (_) {}
      }
      return DisplayItem(
        id: row['id'] as String,
        name: row['name'] as String,
        number: row['number'] as String?,
        imageUrl: row['image_url'] as String?,
        owned: row['owned_record_id'] != null,
        isCustom: false,
        isRare: (meta?['rare'] as bool?) ?? false,
        metadata: meta,
        ownedRecordId: row['owned_record_id'] as String?,
      );
    });

    // Custom items (always owned)
    final customRows = await db.rawQuery('''
      SELECT id, name, number, image_path
      FROM custom_items
      WHERE collection_id = ?
      ORDER BY created_at ASC
    ''', [collectionId]);

    final customItems = customRows.map((row) {
      final rawPath = row['image_path'] as String?;
      List<String> paths = [];
      if (rawPath != null && rawPath.isNotEmpty) {
        try {
          paths = (json.decode(rawPath) as List<dynamic>).cast<String>();
        } catch (_) {
          paths = [rawPath];
        }
      }
      return DisplayItem(
        id: row['id'] as String,
        name: row['name'] as String,
        number: row['number'] as String?,
        imagePaths: paths,
        owned: true,
        isCustom: true,
      );
    });

    return [...baseItems, ...customItems];
  }
}
