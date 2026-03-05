// lib/features/learning/widgets/xai_panel.dart
import 'package:flutter/material.dart';
import '../../../models/xai_models.dart';

class XAIPanel extends StatefulWidget {
  final XaiExplanation? explanation;
  final bool isLoading;

  const XAIPanel({
    super.key,
    this.explanation,
    this.isLoading = false,
  });

  @override
  State<XAIPanel> createState() => _XAIPanelState();
}

class _XAIPanelState extends State<XAIPanel> {
  final Set<String> _expandedSections = {'sources', 'concepts', 'safety'};
  bool _showAllConcepts = false;
  bool _showAllFlagged = false;
  bool _showAllMissing = false;
  bool _showAllExtra = false;
  final Map<int, bool> _showAllKeyTerms = {};

  void _toggleSection(String section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.remove(section);
      } else {
        _expandedSections.add(section);
      }
    });
  }

  Map<String, dynamic> _getQualityIndicator(String summary) {
    if (summary.contains('highly confident')) {
      return {
        'icon': Icons.auto_awesome,
        'label': 'High Confidence',
        'color': Colors.green,
        'bg': Colors.green.shade50,
      };
    }
    if (summary.contains('confident')) {
      return {
        'icon': Icons.check_circle,
        'label': 'Confident',
        'color': Colors.blue,
        'bg': Colors.blue.shade50,
      };
    }
    if (summary.contains('cautious')) {
      return {
        'icon': Icons.warning_amber_rounded,
        'label': 'Verify Recommended',
        'color': Colors.orange,
        'bg': Colors.orange.shade50,
      };
    }
    return {
      'icon': Icons.info,
      'label': 'Limited Confidence',
      'color': Colors.grey,
      'bg': Colors.grey.shade50,
    };
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Analyzing how I got this answer...'),
            ],
          ),
        ),
      );
    }

    if (widget.explanation == null) return const SizedBox.shrink();

    final explanation = widget.explanation!;
    final quality = _getQualityIndicator(explanation.explanationSummary ?? '');
    final conceptDetails = explanation.conceptTracing?.conceptDetails ?? [];
    final displayedConcepts =
        _showAllConcepts ? conceptDetails : conceptDetails.take(8).toList();

    // Safety details
    final safetyDetails = explanation.safetyExplanation?.details ?? [];
    final flaggedDetails =
        safetyDetails.where((d) => d.type == 'flagged_sentence').toList();
    final missingDetails =
        safetyDetails.where((d) => d.type == 'missing_concepts').toList();
    final extraDetails =
        safetyDetails.where((d) => d.type == 'extra_concepts').toList();

    final displayedFlagged =
        _showAllFlagged ? flaggedDetails : flaggedDetails.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade50,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: quality['bg'],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    quality['icon'],
                    size: 18,
                    color: quality['color'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        explanation.explanationSummary ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (explanation.chunkContributions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Based on ${explanation.chunkContributions.length} source${explanation.chunkContributions.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sources Section
          if (explanation.chunkContributions.isNotEmpty)
            _buildExpandableSection(
              title: 'Sources Used (${explanation.chunkContributions.length})',
              icon: Icons.menu_book,
              section: 'sources',
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Column(
                  children: explanation.chunkContributions
                      .asMap()
                      .entries
                      .map((entry) => _buildSourceCard(
                            entry.value,
                            entry.key,
                            theme,
                          ))
                      .toList(),
                ),
              ),
            ),

          // Concepts Section
          if (explanation.conceptTracing != null)
            _buildExpandableSection(
              title:
                  'Key Ideas Used (${explanation.conceptTracing!.conceptsWithSources}/${explanation.conceptTracing!.totalConcepts} from sources)',
              icon: Icons.lightbulb_outline,
              section: 'concepts',
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displayedConcepts.map((concept) {
                        return Tooltip(
                          message: concept.foundInSources
                              ? 'Found in source ${concept.sources.map((s) => s.chunkRank).join(", ")}'
                              : 'Added by AI, not in sources',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: concept.foundInSources
                                  ? Colors.green.shade50
                                  : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: concept.foundInSources
                                    ? Colors.green.shade200
                                    : Colors.amber.shade200,
                              ),
                            ),
                            child: Text(
                              concept.concept,
                              style: TextStyle(
                                fontSize: 11,
                                color: concept.foundInSources
                                    ? Colors.green.shade700
                                    : Colors.amber.shade700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (conceptDetails.length > 8)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllConcepts = !_showAllConcepts;
                          });
                        },
                        child: Text(
                          _showAllConcepts
                              ? 'Show fewer'
                              : 'Show all ${conceptDetails.length} ideas',
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Safety Section
          if (explanation.safetyExplanation?.hasIssues == true)
            _buildExpandableSection(
              title: 'Things to Review '
                  '(${explanation.safetyExplanation!.flaggedCount} flagged, '
                  '${explanation.safetyExplanation!.missingConceptsCount} missing, '
                  '${explanation.safetyExplanation!.extraConceptsCount} extra)',
              icon: Icons.warning_amber_rounded,
              section: 'safety',
              warningColor: true,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amber.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flagged Sentences
                    if (flaggedDetails.isNotEmpty) ...[
                      const Text(
                        'Flagged Sentences',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...displayedFlagged
                          .map((detail) => _buildFlaggedSentenceCard(detail)),
                      if (flaggedDetails.length > 3)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllFlagged = !_showAllFlagged;
                            });
                          },
                          child: Text(
                            _showAllFlagged
                                ? 'Show fewer flagged sentences'
                                : 'Show all ${flaggedDetails.length} flagged sentences',
                          ),
                        ),
                    ],

                    // Missing Concepts
                    if (missingDetails.isNotEmpty)
                      ...missingDetails
                          .map((detail) => _buildMissingConceptsCard(detail)),

                    // Extra Concepts
                    if (extraDetails.isNotEmpty)
                      ...extraDetails
                          .map((detail) => _buildExtraConceptsCard(detail)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required String section,
    required Widget child,
    bool warningColor = false,
  }) {
    final isExpanded = _expandedSections.contains(section);
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleSection(section),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: warningColor ? Colors.amber.shade700 : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: warningColor ? Colors.amber.shade700 : null,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) child,
      ],
    );
  }

  Widget _buildSourceCard(ChunkContribution chunk, int index, ThemeData theme) {
    final showAllTerms = _showAllKeyTerms[index] ?? false;
    final displayedTerms =
        showAllTerms ? chunk.keyTerms : chunk.keyTerms.take(4).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Source ${chunk.rank}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const Spacer(),
              if (chunk.similarityScore > 0.7)
                Tooltip(
                  message: 'Highly relevant to your question',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Highly Relevant',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            chunk.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
          if (chunk.keyTerms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Key terms found:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (chunk.keyTerms.length > 4)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllKeyTerms[index] = !showAllTerms;
                      });
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      showAllTerms
                          ? 'Show less'
                          : 'Show all ${chunk.keyTerms.length}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: displayedTerms.map((term) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    term,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlaggedSentenceCard(SafetyDetail detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getSeverityIcon(detail.severity ?? 'low'),
            size: 16,
            color: _getSeverityColor(detail.severity ?? 'low'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(detail.severity ?? 'low')
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (detail.severity ?? 'low').toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getSeverityColor(detail.severity ?? 'low'),
                        ),
                      ),
                    ),
                    if (detail.unseenRatio != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${(detail.unseenRatio! * 100).toStringAsFixed(0)}% unsupported',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail.explanation ?? '',
                  style: const TextStyle(fontSize: 11),
                ),
                if (detail.sentence != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.amber.shade300,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      '"${detail.sentence}"',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingConceptsCard(SafetyDetail detail) {
    final showAll = _showAllMissing;
    final displayedConcepts =
        showAll ? detail.concepts : detail.concepts.take(20).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.close, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Missing Concepts (${detail.concepts.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail.explanation ?? '',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: displayedConcepts.map((concept) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  concept,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                  ),
                ),
              );
            }).toList(),
          ),
          if (detail.concepts.length > 20)
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllMissing = !_showAllMissing;
                });
              },
              child: Text(
                showAll
                    ? 'Show fewer concepts'
                    : 'Show all ${detail.concepts.length} missing concepts',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExtraConceptsCard(SafetyDetail detail) {
    final showAll = _showAllExtra;
    final displayedConcepts =
        showAll ? detail.concepts : detail.concepts.take(20).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, size: 16, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'Extra Concepts Not in Sources (${detail.concepts.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail.explanation ?? '',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: displayedConcepts.map((concept) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Text(
                  concept,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple.shade700,
                  ),
                ),
              );
            }).toList(),
          ),
          if (detail.concepts.length > 20)
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllExtra = !_showAllExtra;
                });
              },
              child: Text(
                showAll
                    ? 'Show fewer concepts'
                    : 'Show all ${detail.concepts.length} extra concepts',
              ),
            ),
        ],
      ),
    );
  }
}
