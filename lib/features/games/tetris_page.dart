import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// 俄罗斯方块（新增功能 6 之二）
class TetrisPage extends StatefulWidget {
  const TetrisPage({super.key});

  @override
  State<TetrisPage> createState() => _TetrisState();
}

class _TetrisState extends State<TetrisPage> {
  static const cols = 10;
  static const rows = 20;
  static const colors = <Color>[
    Color(0xFF5BC0EB), // I
    Color(0xFFF7D154), // O
    Color(0xFF9B7EDB), // T
    Color(0xFF6FC7A6), // S
    Color(0xFFE96A6A), // Z
    Color(0xFF5A9BF5), // J
    Color(0xFFF79E75), // L
  ];
  static const baseShapes = <List<List<int>>>[
    [[1, 1, 1, 1]],
    [[1, 1], [1, 1]],
    [[0, 1, 0], [1, 1, 1]],
    [[0, 1, 1], [1, 1, 0]],
    [[1, 1, 0], [0, 1, 1]],
    [[1, 0, 0], [1, 1, 1]],
    [[0, 0, 1], [1, 1, 1]],
  ];

  late List<List<int?>> board;
  late int type; // 当前块类型
  late List<List<int>> shape; // 当前旋转态
  late int px, py;
  int score = 0;
  int lines = 0;
  int level = 1;
  bool _over = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newGame() {
    board = List.generate(rows, (_) => List<int?>.filled(cols, null));
    score = 0;
    lines = 0;
    level = 1;
    _over = false;
    _spawn();
    _startTick();
  }

  void _startTick() {
    _timer?.cancel();
    final interval = math.max(150, 800 - (level - 1) * 100);
    _timer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (_over) return;
      _stepDown();
    });
  }

  List<List<int>> _rotate(List<List<int>> m) {
    final h = m.length, w = m[0].length;
    return List.generate(w, (i) => List.generate(h, (j) => m[h - 1 - j][i]));
  }

  bool _collide(List<List<int>> s, int x, int y) {
    for (var r = 0; r < s.length; r++) {
      for (var c = 0; c < s[r].length; c++) {
        if (s[r][c] == 0) continue;
        final rr = y + r, cc = x + c;
        if (cc < 0 || cc >= cols || rr >= rows) return true;
        if (rr >= 0 && board[rr][cc] != null) return true;
      }
    }
    return false;
  }

  void _spawn() {
    type = math.Random().nextInt(baseShapes.length);
    shape = baseShapes[type].map((row) => List<int>.from(row)).toList();
    px = (cols - shape[0].length) ~/ 2;
    py = -1;
    if (_collide(shape, px, py)) {
      _over = true;
      _timer?.cancel();
      context.read<AppStore>().setGameScore('tetris', score);
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
    }
  }

  void _showGameOver() {
    final best = context.read<AppStore>().gameBest('tetris');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('游戏结束', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('本局得分：$score\n最高分：$best', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('再玩一局', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700))),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(_newGame);
      }
    });
  }

  void _stepDown() {
    if (_over) return;
    if (!_collide(shape, px, py + 1)) {
      setState(() => py++);
      return;
    }
    _lock();
  }

  void _lock() {
    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final rr = py + r, cc = px + c;
        if (rr < 0) {
          _over = true;
          _timer?.cancel();
          context.read<AppStore>().setGameScore('tetris', score);
          WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
          return;
        }
        board[rr][cc] = type;
      }
    }
    _clearLines();
    _spawn();
    if (!_over) _startTick();
  }

  void _clearLines() {
    var cleared = 0;
    for (var r = rows - 1; r >= 0; r--) {
      if (board[r].every((c) => c != null)) {
        board.removeAt(r);
        board.insert(0, List<int?>.filled(cols, null));
        cleared++;
        r++;
      }
    }
    if (cleared > 0) {
      final pts = [0, 100, 300, 500, 800][cleared] * level;
      score += pts;
      lines += cleared;
      level = lines ~/ 10 + 1;
    }
  }

  void _move(int dx) {
    if (_over) return;
    if (!_collide(shape, px + dx, py)) setState(() => px += dx);
  }

  void _rotatePiece() {
    if (_over) return;
    final next = _rotate(shape);
    for (final kick in [0, -1, 1, -2, 2]) {
      if (!_collide(next, px + kick, py)) {
        setState(() {
          shape = next;
          px += kick;
        });
        return;
      }
    }
  }

  void _softDrop() {
    if (_over) return;
    if (!_collide(shape, px, py + 1)) {
      setState(() {
        py++;
        score += 1;
      });
      return;
    }
    _lock();
  }

  void _hardDrop() {
    if (_over) return;
    while (!_collide(shape, px, py + 1)) {
      py++;
      score += 2;
    }
    _lock();
  }

  @override
  Widget build(BuildContext context) {
    final best = context.watch<AppStore>().gameBest('tetris');
    final screenW = MediaQuery.of(context).size.width;
    final cell = (screenW - 28 - 20) / cols;

    return ModuleScaffold(
      title: '🧱 俄罗斯方块',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          children: [
            SectionCard(
              child: Row(
                children: [
                  Expanded(child: _Info(label: '得分', num: '$score')),
                  Container(width: 1, height: 30, color: AppColors.line),
                  Expanded(child: _Info(label: '行数', num: '$lines')),
                  Container(width: 1, height: 30, color: AppColors.line),
                  Expanded(child: _Info(label: '等级', num: '$level')),
                  Container(width: 1, height: 30, color: AppColors.line),
                  Expanded(child: _Info(label: '最高分', num: '$best', color: AppColors.income)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: cell * cols,
                height: cell * rows,
                decoration: BoxDecoration(color: const Color(0xFF2F2A33), borderRadius: BorderRadius.circular(14), boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 14, offset: const Offset(0, 6)),
                ]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomPaint(painter: _TetrisPainter(board: board, shape: shape, px: px, py: py, cell: cell, activeColor: colors[type % colors.length])),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CtrlBtn(icon: Icons.keyboard_arrow_left_rounded, onTap: () => _move(-1)),
                const SizedBox(width: 12),
                _CtrlBtn(icon: Icons.keyboard_arrow_down_rounded, onTap: _softDrop),
                const SizedBox(width: 12),
                _CtrlBtn(icon: Icons.keyboard_arrow_right_rounded, onTap: () => _move(1)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CtrlBtn(icon: Icons.rotate_90_degrees_cw_rounded, onTap: _rotatePiece),
                const SizedBox(width: 12),
                _CtrlBtn(icon: Icons.vertical_align_bottom_rounded, onTap: _hardDrop, label: '直落'),
              ],
            ),
            const SizedBox(height: 10),
            Text('消满一行 +${100 * level} 分 · 每消 10 行升一级，下落加快', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String num;
  final Color? color;

  const _Info({required this.label, required this.num, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return Column(
      children: [
        Text(num, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
      ],
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  const _CtrlBtn({required this.icon, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
        child: label != null
            ? Text(label!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: pal.primary))
            : Icon(icon, size: 26, color: pal.primary),
      ),
    );
  }
}

class _TetrisPainter extends CustomPainter {
  final List<List<int?>> board;
  final List<List<int>> shape;
  final int px, py;
  final double cell;
  final Color activeColor;

  _TetrisPainter({required this.board, required this.shape, required this.px, required this.py, required this.cell, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (var r = 0; r < _TetrisState.rows; r++) {
      for (var c = 0; c < _TetrisState.cols; c++) {
        final v = board[r][c];
        if (v == null) continue;
        _drawCell(canvas, c, r, _TetrisState.colors[v % _TetrisState.colors.length]);
      }
    }
    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final rr = py + r, cc = px + c;
        if (rr < 0) continue;
        _drawCell(canvas, cc, rr, activeColor);
      }
    }
  }

  void _drawCell(Canvas canvas, int c, int r, Color color) {
    final rect = Rect.fromLTWH(c * cell + 1.2, r * cell + 1.2, cell - 2.4, cell - 2.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * .16)),
      Paint()..color = color,
    );
    final light = Paint()
      ..color = Colors.white.withOpacity(.22)
      ..strokeWidth = 1.6;
    canvas.drawLine(rect.topLeft.translate(1, 1), rect.topRight.translate(-1, 1), light);
  }

  @override
  bool shouldRepaint(covariant _TetrisPainter old) => true;
}
