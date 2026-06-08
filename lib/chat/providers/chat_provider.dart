import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings_provider.dart';
import '../../database/isar_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'sse_stream_parser.dart';

/// 对话状态
class ChatState {
  final Conversation? currentConversation;
  final List<Message> messages;
  final String? lastAiMessage;
  final bool isStreaming;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.currentConversation,
    this.messages = const [],
    this.lastAiMessage,
    this.isStreaming = false,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    Conversation? currentConversation,
    List<Message>? messages,
    String? lastAiMessage,
    bool? isStreaming,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        currentConversation: currentConversation ?? this.currentConversation,
        messages: messages ?? this.messages,
        lastAiMessage: lastAiMessage ?? this.lastAiMessage,
        isStreaming: isStreaming ?? this.isStreaming,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// 对话状态管理
class ChatProvider extends StateNotifier<ChatState> {
  final Ref _ref;
  ChatService? _chatService;
  StreamSubscription<ChatStreamEvent>? _streamSubscription;

  ChatProvider(this._ref) : super(const ChatState());

  DatabaseService get _db => _ref.read(databaseProvider);
  ChatService get _chatServiceInstance {
    _chatService ??= ChatService(_db);
    return _chatService!;
  }

  /// 创建新会话
  Future<void> createConversation({String? title, String? systemPrompt}) async {
    final settings = _ref.read(settingsProvider);
    final conv = await _chatServiceInstance.createConversation(
      title: title,
      config: settings.activeAiConfig,
      systemPrompt: systemPrompt,
    );
    state = state.copyWith(
      currentConversation: conv,
      messages: [],
    );

    // 刷新会话列表
    _ref.invalidate(conversationListProvider);
  }

  /// 切换到已有会话
  Future<void> selectConversation(String conversationId) async {
    state = state.copyWith(isLoading: true, error: null);

    final conv = await _db.getConversation(conversationId);
    if (conv == null) {
      state = state.copyWith(isLoading: false, error: '会话不存在');
      return;
    }

    final messages = await _db.getMessages(conversationId);
    state = state.copyWith(
      currentConversation: conv,
      messages: messages.reversed.toList(),
      isLoading: false,
    );
  }

  /// 发送消息
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isStreaming) return;

    final convId = state.currentConversation?.id;
    if (convId == null) {
      // 自动创建新会话
      await createConversation(title: content.length > 20 ? '${content.substring(0, 20)}...' : content);
    }

    final settings = _ref.read(settingsProvider);
    final systemPrompt = state.currentConversation?.systemPrompt;

    // 先将用户消息加入本地状态
    final tempMsg = Message(
      id: const Uuid().v4(),
      conversationId: state.currentConversation!.id,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, tempMsg],
      isStreaming: true,
      lastAiMessage: null,
      error: null,
    );

    try {
      final stream = _chatServiceInstance.sendMessage(
        conversationId: state.currentConversation!.id,
        content: content,
        config: settings.activeAiConfig,
        systemPrompt: systemPrompt,
      );

      var aiContent = '';
      await for (final event in stream) {
        switch (event) {
          case ChatStreamContent(:final text):
            aiContent += text;
            state = state.copyWith(lastAiMessage: aiContent);
          case ChatStreamError(:final message):
            state = state.copyWith(error: message, isStreaming: false);
          case ChatStreamDone():
            // 刷新消息列表
            final msgs = await _db.getMessages(state.currentConversation!.id);
            state = state.copyWith(
              messages: msgs.reversed.toList(),
              isStreaming: false,
              lastAiMessage: null,
            );
          case _:
            break;
        }
      }
    } catch (e) {
      state = state.copyWith(
        error: '发送失败: $e',
        isStreaming: false,
      );
    }

    // 刷新会话列表（更新摘要和消息数）
    _ref.invalidate(conversationListProvider);
  }

  /// 删除会话
  Future<void> deleteConversation(String id) async {
    await _db.deleteConversation(id);
    if (state.currentConversation?.id == id) {
      state = state.copyWith(
        currentConversation: null,
        messages: [],
      );
    }
    _ref.invalidate(conversationListProvider);
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

// ========== Providers ==========

final databaseProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be initialized before use');
});

final chatProvider = StateNotifierProvider<ChatProvider, ChatState>((ref) {
  return ChatProvider(ref);
});

final conversationListProvider = FutureProvider<List<Conversation>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getConversations();
});
