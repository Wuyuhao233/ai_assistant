import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../chat/models/message.dart';

/// SSE 流式响应解析器
class SseStreamParser {
  final StreamController<ChatStreamEvent> _controller =
      StreamController<ChatStreamEvent>.broadcast();

  Stream<ChatStreamEvent> get stream => _controller.stream;

  void parseResponse(Response response) {
    if (response.data is Stream) {
      _parseStream(response.data as Stream);
    } else if (response.data is String) {
      _parseString(response.data as String);
    }
  }

  Future<void> _parseStream(Stream dataStream) async {
    String buffer = '';
    await for (final chunk in dataStream) {
      buffer += utf8.decode(chunk as List<int>);
      while (buffer.contains('\n')) {
        final lineEnd = buffer.indexOf('\n');
        final line = buffer.substring(0, lineEnd).trim();
        buffer = buffer.substring(lineEnd + 1);
        _processLine(line);
      }
    }
    if (buffer.isNotEmpty) {
      _processLine(buffer.trim());
    }
    _controller.close();
  }

  void _parseString(String data) {
    for (final line in data.split('\n')) {
      _processLine(line.trim());
    }
    _controller.close();
  }

  void _processLine(String line) {
    if (line.isEmpty || line.startsWith(':')) return; // 注释或空行

    if (line.startsWith('data: ')) {
      final data = line.substring(6);
      if (data == '[DONE]') {
        _controller.add(const ChatStreamEvent.done());
        return;
      }
      try {
        final json = jsonDecode(data);
        final choices = json['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final delta = choices[0]['delta'] as Map<String, dynamic>?;
          if (delta != null) {
            final content = delta['content'] as String?;
            if (content != null && content.isNotEmpty) {
              _controller.add(ChatStreamEvent.content(content));
            }
            // tool calls
            final toolCalls = delta['tool_calls'] as List?;
            if (toolCalls != null) {
              for (final tc in toolCalls) {
                final fn = tc['function'] as Map<String, dynamic>?;
                if (fn != null) {
                  _controller.add(ChatStreamEvent.toolCall(
                    ToolCall(
                      id: tc['id'] ?? '',
                      functionName: fn['name'] ?? '',
                      arguments: fn['arguments'] is Map
                          ? fn['arguments'] as Map<String, dynamic>
                          : {},
                    ),
                  ));
                }
              }
            }
          }
          // 用量信息
          final usage = choices[0].containsKey('usage')
              ? choices[0]['usage'] as Map<String, dynamic>?
              : null;
          if (usage != null) {
            _controller.add(ChatStreamEvent.usage(
              tokensIn: usage['prompt_tokens'] ?? 0,
              tokensOut: usage['completion_tokens'] ?? 0,
            ));
          }
        }
      } catch (_) {
        // 非 JSON 数据，可能是纯文本流
        _controller.add(ChatStreamEvent.content(data));
      }
    } else if (line.startsWith('event: ')) {
      // 暂不处理 event 类型
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// 流式事件的联合类型
sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

final class ChatStreamContent extends ChatStreamEvent {
  final String text;
  const ChatStreamContent(this.text);
}

final class ChatStreamToolCall extends ChatStreamEvent {
  final ToolCall toolCall;
  const ChatStreamToolCall(this.toolCall);
}

final class ChatStreamUsage extends ChatStreamEvent {
  final int tokensIn;
  final int tokensOut;
  const ChatStreamUsage({required this.tokensIn, required this.tokensOut});
}

final class ChatStreamError extends ChatStreamEvent {
  final String message;
  const ChatStreamError(this.message);
}

final class ChatStreamDone extends ChatStreamEvent {
  const ChatStreamDone();
}

// 命名构造函数扩展
extension ChatStreamEventFactory on ChatStreamEvent {
  static const content = ChatStreamContent.new;
  static const toolCall = ChatStreamToolCall.new;
  static const usage = ChatStreamUsage.new;
  static const error = ChatStreamError.new;
  static const done = ChatStreamDone.new;
}
