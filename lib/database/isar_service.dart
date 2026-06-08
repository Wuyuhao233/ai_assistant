// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import '../chat/models/conversation.dart';
import '../chat/models/message.dart';
import '../tasks/models/ai_task.dart';

/// Isar 数据库封装 — 单例
class DatabaseService {
  static DatabaseService? _instance;
  late Isar _isar;

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = DatabaseService._();
    await _instance._init();
    return _instance!;
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ConversationSchema, MessageSchema, AiTaskSchema],
      directory: dir.path,
      name: 'ai_assistant',
    );
  }

  Isar get db => _isar;

  // ========== 会话 CRUD ==========

  Future<void> saveConversation(Conversation conv) async {
    await _isar.writeTxn(() async {
      await _isar.conversations.put(conv.copyWith(
        updatedAt: DateTime.now(),
      ));
    });
  }

  Future<List<Conversation>> getConversations({bool includeArchived = false}) async {
    final query = _isar.conversations.where();
    if (!includeArchived) {
      return query.filter().isArchivedEqualTo(false).sortByUpdatedAtDesc().findAll();
    }
    return query.sortByUpdatedAtDesc().findAll();
  }

  Future<Conversation?> getConversation(String id) async {
    return _isar.conversations.where().idEqualTo(id).findFirst();
  }

  Future<void> deleteConversation(String id) async {
    await _isar.writeTxn(() async {
      await _isar.messages.where().conversationIdEqualTo(id).deleteAll();
      await _isar.conversations.delete(id);
    });
  }

  // ========== 消息 CRUD ==========

  Future<void> saveMessage(Message msg) async {
    await _isar.writeTxn(() async {
      await _isar.messages.put(msg);
      // 更新会话的消息计数
      final conv = await _isar.conversations.where().idEqualTo(msg.conversationId).findFirst();
      if (conv != null) {
        final count = await _isar.messages.where()
            .conversationIdEqualTo(msg.conversationId)
            .count();
        await _isar.conversations.put(conv.copyWith(
          messageCount: count,
          updatedAt: DateTime.now(),
        ));
      }
    });
  }

  Future<List<Message>> getMessages(String conversationId, {int page = 0, int pageSize = 50}) async {
    return _isar.messages.where()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAtDesc()
        .offset(page * pageSize)
        .limit(pageSize)
        .findAll();
  }

  Future<void> deleteMessages(String conversationId) async {
    await _isar.writeTxn(() async {
      await _isar.messages.where()
          .conversationIdEqualTo(conversationId)
          .deleteAll();
    });
  }

  // ========== 任务 CRUD ==========

  Future<void> saveTask(AiTask task) async {
    await _isar.writeTxn(() async {
      await _isar.aiTasks.put(task.copyWith(
        updatedAt: DateTime.now(),
      ));
    });
  }

  Future<List<AiTask>> getTasks({TaskStatus? status}) async {
    final query = _isar.aiTasks.where();
    if (status != null) {
      return query.filter().statusEqualTo(status).sortByCreatedAtDesc().findAll();
    }
    return query.sortByCreatedAtDesc().findAll();
  }

  Future<List<AiTask>> getActiveTasks() async {
    return _isar.aiTasks.where()
        .filter()
        .statusEqualTo(TaskStatus.active)
        .findAll();
  }

  Future<AiTask?> getTask(String id) async {
    return _isar.aiTasks.where().idEqualTo(id).findFirst();
  }

  Future<void> deleteTask(String id) async {
    await _isar.writeTxn(() async {
      await _isar.aiTasks.delete(id);
    });
  }
}
