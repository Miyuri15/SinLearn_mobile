class ChatSession {
  final String id;
  final String mode;
  final String channel;
  final String createdAt;
  final String? updatedAt;
  final String? title;

  ChatSession({
    required this.id,
    required this.mode,
    required this.channel,
    required this.createdAt,
    this.updatedAt,
    this.title,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'text',
      channel: json['channel']?.toString() ?? 'text',
      createdAt:
          json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at']?.toString(),
      title: json['title']?.toString(),
    );
  }
}

class ChatMessage {
  final String? id;
  final String role;
  final dynamic content;
  final String createdAt;
  final String? gradeLevel;
  final List<String>? resourceIds;
  final Map<String, dynamic>? safetySummary;
  final String? modality;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.gradeLevel,
    this.resourceIds,
    this.safetySummary,
    this.modality,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString(),
      role: json['role'],
      content: json['content'],
      createdAt: json['created_at'],
      gradeLevel: json['grade_level']?.toString(),
      resourceIds: (json['resource_ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      safetySummary: json['safety_summary'] is Map
          ? Map<String, dynamic>.from(json['safety_summary'] as Map)
          : null,
      modality: json['modality']?.toString(),
    );
  }
}
