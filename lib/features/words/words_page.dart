import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// 背单词（新增功能 4）
class WordsPage extends StatefulWidget {
  const WordsPage({super.key});

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  static const goal = 10;
  bool _showMeaning = false;
  int _cardKey = 0;

  void _answer(WordItem w, bool known) {
    final store = context.read<AppStore>();
    store.recordWord(w, known);
    setState(() {
      _showMeaning = false;
      _cardKey++;
    });
    if (store.wordDoneToday.length >= goal) {
      tipSnackBar(context, '🎉 今日目标达成，明天继续！');
    }
  }

  void _openAddWord() {
    final wordCtrl = TextEditingController();
    final phCtrl = TextEditingController();
    final meanCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SheetWrap(
          '加一个词',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('单词'),
              AppInput('例如 cherish', wordCtrl),
              const FieldLabel('音标（可不填）'),
              AppInput('例如 /ˈtʃerɪʃ/', phCtrl),
              const FieldLabel('释义'),
              AppInput('例如 v. 珍惜；珍视', meanCtrl),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton('加入词库', onTap: () {
                  final store = context.read<AppStore>();
                  final err = store.addCustomWord(wordCtrl.text, phCtrl.text, meanCtrl.text);
                  if (err != null) {
                    tipSnackBar(ctx, err);
                    return;
                  }
                  Navigator.pop(ctx);
                  tipSnackBar(ctx, '已加入词库 📖');
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
    final todayList = store.todaysWords;
    final doneToday = store.wordDoneToday.length;
    final mastered = store.wordMasteredCount;
    final total = store.wordTotalCount;
    final current = todayList.isNotEmpty ? todayList.first : null;
    final goalReached = doneToday >= goal && todayList.isEmpty;

    return ModuleScaffold(
      title: '📖 背单词',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计卡
            SectionCard(
              child: Row(
                children: [
                  Expanded(child: _Stat(emoji: '📅', num: '${doneToday.clamp(0, goal)}/$goal', label: '今日已学')),
                  Container(width: 1, height: 32, color: AppColors.line),
                  Expanded(child: _Stat(emoji: '✅', num: '$mastered', label: '已掌握')),
                  Container(width: 1, height: 32, color: AppColors.line),
                  Expanded(child: _Stat(emoji: '📚', num: '$total', label: '词库总数')),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 学习卡片
            SectionCard(
              padding: const EdgeInsets.all(16),
              child: current == null
                  ? Column(
                      children: [
                        const SizedBox(height: 10),
                        const Text('🎉', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        const Text(
                          doneToday >= goal ? '今日目标达成，明天再来看新词吧！' : '词库里的词都掌握啦，去加点新词吧！',
                          style: TextStyle(fontSize: 13, color: AppColors.sub),
                        ),
                        const SizedBox(height: 12),
                        AppButton('加新词', ghost: true, onTap: _openAddWord),
                        const SizedBox(height: 10),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('还有 ${todayList.length} 个词要过 · 目标 $goal 个', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => setState(() => _showMeaning = !_showMeaning),
                          child: AnimatedContainer(
                            key: ValueKey(_cardKey),
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: pal.softBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: pal.softBorder),
                            ),
                            child: Column(
                              children: [
                                Text(current.word, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: 0.5)),
                                const SizedBox(height: 6),
                                if (current.phonetic.isNotEmpty)
                                  Text(current.phonetic, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontStyle: FontStyle.italic)),
                                const SizedBox(height: 16),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _showMeaning ? 1 : 0,
                                  child: Text(
                                    current.meaning,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _showMeaning ? '点卡片收起释义' : '👆 点卡片看释义',
                                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _answer(current, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF1D5D5))),
                                  child: const Text('😅 不认识', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _answer(current, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(gradient: pal.gradient, borderRadius: BorderRadius.circular(14)),
                                  child: const Text('✅ 认识', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text('认识要连续两次才算掌握，不认识的过几天还会再见到它', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 4),

            // 自定义词库
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle('➕ 我的词库', trailing: AppButton('加词', ghost: true, small: true, onTap: _openAddWord)),
                  if (store.customWords.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('还没有自定义单词，把想背的词加进来吧', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    )
                  else
                    for (final w in store.customWords) _CustomWordRow(word: w),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String emoji;
  final String num;
  final String label;

  const _Stat({required this.emoji, required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(num, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pal.primary)),
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}

class _CustomWordRow extends StatelessWidget {
  final WordItem word;

  const _CustomWordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final status = store.wordStatus[word.word] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(9)),
            child: Text(status >= 2 ? '✅' : (status >= 1 ? '📖' : '🆕'), style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.word, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Text(word.meaning, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              store.deleteCustomWord(word);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
