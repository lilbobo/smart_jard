import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/code_screen.dart';
import 'screens/home_screen.dart';
import 'screens/version_screen.dart';
import 'screens/jard_screen.dart';
import 'screens/InventoryListScreen.dart';

void main() {
  // التأكد من تهيئة الإضافات قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SmartJardApp());
}

class SmartJardApp extends StatelessWidget {
  const SmartJardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Jard',

      // إعداد اللغة والاتجاه الافتراضي للتطبيق ليكون متوافقاً مع العربية
      locale: const Locale('ar', 'SA'),

      theme: ThemeData(
        useMaterial3: true,
        // تم إلغاء GoogleFonts واستخدام خطوط النظام الافتراضية
        // إذا كنت تملك ملف خط Cairo محلياً في مجلد assets، اترك السطر التالي
        // إذا لا تملك ملفاً محلياً، قم بوضع علامة تعليق (//) عليه
        fontFamily: 'Cairo',

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056CC),
          primary: const Color(0xFF0056CC),
        ),

        // تحسين مظهر النصوص بشكل عام في التطبيق
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/code': (context) => const CodeScreen(),
        '/home': (context) => const HomeScreen(),
        '/version': (context) => const VersionScreen(currentVersion: "0000"),
        '/jard': (context) => const JardScreen(),
        '/inventory_list': (context) => const InventoryListScreen(),
      },
    );
  }
}