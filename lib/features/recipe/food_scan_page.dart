import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 拍照片识别热量（新增功能 2，置于食谱模块）
class FoodScanPage extends StatefulWidget {
  const FoodScanPage({super.key});

  @override
  State<FoodScanPage> createState() => _FoodScanPageState();
}

class _FoodScanPageState extends State<FoodScanPage> {
  final _picker = ImagePicker();
  bool _busy = false;
  Uint8List? _image;
  Map<String, dynamic>? _result;

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _image = bytes;
        _result = null;
        _busy = true;
      });
      final r = await _recognize(bytes);
      if (!mounted) return;
      setState(() {
        _result = r;
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        tipSnackBar(context, '识别出错啦：$e');
      }
    }
  }

  Future<Map<String, dynamic>> _recognize(Uint8List bytes) async {
    final store = context.read<AppStore>();
    if (store.aiApiKey.isEmpty) {
      // 演示模式：按图片字节和随机数从内置样例里取一个
      await Future.delayed(const Duration(milliseconds: 1000));
      final sum = bytes.fold<int>(0, (s, b) => s + b);
      final idx = (sum + DateTime.now().second) % demoFoods.length;
      final f = demoFoods[idx];
      return {'name': f['name'], 'calories': f['cal'], 'note': f['note']};
    }
    final base64img = base64Encode(bytes);
    final body = jsonEncode({
      'model': store.aiModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': '你是一位营养师。请识别这张食物图片，只输出一个 JSON 对象，不要输出其他任何文字。'
                  '格式：{"name":"食物名称","calories":"估算总热量(整数千卡)","note":"一句份量说明，如 一碗米饭约200克"}。'
                  '如果看不出是什么食物，calories 填 0。',
            },
            {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64img'}},
          ],
        },
      ],
      'temperature': 0.1,
      'max_tokens': 300,
    });
    final resp = await http
        .post(
          Uri.parse('${store.aiBaseUrl}/chat/completions'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${store.aiApiKey}'},
          body: body,
        )
        .timeout(const Duration(seconds: 40));
    if (resp.statusCode != 200) {
      throw Exception('AI 接口返回 ${resp.statusCode}：${resp.body}');
    }
    final j = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final content = ((j['choices'] as List).first as Map)['message']['content'].toString();
    final m = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    if (m == null) throw Exception('AI 没有返回有效结果');
    final parsed = jsonDecode(m.group(0)!) as Map<String, dynamic>;
    return {
      'name': parsed['name']?.toString() ?? '未知食物',
      'calories': int.tryParse('${parsed['calories'] ?? 0}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      'note': parsed['note']?.toString() ?? '',
    };
  }

  void _openAiSettings() {
    final store = context.read<AppStore>();
    final keyCtrl = TextEditingController(text: store.aiApiKey);
    final baseCtrl = TextEditingController(text: store.aiBaseUrl);
    final modelCtrl = TextEditingController(text: store.aiModel);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SheetWrap(
          'AI 识别设置',
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('填上任意 OpenAI 兼容视觉模型接口即可真识别（通义千问/智谱/豆包等都有免费额度）。不填时使用演示识别。', style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5)),
                const FieldLabel('接口地址 Base URL'),
                AppInput('https://dashscope.aliyuncs.com/compatible-mode/v1', baseCtrl),
                const FieldLabel('模型名'),
                AppInput('例如 qwen-vl-plus', modelCtrl),
                const FieldLabel('API Key'),
                AppInput('sk-...', keyCtrl, obscure: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton('保存设置', onTap: () {
                    store.setAiConfig(apiKey: keyCtrl.text, baseUrl: baseCtrl.text, model: modelCtrl.text);
                    Navigator.pop(ctx);
                    tipSnackBar(ctx, store.aiApiKey.isEmpty ? '已切回演示识别模式' : '已保存，下次识别走真实 AI');
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveResult() {
    final r = _result;
    if (r == null) return;
    context.read<AppStore>().addFoodScan(r['name'].toString(), (r['calories'] as num).toInt(), r['note']?.toString() ?? '');
    tipSnackBar(context, '已存进识别记录 🍽️');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final list = store.sortedFoodScans;

    return ModuleScaffold(
      title: '🍽️ 识热量',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部操作卡
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.aiApiKey.isEmpty ? '演示模式：结果仅供参考' : 'AI 模式：${store.aiModel}',
                          style: TextStyle(fontSize: 11, color: store.aiApiKey.isEmpty ? AppColors.muted : pal.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: _openAiSettings,
                        child: Row(
                          children: [const Text('⚙️', style: TextStyle(fontSize: 13)), const SizedBox(width: 3), Text('设置', style: TextStyle(fontSize: 11, color: pal.primary, fontWeight: FontWeight.w700))],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _busy ? null : () => _pick(ImageSource.camera),
                          child: _ActionCard(emoji: '📷', label: '拍一张', color: pal.primary, sub: '对着食物拍'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _busy ? null : () => _pick(ImageSource.gallery),
                          child: _ActionCard(emoji: '🖼️', label: '从相册选', color: const Color(0xFF8E7CC3), sub: '上传已有照片'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('拍下或上传食物照片，自动识别是什么、估算多少千卡。AI 估算仅供参考，具体以实际为准。', style: const TextStyle(fontSize: 10, color: AppColors.muted, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 识别中 / 结果
            if (_busy)
              const SectionCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 14),
                      Text('正在识别这顿饭...', style: TextStyle(fontSize: 12, color: AppColors.sub)),
                    ],
                  ),
                ),
              ),
            if (!_busy && _result != null && _image != null) _ResultCard(
              image: _image!,
              name: _result!['name'].toString(),
              calories: (_result!['calories'] as num).toInt(),
              note: _result!['note']?.toString() ?? '',
              onSave: _saveResult,
            ),
            const SizedBox(height: 4),

            // 历史记录
            if (list.isNotEmpty)
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardTitle('🗒️ 识别记录'),
                    for (final f in list.take(20)) _ScanRow(scan: f),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String sub;
  final Color color;

  const _ActionCard({required this.emoji, required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(.3))),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Uint8List image;
  final String name;
  final int calories;
  final String note;
  final VoidCallback onSave;

  const _ResultCard({required this.image, required this.name, required this.calories, required this.note, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('识别结果', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(image, width: 72, height: 72, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text('约 $calories 千卡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pal.primary)),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(note, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: AppButton('存进识别记录', onTap: onSave)),
        ],
      ),
    );
  }
}

class _ScanRow extends StatelessWidget {
  final dynamic scan;

  const _ScanRow({required this.scan});

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: const Text('🍽️', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('${scan.note.isEmpty ? '' : scan.note + ' · '}${fmtCN(scan.date)}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Text('${scan.calories} 千卡', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.income)),
          IconButton(
            onPressed: () => store.deleteFoodScan(scan),
            icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

const demoFoods = <Map<String, dynamic>>[
  {'name': '米饭一碗', 'cal': 232, 'note': '约 200 克熟米饭'},
  {'name': '宫保鸡丁', 'cal': 360, 'note': '一份约 250 克，含花生与鸡丁'},
  {'name': '红烧肉', 'cal': 480, 'note': '一份约 200 克，肥瘦相间'},
  {'name': '蔬菜沙拉', 'cal': 120, 'note': '一碗约 250 克，含油醋汁'},
  {'name': '牛肉汉堡', 'cal': 540, 'note': '一个汉堡，含芝士与酱料'},
  {'name': '薯条', 'cal': 310, 'note': '中份约 115 克'},
  {'name': '苹果', 'cal': 95, 'note': '一个中等大小约 180 克'},
  {'name': '牛奶', 'cal': 130, 'note': '一杯约 250 毫升全脂奶'},
  {'name': '牛肉面', 'cal': 520, 'note': '一碗约 400 克，含面条与牛肉'},
  {'name': '饺子', 'cal': 240, 'note': '10 个猪肉白菜馅水饺'},
  {'name': '煎蛋', 'cal': 90, 'note': '一个油煎鸡蛋'},
  {'name': '火锅', 'cal': 750, 'note': '一餐约 500 克食材，含牛油锅底'},
];
