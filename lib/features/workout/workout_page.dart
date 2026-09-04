import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 运动打卡（新增功能 5，参考 Keep）
class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  DateTime _viewMonth = DateTime(today().year, today().month);

  void _shiftMonth(int delta) {
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta));
  }

  int _minutesOn(String dateKey) {
    var sum = 0;
    for (final w in context.read<AppStore>().workouts) {
      if (w.date == dateKey) sum += w.minutes;
    }
    return sum;
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _WorkoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final days = store.workoutDaysInMonth(_viewMonth);
    final minutes = store.workoutMinutesInMonth(_viewMonth);
    final calories = store.workoutCaloriesInMonth(_viewMonth);
    final streak = store.workoutStreak;
    final list = store.sortedWorkouts;

    return ModuleScaffold(
      title: '💪 运动打卡',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计卡
            SectionCard(
              child: Row(
                children: [
                  Expanded(child: _Stat(num: '$days', unit: '天', label: '本月运动')),
                  Container(width: 1, height: 34, color: AppColors.line),
                  Expanded(child: _Stat(num: '$minutes', unit: '分钟', label: '本月累计')),
                  Container(width: 1, height: 34, color: AppColors.line),
                  Expanded(child: _Stat(num: '${calories.round()}', unit: '千卡', label: '本月消耗')),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 连续打卡横幅
            SectionCard(
              color: pal.softBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '连续打卡 ',
                        style: const TextStyle(fontSize: 13, color: AppColors.sub),
                        children: [
                          TextSpan(text: '$streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pal.primary)),
                          const TextSpan(text: ' 天', style: TextStyle(fontSize: 13, color: AppColors.sub)),
                          TextSpan(text: streak > 0 ? ' · 今天也要动一动！' : ' · 从今天开始打卡吧', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 月历热力图
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _shiftMonth(-1),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.muted),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${_viewMonth.year}年${_viewMonth.month}月',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _shiftMonth(1),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final w in ['一', '二', '三', '四', '五', '六', '日'])
                        Expanded(
                          child: Text(w, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _MonthGrid(
                    month: _viewMonth,
                    minutesOn: _minutesOn,
                    colorOf: (int minutes) {
                      if (minutes <= 0) return null;
                      if (minutes < 20) return pal.gradStart.withOpacity(.55);
                      if (minutes < 40) return pal.gradStart;
                      return pal.gradEnd;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('少', style: TextStyle(fontSize: 9, color: AppColors.muted)),
                      const SizedBox(width: 4),
                      for (final c in [pal.gradStart.withOpacity(.55), pal.gradStart, pal.gradEnd])
                        Container(width: 10, height: 10, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 4),
                      const Text('多', style: TextStyle(fontSize: 9, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 历史记录
            if (list.isEmpty)
              const EmptyState('💪', '还没有运动记录，点右下角打卡吧')
            else
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardTitle('🗒️ 最近记录'),
                    for (final w in list.take(15)) _WorkoutRow(record: w),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingAction: AppButton('打卡', onTap: _openAddSheet),
    );
  }
}

class _Stat extends StatelessWidget {
  final String num;
  final String unit;
  final String label;

  const _Stat({required this.num, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: num,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: pal.primary),
            children: [TextSpan(text: ' $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted))],
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final int Function(String dateKey) minutesOn;
  final Color? Function(int minutes) colorOf;

  const _MonthGrid({required this.month, required this.minutesOn, required this.colorOf});

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1; // 周一开头
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    final nowKey = dateKey(today());
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final key = dateKey(date);
      final min = minutesOn(key);
      final color = colorOf(min);
      final isFuture = key.compareTo(nowKey) > 0;
      cells.add(
        Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isFuture ? AppColors.bg.withOpacity(.4) : (color ?? AppColors.bg),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: key == nowKey ? const Color(0xFFE8798F) : AppColors.line, width: key == nowKey ? 1.6 : 1),
          ),
          child: Center(
            child: Text(
              '$d',
              style: TextStyle(
                fontSize: 10,
                fontWeight: key == nowKey ? FontWeight.w800 : FontWeight.w500,
                color: isFuture ? AppColors.line : (color != null ? Colors.white : AppColors.sub),
              ),
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  final WorkoutRecord record;

  const _WorkoutRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final type = workoutTypeOf(record.typeKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(11)),
            child: Text(type.emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${type.name} · ${record.minutes} 分钟', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  record.note.isEmpty ? '${fmtCN(parseDate(record.date))} · 约 ${record.calories.round()} 千卡' : '${fmtCN(parseDate(record.date))} · ${record.note}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text('${record.calories.round()} 千卡', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.income)),
          IconButton(
            onPressed: () {
              store.deleteWorkout(record);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSheet extends StatefulWidget {
  const _WorkoutSheet();

  @override
  State<_WorkoutSheet> createState() => _WorkoutSheetState();
}

class _WorkoutSheetState extends State<_WorkoutSheet> {
  String _type = 'run';
  String _date = dateKey(today());
  final _minCtrl = TextEditingController(text: '30');
  final _noteCtrl = TextEditingController();
  int? _previewCal;

  @override
  void initState() {
    super.initState();
    _minCtrl.addListener(_updatePreview);
    _updatePreview();
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final store = context.read<AppStore>();
    final n = int.tryParse(_minCtrl.text.trim()) ?? 0;
    final cal = n > 0 ? store.estimateCalories(_type, n, store.lastHeightWeight).round() : null;
    if (cal != _previewCal && mounted) setState(() => _previewCal = cal);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: parseDate(_date),
      firstDate: DateTime(2020),
      lastDate: today(),
    );
    if (d != null) setState(() => _date = dateKey(d));
  }

  void _save() {
    final store = context.read<AppStore>();
    final n = int.tryParse(_minCtrl.text.trim());
    if (n == null) {
      tipSnackBar(context, '时长还没填对哦');
      return;
    }
    final err = store.addWorkout(_date, _type, n, _noteCtrl.text);
    if (err != null) {
      tipSnackBar(context, err);
      return;
    }
    Navigator.pop(context);
    tipSnackBar(context, '打卡成功，继续坚持！💪');
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SheetWrap(
        '运动打卡',
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel('日期'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                  child: Text(fmtCN(parseDate(_date)), style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
                ),
              ),
              const FieldLabel('运动类型'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in workoutTypes)
                    GestureDetector(
                      onTap: () => setState(() {
                        _type = t.key;
                        _updatePreview();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: _type == t.key ? pal.gradient : null,
                          color: _type == t.key ? null : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _type == t.key ? pal.gradEnd : AppColors.line),
                        ),
                        child: Text('${t.emoji} ${t.name}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _type == t.key ? Colors.white : AppColors.sub)),
                      ),
                    ),
                ],
              ),
              const FieldLabel('时长（分钟）'),
              AppInput('例如 30', _minCtrl, keyboard: const TextInputType.numberWithOptions()),
              const FieldLabel('备注（可不填）'),
              AppInput('例如 慢跑、夜跑', _noteCtrl),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: pal.softBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      _previewCal != null ? '预计消耗约 $_previewCal 千卡（按你最新体重估算）' : '填个时长看看预计消耗',
                      style: TextStyle(fontSize: 11.5, color: pal.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: AppButton('保存打卡', onTap: _save)),
            ],
          ),
        ),
      ),
    );
  }
}
