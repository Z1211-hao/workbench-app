import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 身高体重记录（新增功能 1）
class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _HealthSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final list = store.sortedHealthRecords;
    final latest = list.isNotEmpty ? list.first : null;
    final height = latest?.heightCm ?? store.lastHeight;
    final bmi = latest?.bmi;

    return ModuleScaffold(
      title: '📏 身高体重',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日概览卡
            SectionCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatBlock(num: latest != null ? _trim(latest.weightKg) : '—', unit: 'kg', label: '最新体重', color: pal.primary),
                  _Divider(),
                  _StatBlock(num: height != null ? '${_trim(height)}' : '—', unit: 'cm', label: '身高', color: pal.primary),
                  _Divider(),
                  _StatBlock(
                    num: bmi != null ? '$bmi' : '—',
                    unit: bmiLabel(bmi),
                    label: 'BMI',
                    color: bmiColor(bmi),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 体重趋势
            if (list.length >= 2) ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardTitle('📈 体重趋势（最近 10 次）'),
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: _WeightChart(records: list.take(10).toList().reversed.toList()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],

            // 记录列表
            if (list.isEmpty)
              const EmptyState('📏', '还没有记录，点右上角「记一笔」吧')
            else
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardTitle('🗒️ 历史记录'),
                    for (final r in list) _RecordRow(record: r),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingAction: AppButton('记一笔', onTap: _openAddSheet),
    );
  }
}

String _trim(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

String bmiLabel(double? bmi) {
  if (bmi == null) return '';
  if (bmi < 18.5) return '偏瘦';
  if (bmi < 24) return '标准';
  if (bmi < 28) return '偏胖';
  return '偏胖';
}

Color bmiColor(double? bmi) {
  if (bmi == null) return AppColors.muted;
  if (bmi < 18.5 || bmi >= 28) return AppColors.danger;
  if (bmi < 24) return AppColors.income;
  return const Color(0xFFE8A33D);
}

class _StatBlock extends StatelessWidget {
  final String num;
  final String unit;
  final String label;
  final Color color;

  const _StatBlock({required this.num, required this.unit, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              text: num,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
              children: [TextSpan(text: ' $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted))],
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 34, color: AppColors.line);
}

class _RecordRow extends StatelessWidget {
  final HealthRecord record;

  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final bmi = record.bmi;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(11)),
            child: const Text('⚖️', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_trim(record.weightKg)} kg', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  record.heightCm != null ? '${fmtCN(parseDate(record.date))} · 身高 ${_trim(record.heightCm!)} cm' : fmtCN(parseDate(record.date)),
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (bmi != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: bmiColor(bmi).withOpacity(.12), borderRadius: BorderRadius.circular(999)),
              child: Text('BMI $bmi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: bmiColor(bmi))),
            ),
          IconButton(
            onPressed: () async {
              if (await confirmDialog(context, '删除这条记录？', '删掉就找不回来啦')) {
                store.deleteHealthRecord(record);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<HealthRecord> records;

  const _WeightChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    final weights = records.map((r) => r.weightKg).toList();
    final min = weights.reduce(math.min);
    final max = weights.reduce(math.max);
    final span = (max - min) < 0.5 ? 0.5 : (max - min);
    return CustomPaint(
      painter: _WeightChartPainter(weights: weights, min: min, span: span, color: pal.primary),
      size: Size.infinite,
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<double> weights;
  final double min;
  final double span;
  final Color color;

  _WeightChartPainter({required this.weights, required this.min, required this.span, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final padL = 6.0, padR = 6.0, padT = 12.0, padB = 6.0;
    final plotW = w - padL - padR, plotH = h - padT - padB;
    if (weights.length < 2) return;

    Offset point(int i) {
      final x = padL + (weights.length == 1 ? plotW / 2 : plotW * i / (weights.length - 1));
      final y = padT + plotH - plotH * (weights[i] - min) / span;
      return Offset(x, y);
    }

    final line = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < weights.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    canvas.drawPath(path, line);

    final fill = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(.18), color.withOpacity(.01)]).createShader(Rect.fromLTWH(0, 0, w, h));
    final fillPath = Path.from(path)
      ..lineTo(point(weights.length - 1).dx, h - padB)
      ..lineTo(point(0).dx, h - padB)
      ..close();
    canvas.drawPath(fillPath, fill);

    final dot = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < weights.length; i++) {
      final p = point(i);
      canvas.drawCircle(p, 3.4, dot);
      canvas.drawCircle(p, 3.4, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) => old.weights != weights || old.color != color;
}

class _HealthSheet extends StatefulWidget {
  const _HealthSheet();

  @override
  State<_HealthSheet> createState() => _HealthSheetState();
}

class _HealthSheetState extends State<_HealthSheet> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _date = dateKey(today());

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: parseDate(_date),
      firstDate: DateTime(2000),
      lastDate: today(),
    );
    if (d != null) setState(() => _date = dateKey(d));
  }

  void _save() {
    final store = context.read<AppStore>();
    final w = double.tryParse(_weightCtrl.text.trim());
    final hTxt = _heightCtrl.text.trim();
    final h = hTxt.isEmpty ? null : double.tryParse(hTxt);
    if (w == null) {
      tipSnackBar(context, '体重还没填对哦');
      return;
    }
    final err = store.addHealthRecord(_date, h, w);
    if (err != null) {
      tipSnackBar(context, err);
      return;
    }
    Navigator.pop(context);
    tipSnackBar(context, '记录好啦 📏');
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SheetWrap(
        '记一笔',
        Column(
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
            FieldLabel('体重（kg，必填）'),
            AppInput('例如 52.5', _weightCtrl, keyboard: const TextInputType.numberWithOptions(decimal: true)),
            FieldLabel('身高（cm，可不填）'),
            AppInput('例如 165', _heightCtrl, keyboard: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: AppButton('保存', onTap: _save)),
          ],
        ),
      ),
    );
  }
}
