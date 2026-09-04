import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';

/// 启动欢迎页（PRD 3.1）：日期、问候、随机寄语、进入按钮 + 撒爱心动效
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _hearts = <_HeartSpec>[];
  Timer? _cleanupTimer;
  int _heartSeq = 0;

  static const _heartEmojis = ['💕', '💗', '✨', '💖', '🩷'];

  void _burstHearts() {
    final random = Random();
    for (var i = 0; i < 10; i++) {
      _hearts.add(_HeartSpec(
        id: _heartSeq++,
        left: 0.15 + random.nextDouble() * 0.7,
        bottom: 0.38 + random.nextDouble() * 0.14,
        emoji: _heartEmojis[random.nextInt(_heartEmojis.length)],
        drift: (random.nextDouble() - 0.5) * 40,
      ));
    }
    setState(() {});
    _cleanupTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _hearts.clear());
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final now = DateTime.now();
    final name = store.profile.name.isEmpty ? '今天也要加油哦' : store.profile.name;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pal.softBg, AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: pal.softBorder, width: 4)),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/mascot.jpg',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 110,
                              height: 110,
                              color: pal.softBg,
                              alignment: Alignment.center,
                              child: const Text('🏠', style: TextStyle(fontSize: 44)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${fmtCN(now)} 星期${weekCn(now.weekday)}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted, letterSpacing: 1),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name.isEmpty ? '嗨，今天也要加油哦 🎀' : '嗨，$name 🎀',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${store.todayMotto} ✨',
                        style: const TextStyle(fontSize: 13, color: AppColors.sub),
                      ),
                      const SizedBox(height: 34),
                      _EnterButton(onTap: () {
                        _burstHearts();
                        Timer(const Duration(milliseconds: 380), () {
                          if (mounted) context.read<AppStore>().enterApp();
                        });
                      }),
                    ],
                  ),
                ),
              ),
              // 底部品牌标语
              const Positioned(
                left: 0,
                right: 0,
                bottom: 22,
                child: Text(
                  '小窝工作台 · 每天进步一点点',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 1),
                ),
              ),
              // 撒出的爱心
              for (final h in _hearts)
                Positioned(
                  left: MediaQuery.of(context).size.width * h.left - 10,
                  bottom: MediaQuery.of(context).size.height * h.bottom,
                  child: _FloatingHeart(spec: h),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EnterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 13),
          decoration: BoxDecoration(
            gradient: pal.gradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: pal.gradEnd.withOpacity(.4), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: const Text('进入工作台 →', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
        ),
      ),
    );
  }
}

class _HeartSpec {
  final int id;
  final double left;
  final double bottom;
  final String emoji;
  final double drift;

  const _HeartSpec({required this.id, required this.left, required this.bottom, required this.emoji, required this.drift});
}

class _FloatingHeart extends StatefulWidget {
  final _HeartSpec spec;

  const _FloatingHeart({required this.spec});

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn)),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(widget.spec.drift * _c.value, -70 * Curves.easeOut.transform(_c.value)),
          child: child,
        ),
        child: Text(widget.spec.emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
