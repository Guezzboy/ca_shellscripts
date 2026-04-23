import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/custom_item.dart';

class CustomItemRepository {
  final _uuid = const Uuid();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<CustomItem> create({
    required String name,
    String? number,
    required String collectionId,
    String? imagePath,
    required String source,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = CustomItem(
      id: _uuid.v4(),
      name: name,
      number: number,
      collectionId: collectionId,
      imagePath: imagePath,
      source: source,
      createdAt: now,
    );
    await db.insert('custom_items', item.toMap());
    return item;
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('custom_items', where: 'id = ?', whereArgs: [id]);
  }
}
