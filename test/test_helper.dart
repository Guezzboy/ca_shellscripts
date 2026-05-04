import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:collection_app/core/database/database_helper.dart';

/// Creates an in-memory test database, creates all tables,
/// and injects it into DatabaseHelper so repositories use it.
Future<Database> setupTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await _createTables(db);
  DatabaseHelper.setTestDatabase(db);
  return db;
}

Future<void> _createTables(Database db) async {
  final batch = db.batch();
  batch.execute('''
    CREATE TABLE collections (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      source_url TEXT,
      version INTEGER NOT NULL DEFAULT 1,
      item_count INTEGER NOT NULL DEFAULT 0,
      last_sync INTEGER,
      created_at INTEGER NOT NULL
    )
  ''');
  batch.execute('''
    CREATE TABLE items (
      id TEXT PRIMARY KEY,
      base_id TEXT NOT NULL,
      name TEXT NOT NULL,
      number TEXT,
      description TEXT,
      image_url TEXT,
      metadata TEXT,
      isbn TEXT,
      author TEXT,
      publisher TEXT,
      publish_year TEXT,
      edition TEXT,
      genre TEXT,
      condition TEXT,
      purchase_price REAL,
      estimated_value REAL,
      wanted INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  batch.execute('''
    CREATE TABLE owned_items (
      id TEXT PRIMARY KEY,
      item_id TEXT NOT NULL,
      collection_id TEXT NOT NULL,
      owned INTEGER NOT NULL DEFAULT 1,
      notes TEXT,
      user_photos TEXT,
      added_at INTEGER NOT NULL,
      FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
    )
  ''');
  batch.execute('''
    CREATE TABLE custom_items (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      number TEXT,
      collection_id TEXT NOT NULL,
      image_path TEXT,
      source TEXT NOT NULL DEFAULT 'manual',
      created_at INTEGER NOT NULL,
      FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
    )
  ''');
  batch.execute('CREATE INDEX idx_items_base_id ON items(base_id)');
  batch.execute(
      'CREATE INDEX idx_owned_collection ON owned_items(collection_id)');
  batch.execute('CREATE INDEX idx_owned_item ON owned_items(item_id)');
  batch.execute(
      'CREATE INDEX idx_custom_collection ON custom_items(collection_id)');
  await batch.commit(noResult: true);
}
