import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'collection_app.db';
  static const _databaseVersion = 4;

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
      onUpgrade: _onUpgrade,
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

    await db.execute('''
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE owned_items ADD COLUMN user_photos TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE items ADD COLUMN isbn TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN author TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN publisher TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN publish_year TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN edition TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN genre TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN condition TEXT');
      await db.execute(
          'ALTER TABLE items ADD COLUMN purchase_price REAL');
      await db.execute(
          'ALTER TABLE items ADD COLUMN estimated_value REAL');
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE items ADD COLUMN wanted INTEGER NOT NULL DEFAULT 0');
    }
  }
}
