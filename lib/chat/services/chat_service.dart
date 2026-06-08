import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings_provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'sse_stream_parser.dart';
import '../../database/isar_service.dart';

/// AI 对话服务 — 发送消息、流式接收、工具调用
class ChatService {
  final DatabaseService _db;
  final Dio _dio;

  ChatService(this._db)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  /// 发送消息并获取流式回复
  Stream<ChatStreamEvent> sendMessage({
    required String conversationId,
    required String content,
    required AiProviderConfig config,
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
  }) async* {
    final uuid = const Uuid();

    // 1. 保存用户消息
    final userMsg = Message(
      id: uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    await _db.saveMessage(userMsg);

    // 2. 获取历史消息
    final history = await _db.getMessages(conversationId, pageSize: 50);
    final apiMessages = <Map<String, dynamic>>[];

    // 添加系统提示
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      apiMessages.add({
        'role': 'system',
        'content': systemPrompt,
      });
    }

    // 添加历史消息（反转回时间正序）
    for (final msg in history.reversed) {
      apiMessages.add(msg.toApiMessage());
    }

    // 3. 构建请求体
    final requestBody = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': true,
    };

    if (tools != null && tools.isNotEmpty) {
      requestBody['tools'] = tools;
      requestBody['tool_choice'] = 'auto';
    }

    // 4. 创建 AI 回复消息（占位）
    final aiMsgId = uuid.v4();
    final aiMsg = Message(
      id: aiMsgId,
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
      createdAt: DateTime.now(),
    );

    try {
      // 发送流式请求
      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      final parser = SseStreamParser();
      var accumulatedContent = '';

      // 先保存 AI 占位消息
      await _db.saveMessage(aiMsg);

      parser.parseResponse(response);

      await for (final event in parser.stream) {
        switch (event) {
          case ChatStreamContent(:final text):
            accumulatedContent += text;
            yield event;
          case ChatStreamToolCall(:final toolCall):
            yield event;
          case ChatStreamUsage(:final tokensIn, :final tokensOut):
            // 保存最终消息
            final finalMsg = aiMsg.copyWith(
              content: accumulatedContent,
              tokensIn: tokensIn,
              tokensOut: tokensOut,
              isStreaming: false,
            );
            await _db.saveMessage(finalMsg);
            yield event;
          case ChatStreamDone():
            // 确保消息已保存
            if (accumulatedContent.isNotEmpty) {
              final finalMsg = aiMsg.copyWith(
                content: accumulatedContent,
                isStreaming: false,
              );
              await _db.saveMessage(finalMsg);
            }
            yield event;
          case ChatStreamError(:final message):
            yield event;
        }
      }
    } on DioException catch (e) {
      final errorMsg = _formatError(e);
      await _db.saveMessage(aiMsg.copyWith(
        content: errorMsg,
        isStreaming: false,
      ));
      yield ChatStreamEvent.error(errorMsg);
    }
  }

  /// 简单的非流式请求（用于任务执行等后台场景）
  Future<String> sendMessageSync({
    required String prompt,
    required AiProviderConfig config,
    String? systemPrompt,
  }) async {
    try {
      final messages = <Map<String, dynamic>>[];
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      messages.add({'role': 'user', 'content': prompt});

      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        data: {
          'model': config.model,
          'messages': messages,
          'stream': false,
        },
        options: Options(headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        }),
      );

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        return choices[0]['message']['content'] ?? '';
      }
      return '';
    } catch (e) {
      return '执行出错: $e';
    }
  }

  String _formatError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.receiveTimeout:
        return '响应超时，请重试';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        if (statusCode == 401) return 'API Key 无效，请在设置中检查';
        if (statusCode == 429) return '请求过于频繁，请稍后再试';
        if (statusCode == 500) return 'AI 服务端错误';
        return '请求失败 ($statusCode): ${body.toString().length > 100 ? body.toString().substring(0, 100) : body}';
      default:
        return '网络错误: ${e.message}';
    }
  }

  /// 创建新会话
  Future<Conversation> createConversation({
    String? title,
    required AiProviderConfig config,
    String? systemPrompt,
  }) async {
    final conv = Conversation(
      id: const Uuid().v4(),
      title: title ?? '新对话',
      aiProvider: config.provider,
      aiModel: config.model,
      systemPrompt: systemPrompt ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.saveConversation(conv);
    return conv;
  }
}
