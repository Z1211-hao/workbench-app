import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';
import 'chat_transport.dart';
import 'models.dart';
import 'remote_chat_transport.dart';
import 'seed.dart';
import 'theme.dart';
import 'util.dart';
import 'words_data.dart';

/// 全局状态与业务逻辑：本地优先，每次变更即时落盘（shared_preferences 单 JSON 快照）。
class AppStore extends ChangeNotifier {
  static const _storageKey = 'wb_data_v1';

  final SharedPreferences _prefs;
  ChatTransport _transport = LocalEchoTransport();

  Profile profile = Profile();
  AppSettings settings = AppSettings();
  Term term = Term();
  List<CheckinItem> checkinItems = [];
  Map<String, List<String>> checkinDone = {}; // dateKey -> 完成的 itemIds
  List<Todo> todos = [];
  List<Bill> bills = [];
  List<Course> courses = [];
  List<Countdown> countdowns = [];
  List<Recipe> recipes = [];
  List<ChatMessage> messages = [];
  List<String> customMottos = [];
  Set<String> favoredQuotes = {};
  // 扩展模块数据（V1.1）
  List<HealthRecord> healthRecords = [];
  List<WorkoutRecord> workouts = [];
  Map<String, int> pomodoroLog = {}; // dateKey -> 完成专注数
  Map<String, int> wordStatus = {}; // word -> 0 未学 / 1 学习中 / 2 已掌握
  List<String> wordDoneToday = []; // 今日已学单词
  String wordDoneDate = '';
  List<WordItem> customWords = [];
  List<FoodScan> foodScans = [];
  Map<String, int> gameScores = {}; // 'match' / 'tetris' -> 最高分
  List<MusicTrack> musicTracks = [];
  // AI 识别配置（本机持久化；不进导出备份，避免密钥外泄）
  String aiApiKey = '';
  String aiBaseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
  String aiModel = 'qwen-vl-plus';

  // 每日格言：今日种子格言 + 手动换（每日限 3 次）
  String _quoteOverride = '';
  int _quoteSwaps = 0;
  String _quoteSwapDate = '';

  int chatUnread = 0;
  int currentTab = 0; // 0 桌面 1 待办 2 记账 3 课表 4 倒数日 5 食谱 6 聊天 7 我的

  // 环信账号（本机持久化；不进导出备份，避免两台设备互相覆盖登录身份）
  String chatMyId = '';
  String chatMyPwd = '';
  String chatPartnerId = '';
  bool chatRemoteReady = false; // 运行时状态：远程传输层是否已登录
  bool _reconnecting = false; // 重连进行中标记（防并发登录）

  /// 本次会话是否已从欢迎页进入工作台（不持久化）
  bool entered = false;

  void enterApp() {
    entered = true;
    notifyListeners();
  }

  /// 记账页查看月份（null = 当前月）
  DateTime? accountMonth;

  AppStore(this._prefs) {
    _load();
    _initChatTransport();
  }

  // ---------------- 持久化 ----------------

  void _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _seedFirstRun();
      return;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      profile = Profile.fromJson(j['profile'] ?? {});
      settings = AppSettings.fromJson(j['settings'] ?? {});
      term = Term.fromJson(j['term'] ?? {});
      checkinItems = (j['checkinItems'] as List?)?.map((e) => CheckinItem.fromJson(e)).toList() ?? [];
      checkinDone = ((j['checkinDone'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()));
      todos = (j['todos'] as List?)?.map((e) => Todo.fromJson(e)).toList() ?? [];
      bills = (j['bills'] as List?)?.map((e) => Bill.fromJson(e)).toList() ?? [];
      courses = (j['courses'] as List?)?.map((e) => Course.fromJson(e)).toList() ?? [];
      countdowns = (j['countdowns'] as List?)?.map((e) => Countdown.fromJson(e)).toList() ?? [];
      recipes = (j['recipes'] as List?)?.map((e) => Recipe.fromJson(e)).toList() ?? [];
      messages = (j['messages'] as List?)?.map((e) => ChatMessage.fromJson(e)).toList() ?? [];
      customMottos = (j['customMottos'] as List?)?.map((e) => e.toString()).toList() ?? [];
      favoredQuotes = (j['favoredQuotes'] as List?)?.map((e) => e.toString()).toSet() ?? {};
      _quoteOverride = j['quoteOverride'] ?? '';
      _quoteSwaps = (j['quoteSwaps'] ?? 0) as int;
      _quoteSwapDate = j['quoteSwapDate'] ?? '';
      chatUnread = (j['chatUnread'] ?? 0) as int;
      chatMyId = j['chatMyId'] ?? '';
      chatMyPwd = j['chatMyPwd'] ?? '';
      chatPartnerId = j['chatPartnerId'] ?? '';
      healthRecords = (j['healthRecords'] as List?)?.map((e) => HealthRecord.fromJson(e)).toList() ?? [];
      workouts = (j['workouts'] as List?)?.map((e) => WorkoutRecord.fromJson(e)).toList() ?? [];
      pomodoroLog = ((j['pomodoroLog'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      wordStatus = ((j['wordStatus'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      wordDoneToday = (j['wordDoneToday'] as List?)?.map((e) => e.toString()).toList() ?? [];
      wordDoneDate = j['wordDoneDate'] ?? '';
      customWords = (j['customWords'] as List?)?.map((e) => WordItem.fromJson(e)).toList() ?? [];
      foodScans = (j['foodScans'] as List?)?.map((e) => FoodScan.fromJson(e)).toList() ?? [];
      gameScores = ((j['gameScores'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      musicTracks = (j['musicTracks'] as List?)?.map((e) => MusicTrack.fromJson(e)).toList() ?? [];
      aiApiKey = j['aiApiKey'] ?? '';
      aiBaseUrl = j['aiBaseUrl'] ?? 'https://dashscope.aliyuncs.com/compatible-mode/v1';
      aiModel = j['aiModel'] ?? 'qwen-vl-plus';
    } catch (_) {
      _seedFirstRun();
    }
  }

  void _seedFirstRun() {
    checkinItems = seedCheckinItems();
    todos = seedTodos();
    bills = seedBills();
    courses = seedCourses();
    countdowns = seedCountdowns();
    recipes = seedRecipes();
    messages = seedMessages();
    term = Term(startDate: dateKey(today()), totalWeeks: 20);
    _save();
  }

  void _save() {
    final j = {
      'profile': profile.toJson(),
      'settings': settings.toJson(),
      'term': term.toJson(),
      'checkinItems': checkinItems.map((e) => e.toJson()).toList(),
      'checkinDone': checkinDone,
      'todos': todos.map((e) => e.toJson()).toList(),
      'bills': bills.map((e) => e.toJson()).toList(),
      'courses': courses.map((e) => e.toJson()).toList(),
      'countdowns': countdowns.map((e) => e.toJson()).toList(),
      'recipes': recipes.map((e) => e.toJson()).toList(),
      'messages': messages.map((e) => e.toJson()).toList(),
      'customMottos': customMottos,
      'favoredQuotes': favoredQuotes.toList(),
      'quoteOverride': _quoteOverride,
      'quoteSwaps': _quoteSwaps,
      'quoteSwapDate': _quoteSwapDate,
      'chatUnread': chatUnread,
      'chatMyId': chatMyId,
      'chatMyPwd': chatMyPwd,
      'chatPartnerId': chatPartnerId,
      'healthRecords': healthRecords.map((e) => e.toJson()).toList(),
      'workouts': workouts.map((e) => e.toJson()).toList(),
      'pomodoroLog': pomodoroLog,
      'wordStatus': wordStatus,
      'wordDoneToday': wordDoneToday,
      'wordDoneDate': wordDoneDate,
      'customWords': customWords.map((e) => e.toJson()).toList(),
      'foodScans': foodScans.map((e) => e.toJson()).toList(),
      'gameScores': gameScores,
      'musicTracks': musicTracks.map((e) => e.toJson()).toList(),
      'aiApiKey': aiApiKey,
      'aiBaseUrl': aiBaseUrl,
      'aiModel': aiModel,
    };
    _prefs.setString(_storageKey, jsonEncode(j));
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  // ---------------- 导航 ----------------

  void goToTab(int i) {
    currentTab = i;
    notifyListeners();
    if (i == 6) {
      clearUnread();
      reconnectChat(); // 已配置远程但未连上时自动重试
    }
  }

  // ---------------- 每日格言 ----------------

  Quote get quoteOfDay {
    if (_quoteOverride.isNotEmpty) {
      final idx = builtInQuotes.indexWhere((q) => q.zh == _quoteOverride);
      if (idx >= 0) return builtInQuotes[idx];
    }
    final seed = daySeed(today());
    return builtInQuotes[seededRandom(seed, builtInQuotes.length)];
  }

  bool get canSwapQuote {
    final t = dateKey(today());
    return _quoteSwapDate != t || _quoteSwaps < 3;
  }

  int get quoteSwapsLeft {
    final t = dateKey(today());
    if (_quoteSwapDate != t) return 3;
    return (3 - _quoteSwaps).clamp(0, 3);
  }

  void swapQuote() {
    if (!canSwapQuote) return;
    final t = dateKey(today());
    if (_quoteSwapDate != t) {
      _quoteSwapDate = t;
      _quoteSwaps = 0;
    }
    _quoteSwaps++;
    final current = quoteOfDay.zh;
    Quote next;
    do {
      next = builtInQuotes[DateTime.now().microsecondsSinceEpoch % builtInQuotes.length];
    } while (next.zh == current && builtInQuotes.length > 1);
    _quoteOverride = next.zh;
    _changed();
  }

  bool isQuoteFavored(Quote q) => favoredQuotes.contains(q.zh);

  void toggleQuoteFav(Quote q) {
    if (favoredQuotes.contains(q.zh)) {
      favoredQuotes.remove(q.zh);
    } else {
      if (favoredQuotes.length >= 50) return;
      favoredQuotes.add(q.zh);
    }
    _changed();
  }

  // ---------------- 打卡 ----------------

  bool isDoneToday(CheckinItem item) => (checkinDone[dateKey(today())] ?? []).contains(item.id);

  bool get allCheckinDone => checkinItems.isNotEmpty && checkinItems.every(isDoneToday);

  bool _allDoneOn(DateTime d) {
    if (checkinItems.isEmpty) return false;
    final done = checkinDone[dateKey(d)] ?? [];
    return checkinItems.every((i) => done.contains(i.id));
  }

  /// 连续全部完成打卡的自然日天数
  int get checkinStreak {
    var s = 0;
    var d = today();
    if (!_allDoneOn(d)) d = addDays(d, -1);
    while (_allDoneOn(d)) {
      s++;
      d = addDays(d, -1);
    }
    return s;
  }

  void toggleCheckin(CheckinItem item) {
    final key = dateKey(today());
    final list = checkinDone.putIfAbsent(key, () => []);
    if (list.contains(item.id)) {
      list.remove(item.id);
    } else {
      list.add(item.id);
    }
    _changed();
  }

  void addCheckinItem(String name, String emoji) {
    if (name.isEmpty || checkinItems.length >= 10) return;
    checkinItems.add(CheckinItem(
      id: id(),
      name: name,
      emoji: emoji,
      sort: checkinItems.length + 1,
    ));
    _changed();
  }

  void updateCheckinItem(CheckinItem item, String name, String emoji) {
    item.name = name;
    item.emoji = emoji;
    _changed();
  }

  void deleteCheckinItem(CheckinItem item) {
    checkinItems.remove(item);
    for (final list in checkinDone.values) {
      list.remove(item.id);
    }
    _changed();
  }

  void moveCheckinItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= checkinItems.length) return;
    final item = checkinItems.removeAt(oldIndex);
    final clamped = newIndex.clamp(0, checkinItems.length);
    checkinItems.insert(clamped, item);
    for (var i = 0; i < checkinItems.length; i++) {
      checkinItems[i].sort = i + 1;
    }
    _changed();
  }

  // ---------------- 待办 ----------------

  List<Todo> get todayUndoneTodos {
    final t = dateKey(today());
    final list = todos.where((x) => !x.done && x.date.compareTo(t) <= 0).toList();
    list.sort((a, b) {
      if (a.overdue != b.overdue) return a.overdue ? -1 : 1; // 过期置顶
      if (a.priority != b.priority) return a.priority - b.priority;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  /// 日期大于今天的未完成待办，按日期由近到远
  List<Todo> get futureTodos {
    final t = dateKey(today());
    final list = todos.where((x) => !x.done && x.date.compareTo(t) > 0).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<Todo> get doneTodos {
    final list = todos.where((x) => x.done).toList();
    list.sort((a, b) => (b.doneAt ?? b.createdAt).compareTo(a.doneAt ?? a.createdAt));
    return list;
  }

  String? addTodo(String text, String date, int priority) {
    if (text.trim().isEmpty) return '要做什么呢，先写下来吧';
    final t = dateKey(today());
    if (date.compareTo(t) < 0) return '不能选过去的日期哦';
    final count = todos.where((x) => !x.done && x.date == date).length;
    if (count >= 99) return '今天的计划已经满啦';
    todos.add(Todo(id: id(), text: text.trim(), date: date, priority: priority));
    _changed();
    return null;
  }

  void toggleTodo(Todo t) {
    t.done = !t.done;
    t.doneAt = t.done ? DateTime.now() : null;
    _changed();
  }

  void deleteTodo(Todo t) {
    todos.remove(t);
    _changed();
  }

  void restoreTodo(Todo t) {
    todos.add(t);
    _changed();
  }

  // ---------------- 记账 ----------------

  DateTime get viewMonth => accountMonth ?? DateTime(today().year, today().month);

  void shiftMonth(int delta) {
    final m = viewMonth;
    accountMonth = DateTime(m.year, m.month + delta);
    notifyListeners();
  }

  bool _billInMonth(Bill b, DateTime month) {
    final d = parseDate(b.date);
    return d.year == month.year && d.month == month.month;
  }

  List<Bill> get billsOfViewMonth {
    final list = bills.where((b) => _billInMonth(b, viewMonth)).toList();
    list.sort((a, b) {
      final c = b.date.compareTo(a.date);
      if (c != 0) return c;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  double get monthIncome => bills
      .where((b) => _billInMonth(b, viewMonth) && b.type == 'in')
      .fold(0.0, (s, b) => s + b.amount);

  double get monthExpense => bills
      .where((b) => _billInMonth(b, viewMonth) && b.type == 'out')
      .fold(0.0, (s, b) => s + b.amount);

  double get monthBalance => monthIncome - monthExpense;

  String? addBill(String type, double amount, String category, String date, String note) {
    if (amount < 0.01) return '金额还没有填哦';
    if (amount > 99999.99) amount = 99999.99;
    final t = dateKey(today());
    if (date.compareTo(t) > 0) return '日期不能选未来哦';
    bills.add(Bill(
      id: id(),
      type: type,
      amount: double.parse(amount.toStringAsFixed(2)),
      category: category,
      date: date,
      note: note.trim(),
    ));
    _changed();
    return null;
  }

  void deleteBill(Bill b) {
    bills.remove(b);
    _changed();
  }

  void restoreBill(Bill b) {
    bills.add(b);
    _changed();
  }

  // ---------------- 课表 ----------------

  /// 当前周数：0 表示未设置学期或早于开学；-1 表示超过总周数（假期中）
  int get currentWeekNo {
    if (!term.isSet) return 0;
    final n = weekNoOf(today(), term.start);
    if (n < 1) return 0;
    if (n > term.totalWeeks) return -1;
    return n;
  }

  String get weekNoLabel {
    final n = currentWeekNo;
    if (n == 0) return '未开学';
    if (n == -1) return '假期中';
    return '第 $n 周';
  }

  List<Course> coursesOn(int weekday, int week) {
    if (week < 1) return [];
    return courses.where((c) => c.weekdays.contains(weekday) && c.coversWeek(week)).toList();
  }

  List<Course> get todayCourses {
    final list = coursesOn(today().weekday, currentWeekNo);
    list.sort((a, b) => a.startNode.compareTo(b.startNode));
    return list;
  }

  /// 学期是否处于展示范围（用于首页切片）
  bool get scheduleActive => currentWeekNo >= 1;

  static bool parityOverlap(int a, int b) {
    if (a == 0 || b == 0) return true;
    return a == b;
  }

  /// 与 candidate 时间冲突的已有课程（排除自身）
  List<Course> conflictsFor(Course candidate) {
    return courses.where((c) {
      if (c.id == candidate.id) return false;
      if (c.weekdays.toSet().intersection(candidate.weekdays.toSet()).isEmpty) return false;
      if (c.startNode > candidate.endNode || candidate.startNode > c.endNode) return false;
      if (c.weekStart > candidate.weekEnd || candidate.weekStart > c.weekEnd) return false;
      return parityOverlap(c.parity, candidate.parity);
    }).toList();
  }

  void addCourse(Course c) {
    if (courses.length >= 60) return;
    c.colorIndex = courses.length % coursePalette.length;
    courses.add(c);
    _changed();
  }

  void updateCourse(Course c) {
    final idx = courses.indexWhere((x) => x.id == c.id);
    if (idx >= 0) courses[idx] = c;
    _changed();
  }

  void deleteCourse(Course c) {
    courses.remove(c);
    _changed();
  }

  // ---------------- 倒数日 ----------------

  List<Countdown> get sortedCountdowns {
    final list = [...countdowns];
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final ar = a.remainDays, br = b.remainDays;
      final aPast = ar < 0, bPast = br < 0;
      if (aPast != bPast) return aPast ? 1 : -1;
      if (aPast && bPast) return br.compareTo(ar); // 刚过期的排前面
      return ar.compareTo(br);
    });
    return list;
  }

  Countdown? get nearestCountdown {
    Countdown? best;
    for (final c in countdowns) {
      if (c.remainDays < 0) continue;
      if (best == null || c.remainDays < best.remainDays) best = c;
    }
    return best;
  }

  String? addCountdown(String name, String date, String emoji, String category, {bool shared = false, bool repeatYearly = false}) {
    if (name.trim().isEmpty) return '给这个日子起个名字吧';
    countdowns.add(Countdown(
      id: id(),
      name: name.trim(),
      date: date,
      emoji: emoji,
      category: category,
      shared: shared,
      repeatYearly: repeatYearly,
    ));
    _changed();
    return null;
  }

  void toggleCountdownPin(Countdown c) {
    c.pinned = !c.pinned;
    _changed();
  }

  void deleteCountdown(Countdown c) {
    countdowns.remove(c);
    _changed();
  }

  // ---------------- 食谱 ----------------

  List<Recipe> filteredRecipes(String query, String filter) {
    Iterable<Recipe> list = recipes;
    if (filter == 'fav') list = list.where((r) => r.fav);
    if (filter == 'ate') list = list.where((r) => r.ateCount > 0);
    final q = query.trim();
    if (q.isNotEmpty) {
      list = list.where((r) =>
          r.name.contains(q) || r.ingredients.any((i) => i.name.contains(q)));
    }
    final result = list.toList();
    result.sort((a, b) {
      if (a.fav != b.fav) return a.fav ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  String? addRecipe(Recipe r) {
    if (r.name.trim().isEmpty) return '菜名还没有填哦';
    if (recipes.length >= 200) return '小本本写满啦';
    if (r.ingredients.isEmpty) return '至少写一样食材吧';
    if (r.steps.isEmpty) return '至少写一步做法吧';
    recipes.add(r);
    _changed();
    return null;
  }

  void toggleRecipeFav(Recipe r) {
    r.fav = !r.fav;
    _changed();
  }

  void markRecipeAte(Recipe r) {
    r.ateCount++;
    r.lastAteAt = dateKey(today());
    _changed();
  }

  void deleteRecipe(Recipe r) {
    recipes.remove(r);
    _changed();
  }

  // ---------------- 聊天（本地演示 / 环信远程互通） ----------------

  void _onIncoming(ChatMessage msg) {
    messages.add(msg);
    if (currentTab != 6) {
      chatUnread = chatUnread + 1 > 99 ? 99 : chatUnread + 1;
    }
    _changed();
  }

  /// 挂载传输层（调用方需先 dispose 旧传输层）
  void _attachTransport(ChatTransport t) {
    _transport = t;
    _transport.listen(_onIncoming);
  }

  RemoteChatTransport _makeRemoteTransport() => RemoteChatTransport(
        appKey: AppConfig.easemobAppKey,
        myId: chatMyId,
        myPwd: chatMyPwd,
        partnerId: chatPartnerId,
      );

  /// 启动时：已配置环信账号则连远程，否则用本地演示
  Future<void> _initChatTransport() async {
    if (chatMyId.isEmpty || chatMyPwd.isEmpty || chatPartnerId.isEmpty) {
      _attachTransport(_transport);
      return;
    }
    _transport.dispose();
    final remote = _makeRemoteTransport();
    final err = await remote.connect();
    chatRemoteReady = err == null;
    _attachTransport(remote);
    notifyListeners();
  }

  /// 配置并连接环信账号；返回 null 表示成功
  Future<String?> setChatAccount({required String myId, required String myPwd, required String partnerId}) async {
    final id = myId.trim(), pwd = myPwd.trim(), peer = partnerId.trim();
    if (id.isEmpty || pwd.isEmpty || peer.isEmpty) return '三个框都要填哦';
    _transport.dispose();
    final remote = RemoteChatTransport(
      appKey: AppConfig.easemobAppKey,
      myId: id,
      myPwd: pwd,
      partnerId: peer,
    );
    final err = await remote.connect();
    if (err != null) {
      _attachTransport(LocalEchoTransport());
      remote.dispose();
      return err;
    }
    chatMyId = id;
    chatMyPwd = pwd;
    chatPartnerId = peer;
    chatRemoteReady = true;
    _attachTransport(remote);
    _changed();
    return null;
  }

  /// 断开环信连接，回到本地演示模式
  void disconnectChatAccount() {
    _transport.dispose();
    chatMyId = '';
    chatMyPwd = '';
    chatPartnerId = '';
    chatRemoteReady = false;
    _attachTransport(LocalEchoTransport());
    _changed();
  }

  /// 已配置但未连上时重试（进入聊天页会自动触发）
  Future<void> reconnectChat() async {
    if (chatRemoteReady || chatMyId.isEmpty || chatMyPwd.isEmpty || chatPartnerId.isEmpty) return;
    if (_reconnecting) return;
    _reconnecting = true;
    try {
      _transport.dispose();
      final remote = _makeRemoteTransport();
      final err = await remote.connect();
      chatRemoteReady = err == null;
      _attachTransport(remote);
      notifyListeners();
    } finally {
      _reconnecting = false;
    }
  }

  void sendMessage({String type = 'text', String text = '', String cardKind = '', Map<String, dynamic>? cardPayload}) {
    final msg = ChatMessage(
      id: id(),
      fromMe: true,
      type: type,
      text: text,
      cardKind: cardKind,
      cardPayload: cardPayload,
      status: MsgStatus.sending,
    );
    messages.add(msg);
    _changed();

    _transport.deliver(msg).then((status) {
      if (messages.contains(msg)) {
        msg.status = status;
        _changed();
      }
    });
  }

  void clearUnread() {
    if (chatUnread != 0) {
      chatUnread = 0;
      _changed();
    }
    var changed = false;
    for (final m in messages) {
      if (!m.fromMe && m.status == MsgStatus.delivered) {
        m.status = MsgStatus.read;
        changed = true;
      }
    }
    if (changed) _changed();
  }

  void deleteMessage(ChatMessage m) {
    messages.remove(m);
    _changed();
  }

  // ---------------- 我的 / 资料 / 主题 ----------------

  void updateProfile({String? name, String? motto, String? avatar, String? partnerNote}) {
    if (name != null) profile.name = name.trim().isEmpty ? profile.name : name.trim();
    if (motto != null) profile.motto = motto.trim();
    if (avatar != null) profile.avatar = avatar;
    if (partnerNote != null) profile.partnerNote = partnerNote.trim();
    _changed();
  }

  String get partnerName => profile.partnerNote.isNotEmpty ? profile.partnerNote : '小伙伴';

  AppPalette get palette => paletteOf(profile.themeKey);

  void setTheme(String key) {
    profile.themeKey = key;
    _changed();
  }

  void toggleWelcome() {
    settings.showWelcome = !settings.showWelcome;
    _changed();
  }

  void toggleNotify() {
    settings.notifyOn = !settings.notifyOn;
    _changed();
  }

  void setTerm({required String startDate, required int totalWeeks, required List<String> nodeTimes}) {
    term.startDate = startDate;
    term.totalWeeks = totalWeeks;
    term.nodeTimes = nodeTimes;
    _changed();
  }

  // ---------------- 寄语池 ----------------

  List<String> get mottoPool => [...builtInMottos, ...customMottos];

  String get todayMotto {
    final pool = mottoPool;
    if (pool.isEmpty) return builtInMottos.first;
    return pool[seededRandom(daySeed(today()), pool.length)];
  }

  String? addCustomMotto(String text) {
    if (text.trim().isEmpty) return '写点什么吧';
    if (mottoPool.length >= 50) return '寄语池满啦（上限 50 条）';
    customMottos.add(text.trim());
    _changed();
    return null;
  }

  void removeCustomMotto(String text) {
    customMottos.remove(text);
    _changed();
  }

  // ---------------- 导出 / 恢复 / 清空 ----------------

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'workbench',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'profile': profile.toJson(),
        'settings': settings.toJson(),
        'term': term.toJson(),
        'checkinItems': checkinItems.map((e) => e.toJson()).toList(),
        'checkinDone': checkinDone,
        'todos': todos.map((e) => e.toJson()).toList(),
        'bills': bills.map((e) => e.toJson()).toList(),
        'courses': courses.map((e) => e.toJson()).toList(),
        'countdowns': countdowns.map((e) => e.toJson()).toList(),
        'recipes': recipes.map((e) => e.toJson()).toList(),
        'messages': messages.map((e) => e.toJson()).toList(),
        'customMottos': customMottos,
        'favoredQuotes': favoredQuotes.toList(),
        'healthRecords': healthRecords.map((e) => e.toJson()).toList(),
        'workouts': workouts.map((e) => e.toJson()).toList(),
        'pomodoroLog': pomodoroLog,
        'wordStatus': wordStatus,
        'wordDoneToday': wordDoneToday,
        'wordDoneDate': wordDoneDate,
        'customWords': customWords.map((e) => e.toJson()).toList(),
        'foodScans': foodScans.map((e) => e.toJson()).toList(),
        'gameScores': gameScores,
        'musicTracks': musicTracks.map((e) => e.toJson()).toList(),
      });

  /// 返回 null 表示成功，否则为错误提示
  String? importJson(String raw) {
    try {
      final j = jsonDecode(raw.trim());
      if (j is! Map<String, dynamic> || j['app'] != 'workbench') {
        return '这不是小窝工作台的备份文件';
      }
      profile = Profile.fromJson(j['profile'] ?? {});
      settings = AppSettings.fromJson(j['settings'] ?? {});
      term = Term.fromJson(j['term'] ?? {});
      checkinItems = (j['checkinItems'] as List?)?.map((e) => CheckinItem.fromJson(e)).toList() ?? [];
      checkinDone = ((j['checkinDone'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()));
      todos = (j['todos'] as List?)?.map((e) => Todo.fromJson(e)).toList() ?? [];
      bills = (j['bills'] as List?)?.map((e) => Bill.fromJson(e)).toList() ?? [];
      courses = (j['courses'] as List?)?.map((e) => Course.fromJson(e)).toList() ?? [];
      countdowns = (j['countdowns'] as List?)?.map((e) => Countdown.fromJson(e)).toList() ?? [];
      recipes = (j['recipes'] as List?)?.map((e) => Recipe.fromJson(e)).toList() ?? [];
      messages = (j['messages'] as List?)?.map((e) => ChatMessage.fromJson(e)).toList() ?? [];
      customMottos = (j['customMottos'] as List?)?.map((e) => e.toString()).toList() ?? [];
      favoredQuotes = (j['favoredQuotes'] as List?)?.map((e) => e.toString()).toSet() ?? {};
      _quoteOverride = j['quoteOverride'] ?? '';
      healthRecords = (j['healthRecords'] as List?)?.map((e) => HealthRecord.fromJson(e)).toList() ?? [];
      workouts = (j['workouts'] as List?)?.map((e) => WorkoutRecord.fromJson(e)).toList() ?? [];
      pomodoroLog = ((j['pomodoroLog'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      wordStatus = ((j['wordStatus'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      wordDoneToday = (j['wordDoneToday'] as List?)?.map((e) => e.toString()).toList() ?? [];
      wordDoneDate = j['wordDoneDate'] ?? '';
      customWords = (j['customWords'] as List?)?.map((e) => WordItem.fromJson(e)).toList() ?? [];
      foodScans = (j['foodScans'] as List?)?.map((e) => FoodScan.fromJson(e)).toList() ?? [];
      gameScores = ((j['gameScores'] ?? {}) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      musicTracks = (j['musicTracks'] as List?)?.map((e) => MusicTrack.fromJson(e)).toList() ?? [];
      _changed();
      return null;
    } catch (_) {
      return '备份内容好像不完整，检查一下再试试';
    }
  }

  /// 按模块清空：todo / bill / course / countdown / recipe / chat / checkin
  void clearModules(Set<String> modules) {
    if (modules.contains('todo')) todos = [];
    if (modules.contains('bill')) bills = [];
    if (modules.contains('course')) courses = [];
    if (modules.contains('countdown')) countdowns = [];
    if (modules.contains('recipe')) recipes = [];
    if (modules.contains('chat')) {
      messages = [];
      chatUnread = 0;
    }
    if (modules.contains('checkin')) {
      checkinItems = [];
      checkinDone = {};
    }
    if (modules.contains('health')) healthRecords = [];
    if (modules.contains('workout')) workouts = [];
    if (modules.contains('foodscan')) foodScans = [];
    if (modules.contains('music')) musicTracks = [];
    _changed();
  }

  // ---------------- 身高体重 ----------------

  /// 按日期倒序
  List<HealthRecord> get sortedHealthRecords {
    final list = [...healthRecords];
    list.sort((a, b) {
      final c = b.date.compareTo(a.date);
      if (c != 0) return c;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  double? get lastHeight {
    for (final r in sortedHealthRecords) {
      if (r.heightCm != null) return r.heightCm;
    }
    return null;
  }

  String? addHealthRecord(String date, double? heightCm, double weightKg) {
    if (weightKg < 10 || weightKg > 300) return '体重写 10~300 之间哦';
    if (heightCm != null && (heightCm < 80 || heightCm > 230)) return '身高写 80~230 之间哦';
    final t = dateKey(today());
    if (date.compareTo(t) > 0) return '日期不能选未来哦';
    // 同一天重复记录则覆盖当天（保持列表清爽）
    final idx = healthRecords.indexWhere((r) => r.date == date);
    if (idx >= 0) {
      healthRecords[idx].heightCm = heightCm;
      healthRecords[idx].weightKg = weightKg;
    } else {
      healthRecords.add(HealthRecord(id: id(), date: date, heightCm: heightCm, weightKg: weightKg));
    }
    _changed();
    return null;
  }

  void deleteHealthRecord(HealthRecord r) {
    healthRecords.remove(r);
    _changed();
  }

  // ---------------- 番茄钟 ----------------

  int get pomodoroToday => pomodoroLog[dateKey(today())] ?? 0;

  void addPomodoroDone() {
    final key = dateKey(today());
    pomodoroLog[key] = (pomodoroLog[key] ?? 0) + 1;
    _changed();
  }

  // ---------------- 背单词 ----------------

  List<WordItem> get allWords => [...builtInWords, ...customWords];

  int get wordMasteredCount => wordStatus.values.where((s) => s >= 2).length;

  int get wordTotalCount => allWords.length;

  /// 今日待学单词：未掌握（状态<2）且今日没学过的，按内置在前、自定义在后
  List<WordItem> get todaysWords {
    final t = dateKey(today());
    if (wordDoneDate != t) {
      wordDoneDate = t;
      wordDoneToday = [];
    }
    final done = wordDoneToday.toSet();
    return allWords.where((w) => (wordStatus[w.word] ?? 0) < 2 && !done.contains(w.word)).toList();
  }

  void recordWord(WordItem w, bool known) {
    final t = dateKey(today());
    if (wordDoneDate != t) {
      wordDoneDate = t;
      wordDoneToday = [];
    }
    final cur = wordStatus[w.word] ?? 0;
    wordStatus[w.word] = known ? (cur + 1).clamp(0, 2) : 0;
    if (!wordDoneToday.contains(w.word)) wordDoneToday.add(w.word);
    _changed();
  }

  String? addCustomWord(String word, String phonetic, String meaning) {
    final w = word.trim();
    if (w.isEmpty || meaning.trim().isEmpty) return '单词和释义都要填哦';
    if (allWords.any((x) => x.word.toLowerCase() == w.toLowerCase())) return '这个词已经在词库里啦';
    customWords.add(WordItem(w, phonetic.trim(), meaning.trim()));
    _changed();
    return null;
  }

  void deleteCustomWord(WordItem w) {
    customWords.remove(w);
    wordStatus.remove(w.word);
    wordDoneToday.remove(w.word);
    _changed();
  }

  // ---------------- 运动打卡 ----------------

  List<WorkoutRecord> get sortedWorkouts {
    final list = [...workouts];
    list.sort((a, b) {
      final c = b.date.compareTo(a.date);
      if (c != 0) return c;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  bool hasWorkoutOn(DateTime d) => workouts.any((w) => w.date == dateKey(d));

  /// 连续运动打卡的自然日天数
  int get workoutStreak {
    var s = 0;
    var d = today();
    if (!hasWorkoutOn(d)) d = addDays(d, -1);
    while (hasWorkoutOn(d)) {
      s++;
      d = addDays(d, -1);
    }
    return s;
  }

  int workoutMinutesInMonth(DateTime month) {
    var sum = 0;
    for (final w in workouts) {
      final d = parseDate(w.date);
      if (d.year == month.year && d.month == month.month) sum += w.minutes;
    }
    return sum;
  }

  double workoutCaloriesInMonth(DateTime month) {
    var sum = 0.0;
    for (final w in workouts) {
      final d = parseDate(w.date);
      if (d.year == month.year && d.month == month.month) sum += w.calories;
    }
    return sum;
  }

  int workoutDaysInMonth(DateTime month) {
    final days = <String>{};
    for (final w in workouts) {
      final d = parseDate(w.date);
      if (d.year == month.year && d.month == month.month) days.add(w.date);
    }
    return days.length;
  }

  /// 估算千卡 = MET × 体重(kg) × 小时
  double estimateCalories(String typeKey, int minutes, double? weightKg) {
    final w = weightKg ?? 60;
    return double.parse((workoutTypeOf(typeKey).met * w * (minutes / 60)).toStringAsFixed(0));
  }

  String? addWorkout(String date, String typeKey, int minutes, String note, {double? weightKg}) {
    if (minutes < 1 || minutes > 600) return '时长写 1~600 分钟哦';
    final t = dateKey(today());
    if (date.compareTo(t) > 0) return '日期不能选未来哦';
    final cal = estimateCalories(typeKey, minutes, weightKg ?? lastHeightWeight);
    workouts.add(WorkoutRecord(
      id: id(),
      date: date,
      typeKey: typeKey,
      minutes: minutes,
      calories: cal,
      note: note.trim(),
    ));
    _changed();
    return null;
  }

  double get lastHeightWeight {
    for (final r in sortedHealthRecords) {
      return r.weightKg;
    }
    return 60;
  }

  void deleteWorkout(WorkoutRecord w) {
    workouts.remove(w);
    _changed();
  }

  // ---------------- 食物识别 ----------------

  List<FoodScan> get sortedFoodScans {
    final list = [...foodScans];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void addFoodScan(String name, int calories, String note) {
    foodScans.add(FoodScan(
      id: id(),
      date: dateKey(today()),
      name: name,
      calories: calories,
      note: note,
    ));
    _changed();
  }

  void deleteFoodScan(FoodScan f) {
    foodScans.remove(f);
    _changed();
  }

  void setAiConfig({required String apiKey, required String baseUrl, required String model}) {
    aiApiKey = apiKey.trim();
    aiBaseUrl = baseUrl.trim().isEmpty ? 'https://dashscope.aliyuncs.com/compatible-mode/v1' : baseUrl.trim();
    aiModel = model.trim().isEmpty ? 'qwen-vl-plus' : model.trim();
    _changed();
  }

  // ---------------- 小游戏 ----------------

  int gameBest(String key) => gameScores[key] ?? 0;

  void setGameScore(String key, int score) {
    if (score > (gameScores[key] ?? 0)) {
      gameScores[key] = score;
      _changed();
    }
  }

  // ---------------- 音乐 ----------------

  void addMusicTrack(String title, String path) {
    if (musicTracks.any((t) => t.path == path)) return;
    musicTracks.add(MusicTrack(id: id(), title: title, path: path));
    _changed();
  }

  void removeMusicTrack(MusicTrack t) {
    musicTracks.remove(t);
    _changed();
  }

  @override
  void dispose() {
    _transport.dispose();
    super.dispose();
  }
}
