import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/seed.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 倒数日（PRD 3.6）
class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  final _nameCtrl = TextEditingController();
  final _shakeKey = GlobalKey<ShakerState>();
  DateTime _date = today();
  String _emoji = '⭐';
  String _category = '其他';
  bool _shared = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '目标日期（过去的日子会变成纪念日）',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) setState(() => _date = dayStart(picked));
  }

  Future<void> _pickEmoji() async {
    final e = await pickEmojiSheet(context, countdownEmojis, current: _emoji);
    if (e != null) setState(() => _emoji = e);
  }

  void _add() {
    final store = context.read<AppStore>();
    final err = store.addCountdown(_nameCtrl.text, dateKey(_date), _emoji, _category, shared: _shared);
    if (err != null) {
      _shakeKey.currentState?.shake();
      tipSnackBar(context, err);
      return;
    }
    _nameCtrl.clear();
    setState(() {
      _emoji = '⭐';
      _category = '其他';
      _shared = false;
    });
    tipSnackBar(context, '盼头 +1 ⏳');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final list = store.sortedCountdowns;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader('⏳ 倒数日', '期待每一个重要的日子'),

            // 添加卡
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CardTitle('✨ 添加倒数日'),
                  Shaker(
                    key: _shakeKey,
                    child: AppInput('什么事情值得期待？', _nameCtrl, maxLength: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('目标日期'),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                                child: Row(
                                  children: [
                                    Text(fmtCN(_date), style: const TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    const Text('📅', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('共享给小伙伴'),
                            GestureDetector(
                              onTap: () => setState(() => _shared = !_shared),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: _shared ? pal.gradient : null,
                                  color: _shared ? null : AppColors.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _shared ? pal.gradEnd : AppColors.line),
                                ),
                                child: Text(_shared ? '💕 两人共享' : '仅自己可见', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _shared ? Colors.white : AppColors.sub)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const FieldLabel('分类'),
                  PillGroup<String>(
                    current: _category,
                    onChanged: (v) => setState(() => _category = v),
                    options: [for (final c in countdownCategories) (value: c, label: c)],
                  ),
                  const FieldLabel('挑个图标'),
                  GestureDetector(
                    onTap: _pickEmoji,
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: pal.softBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: pal.softBorder)),
                      child: Text(_emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(child: AppButton('＋ 添加倒数日', onTap: _add)),
                ],
              ),
            ),

            // 列表
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CardTitle('重要的日子'),
                  if (list.isEmpty)
                    const EmptyState('🌱', '快创建一个盼头吧，日子会甜一点'),
                  for (final c in list) _CountdownRow(item: c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  final Countdown item;

  const _CountdownRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final remain = item.remainDays;
    final isToday = remain == 0;
    final isPast = remain < 0;
    final d = parseDate(item.date);

    return GestureDetector(
      onTap: () => _openDetail(context, item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isToday ? pal.gradient : null,
          color: isToday
              ? null
              : item.shared
                  ? const Color(0xFFF8F5FE)
                  : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday
                ? pal.gradEnd
                : item.shared
                    ? const Color(0xFFE2D8F8)
                    : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.white.withOpacity(.25)
                    : item.shared
                        ? const Color(0xFFEFE9FC)
                        : Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 21)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isToday ? Colors.white : isPast ? AppColors.muted : AppColors.ink,
                          ),
                        ),
                      ),
                      if (item.pinned) ...[
                        const SizedBox(width: 5),
                        const Text('📌', style: TextStyle(fontSize: 11)),
                      ],
                      if (item.shared) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(color: isToday ? Colors.white.withOpacity(.25) : const Color(0xFFEFE9FC), borderRadius: BorderRadius.circular(999)),
                          child: Text('我们俩的', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: isToday ? Colors.white : const Color(0xFF7B5FC9))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.year == today().year ? '' : '${d.year}年'}${fmtMD(d)} · ${item.category}',
                    style: TextStyle(fontSize: 10, color: isToday ? Colors.white70 : AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isToday ? '就是今天' : isPast ? '已过' : '还有',
                  style: TextStyle(fontSize: 9.5, color: isToday ? Colors.white70 : AppColors.muted),
                ),
                Text(
                  isToday ? '🎉' : '${isPast ? -remain : remain}',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isToday
                        ? Colors.white
                        : isPast
                            ? AppColors.muted
                            : item.shared
                                ? AppColors.shared
                                : pal.primary,
                  ),
                ),
                Text(isToday ? '啦！' : '天', style: TextStyle(fontSize: 9.5, color: isToday ? Colors.white70 : AppColors.muted)),
              ],
            ),
            const SizedBox(width: 6),
            // 置顶切换
            GestureDetector(
              onTap: () => store.toggleCountdownPin(item),
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(item.pinned ? '📍' : '📌', style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openDetail(BuildContext context, Countdown item) {
  final store = context.read<AppStore>();
  final d = parseDate(item.date);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SheetWrap('${item.emoji} ${item.name}', Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('📅', '${fmtCN(d)}（${weekCn(d.weekday)}）'),
            _row('🏷', item.category),
            _row('🔁', item.repeatYearly ? '每年重复' : '不重复'),
            _row('💕', item.shared ? '两人共享，双方可见可编辑' : '仅自己可见'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton('分享给 TA 💬', ghost: true, small: true, onTap: () {
                    Navigator.pop(ctx);
                    shareCardToChat(context, 'countdown', {'name': item.name, 'emoji': item.emoji, 'date': fmtMD(d), 'remain': item.remainDays});
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton('删除 🗑', small: true, onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await confirmDialog(
                      context,
                      '删除倒数日',
                      item.shared ? '它记得你们的约定哦，确定要删除吗？' : '《${item.name}》会被删除，确定吗？',
                    );
                    if (ok) store.deleteCountdown(item);
                  }),
                ),
              ],
            ),
          ],
        )),
  );
}

Widget _row(String emoji, String text) {
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
