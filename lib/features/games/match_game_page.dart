import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// 消消乐（新增功能 6 之一）：8x8 三消，6 种糖果
class MatchGamePage extends StatefulWidget {
  const MatchGamePage({super.key});

  @override
  State<MatchGamePage> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGamePage> {
  static const n = 8;
  static const candies = ['🍓', '🍊', '🍋', '🍇', '🫐', '🍬'];
  static const candyColors = [Color(0xFFF27E8A), Color(0xFFF7A94C), Color(0xFFF7D154), Color(0xFF9B7EDB), Color(0xFF7FA8F5), Color(0xFF6FC7A6)];

  late List<List<int>> board; // -1 空
  int score = 0;
  (int, int)? selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _newBoard();
  }

  void _newBoard() {
    board = List.generate(n, (_) => List.generate(n, (_) => math.Random().nextInt(candies.length)));
    _clearMatches(false); // 去除初始三连
    score = 0;
    _busy = false;
  }

  (int, int)? _matchAt(int r, int c, List<List<int>> b) {
    final v = b[r][c];
    if (v < 0) return null;
    var h = 1;
    while (c + h < n && b[r][c + h] == v) {
      h++;
    }
    var hl = 1;
    while (c - hl >= 0 && b[r][c - hl] == v) {
      hl++;
    }
    if (h + hl - 1 >= 3) return (h + hl - 1, 0);
    var vv = 1;
    while (r + vv < n && b[r + vv][c] == v) {
      vv++;
    }
    var vd = 1;
    while (r - vd >= 0 && b[r - vd][c] == v) {
      vd++;
    }
    if (vv + vd - 1 >= 3) return (0, vv + vd - 1);
    return null;
  }

  Set<(int, int)> _findAllMatches(List<List<int>> b) {
    final s = <(int, int)>{};
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final m = _matchAt(r, c, b);
        if (m == null) continue;
        final (hl, vl) = m;
        if (hl >= 3) {
          for (var i = c - hl + 1; i <= c; i++) {
            s.add((r, i));
          }
        }
        if (vl >= 3) {
          for (var i = r - vl + 1; i <= r; i++) {
            s.add((i, c));
          }
        }
      }
    }
    return s;
  }

  bool _hasValidMove(List<List<int>> b) {
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (c + 1 < n) {
          _swap(b, r, c, r, c + 1);
          final m = _findAllMatches(b);
          _swap(b, r, c, r, c + 1);
          if (m.isNotEmpty) return true;
        }
        if (r + 1 < n) {
          _swap(b, r, c, r + 1, c);
          final m = _findAllMatches(b);
          _swap(b, r, c, r + 1, c);
          if (m.isNotEmpty) return true;
        }
      }
    }
    return false;
  }

  void _swap(List<List<int>> b, int r1, int c1, int r2, int c2) {
    final t = b[r1][c1];
    b[r1][c1] = b[r2][c2];
    b[r2][c2] = t;
  }

  /// 清除所有匹配（返回是否清除过）
  bool _clearMatches(bool scoring) {
    final matches = _findAllMatches(board);
    if (matches.isEmpty) return false;
    for (final (r, c) in matches) {
      board[r][c] = -1;
      if (scoring) score += 10;
    }
    _gravity();
    _refill();
    return true;
  }

  void _gravity() {
    for (var c = 0; c < n; c++) {
      var write = n - 1;
      for (var r = n - 1; r >= 0; r--) {
        if (board[r][c] >= 0) {
          board[write][c] = board[r][c];
          if (write != r) board[r][c] = -1;
          write--;
        }
      }
    }
  }

  void _refill() {
    final rand = math.Random();
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (board[r][c] < 0) board[r][c] = rand.nextInt(candies.length);
      }
    }
  }

  Future<void> _resolve() async {
    while (_clearMatches(true)) {
      await Future.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      setState(() {});
    }
    if (!_hasValidMove(board)) {
      _newBoard();
      setState(() {});
      tipSnackBar(context, '没有可走的了，重新洗牌 🎲');
    }
  }

  void _onTap(int r, int c) {
    if (_busy) return;
    if (selected == null) {
      setState(() => selected = (r, c));
      return;
    }
    final (sr, sc) = selected!;
    setState(() => selected = null);
    final adjacent = (sr == r && (sc - c).abs() == 1) || (sc == c && (sr - r).abs() == 1);
    if (!adjacent) {
      setState(() => selected = (r, c));
      return;
    }
    _swap(board, sr, sc, r, c);
    if (_findAllMatches(board).isEmpty) {
      _swap(board, sr, sc, r, c); // 无效交换换回来
      setState(() {});
      return;
    }
    _busy = true;
    setState(() {});
    _resolve().then((_) {
      if (!mounted) return;
      setState(() => _busy = false);
      context.read<AppStore>().setGameScore('match', score);
    });
  }

  @override
  Widget build(BuildContext context) {
    final best = context.watch<AppStore>().gameBest('match');
    final cell = MediaQuery.of(context).size.width * 0.22;

    return ModuleScaffold(
      title: '🍬 消消乐',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          children: [
            SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('当前得分', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                        Text('$score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.line),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('最高分', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                        Text('$best', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.income)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                onTapUp: (d) {
                  final p = d.localPosition;
                  final g = p.dx / cell;
                  if (g >= n) return;
                  final r = (p.dy / cell).floor().clamp(0, n - 1);
                  final c = (p.dx / cell).floor().clamp(0, n - 1);
                  _onTap(r, c);
                },
                child: Container(
                  width: cell * n,
                  height: cell * n,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                  child: CustomPaint(painter: _BoardPainter(board: board, selected: selected, cell: cell)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('点两个相邻的糖果交换，三个以上相同连成一条就能消除', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final List<List<int>> board;
  final (int, int)? selected;
  final double cell;

  _BoardPainter({required this.board, required this.selected, required this.cell});

  @override
  void paint(Canvas canvas, Size size) {
    for (var r = 0; r < _MatchGameState.n; r++) {
      for (var c = 0; c < _MatchGameState.n; c++) {
        final v = board[r][c];
        final rect = Rect.fromLTWH(c * cell + 2, r * cell + 2, cell - 4, cell - 4);
        final on = selected != null && selected!.$1 == r && selected!.$2 == c;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * .22)),
          Paint()
            ..color = v >= 0 ? _MatchGameState.candyColors[v % _MatchGameState.candyColors.length].withOpacity(on ? 1 : .82)
            : AppColors.bg,
        );
        if (v >= 0) {
          final tp = TextPainter(
            text: TextSpan(text: _MatchGameState.candies[v % _MatchGameState.candies.length], style: TextStyle(fontSize: cell * .52)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
        }
        if (on) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(cell * .22)),
            Paint()
              ..color = Colors.transparent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
