/// 内置静态数据 + 首次启动种子数据
library;

import 'models.dart';
import 'util.dart';

// ---------------- 内置格言库（每日格言） ----------------

const builtInQuotes = <Quote>[
  Quote('种一棵树最好的时间是十年前，其次是现在。', 'The best time to plant a tree was ten years ago. The second best time is now.'),
  Quote('慢慢来，比较快。', 'Slow and steady wins the race.'),
  Quote('你只管努力，剩下的交给时间。', 'Just do your best and let time do the rest.'),
  Quote('星光不问赶路人，时光不负有心人。', 'Time rewards those who keep walking.'),
  Quote('把日子过成诗，简单而精致。', 'Live simply, live beautifully.'),
  Quote('今天也要记得夸夸自己。', 'Remember to praise yourself today.'),
  Quote('生活明朗，万物可爱。', 'Life is bright and everything is lovely.'),
  Quote('凡是过往，皆为序章。', 'What is past is prologue.'),
  Quote('心之所向，素履以往。', 'Follow your heart, step by step.'),
  Quote('保持热爱，奔赴山海。', 'Stay passionate, chase the horizon.'),
  Quote('日拱一卒，功不唐捐。', 'One small step a day, nothing is wasted.'),
  Quote('热爱可抵岁月漫长。', 'Passion makes the long years worthwhile.'),
  Quote('所有的惊艳，都来自长久的努力。', 'Every shine comes from long effort.'),
  Quote('路虽远行则将至，事虽难做则必成。', 'A long road begins with a single step.'),
  Quote('有趣的人生，一半是山川湖海。', 'An interesting life is half mountains and seas.'),
  Quote('要善良，要勇敢，要像小星星一样努力发光。', 'Be kind, be brave, and shine like a little star.'),
  Quote('你的好运藏在你的实力里。', 'Your luck hides in your strength.'),
  Quote('满怀希望就会所向披靡。', 'Hope conquers everything.'),
  Quote('熬过无人问津的日子，才有诗和远方。', 'Quiet effort today, poetry and distance tomorrow.'),
  Quote('知足且坚定，温柔且上进。', 'Be content and firm, gentle and ambitious.'),
  Quote('与其临渊羡鱼，不如退而结网。', 'Better to weave a net than to envy the fish.'),
  Quote('命是弱者的借口，运是强者的谦辞。', 'Fate is the excuse of the weak, luck the modesty of the strong.'),
  Quote('凡是打不倒你的，终将使你更强大。', 'What does not kill you makes you stronger.'),
  Quote('世上无难事，只怕有心人。', 'Where there is a will, there is a way.'),
  Quote('不飞则已，一飞冲天。', 'A bird that does not fly soars when it does.'),
  Quote('宝剑锋从磨砺出，梅花香自苦寒来。', 'The sharper the grind, the sweeter the bloom.'),
  Quote('海纳百川，有容乃大。', 'The sea is vast because it welcomes all rivers.'),
  Quote('博观而约取，厚积而薄发。', 'Read widely, act wisely.'),
  Quote('非淡泊无以明志，非宁静无以致远。', 'Tranquility breeds achievement.'),
  Quote('长风破浪会有时，直挂云帆济沧海。', 'Someday I will ride the wind and break the waves.'),
  Quote('千里之行，始于足下。', 'A journey of a thousand miles begins with a single step.'),
  Quote('只要功夫深，铁杵磨成针。', 'With enough effort, an iron rod becomes a needle.'),
  Quote('精诚所至，金石为开。', 'Sincerity can move mountains.'),
  Quote('绳锯木断，水滴石穿。', 'Little strokes fell great oaks.'),
  Quote('天行健，君子以自强不息。', 'As nature moves ceaselessly, so should we.'),
  Quote('苔花如米小，也学牡丹开。', 'Even a tiny moss flower blooms like a peony.'),
  Quote('心中有丘壑，眉目作山河。', 'With valleys in heart, eyes become landscapes.'),
  Quote('愿你的眼中总有光芒，活成你想要的模样。', 'May your eyes always shine with your dreams.'),
  Quote('永远相信美好的事情即将发生。', 'Always believe something wonderful is about to happen.'),
  Quote('小步慢跑也没关系，重要的是一直在路上。', 'Small slow steps still count, as long as you keep walking.'),
];

// ---------------- 寄语池（欢迎页每日随机） ----------------

const builtInMottos = <String>[
  '慢慢来，一切都在变好',
  '今天也要记得夸夸自己',
  '你比你想象中更棒',
  '小小的一天，大大的可爱',
  '喝口水，休息一下眼睛吧',
  '今天的你也是闪闪发光的',
  '别着急，好运在排队呢',
  '记得吃早餐哦',
  '深呼吸，一切都会顺利',
  '今天适合睡个好觉',
  '把烦恼写成待办，一件件划掉',
  '遇见的都是天意，拥有的都是幸运',
  '保持热爱，奔赴山海',
  '小小的坚持，大大的能量',
  '今天的月亮也很可爱',
  '好好吃饭，好好睡觉',
  '所有美好都会如期而至',
  '做自己的小太阳',
  '慢慢变好，是给自己最好的礼物',
  '生活很甜，要慢慢品尝',
];

// ---------------- 记账分类 ----------------

const expenseCategories = <BillCategory>[
  BillCategory('food', '餐饮', '🍜'),
  BillCategory('traffic', '交通', '🚌'),
  BillCategory('shopping', '购物', '🛍'),
  BillCategory('fun', '娱乐', '🎬'),
  BillCategory('study', '学习', '📚'),
  BillCategory('home', '居住', '🏠'),
  BillCategory('medical', '医疗', '💊'),
  BillCategory('other', '其他', '📦'),
];

const incomeCategories = <BillCategory>[
  BillCategory('salary', '工资', '💰'),
  BillCategory('redpacket', '红包', '🧧'),
  BillCategory('parttime', '兼职', '💼'),
  BillCategory('otherIn', '其他', '🎁'),
];

List<BillCategory> categoriesOf(String type) =>
    type == 'in' ? incomeCategories : expenseCategories;

BillCategory categoryByKey(String key) {
  return [...expenseCategories, ...incomeCategories].firstWhere((c) => c.key == key,
      orElse: () => const BillCategory('other', '其他', '📦'));
}

// ---------------- 课表 ----------------

/// 6 色可爱色板（课程块背景）
const coursePalette = <List<int>>[
  [0xFFFFE4EC, 0xFFF7B8C8], // 粉
  [0xFFEFE7FC, 0xFFC9A7EE], // 紫
  [0xFFE2F5EC, 0xFF95D4B6], // 薄荷
  [0xFFFFF3D6, 0xFFFBD685], // 蜜黄
  [0xFFE4EFFA, 0xFF9DC2E8], // 雾蓝
  [0xFFFFE9E0, 0xFFF9B49A], // 珊瑚
];

const coursePaletteText = <int>[
  0xFFB0536C, // 粉
  0xFF7B5FC9, // 紫
  0xFF3D8A67, // 薄荷
  0xFFA67C1F, // 蜜黄
  0xFF4A78AE, // 雾蓝
  0xFFC2643C, // 珊瑚
];

// ---------------- 倒数日 ----------------

const countdownEmojis = <String>[
  '⭐', '🎂', '📝', '✈️', '💕', '🎓', '🎄', '🎉', '🏖', '🎈', '🏆', '🌈'
];

const countdownCategories = <String>['考试', '生日', '纪念日', '节日', '旅行', '其他'];

// ---------------- 食谱 ----------------

const mealOptions = <String>['早餐', '午餐', '晚餐', '加餐', '家常菜', '硬菜'];

const mealEmojis = <String, String>{
  '早餐': '🥐', '午餐': '🍱', '晚餐': '🍲', '加餐': '🍮', '家常菜': '🍳', '硬菜': '🥩',
};

const difficultyOptions = <String>['简单', '中等', '复杂'];

const recipeEmojis = <String>['🍳', '🥘', '🍜', '🍱', '🍲', '🥗', '🍰', '🥟', '🍤', '🍛', '🥞', '🍟'];

// ---------------- 头像 / 窝窝表情包 ----------------

const avatarOptions = <String>['🐻', '🐰', '🐱', '🐼', '🦊', '🐹'];

/// 内置 12 枚窝窝表情包（大图气泡发送）
const wowoStickers = <String>[
  '😊', '🥰', '🤗', '🥳', '🤤', '😪', '😭', '😤', '🙈', '🙌', '🤔', '💪'
];

/// 本地演示模式下「小伙伴」的自动回复池
const partnerReplies = <String>[
  '收到收到～',
  '好呀好呀 👀',
  '哈哈哈哈笑死我了',
  '嗯嗯，我看看',
  '好嘞，记下了！',
  '也是辛苦你啦 🤗',
  '晚上想吃什么？',
  '你说得对！',
  '等我忙完这阵～',
  '抱抱 🤗',
  '那必须的！',
  '好主意，就按你说的来',
];

// ---------------- 首次启动种子数据 ----------------

/// 首启动写入的示例数据：让每个模块一打开就有内容可体验。
/// 全部可在各模块或「我的-清空数据」中删除。
List<CheckinItem> seedCheckinItems() => [
      CheckinItem(id: 'ci1', name: '早起', emoji: '☀️', sort: 1),
      CheckinItem(id: 'ci2', name: '饮水', emoji: '💧', sort: 2),
      CheckinItem(id: 'ci3', name: '运动', emoji: '🧘', sort: 3),
      CheckinItem(id: 'ci4', name: '阅读', emoji: '📖', sort: 4),
      CheckinItem(id: 'ci5', name: '早睡', emoji: '🌙', sort: 5),
    ];

List<Todo> seedTodos() {
  final t = today();
  return [
    Todo(id: 'td1', text: '体验一下待办：点左边圆圈完成它', date: dateKey(t), priority: 0),
    Todo(id: 'td2', text: '去记账页面记一笔今天的午饭', date: dateKey(t), priority: 1),
    Todo(id: 'td3', text: '给「今天吃什么」抽个签', date: dateKey(addDays(t, 1)), priority: 2),
  ];
}

List<Bill> seedBills() {
  final t = today();
  return [
    Bill(id: 'bl1', type: 'out', amount: 15, category: 'food', date: dateKey(t), note: '食堂午饭'),
    Bill(id: 'bl2', type: 'out', amount: 6, category: 'traffic', date: dateKey(t), note: '地铁'),
    Bill(id: 'bl3', type: 'in', amount: 200, category: 'redpacket', date: dateKey(addDays(t, -1)), note: '来自小伙伴'),
  ];
}

List<Course> seedCourses() {
  return [
    Course(id: 'co1', name: '高等数学', weekdays: [1, 3], startNode: 1, endNode: 2, place: '教一 201', teacher: '王老师', colorIndex: 0),
    Course(id: 'co2', name: '大学英语', weekdays: [2, 4], startNode: 3, endNode: 3, place: '教二 105', teacher: '李老师', colorIndex: 4),
    Course(id: 'co3', name: '数据结构', weekdays: [3], startNode: 3, endNode: 4, place: '机房 3', teacher: '张老师', colorIndex: 1),
    Course(id: 'co4', name: '体育', weekdays: [5], startNode: 5, endNode: 5, place: '操场', teacher: '刘老师', colorIndex: 2),
    Course(id: 'co5', name: '毛概', weekdays: [1], startNode: 3, endNode: 3, place: '教三 402', teacher: '陈老师', colorIndex: 3),
  ];
}

List<Countdown> seedCountdowns() {
  final t = today();
  return [
    Countdown(id: 'cd1', name: '期末考试', date: dateKey(addDays(t, 60)), emoji: '📝', category: '考试', pinned: true),
    Countdown(id: 'cd2', name: '小伙伴的生日', date: dateKey(addDays(t, 25)), emoji: '🎂', category: '生日', shared: true, repeatYearly: true),
  ];
}

List<Recipe> seedRecipes() {
  return [
    Recipe(
      id: 'rp1',
      name: '番茄炒蛋',
      emoji: '🍳',
      meal: '家常菜',
      difficulty: '简单',
      calories: 280,
      ingredients: [Ingredient('番茄', '2 个'), Ingredient('鸡蛋', '3 个'), Ingredient('小葱', '1 根')],
      steps: ['番茄切块，鸡蛋打散加少许盐', '热锅倒油，蛋液炒至凝固盛出', '补一点油下番茄，炒出汁水', '倒回鸡蛋翻匀，撒盐和葱花出锅'],
      tip: '喜欢甜口可以加半勺糖提鲜',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Recipe(
      id: 'rp2',
      name: '奶油蘑菇意面',
      emoji: '🍝',
      meal: '晚餐',
      difficulty: '中等',
      calories: 520,
      ingredients: [Ingredient('意面', '100g'), Ingredient('蘑菇', '5 朵'), Ingredient('淡奶油', '100ml')],
      steps: ['意面煮至八分熟捞出', '黄油煎蘑菇至微焦', '倒入淡奶油小火煮稠', '拌入意面，加盐和黑胡椒'],
      tip: '留一勺煮面水拌酱会更顺滑',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Recipe(
      id: 'rp3',
      name: '紫菜蛋花汤',
      emoji: '🍲',
      meal: '晚餐',
      difficulty: '简单',
      calories: 90,
      ingredients: [Ingredient('紫菜', '一小把'), Ingredient('鸡蛋', '1 个'), Ingredient('虾皮', '少许')],
      steps: ['水烧开下紫菜和虾皮', '淋入蛋液搅出蛋花', '加盐和几滴香油关火'],
      tip: '蛋液沿筷子淋下去，蛋花会更漂亮',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Recipe(
      id: 'rp4',
      name: '蜂蜜吐司',
      emoji: '🥞',
      meal: '早餐',
      difficulty: '简单',
      calories: 240,
      ingredients: [Ingredient('吐司', '2 片'), Ingredient('蜂蜜', '适量'), Ingredient('黄油', '10g')],
      steps: ['黄油小火融化', '吐司两面煎至金黄', '淋蜂蜜，趁热吃'],
      createdAt: DateTime.now(),
    ),
  ];
}

List<ChatMessage> seedMessages() {
  final now = DateTime.now();
  return [
    ChatMessage(
      id: 'ms1',
      fromMe: false,
      type: 'text',
      text: '欢迎来到我们的小窝 🏠',
      time: now.subtract(const Duration(minutes: 30)),
      status: MsgStatus.read,
    ),
    ChatMessage(
      id: 'ms2',
      fromMe: false,
      type: 'text',
      text: '这里只有我们俩能看见，随便聊～',
      time: now.subtract(const Duration(minutes: 29)),
      status: MsgStatus.read,
    ),
    ChatMessage(
      id: 'ms3',
      fromMe: false,
      type: 'emoji',
      text: '🥰',
      time: now.subtract(const Duration(minutes: 28)),
      status: MsgStatus.read,
    ),
  ];
}
