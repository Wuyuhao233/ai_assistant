/// 任务状态
enum TaskStatus { active, paused, archived }

/// 触发类型
enum TriggerType { cron, interval, specificTime }

/// 执行动作类型
enum ActionType { notification, apiCall, sendMessage }

/// 任务触发条件
class TaskTrigger {
  final TriggerType type;
  final String? cronExpr;
  final Duration? interval;
  final DateTime? specificTime;
  final bool repeat;

  const TaskTrigger({
    required this.type,
    this.cronExpr,
    this.interval,
    this.specificTime,
    this.repeat = true,
  });

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

  TaskTrigger copyWith({
    TriggerType? type,
    String? cronExpr,
    Duration? interval,
    DateTime? specificTime,
    bool? repeat,
  }) =>
      TaskTrigger(
        type: type ?? this.type,
        cronExpr: cronExpr ?? this.cronExpr,
        interval: interval ?? this.interval,
        specificTime: specificTime ?? this.specificTime,
        repeat: repeat ?? this.repeat,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'cronExpr': cronExpr,
        'interval': interval?.inMinutes,
        'specificTime': specificTime?.toIso8601String(),
        'repeat': repeat,
      };

  factory TaskTrigger.fromJson(Map<String, dynamic> json) => TaskTrigger(
        type: TriggerType.values.firstWhere(
            (t) => t.name == json['type'],
            orElse: () => TriggerType.interval),
        cronExpr: json['cronExpr'] as String?,
        interval: json['interval'] != null
            ? Duration(minutes: json['interval'] as int)
            : null,
        specificTime: json['specificTime'] != null
            ? DateTime.parse(json['specificTime'] as String)
            : null,
        repeat: json['repeat'] as bool? ?? true,
      );
}

/// 任务执行动作
class TaskAction {
  final ActionType type;
  final String? notificationTitle;
  final String? notificationBody;
  final String? apiUrl;
  final String? apiMethod;
  final Map<String, dynamic>? apiHeaders;
  final String? apiBodyTemplate;

  const TaskAction({
    required this.type,
    this.notificationTitle,
    this.notificationBody,
    this.apiUrl,
    this.apiMethod,
    this.apiHeaders,
    this.apiBodyTemplate,
  });

  TaskAction copyWith({
    ActionType? type,
    String? notificationTitle,
    String? notificationBody,
    String? apiUrl,
    String? apiMethod,
    Map<String, dynamic>? apiHeaders,
    String? apiBodyTemplate,
  }) =>
      TaskAction(
        type: type ?? this.type,
        notificationTitle: notificationTitle ?? this.notificationTitle,
        notificationBody: notificationBody ?? this.notificationBody,
        apiUrl: apiUrl ?? this.apiUrl,
        apiMethod: apiMethod ?? this.apiMethod,
        apiHeaders: apiHeaders ?? this.apiHeaders,
        apiBodyTemplate: apiBodyTemplate ?? this.apiBodyTemplate,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'notificationTitle': notificationTitle,
        'notificationBody': notificationBody,
        'apiUrl': apiUrl,
        'apiMethod': apiMethod,
        'apiHeaders': apiHeaders,
        'apiBodyTemplate': apiBodyTemplate,
      };

  factory TaskAction.fromJson(Map<String, dynamic> json) => TaskAction(
        type: ActionType.values.firstWhere(
            (a) => a.name == json['type'],
            orElse: () => ActionType.notification),
        notificationTitle: json['notificationTitle'] as String?,
        notificationBody: json['notificationBody'] as String?,
        apiUrl: json['apiUrl'] as String?,
        apiMethod: json['apiMethod'] as String?,
        apiHeaders:
            json['apiHeaders'] as Map<String, dynamic>?,
        apiBodyTemplate: json['apiBodyTemplate'] as String?,
      );
}

/// 任务执行记录
class TaskExecution {
  final String id;
  final String taskId;
  final DateTime executedAt;
  final bool success;
  final String? resultSummary;
  final String? errorMessage;
  final int tokensUsed;
  final Duration? duration;

  const TaskExecution({
    required this.id,
    required this.taskId,
    required this.executedAt,
    this.success = true,
    this.resultSummary,
    this.errorMessage,
    this.tokensUsed = 0,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'executedAt': executedAt.toIso8601String(),
        'success': success,
        'resultSummary': resultSummary,
        'errorMessage': errorMessage,
        'tokensUsed': tokensUsed,
        'duration': duration?.inSeconds,
      };

  factory TaskExecution.fromJson(Map<String, dynamic> json) => TaskExecution(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        executedAt: DateTime.parse(json['executedAt'] as String),
        success: json['success'] as bool? ?? true,
        resultSummary: json['resultSummary'] as String?,
        errorMessage: json['errorMessage'] as String?,
        tokensUsed: json['tokensUsed'] as int? ?? 0,
        duration: json['duration'] != null
            ? Duration(seconds: json['duration'] as int)
            : null,
      );
}

/// AI 定时任务
class AiTask {
  final String id;
  final String title;
  final String prompt;
  final TaskTrigger trigger;
  final TaskAction action;
  final String? aiProvider;
  final String? aiModel;
  final String? conversationId;
  final TaskStatus status;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TaskExecution> history;

  const AiTask({
    required this.id,
    required this.title,
    required this.prompt,
    required this.trigger,
    required this.action,
    this.aiProvider,
    this.aiModel,
    this.conversationId,
    this.status = TaskStatus.active,
    this.lastRunAt,
    this.nextRunAt,
    required this.createdAt,
    this.updatedAt,
    this.history = const [],
  });

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

  AiTask copyWith({
    String? id,
    String? title,
    String? prompt,
    TaskTrigger? trigger,
    TaskAction? action,
    String? aiProvider,
    String? aiModel,
    String? conversationId,
    TaskStatus? status,
    DateTime? lastRunAt,
    DateTime? nextRunAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskExecution>? history,
  }) =>
      AiTask(
        id: id ?? this.id,
        title: title ?? this.title,
        prompt: prompt ?? this.prompt,
        trigger: trigger ?? this.trigger,
        action: action ?? this.action,
        aiProvider: aiProvider ?? this.aiProvider,
        aiModel: aiModel ?? this.aiModel,
        conversationId: conversationId ?? this.conversationId,
        status: status ?? this.status,
        lastRunAt: lastRunAt ?? this.lastRunAt,
        nextRunAt: nextRunAt ?? this.nextRunAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        history: history ?? this.history,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'prompt': prompt,
        'trigger': trigger.toJson(),
        'action': action.toJson(),
        'aiProvider': aiProvider,
        'aiModel': aiModel,
        'conversationId': conversationId,
        'status': status.name,
        'lastRunAt': lastRunAt?.toIso8601String(),
        'nextRunAt': nextRunAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory AiTask.fromJson(Map<String, dynamic> json) => AiTask(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        trigger: TaskTrigger.fromJson(
            json['trigger'] as Map<String, dynamic>? ?? {}),
        action: TaskAction.fromJson(
            json['action'] as Map<String, dynamic>? ?? {}),
        aiProvider: json['aiProvider'] as String?,
        aiModel: json['aiModel'] as String?,
        conversationId: json['conversationId'] as String?,
        status: TaskStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => TaskStatus.active),
        lastRunAt: json['lastRunAt'] != null
            ? DateTime.parse(json['lastRunAt'] as String)
            : null,
        nextRunAt: json['nextRunAt'] != null
            ? DateTime.parse(json['nextRunAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        history: (json['history'] as List?)
                ?.map(
                    (h) => TaskExecution.fromJson(h as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
