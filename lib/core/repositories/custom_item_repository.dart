import 'dart:convert';
import 'dart:io';
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
    List<String> imagePaths = const [],
    required String source,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = CustomItem(
      id: _uuid.v4(),
      name: name,
      number: number,
      collectionId: collectionId,
      imagePaths: imagePaths,
      source: source,
      createdAt: now,
    );
    await db.insert('custom_items', item.toMap());
    return item;
  }

  Future<void> updateImagePaths(String id, List<String> imagePaths) async {
    final db = await _db;
    await db.update(
      'custom_items',
      {'image_path': imagePaths.isEmpty ? null : json.encode(imagePaths)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;

    // Load image paths before deleting the row
    final rows = await db.query('custom_items',
        columns: ['image_path'], where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final raw = rows.first['image_path'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final paths = CustomItem.parsePaths(raw);
        for (final path in paths) {
          try {
            await File(path).delete();
          } catch (_) {
            // File already gone or inaccessible — that's fine
          }
        }
      }
    }

    await db.delete('custom_items', where: 'id = ?', whereArgs: [id]);
  }
}
