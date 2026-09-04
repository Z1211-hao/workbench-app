import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/seed.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 记账本（PRD 3.4）
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _shakeKey = GlobalKey<ShakerState>();
  String _type = 'out';
  String _category = 'food';
  DateTime _date = today();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onTypeChange(String v) {
    setState(() {
      _type = v;
      _category = categoriesOf(v).first.key;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today()) ? today() : _date,
      firstDate: DateTime(2020),
      lastDate: today(),
      helpText: '选择日期（不能选未来）',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) setState(() => _date = dayStart(picked));
  }

  void _add() {
    final store = context.read<AppStore>();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final err = store.addBill(_type, amount, _category, dateKey(_date), _noteCtrl.text);
    if (err != null) {
      _shakeKey.currentState?.shake();
      tipSnackBar(context, err);
      return;
    }
    _amountCtrl.clear();
    _noteCtrl.clear();
    tipSnackBar(context, '记好啦 ✅');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final month = store.viewMonth;
    final income = store.monthIncome;
    final expense = store.monthExpense;
    final balance = store.monthBalance;
    final monthBills = store.billsOfViewMonth;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader('💰 记账本', '理性消费，快乐生活'),

            // 概览三卡
            Row(
              children: [
                _SumCard(label: '本月收入', value: '+${fmtAmount(income)}', color: AppColors.income),
                const SizedBox(width: 8),
                _SumCard(label: '本月支出', value: '-${fmtAmount(expense)}', color: pal.primary),
                const SizedBox(width: 8),
                _SumCard(label: '结余', value: fmtAmount(balance), color: balance < 0 ? pal.primary : const Color(0xFF8E7CC3)),
              ],
            ),
            const SizedBox(height: 12),

            // 记一笔
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle(
                    '✨ 记一笔',
                    trailing: Text('${month.month}月账单', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                  ),
                  PillGroup<String>(
                    current: _type,
                    onChanged: _onTypeChange,
                    options: const [
                      (value: 'out', label: '支出'),
                      (value: 'in', label: '收入'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('金额（元）'),
                            Shaker(
                              key: _shakeKey,
                              child: AppInput('0.00', _amountCtrl, keyboard: const TextInputType.numberWithOptions(decimal: true)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('日期'),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Row(
                                  children: [
                                    Text(fmtMD(_date), style: const TextStyle(fontSize: 13.5, color: AppColors.ink, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    const Text('📅', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const FieldLabel('分类'),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.9,
                    children: [
                      for (final c in categoriesOf(_type))
                        _CatTile(
                          cat: c,
                          selected: _category == c.key,
                          onTap: () => setState(() => _category = c.key),
                        ),
                    ],
                  ),
                  const FieldLabel('备注（可选）'),
                  AppInput('写点什么...', _noteCtrl, maxLength: 30),
                  const SizedBox(height: 14),
                  Center(child: AppButton('＋ 记一笔', onTap: _add)),
                ],
              ),
            ),

            // 账单明细
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle(
                    '📝 账单明细',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(onTap: () => store.shiftMonth(-1), child: const Text('‹ ', style: TextStyle(fontSize: 18, color: AppColors.muted))),
                        Text('${month.year == today().year ? '' : '${month.year}年'}${month.month}月', style: const TextStyle(fontSize: 11.5, color: AppColors.sub, fontWeight: FontWeight.w700)),
                        GestureDetector(onTap: () => store.shiftMonth(1), child: const Text(' ›', style: TextStyle(fontSize: 18, color: AppColors.muted))),
                      ],
                    ),
                  ),
                  if (monthBills.isEmpty)
                    const EmptyState('💸', '还没有账单，记一笔吧～'),
                  for (final b in monthBills) _BillRow(bill: b),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SumCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.18)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.sub)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _CatTile extends StatelessWidget {
  final BillCategory cat;
  final bool selected;
  final VoidCallback onTap;

  const _CatTile({required this.cat, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: selected ? pal.gradient : null,
          color: selected ? null : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? pal.gradEnd : AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(cat.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 2),
            Text(cat.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.sub)),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final Bill bill;

  const _BillRow({required this.bill});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final cat = categoryByKey(bill.category);
    final isIn = bill.type == 'in';
    final d = parseDate(bill.date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: (isIn ? AppColors.income : pal.primary).withOpacity(.1), borderRadius: BorderRadius.circular(11)),
            child: Text(cat.emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.note.isNotEmpty ? bill.note : cat.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 1),
                Text('${d.month}月${d.day}日 · ${cat.name}', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
              ],
            ),
          ),
          Text(
            '${isIn ? '+' : '-'}${fmtAmount(bill.amount)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isIn ? AppColors.income : pal.primary),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              store.deleteBill(bill);
              undoSnackBar(context, '已删除该笔账单', () => store.restoreBill(bill));
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('×', style: TextStyle(fontSize: 16, color: AppColors.muted)),
            ),
          ),
        ],
      ),
    );
  }
}
