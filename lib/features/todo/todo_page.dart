import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 优先级三档：0 高 / 1 中 / 2 低
const _prioLabels = ['🌸 高', '🌷 中', '🤍 低'];
const _prioDots = [Color(0xFFE8798F), Color(0xFFD98FB0), Color(0xFFC9C2C6)];

/// 待办事项（PRD 3.3）
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _input = TextEditingController();
  final _shakeKey = GlobalKey<ShakerState>();
  String _dateChoice = 'today';
  DateTime? _customDate;
  int _priority = 1;
  bool _showAllDone = false;

  String get _selectedDateKey {
    switch (_dateChoice) {
      case 'tomorrow':
        return dateKey(addDays(today(), 1));
      case 'after':
        return dateKey(addDays(today(), 2));
      case 'custom':
        return _customDate != null ? dateKey(_customDate!) : dateKey(today());
      default:
        return dateKey(today());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: today(),
      firstDate: today(),
      lastDate: today().add(const Duration(days: 365)),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) {
      setState(() {
        _customDate = picked;
        _dateChoice = 'custom';
      });
    }
  }

  void _add() {
    final store = context.read<AppStore>();
    final err = store.addTodo(_input.text, _selectedDateKey, _priority);
    if (err != null) {
      _shakeKey.currentState?.shake();
      tipSnackBar(context, err);
      return;
    }
    _input.clear();
    setState(() => _dateChoice = 'today');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final undone = store.todayUndoneTodos;
    final future = store.futureTodos;
    final done = store.doneTodos;

    final customLabel = _customDate == null ? '选日期' : fmtMD(_customDate!);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader('📋 待办事项', '${greetingOf(DateTime.now().hour)}，${store.profile.name.isEmpty ? '加油' : store.profile.name}～'),

            // 添加卡
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CardTitle('✨ 添加待办'),
                  Shaker(
                    key: _shakeKey,
                    child: AppInput('要做什么呢？', _input, maxLength: 50, autofocus: false),
                  ),
                  const FieldLabel('日期'),
                  PillGroup<String>(
                    current: _dateChoice,
                    onChanged: (v) => setState(() {
                      _dateChoice = v;
                      if (v != 'custom') _customDate = null;
                    }),
                    options: [
                      (value: 'today', label: '今天'),
                      (value: 'tomorrow', label: '明天'),
                      (value: 'after', label: '后天'),
                      (value: 'custom', label: customLabel),
                    ],
                  ),
                  if (_dateChoice == 'custom')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AppButton('选一个日期 📅', ghost: true, small: true, onTap: _pickCustomDate),
                    ),
                  const FieldLabel('优先级'),
                  PillGroup<int>(
                    current: _priority,
                    onChanged: (v) => setState(() => _priority = v),
                    options: [
                      (value: 0, label: _prioLabels[0]),
                      (value: 1, label: _prioLabels[1]),
                      (value: 2, label: _prioLabels[2]),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(child: AppButton('＋ 添加待办', onTap: _add)),
                ],
              ),
            ),

            // 今日待办
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle('☀️ 今日待办（${undone.length}）'),
                  if (undone.isEmpty)
                    const EmptyState('🌈', '今天没有待办，享受美好的一天吧！'),
                  for (final t in undone) _TodoRow(todo: t),
                  if (future.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const CardTitle('🌙 往后的日子'),
                    for (final t in future) _TodoRow(todo: t, showDate: true),
                  ],
                ],
              ),
            ),

            // 已完成
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle('✅ 已完成（${done.length}）'),
                  if (done.isEmpty)
                    const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('还没有完成的待办', style: TextStyle(fontSize: 11.5, color: AppColors.muted))),
                  for (final t in (done.length > 3 && !_showAllDone ? done.sublist(0, 3) : done)) _TodoRow(todo: t),
                  if (done.length > 3)
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _showAllDone = !_showAllDone),
                        child: Text(_showAllDone ? '收起' : '展开全部（${done.length}）', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
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
}

class _TodoRow extends StatelessWidget {
  final Todo todo;
  final bool showDate;

  const _TodoRow({required this.todo, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // 圆形勾选
          GestureDetector(
            onTap: () => store.toggleTodo(todo),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: todo.done ? pal.gradient : null,
                color: todo.done ? null : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: todo.done ? pal.gradEnd : AppColors.line, width: 1.6),
              ),
              child: todo.done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 10),
          // 优先级点 + 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: todo.done ? AppColors.muted : AppColors.ink,
                    decoration: todo.done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: _prioDots[todo.priority.clamp(0, 2)], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${['高', '中', '低'][todo.priority.clamp(0, 2)]}优先',
                      style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                    if (showDate) ...[
                      const SizedBox(width: 8),
                      Text(fmtMD(parseDate(todo.date)), style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
                    ],
                    if (todo.overdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(5)),
                        child: const Text('已过期', style: TextStyle(fontSize: 9, color: AppColors.danger, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // 删除
          GestureDetector(
            onTap: () {
              store.deleteTodo(todo);
              undoSnackBar(context, '已删除待办', () => store.restoreTodo(todo));
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('×', style: TextStyle(fontSize: 17, color: AppColors.muted)),
            ),
          ),
        ],
      ),
    );
  }
}
