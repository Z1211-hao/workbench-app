import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/seed.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/util.dart';

/// 双人聊天（PRD 3.8）：本地演示 / 环信远程双模式，界面与交互完全一致
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _emojiPanel = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<AppStore>().sendMessage(type: 'text', text: text);
    _input.clear();
    setState(() => _emojiPanel = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendSticker(String emoji) {
    context.read<AppStore>().sendMessage(type: 'emoji', text: emoji);
    setState(() => _emojiPanel = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _onLongPress(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.type == 'text')
              ListTile(
                leading: const Text('📋', style: TextStyle(fontSize: 18)),
                title: const Text('复制', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.text));
                  Navigator.pop(ctx);
                  tipSnack('已复制');
                },
              ),
            ListTile(
              leading: const Text('🗑', style: TextStyle(fontSize: 18)),
              title: const Text('删除（仅本机）', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<AppStore>().deleteMessage(msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  void tipSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final messages = store.messages;

    // 进度条变化时滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (store.messages.length != _lastCount) {
        _lastCount = store.messages.length;
        _scrollToBottom();
      }
    });

    // 按天分组
    final groups = <_DayGroup>[];
    for (final m in messages) {
      final label = chatDayLabel(m.time);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(_DayGroup(label));
      }
      groups.last.items.add(m);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 会话头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: pal.softBorder)),
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/mascot.jpg',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 38,
                        height: 38,
                        color: pal.softBg,
                        alignment: Alignment.center,
                        child: const Text('🐹', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.partnerName, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        Text(
                          store.chatRemoteReady ? '● 在线 · 消息实时互通' : '● 在线 · 本地演示，仅你们俩可见',
                          style: TextStyle(fontSize: 10, color: store.chatRemoteReady ? AppColors.income : AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => store.reconnectChat(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: store.chatRemoteReady ? AppColors.income.withOpacity(.12) : pal.softBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: store.chatRemoteReady ? AppColors.income.withOpacity(.4) : pal.softBorder),
                      ),
                      child: Text(
                        store.chatRemoteReady ? '已连接' : '本地演示模式',
                        style: TextStyle(
                          fontSize: 9,
                          color: store.chatRemoteReady ? AppColors.income : pal.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 消息流
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: groups.length,
                itemBuilder: (context, gi) {
                  final g = groups[gi];
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.line.withOpacity(.6), borderRadius: BorderRadius.circular(999)),
                        child: Text(g.label, style: const TextStyle(fontSize: 9.5, color: AppColors.sub)),
                      ),
                      for (final m in g.items) _MessageBubble(msg: m, onLongPress: () => _onLongPress(m)),
                    ],
                  );
                },
              ),
            ),
            // 表情面板
            if (_emojiPanel)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final s in wowoStickers)
                      GestureDetector(
                        onTap: () => _sendSticker(s),
                        child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
                          child: Text(s, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                  ],
                ),
              ),
            // 输入区
            Container(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: pal.softBorder)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _emojiPanel = !_emojiPanel),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _emojiPanel ? pal.softBg : AppColors.bg, borderRadius: BorderRadius.circular(11)),
                      child: Text('😊', style: const TextStyle(fontSize: 17)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLength: 500,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: '说点什么...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                        filled: true,
                        fillColor: AppColors.bg,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: pal.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(gradient: pal.gradient, borderRadius: BorderRadius.circular(12)),
                      child: const Text('➤', style: TextStyle(fontSize: 16, color: Colors.white)),
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

class _DayGroup {
  final String label;
  final items = <ChatMessage>[];
  _DayGroup(this.label);
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback onLongPress;

  const _MessageBubble({required this.msg, required this.onLongPress});

  static const _statusIcons = {
    MsgStatus.sending: '🕓',
    MsgStatus.delivered: '✓',
    MsgStatus.read: '✓✓',
    MsgStatus.failed: '❗',
  };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final mine = msg.fromMe;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.66),
          padding: msg.type == 'emoji' ? const EdgeInsets.all(6) : const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            gradient: mine ? pal.gradient : null,
            color: mine ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: mine ? null : Border.all(color: AppColors.line),
          ),
          child: _content(context, mine, pal),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, bool mine, AppPalette pal) {
    if (msg.type == 'emoji') {
      return Text(msg.text, style: const TextStyle(fontSize: 42));
    }
    if (msg.type == 'card') {
      return _CardBubble(kind: msg.cardKind, payload: msg.cardPayload, mine: mine, pal: pal);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          msg.text,
          style: TextStyle(fontSize: 13.5, height: 1.45, color: mine ? Colors.white : AppColors.ink),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fmtTime(msg.time), style: TextStyle(fontSize: 9, color: mine ? Colors.white70 : AppColors.muted)),
            if (mine) ...[
              const SizedBox(width: 4),
              Text(
                _statusIcons[msg.status] ?? '',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: msg.status == MsgStatus.read ? Colors.white : Colors.white70),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// 卡片消息气泡：点击查看只读详情
class _CardBubble extends StatelessWidget {
  final String kind;
  final Map<String, dynamic> payload;
  final bool mine;
  final AppPalette pal;

  const _CardBubble({required this.kind, required this.payload, required this.mine, required this.pal});

  static const _kindMeta = {
    'todo': ('📋', '待办'),
    'bill': ('💰', '账单'),
    'recipe': ('🍳', '食谱'),
    'countdown': ('⏳', '倒数日'),
    'course': ('📚', '课程'),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _kindMeta[kind] ?? ('🔗', '分享');
    final title = payload['name'] ?? payload['title'] ?? '';
    final sub = _subText();

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: mine ? Colors.white.withOpacity(.22) : AppColors.bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Text(meta.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${meta.$2}分享', style: TextStyle(fontSize: 9, color: mine ? Colors.white70 : AppColors.muted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 1),
                      Text('$title', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: mine ? Colors.white : AppColors.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sub, style: TextStyle(fontSize: 9.5, color: mine ? Colors.white70 : AppColors.sub)),
              const SizedBox(width: 4),
              Text('›', style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  String _subText() {
    switch (kind) {
      case 'todo':
        return '${payload['date'] ?? ''} · ${payload['priority'] ?? ''}';
      case 'bill':
        return '${payload['amount'] ?? ''} · ${payload['date'] ?? ''}';
      case 'recipe':
        return '${payload['meal'] ?? ''} · ${payload['difficulty'] ?? ''}';
      case 'countdown':
        final remain = payload['remain'];
        return remain == null ? '' : (remain == 0 ? '就是今天！' : remain > 0 ? '还有 $remain 天' : '已过 ${-remain} 天');
      case 'course':
        return '${payload['weekday'] ?? ''} ${payload['nodes'] ?? ''}';
      default:
        return '点击查看';
    }
  }

  void _showDetail(BuildContext context) {
    final lines = <String>[];
    payload.forEach((k, v) {
      if (k == 'remain') {
        lines.add('剩余：$v 天');
      } else if (v.toString().isNotEmpty) {
        lines.add('$k: $v');
      }
    });
    final title = payload['name'] ?? payload['title'] ?? '分享内容';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(line, style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('知道了', style: TextStyle(color: pal.primary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
