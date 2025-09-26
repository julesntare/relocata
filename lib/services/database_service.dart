import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/furniture_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'relocata.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE furniture_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        room TEXT NOT NULL,
        image_path TEXT,
        width_cm REAL,
        height_cm REAL,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertItem(FurnitureItem item) async {
    final db = await database;
    return await db.insert(
      'furniture_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FurnitureItem>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'furniture_items',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return FurnitureItem.fromMap(maps[i]);
    });
  }

  Future<List<FurnitureItem>> getItemsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'furniture_items',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return FurnitureItem.fromMap(maps[i]);
    });
  }

  Future<List<FurnitureItem>> getItemsByRoom(String room) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'furniture_items',
      where: 'room = ?',
      whereArgs: [room],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return FurnitureItem.fromMap(maps[i]);
    });
  }

  Future<FurnitureItem?> getItemById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'furniture_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return FurnitureItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateItem(FurnitureItem item) async {
    final db = await database;
    return await db.update(
      'furniture_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(String id) async {
    final db = await database;
    return await db.delete(
      'furniture_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getItemCountsByCategory() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM furniture_items
      GROUP BY category
    ''');

    Map<String, int> counts = {};
    for (var row in result) {
      counts[row['category']] = row['count'];
    }
    return counts;
  }

  Future<Map<String, int>> getItemCountsByRoom() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT room, COUNT(*) as count
      FROM furniture_items
      GROUP BY room
    ''');

    Map<String, int> counts = {};
    for (var row in result) {
      counts[row['room']] = row['count'];
    }
    return counts;
  }

  Future<double> getTotalArea() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(width_cm * height_cm) as total_area
      FROM furniture_items
      WHERE width_cm IS NOT NULL
      AND height_cm IS NOT NULL
    ''');

    if (result.isNotEmpty && result.first['total_area'] != null) {
      return (result.first['total_area'] as num).toDouble() / 10000; // Convert to square meters
    }
    return 0.0;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}