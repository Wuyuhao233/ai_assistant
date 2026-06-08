class Conversation {
  final String id;
  final String title;
  final String? summary;
  final int messageCount;
  final String aiProvider;
  final String aiModel;
  final String systemPrompt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isArchived;

  const Conversation({
    required this.id,
    required this.title,
    this.summary,
    this.messageCount = 0,
    required this.aiProvider,
    required this.aiModel,
    this.systemPrompt = '',
    this.createdAt,
    this.updatedAt,
    this.isArchived = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(updatedAt ?? createdAt ?? now);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${(diff.inDays / 30).floor()}个月前';
  }

  Conversation copyWith({
    String? id,
    String? title,
    String? summary,
    int? messageCount,
    String? aiProvider,
    String? aiModel,
    String? systemPrompt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) =>
      Conversation(
        id: id ?? this.id,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        messageCount: messageCount ?? this.messageCount,
        aiProvider: aiProvider ?? this.aiProvider,
        aiModel: aiModel ?? this.aiModel,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isArchived: isArchived ?? this.isArchived,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'messageCount': messageCount,
        'aiProvider': aiProvider,
        'aiModel': aiModel,
        'systemPrompt': systemPrompt,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isArchived': isArchived,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String?,
        messageCount: json['messageCount'] as int? ?? 0,
        aiProvider: json['aiProvider'] as String? ?? 'openai',
        aiModel: json['aiModel'] as String? ?? 'gpt-4o-mini',
        systemPrompt: json['systemPrompt'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        isArchived: json['isArchived'] as bool? ?? false,
      );
}
