import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../chat/models/conversation.dart';
import '../chat/models/message.dart';
import '../tasks/models/ai_task.dart';

/// 本地 JSON 文件数据库 — 零依赖，无需代码生成
class DatabaseService {
  static DatabaseService? _instance;
  late String _basePath;

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = DatabaseService._();
    await _instance._init();
    return _instance!;
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _basePath = '${dir.path}/ai_assistant_db';
    await Directory(_basePath).create(recursive: true);
    await Directory('$_basePath/conversations').create(recursive: true);
    await Directory('$_basePath/messages').create(recursive: true);
    await Directory('$_basePath/tasks').create(recursive: true);
  }

  String get basePath => _basePath;

  // ========== 会话 CRUD ==========

  Future<void> saveConversation(Conversation conv) async {
    final file = File('$_basePath/conversations/${conv.id}.json');
    await file.writeAsString(
      jsonEncode(conv.copyWith(updatedAt: DateTime.now()).toJson()),
    );
  }

  Future<List<Conversation>> getConversations({bool includeArchived = false}) async {
    final dir = Directory('$_basePath/conversations');
    final files = dir.listSync().whereType<File>().toList();

    final conversations = <Conversation>[];
    for (final file in files) {
      try {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final conv = Conversation.fromJson(json);
        if (!includeArchived && conv.isArchived) continue;
        conversations.add(conv);
      } catch (_) {}
    }

    // 按更新时间排序
    conversations.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  Future<Conversation?> getConversation(String id) async {
    final file = File('$_basePath/conversations/$id.json');
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Conversation.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteConversation(String id) async {
    // 删除会话文件
    await File('$_basePath/conversations/$id.json').delete().catchError((_) {});
    // 删除关联消息
    final msgDir = Directory('$_basePath/messages');
    if (await msgDir.exists()) {
      final files = msgDir.listSync().whereType<File>();
      for (final file in files) {
        if (file.path.contains(id)) {
          await file.delete().catchError((_) {});
        }
      }
    }
  }

  // ========== 消息 CRUD ==========

  Future<void> saveMessage(Message msg) async {
    final file = File('$_basePath/messages/${msg.conversationId}_${msg.id}.json');
    await file.writeAsString(jsonEncode(msg.toJson()));
  }

  Future<List<Message>> getMessages(String conversationId,
      {int page = 0, int pageSize = 50}) async {
    final dir = Directory('$_basePath/messages');
    if (!await dir.exists()) return [];

    final files = dir.listSync().whereType<File>().where(
        (f) => f.path.contains(conversationId)).toList();

    final messages = <Message>[];
    for (final file in files) {
      try {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        messages.add(Message.fromJson(json));
      } catch (_) {}
    }

    // 按时间排序（最新的在前）
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 分页
    final start = page * pageSize;
    if (start >= messages.length) return [];
    final end = (start + pageSize).clamp(0, messages.length);
    return messages.sublist(start, end);
  }

  Future<int> getMessageCount(String conversationId) async {
    final msgs = await getMessages(conversationId);
    return msgs.length;
  }

  // ========== 任务 CRUD ==========

  Future<void> saveTask(AiTask task) async {
    final file = File('$_basePath/tasks/${task.id}.json');
    await file.writeAsString(
      jsonEncode(task.copyWith(updatedAt: DateTime.now()).toJson()),
    );
  }

  Future<List<AiTask>> getTasks({TaskStatus? status}) async {
    final dir = Directory('$_basePath/tasks');
    if (!await dir.exists()) return [];

    final files = dir.listSync().whereType<File>().toList();
    final tasks = <AiTask>[];

    for (final file in files) {
      try {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final task = AiTask.fromJson(json);
        if (status == null || task.status == status) {
          tasks.add(task);
        }
      } catch (_) {}
    }

    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  Future<List<AiTask>> getActiveTasks() async {
    return getTasks(status: TaskStatus.active);
  }

  Future<AiTask?> getTask(String id) async {
    final file = File('$_basePath/tasks/$id.json');
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return AiTask.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteTask(String id) async {
    await File('$_basePath/tasks/$id.json').delete().catchError((_) {});
  }
}
