/// 环信 IM 远程聊天传输层：把 AppStore 的收发接到环信服务器，实现两台手机真实互通。
///
/// 使用 im_flutter_sdk 4.22+（Chat 前缀 API）。SDK 在进程内是单例
/// （ChatClient.getInstance），因此同一时刻只有一个传输层实例在登录态上；
/// 切换账号的顺序由 AppStore 保证：先 dispose 旧传输层（登出），再 connect 新的。
library;

import 'dart:async';
import 'dart:convert';

import 'package:im_flutter_sdk/im_flutter_sdk.dart' as emsdk;

import 'chat_transport.dart';
import 'models.dart';

class RemoteChatTransport implements ChatTransport {
  static const _handlerKey = 'wb_transport';
  static const _eventEmoji = 'wb_emoji';
  static const _eventCard = 'wb_card';

  /// SDK init 进程内只允许一次，多实例共享该标记
  static bool _sdkInited = false;

  final String appKey;
  final String myId;
  final String myPwd;
  final String partnerId;

  bool isConnected = false;
  void Function(ChatMessage msg)? _onReceive;

  /// 发送中消息：环信 msgId -> 状态 Completer
  final _pendingStatus = <String, Completer<MsgStatus>>{};

  RemoteChatTransport({
    required this.appKey,
    required this.myId,
    required this.myPwd,
    required this.partnerId,
  });

  /// 连接（init + 登录）。返回 null 表示成功，否则为失败原因。
  Future<String?> connect() async {
    try {
      if (!_sdkInited) {
        await emsdk.ChatClient.getInstance.init(
          emsdk.ChatOptions(appKey: appKey, autoLogin: false),
        );
        // 通知 SDK UI 已就绪，执行后才会收到事件回调
        await emsdk.ChatClient.getInstance.startCallback();
        _sdkInited = true;
      }
      await emsdk.ChatClient.getInstance.login(myId, myPwd);
      _installHandlers();
      isConnected = true;
      return null;
    } on emsdk.ChatError catch (e) {
      return '连接失败（${e.code}）：${e.description}';
    } catch (e) {
      return '连接失败：$e';
    }
  }

  void _installHandlers() {
    emsdk.ChatClient.getInstance.chatManager.addEventHandler(
      _handlerKey,
      emsdk.ChatEventHandler(
        onMessagesReceived: (messages) {
          for (final m in messages) {
            final converted = _convertIncoming(m);
            if (converted != null) _onReceive?.call(converted);
          }
        },
      ),
    );
    emsdk.ChatClient.getInstance.chatManager.addMessageEvent(
      _handlerKey,
      emsdk.ChatMessageEvent(
        onSuccess: (msgId, msg) => _completePending(msgId, MsgStatus.delivered),
        onError: (msgId, msg, error) => _completePending(msgId, MsgStatus.failed),
      ),
    );
  }

  void _completePending(String msgId, MsgStatus status) {
    final c = _pendingStatus.remove(msgId);
    if (c != null && !c.isCompleted) c.complete(status);
  }

  @override
  Future<MsgStatus> deliver(ChatMessage msg) async {
    if (!isConnected) return MsgStatus.failed;
    final emsdk.ChatMessage em;
    try {
      if (msg.type == 'text') {
        em = emsdk.ChatMessage.createTxtSendMessage(
          targetId: partnerId,
          content: msg.text,
        );
      } else if (msg.type == 'emoji') {
        em = emsdk.ChatMessage.createCustomSendMessage(
          targetId: partnerId,
          event: _eventEmoji,
          params: {'e': msg.text},
        );
      } else {
        em = emsdk.ChatMessage.createCustomSendMessage(
          targetId: partnerId,
          event: _eventCard,
          params: {
            'kind': msg.cardKind,
            'payload': jsonEncode(msg.cardPayload),
          },
        );
      }
    } catch (_) {
      return MsgStatus.failed;
    }

    final completer = Completer<MsgStatus>();
    _pendingStatus[em.msgId] = completer;
    try {
      await emsdk.ChatClient.getInstance.chatManager.sendMessage(em);
    } catch (_) {
      _completePending(em.msgId, MsgStatus.failed);
    }
    return completer.future.timeout(const Duration(seconds: 15), onTimeout: () {
      _pendingStatus.remove(em.msgId);
      return MsgStatus.failed;
    });
  }

  /// 环信消息 -> 本地模型；只处理来自小伙伴的消息，其余忽略
  ChatMessage? _convertIncoming(emsdk.ChatMessage em) {
    if (em.from != partnerId) return null;
    final time = em.serverTime > 0
        ? DateTime.fromMillisecondsSinceEpoch(em.serverTime)
        : DateTime.now();
    final body = em.body;
    if (body is emsdk.ChatTextMessageBody) {
      return ChatMessage(
        id: 'e${em.msgId}',
        fromMe: false,
        type: 'text',
        text: body.content,
        time: time,
        status: MsgStatus.delivered,
      );
    }
    if (body is emsdk.ChatCustomMessageBody) {
      final params = body.params ?? {};
      if (body.event == _eventEmoji) {
        return ChatMessage(
          id: 'e${em.msgId}',
          fromMe: false,
          type: 'emoji',
          text: params['e'] ?? '',
          time: time,
          status: MsgStatus.delivered,
        );
      }
      if (body.event == _eventCard) {
        Map<String, dynamic> payload = {};
        try {
          payload = (jsonDecode(params['payload'] ?? '{}') as Map).cast<String, dynamic>();
        } catch (_) {}
        return ChatMessage(
          id: 'e${em.msgId}',
          fromMe: false,
          type: 'card',
          cardKind: params['kind'] ?? '',
          cardPayload: payload,
          time: time,
          status: MsgStatus.delivered,
        );
      }
    }
    return null; // 其他类型（图片/语音等）V1 不处理
  }

  @override
  void listen(void Function(ChatMessage msg) onReceive) {
    _onReceive = onReceive;
  }

  @override
  void dispose() {
    _onReceive = null;
    for (final c in _pendingStatus.values) {
      if (!c.isCompleted) c.complete(MsgStatus.failed);
    }
    _pendingStatus.clear();
    try {
      emsdk.ChatClient.getInstance.chatManager.removeMessageEvent(_handlerKey);
    } catch (_) {}
    try {
      emsdk.ChatClient.getInstance.chatManager.removeEventHandler(_handlerKey);
    } catch (_) {}
    try {
      emsdk.ChatClient.getInstance.logout(true);
    } catch (_) {}
    isConnected = false;
  }
}
