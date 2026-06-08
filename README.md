# AI 助手 — 类豆包 AI 对话 + 定时任务

一个 Flutter 实现的 AI 对话助手 App，支持预设任务定时执行。

## 功能

- 🤖 **AI 对话**：多模型支持（OpenAI / Claude / 通义千问等），流式输出
- 🎤 **语音交互**：语音输入 + TTS 语音回复
- ⏰ **定时任务**：预设任务让 AI 定时执行，支持多种触发方式
- 📋 **会话管理**：多会话、历史记录
- 🎨 **主题切换**：浅色/深色/跟随系统

## 开始使用

### 前置条件

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0

### 安装

```bash
cd ai_assistant_app
flutter pub get
```

### 代码生成

该项目使用 `freezed` 生成数据类。在修改 model 文件后需要重新生成：

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行

```bash
flutter run
```

### 配置 API Key

首次使用需要在「设置 → API 配置」中填入你的 AI API Key。

支持的提供商：
- OpenAI (GPT-4o, GPT-4o-mini 等)
- Claude (Sonnet, Haiku)
- Gemini (Pro, Flash)
- DeepSeek
- 通义千问
- 文心一言
- 自定义 (兼容 OpenAI API 格式的任意服务)

## 项目结构

```
lib/
├── main.dart                    # 入口
├── core/
│   ├── constants.dart           # 常量
│   ├── theme.dart               # 主题
│   ├── router.dart              # 路由
│   └── settings_provider.dart   # 设置状态
├── database/
│   └── isar_service.dart        # 数据库封装
├── chat/
│   ├── models/
│   │   ├── conversation.dart    # 会话模型
│   │   └── message.dart         # 消息模型
│   ├── providers/
│   │   └── chat_provider.dart   # 对话状态
│   ├── services/
│   │   ├── chat_service.dart    # AI 对话服务
│   │   └── sse_stream_parser.dart # SSE 流解析
│   └── ui/                      # 预留 UI 目录
├── tasks/
│   ├── models/
│   │   └── ai_task.dart         # 任务模型
│   ├── providers/
│   │   └── task_provider.dart   # 任务状态
│   ├── services/
│   │   └── task_executor.dart   # 任务执行器
│   └── ui/                      # 预留 UI 目录
├── voice/
│   ├── services/                # 语音服务
│   └── ui/                      # 预留 UI 目录
├── settings/
│   ├── providers/               # 预留
│   └── ui/                      # 预留
└── shared/
    └── widgets/
        ├── home_screen.dart         # 主页面 (Tabs)
        ├── conversation_list_screen.dart # 历史会话
        ├── task_list_screen.dart     # 任务列表 + 编辑器
        └── settings_screen.dart      # 设置页面
```

## 架构

- **状态管理**: Riverpod (StateNotifier + FutureProvider)
- **数据库**: Isar (本地 NoSQL，支持全文搜索)
- **AI 接口**: Dio + SSE 流式解析 (支持 Function Calling)
- **任务调度**: WorkManager (Android 原生定时任务)
- **通知**: flutter_local_notifications
- **语音**: speech_to_text + flutter_tts
- **代码生成**: freezed (不可变数据类)

## 定时任务保活策略

Android 系统对后台任务有严格限制。本 App 采用以下策略确保任务可靠执行：

1. **WorkManager**: Google 官方方案，适配 Doze 省电
2. **前台服务**: 执行任务时显示常驻通知
3. **白名单引导**: 提示用户将 App 加入电池优化白名单

## License

MIT
