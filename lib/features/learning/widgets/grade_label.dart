// lib/features/learning/widgets/grade_label.dart
import 'package:flutter/material.dart';

class GradeLabel extends StatelessWidget {
  final String gradeLevel;

  const GradeLabel({
    super.key,
    required this.gradeLevel,
  });

  String _formatGradeLevel(String gradeLevel) {
    switch (gradeLevel) {
      case 'grade_6_8':
        return 'Grades 6-8';
      case 'grade_9_11':
        return 'Grades 9-11';
      case 'grade_12_13':
        return 'Grades 12-13';
      case 'grade_12_plus':
        return 'Grades 12+';
      default:
        return gradeLevel.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getGradeColor(String gradeLevel) {
    switch (gradeLevel) {
      case 'grade_6_8':
        return Colors.green;
      case 'grade_9_11':
        return Colors.blue;
      case 'grade_12_13':
        return Colors.purple;
      case 'grade_12_plus':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGradeColor(gradeLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatGradeLevel(gradeLevel),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
