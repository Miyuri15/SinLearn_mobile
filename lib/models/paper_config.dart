class PaperConfig {
  final String id;
  final String? chatSessionId;
  final String? evaluationSessionId;
  String paperPart;
  final String subjectName;
  final String medium;
  int totalMarks;
  final String weightage;
  int totalMainQuestions;
  SelectionRules selectionRules;
  final bool isConfirmed;
  final String createdAt;
  List<QuestionStructure> questions;

  PaperConfig({
    required this.id,
    this.chatSessionId,
    this.evaluationSessionId,
    required this.paperPart,
    required this.subjectName,
    required this.medium,
    required this.totalMarks,
    required this.weightage,
    required this.totalMainQuestions,
    required this.selectionRules,
    required this.isConfirmed,
    required this.createdAt,
    this.questions = const [],
  });

  factory PaperConfig.fromJson(Map<String, dynamic> json) {
    return PaperConfig(
      id: json['id'],
      chatSessionId: json['chat_session_id'],
      evaluationSessionId: json['evaluation_session_id'],
      paperPart: json['paper_part'],
      subjectName: json['subject_name'],
      medium: json['medium'],
      totalMarks: json['total_marks'],
      weightage: json['weightage'],
      totalMainQuestions: json['total_main_questions'],
      selectionRules: SelectionRules.fromJson(json['selection_rules']),
      isConfirmed: json['is_confirmed'],
      createdAt: json['created_at'],
      questions: (json['questions'] as List?)
          ?.map((e) => QuestionStructure.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_session_id': chatSessionId,
      'evaluation_session_id': evaluationSessionId,
      'paper_part': paperPart,
      'subject_name': subjectName,
      'medium': medium,
      'total_marks': totalMarks,
      'weightage': weightage,
      'total_main_questions': totalMainQuestions,
      'selection_rules': selectionRules.toJson(),
      'is_confirmed': isConfirmed,
      'created_at': createdAt,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

class SelectionRules {
  int? chooseAny;
  String? mode;

  SelectionRules({this.chooseAny, this.mode});

  factory SelectionRules.fromJson(Map<String, dynamic> json) {
    return SelectionRules(
      chooseAny: json['choose_any'],
      mode: json['mode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'choose_any': chooseAny,
      'mode': mode,
    };
  }
}

class QuestionStructure {
  String? id;
  int questionNo;
  double marks;
  bool hasSubQuestions;
  List<SubQuestionStructure> subQuestions;

  QuestionStructure({
    this.id,
    required this.questionNo,
    required this.marks,
    this.hasSubQuestions = false,
    this.subQuestions = const [],
  });

  factory QuestionStructure.fromJson(Map<String, dynamic> json) {
    return QuestionStructure(
      id: json['id'],
      questionNo: json['question_no'] ?? 0,
      marks: (json['marks'] as num?)?.toDouble() ?? 0.0,
      hasSubQuestions: json['has_sub_questions'] ?? false,
      subQuestions: (json['sub_questions'] as List?)
          ?.map((e) => SubQuestionStructure.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_no': questionNo,
      'marks': marks,
      'has_sub_questions': hasSubQuestions,
      'sub_questions': subQuestions.map((e) => e.toJson()).toList(),
    };
  }
}

class SubQuestionStructure {
  String? id;
  String subQuestionNo;
  double marks;

  SubQuestionStructure({
    this.id,
    required this.subQuestionNo,
    required this.marks,
  });

  factory SubQuestionStructure.fromJson(Map<String, dynamic> json) {
    return SubQuestionStructure(
      id: json['id'],
      subQuestionNo: json['sub_q_no'] ?? '',
      marks: (json['marks'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sub_q_no': subQuestionNo,
      'marks': marks,
    };
  }
}
