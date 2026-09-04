import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';
import '../../widgets/common.dart';
import '../games/games_page.dart';
import '../health/health_page.dart';
import '../music/music_page.dart';
import '../pomodoro/pomodoro_page.dart';
import '../recipe/food_scan_page.dart';
import '../words/words_page.dart';
import '../workout/workout_page.dart';

final _appEntries = <(String, String, Widget)>[
  ('📏', '身高体重', const HealthPage()),
  ('🍅', '番茄钟', const PomodoroPage()),
  ('📖', '背单词', const WordsPage()),
  ('💪', '运动打卡', const WorkoutPage()),
  ('🍽️', '识热量', const FoodScanPage()),
  ('🎮', '小游戏', const GamesPage()),
  ('🎵', '音乐', const MusicPage()),
];

/// 桌面仪表盘（PRD 3.2）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final nickname = store.profile.name;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 问候区
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${greetingOf(_now.hour)}～', style: const TextStyle(fontSize: 13, color: AppColors.sub)),
                      const SizedBox(height: 2),
                      Text(nickname.isEmpty ? '今天也要加油' : nickname,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ],
                  ),
                ),
                Text(fmtClock(_now), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: pal.primary)),
              ],
            ),
            const SizedBox(height: 3),
            Text.rich(
              TextSpan(
                text: '${fmtCN(_now)} ',
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                children: [
                  TextSpan(text: '星期${weekCn(_now.weekday)}', style: TextStyle(color: pal.primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 每日格言卡
            _QuoteCard(quote: store.quoteOfDay),
            const SizedBox(height: 12),

            // 每日打卡卡
            if (store.checkinItems.isNotEmpty) const _CheckinCard(),
            const SizedBox(height: 12),

            // 今日概览卡
            const _OverviewCard(),

            // 应用中心
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CardTitle('🧰 应用中心'),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.95,
                    children: [
                      for (final e in _appEntries) _AppTile(emoji: e.$1, label: e.$2, page: e.$3),
                    ],
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

class _AppTile extends StatelessWidget {
  final String emoji;
  final String label;
  final Widget page;

  const _AppTile({required this.emoji, required this.label, required this.page});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pal.softBg, Colors.white]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pal.softBorder),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 21)),
          ),
          const SizedBox(height: 5),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.sub, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final favored = store.isQuoteFavored(quote);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pal.softBg, Colors.white]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pal.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quote.zh, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.55)),
          const SizedBox(height: 5),
          Text(quote.en, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, height: 1.5, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  store.toggleQuoteFav(quote);
                  tipSnackBar(context, store.isQuoteFavored(quote) ? '收进格言库啦，在「我的」里能找到它' : '已取消收藏');
                },
                child: Row(
                  children: [
                    Text(favored ? '💗' : '🤍', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(favored ? '已收藏' : '收藏格言', style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (!store.canSwapQuote) {
                    tipSnackBar(context, '明天再来一句吧');
                    return;
                  }
                  store.swapQuote();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.line)),
                  child: Text(
                    store.canSwapQuote ? '换一首 ♪（剩 ${store.quoteSwapsLeft} 次）' : '换一首 ♪',
                    style: TextStyle(fontSize: 11, color: store.canSwapQuote ? pal.primary : AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  const _CheckinCard();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final items = store.checkinItems;
    final doneCount = items.where(store.isDoneToday).length;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            '☀️ 每日打卡',
            trailing: Text('$doneCount/${items.length}', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: [for (final item in items) _CheckinTile(item: item)],
          ),
          const SizedBox(height: 10),
          Text(
            store.allCheckinDone ? '🎉 今天全部完成啦，连续 ${store.checkinStreak} 天！' : '🔥 连续打卡 ${store.checkinStreak} 天 · 今天全部完成就 +1',
            style: const TextStyle(fontSize: 11, color: AppColors.sub),
          ),
        ],
      ),
    );
  }
}

class _CheckinTile extends StatelessWidget {
  final CheckinItem item;

  const _CheckinTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final done = store.isDoneToday(item);

    return GestureDetector(
      onTap: () {
        final wasAll = store.allCheckinDone;
        store.toggleCheckin(item);
        if (!wasAll && store.allCheckinDone) {
          tipSnackBar(context, '今天全部完成啦，太棒了！🎉');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: done ? pal.gradient : null,
          color: done ? null : AppColors.bg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: done ? pal.gradEnd : AppColors.line),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Text(item.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: done ? Colors.white : AppColors.ink)),
                  Text(done ? '已完成' : '待完成', style: TextStyle(fontSize: 9.5, color: done ? Colors.white70 : AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    final todoCount = store.todayUndoneTodos.length;
    final courseCount = store.todayCourses.length;
    final scheduleReady = store.term.isSet && store.scheduleActive;

    final nearest = store.nearestCountdown;
    final String cdNum;
    final String cdLabel;
    if (nearest == null) {
      cdNum = '';
      cdLabel = '快去创建一个盼头吧';
    } else if (nearest.remainDays == 0) {
      cdNum = '🎉';
      cdLabel = '${nearest.name}就是今天';
    } else {
      cdNum = '${nearest.remainDays}';
      cdLabel = '天到${nearest.name}';
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('📌 今日概览'),
          Row(
            children: [
              _OvSlice(num: '$todoCount', label: '条待办', onTap: () => store.goToTab(1)),
              _OvSlice(
                num: scheduleReady ? '$courseCount' : '',
                label: scheduleReady ? '节课' : '去设置学期',
                onTap: () => store.goToTab(3),
              ),
              _OvSlice(num: cdNum, label: cdLabel, onTap: () => store.goToTab(4)),
              _OvSlice(
                num: store.chatUnread > 0 ? '${store.chatUnread}' : '0',
                label: '未读消息',
                hot: store.chatUnread > 0,
                onTap: () => store.goToTab(6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OvSlice extends StatelessWidget {
  final String num;
  final String label;
  final VoidCallback onTap;
  final bool hot;

  const _OvSlice({required this.num, required this.label, required this.onTap, this.hot = false});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text(
                num.isEmpty ? '—' : num,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: hot ? AppColors.danger : pal.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, color: AppColors.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
