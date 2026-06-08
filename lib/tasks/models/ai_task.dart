import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_task.freezed.dart';
part 'ai_task.g.dart';

/// 任务状态
enum TaskStatus { active, paused, archived }

/// 触发类型
enum TriggerType { cron, interval, specificTime }

/// 执行动作类型
enum ActionType { notification, apiCall, sendMessage }

@freezed
class TaskTrigger with _$TaskTrigger {
  const factory TaskTrigger({
    required TriggerType type,
    String? cronExpr,      // cron 表达式: "0 9 * * *"
    Duration? interval,     // 间隔
    DateTime? specificTime, // 一次性定时
    @Default(true) bool repeat, // 是否重复
  }) = _TaskTrigger;

  /// 人类可读的触发描述
  String get description {
    switch (type) {
      case TriggerType.cron:
        return 'Cron: $cronExpr';
      case TriggerType.interval:
        final i = interval ?? Duration.zero;
        if (i.inDays > 0) return '每 ${i.inDays} 天';
        if (i.inHours > 0) return '每 ${i.inHours} 小时';
        return '每 ${i.inMinutes} 分钟';
      case TriggerType.specificTime:
        final t = specificTime;
        if (t == null) return '未设置';
        return '于 ${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
  }

  factory TaskTrigger.fromJson(Map<String, dynamic> json) =>
      _$TaskTriggerFromJson(json);
}

@freezed
class TaskAction with _$TaskAction {
  const factory TaskAction({
    required ActionType type,
    String? notificationTitle,
    String? notificationBody,
    String? apiUrl,
    String? apiMethod,
    Map<String, dynamic>? apiHeaders,
    String? apiBodyTemplate,
  }) = _TaskAction;

  factory TaskAction.fromJson(Map<String, dynamic> json) =>
      _$TaskActionFromJson(json);
}

@freezed
class TaskExecution with _$TaskExecution {
  const factory TaskExecution({
    required String id,
    required String taskId,
    required DateTime executedAt,
    @Default(true) bool success,
    String? resultSummary,
    String? errorMessage,
    @Default(0) int tokensUsed,
    Duration? duration,
  }) = _TaskExecution;

  factory TaskExecution.fromJson(Map<String, dynamic> json) =>
      _$TaskExecutionFromJson(json);
}

@freezed
class AiTask with _$AiTask {
  const AiTask._();

  const factory AiTask({
    required String id,
    required String title,
    required String prompt,
    required TaskTrigger trigger,
    required TaskAction action,
    String? aiProvider,
    String? aiModel,
    String? conversationId,
    @Default(TaskStatus.active) TaskStatus status,
    DateTime? lastRunAt,
    DateTime? nextRunAt,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default([]) List<TaskExecution> history,
  }) = _AiTask;

  bool get isActive => status == TaskStatus.active;
  bool get isPaused => status == TaskStatus.paused;

  /// 下次执行倒计时文字
  String get nextRunText {
    if (status != TaskStatus.active) return '已暂停';
    if (nextRunAt == null) return '未调度';
    final diff = nextRunAt!.difference(DateTime.now());
    if (diff.isNegative) return '即将执行';
    if (diff.inMinutes < 1) return '几秒后';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟后';
    if (diff.inDays < 1) return '${diff.inHours}小时后';
    return '${diff.inDays}天后';
  }

  factory AiTask.fromJson(Map<String, dynamic> json) =>
      _$AiTaskFromJson(json);
}
