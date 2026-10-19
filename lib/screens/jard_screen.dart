import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// --- مدير قاعدة البيانات (تم تحديث الإصدار ليتوافق مع التعديلات السابقة) ---
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
      version: 2, // موحد مع بقية الصفحات
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode TEXT,
            quantity REAL,
            cost REAL,
            timestamp TEXT,
            version_number TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE inventory ADD COLUMN version_number TEXT');
        }
      },
    );
  }

  Future<int> insertItem(Map<String, dynamic> data) async {
    final Database dbClient = await db;
    return await dbClient.insert('inventory', data);
  }
}

class JardScreen extends StatefulWidget {
  const JardScreen({super.key});

  @override
  State<JardScreen> createState() => _JardScreenState();
}

class _JardScreenState extends State<JardScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DBHelper _dbHelper = DBHelper();

  bool _canScan = true;

  // ستايل موحد للنصوص بدلاً من خطوط جوجل
  final TextStyle _labelStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: Colors.black87,
  );

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _clearAllFields() {
    setState(() {
      _barcodeController.clear();
      _quantityController.clear();
      _costController.clear();
      _canScan = true;
    });
  }

  void _saveData() async {
    final String barcode = _barcodeController.text.trim();
    final String qty = _quantityController.text.trim();
    final String cost = _costController.text.trim();

    final messenger = ScaffoldMessenger.of(context);

    if (barcode.isEmpty || qty.isEmpty || cost.isEmpty) {
      _showSnackBar(messenger, "الرجاء إكمال جميع البيانات", Colors.orange);
      return;
    }

    try {
      final Map<String, dynamic> row = {
        'barcode': barcode,
        'quantity': double.tryParse(qty) ?? 0.0,
        'cost': double.tryParse(cost) ?? 0.0,
        'timestamp': DateTime.now().toString(),
        'version_number': "0000", // قيمة افتراضية أو جلبها من prefs
      };

      await _dbHelper.insertItem(row);

      if (!mounted) return;
      _showSnackBar(messenger, "تم حفظ السجل بنجاح", Colors.green);
      _clearAllFields();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(messenger, "خطأ أثناء الحفظ: $e", Colors.red);
    }
  }

  void _showSnackBar(ScaffoldMessengerState messenger, String message, Color color) {
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleBarcodeDetection(String code) async {
    if (code == _barcodeController.text) return;
    if (!_canScan) return;

    setState(() {
      _canScan = false;
      _barcodeController.text = code;
    });

    try {
      await _audioPlayer.play(AssetSource('beep.mp3'));
    } catch (e) {
      debugPrint("خطأ في الصوت: $e");
    }

    final bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 100);
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      setState(() {
        _canScan = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("عملية الجرد", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0056CC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // إطار الكاميرا
            Container(
              height: size.height * 0.25,
              margin: const EdgeInsets.symmetric(horizontal: 50),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _canScan ? const Color(0xFF0056CC) : Colors.orangeAccent,
                    width: 2
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    MobileScanner(
                      onDetect: (BarcodeCapture capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          _handleBarcodeDetection(barcodes.first.rawValue ?? "");
                        }
                      },
                    ),
                    if (!_canScan)
                      Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  _buildInputField(
                    label: "قيمة الباركود",
                    controller: _barcodeController,
                    icon: Icons.qr_code_rounded,
                    keyboardType: TextInputType.text,
                    hint: "سيظهر الرقم هنا عند المسح",
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(
                    label: "الكمية",
                    controller: _quantityController,
                    icon: Icons.ad_units_rounded,
                    keyboardType: TextInputType.number,
                    hint: "ادخل الكمية هنا",
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(
                    label: "التكلفة",
                    controller: _costController,
                    icon: Icons.payments_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hint: "ادخل التكلفة هنا",
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: OutlinedButton(
                            onPressed: _clearAllFields,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("إلغاء", style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _saveData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056CC),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            child: const Text("حفظ السجل", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 8),
          child: Text(label, style: _labelStyle),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: const Color(0xFF0056CC)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0056CC))),
          ),
        ),
      ],
    );
  }
}