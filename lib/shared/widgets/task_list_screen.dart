import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/models/ai_task.dart';
import '../../core/constants.dart';

/// 任务列表页面
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载后自动刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskListProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('定时任务'),
        actions: [
          // 过滤切换
          PopupMenuButton<TaskStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              ref.read(taskListProvider.notifier).setFilter(status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部')),
              const PopupMenuItem(
                value: TaskStatus.active,
                child: Text('进行中'),
              ),
              const PopupMenuItem(
                value: TaskStatus.paused,
                child: Text('已暂停'),
              ),
              const PopupMenuItem(
                value: TaskStatus.archived,
                child: Text('已归档'),
              ),
            ],
          ),
        ],
      ),
      body: taskState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskState.tasks.isEmpty
              ? _buildEmptyState(theme)
              : _buildTaskList(theme, taskState.tasks),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('新建任务'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无定时任务',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建任务让 AI 定时帮你做事',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(ThemeData theme, List<AiTask> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(
          task: task,
          onToggle: () {
            ref.read(taskListProvider.notifier).toggleTaskStatus(task.id);
          },
          onDelete: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('删除任务'),
                content: Text('确定删除"${task.title}"？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('删除'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              ref.read(taskListProvider.notifier).deleteTask(task.id);
            }
          },
          onEdit: () => _showTaskEditor(context, task: task),
        );
      },
    );
  }

  void _showTaskEditor(BuildContext context, {AiTask? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditorScreen(existingTask: task),
      ),
    );
  }
}

/// 任务卡片组件
class _TaskCard extends StatelessWidget {
  final AiTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = task.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 状态指示灯
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                // 标题
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 开关
                Switch(
                  value: isActive,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 触发条件
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  task.trigger.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                // 下次执行
                if (isActive)
                  Text(
                    task.nextRunText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            // 提示预览
            const SizedBox(height: 4),
            Text(
              task.prompt.length > 60
                  ? '${task.prompt.substring(0, 60)}...'
                  : task.prompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // 操作按钮
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  tooltip: '编辑',
                ),
                IconButton(
                  icon: const Icon(Icons.history_outlined, size: 18),
                  onPressed: () {
                    // TODO: 执行历史
                  },
                  tooltip: '执行历史',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  tooltip: '删除',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 任务编辑器页面
class TaskEditorScreen extends StatefulWidget {
  final AiTask? existingTask;

  const TaskEditorScreen({super.key, this.existingTask});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _promptController;
  late final TextEditingController _notificationTitleController;
  late final TextEditingController _notificationBodyController;

  TriggerType _triggerType = TriggerType.interval;
  int _intervalMinutes = 60;
  ActionType _actionType = ActionType.notification;
  bool _repeat = true;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;

    _titleController = TextEditingController(text: task?.title ?? '');
    _promptController = TextEditingController(text: task?.prompt ?? '');
    _notificationTitleController = TextEditingController(
      text: task?.action.notificationTitle ?? '任务执行完成',
    );
    _notificationBodyController = TextEditingController(
      text: task?.action.notificationBody ?? '{result}',
    );

    if (task != null) {
      _triggerType = task.trigger.type;
      _actionType = task.action.type;
      _repeat = task.trigger.repeat;
      if (task.trigger.interval != null) {
        _intervalMinutes = task.trigger.interval!.inMinutes;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _notificationTitleController.dispose();
    _notificationBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask != null ? '编辑任务' : '新建任务'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务标题
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '任务名称',
                hintText: '例如：每日新闻摘要',
              ),
            ),
            const SizedBox(height: 16),

            // AI 提示词
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'AI 执行指令',
                hintText: '告诉 AI 每次执行时要做什么...',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 24),

            // 触发条件
            Text('执行频率', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TriggerType>(
              segments: const [
                ButtonSegment(
                  value: TriggerType.interval,
                  label: Text('间隔'),
                  icon: Icon(Icons.repeat),
                ),
                ButtonSegment(
                  value: TriggerType.cron,
                  label: Text('Cron'),
                  icon: Icon(Icons.schedule),
                ),
                ButtonSegment(
                  value: TriggerType.specificTime,
                  label: Text('定时'),
                  icon: Icon(Icons.alarm),
                ),
              ],
              selected: {_triggerType},
              onSelectionChanged: (set) {
                setState(() => _triggerType = set.first);
              },
            ),
            const SizedBox(height: 12),

            // 间隔设置
            if (_triggerType == TriggerType.interval) ...[
              Row(
                children: [
                  const Text('每'),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '间隔',
                        hintText: '60',
                      ),
                      controller: TextEditingController(
                        text: _intervalMinutes.toString(),
                      ),
                      onChanged: (v) =>
                          _intervalMinutes = int.tryParse(v) ?? 60,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('分钟'),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('重复执行'),
              subtitle: const Text('关闭后只执行一次'),
              value: _repeat,
              onChanged: (v) => setState(() => _repeat = v),
            ),
            const SizedBox(height: 24),

            // 执行动作
            Text('执行动作', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ActionType>(
              segments: const [
                ButtonSegment(
                  value: ActionType.notification,
                  label: Text('通知'),
                  icon: Icon(Icons.notifications),
                ),
                ButtonSegment(
                  value: ActionType.apiCall,
                  label: Text('API'),
                  icon: Icon(Icons.api),
                ),
              ],
              selected: {_actionType},
              onSelectionChanged: (set) {
                setState(() => _actionType = set.first);
              },
            ),
            const SizedBox(height: 12),

            // 通知设置
            if (_actionType == ActionType.notification) ...[
              TextField(
                controller: _notificationTitleController,
                decoration: const InputDecoration(
                  labelText: '通知标题',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notificationBodyController,
                decoration: const InputDecoration(
                  labelText: '通知内容',
                  hintText: '使用 {result} 引用 AI 返回结果',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Text(
                '提示: {result} 会被 AI 的执行结果替换',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveTask() {
    if (_titleController.text.isEmpty || _promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写任务名称和执行指令')),
      );
      return;
    }

    final trigger = TaskTrigger(
      type: _triggerType,
      interval: _triggerType == TriggerType.interval
          ? Duration(minutes: _intervalMinutes)
          : null,
      repeat: _repeat,
    );

    final action = TaskAction(
      type: _actionType,
      notificationTitle: _notificationTitleController.text,
      notificationBody: _notificationBodyController.text,
    );

    if (widget.existingTask != null) {
      // 更新
      context.read(taskListProvider.notifier).updateTask(
            widget.existingTask!.copyWith(
              title: _titleController.text,
              prompt: _promptController.text,
              trigger: trigger,
              action: action,
            ),
          );
    } else {
      // 创建
      context.read(taskListProvider.notifier).createTask(
            title: _titleController.text,
            prompt: _promptController.text,
            trigger: trigger,
            action: action,
          );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingTask != null ? '任务已更新' : '任务已创建'),
      ),
    );
  }
}
