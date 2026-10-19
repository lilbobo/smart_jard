import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_jard/screens/version_screen.dart';

// --- مساعد قاعدة البيانات ---
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

  Future<List<Map<String, dynamic>>> getAllItems() async {
    try {
      final Database dbClient = await db;
      return await dbClient.query('inventory', orderBy: 'id DESC');
    } catch (e) {
      return [];
    }
  }

  Future<void> updateAllVersions(String newVersion) async {
    final Database dbClient = await db;
    await dbClient.update('inventory', {'version_number': newVersion});
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasData = false;
  int _recordCount = 0;
  final DBHelper _dbHelper = DBHelper();
  String systemVersion = "0000";

  // ستايل ثابت للنصوص لتعويض Cairo
  final TextStyle _baseStyle = const TextStyle(
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    super.initState();
    _loadSavedVersion();
    _checkDatabase();
  }

  void _loadSavedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        systemVersion = prefs.getString('saved_version') ?? "0000";
      });
    }
  }

  void _checkDatabase() async {
    try {
      final List<Map<String, dynamic>> data = await _dbHelper.getAllItems();
      if (mounted) {
        setState(() {
          _recordCount = data.length;
          _hasData = _recordCount > 0;
        });
      }
    } catch (e) {
      debugPrint("خطأ في قاعدة البيانات: $e");
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  "نظام الجرد الذكي",
                  style: _baseStyle.copyWith(
                      fontSize: 20,
                      color: const Color(0xFF0056CC)
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "هذا النظام مقدم من شركة سمارت برو لتسهيل عمليات الجرد، يتميز التطبيق بالسرعة والدقة وسهولة عملية الجرد في قراءة الباركود وربط البيانات وترحيلها الى النظام",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056CC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      "إغلاق",
                      style: _baseStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const String institutionName = "شركة سمارت برو";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      drawer: _buildVersionDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0056CC)),
        title: Text(
          "الرئيسية",
          style: _baseStyle.copyWith(color: const Color(0xFF0056CC)),
        ),
        actions: [
          IconButton(
            onPressed: _checkDatabase,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0056CC)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildInfoCard(
              title: "اسم المؤسسة",
              value: institutionName,
              icon: Icons.business_rounded,
              color: const Color(0xFF0056CC),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),

            const SizedBox(height: 15),

            _buildInfoCard(
              title: "رقم نسخة النظام المرتبط",
              value: systemVersion,
              icon: Icons.vibration_rounded,
              color: Colors.orangeAccent,
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: 0.2),

            const SizedBox(height: 40),

            SizedBox(
              height: 65,
              child: OutlinedButton(
                onPressed: _hasData ? () {
                  Navigator.pushNamed(context, '/inventory_list').then((_) => _checkDatabase());
                } : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _hasData ? const Color(0xFF0056CC) : Colors.grey.shade300, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  backgroundColor: _hasData ? Colors.white : Colors.grey.shade100,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, color: _hasData ? const Color(0xFF0056CC) : Colors.grey.shade400),
                    const SizedBox(width: 12),
                    Text(
                      "عرض سجلات الجرد",
                      style: _baseStyle.copyWith(
                          fontSize: 16,
                          color: _hasData ? const Color(0xFF0056CC) : Colors.grey.shade400
                      ),
                    ),
                    if (_hasData) ...[
                      const SizedBox(width: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0056CC), borderRadius: BorderRadius.circular(20)),
                        child: Text("$_recordCount", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ).animate().scale(),
                    ],
                  ],
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: SizedBox(
                height: 65,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/jard').then((_) => _checkDatabase());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, size: 28),
                      const SizedBox(width: 15),
                      Text(
                        "ابدأ الجرد الآن",
                        style: _baseStyle.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).scale(curve: Curves.elasticOut, duration: 800.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0056CC), Color(0xFF003D99)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                height: 160,
                width: 160,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Transform.scale(
                    scale: 1.3,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.business_rounded, color: Color(0xFF0056CC), size: 80),
                    ),
                  ),
                ),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF0056CC)),
            title: const Text("إصدار التطبيق", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("v1.0.0"),
          ),

          ListTile(
            leading: const Icon(Icons.edit_note_rounded, color: Color(0xFF0056CC)),
            title: const Text("تعديل رقم نسخة النظام", style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VersionScreen(currentVersion: systemVersion),
                ),
              );

              if (result != null && result is String) {
                setState(() {
                  systemVersion = result;
                });
              }
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.orangeAccent),
            title: const Text("عن التطبيق", style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            color: Colors.grey.shade50,
            child: const Text(
              "جميع الحقوق محفوظة © 2026",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
        ],
      ),
    );
  }
}