import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- مساعد قاعدة البيانات ---
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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE inventory ADD COLUMN version_number TEXT');
        }
      },
    );
  }
}

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final DBHelper _dbHelper = DBHelper();

  final TextStyle _arabicStyle = const TextStyle(fontWeight: FontWeight.bold);

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // دالة التعامل مع حالة الخطأ (إعادة التركيز وتحديد النص)
  void _handleErrorState() {
    _focusNode.requestFocus();
    if (_codeController.text.isNotEmpty) {
      _codeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _codeController.text.length,
      );
    }
  }

  // دالة التواصل عبر واتساب
  void _contactSupport() async {
    const String phoneNumber = "966503387544";
    const String message = "السلام عليكم، أحتاج المساعدة في شفرة الدخول لتطبيق الجرد الذكي";
    final Uri url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("تعذر فتح واتساب", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("خطأ في الاتصال", Colors.red);
    }
  }

  // تحويل الأرقام لإنجليزية لضمان صحة المقارنة
  String _convertToEnglishNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < arabic.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  // إظهار التنبيه بشكل احترافي
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // مسح الرسائل القديمة فوراً
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right, style: _arabicStyle),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // أيقونة المفتاح
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: const Icon(Icons.vpn_key_rounded, size: 60, color: Color(0xFF0056CC)),
              ).animate().fadeIn().scale(),

              const SizedBox(height: 40),

              Text(
                "الرجاء إدخال الشفرة",
                style: _arabicStyle.copyWith(fontSize: 24, color: const Color(0xFF0056CC)),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),

              // حقل إدخال الشفرة
              TextField(
                controller: _codeController,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(letterSpacing: 2, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "رقم الشفرة",
                  hintStyle: _arabicStyle.copyWith(fontSize: 16, color: Colors.grey.shade400, letterSpacing: 0),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(20),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 30),

              // زر الدخول مع المنطق المدمج
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    String rawInput = _codeController.text.trim();
                    String input = _convertToEnglishNumbers(rawInput);

                    if (input.isEmpty) {
                      // الحالة 1: الحقل فارغ (تنبيه برتقالي)
                      _showSnackBar("يجب إدخال الشفرة أولاً", Colors.orange.shade700);
                      _handleErrorState();
                    } else if (input == "1234") {
                      // الحالة 2: الشفرة صحيحة
                      await _dbHelper.db;
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      // الحالة 3: الشفرة خاطئة (تنبيه أحمر)
                      _showSnackBar("الشفرة غير صحيحة، حاول مجدداً", Colors.redAccent);
                      _handleErrorState();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text("دخول", style: _arabicStyle.copyWith(fontSize: 18, color: Colors.white)),
                ),
              ).animate().fadeIn(delay: 700.ms),

              const Spacer(flex: 1),

              // زر التواصل عبر واتساب
              InkWell(
                onTap: _contactSupport,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Color(0xFF25D366),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "تحتاج مساعدة؟ تواصل معنا عبر واتساب",
                        style: _arabicStyle.copyWith(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}