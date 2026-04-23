import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'collection_app.db';
  static const _databaseVersion = 1;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
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

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        base_id TEXT NOT NULL,
        name TEXT NOT NULL,
        number TEXT,
        description TEXT,
        image_url TEXT,
        metadata TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE owned_items (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        collection_id TEXT NOT NULL,
        owned INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
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

    await db.execute(
        'CREATE INDEX idx_items_base_id ON items(base_id)');
    await db.execute(
        'CREATE INDEX idx_owned_collection ON owned_items(collection_id)');
    await db.execute(
        'CREATE INDEX idx_owned_item ON owned_items(item_id)');
    await db.execute(
        'CREATE INDEX idx_custom_collection ON custom_items(collection_id)');
  }
}
