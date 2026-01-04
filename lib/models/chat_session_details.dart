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
    final dynamic idRaw =
        json['resource_id'] ?? json['id'] ?? json['resourceId'] ?? json['resourceID'];
    final dynamic filenameRaw =
        json['filename'] ?? json['file_name'] ?? json['name'] ?? json['original_filename'];
    final dynamic sizeRaw =
        json['size_bytes'] ?? json['size'] ?? json['bytes'] ?? json['file_size'];
    final dynamic mimeRaw =
        json['mime_type'] ?? json['content_type'] ?? json['mimeType'] ?? json['mimetype'];
    final dynamic typeRaw =
        json['resource_type'] ?? json['type'] ?? json['document_type'] ?? json['kind'];

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

  const ChatSessionDetails({
    required this.id,
    required this.resources,
  });

  SessionResource? firstByType(String type) {
    for (final r in resources) {
      if ((r.resourceType ?? '').toLowerCase() == type.toLowerCase()) return r;
    }
    return null;
  }

  SessionResource? get questionPaper => firstByType('question_paper');
  SessionResource? get syllabus => firstByType('syllabus');

  factory ChatSessionDetails.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';

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

    return ChatSessionDetails(id: id, resources: resources);
  }
}
