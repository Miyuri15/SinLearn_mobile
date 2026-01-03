class PaperConfig {
  final String id;
  final String subjectName;
  final String medium;
  String paperPart;                
  int totalMarks;                  
  int totalMainQuestions;          
  SelectionRules selectionRules;   
  bool isConfirmed;  
  List<QuestionStructure> questions;

  PaperConfig({
    required this.id,
    required this.paperPart,
    required this.subjectName,
    required this.medium,
    required this.totalMarks,
    required this.totalMainQuestions,
    required this.selectionRules,
    required this.isConfirmed,
    required this.questions,
  });

  factory PaperConfig.fromJson(Map<String, dynamic> json) {
    return PaperConfig(
      id: json['id'],
      paperPart: json['paper_part'],
      subjectName: json['subject_name'],
      medium: json['medium'],
      totalMarks: json['total_marks'],
      totalMainQuestions: json['total_main_questions'],
      selectionRules: SelectionRules.fromJson(json['selection_rules']),
      isConfirmed: json['is_confirmed'],
      questions: (json['questions'] as List? ?? [])
          .map((e) => QuestionStructure.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'paper_part': paperPart,
        'total_marks': totalMarks,
        'total_main_questions': totalMainQuestions,
        'selection_rules': selectionRules.toJson(),
        'questions': questions.map((e) => e.toJson()).toList(),
      };
}

class SelectionRules {
  final int? chooseAny;
  final String? mode;

  SelectionRules({this.chooseAny, this.mode});

  factory SelectionRules.fromJson(Map<String, dynamic> json) {
    return SelectionRules(
      chooseAny: json['choose_any'],
      mode: json['mode'],
    );
  }

  Map<String, dynamic> toJson() => {
        'choose_any': chooseAny,
        'mode': mode,
      };
}

class QuestionStructure {
  int questionNo;
  double marks;
  bool hasSubQuestions;
  List<SubQuestionStructure> subQuestions;

  QuestionStructure({
    required this.questionNo,
    this.marks = 0,
    this.hasSubQuestions = false,
    this.subQuestions = const [],
  });

  factory QuestionStructure.fromJson(Map<String, dynamic> json) {
    return QuestionStructure(
      questionNo: json['question_no'],
      marks: (json['marks'] ?? 0).toDouble(),
      hasSubQuestions: json['has_sub_questions'] ?? false,
      subQuestions: (json['sub_questions'] as List? ?? [])
          .map((e) => SubQuestionStructure.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'question_no': questionNo,
        'marks': marks,
        'has_sub_questions': hasSubQuestions,
        'sub_questions': subQuestions.map((e) => e.toJson()).toList(),
      };
}

class SubQuestionStructure {
  String label;
  double marks;

  SubQuestionStructure({required this.label, this.marks = 0});

  factory SubQuestionStructure.fromJson(Map<String, dynamic> json) {
    return SubQuestionStructure(
      label: json['sub_q_no'],
      marks: (json['marks'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sub_q_no': label,
        'marks': marks,
      };
}
