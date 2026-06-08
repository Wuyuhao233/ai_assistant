import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// 消息角色
enum MessageRole { user, assistant, system, tool }

/// 消息内容类型
enum MessageContentType { text, image, voice }

/// AI 工具调用（Function Calling）
@freezed
class ToolCall with _$ToolCall {
  const factory ToolCall({
    required String id,
    required String functionName,
    required Map<String, dynamic> arguments,
  }) = _ToolCall;

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);
}

@freezed
class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String conversationId,
    required MessageRole role,
    required String content,
    @Default(MessageContentType.text) MessageContentType contentType,
    @Default([]) List<ToolCall> toolCalls,
    String? imageUrl,
    String? voiceUrl,
    @Default(0) int tokensIn,
    @Default(0) int tokensOut,
    required DateTime createdAt,
    @Default(false) bool isStreaming,
  }) = _Message;

  /// 获取 API 请求格式的消息体
  Map<String, dynamic> toApiMessage() {
    final msg = <String, dynamic>{
      'role': role.name,
      'content': content,
    };
    if (toolCalls.isNotEmpty) {
      msg['tool_calls'] = toolCalls
          .map((t) => {
                'id': t.id,
                'type': 'function',
                'function': {
                  'name': t.functionName,
                  'arguments': t.arguments,
                },
              })
          .toList();
    }
    return msg;
  }

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
