import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'match_game_page.dart';
import 'tetris_page.dart';

/// 小游戏中心（新增功能 6）
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return ModuleScaffold(
      title: '🎮 小游戏',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          children: [
            _GameCard(
              emoji: '🍬',
              title: '消消乐',
              sub: '交换糖果，三个连成一线消除',
              color: const Color(0xFFF27E8A),
              best: store.gameBest('match'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchGamePage())),
            ),
            const SizedBox(height: 10),
            _GameCard(
              emoji: '🧱',
              title: '俄罗斯方块',
              sub: '经典下落消除，挑战更高分',
              color: const Color(0xFF5A9BF5),
              best: store.gameBest('tetris'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TetrisPage())),
            ),
            const SizedBox(height: 16),
            const Text('和 TA 比比谁分高吧！', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final Color color;
  final int best;
  final VoidCallback onTap;

  const _GameCard({required this.emoji, required this.title, required this.sub, required this.color, required this.best, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(.12), Colors.white]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
                BoxShadow(color: color.withOpacity(.25), blurRadius: 10, offset: const Offset(0, 4)),
              ]),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 5),
                  Text('最高分 $best', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
