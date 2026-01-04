import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys used by evaluation flow.
class EvalDocKeys {
  static const String attachment = 'evaluation_attachment';
  static const String evaluationData = 'evaluation_data';
  static const String hasRubric = 'hasRubric';
  static const String rubricNameTeacher = 'rubricName';
  static const String rubricNameStudent = 'appliedRubricName';
  static const String isCustomRubric = 'isCustomRubric';
  static const String hasCustomRubric = 'hasCustomRubric';
  static const String semantic = 'semantic';
  static const String coverage = 'coverage';
  static const String relevance = 'relevance';
  static const String customSemantic = 'custom_semantic';
  static const String customCoverage = 'custom_coverage';
  static const String customRelevance = 'custom_relevance';
  static const String paperConfigConfirmed = 'paper_config_confirmed';
  static const String questionPaperFile = 'question_paper_file';
  static const String syllabusItems = 'syllabus_items';

  /// Stores the token snapshot from the last successful "Process Documents".
  static const String processedTokens = 'evaluation_processed_tokens_v1';
}

/// Generates and compares stable "tokens" for uploaded documents.
///
/// If any token changes (new answer sheet, new question paper, syllabus edits,
/// rubric/marks changes), the documents must be processed again before
/// evaluating.
class EvalDocTokens {
  static Map<String, String> buildCurrent(SharedPreferences prefs) {
    final answerSheetName = prefs.getString(EvalDocKeys.attachment) ?? '';
    final questionPaperRaw =
        prefs.getString(EvalDocKeys.questionPaperFile) ?? '';
    final syllabus =
        prefs.getStringList(EvalDocKeys.syllabusItems) ?? const <String>[];

    final rubricSnapshot = <String, Object?>{
      'hasRubric': prefs.getBool(EvalDocKeys.hasRubric) ?? false,
      // Teacher flow
      'rubricName': prefs.getString(EvalDocKeys.rubricNameTeacher) ?? '',
      'semantic': prefs.getInt(EvalDocKeys.semantic),
      'coverage': prefs.getInt(EvalDocKeys.coverage),
      'relevance': prefs.getInt(EvalDocKeys.relevance),
      // Student flow
      'appliedRubricName': prefs.getString(EvalDocKeys.rubricNameStudent) ?? '',
      'isCustomRubric': prefs.getBool(EvalDocKeys.isCustomRubric) ?? false,
      // Custom rubric upload flow
      'hasCustomRubric': prefs.getBool(EvalDocKeys.hasCustomRubric) ?? false,
      'custom_semantic': prefs.getInt(EvalDocKeys.customSemantic),
      'custom_coverage': prefs.getInt(EvalDocKeys.customCoverage),
      'custom_relevance': prefs.getInt(EvalDocKeys.customRelevance),
    };
    final rubricToken = _fnv1a32Hex(jsonEncode(rubricSnapshot));

    final legacyMarks = prefs.getString(EvalDocKeys.evaluationData) ?? '';
    final paperConfirmed =
        (prefs.getBool(EvalDocKeys.paperConfigConfirmed) ?? false).toString();

    return <String, String>{
      'answerSheets': answerSheetName,
      'questionPaper': _fnv1a32Hex(questionPaperRaw),
      'syllabus': _fnv1a32Hex(jsonEncode(syllabus)),
      'rubric': rubricToken,
      'paperConfig': _fnv1a32Hex('$legacyMarks|$paperConfirmed'),
    };
  }

  static Map<String, String>? loadProcessed(SharedPreferences prefs) {
    final raw = prefs.getString(EvalDocKeys.processedTokens);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProcessed(
      SharedPreferences prefs, Map<String, String> tokens) async {
    await prefs.setString(EvalDocKeys.processedTokens, jsonEncode(tokens));
  }

  static bool equals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static String? tokenForStep(Map<String, String> tokens, String stepKey) {
    return tokens[stepKey];
  }
}

// Simple stable hash (FNV-1a 32-bit). Good enough for change detection.
String _fnv1a32Hex(String input) {
  const int fnvPrime = 0x01000193;
  const int fnvOffset = 0x811C9DC5;

  var hash = fnvOffset;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
