// lib/models/message.dart
import 'package:file_picker/file_picker.dart';

/// Represents a chat message in the learning mode interface.
class Message {
  final String? messageId;
  final String text;
  final bool fromUser;
  final DateTime time;
  final List<PlatformFile>? attachments;
  final String? gradeLevel;
  final List<String>? resourceIds;
  final Map<String, dynamic>? safetySummary;
  final Map<String, dynamic>? xaiExplanation; // Added for caching
  final String? modality; // e.g. 'voice_transcription'

  Message({
    this.messageId,
    required this.text,
    required this.fromUser,
    this.attachments,
    this.gradeLevel,
    this.resourceIds,
    this.safetySummary,
    this.xaiExplanation,
    this.modality,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  Message copyWith({
    String? messageId,
    String? text,
    bool? fromUser,
    DateTime? time,
    List<PlatformFile>? attachments,
    String? gradeLevel,
    List<String>? resourceIds,
    Map<String, dynamic>? safetySummary,
    Map<String, dynamic>? xaiExplanation,
    String? modality,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      text: text ?? this.text,
      fromUser: fromUser ?? this.fromUser,
      time: time ?? this.time,
      attachments: attachments ?? this.attachments,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      resourceIds: resourceIds ?? this.resourceIds,
      safetySummary: safetySummary ?? this.safetySummary,
      xaiExplanation: xaiExplanation ?? this.xaiExplanation,
      modality: modality ?? this.modality,
    );
  }
}
