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

  SessionResource? firstByType(String type) {
    for (final r in resources) {
      if ((r.resourceType ?? '').toLowerCase() == type.toLowerCase()) return r;
    }
    return null;
  }

  List<SessionResource> allByType(String type) {
    final target = type.toLowerCase();
    return resources
        .where((r) => (r.resourceType ?? '').toLowerCase() == target)
        .toList();
  }

  SessionResource? get questionPaper => firstByType('question_paper');
  SessionResource? get syllabus => firstByType('syllabus');

  List<SessionResource> get answerSheets {
    final a = allByType('answer_sheet');
    if (a.isNotEmpty) return a;
    return allByType('answer_sheets');
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
