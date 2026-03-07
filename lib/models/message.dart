import 'package:file_picker/file_picker.dart';

/// Represents a chat message in the learning mode interface.
///
/// Contains the message content, metadata about sender, timestamps,
/// and optional attachments (both local files and API resources).
class Message {
  /// The text content of the message
  final String text;

  /// Whether this message was sent by the user (true) or the AI assistant (false)
  final bool fromUser;

  /// When this message was created or received
  final DateTime time;

  /// Local file attachments (picked by the user from their device)
  final List<PlatformFile>? attachments;

  /// Grade level associated with this message (e.g., 'grade_6_8', 'grade_9_11')
  /// Used to indicate the complexity level of the content
  final String? gradeLevel;

  /// List of resource IDs from the API that can be viewed via the resource endpoint
  /// Format: /api/v1/resources/{resourceId}/view
  final List<String>? resourceIds;

  Message({
    required this.text,
    required this.fromUser,
    this.attachments,
    this.gradeLevel,
    this.resourceIds,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  /// Creates a copy of this message with optional field updates
  Message copyWith({
    String? text,
    bool? fromUser,
    DateTime? time,
    List<PlatformFile>? attachments,
    String? gradeLevel,
    List<String>? resourceIds,
  }) {
    return Message(
      text: text ?? this.text,
      fromUser: fromUser ?? this.fromUser,
      time: time ?? this.time,
      attachments: attachments ?? this.attachments,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      resourceIds: resourceIds ?? this.resourceIds,
    );
  }
}
