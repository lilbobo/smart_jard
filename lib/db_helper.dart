import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  initDB() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT,
          quantity REAL,
          cost REAL,
          date TEXT
        )
      ''');
    });
  }

  // دالة الحفظ
  Future<int> insertItem(Map<String, dynamic> data) async {
    Database dbClient = await db;
    return await dbClient.insert('items', data);
  }
}