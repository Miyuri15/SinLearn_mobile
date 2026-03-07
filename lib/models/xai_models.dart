// lib/models/xai_models.dart

class XaiResponse {
  final XaiExplanation? xaiExplanation;

  const XaiResponse({this.xaiExplanation});

  factory XaiResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['xai_explanation'];
    final explanation = raw is Map
        ? XaiExplanation.fromJson(Map<String, dynamic>.from(raw))
        : null;

    return XaiResponse(xaiExplanation: explanation);
  }

  Map<String, dynamic> toJson() {
    return {
      if (xaiExplanation != null) 'xai_explanation': xaiExplanation!.toJson(),
    };
  }
}

class XaiExplanation {
  final ConceptTracing? conceptTracing;
  final RetrievalStats? retrievalStats;
  final SafetyExplanation? safetyExplanation;
  final List<ChunkContribution> chunkContributions;
  final String? explanationSummary;
  final ConfidenceBreakdown? confidenceBreakdown;

  const XaiExplanation({
    this.conceptTracing,
    this.retrievalStats,
    this.safetyExplanation,
    this.chunkContributions = const [],
    this.explanationSummary,
    this.confidenceBreakdown,
  });

  factory XaiExplanation.fromJson(Map<String, dynamic> json) {
    final rawChunks = json['chunk_contributions'];
    final chunks = rawChunks is List
        ? rawChunks
            .whereType<Map>()
            .map(
                (e) => ChunkContribution.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <ChunkContribution>[];

    final rawConceptTracing = json['concept_tracing'];
    final rawRetrievalStats = json['retrieval_stats'];
    final rawSafetyExplanation = json['safety_explanation'];
    final rawConfidenceBreakdown = json['confidence_breakdown'];

    return XaiExplanation(
      conceptTracing: rawConceptTracing is Map
          ? ConceptTracing.fromJson(
              Map<String, dynamic>.from(rawConceptTracing))
          : null,
      retrievalStats: rawRetrievalStats is Map
          ? RetrievalStats.fromJson(
              Map<String, dynamic>.from(rawRetrievalStats))
          : null,
      safetyExplanation: rawSafetyExplanation is Map
          ? SafetyExplanation.fromJson(
              Map<String, dynamic>.from(rawSafetyExplanation))
          : null,
      chunkContributions: chunks,
      explanationSummary: json['explanation_summary']?.toString(),
      confidenceBreakdown: rawConfidenceBreakdown is Map
          ? ConfidenceBreakdown.fromJson(
              Map<String, dynamic>.from(rawConfidenceBreakdown),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (conceptTracing != null) 'concept_tracing': conceptTracing!.toJson(),
      if (retrievalStats != null) 'retrieval_stats': retrievalStats!.toJson(),
      if (safetyExplanation != null)
        'safety_explanation': safetyExplanation!.toJson(),
      'chunk_contributions': chunkContributions.map((c) => c.toJson()).toList(),
      if (explanationSummary != null) 'explanation_summary': explanationSummary,
      if (confidenceBreakdown != null)
        'confidence_breakdown': confidenceBreakdown!.toJson(),
    };
  }
}

class ConceptTracing {
  final int totalConcepts;
  final List<ConceptDetail> conceptDetails;
  final int conceptsWithSources;

  const ConceptTracing({
    required this.totalConcepts,
    required this.conceptDetails,
    required this.conceptsWithSources,
  });

  factory ConceptTracing.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['concept_details'];
    final details = rawDetails is List
        ? rawDetails
            .whereType<Map>()
            .map((e) => ConceptDetail.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <ConceptDetail>[];

    return ConceptTracing(
      totalConcepts: _toInt(json['total_concepts']),
      conceptDetails: details,
      conceptsWithSources: _toInt(json['concepts_with_sources']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_concepts': totalConcepts,
      'concept_details': conceptDetails.map((c) => c.toJson()).toList(),
      'concepts_with_sources': conceptsWithSources,
    };
  }
}

class ConceptDetail {
  final String concept;
  final List<ConceptSource> sources;
  final int sourceCount;
  final bool foundInSources;

  const ConceptDetail({
    required this.concept,
    required this.sources,
    required this.sourceCount,
    required this.foundInSources,
  });

  factory ConceptDetail.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final sources = rawSources is List
        ? rawSources
            .whereType<Map>()
            .map((e) => ConceptSource.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <ConceptSource>[];

    return ConceptDetail(
      concept: json['concept']?.toString() ?? '',
      sources: sources,
      sourceCount: _toInt(json['source_count']),
      foundInSources: json['found_in_sources'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'concept': concept,
      'sources': sources.map((s) => s.toJson()).toList(),
      'source_count': sourceCount,
      'found_in_sources': foundInSources,
    };
  }
}

class ConceptSource {
  final String preview;
  final int chunkRank;

  const ConceptSource({required this.preview, required this.chunkRank});

  factory ConceptSource.fromJson(Map<String, dynamic> json) {
    return ConceptSource(
      preview: json['preview']?.toString() ?? '',
      chunkRank: _toInt(json['chunk_rank']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preview': preview,
      'chunk_rank': chunkRank,
    };
  }
}

class RetrievalStats {
  final int bm25K;
  final int finalK;
  final int usedChunks;

  const RetrievalStats({
    required this.bm25K,
    required this.finalK,
    required this.usedChunks,
  });

  factory RetrievalStats.fromJson(Map<String, dynamic> json) {
    return RetrievalStats(
      bm25K: _toInt(json['bm25_k']),
      finalK: _toInt(json['final_k']),
      usedChunks: _toInt(json['used_chunks']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bm25_k': bm25K,
      'final_k': finalK,
      'used_chunks': usedChunks,
    };
  }
}

class SafetyExplanation {
  final List<SafetyDetail> details;
  final bool hasIssues;
  final int flaggedCount;
  final int extraConceptsCount;
  final int missingConceptsCount;

  const SafetyExplanation({
    required this.details,
    required this.hasIssues,
    required this.flaggedCount,
    required this.extraConceptsCount,
    required this.missingConceptsCount,
  });

  factory SafetyExplanation.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final details = rawDetails is List
        ? rawDetails
            .whereType<Map>()
            .map((e) => SafetyDetail.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <SafetyDetail>[];

    return SafetyExplanation(
      details: details,
      hasIssues: json['has_issues'] == true,
      flaggedCount: _toInt(json['flagged_count']),
      extraConceptsCount: _toInt(json['extra_concepts_count']),
      missingConceptsCount: _toInt(json['missing_concepts_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'details': details.map((d) => d.toJson()).toList(),
      'has_issues': hasIssues,
      'flagged_count': flaggedCount,
      'extra_concepts_count': extraConceptsCount,
      'missing_concepts_count': missingConceptsCount,
    };
  }
}

class SafetyDetail {
  final String type;
  final String? sentence;
  final String? severity;
  final String? explanation;
  final double? unseenRatio;
  final List<String> concepts;

  const SafetyDetail({
    required this.type,
    this.sentence,
    this.severity,
    this.explanation,
    this.unseenRatio,
    this.concepts = const [],
  });

  factory SafetyDetail.fromJson(Map<String, dynamic> json) {
    final rawConcepts = json['concepts'];
    final concepts = rawConcepts is List
        ? rawConcepts.map((e) => e.toString()).toList()
        : const <String>[];

    return SafetyDetail(
      type: json['type']?.toString() ?? '',
      sentence: json['sentence']?.toString(),
      severity: json['severity']?.toString(),
      explanation: json['explanation']?.toString(),
      unseenRatio: _toDouble(json['unseen_ratio']),
      concepts: concepts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (sentence != null) 'sentence': sentence,
      if (severity != null) 'severity': severity,
      if (explanation != null) 'explanation': explanation,
      if (unseenRatio != null) 'unseen_ratio': unseenRatio,
      'concepts': concepts,
    };
  }
}

class ChunkContribution {
  final int rank;
  final String preview;
  final String chunkId;
  final List<String> keyTerms;
  final double similarityScore;
  final double contributionScore;

  const ChunkContribution({
    required this.rank,
    required this.preview,
    required this.chunkId,
    required this.keyTerms,
    required this.similarityScore,
    required this.contributionScore,
  });

  factory ChunkContribution.fromJson(Map<String, dynamic> json) {
    final rawTerms = json['key_terms'];
    final terms = rawTerms is List
        ? rawTerms.map((e) => e.toString()).toList()
        : const <String>[];

    return ChunkContribution(
      rank: _toInt(json['rank']),
      preview: json['preview']?.toString() ?? '',
      chunkId: json['chunk_id']?.toString() ?? '',
      keyTerms: terms,
      similarityScore: _toDouble(json['similarity_score']) ?? 0,
      contributionScore: _toDouble(json['contribution_score']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'preview': preview,
      'chunk_id': chunkId,
      'key_terms': keyTerms,
      'similarity_score': similarityScore,
      'contribution_score': contributionScore,
    };
  }
}

class ConfidenceBreakdown {
  final double? overall;
  final List<ConfidenceComponent> components;

  const ConfidenceBreakdown({
    this.overall,
    required this.components,
  });

  factory ConfidenceBreakdown.fromJson(Map<String, dynamic> json) {
    final rawComponents = json['components'];
    final components = rawComponents is List
        ? rawComponents
            .whereType<Map>()
            .map(
              (e) => ConfidenceComponent.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : const <ConfidenceComponent>[];

    return ConfidenceBreakdown(
      overall: _toDouble(json['overall']),
      components: components,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (overall != null) 'overall': overall,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }
}

class ConfidenceComponent {
  final String name;
  final double? score;
  final double? weight;

  const ConfidenceComponent({
    required this.name,
    this.score,
    this.weight,
  });

  factory ConfidenceComponent.fromJson(Map<String, dynamic> json) {
    return ConfidenceComponent(
      name: json['name']?.toString() ?? '',
      score: _toDouble(json['score']),
      weight: _toDouble(json['weight']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (score != null) 'score': score,
      if (weight != null) 'weight': weight,
    };
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
