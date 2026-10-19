import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<Offset> _rightTextAnimation;
  late Animation<Offset> _leftTextAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    // 1. أنيميشن الشعار (نزول)
    _logoSlideAnimation = Tween<Offset>(begin: const Offset(0, -2.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutQuart),
      ),
    );

    // 2. أنيميشن النصوص (تجمع من اليمين واليسار)
    _rightTextAnimation = Tween<Offset>(begin: const Offset(3, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _leftTextAnimation = Tween<Offset>(begin: const Offset(-3, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4)),
    );

    _controller.forward();

    // الانتقال للشاشة التالية بعد 6 ثوانٍ
    Timer(const Duration(seconds: 6), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/code');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- ويدجت المكعب الصغير المتحرك (بديل لـ ProgressIndicator) ---
  Widget _buildCube(Color color, Duration delay) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: -15, duration: 600.ms, delay: delay, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // نمط نص موحد يعتمد على خط النظام (نظيف وسريع التحميل)
    final TextStyle splashTextStyle = TextStyle(
      fontSize: size.width * 0.07,
      fontWeight: FontWeight.bold,
      // تم إلغاء fontFamily: 'Cairo' لضمان عدم حدوث خطأ عند غياب الإنترنت
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الشعار الأصلي مع تأثير اللمعة
            SlideTransition(
              position: _logoSlideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/logo.png',
                  width: size.shortestSide * 0.7,
                  height: size.shortestSide * 0.7,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.business_rounded, size: 100, color: Color(0xFF0056CC)),
                )
                    .animate()
                    .scale(delay: 200.ms, duration: 800.ms, curve: Curves.easeOutBack)
                    .shimmer(delay: 1500.ms, duration: 1500.ms, color: Colors.blue.shade200),
              ),
            ),

            const SizedBox(height: 30),

            // نصوص العنوان مع الظلال وتأثير التجمع
            FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  SlideTransition(
                    position: _rightTextAnimation,
                    child: Text(
                      "تطبيق الجرد ",
                      style: splashTextStyle.copyWith(
                        color: const Color(0xFF0056CC),
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(2, 2), blurRadius: 5),
                        ],
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: _leftTextAnimation,
                    child: Text(
                      "الذكي",
                      style: splashTextStyle.copyWith(
                        color: Colors.orangeAccent,
                        shadows: [
                          Shadow(color: Colors.orange.withValues(alpha: 0.2), offset: const Offset(0, 0), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().shimmer(delay: 2500.ms, duration: 1500.ms, color: Colors.white70),

            const SizedBox(height: 60),

            // --- مكعبات التحميل المتحركة ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCube(const Color(0xFF0056CC), 0.ms),
                const SizedBox(width: 8),
                _buildCube(Colors.orangeAccent, 200.ms),
                const SizedBox(width: 8),
                _buildCube(const Color(0xFF0056CC), 400.ms),
              ],
            ).animate().fadeIn(delay: 3000.ms),
          ],
        ),
      ),
    );
  }
}