import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 管理 App 级别的设置（主题、语言、AI 提供商选择等）
class SettingsProvider extends StateNotifier<AppSettings> {
  SettingsProvider() : super(AppSettings.defaults()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('app_settings');
    if (json != null) {
      try {
        state = AppSettings.fromJson(jsonDecode(json));
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', jsonEncode(state.toJson()));
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void setLocale(String locale) {
    state = state.copyWith(locale: locale);
    _persist();
  }

  void setAiProviderConfig(AiProviderConfig config) {
    state = state.copyWith(activeAiConfig: config);
    _persist();
  }

  void setEnableVoice(bool enabled) {
    state = state.copyWith(enableVoice: enabled);
    _persist();
  }

  void setEnableTaskNotifications(bool enabled) {
    state = state.copyWith(enableTaskNotifications: enabled);
    _persist();
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final String locale;
  final AiProviderConfig activeAiConfig;
  final bool enableVoice;
  final bool enableTaskNotifications;

  const AppSettings({
    required this.themeMode,
    required this.locale,
    required this.activeAiConfig,
    required this.enableVoice,
    required this.enableTaskNotifications,
  });

  factory AppSettings.defaults() => AppSettings(
        themeMode: ThemeMode.system,
        locale: 'zh_CN',
        activeAiConfig: const AiProviderConfig(
          provider: 'openai',
          model: 'gpt-4o-mini',
          apiKey: '',
          baseUrl: 'https://api.openai.com/v1',
        ),
        enableVoice: true,
        enableTaskNotifications: true,
      );

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? locale,
    AiProviderConfig? activeAiConfig,
    bool? enableVoice,
    bool? enableTaskNotifications,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        activeAiConfig: activeAiConfig ?? this.activeAiConfig,
        enableVoice: enableVoice ?? this.enableVoice,
        enableTaskNotifications:
            enableTaskNotifications ?? this.enableTaskNotifications,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'locale': locale,
        'activeAiConfig': activeAiConfig.toJson(),
        'enableVoice': enableVoice,
        'enableTaskNotifications': enableTaskNotifications,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values[json['themeMode'] ?? 0],
        locale: json['locale'] ?? 'zh_CN',
        activeAiConfig: AiProviderConfig.fromJson(json['activeAiConfig']),
        enableVoice: json['enableVoice'] ?? true,
        enableTaskNotifications: json['enableTaskNotifications'] ?? true,
      );
}

class AiProviderConfig {
  final String provider;
  final String model;
  final String apiKey;
  final String baseUrl;

  const AiProviderConfig({
    required this.provider,
    required this.model,
    required this.apiKey,
    required this.baseUrl,
  });

  String get displayName {
    switch (provider) {
      case 'openai':
        return 'OpenAI ($model)';
      case 'claude':
        return 'Claude ($model)';
      case 'gemini':
        return 'Gemini ($model)';
      case 'deepseek':
        return 'DeepSeek ($model)';
      case 'qwen':
        return '通义千问 ($model)';
      case 'ernie':
        return '文心一言 ($model)';
      default:
        return '自定义 ($model)';
    }
  }

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'model': model,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
      };

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) =>
      AiProviderConfig(
        provider: json['provider'] ?? 'openai',
        model: json['model'] ?? 'gpt-4o-mini',
        apiKey: json['apiKey'] ?? '',
        baseUrl: json['baseUrl'] ?? 'https://api.openai.com/v1',
      );
}

final settingsProvider =
    StateNotifierProvider<SettingsProvider, AppSettings>((ref) {
  return SettingsProvider();
});
