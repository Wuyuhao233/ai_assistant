/// 消息角色
enum MessageRole { user, assistant, system, tool }

/// 消息内容类型
enum MessageContentType { text, image, voice }

/// AI 工具调用
class ToolCall {
  final String id;
  final String functionName;
  final Map<String, dynamic> arguments;

  const ToolCall({
    required this.id,
    required this.functionName,
    required this.arguments,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        id: json['id'] as String? ?? '',
        functionName: json['functionName'] as String? ?? '',
        arguments: json['arguments'] as Map<String, dynamic>? ?? {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'functionName': functionName,
        'arguments': arguments,
      };
}

class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final MessageContentType contentType;
  final List<ToolCall> toolCalls;
  final String? imageUrl;
  final String? voiceUrl;
  final int tokensIn;
  final int tokensOut;
  final DateTime createdAt;
  final bool isStreaming;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.contentType = MessageContentType.text,
    this.toolCalls = const [],
    this.imageUrl,
    this.voiceUrl,
    this.tokensIn = 0,
    this.tokensOut = 0,
    required this.createdAt,
    this.isStreaming = false,
  });

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

  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    MessageContentType? contentType,
    List<ToolCall>? toolCalls,
    String? imageUrl,
    String? voiceUrl,
    int? tokensIn,
    int? tokensOut,
    DateTime? createdAt,
    bool? isStreaming,
  }) =>
      Message(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        role: role ?? this.role,
        content: content ?? this.content,
        contentType: contentType ?? this.contentType,
        toolCalls: toolCalls ?? this.toolCalls,
        imageUrl: imageUrl ?? this.imageUrl,
        voiceUrl: voiceUrl ?? this.voiceUrl,
        tokensIn: tokensIn ?? this.tokensIn,
        tokensOut: tokensOut ?? this.tokensOut,
        createdAt: createdAt ?? this.createdAt,
        isStreaming: isStreaming ?? this.isStreaming,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'role': role.name,
        'content': content,
        'contentType': contentType.name,
        'toolCalls': toolCalls.map((t) => t.toJson()).toList(),
        'imageUrl': imageUrl,
        'voiceUrl': voiceUrl,
        'tokensIn': tokensIn,
        'tokensOut': tokensOut,
        'createdAt': createdAt.toIso8601String(),
        'isStreaming': isStreaming,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        role: MessageRole.values.firstWhere(
            (r) => r.name == json['role'],
            orElse: () => MessageRole.user),
        content: json['content'] as String? ?? '',
        contentType: MessageContentType.values.firstWhere(
            (t) => t.name == json['contentType'],
            orElse: () => MessageContentType.text),
        toolCalls: (json['toolCalls'] as List?)
                ?.map((t) => ToolCall.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        imageUrl: json['imageUrl'] as String?,
        voiceUrl: json['voiceUrl'] as String?,
        tokensIn: json['tokensIn'] as int? ?? 0,
        tokensOut: json['tokensOut'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isStreaming: json['isStreaming'] as bool? ?? false,
      );
}
