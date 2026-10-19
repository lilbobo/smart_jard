import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final String databasesPath = await getDatabasesPath();
    final String path = p.join(databasesPath, 'smart_jard.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, barcode TEXT, quantity REAL, cost REAL, timestamp TEXT, version_number TEXT)'
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE inventory ADD COLUMN version_number TEXT');
        }
      },
    );
  }

  // دالة جلب البيانات
  Future<List<Map<String, dynamic>>> getAllItems() async {
    try {
      final Database dbClient = await db;
      return await dbClient.query('inventory', orderBy: 'id DESC');
    } catch (e) {
      return [];
    }
  }

  // دالة التحديث الشامل لرقم النسخة
  Future<void> updateAllVersions(String newVersion) async {
    final Database dbClient = await db;
    await dbClient.update('inventory', {'version_number': newVersion});
  }

  // دالة الحذف
  Future<int> deleteItem(int id) async {
    final Database dbClient = await db;
    return await dbClient.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  // دالة تعديل سجل واحد
  Future<int> updateItem(int id, Map<String, dynamic> data) async {
    final Database dbClient = await db;
    return await dbClient.update('inventory', data, where: 'id = ?', whereArgs: [id]);
  }
}