class AppConstants {
  AppConstants._();

  static const String appName = 'AI助手';
  static const String appVersion = '1.0.0';

  // 默认 AI 提供商配置
  static const String defaultAiProvider = 'openai';
  static const String defaultModel = 'gpt-4o-mini';
  static const String defaultApiBaseUrl = 'https://api.openai.com/v1';

  // 支持的 AI 提供商列表
  static const Map<String, String> supportedProviders = {
    'openai': 'OpenAI',
    'claude': 'Claude (Anthropic)',
    'gemini': 'Gemini (Google)',
    'deepseek': 'DeepSeek',
    'qwen': '通义千问',
    'ernie': '文心一言',
    'custom': '自定义',
  };

  // 各提供商的默认 API 端点
  static const Map<String, String> providerBaseUrls = {
    'openai': 'https://api.openai.com/v1',
    'claude': 'https://api.anthropic.com/v1',
    'gemini': 'https://generativelanguage.googleapis.com/v1beta',
    'deepseek': 'https://api.deepseek.com',
    'qwen': 'https://dashscope.aliyuncs.com/api/v1',
    'ernie': 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1',
  };

  // 任务默认值
  static const int maxTaskExecutionHistory = 50;
  static const int minTaskIntervalMinutes = 5;

  // 消息分页
  static const int messagePageSize = 50;

  // 数据库
  static const String dbName = 'ai_assistant';
}
