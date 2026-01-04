class SessionResource {
  final String resourceId;
  final String? resourceType;
  final String filename;
  final int sizeBytes;
  final String mimeType;

  const SessionResource({
    required this.resourceId,
    required this.filename,
    required this.sizeBytes,
    required this.mimeType,
    this.resourceType,
  });

  SessionResource copyWith({
    String? filename,
    int? sizeBytes,
    String? mimeType,
    String? resourceType,
  }) {
    return SessionResource(
      resourceId: resourceId,
      filename: filename ?? this.filename,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      resourceType: resourceType ?? this.resourceType,
    );
  }

  factory SessionResource.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? nestedResource = (json['resource'] is Map)
        ? Map<String, dynamic>.from(json['resource'])
        : null;

    final dynamic idRaw = json['resource_id'] ??
        json['id'] ??
        json['resourceId'] ??
        json['resourceID'];
    final dynamic filenameRaw = json['filename'] ??
        json['file_name'] ??
        json['name'] ??
        json['original_filename'] ??
        nestedResource?['filename'] ??
        nestedResource?['file_name'] ??
        nestedResource?['name'] ??
        nestedResource?['original_filename'];
    final dynamic sizeRaw = json['size_bytes'] ??
        json['size'] ??
        json['bytes'] ??
        json['file_size'] ??
        nestedResource?['size_bytes'] ??
        nestedResource?['size'] ??
        nestedResource?['bytes'] ??
        nestedResource?['file_size'];
    final dynamic mimeRaw = json['mime_type'] ??
        json['content_type'] ??
        json['mimeType'] ??
        json['mimetype'] ??
        nestedResource?['mime_type'] ??
        nestedResource?['content_type'] ??
        nestedResource?['mimeType'] ??
        nestedResource?['mimetype'];
    final dynamic typeRaw = json['resource_type'] ??
        json['type'] ??
        json['document_type'] ??
        json['kind'] ??
        json['label'] ??
        nestedResource?['resource_type'] ??
        nestedResource?['type'] ??
        nestedResource?['document_type'] ??
        nestedResource?['kind'] ??
        nestedResource?['label'];

    int parseSize(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return SessionResource(
      resourceId: idRaw?.toString() ?? '',
      filename: filenameRaw?.toString() ?? '',
      sizeBytes: parseSize(sizeRaw),
      mimeType: mimeRaw?.toString() ?? 'application/octet-stream',
      resourceType: typeRaw?.toString(),
    );
  }
}

class ChatSessionDetails {
  final String id;
  final List<SessionResource> resources;
  final String? rubricId;

  const ChatSessionDetails({
    required this.id,
    required this.resources,
    this.rubricId,
  });

  static String _canonicalType(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return '';

    // Normalize separators.
    final normalized = v
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll('__', '_');

    // Coarse canonical mapping by containment.
    if (normalized.contains('syllabus')) return 'syllabus';
    if (normalized.contains('question') && normalized.contains('paper')) {
      return 'question_paper';
    }
    if (normalized.contains('answer') &&
        (normalized.contains('sheet') || normalized.contains('script'))) {
      return 'answer_sheet';
    }

    // Common exact/legacy variants.
    if (normalized == 'answer_sheets') return 'answer_sheet';
    if (normalized == 'answer_sheet') return 'answer_sheet';
    if (normalized == 'questionpaper') return 'question_paper';
    if (normalized == 'question_papers') return 'question_paper';

    return normalized;
  }

  SessionResource? firstByType(String type) {
    final target = _canonicalType(type);
    for (final r in resources) {
      if (_canonicalType(r.resourceType) == target) return r;
    }
    return null;
  }

  List<SessionResource> allByType(String type) {
    final target = _canonicalType(type);
    return resources
      .where((r) => _canonicalType(r.resourceType) == target)
        .toList();
  }

  SessionResource? get questionPaper => firstByType('question_paper');
  SessionResource? get syllabus => firstByType('syllabus');

  List<SessionResource> get answerSheets {
    return allByType('answer_sheet');
  }

  factory ChatSessionDetails.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final rubricId = (json['rubric_id'] ??
            json['rubricId'] ??
            (json['rubric'] is Map
                ? (json['rubric']['id'] ?? json['rubric']['rubric_id'])
                : null))
        ?.toString();

    List<dynamic>? list;
    final dynamic candidate = json['resources'] ??
        json['uploads'] ??
        json['documents'] ??
        json['attached_resources'] ??
        json['resource_uploads'] ??
        json['data'];

    if (candidate is List) {
      list = candidate;
    }

    final resources = <SessionResource>[];

    if (list != null) {
      for (final e in list) {
        if (e is Map) {
          resources.add(SessionResource.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    // Also support envelope fields for single documents
    final dynamic qp = json['question_paper'];
    if (qp is Map) {
      final map = Map<String, dynamic>.from(qp);
      map.putIfAbsent('resource_type', () => 'question_paper');
      resources.add(SessionResource.fromJson(map));
    }

    final dynamic syl = json['syllabus'];
    if (syl is Map) {
      final map = Map<String, dynamic>.from(syl);
      map.putIfAbsent('resource_type', () => 'syllabus');
      resources.add(SessionResource.fromJson(map));
    }

    return ChatSessionDetails(id: id, resources: resources, rubricId: rubricId);
  }
}
