import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings_provider.dart';
import '../../database/isar_service.dart';
import '../models/ai_task.dart';

/// 任务列表状态
class TaskListState {
  final List<AiTask> tasks;
  final bool isLoading;
  final String? error;
  final TaskStatus? filterStatus;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });

  TaskListState copyWith({
    List<AiTask>? tasks,
    bool? isLoading,
    String? error,
    bool clearError = false,
    TaskStatus? filterStatus,
    bool clearFilter = false,
  }) =>
      TaskListState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      );
}

/// 任务列表状态管理
class TaskListProvider extends StateNotifier<TaskListState> {
  final Ref _ref;

  TaskListProvider(this._ref) : super(const TaskListState());

  DatabaseService get _db => _ref.read(databaseProvider);

  /// 加载任务列表
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true);
    try {
      final tasks = await _db.getTasks(status: state.filterStatus);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载失败: $e');
    }
  }

  /// 创建新任务
  Future<void> createTask({
    required String title,
    required String prompt,
    required TaskTrigger trigger,
    required TaskAction action,
  }) async {
    try {
      final settings = _ref.read(settingsProvider);
      final task = AiTask(
        id: const Uuid().v4(),
        title: title,
        prompt: prompt,
        trigger: trigger,
        action: action,
        aiProvider: settings.activeAiConfig.provider,
        aiModel: settings.activeAiConfig.model,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _db.saveTask(task);
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: '创建失败: $e');
    }
  }

  /// 更新任务
  Future<void> updateTask(AiTask task) async {
    await _db.saveTask(task);
    await loadTasks();
  }

  /// 切换任务启停
  Future<void> toggleTaskStatus(String taskId) async {
    final task = await _db.getTask(taskId);
    if (task == null) return;

    final newStatus = task.status == TaskStatus.active
        ? TaskStatus.paused
        : TaskStatus.active;

    await _db.saveTask(task.copyWith(
      status: newStatus,
      nextRunAt: newStatus == TaskStatus.active
          ? DateTime.now().add(const Duration(minutes: 5))
          : null,
    ));
    await loadTasks();
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    await _db.deleteTask(taskId);
    await loadTasks();
  }

  /// 设置过滤
  void setFilter(TaskStatus? status) {
    state = state.copyWith(filterStatus: status);
    loadTasks();
  }
}

// ========== Providers ==========

final taskListProvider =
    StateNotifierProvider<TaskListProvider, TaskListState>((ref) {
  return TaskListProvider(ref);
});
