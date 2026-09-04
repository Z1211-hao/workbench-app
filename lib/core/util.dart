/// 日期与文本工具函数
library;

String _p2(int n) => n.toString().padLeft(2, '0');

/// 'yyyy-MM-dd' 形式的日期键，全应用统一用它存储日期
String dateKey(DateTime d) => '${d.year}-${_p2(d.month)}-${_p2(d.day)}';

DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime today() => dayStart(DateTime.now());

DateTime now() => DateTime.now();

DateTime parseDate(String? s) {
  if (s == null || s.length < 10) return today();
  final parts = s.split('-');
  if (parts.length != 3) return today();
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return today();
  return DateTime(y, m, d);
}

DateTime parseTimeOfDay(String? s) {
  final parts = (s ?? '').split(':');
  final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(2000, 1, 1, h, m);
}

/// 自然日差：b - a（天数）
int daysBetween(DateTime a, DateTime b) =>
    dayStart(b).difference(dayStart(a)).inDays;

DateTime addDays(DateTime d, int n) => dayStart(d).add(Duration(days: n));

/// 周一为一周起点
DateTime startOfWeek(DateTime d) => dayStart(d.subtract(Duration(days: d.weekday - 1)));

/// 当前是第几周（学期开学日期所在周为第 1 周）；早于开学返回 0
int weekNoOf(DateTime date, DateTime termStart) {
  final s = startOfWeek(termStart);
  final t = startOfWeek(date);
  final n = t.difference(s).inDays ~/ 7 + 1;
  return n;
}

const _weekCnChars = '一二三四五六日';

String weekCn(int weekday) => _weekCnChars[weekday - 1];

String fmtCN(DateTime d) => '${d.year}年${d.month}月${d.day}日';

String fmtMD(DateTime d) => '${d.month}月${d.day}日';

String fmtTime(DateTime d) => '${_p2(d.hour)}:${_p2(d.minute)}';

String fmtTimeSec(DateTime d) => '${_p2(d.hour)}:${_p2(d.minute)}:${_p2(d.second)}';

String fmtClock(DateTime d) => '${_p2(d.hour)}:${_p2(d.minute)}';

String fmtAmount(double v) {
  final fixed = v.toStringAsFixed(2);
  return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
}

String greetingOf(int hour) {
  if (hour >= 5 && hour < 11) return '早上好';
  if (hour >= 11 && hour < 13) return '中午好';
  if (hour >= 13 && hour < 18) return '下午好';
  if (hour >= 18 && hour < 23) return '晚上好';
  return '夜深了';
}

/// 按日期生成稳定随机种子（每日格言用）
int daySeed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// 简单可复现的伪随机（种子 + 索引）
int seededRandom(int seed, int mod) {
  final x = (seed * 1103515245 + 12345) & 0x7fffffff;
  return x % mod;
}

/// 聊天消息按天分组的标签
String chatDayLabel(DateTime d) {
  final diff = daysBetween(d, today());
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  return '${d.month}月${d.day}日';
}

String id() => DateTime.now().microsecondsSinceEpoch.toString();
