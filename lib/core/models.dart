/// 全部数据模型，字段定义以 PRD 各模块「字段规则」小节与 5.3 数据实体为准。
library;

import 'util.dart';

// ---------------- 用户与设置 ----------------

class Profile {
  String name; // 2-12 字
  String motto; // 个性寄语 0-20 字
  String avatar; // emoji 头像
  String partnerNote; // 给小伙伴的备注名 0-12 字
  String themeKey;

  Profile({
    this.name = '小黄',
    this.motto = '慢慢来，一切都在变好',
    this.avatar = '🐻',
    this.partnerNote = '',
    this.themeKey = 'pink',
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] ?? '小黄',
        motto: j['motto'] ?? '',
        avatar: j['avatar'] ?? '🐻',
        partnerNote: j['partnerNote'] ?? '',
        themeKey: j['themeKey'] ?? 'pink',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'motto': motto,
        'avatar': avatar,
        'partnerNote': partnerNote,
        'themeKey': themeKey,
      };
}

class AppSettings {
  bool showWelcome;
  bool notifyOn; // 通知总开关（V1.0 仅保存偏好，V1.1 接系统通知）

  AppSettings({this.showWelcome = true, this.notifyOn = true});

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        showWelcome: j['showWelcome'] ?? true,
        notifyOn: j['notifyOn'] ?? true,
      );

  Map<String, dynamic> toJson() => {'showWelcome': showWelcome, 'notifyOn': notifyOn};
}

/// 学期信息（我的-学期设置）
class Term {
  String startDate; // 'yyyy-MM-dd'，空串 = 未设置
  int totalWeeks; // 默认 20
  List<String> nodeTimes; // 五档节次开始时间 'HH:mm'

  Term({this.startDate = '', this.totalWeeks = 20, List<String>? nodeTimes})
      : nodeTimes = nodeTimes ?? ['08:00', '10:00', '14:00', '16:00', '19:00'];

  bool get isSet => startDate.isNotEmpty;

  DateTime get start => parseDate(startDate);

  factory Term.fromJson(Map<String, dynamic> j) => Term(
        startDate: j['startDate'] ?? '',
        totalWeeks: (j['totalWeeks'] ?? 20) as int,
        nodeTimes: (j['nodeTimes'] as List?)?.map((e) => e.toString()).toList() ??
            ['08:00', '10:00', '14:00', '16:00', '19:00'],
      );

  Map<String, dynamic> toJson() => {'startDate': startDate, 'totalWeeks': totalWeeks, 'nodeTimes': nodeTimes};
}

// ---------------- 打卡 ----------------

class CheckinItem {
  final String id;
  String name; // 1-6 字
  String emoji;
  int sort;

  CheckinItem({required this.id, required this.name, required this.emoji, this.sort = 0});

  factory CheckinItem.fromJson(Map<String, dynamic> j) => CheckinItem(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'],
        sort: (j['sort'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji, 'sort': sort};
}

// ---------------- 待办 ----------------

class Todo {
  final String id;
  String text; // 1-50 字
  String date; // 'yyyy-MM-dd'
  int priority; // 0 高 / 1 中 / 2 低
  bool done;
  DateTime? doneAt;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.text,
    required this.date,
    this.priority = 1,
    this.done = false,
    this.doneAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get overdue => !done && daysBetween(parseDate(date), today()) > 0;

  factory Todo.fromJson(Map<String, dynamic> j) => Todo(
        id: j['id'],
        text: j['text'],
        date: j['date'],
        priority: (j['priority'] ?? 1) as int,
        done: j['done'] ?? false,
        doneAt: j['doneAt'] != null ? DateTime.tryParse(j['doneAt'].toString()) : null,
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'date': date,
        'priority': priority,
        'done': done,
        'doneAt': doneAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

// ---------------- 记账 ----------------

class BillCategory {
  final String key;
  final String name;
  final String emoji;
  const BillCategory(this.key, this.name, this.emoji);
}

class Bill {
  final String id;
  String type; // 'out' 支出 / 'in' 收入
  double amount; // 0.01 - 99999.99
  String category; // category key
  String date; // 'yyyy-MM-dd'，禁选未来
  String note; // 0-30 字
  final DateTime createdAt;

  Bill({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        id: j['id'],
        type: j['type'] ?? 'out',
        amount: (j['amount'] ?? 0).toDouble(),
        category: j['category'] ?? 'food',
        date: j['date'],
        note: j['note'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'date': date,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ---------------- 课表 ----------------

class Course {
  final String id;
  String name; // 1-10 字
  List<int> weekdays; // 1(周一) - 7(周日)，多选
  int startNode; // 第 X 节，1-5
  int endNode; // 起 ≤ 止
  int weekStart; // 第 A 周
  int weekEnd;
  int parity; // 0 每周 / 1 单周 / 2 双周
  String place; // 0-15 字
  String teacher; // 0-10 字
  int colorIndex; // 6 色色板循环

  Course({
    required this.id,
    required this.name,
    required this.weekdays,
    this.startNode = 1,
    this.endNode = 1,
    this.weekStart = 1,
    this.weekEnd = 20,
    this.parity = 0,
    this.place = '',
    this.teacher = '',
    this.colorIndex = 0,
  });

  bool coversWeek(int week) {
    if (week < weekStart || week > weekEnd) return false;
    if (parity == 1 && week % 2 == 0) return false;
    if (parity == 2 && week % 2 == 1) return false;
    return true;
  }

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'],
        name: j['name'],
        weekdays: (j['weekdays'] as List).map((e) => e as int).toList(),
        startNode: (j['startNode'] ?? 1) as int,
        endNode: (j['endNode'] ?? 1) as int,
        weekStart: (j['weekStart'] ?? 1) as int,
        weekEnd: (j['weekEnd'] ?? 20) as int,
        parity: (j['parity'] ?? 0) as int,
        place: j['place'] ?? '',
        teacher: j['teacher'] ?? '',
        colorIndex: (j['colorIndex'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weekdays': weekdays,
        'startNode': startNode,
        'endNode': endNode,
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'parity': parity,
        'place': place,
        'teacher': teacher,
        'colorIndex': colorIndex,
      };
}

// ---------------- 倒数日 ----------------

class Countdown {
  final String id;
  String name; // 1-12 字
  String date; // 任意日期，过去日期作为纪念日
  String emoji;
  String category; // 考试/生日/纪念日/节日/旅行/其他
  bool pinned;
  bool repeatYearly;
  bool shared; // 两人共享

  Countdown({
    required this.id,
    required this.name,
    required this.date,
    this.emoji = '⭐',
    this.category = '其他',
    this.pinned = false,
    this.repeatYearly = false,
    this.shared = false,
  });

  int get remainDays => daysBetween(today(), parseDate(date));

  factory Countdown.fromJson(Map<String, dynamic> j) => Countdown(
        id: j['id'],
        name: j['name'],
        date: j['date'],
        emoji: j['emoji'] ?? '⭐',
        category: j['category'] ?? '其他',
        pinned: j['pinned'] ?? false,
        repeatYearly: j['repeatYearly'] ?? false,
        shared: j['shared'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date,
        'emoji': emoji,
        'category': category,
        'pinned': pinned,
        'repeatYearly': repeatYearly,
        'shared': shared,
      };
}

// ---------------- 食谱 ----------------

class Ingredient {
  String name; // 0-10 字
  String amount; // 0-8 字

  Ingredient(this.name, this.amount);

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(j['name'] ?? '', j['amount'] ?? '');

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

class Recipe {
  final String id;
  String name; // 1-15 字
  String emoji; // 封面（V1 用 emoji 渐变底，V1.1 支持照片）
  String meal; // 早餐/午餐/晚餐/加餐/家常菜/硬菜
  String difficulty; // 简单/中等/复杂
  int? calories; // 1-5000 千卡
  List<Ingredient> ingredients; // 至少 1 条
  List<String> steps; // 至少 1 条，每条 ≤100 字
  String tip; // 0-80 字
  bool fav;
  int ateCount;
  String lastAteAt; // 'yyyy-MM-dd'
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.name,
    this.emoji = '🍳',
    this.meal = '家常菜',
    this.difficulty = '简单',
    this.calories,
    List<Ingredient>? ingredients,
    List<String>? steps,
    this.tip = '',
    this.fav = false,
    this.ateCount = 0,
    this.lastAteAt = '',
    DateTime? createdAt,
  })  : ingredients = ingredients ?? [],
        steps = steps ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'] ?? '🍳',
        meal: j['meal'] ?? '家常菜',
        difficulty: j['difficulty'] ?? '简单',
        calories: j['calories'] != null ? (j['calories'] as num).toInt() : null,
        ingredients: (j['ingredients'] as List?)?.map((e) => Ingredient.fromJson(e)).toList() ?? [],
        steps: (j['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
        tip: j['tip'] ?? '',
        fav: j['fav'] ?? false,
        ateCount: (j['ateCount'] ?? 0) as int,
        lastAteAt: j['lastAteAt'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'meal': meal,
        'difficulty': difficulty,
        'calories': calories,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps,
        'tip': tip,
        'fav': fav,
        'ateCount': ateCount,
        'lastAteAt': lastAteAt,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ---------------- 聊天 ----------------

/// 送达状态：0 发送中 / 1 已送达 / 2 已读 / 3 失败
enum MsgStatus { sending, delivered, read, failed }

class ChatMessage {
  final String id;
  final bool fromMe;
  String type; // 'text' / 'emoji' / 'card'
  String text; // 文本或表情 emoji
  String cardKind; // 'todo' / 'bill' / 'recipe' / 'countdown'
  Map<String, dynamic> cardPayload; // 卡片内容快照
  DateTime time;
  MsgStatus status;

  ChatMessage({
    required this.id,
    required this.fromMe,
    this.type = 'text',
    this.text = '',
    this.cardKind = '',
    Map<String, dynamic>? cardPayload,
    DateTime? time,
    this.status = MsgStatus.sending,
  })  : cardPayload = cardPayload ?? {},
        time = time ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        fromMe: j['fromMe'] ?? true,
        type: j['type'] ?? 'text',
        text: j['text'] ?? '',
        cardKind: j['cardKind'] ?? '',
        cardPayload: (j['cardPayload'] as Map?)?.cast<String, dynamic>() ?? {},
        time: DateTime.tryParse(j['time'].toString()) ?? DateTime.now(),
        status: MsgStatus.values[(j['status'] ?? 1) as int],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromMe': fromMe,
        'type': type,
        'text': text,
        'cardKind': cardKind,
        'cardPayload': cardPayload,
        'time': time.toIso8601String(),
        'status': status.index,
      };
}

// ---------------- 格言 ----------------

class Quote {
  final String zh;
  final String en;
  const Quote(this.zh, this.en);
}

// ---------------- 身高体重 ----------------

class HealthRecord {
  final String id;
  String date; // 'yyyy-MM-dd'
  double? heightCm; // 80 - 230，可空（只记体重）
  double weightKg; // 10 - 300
  final DateTime createdAt;

  HealthRecord({
    required this.id,
    required this.date,
    this.heightCm,
    required this.weightKg,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double? get bmi {
    final h = heightCm;
    if (h == null || h <= 0) return null;
    return double.parse((weightKg / ((h / 100) * (h / 100))).toStringAsFixed(1));
  }

  factory HealthRecord.fromJson(Map<String, dynamic> j) => HealthRecord(
        id: j['id'],
        date: j['date'],
        heightCm: j['heightCm'] != null ? (j['heightCm'] as num).toDouble() : null,
        weightKg: (j['weightKg'] as num).toDouble(),
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ---------------- 运动打卡 ----------------

class WorkoutType {
  final String key;
  final String name;
  final String emoji;
  final double met; // 代谢当量，用于估算千卡
  const WorkoutType(this.key, this.name, this.emoji, this.met);
}

const workoutTypes = <WorkoutType>[
  WorkoutType('run', '跑步', '🏃', 8.0),
  WorkoutType('walk', '快走', '🚶', 4.3),
  WorkoutType('jump', '跳绳', '🤸', 11.0),
  WorkoutType('cycle', '骑行', '🚴', 6.8),
  WorkoutType('swim', '游泳', '🏊', 6.0),
  WorkoutType('yoga', '瑜伽', '🧘', 2.5),
  WorkoutType('strength', '力量训练', '🏋️', 5.0),
  WorkoutType('badminton', '羽毛球', '🏸', 5.5),
  WorkoutType('basketball', '篮球', '🏀', 6.5),
  WorkoutType('hike', '徒步', '🥾', 5.3),
  WorkoutType('other', '其他', '✨', 4.0),
];

WorkoutType workoutTypeOf(String key) =>
    workoutTypes.firstWhere((t) => t.key == key, orElse: () => workoutTypes.last);

class WorkoutRecord {
  final String id;
  String date; // 'yyyy-MM-dd'
  String typeKey;
  int minutes; // 1 - 600
  double calories; // 估算千卡
  String note; // 0-30 字
  final DateTime createdAt;

  WorkoutRecord({
    required this.id,
    required this.date,
    required this.typeKey,
    required this.minutes,
    required this.calories,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WorkoutRecord.fromJson(Map<String, dynamic> j) => WorkoutRecord(
        id: j['id'],
        date: j['date'],
        typeKey: j['typeKey'] ?? 'other',
        minutes: (j['minutes'] ?? 0) as int,
        calories: (j['calories'] ?? 0).toDouble(),
        note: j['note'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'typeKey': typeKey,
        'minutes': minutes,
        'calories': calories,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ---------------- 背单词 ----------------

class WordItem {
  final String word;
  String phonetic;
  String meaning;

  WordItem(this.word, this.phonetic, this.meaning);

  factory WordItem.fromJson(Map<String, dynamic> j) =>
      WordItem(j['word'] ?? '', j['phonetic'] ?? '', j['meaning'] ?? '');

  Map<String, dynamic> toJson() => {'word': word, 'phonetic': phonetic, 'meaning': meaning};
}

// ---------------- 食物识别 ----------------

class FoodScan {
  final String id;
  String date; // 'yyyy-MM-dd'
  String name; // 识别出的食物名
  int calories; // 估算千卡
  String note; // 份量说明等
  final DateTime createdAt;

  FoodScan({
    required this.id,
    required this.date,
    required this.name,
    required this.calories,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FoodScan.fromJson(Map<String, dynamic> j) => FoodScan(
        id: j['id'],
        date: j['date'],
        name: j['name'] ?? '',
        calories: (j['calories'] ?? 0) as int,
        note: j['note'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'name': name,
        'calories': calories,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ---------------- 音乐 ----------------

class MusicTrack {
  final String id;
  String title;
  String path; // 本地文件路径
  final DateTime createdAt;

  MusicTrack({required this.id, required this.title, required this.path, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  factory MusicTrack.fromJson(Map<String, dynamic> j) => MusicTrack(
        id: j['id'],
        title: j['title'] ?? '未知曲目',
        path: j['path'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'path': path, 'createdAt': createdAt.toIso8601String()};
}
