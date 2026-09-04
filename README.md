# 小窝工作台 🏠

两个人一起用的生活管理工作台：欢迎页、桌面仪表盘、待办、记账、课表、倒数日、食谱、双人聊天、我的。
依据《小窝工作台 App 产品需求文档 V1.0》开发，界面与 PRD 交互原型一致。

## 运行方式

本仓库提供 `lib/` 源码与 `pubspec.yaml`，首次使用需要先生成平台壳工程：

```bash
# 1. 确认 Flutter SDK（3.x）已安装：flutter --version
cd workbench-app

# 2. 生成 Android / iOS 平台目录（lib 与 pubspec 不会被覆盖）
#    聊天模块依赖环信 SDK，仅支持 Android / iOS，不再生成 web
flutter create . --platforms android,ios --project-name workbench_app

# 3. 拉取依赖
flutter pub get

# 4. 运行
flutter run                    # 连接的手机 / 模拟器
flutter build apk --release    # 打 release 包发给自己和小伙伴
```

> 提示：Android Studio 打开本目录后，直接点 Run 也可以（首次会自动执行上面第 2、3 步）。

### Android 平台注意

- `android/app/build.gradle` 的 `defaultConfig` 中 `minSdkVersion` 需 ≥ 21（新版 Flutter 默认满足）。
- `android/app/src/main/AndroidManifest.xml` 的 `<manifest>` 节点内确认有网络权限（模板默认已有，若没有请补上）：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

- 打 release 包时在 `android/app/proguard-rules.pro` 添加环信免混淆规则：

```
-keep class com.hyphenate.** {*;}
-dontwarn com.hyphenate.**
```

## 聊天真实互通（环信 IM）

聊天模块通过 `ChatTransport` 接口解耦，内置两种实现：

- `LocalEchoTransport`（本地演示）：不配置账号时的默认模式，发送后"小伙伴"自动回复，用于单机体验。
- `RemoteChatTransport`（环信远程）：配置账号后启用，两台手机真实互通；文本、窝窝表情、卡片分享
  （待办 / 账单 / 食谱 / 倒数日）全部走环信服务器，表情和卡片使用自定义消息（`wb_emoji` / `wb_card` 事件）。

AppKey 已内置在 `lib/core/app_config.dart`。开通步骤：

1. 登录[环信控制台](https://console.easemob.com/user/login)，找到你的应用（AppKey `1120260904193646#zyx`）。
2. 在「用户管理 → 创建用户」里创建**两个**用户：你和小伙伴各一个（记住用户 ID 和密码）。
3. 各自手机上：App「我的 → 聊天互通设置」填入**自己的**账号 ID、密码和**对方的**账号 ID，点「保存并连接」。
4. 连接成功后聊天页头部徽标变为「已连接」，消息实时互通；进入聊天页时会自动重试断开的连接。

> 账号信息只保存在各自手机本地，不会随「数据导出」备份出去，两台设备互不干扰。免费版 100 用户额度对双人使用绰绰有余。

## V1.0 已实现范围

| 模块 | 说明 |
|------|------|
| 欢迎页 | 昵称问候、随机寄语、日期星期、进入动效；可在「我的」关闭 |
| 桌面仪表盘 | 时段问候 + 分钟级时钟、每日格言（收藏 / 每日限换 3 次）、每日打卡（连续天数）、今日概览四切片跳转 |
| 待办 | 快捷日期胶囊、三档优先级、过期置顶、已完成折叠、删除撤销 |
| 记账 | 支出 8 类 / 收入 4 类、月份切换、收入支出结余三卡、明细倒序、删除撤销 |
| 课表 | 学期周数自动计算、周视图（今日列高亮 / 跨节合并 / 单双周 / 周次过滤）、今日视图、冲突提示、6 色色板 |
| 倒数日 | 大数字倒数、置顶、每年重复、今天高亮、过期沉底、两人共享标识 |
| 食谱 | 卡片流、搜索（菜名 / 食材）、收藏 / 做过筛选、随机「今天吃什么」轮转动效、做过次数累计 |
| 聊天 | 固定双人会话、按天分组气泡、窝窝表情包、送达状态、卡片分享（待办 / 账单 / 食谱 / 倒数日 → 聊天气泡）、未读角标；环信远程互通 + 本地演示双模式 |
| 我的 | 资料与备注名、四套主题色即时切换、聊天互通设置（环信账号）、打卡项管理、格言库与寄语池、学期设置（含节次时间）、数据导出 / 恢复（剪贴板 JSON）、按模块清空 |

## 本地模式说明（重要）

数据全部保存在设备本地（`shared_preferences`，JSON 存储）；聊天模块在环信远程模式之外仍保留本地演示实现
（`LocalEchoTransport`），未配置账号时可单机体验完整交互。消息记录同样以本地为准（环信漫游消息可作后续增强）。

## 数据与备份

- 全部数据为单份 JSON 快照：自动保存（每次操作后即时落盘）。
- 「我的 → 数据导出与备份」一键复制完整 JSON（剪贴板），换机 / 备份时粘贴到「从备份恢复」即可还原。
- 「清空数据」按模块单独清空或全部清空，需输入「清空」二字确认。

## 后续版本计划（见 PRD 第 6 章）

- V1.1：环信消息漫游同步、共享倒数日与资料同步、本地推送提醒、图片消息与食谱封面。
- V1.2：邀请码配对流程、上架商店、多设备登录。
