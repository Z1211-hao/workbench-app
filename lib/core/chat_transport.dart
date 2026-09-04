/// 聊天传输层接口：本地演示见 [LocalEchoTransport]，环信远程实现见 remote_chat_transport.dart。
library;

import 'dart:async';
import 'dart:math';

import 'models.dart';
import 'seed.dart';

abstract class ChatTransport {
  /// 发送消息：返回送达状态（本地演示为延迟模拟）。
  Future<MsgStatus> deliver(ChatMessage msg);

  /// 订阅对方新消息（演示模式由本地回复池触发）。
  void listen(void Function(ChatMessage msg) onReceive);

  void dispose();
}

/// 本地演示实现：发送约 0.8s 后送达；约 1.5-2.5s 后"小伙伴"自动回复一条。
class LocalEchoTransport implements ChatTransport {
  final _random = Random();
  final List<Timer> _timers = [];
  void Function(ChatMessage msg)? _onReceive;
  bool _disposed = false;

  @override
  Future<MsgStatus> deliver(ChatMessage msg) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_disposed) return MsgStatus.failed;
    _scheduleReply();
    return MsgStatus.delivered;
  }

  void _scheduleReply() {
    final delay = 1500 + _random.nextInt(1000);
    _timers.add(Timer(Duration(milliseconds: delay), () {
      if (_disposed || _onReceive == null) return;
      final text = partnerReplies[_random.nextInt(partnerReplies.length)];
      final reply = ChatMessage(
        id: 'r${DateTime.now().microsecondsSinceEpoch}',
        fromMe: false,
        type: 'text',
        text: text,
        status: MsgStatus.delivered,
      );
      _onReceive!(reply);
    }));
  }

  @override
  void listen(void Function(ChatMessage msg) onReceive) {
    _onReceive = onReceive;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}
