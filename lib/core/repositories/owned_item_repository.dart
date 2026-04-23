import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/owned_item.dart';

class OwnedItemRepository {
  final _uuid = const Uuid();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<OwnedItem> markOwned(String itemId, String collectionId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = OwnedItem(
      id: _uuid.v4(),
      itemId: itemId,
      collectionId: collectionId,
      owned: true,
      addedAt: now,
    );
    await db.insert('owned_items', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
    return record;
  }

  Future<void> markUnowned(String ownedRecordId) async {
    final db = await _db;
    await db.delete('owned_items',
        where: 'id = ?', whereArgs: [ownedRecordId]);
  }

  Future<int> countOwned(String collectionId) async {
    final db = await _db;
    return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM owned_items WHERE collection_id = ?',
          [collectionId])) ??
        0;
  }
}
