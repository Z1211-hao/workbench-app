import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 番茄钟（新增功能 3）
class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  static const _presets = [
    ('focus', '🍅 专注', 25),
    ('short', '🍵 短休', 5),
    ('long', '🌙 长休', 15),
  ];

  String _mode = 'focus';
  int _totalSeconds = 25 * 60;
  int _remain = 25 * 60;
  bool _running = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _switchMode(String mode, int minutes) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _totalSeconds = minutes * 60;
      _remain = minutes * 60;
      _running = false;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_remain <= 0) {
      _remain = _totalSeconds;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remain--);
      if (_remain <= 0) {
        _timer?.cancel();
        _running = false;
        _onComplete();
      }
    });
  }

  void _onComplete() {
    final store = context.read<AppStore>();
    if (_mode == 'focus') {
      store.addPomodoroDone();
      tipSnackBar(context, '🍅 专注完成！休息一下吧');
    } else {
      tipSnackBar(context, '☕ 休息结束，继续加油！');
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remain = _totalSeconds;
      _running = false;
    });
  }

  void _skip() {
    _timer?.cancel();
    setState(() {
      _remain = 1;
      _running = false;
    });
    _onComplete();
    _reset();
  }

  void _openCustom() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SheetWrap(
          '自定义时长',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('分钟数（1~120）'),
              AppInput('例如 40', ctrl, keyboard: const TextInputType.numberWithOptions()),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton('开始用这个时长', onTap: () {
                  final n = int.tryParse(ctrl.text.trim());
                  if (n == null || n < 1 || n > 120) {
                    tipSnackBar(ctx, '写 1~120 之间的整数哦');
                    return;
                  }
                  _switchMode(_mode, n);
                  Navigator.pop(ctx);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final todayCount = store.pomodoroToday;
    final progress = _totalSeconds == 0 ? 0.0 : _remain / _totalSeconds;

    return ModuleScaffold(
      title: '🍅 番茄钟',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          children: [
            // 模式切换
            SectionCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (key, label, minutes) in _presets)
                    GestureDetector(
                      onTap: () => _switchMode(key, minutes),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: _mode == key ? pal.gradient : null,
                          color: _mode == key ? null : AppColors.bg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _mode == key ? pal.gradEnd : AppColors.line),
                        ),
                        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _mode == key ? Colors.white : AppColors.sub)),
                      ),
                    ),
                  GestureDetector(
                    onTap: _openCustom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.line)),
                      child: const Text('⏱️ 自定义', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sub)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 圆形计时
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Column(
                children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: CustomPaint(
                      painter: _RingPainter(progress: progress, color: _mode == 'focus' ? pal.primary : AppColors.income),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _mode == 'focus' ? '专注中' : '休息中',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_remain ~/ 60).toString().padLeft(2, '0')}:${(_remain % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundBtn(icon: Icons.refresh_rounded, label: '重置', onTap: _reset),
                      const SizedBox(width: 22),
                      GestureDetector(
                        onTap: _toggle,
                        child: Container(
                          width: 74,
                          height: 74,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: pal.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: pal.gradEnd.withOpacity(.4), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 34),
                        ),
                      ),
                      const SizedBox(width: 22),
                      _RoundBtn(icon: Icons.skip_next_rounded, label: '跳过', onTap: _skip),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _mode == 'focus' ? '专注时放下手机，一次只做一件事' : '闭上眼睛，让大脑休息一下',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 今日统计
            SectionCard(
              child: Row(
                children: [
                  Expanded(child: _MiniStat(emoji: '🍅', num: '$todayCount', label: '今日番茄')),
                  Container(width: 1, height: 32, color: AppColors.line),
                  Expanded(child: _MiniStat(emoji: '⏱️', num: '${todayCount * 25}', label: '专注分钟')),
                  Container(width: 1, height: 32, color: AppColors.line),
                  Expanded(
                    child: _MiniStat(
                      emoji: '🔥',
                      num: '${_weekTotal(store)}',
                      label: '本周番茄',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _weekTotal(AppStore store) {
    final start = startOfWeek(today());
    var sum = 0;
    for (var i = 0; i < 7; i++) {
      sum += store.pomodoroLog[dateKey(addDays(start, i))] ?? 0;
    }
    return sum;
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 14) / 2;
    final track = Paint()
      ..color = AppColors.bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (1 - progress),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.color != color;
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)),
            child: Icon(icon, size: 20, color: AppColors.sub),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String num;
  final String label;

  const _MiniStat({required this.emoji, required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(num, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pal.primary)),
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}
