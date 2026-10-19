import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// --- كلاس DBHelper الموحد ---
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

  Future<void> updateAllVersions(String newVersion) async {
    final Database dbClient = await db;
    await dbClient.update('inventory', {'version_number': newVersion});
  }
}

class VersionScreen extends StatefulWidget {
  final String currentVersion;
  const VersionScreen({super.key, this.currentVersion = "0000"});

  @override
  State<VersionScreen> createState() => _VersionScreenState();
}

class _VersionScreenState extends State<VersionScreen> {
  late TextEditingController _controller;
  final DBHelper _dbHelper = DBHelper();

  // ستايل موحد لتعويض Cairo
  final TextStyle _baseStyle = const TextStyle(fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentVersion);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          title: Text(
            "تعديل رقم نسخة النظام",
            style: _baseStyle,
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0056CC),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: "رقم نسخة البرنامج (4 أرقام)",
                  labelStyle: const TextStyle(fontWeight: FontWeight.normal),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  prefixIcon: const Icon(Icons.edit, color: Color(0xFF0056CC)),
                  counterText: "",
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_controller.text.length == 4) {
                      String newV = _controller.text;

                      try {
                        // 1. الحفظ في SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('saved_version', newV);

                        // 2. تحديث قاعدة البيانات
                        try {
                          await _dbHelper.updateAllVersions(newV);
                        } catch (dbError) {
                          debugPrint("فشل تحديث SQL: $dbError");
                        }

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("تم حفظ وتحديث رقم النسخة بنجاح", textAlign: TextAlign.right),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        Navigator.pop(context, newV);

                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("يرجى إدخال 4 أرقام بالضبط", textAlign: TextAlign.right),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    "حفظ وتحديث",
                    style: _baseStyle.copyWith(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}