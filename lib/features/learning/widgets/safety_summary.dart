// lib/features/learning/widgets/safety_summary.dart
import 'package:flutter/material.dart';

class SafetySummary extends StatelessWidget {
  final Map<String, dynamic> summary;

  const SafetySummary({
    super.key,
    required this.summary,
  });

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'low':
        return Icons.check_circle_outline;
      case 'medium':
        return Icons.warning_amber_outlined;
      case 'high':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getReliabilityColor(String reliability) {
    switch (reliability) {
      case 'fully_supported':
        return Colors.green;
      case 'partially_supported':
        return Colors.orange;
      case 'likely_unsupported':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatReliability(String reliability) {
    switch (reliability) {
      case 'fully_supported':
        return 'Fully Supported';
      case 'partially_supported':
        return 'Partially Supported';
      case 'likely_unsupported':
        return 'Verify Before Using';
      default:
        return reliability.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getReliabilityDescription(String reliability) {
    switch (reliability) {
      case 'fully_supported':
        return 'Directly matches source material';
      case 'partially_supported':
        return 'Some concepts match sources, some added by AI';
      case 'likely_unsupported':
        return 'Limited support from source materials';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = summary['overall_severity']?.toString() ?? 'low';
    final reliability =
        summary['reliability']?.toString() ?? 'likely_unsupported';
    final confidenceScore =
        (summary['confidence_score'] as num?)?.toDouble() ?? 0.0;

    final severityColor = _getSeverityColor(severity);
    final reliabilityColor = _getReliabilityColor(reliability);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Severity Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: severityColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSeverityIcon(severity),
                size: 14,
                color: severityColor,
              ),
              const SizedBox(width: 4),
              Text(
                severity.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: severityColor,
                ),
              ),
            ],
          ),
        ),

        // Reliability Indicator
        Tooltip(
          message: _getReliabilityDescription(reliability),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reliability == 'fully_supported'
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  size: 14,
                  color: reliabilityColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatReliability(reliability),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: reliabilityColor,
                  ),
                ),
                const SizedBox(width: 6),
                // Confidence bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: confidenceScore.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: reliabilityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
