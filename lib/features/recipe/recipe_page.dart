import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/seed.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 食谱小本（PRD 3.7）
class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';
  String? _expandedId;

  // 随机抽菜
  Timer? _rollTimer;
  int _highlightIndex = -1;
  bool _rolling = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _rollTimer?.cancel();
    super.dispose();
  }

  void _roll() {
    final store = context.read<AppStore>();
    final pool = store.filteredRecipes(_searchCtrl.text, _filter);
    if (pool.length < 2) {
      tipSnackBar(context, '再多攒一道菜就能抽签啦');
      return;
    }
    setState(() {
      _rolling = true;
      _highlightIndex = 0;
    });

    // 高亮框依次扫过，速度先快后慢，约 2 秒后停留
    var delay = 120;
    var elapsed = 0;
    void tick() {
      _rollTimer = Timer(Duration(milliseconds: delay), () {
        if (!mounted) return;
        setState(() => _highlightIndex = (_highlightIndex + 1) % pool.length);
        delay += 28;
        elapsed += delay;
        if (elapsed < 2000) {
          tick();
        } else {
          final picked = pool[_highlightIndex];
          setState(() => _rolling = false);
          tipSnackBar(context, '就决定是你了：《${picked.name}》！');
        }
      });
    }

    tick();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _RecipeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final list = store.filteredRecipes(_searchCtrl.text, _filter);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader('🍳 食谱小本', '今天也要好好吃饭'),

          // 工具行
          Row(
            children: [
              Expanded(child: AppInput('搜菜名或食材...', _searchCtrl)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _rolling ? null : _roll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: _rolling ? null : pal.gradient,
                    color: _rolling ? AppColors.muted.withOpacity(.4) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('🎲', style: TextStyle(fontSize: 16, color: _rolling ? Colors.white : Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 筛选行
          Row(
            children: [
              Expanded(
                child: PillGroup<String>(
                  current: _filter,
                  onChanged: (v) => setState(() => _filter = v),
                  options: const [
                    (value: 'all', label: '全部'),
                    (value: 'fav', label: '♥ 收藏'),
                    (value: 'ate', label: '做过'),
                  ],
                ),
              ),
              AppButton('＋ 添加', ghost: true, small: true, onTap: _openAddSheet),
            ],
          ),
          const SizedBox(height: 12),

          if (list.isEmpty)
            SectionCard(
              child: EmptyState(
                _searchCtrl.text.isEmpty ? '📖' : '🔍',
                _searchCtrl.text.isEmpty ? '小本本还空着，把第一道菜写进来吧' : '没有找到，换一个关键词试试？',
              ),
            ),

          for (var i = 0; i < list.length; i++)
            _RecipeCard(
              recipe: list[i],
              highlighted: i == _highlightIndex,
              expanded: _expandedId == list[i].id,
              onToggleExpand: () => setState(() => _expandedId = _expandedId == list[i].id ? null : list[i].id),
            ),
        ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool highlighted;
  final bool expanded;
  final VoidCallback onToggleExpand;

  const _RecipeCard({required this.recipe, required this.highlighted, required this.expanded, required this.onToggleExpand});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final emoji = recipe.emoji.isNotEmpty ? recipe.emoji : (mealEmojis[recipe.meal] ?? '🍳');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: highlighted ? pal.softBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlighted ? pal.primary : AppColors.line, width: highlighted ? 2 : 1),
        boxShadow: highlighted
            ? [BoxShadow(color: pal.gradEnd.withOpacity(.3), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        children: [
          // 头部：封面 + 菜名 + 收藏
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [pal.softBg, pal.softBorder],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            _tag(recipe.meal, pal.softBg, pal.primary),
                            _tag(recipe.difficulty, const Color(0xFFF3EFFA), const Color(0xFF8E7CC3)),
                            if (recipe.calories != null) _tag('${recipe.calories} 千卡', const Color(0xFFEFF7F1), AppColors.income),
                            if (recipe.ateCount > 0) _tag('做过 ${recipe.ateCount} 次', const Color(0xFFFFF6E8), const Color(0xFFC98A2D)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => store.toggleRecipeFav(recipe),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(recipe.fav ? '❤️' : '🤍', style: const TextStyle(fontSize: 19)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 展开区：食材 / 步骤 / 贴士 / 操作
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 1, color: AppColors.line),
                  const SizedBox(height: 10),
                  const Text('🧺 食材清单', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 5),
                  for (final ing in recipe.ingredients)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('· ${ing.name}', style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                          const Spacer(),
                          Text(ing.amount, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text('👩‍🍳 做法步骤', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 5),
                  for (var s = 0; s < recipe.steps.length; s++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Text('${s + 1}. ${recipe.steps[s]}', style: const TextStyle(fontSize: 12, color: AppColors.sub, height: 1.5)),
                    ),
                  if (recipe.tip.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: pal.softBg, borderRadius: BorderRadius.circular(10)),
                      child: Text('💡 ${recipe.tip}', style: const TextStyle(fontSize: 11, color: AppColors.sub, height: 1.5)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          recipe.ateCount > 0 ? '吃过 ${recipe.ateCount} 次 · 再吃一次 😋' : '吃过啦 😋',
                          ghost: true,
                          small: true,
                          onTap: () {
                            store.markRecipeAte(recipe);
                            tipSnackBar(context, '又多了一次成就！🎉');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton('分享给 TA 💬', ghost: true, small: true, onTap: () {
                          shareCardToChat(context, 'recipe', {'name': recipe.name, 'emoji': emoji, 'meal': recipe.meal, 'difficulty': recipe.difficulty});
                        }),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final ok = await confirmDialog(
                            context,
                            '删除食谱',
                            recipe.ateCount > 0 ? '它已经被做过 ${recipe.ateCount} 次了，真的要删掉吗？' : '《${recipe.name}》会被删除，确定吗？',
                          );
                          if (ok) store.deleteRecipe(recipe);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text('🗑', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 9.5, color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

// ---------------- 添加食谱表单 ----------------

class _RecipeSheet extends StatefulWidget {
  const _RecipeSheet();

  @override
  State<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends State<_RecipeSheet> {
  final _name = TextEditingController();
  final _tip = TextEditingController();
  final _calories = TextEditingController();
  String _emoji = '🍳';
  String _meal = '家常菜';
  String _difficulty = '简单';

  final _ingName = <TextEditingController>[];
  final _ingAmount = <TextEditingController>[];
  final _steps = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _addIngredientRow();
    _steps.add(TextEditingController());
  }

  void _addIngredientRow() {
    _ingName.add(TextEditingController());
    _ingAmount.add(TextEditingController());
  }

  @override
  void dispose() {
    _name.dispose();
    _tip.dispose();
    _calories.dispose();
    for (final c in _ingName) {
      c.dispose();
    }
    for (final c in _ingAmount) {
      c.dispose();
    }
    for (final c in _steps) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final e = await pickEmojiSheet(context, recipeEmojis, current: _emoji);
    if (e != null) setState(() => _emoji = e);
  }

  void _save() {
    final store = context.read<AppStore>();
    final recipe = Recipe(
      id: id(),
      name: _name.text.trim(),
      emoji: _emoji,
      meal: _meal,
      difficulty: _difficulty,
      calories: int.tryParse(_calories.text.trim()),
      ingredients: [
        for (var i = 0; i < _ingName.length; i++)
          if (_ingName[i].text.trim().isNotEmpty) Ingredient(_ingName[i].text.trim(), _ingAmount[i].text.trim()),
      ],
      steps: [for (final c in _steps) if (c.text.trim().isNotEmpty) c.text.trim()],
      tip: _tip.text.trim(),
    );
    final err = store.addRecipe(recipe);
    if (err != null) {
      tipSnackBar(context, err);
      return;
    }
    Navigator.pop(context);
    tipSnackBar(context, '新菜入库！🍳');
  }

  @override
  Widget build(BuildContext context) {
    return SheetWrap('＋ 添加食谱', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('菜名（必填）'),
        AppInput('如：番茄炒蛋', _name, maxLength: 15),
        const FieldLabel('封面图标'),
        GestureDetector(
          onTap: _pickEmoji,
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.line)),
            child: Text(_emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const FieldLabel('餐次'),
        PillGroup<String>(
          current: _meal,
          onChanged: (v) => setState(() => _meal = v),
          options: [for (final m in mealOptions) (value: m, label: m)],
        ),
        const FieldLabel('难度'),
        PillGroup<String>(
          current: _difficulty,
          onChanged: (v) => setState(() => _difficulty = v),
          options: [for (final d in difficultyOptions) (value: d, label: d)],
        ),
        const FieldLabel('参考热量（千卡，可选）'),
        AppInput('如：280', _calories, keyboard: TextInputType.number),
        const FieldLabel('食材清单（至少 1 条）'),
        for (var i = 0; i < _ingName.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: AppInput('名称', _ingName[i], maxLength: 10)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: AppInput('用量', _ingAmount[i], maxLength: 8)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() {
                    _ingName.removeAt(i).dispose();
                    _ingAmount.removeAt(i).dispose();
                  }),
                  child: const Padding(padding: EdgeInsets.all(6), child: Text('×', style: TextStyle(fontSize: 16, color: AppColors.muted))),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => _addIngredientRow()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(border: Border.all(color: AppColors.line, style: BorderStyle.solid), borderRadius: BorderRadius.circular(10)),
            child: const Text('＋ 加一样食材', style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
        ),
        const FieldLabel('做法步骤（至少 1 条）'),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('${i + 1}.', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                ),
                const SizedBox(width: 8),
                Expanded(child: AppInput('这一步做什么', _steps[i], maxLines: 3, maxLength: 100)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _steps.removeAt(i).dispose()),
                  child: const Padding(padding: EdgeInsets.all(6), child: Text('×', style: TextStyle(fontSize: 16, color: AppColors.muted))),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => _steps.add(TextEditingController())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
            child: const Text('＋ 加一步', style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
        ),
        const FieldLabel('小贴士（可选）'),
        AppInput('有什么私房心得...', _tip, maxLines: 2, maxLength: 80),
        const SizedBox(height: 16),
        Center(child: AppButton('＋ 保存食谱', onTap: _save)),
        const SizedBox(height: 8),
      ],
    ));
  }
}
