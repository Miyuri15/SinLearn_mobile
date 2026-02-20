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
      id: (json['id'] ?? '').toString(),
      paperPart: (json['paper_part'] ?? '').toString(),
      subjectName: (json['subject_name'] ?? '').toString(),
      medium: (json['medium'] ?? '').toString(),
      totalMarks: (json['total_marks'] ?? 0) is num
          ? (json['total_marks'] as num).toInt()
          : int.tryParse((json['total_marks'] ?? 0).toString()) ?? 0,
      totalMainQuestions: (json['total_main_questions'] ?? 0) is num
          ? (json['total_main_questions'] as num).toInt()
          : int.tryParse((json['total_main_questions'] ?? 0).toString()) ?? 0,
      selectionRules: SelectionRules.fromJson(
        (json['selection_rules'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      isConfirmed: json['is_confirmed'] == true,
      questions: (json['questions'] as List? ?? [])
          .map((e) => QuestionStructure.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'paper_part': paperPart,
      'subject_name': subjectName,
      'medium': medium,
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
      chooseAny: (json['choose_any'] is num)
          ? (json['choose_any'] as num).toInt()
          : int.tryParse((json['choose_any'] ?? '').toString()),
      mode: json['mode']?.toString(),
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
