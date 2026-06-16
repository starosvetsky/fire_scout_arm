import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/hotspot.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  DatabaseHelper._init();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fire_scout.db');
    return _database!;
  }
  
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }
  
  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE hotspots (id TEXT PRIMARY KEY, latitude REAL NOT NULL, longitude REAL NOT NULL, status TEXT NOT NULL)');
  }
  
  Future<void> insertHotspot(Hotspot hotspot) async {
    final db = await instance.database;
    await db.insert('hotspots', hotspot.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<List<Hotspot>> getAllHotspots() async {
    final db = await instance.database;
    final result = await db.query('hotspots');
    return result.map((json) => Hotspot.fromMap(json)).toList();
  }
  
  Future<void> updateStatus(String id, String status) async {
    final db = await instance.database;
    await db.update('hotspots', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }
}
