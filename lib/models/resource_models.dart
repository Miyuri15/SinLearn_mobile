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
    return ResourceUploadResponse(
      resourceId: json['resource_id'],
      filename: json['filename'],
      sizeBytes: json['size_bytes'],
      mimeType: json['mime_type'],
    );
  }
}
