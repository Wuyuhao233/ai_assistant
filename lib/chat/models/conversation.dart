import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
class Conversation with _$Conversation {
  const Conversation._();

  const factory Conversation({
    required String id,
    required String title,
    String? summary,
    @Default(0) int messageCount,
    required String aiProvider,
    required String aiModel,
    @Default('') String systemPrompt,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isArchived,
  }) = _Conversation;

  /// 格式化时间显示
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(updatedAt ?? createdAt ?? now);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${(diff.inDays / 30).floor()}个月前';
  }

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
