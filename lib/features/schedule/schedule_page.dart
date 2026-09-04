import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/seed.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 我的课表（PRD 3.5）
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _todayView = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader('📚 我的课表', '好好学习，天天向上'),

            if (!store.term.isSet) ...[
              // 未设置学期：引导卡
              SectionCard(
                child: Column(
                  children: [
                    const Text('🎒', style: TextStyle(fontSize: 34)),
                    const SizedBox(height: 8),
                    const Text('先告诉我什么时候开学吧', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    const Text('设置开学日期后，这里会变成你的周课表', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 12),
                    AppButton('去设置学期 📅', small: true, onTap: () => store.goToTab(7)),
                  ],
                ),
              ),
            ] else ...[
              // 工具行
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(gradient: pal.gradient, borderRadius: BorderRadius.circular(999)),
                    child: Text(store.weekNoLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _todayView = !_todayView),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: pal.softBg, borderRadius: BorderRadius.circular(999), border: Border.all(color: pal.softBorder)),
                      child: Text(_todayView ? '← 周视图' : '今日视图 →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: pal.primary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SectionCard(
                padding: const EdgeInsets.all(10),
                child: _todayView ? _buildTodayView(store) : _buildWeekGrid(store),
              ),

              // 添加课程
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AppButton('＋ 添加课程', ghost: true, small: true, onTap: () => _openCourseSheet(context, null)),
                ),
              ),
              const SizedBox(height: 12),

              // 节次时间条
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(color: pal.softBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: pal.softBorder)),
                child: Text(
                  [
                    for (var i = 0; i < termNodeCount; i++)
                      if (i < store.term.nodeTimes.length) '第 ${i + 1} 节 ${store.term.nodeTimes[i]}'
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.sub, height: 1.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const termNodeCount = 5;

  // ---------------- 周视图 ----------------

  Widget _buildWeekGrid(AppStore store) {
    final week = store.currentWeekNo;
    final pal = store.palette;
    final todayWd = today().weekday;

    // (weekday, node) -> 课程
    final cellCourse = <String, Course>{};
    if (week >= 1) {
      for (final c in store.courses) {
        if (!c.coversWeek(week)) continue;
        for (final wd in c.weekdays) {
          for (var n = c.startNode; n <= c.endNode; n++) {
            cellCourse['$wd-$n'] = c;
          }
        }
      }
    }

    final conflictedIds = <String>{};
    for (final c in store.courses) {
      if (store.conflictsFor(c).isNotEmpty) conflictedIds.add(c.id);
    }

    return Column(
      children: [
        // 表头
        Row(
          children: [
            const SizedBox(width: 22),
            for (var wd = 1; wd <= 7; wd++)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(color: wd == todayWd ? pal.softBg : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    weekCn(wd),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: wd == todayWd ? FontWeight.w800 : FontWeight.w600,
                      color: wd == todayWd ? pal.primary : AppColors.sub,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        // 5 行节次
        for (var node = 1; node <= termNodeCount; node++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 22,
                child: Center(child: Text('$node', style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700))),
              ),
              for (var wd = 1; wd <= 7; wd++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final c = cellCourse['$wd-$node'];
                      if (c != null) {
                        _openCourseDetail(c);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: wd == todayWd ? pal.softBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _courseCell(cellCourse['$wd-$node'], node, conflictedIds),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _courseCell(Course? c, int node, Set<String> conflictedIds) {
    if (c == null) return const SizedBox(height: 40);
    final isStart = node == c.startNode;
    final colors = coursePalette[c.colorIndex % coursePalette.length].map(Color.new).toList();
    final textColor = coursePaletteText[c.colorIndex % coursePaletteText.length];
    final conflicted = conflictedIds.contains(c.id);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        borderRadius: BorderRadius.vertical(
          top: isStart ? const Radius.circular(9) : Radius.zero,
          bottom: node == c.endNode ? const Radius.circular(9) : Radius.zero,
        ),
        border: conflicted ? Border.all(color: AppColors.danger, width: 1.5) : null,
      ),
      child: isStart
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(textColor)),
                ),
                if (c.place.isNotEmpty && c.startNode != c.endNode)
                  Text(c.place, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: Color(textColor).withOpacity(.8))),
              ],
            )
          : null,
    );
  }

  // ---------------- 今日视图 ----------------

  Widget _buildTodayView(AppStore store) {
    final pal = store.palette;
    final list = store.todayCourses;
    if (list.isEmpty) {
      return const EmptyState('🌤', '今天没有课，自由时光！');
    }
    return Column(
      children: [
        for (final c in list)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: GestureDetector(
              onTap: () => _openCourseDetail(c),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: coursePalette[c.colorIndex % coursePalette.length].map(Color.new).toList()),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(.75), borderRadius: BorderRadius.circular(8)),
                      child: Text('第 ${c.startNode}${c.endNode > c.startNode ? '-${c.endNode}' : ''} 节', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                          if (c.place.isNotEmpty)
                            Text('${c.place}${c.teacher.isNotEmpty ? ' · ${c.teacher}老师' : ''}', style: const TextStyle(fontSize: 10, color: AppColors.sub)),
                        ],
                      ),
                    ),
                    _todayStatus(store, c, pal),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _todayStatus(AppStore store, Course c, AppPalette pal) {
    final nodeTimes = store.term.nodeTimes;
    final startT = parseTimeOfDay(nodeTimes[(c.startNode - 1).clamp(0, nodeTimes.length - 1)]);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, startT.hour, startT.minute);
    final end = start.add(const Duration(minutes: 90));

    if (now.isBefore(start)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: pal.softBorder)),
        child: Text('未开始', style: TextStyle(fontSize: 9.5, color: pal.primary, fontWeight: FontWeight.w700)),
      );
    }
    if (now.isAfter(end)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(999)),
        child: const Text('已结束', style: TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(gradient: pal.gradient, borderRadius: BorderRadius.circular(999)),
      child: const Text('进行中', style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }

  // ---------------- 详情 / 编辑 ----------------

  void _openCourseDetail(Course c) {
    final store = context.read<AppStore>();
    final parityText = ['每周', '单周', '双周'][c.parity];
    final wdText = c.weekdays.map(weekCn).map((s) => '周$s').join('、');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SheetWrap('📚 ${c.name}', Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('⏰', '$wdText · 第 ${c.startNode}${c.endNode > c.startNode ? '-${c.endNode}' : ''} 节'),
              _detailRow('📅', '第 ${c.weekStart}-${c.weekEnd} 周 · $parityText'),
              if (c.place.isNotEmpty) _detailRow('📍', c.place),
              if (c.teacher.isNotEmpty) _detailRow('👩‍🏫', '${c.teacher}老师'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: AppButton('分享给 TA 💬', ghost: true, small: true, onTap: () {
                    Navigator.pop(ctx);
                    shareCardToChat(context, 'course', {'name': c.name, 'place': c.place, 'weekday': wdText, 'nodes': '第 ${c.startNode}-${c.endNode} 节'});
                  })),
                  const SizedBox(width: 10),
                  Expanded(child: AppButton('编辑 ✏️', ghost: true, small: true, onTap: () {
                    Navigator.pop(ctx);
                    _openCourseSheet(context, c);
                  })),
                  const SizedBox(width: 10),
                  Expanded(child: AppButton('删除 🗑', small: true, onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await confirmDialog(context, '删除课程', '《${c.name}》会被移出课表，确定吗？');
                    if (ok) store.deleteCourse(c);
                  })),
                ],
              ),
            ],
          )),
    );
  }

  Widget _detailRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _openCourseSheet(BuildContext context, Course? editing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CourseSheet(editing: editing),
    );
  }
}

// ---------------- 添加 / 编辑课程表单 ----------------

class _CourseSheet extends StatefulWidget {
  final Course? editing;

  const _CourseSheet({this.editing});

  @override
  State<_CourseSheet> createState() => _CourseSheetState();
}

class _CourseSheetState extends State<_CourseSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _place = TextEditingController(text: widget.editing?.place ?? '');
  late final TextEditingController _teacher = TextEditingController(text: widget.editing?.teacher ?? '');
  late final Set<int> _weekdays = {...?widget.editing?.weekdays};
  late int _startNode = widget.editing?.startNode ?? 1;
  late int _endNode = widget.editing?.endNode ?? 1;
  late int _weekStart = widget.editing?.weekStart ?? 1;
  late int _weekEnd = widget.editing?.weekEnd ?? 20;
  late int _parity = widget.editing?.parity ?? 0;

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    _teacher.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<AppStore>();
    final name = _name.text.trim();
    if (name.isEmpty) {
      tipSnackBar(context, '课名还没有填哦');
      return;
    }
    if (_weekdays.isEmpty) {
      tipSnackBar(context, '选一下哪几天上课');
      return;
    }
    if (_endNode < _startNode) _endNode = _startNode;
    if (_weekEnd < _weekStart) _weekEnd = _weekStart;

    final candidate = Course(
      id: widget.editing?.id ?? id(),
      name: name,
      weekdays: _weekdays.toList()..sort(),
      startNode: _startNode,
      endNode: _endNode,
      weekStart: _weekStart,
      weekEnd: _weekEnd,
      parity: _parity,
      place: _place.text.trim(),
      teacher: _teacher.text.trim(),
      colorIndex: widget.editing?.colorIndex ?? 0,
    );

    final conflicts = store.conflictsFor(candidate);
    if (conflicts.isNotEmpty) {
      final ok = await confirmDialog(
        context,
        '时间有冲突',
        '这个时间已经有《${conflicts.first.name}》了，还要保存吗？（冲突课程会加红边标记）',
        okText: '仍要保存',
      );
      if (!ok) return;
    }

    if (widget.editing == null) {
      store.addCourse(candidate);
    } else {
      store.updateCourse(candidate);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final totalWeeks = store.term.isSet ? store.term.totalWeeks : 20;

    return SheetWrap(widget.editing == null ? '＋ 添加课程' : '编辑课程', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('课名（必填）'),
        AppInput('如：高等数学', _name, maxLength: 10),
        const FieldLabel('上课星期（可多选）'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var wd = 1; wd <= 7; wd++)
              GestureDetector(
                onTap: () => setState(() {
                  if (_weekdays.contains(wd)) {
                    _weekdays.remove(wd);
                  } else {
                    _weekdays.add(wd);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: _weekdays.contains(wd) ? pal.gradient : null,
                    color: _weekdays.contains(wd) ? null : AppColors.bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _weekdays.contains(wd) ? pal.gradEnd : AppColors.line),
                  ),
                  child: Text('周${weekCn(wd)}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _weekdays.contains(wd) ? Colors.white : AppColors.sub)),
                ),
              ),
          ],
        ),
        const FieldLabel('节次'),
        Row(
          children: [
            Expanded(child: _NodePicker(label: '开始', value: _startNode, max: 5, onChanged: (v) => setState(() => _startNode = v))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('至', style: TextStyle(fontSize: 12, color: AppColors.muted))),
            Expanded(child: _NodePicker(label: '结束', value: _endNode, max: 5, onChanged: (v) => setState(() => _endNode = v))),
          ],
        ),
        const FieldLabel('周次范围'),
        Row(
          children: [
            Expanded(child: _NodePicker(label: '开始周', value: _weekStart, max: totalWeeks, onChanged: (v) => setState(() => _weekStart = v))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('至', style: TextStyle(fontSize: 12, color: AppColors.muted))),
            Expanded(child: _NodePicker(label: '结束周', value: _weekEnd, max: totalWeeks, onChanged: (v) => setState(() => _weekEnd = v))),
          ],
        ),
        const FieldLabel('单双周'),
        PillGroup<int>(
          current: _parity,
          onChanged: (v) => setState(() => _parity = v),
          options: const [
            (value: 0, label: '每周'),
            (value: 1, label: '单周'),
            (value: 2, label: '双周'),
          ],
        ),
        const FieldLabel('地点（可选）'),
        AppInput('如：教一 201', _place, maxLength: 15),
        const FieldLabel('老师（可选）'),
        AppInput('如：王老师', _teacher, maxLength: 10),
        const SizedBox(height: 16),
        Center(child: AppButton(widget.editing == null ? '＋ 保存课程' : '保存修改', onTap: _save)),
        const SizedBox(height: 8),
      ],
    ));
  }
}

class _NodePicker extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _NodePicker({required this.label, required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final v = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (var i = 1; i <= max; i++)
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, i),
                    child: Container(
                      width: 48,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == value ? const Color(0xFFFFE4EC) : AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: i == value ? const Color(0xFFE8798F) : AppColors.line),
                      ),
                      child: Text('$i', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: i == value ? const Color(0xFFE8798F) : AppColors.ink)),
                    ),
                  ),
              ],
            ),
          ),
        );
        if (v != null) onChanged(v);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            Text('$value', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
