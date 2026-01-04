class VoiceQAResponse {
  final String sessionId;
  final String question;
  final String answer;

  VoiceQAResponse({
    required this.sessionId,
    required this.question,
    required this.answer,
  });

  factory VoiceQAResponse.fromJson(Map<String, dynamic> json) {
    return VoiceQAResponse(
      sessionId: json['session_id'],
      question: json['question'],
      answer: json['answer'],
    );
  }
}
