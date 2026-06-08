import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/settings_provider.dart';
import '../models/ai_task.dart';
import '../../database/isar_service.dart';
import '../../chat/services/chat_service.dart';

/// 任务调度执行器 — 被 WorkManager 或前台服务调用
class TaskExecutor {
  final DatabaseService _db;
  final ChatService _chatService;
  final FlutterLocalNotificationsPlugin _notifications;

  TaskExecutor(this._db, this._chatService, this._notifications);

  /// 执行单个任务
  Future<void> executeTask(AiTask task, AiProviderConfig config) async {
    final startTime = DateTime.now();
    final executionId = const Uuid().v4();

    try {
      // 1. 调用 AI 执行
      final result = await _chatService.sendMessageSync(
        prompt: task.prompt,
        config: config,
        systemPrompt: '你是一个任务执行助手。请严格按照用户要求的格式和内容执行任务。',
      );

      // 2. 记录执行历史
      final execution = TaskExecution(
        id: executionId,
        taskId: task.id,
        executedAt: DateTime.now(),
        success: true,
        resultSummary: result.length > 200 ? '${result.substring(0, 200)}...' : result,
        duration: DateTime.now().difference(startTime),
      );

      final updatedHistory = [...task.history, execution];
      if (updatedHistory.length > 50) {
        updatedHistory.removeAt(0);
      }

      // 3. 根据动作类型响应
      await _handleAction(task.action, result);

      // 4. 更新任务状态
      final updatedTask = task.copyWith(
        lastRunAt: DateTime.now(),
        nextRunAt: _calculateNextRun(task.trigger),
        history: updatedHistory,
      );
      await _db.saveTask(updatedTask);
    } catch (e) {
      // 记录失败
      final execution = TaskExecution(
        id: executionId,
        taskId: task.id,
        executedAt: DateTime.now(),
        success: false,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );

      await _db.saveTask(task.copyWith(
        history: [...task.history, execution],
      ));
    }
  }

  Future<void> _handleAction(TaskAction action, String aiResult) async {
    switch (action.type) {
      case ActionType.notification:
        await _showNotification(
          title: action.notificationTitle ?? '任务执行完成',
          body: action.notificationBody?.replaceAll('{result}', aiResult) ??
              aiResult.length > 100
                  ? '${aiResult.substring(0, 100)}...'
                  : aiResult,
        );
      case ActionType.sendMessage:
        // 发送到指定会话 — 由 ChatProvider 处理
        break;
      case ActionType.apiCall:
        if (action.apiUrl != null) {
          await _callExternalApi(action, aiResult);
        }
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      '定时任务',
      channelDescription: 'AI 定时任务执行通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> _callExternalApi(TaskAction action, String aiResult) async {
    try {
      final dio = Dio();
      final body = action.apiBodyTemplate != null
          ? jsonDecode(action.apiBodyTemplate.replaceAll('{result}', aiResult))
          : {'result': aiResult};

      await dio.post(
        action.apiUrl!,
        data: body,
        options: Options(
          method: action.apiMethod ?? 'POST',
          headers: action.apiHeaders,
        ),
      );
    } catch (e) {
      // API 调用失败 — 记录但不阻塞
    }
  }

  DateTime? _calculateNextRun(TaskTrigger trigger) {
    if (!trigger.repeat) return null;

    final now = DateTime.now();
    switch (trigger.type) {
      case TriggerType.interval:
        final interval = trigger.interval ?? Duration.zero;
        return now.add(interval);
      case TriggerType.cron:
        // 简化的 cron 解析 — 实际项目建议用 cron 库
        return now.add(const Duration(hours: 24));
      case TriggerType.specificTime:
        return trigger.specificTime;
    }
  }
}

/// 调度器 — 注册/取消 WorkManager 任务
class TaskScheduler {
  final DatabaseService _db;
  final TaskExecutor _executor;

  TaskScheduler(this._db, this._executor);

  /// 注册所有活跃任务到 WorkManager
  Future<void> registerAllActiveTasks() async {
    final tasks = await _db.getActiveTasks();
    for (final task in tasks) {
      await registerTask(task);
    }
  }

  /// 注册单个任务
  Future<void> registerTask(AiTask task) async {
    // WorkManager 的注册逻辑由原生侧处理
    // 这里存储调度信息到数据库
    await _db.saveTask(task.copyWith(
      nextRunAt: _calculateInitialRun(task.trigger),
    ));
  }

  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    // 由 WorkManager 取消
  }

  DateTime _calculateInitialRun(TaskTrigger trigger) {
    final now = DateTime.now();
    switch (trigger.type) {
      case TriggerType.specificTime:
        return trigger.specificTime ?? now;
      case TriggerType.interval:
        return now.add(trigger.interval ?? Duration.zero);
      case TriggerType.cron:
        return now.add(const Duration(hours: 1));
    }
  }
}
