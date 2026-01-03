class ChatSession {
  final String id;
  final String mode;
  final String channel;
  final String createdAt;
  final String updatedAt;
  final String? title;

  ChatSession({
    required this.id,
    required this.mode,
    required this.channel,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      mode: json['mode'],
      channel: json['channel'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      title: json['title'],
    );
  }
}


class ChatMessage {
  final String role;
  final dynamic content;
  final String createdAt;

  ChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
      createdAt: json['created_at'],
    );
  }
}
