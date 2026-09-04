import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/store.dart';
import '../core/theme.dart';
import 'account/account_page.dart';
import 'chat/chat_page.dart';
import 'countdown/countdown_page.dart';
import 'home/home_page.dart';
import 'profile/profile_page.dart';
import 'recipe/recipe_page.dart';
import 'schedule/schedule_page.dart';
import 'todo/todo_page.dart';
import 'welcome/welcome_page.dart';

const _navEmojis = ['🏠', '📋', '💰', '📚', '⏳', '🍳', '💬', '🎀'];
const _navLabels = ['桌面', '待办', '记账', '课表', '倒数日', '食谱', '聊天', '我的'];

/// 根路由：欢迎页 ⇄ 工作台（0.3s 淡出右滑动效，见 PRD 3.1）
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final showWelcome = store.settings.showWelcome && !store.entered;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: showWelcome ? const WelcomePage(key: ValueKey('welcome')) : const ShellPage(key: ValueKey('shell')),
    );
  }
}

/// 通用框架：左侧导航 + 内容区（PRD 3.1 通用框架）
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 68,
            color: Colors.white,
            child: SafeArea(
              right: false,
              child: Column(
                children: [
                  for (var i = 0; i < _navEmojis.length; i++)
                    Expanded(
                      child: _NavItem(
                        emoji: _navEmojis[i],
                        label: _navLabels[i],
                        active: store.currentTab == i,
                        badge: i == 6 && store.chatUnread > 0 ? (store.chatUnread > 99 ? '99+' : '${store.chatUnread}') : null,
                        onTap: () => store.goToTab(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(width: 1, color: AppColors.line),
          Expanded(
            child: IndexedStack(
              index: store.currentTab,
              children: const [
                HomePage(),
                TodoPage(),
                AccountPage(),
                SchedulePage(),
                CountdownPage(),
                RecipePage(),
                ChatPage(),
                ProfilePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({required this.emoji, required this.label, required this.active, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
        decoration: BoxDecoration(
          color: active ? pal.softBg : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 19)),
                if (badge != null)
                  Positioned(
                    right: -9,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 14),
                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(999)),
                      child: Text(badge!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? pal.primary : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
