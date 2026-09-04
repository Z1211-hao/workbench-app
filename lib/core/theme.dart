import 'package:flutter/material.dart';

/// 四套主题色板，与 PRD 3.9 保持一致
class AppPalette {
  final String key;
  final String name;
  final Color primary;
  final Color gradStart;
  final Color gradEnd;
  final Color softBg;
  final Color softBorder;

  const AppPalette({
    required this.key,
    required this.name,
    required this.primary,
    required this.gradStart,
    required this.gradEnd,
    required this.softBg,
    required this.softBorder,
  });

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradStart, gradEnd],
      );
}

const appPalettes = <String, AppPalette>{
  'pink': AppPalette(
    key: 'pink',
    name: '樱花粉',
    primary: Color(0xFFE8798F),
    gradStart: Color(0xFFF58CA0),
    gradEnd: Color(0xFFE8798F),
    softBg: Color(0xFFFFF3F5),
    softBorder: Color(0xFFF6DCE2),
  ),
  'lavender': AppPalette(
    key: 'lavender',
    name: '薰衣草紫',
    primary: Color(0xFFB79CE8),
    gradStart: Color(0xFFC9A7EE),
    gradEnd: Color(0xFFB79CE8),
    softBg: Color(0xFFF7F3FC),
    softBorder: Color(0xFFE9DFFB),
  ),
  'mint': AppPalette(
    key: 'mint',
    name: '薄荷绿',
    primary: Color(0xFF6FC7A6),
    gradStart: Color(0xFF8FD4BC),
    gradEnd: Color(0xFF6FC7A6),
    softBg: Color(0xFFF1FAF6),
    softBorder: Color(0xFFDFF3EA),
  ),
  'peach': AppPalette(
    key: 'peach',
    name: '蜜桃橙',
    primary: Color(0xFFF79E75),
    gradStart: Color(0xFFFDBA96),
    gradEnd: Color(0xFFF79E75),
    softBg: Color(0xFFFEF5F0),
    softBorder: Color(0xFFFDE7DB),
  ),
};

const defaultPaletteKey = 'pink';

AppPalette paletteOf(String key) => appPalettes[key] ?? appPalettes[defaultPaletteKey]!;

/// 全局通用色（不随主题切换的暖色系基础色）
class AppColors {
  static const bg = Color(0xFFFFF9FA);
  static const card = Colors.white;
  static const ink = Color(0xFF5A4A4F);
  static const sub = Color(0xFF8A7A80);
  static const muted = Color(0xFFC79FAD);
  static const line = Color(0xFFF3E7EA);
  static const income = Color(0xFF79B58C);
  static const danger = Color(0xFFE96A6A);
  static const shared = Color(0xFF8E7CC3);
}

class AppThemes {
  static ThemeData build(BuildContext context, AppPalette p) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: p.primary, brightness: Brightness.light),
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.sub, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
