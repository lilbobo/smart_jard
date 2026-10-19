import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// --- تطوير كلاس DBHelper ليدعم عمود رقم النسخة وتعديل البيانات ---
class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    String path = p.join(await getDatabasesPath(), 'smart_jard.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, barcode TEXT, quantity REAL, cost REAL, timestamp TEXT, version_number TEXT)'
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE inventory ADD COLUMN version_number TEXT');
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    final Database dbClient = await db;
    return await dbClient.query('inventory', orderBy: 'id DESC');
  }

  Future<int> updateItem(int id, Map<String, dynamic> data) async {
    final Database dbClient = await db;
    return await dbClient.update('inventory', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAllVersions(String newVersion) async {
    final Database dbClient = await db;
    await dbClient.update('inventory', {'version_number': newVersion});
  }

  Future<int> deleteItem(int id) async {
    final Database dbClient = await db;
    return await dbClient.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }
}

// --- شاشة عرض سجلات الجرد (تم تنظيف الخطوط واستخدام خط النظام) ---
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  // ستايل ثابت للنصوص لضمان مظهر احترافي بدون خطوط خارجية
  final TextStyle _textStyleBold = const TextStyle(fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() async {
    final List<Map<String, dynamic>> data = await _dbHelper.getAllItems();
    if (!mounted) return;
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final TextEditingController qtyController = TextEditingController(text: item['quantity'].toString());
    final TextEditingController costController = TextEditingController(text: item['cost'].toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text("تعديل البيانات", textAlign: TextAlign.center, style: _textStyleBold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "الكمية"),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "التكلفة"),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () async {
              final NavigatorState navigator = Navigator.of(context);
              await _dbHelper.updateItem(item['id'], {
                'quantity': double.tryParse(qtyController.text) ?? 0.0,
                'cost': double.tryParse(costController.text) ?? 0.0,
              });
              if (!mounted) return;
              navigator.pop();
              _refreshItems();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056CC)),
            child: const Text("حفظ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text("سجل الجرد", style: _textStyleBold),
        centerTitle: true,
        backgroundColor: const Color(0xFF0056CC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0056CC)))
          : _items.isEmpty
          ? Center(child: Text("لا توجد بيانات مسجلة حالياً", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> item = _items[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF0056CC).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF0056CC))
              ),
              title: Text("باركود: ${item['barcode']}", style: _textStyleBold),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    "الكمية: ${item['quantity']} | التكلفة: ${item['cost']}\n"
                        "التاريخ: ${item['timestamp'].toString().substring(0, 16)}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                      onPressed: () => _showEditDialog(item)
                  ),
                  IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                      onPressed: () async {
                        final bool? confirm = await _showDeleteConfirm();
                        if (confirm == true && mounted) {
                          await _dbHelper.deleteItem(item['id']);
                          _refreshItems();
                        }
                      }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirm() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("تأكيد الحذف", style: _textStyleBold),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذا السجل نهائياً؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("حذف", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}