import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme.dart';
import 'core/settings_provider.dart';
import 'chat/providers/chat_provider.dart';
import 'database/isar_service.dart';
import 'shared/widgets/home_screen.dart';

// WorkManager 回调名称
const String taskBackgroundWorkName = 'ai_task_execution';

// WorkManager 后台任务入口
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 后台执行任务逻辑
    // 注意：这里无法使用 Riverpod，需要用 Isar 直接操作
    try {
      final db = await DatabaseService.getInstance();
      // TODO: 从 inputData 获取 taskId，执行任务
      return true;
    } catch (e) {
      return false;
    }
  });
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // 初始化本地通知
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings),
  );

  // 初始化数据库
  final db = await DatabaseService.getInstance();

  // 配置 WorkManager 定期任务（最短 15 分钟）
  await Workmanager().registerPeriodicTask(
    'periodic_task_check',
    taskBackgroundWorkName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const AIAssistantApp(),
    ),
  );
}

class AIAssistantApp extends ConsumerWidget {
  const AIAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'AI助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
