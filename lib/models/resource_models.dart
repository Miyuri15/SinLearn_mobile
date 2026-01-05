class ResourceUploadResponse {
  final String resourceId;
  final String filename;
  final int sizeBytes;
  final String mimeType;

  ResourceUploadResponse({
    required this.resourceId,
    required this.filename,
    required this.sizeBytes,
    required this.mimeType,
  });

  factory ResourceUploadResponse.fromJson(Map<String, dynamic> json) {
    final dynamic idRaw = json['resource_id'] ??
        json['id'] ??
        json['resourceId'] ??
        json['resourceID'];
    final dynamic filenameRaw = json['filename'] ??
        json['file_name'] ??
        json['name'] ??
        json['original_filename'];
    final dynamic sizeRaw = json['size_bytes'] ??
        json['size'] ??
        json['bytes'] ??
        json['file_size'];
    final dynamic mimeRaw = json['mime_type'] ??
        json['content_type'] ??
        json['mimeType'] ??
        json['mimetype'];

    int parseSize(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ResourceUploadResponse(
      resourceId: idRaw?.toString() ?? '',
      filename: filenameRaw?.toString() ?? '',
      sizeBytes: parseSize(sizeRaw),
      mimeType: mimeRaw?.toString() ?? 'application/octet-stream',
    );
  }
}
