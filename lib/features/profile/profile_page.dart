import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/seed.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';

/// 我的（PRD 3.9）
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final p = store.profile;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader('🎀 我的', '把自己照顾好'),

            // 资料卡
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pal.softBg, Colors.white]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: pal.softBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: pal.softBorder, width: 3)),
                    child: Text(p.avatar, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        const SizedBox(height: 3),
                        Text(p.motto.isEmpty ? '写一句给自己的话吧' : p.motto, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                      ],
                    ),
                  ),
                  AppButton('编辑资料', ghost: true, small: true, onTap: () => _openEditSheet(context)),
                ],
              ),
            ),

            // 主题卡
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CardTitle('🎨 主题色'),
                  ThemeDots(),
                ],
              ),
            ),

            // 内容管理
            SectionCard(
              child: Column(
                children: [
                  SettingRow(
                    emoji: '📡',
                    title: '聊天互通设置',
                    sub: store.chatRemoteReady
                        ? '已连接 · 两台手机真实互通'
                        : (store.chatMyId.isNotEmpty ? '账号已保存 · 未连接' : '本地演示模式 · 点击配置真实账号'),
                    onTap: () => _push(context, const ChatAccountPage()),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  SettingRow(
                    emoji: '☀️',
                    title: '打卡项管理',
                    sub: '当前 ${store.checkinItems.length} 项 · 增删排序',
                    onTap: () => _push(context, const CheckinManagePage()),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  SettingRow(
                    emoji: '💬',
                    title: '格言库与寄语池',
                    sub: '内置 ${builtInQuotes.length} 条格言 · 收藏 ${store.favoredQuotes.length} 条',
                    onTap: () => _push(context, const QuotesPage()),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  SettingRow(
                    emoji: '📅',
                    title: '学期设置',
                    sub: store.term.isSet
                        ? '${store.term.startDate} 开学 · ${store.term.totalWeeks} 周'
                        : '还没设置，课表需要它',
                    onTap: () => _push(context, const TermPage()),
                  ),
                ],
              ),
            ),

            // 偏好开关
            SectionCard(
              child: Column(
                children: [
                  SettingRow(
                    emoji: '🔔',
                    title: '消息通知',
                    sub: '待办 / 课前 / 倒数日 / 新消息',
                    trailing: Switch(
                      value: store.settings.notifyOn,
                      activeTrackColor: pal.primary,
                      onChanged: (_) => store.toggleNotify(),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  SettingRow(
                    emoji: '🌸',
                    title: '启动时显示欢迎页',
                    sub: '每次打开都有仪式感',
                    trailing: Switch(
                      value: store.settings.showWelcome,
                      activeTrackColor: pal.primary,
                      onChanged: (_) => store.toggleWelcome(),
                    ),
                  ),
                ],
              ),
            ),

            // 数据与关于
            SectionCard(
              child: Column(
                children: [
                  SettingRow(
                    emoji: '📤',
                    title: '数据导出与备份',
                    sub: '导出 JSON · 从备份恢复',
                    onTap: () => _push(context, const DataPage()),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  SettingRow(
                    emoji: 'ℹ️',
                    title: '关于小窝工作台',
                    sub: 'V1.0.0 · 认识窝窝',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🏠 小窝工作台', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('V1.0.0 · 本地版', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
            SizedBox(height: 10),
            Text('窝窝是这只住在 App 里的小仓鼠 🐹，它帮你们记日子、记账、记想吃的东西，还守着只有你们俩能看的聊天小屋。',
                style: TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.6)),
            SizedBox(height: 10),
            Text('数据全部保存在这台设备上；接入服务器后即可与 TA 互通。', style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.6)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('抱抱窝窝', style: TextStyle(color: Color(0xFFE8798F), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _ProfileEditSheet(),
    );
  }
}

// ---------------- 编辑资料 ----------------

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet();

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _motto;
  late final TextEditingController _note;
  late String _avatar;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppStore>().profile;
    _name = TextEditingController(text: p.name);
    _motto = TextEditingController(text: p.motto);
    _note = TextEditingController(text: p.partnerNote);
    _avatar = p.avatar;
  }

  @override
  void dispose() {
    _name.dispose();
    _motto.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;

    return SheetWrap('✏️ 编辑资料', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('窝窝头像（六选一）'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final a in avatarOptions)
              GestureDetector(
                onTap: () => setState(() => _avatar = a),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _avatar == a ? pal.softBg : AppColors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: _avatar == a ? pal.primary : AppColors.line, width: _avatar == a ? 2 : 1),
                  ),
                  child: Text(a, style: const TextStyle(fontSize: 24)),
                ),
              ),
          ],
        ),
        const FieldLabel('昵称（2-12 字）'),
        AppInput('比如：小黄', _name, maxLength: 12),
        const FieldLabel('个性寄语（0-20 字，欢迎页展示）'),
        AppInput('写一句给自己的话', _motto, maxLength: 20),
        const FieldLabel('给小伙伴的备注名（0-12 字）'),
        AppInput('比如：小熊猫', _note, maxLength: 12),
        const SizedBox(height: 16),
        Center(
          child: AppButton('保存 💾', onTap: () {
            context.read<AppStore>().updateProfile(
                  name: _name.text,
                  motto: _motto.text,
                  avatar: _avatar,
                  partnerNote: _note.text,
                );
            Navigator.pop(context);
            tipSnackBar(context, '资料已保存 ✅');
          }),
        ),
        const SizedBox(height: 8),
      ],
    ));
  }
}

// ---------------- 打卡项管理 ----------------

class CheckinManagePage extends StatefulWidget {
  const CheckinManagePage({super.key});

  @override
  State<CheckinManagePage> createState() => _CheckinManagePageState();
}

class _CheckinManagePageState extends State<CheckinManagePage> {
  final _name = TextEditingController();
  String _emoji = '⭐';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final items = store.checkinItems;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('☀️ 打卡项管理', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
        leading: const BackButton(color: AppColors.sub),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('＋ 新增打卡项（上限 10 项）'),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final e = await pickEmojiSheet(context, ['⭐', '☀️', '💧', '🧘', '📖', '🌙', '🏃', '🥗', '💊', '🎧', '✍️', '🧹']);
                        if (e != null) setState(() => _emoji = e);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: pal.softBg, borderRadius: BorderRadius.circular(13), border: Border.all(color: pal.softBorder)),
                        child: Text(_emoji, style: const TextStyle(fontSize: 21)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: AppInput('名称（1-6 字）', _name, maxLength: 6)),
                    const SizedBox(width: 10),
                    AppButton('添加', small: true, onTap: () {
                      if (_name.text.trim().isEmpty) {
                        tipSnackBar(context, '先写个名字吧');
                        return;
                      }
                      if (store.checkinItems.length >= 10) {
                        tipSnackBar(context, '最多 10 项啦');
                        return;
                      }
                      store.addCheckinItem(_name.text.trim(), _emoji);
                      _name.clear();
                    }),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              children: [
                if (items.isEmpty)
                  const EmptyState('🌱', '还没有打卡项，加一个吧'),
                for (var i = 0; i < items.length; i++)
                  Column(
                    children: [
                      if (i > 0) const Divider(height: 1, color: AppColors.line),
                      Row(
                        children: [
                          Text(items[i].emoji, style: const TextStyle(fontSize: 19)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(items[i].name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
                          // 上移 / 下移
                          GestureDetector(
                            onTap: i == 0 ? null : () => store.moveCheckinItem(i, i - 1),
                            child: Padding(padding: const EdgeInsets.all(6), child: Text('↑', style: TextStyle(fontSize: 15, color: i == 0 ? AppColors.line : AppColors.sub))),
                          ),
                          GestureDetector(
                            onTap: i == items.length - 1 ? null : () => store.moveCheckinItem(i, i + 1),
                            child: Padding(padding: const EdgeInsets.all(6), child: Text('↓', style: TextStyle(fontSize: 15, color: i == items.length - 1 ? AppColors.line : AppColors.sub))),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final ok = await confirmDialog(context, '删除打卡项', '「${items[i].name}」和它的历史打卡记录都会被删除，确定吗？');
                              if (ok) store.deleteCheckinItem(items[i]);
                            },
                            child: const Padding(padding: EdgeInsets.all(6), child: Text('🗑', style: TextStyle(fontSize: 14))),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 格言库与寄语池 ----------------

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  String _tab = 'quotes'; // quotes 全部 / favs 收藏 / mottos 寄语池
  final _mottoCtrl = TextEditingController();

  @override
  void dispose() {
    _mottoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('💬 格言库与寄语池', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
        leading: const BackButton(color: AppColors.sub),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          PillGroup<String>(
            current: _tab,
            onChanged: (v) => setState(() => _tab = v),
            options: const [
              (value: 'quotes', label: '全部格言'),
              (value: 'favs', label: '♥ 我的收藏'),
              (value: 'mottos', label: '寄语池'),
            ],
          ),
          const SizedBox(height: 12),
          if (_tab == 'quotes' || _tab == 'favs')
            SectionCard(
              child: Column(
                children: [
                  if (_tab == 'favs' && store.favoredQuotes.isEmpty)
                    const EmptyState('🤍', '还没有收藏，桌面点小心心收起来吧'),
                  for (final q in builtInQuotes)
                    if (_tab == 'quotes' || store.favoredQuotes.contains(q.zh))
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(q.zh, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.5)),
                                      const SizedBox(height: 3),
                                      Text(q.en, style: const TextStyle(fontSize: 10, color: AppColors.muted, height: 1.4, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => store.toggleQuoteFav(q),
                                  child: Text(store.favoredQuotes.contains(q.zh) ? '💗' : '🤍', style: const TextStyle(fontSize: 18)),
                                ),
                              ],
                            ),
                          ),
                          if (q != builtInQuotes.last) const Divider(height: 1, color: AppColors.line),
                        ],
                      ),
                ],
              ),
            ),
          if (_tab == 'mottos') ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CardTitle('＋ 添加自定义寄语（每日随机出现在欢迎页）'),
                  Row(
                    children: [
                      Expanded(child: AppInput('2-20 字', _mottoCtrl, maxLength: 20)),
                      const SizedBox(width: 10),
                      Builder(builder: (ctx) {
                        return AppButton('添加', small: true, onTap: () {
                          final err = ctx.read<AppStore>().addCustomMotto(_mottoCtrl.text);
                          if (err != null) {
                            tipSnackBar(ctx, err);
                          } else {
                            _mottoCtrl.clear();
                          }
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),
            SectionCard(
              child: Column(
                children: [
                  for (var i = 0; i < store.mottoPool.length; i++)
                    Column(
                      children: [
                        if (i > 0) const Divider(height: 1, color: AppColors.line),
                        Row(
                          children: [
                            Expanded(child: Text(store.mottoPool[i], style: const TextStyle(fontSize: 13, color: AppColors.ink))),
                            if (i >= builtInMottos.length)
                              GestureDetector(
                                onTap: () => store.removeCustomMotto(store.mottoPool[i]),
                                child: const Padding(padding: EdgeInsets.all(6), child: Text('🗑', style: TextStyle(fontSize: 13))),
                              )
                            else
                              const Padding(padding: EdgeInsets.all(6), child: Text('内置', style: TextStyle(fontSize: 9.5, color: AppColors.line, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------- 学期设置 ----------------

class TermPage extends StatefulWidget {
  const TermPage({super.key});

  @override
  State<TermPage> createState() => _TermPageState();
}

class _TermPageState extends State<TermPage> {
  DateTime? _startDate;
  late int _totalWeeks;
  late List<String> _nodeTimes;

  @override
  void initState() {
    super.initState();
    final t = context.read<AppStore>().term;
    _startDate = t.isSet ? t.start : null;
    _totalWeeks = t.totalWeeks;
    _nodeTimes = [...t.nodeTimes];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('📅 学期设置', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
        leading: const BackButton(color: AppColors.sub),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('🏫 学期信息'),
                const FieldLabel('开学日期（所在周记为第 1 周）'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? today(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                      helpText: '选择开学日期',
                      cancelText: '取消',
                      confirmText: '确定',
                    );
                    if (picked != null) setState(() => _startDate = dayStart(picked));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                    child: Row(
                      children: [
                        Text(_startDate == null ? '点击选择' : fmtCN(_startDate!), style: TextStyle(fontSize: 13.5, color: _startDate == null ? AppColors.muted : AppColors.ink, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Text('📅', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const FieldLabel('总周数'),
                Row(
                  children: [
                    _stepBtn('−', () => setState(() => _totalWeeks = (_totalWeeks - 1).clamp(10, 30))),
                    Expanded(
                      child: Center(child: Text('$_totalWeeks 周', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink))),
                    ),
                    _stepBtn('＋', () => setState(() => _totalWeeks = (_totalWeeks + 1).clamp(10, 30))),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('⏰ 五档节次时间（课前提醒与今日视图用）'),
                for (var i = 0; i < _nodeTimes.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 56, child: Text('第 ${i + 1} 节', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.sub))),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final t = parseTimeOfDay(_nodeTimes[i]);
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: t.hour, minute: t.minute),
                              helpText: '第 ${i + 1} 节开始时间',
                            );
                            if (picked != null) {
                              setState(() => _nodeTimes[i] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
                            child: Text(_nodeTimes[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pal.primary)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: AppButton('保存学期设置 💾', onTap: () {
              if (_startDate == null) {
                tipSnackBar(context, '先选一个开学日期');
                return;
              }
              context.read<AppStore>().setTerm(
                    startDate: dateKey(_startDate!),
                    totalWeeks: _totalWeeks,
                    nodeTimes: _nodeTimes,
                  );
              tipSnackBar(context, '学期已保存，课表周数自动计算 ✅');
              Navigator.pop(context);
            }),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(String symbol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.line)),
        child: Text(symbol, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sub)),
      ),
    );
  }
}

// ---------------- 数据导出与备份 ----------------

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final exportJson = store.exportJson();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('📤 数据导出与备份', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
        leading: const BackButton(color: AppColors.sub),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('📋 导出备份'),
                const Text('完整备份（资料、待办、账单、课表、倒数日、食谱、聊天、收藏，以及身高体重、运动、番茄钟、单词、识热量、游戏最高分、音乐歌单）会以 JSON 文本复制到剪贴板，粘贴保存到备忘录或发给自己的小号即可。聊天账号与 AI 识别密钥不会导出。',
                    style: TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.6)),
                const SizedBox(height: 12),
                Center(
                  child: AppButton('复制完整备份 📋', onTap: () {
                    Clipboard.setData(ClipboardData(text: exportJson));
                    tipSnackBar(context, '已复制到剪贴板，快去保存吧 ✅');
                  }),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                  child: SelectableText(
                    exportJson.length > 600 ? '${exportJson.substring(0, 600)}……' : exportJson,
                    style: const TextStyle(fontSize: 9.5, color: AppColors.muted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const _RestoreCard(),
          const _ClearCard(),
        ],
      ),
    );
  }
}

class _RestoreCard extends StatefulWidget {
  const _RestoreCard();

  @override
  State<_RestoreCard> createState() => _RestoreCardState();
}

class _RestoreCardState extends State<_RestoreCard> {
  final _ctrl = TextEditingController();
  final _shakeKey = GlobalKey<ShakerState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('📥 从备份恢复'),
          const Text('恢复会覆盖当前全部数据，建议先在上面导出一份当前数据。', style: TextStyle(fontSize: 11.5, color: AppColors.danger, height: 1.5)),
          const SizedBox(height: 10),
          Shaker(
            key: _shakeKey,
            child: AppInput('粘贴备份 JSON 到这里...', _ctrl, maxLines: 4),
          ),
          const SizedBox(height: 12),
          Center(
            child: AppButton('恢复数据 ♻️', onTap: () async {
              final store = context.read<AppStore>();
              final ok = await confirmDialog(
                context,
                '确认恢复',
                '当前数据将被备份内容整体替换，替换前记得先导出现有数据。确定继续吗？',
                okText: '覆盖恢复',
              );
              if (!ok) return;
              final err = store.importJson(_ctrl.text);
              if (err != null) {
                _shakeKey.currentState?.shake();
                tipSnackBar(context, err);
              } else {
                tipSnackBar(context, '恢复完成，欢迎回到小窝 🏠');
                _ctrl.clear();
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _ClearCard extends StatefulWidget {
  const _ClearCard();

  @override
  State<_ClearCard> createState() => _ClearCardState();
}

class _ClearCardState extends State<_ClearCard> {
  final _confirmCtrl = TextEditingController();
  final _selected = <String>{};

  static const _modules = [
    ('todo', '待办'),
    ('bill', '账单'),
    ('course', '课表'),
    ('countdown', '倒数日'),
    ('recipe', '食谱'),
    ('chat', '聊天记录'),
    ('checkin', '打卡项与记录'),
    ('health', '身高体重'),
    ('workout', '运动记录'),
    ('foodscan', '识别记录'),
    ('music', '音乐歌单'),
  ];

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('🗑 清空数据（危险操作）'),
          const Text('选择要清空的模块；操作不可恢复。', style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _modules)
                GestureDetector(
                  onTap: () => setState(() {
                    if (_selected.contains(m.$1)) {
                      _selected.remove(m.$1);
                    } else {
                      _selected.add(m.$1);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _selected.contains(m.$1) ? const Color(0xFFFDE8E8) : AppColors.bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _selected.contains(m.$1) ? AppColors.danger : AppColors.line),
                    ),
                    child: Text(m.$2, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _selected.contains(m.$1) ? AppColors.danger : AppColors.sub)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AppInput('输入「清空」二字确认', _confirmCtrl, maxLength: 2),
          const SizedBox(height: 12),
          Center(
            child: AppButton('清空所选（${_selected.length}）', onTap: () async {
              if (_selected.isEmpty) {
                tipSnackBar(context, '先选择要清空的模块');
                return;
              }
              if (_confirmCtrl.text != '清空') {
                tipSnackBar(context, '输入「清空」两个字才能继续哦');
                return;
              }
              final ok = await confirmDialog(context, '最后确认', '选中的 ${_selected.length} 个模块数据将被永久删除，真的确定吗？', okText: '永久清空');
              if (ok) {
                context.read<AppStore>().clearModules(_selected.toSet());
                _confirmCtrl.clear();
                setState(() => _selected.clear());
                tipSnackBar(context, '已清空所选模块 🧹');
              }
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------- 聊天互通设置（环信账号） ----------------

class ChatAccountPage extends StatefulWidget {
  const ChatAccountPage({super.key});

  @override
  State<ChatAccountPage> createState() => _ChatAccountPageState();
}

class _ChatAccountPageState extends State<ChatAccountPage> {
  late final TextEditingController _myId;
  late final TextEditingController _myPwd;
  late final TextEditingController _partnerId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppStore>();
    _myId = TextEditingController(text: s.chatMyId);
    _myPwd = TextEditingController(text: s.chatMyPwd);
    _partnerId = TextEditingController(text: s.chatPartnerId);
  }

  @override
  void dispose() {
    _myId.dispose();
    _myPwd.dispose();
    _partnerId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final err = await context.read<AppStore>().setChatAccount(
          myId: _myId.text,
          myPwd: _myPwd.text,
          partnerId: _partnerId.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    tipSnackBar(context, err ?? '连接成功，可以真机互通啦 💬');
  }

  Future<void> _reconnect() async {
    setState(() => _busy = true);
    await context.read<AppStore>().reconnectChat();
    if (!mounted) return;
    setState(() => _busy = false);
    tipSnackBar(context, context.read<AppStore>().chatRemoteReady ? '连上啦 ✅' : '还是没连上，检查网络和账号密码');
  }

  Future<void> _disconnect() async {
    final ok = await confirmDialog(context, '断开连接', '断开后聊天回到本地演示模式，本机保存的账号信息会被清空，确定吗？');
    if (ok) context.read<AppStore>().disconnectChatAccount();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final configured = store.chatMyId.isNotEmpty;
    final connected = store.chatRemoteReady;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.sub),
        title: const Text('📡 聊天互通设置', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle(
                  '当前状态',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: connected ? AppColors.income.withOpacity(.14) : AppColors.danger.withOpacity(.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      connected ? '已连接' : '未连接',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: connected ? AppColors.income : AppColors.danger),
                    ),
                  ),
                ),
                Text(
                  configured
                      ? '本机账号：${store.chatMyId}\n小伙伴账号：${store.chatPartnerId}\n${connected ? '消息经环信服务器中转，两台手机实时互通。' : '账号已保存但还没连上，进入聊天页会自动重试，也可以点下面「保存并连接」。'}'
                      : '还没配置账号，当前是本地演示模式（发出去的消息由本地模拟回复）。填好下面的表单就能真正互通啦。',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.8),
                ),
                if (configured) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: AppButton('重新连接', ghost: true, small: true, onTap: _busy ? null : _reconnect)),
                      const SizedBox(width: 10),
                      Expanded(child: AppButton('断开，回到演示模式', small: true, onTap: _disconnect)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('环信账号'),
                const Text(
                  '去环信控制台 → 你的应用 → 用户，创建两个用户（你一个、小伙伴一个），把 ID 和密码填在下面。两台手机各填各的账号，AppKey 已内置无需填写。',
                  style: TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.7),
                ),
                const SizedBox(height: 12),
                const FieldLabel('我的账号 ID'),
                AppInput('例如：xiaohuang', _myId),
                const SizedBox(height: 12),
                const FieldLabel('我的密码'),
                AppInput('环信用户密码', _myPwd, obscure: true),
                const SizedBox(height: 12),
                const FieldLabel('小伙伴的账号 ID'),
                AppInput('例如：xiaomei', _partnerId),
                const SizedBox(height: 16),
                Center(child: AppButton(_busy ? '连接中...' : '保存并连接', onTap: _busy ? null : _save)),
                const SizedBox(height: 10),
                const Center(child: Text('账号信息只保存在本机，不会随备份导出', style: TextStyle(fontSize: 10, color: AppColors.muted))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
