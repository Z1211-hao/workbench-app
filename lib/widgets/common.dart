/// 通用 UI 组件：卡片、标题、按钮、胶囊、空状态、确认弹层、抖动容器等。
library;

import 'dart:math' show sin;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/store.dart';
import '../core/theme.dart';

/// 白底圆角卡片（全应用统一的容器样式）
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// 模块页顶部标题：「emoji 标题」+ 标语
class PageHeader extends StatelessWidget {
  final String title;
  final String slogan;

  const PageHeader(this.title, this.slogan, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(slogan, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// 卡片内小标题
class CardTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const CardTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 表单小标签
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 10, bottom: 6), child: Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)));
}

/// 主渐变按钮
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool ghost;
  final bool small;

  const AppButton(this.text, {super.key, this.onTap, this.ghost = false, this.small = false});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    if (ghost) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 24, vertical: small ? 7 : 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: pal.primary.withOpacity(.45)),
              color: pal.softBg,
            ),
            child: Text(text, style: TextStyle(fontSize: small ? 12 : 13, fontWeight: FontWeight.w700, color: pal.primary)),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 24, vertical: small ? 7 : 11),
          decoration: BoxDecoration(gradient: pal.gradient, borderRadius: BorderRadius.circular(999), boxShadow: [
            BoxShadow(color: pal.gradEnd.withOpacity(.35), blurRadius: 10, offset: const Offset(0, 4)),
          ]),
          child: Text(text, style: TextStyle(fontSize: small ? 12 : 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}

/// 胶囊选择组
class PillGroup<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T current;
  final ValueChanged<T> onChanged;

  const PillGroup({super.key, required this.options, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final on = o.value == current;
        return GestureDetector(
          onTap: () => onChanged(o.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: on ? pal.gradient : null,
              color: on ? null : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? pal.gradEnd : AppColors.line),
            ),
            child: Text(o.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.sub)),
          ),
        );
      }).toList(),
    );
  }
}

/// 统一样式输入框
class AppInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboard;
  final bool autofocus;
  final bool obscure;

  const AppInput(this.hint, this.controller, {super.key, this.maxLines = 1,
 this.maxLength, this.keyboard, this.autofocus = false, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboard,
      autofocus: autofocus,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        filled: true,
        fillColor: AppColors.bg,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.watch<AppStore>().palette.primary, width: 1.4)),
      ),
    );
  }
}

/// 空状态插画位
class EmptyState extends StatelessWidget {
  final String emoji;
  final String text;

  const EmptyState(this.emoji, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// 抖动容器：校验失败时左右晃两下
class Shaker extends StatefulWidget {
  final Widget child;
  const Shaker({super.key, required this.child});

  @override
  State<Shaker> createState() => ShakerState();
}

class ShakerState extends State<Shaker> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  void shake() => _c.forward(from: 0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx = t < 1 ? sin(t * 12.56) * 6 * (1 - t) : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// 确认弹窗
Future<bool> confirmDialog(BuildContext context, String title, String body, {String okText = '确定', String cancelText = '再想想', Color? okColor}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
      content: Text(body, style: const TextStyle(fontSize: 13, color: AppColors.sub, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelText, style: const TextStyle(color: AppColors.muted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(okText, style: TextStyle(color: okColor ?? AppColors.danger, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  return res ?? false;
}

/// 带撤销动作的 SnackBar（删除类操作用）
void undoSnackBar(BuildContext context, String text, VoidCallback onUndo) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Expanded(child: Text(text)),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              onUndo();
            },
            child: Text('撤销', style: TextStyle(color: Colors.pink.shade100, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    ));
}

/// 普通提示 SnackBar
void tipSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// 底部弹层容器（统一圆角与内边距）
class SheetWrap extends StatelessWidget {
  final String title;
  final Widget child;
  final double heightFactor;

  const SheetWrap(this.title, this.child, {super.key, this.heightFactor = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 12),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

/// 设置行（我的页用）
class SettingRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingRow({super.key, required this.emoji, required this.title, this.sub, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (sub != null) ...[
                  const SizedBox(height: 1),
                  Text(sub!, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                ],
              ]),
            ),
            trailing ?? const Text('›', style: TextStyle(fontSize: 17, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// emoji 选择弹层
Future<String?> pickEmojiSheet(BuildContext context, List<String> emojis, {String current = ''}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          const Text('挑一个', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: emojis.map((e) {
              final on = e == current;
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, e),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? AppColors.bg : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: on ? const Color(0xFFE8798F) : AppColors.line, width: on ? 1.6 : 1),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}

/// 分享一条卡片消息给 TA（待办 / 账单 / 食谱 / 倒数日 / 课程）
void shareCardToChat(BuildContext context, String kind, Map<String, dynamic> payload) {
  final store = context.read<AppStore>();
  store.sendMessage(type: 'card', cardKind: kind, cardPayload: payload);
  tipSnackBar(context, '已分享给 TA，去聊天看看吧 💬');
}

/// 模块页框架：顶部返回栏 + 内容区（首页「应用中心」push 的二级页面用）
class ModuleScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? floatingAction;

  const ModuleScaffold({super.key, required this.title, required this.child, this.floatingAction});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: floatingAction,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// 主题色圆点组（我的页用）
class ThemeDots extends StatelessWidget {
  const ThemeDots({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Row(
      children: [
        for (final p in appPalettes.values) ...[
          GestureDetector(
            onTap: () => store.setTheme(p.key),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: p.gradient,
                shape: BoxShape.circle,
                border: Border.all(color: store.profile.themeKey == p.key ? Colors.white : Colors.transparent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: store.profile.themeKey == p.key ? p.gradEnd.withOpacity(.5) : Colors.transparent,
                    blurRadius: 8,
                    spreadRadius: store.profile.themeKey == p.key ? 2 : 0,
                  ),
                ],
              ),
              child: store.profile.themeKey == p.key
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ],
        const Spacer(),
        Text(store.palette.name, style: const TextStyle(fontSize: 12, color: AppColors.sub, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
