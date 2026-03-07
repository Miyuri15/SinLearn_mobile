import 'package:flutter/material.dart';

import '../../../models/xai_models.dart';

class XaiSafetySummarySection extends StatelessWidget {
  const XaiSafetySummarySection({
    super.key,
    required this.safetySummary,
    required this.isExplainLoading,
    this.onExplainTap,
  });

  final Map<String, dynamic> safetySummary;
  final bool isExplainLoading;
  final VoidCallback? onExplainTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (safetySummary['overall_severity'] != null)
                _buildMetricChip(
                  context,
                  label: 'Severity',
                  value: safetySummary['overall_severity']
                      .toString()
                      .toUpperCase(),
                  color: _getSeverityColor(safetySummary['overall_severity']),
                ),
              if (safetySummary['confidence_score'] != null)
                _buildMetricChip(
                  context,
                  label: 'Confidence',
                  value:
                      '${(safetySummary['confidence_score'] * 100).toStringAsFixed(0)}%',
                  color: Colors.blue,
                ),
              if (safetySummary['reliability'] != null)
                _buildMetricChip(
                  context,
                  label: 'Status',
                  value: safetySummary['reliability']
                      .toString()
                      .replaceAll('_', ' '),
                  color: Colors.teal,
                ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: isExplainLoading ? null : onExplainTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How I got this answer',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isExplainLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class XaiExplanationSheet extends StatelessWidget {
  const XaiExplanationSheet({
    super.key,
    required this.response,
  });

  final XaiResponse response;

  @override
  Widget build(BuildContext context) {
    final xai = response.xaiExplanation;
    if (xai == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (sheetContext, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'How I got this answer',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (xai.confidenceBreakdown?.overall != null)
                _ConfidenceMetric(score: xai.confidenceBreakdown!.overall!),
              if (xai.explanationSummary != null &&
                  xai.explanationSummary!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    xai.explanationSummary!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
              if (xai.retrievalStats != null)
                _RetrievalStatsRow(stats: xai.retrievalStats!),
              const SizedBox(height: 18),
              Text(
                'Sources & Contributions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...xai.chunkContributions.map((chunk) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SourceCard(chunk: chunk),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _ConfidenceMetric extends StatelessWidget {
  const _ConfidenceMetric({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = (score * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              value: score.clamp(0, 1),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$percentage% Confidence',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetrievalStatsRow extends StatelessWidget {
  const _RetrievalStatsRow({required this.stats});

  final RetrievalStats stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(label: 'BM25 K', value: stats.bm25K.toString()),
        _StatChip(label: 'Final K', value: stats.finalK.toString()),
        _StatChip(label: 'Used Chunks', value: stats.usedChunks.toString()),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelMedium,
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.chunk});

  final ChunkContribution chunk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Source #${chunk.rank}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(chunk.contributionScore * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            chunk.preview,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

Widget _buildMetricChip(BuildContext context,
    {required String label, required String value, required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
        children: [
          TextSpan(
              text: '$label: ',
              style: TextStyle(color: color.withOpacity(0.8))),
          TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

Color _getSeverityColor(dynamic severity) {
  if (severity == 'low') return Colors.green;
  if (severity == 'medium') return Colors.orange;
  return Colors.red;
}
