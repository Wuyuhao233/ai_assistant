import 'package:flutter/material.dart';

class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String chat = '/chat';
  static const String conversationList = '/conversations';
  static const String taskList = '/tasks';
  static const String taskEditor = '/tasks/edit';
  static const String taskHistory = '/tasks/history';
  static const String settings = '/settings';
  static const String aiProviderConfig = '/settings/ai-provider';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // MaterialPageRouter 自动处理大部分情况
    // 这里保留扩展点，后续可以加自定义过渡动画
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const SizedBox.shrink(), // 由 GoRouter 或 Navigator 处理
    );
  }
}
