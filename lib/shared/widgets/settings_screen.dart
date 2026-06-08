import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings_provider.dart';
import '../../core/constants.dart';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // ---- AI 提供商 ----
          _SectionHeader(title: 'AI 模型'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: const Text('AI 提供商'),
              subtitle: Text(settings.activeAiConfig.displayName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAiConfigDialog(context, ref),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.key),
              title: const Text('API Key'),
              subtitle: Text(
                settings.activeAiConfig.apiKey.isEmpty
                    ? '未设置'
                    : '${settings.activeAiConfig.apiKey.substring(0, 8)}...',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () => _showApiKeyDialog(context, ref),
            ),
          ),

          const SizedBox(height: 8),

          // ---- 语音 ----
          _SectionHeader(title: '语音'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SwitchListTile(
              title: const Text('语音输入'),
              subtitle: const Text('使用麦克风输入消息'),
              value: settings.enableVoice,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setEnableVoice(v),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('语音合成'),
              subtitle: const Text('AI 回复自动朗读'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: TTS 设置
              },
            ),
          ),

          const SizedBox(height: 8),

          // ---- 任务 ----
          _SectionHeader(title: '任务'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SwitchListTile(
              title: const Text('任务通知'),
              subtitle: const Text('任务执行时推送通知'),
              value: settings.enableTaskNotifications,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setEnableTaskNotifications(v),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.battery_alert_outlined),
              title: const Text('电池优化白名单'),
              subtitle: const Text('确保定时任务不被系统杀死'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () {
                // TODO: 引导用户加入白名单
              },
            ),
          ),

          const SizedBox(height: 8),

          // ---- 外观 ----
          _SectionHeader(title: '外观'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('主题模式'),
              subtitle: Text(_themeModeName(settings.themeMode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeDialog(context, ref),
            ),
          ),

          const SizedBox(height: 8),

          // ---- 关于 ----
          _SectionHeader(title: '关于'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('版本'),
              subtitle: Text(AppConstants.appVersion),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.code),
              title: const Text('开源许可'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择主题'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.system);
              Navigator.pop(ctx);
            },
            child: const Text('跟随系统'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.light);
              Navigator.pop(ctx);
            },
            child: const Text('浅色'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
              Navigator.pop(ctx);
            },
            child: const Text('深色'),
          ),
        ],
      ),
    );
  }

  void _showAiConfigDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    String selectedProvider = settings.activeAiConfig.provider;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择 AI 提供商'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.supportedProviders.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: selectedProvider,
              onChanged: (v) {
                selectedProvider = v!;
                Navigator.pop(ctx);
                ref.read(settingsProvider.notifier).setAiProviderConfig(
                      settings.activeAiConfig.copyWith(
                        provider: v,
                        baseUrl: AppConstants.providerBaseUrls[v] ??
                            settings.activeAiConfig.baseUrl,
                      ),
                    );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(text: settings.activeAiConfig.apiKey);
    final modelController = TextEditingController(
      text: settings.activeAiConfig.model,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API 配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: '模型名称',
                hintText: 'gpt-4o-mini',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setAiProviderConfig(
                    settings.activeAiConfig.copyWith(
                      apiKey: controller.text,
                      model: modelController.text,
                    ),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
