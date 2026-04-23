import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/collection.dart';

class CollectionRepository {
  final _uuid = const Uuid();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<Collection>> getAll() async {
    final db = await _db;
    final maps = await db.query('collections', orderBy: 'created_at DESC');
    return maps.map(Collection.fromMap).toList();
  }

  Future<Collection?> getById(String id) async {
    final db = await _db;
    final maps =
        await db.query('collections', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Collection.fromMap(maps.first);
  }

  Future<Collection> create(String name, {String? sourceUrl}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final collection = Collection(
      id: _uuid.v4(),
      name: name,
      sourceUrl: sourceUrl,
      createdAt: now,
    );
    await db.insert('collections', collection.toMap());
    return collection;
  }

  Future<void> update(Collection collection) async {
    final db = await _db;
    await db.update(
      'collections',
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('collections', where: 'id = ?', whereArgs: [id]);
    // Cascade: also delete owned_items and custom_items for this collection
    await db.delete('owned_items',
        where: 'collection_id = ?', whereArgs: [id]);
    await db.delete('custom_items',
        where: 'collection_id = ?', whereArgs: [id]);
    // Items are shared via base_id — keep them to avoid re-download issues
  }

  Future<void> updateItemCount(String collectionId) async {
    final db = await _db;
    final baseCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM items WHERE base_id = ?', [collectionId])) ??
        0;
    final customCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM custom_items WHERE collection_id = ?',
          [collectionId])) ??
        0;
    await db.update(
      'collections',
      {'item_count': baseCount + customCount},
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }
}
