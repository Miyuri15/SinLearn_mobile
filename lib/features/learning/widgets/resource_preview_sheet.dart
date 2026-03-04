import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../services/resource_service.dart';

void showResourcePreviewSheet(BuildContext context, String resourceId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ResourcePreviewSheet(resourceId: resourceId),
    ),
  );
}

class ResourcePreviewSheet extends StatefulWidget {
  const ResourcePreviewSheet({super.key, required this.resourceId});

  final String resourceId;

  @override
  State<ResourcePreviewSheet> createState() => _ResourcePreviewSheetState();
}

class _ResourcePreviewSheetState extends State<ResourcePreviewSheet> {
  static final Map<String, String> _pdfPathCache = {};

  late final Future<Uint8List> _resourceFuture;
  Future<String?>? _pdfFilePathFuture;
  int? _pdfPageCount;
  String? _fileSizeLabel;
  String? _imageDimensionsLabel;
  bool _isPdfResource = false;
  bool _isImageResource = false;

  @override
  void initState() {
    super.initState();
    _resourceFuture = ResourceService.viewResourceCached(widget.resourceId)
        .then((bytes) async {
      await _prepareMetadata(bytes);
      return bytes;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _prepareMetadata(Uint8List bytes) async {
    final isPdf = _isPdf(bytes);
    final isImage = _isImage(bytes);
    final fileSize = _formatBytes(bytes.length);

    String? imageDimensions;
    if (isImage) {
      try {
        final image = await decodeImageFromList(bytes);
        imageDimensions = '${image.width} × ${image.height}px';
        image.dispose();
      } catch (_) {
        imageDimensions = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _isPdfResource = isPdf;
      _isImageResource = isImage;
      _fileSizeLabel = fileSize;
      _imageDimensionsLabel = imageDimensions;
    });
  }

  String _buildMetaLine() {
    if (_isPdfResource) {
      final pages = _pdfPageCount == null
          ? null
          : '${_pdfPageCount!} ${_pdfPageCount == 1 ? 'page' : 'pages'}';
      return ['PDF', _fileSizeLabel, pages]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' • ');
    }

    if (_isImageResource) {
      return ['Image', _imageDimensionsLabel, _fileSizeLabel]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' • ');
    }

    return _fileSizeLabel ?? '';
  }

  bool _isPdf(Uint8List bytes) {
    if (bytes.length < 5) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D;
  }

  bool _isImage(Uint8List bytes) {
    if (bytes.length < 12) return false;

    final isPng = bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    final isGif = bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46;
    final isWebp = bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;

    return isPng || isJpeg || isGif || isWebp;
  }

  Future<String?> _writePdfToTemp(Uint8List bytes) async {
    try {
      final cachedPath = _pdfPathCache[widget.resourceId];
      if (cachedPath != null && cachedPath.isNotEmpty) {
        final cachedFile = File(cachedPath);
        if (await cachedFile.exists()) {
          return cachedPath;
        }
      }

      final dir = await Directory.systemTemp.createTemp('sinlearn_preview_');
      final file = File('${dir.path}/resource_preview.pdf');
      await file.writeAsBytes(bytes, flush: true);
      _pdfPathCache[widget.resourceId] = file.path;
      return file.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.description, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resource Preview',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_fileSizeLabel != null)
                      Text(
                        _buildMetaLine(),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: FutureBuilder<Uint8List>(
            future: _resourceFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Unable to load resource preview.'),
                  ),
                );
              }

              final bytes = snapshot.data!;

              if (_isImage(bytes)) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                );
              }

              if (_isPdf(bytes)) {
                _pdfFilePathFuture ??= _writePdfToTemp(bytes);
                return FutureBuilder<String?>(
                  future: _pdfFilePathFuture,
                  builder: (context, pdfSnapshot) {
                    if (pdfSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final path = pdfSnapshot.data;
                    if (path == null || path.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Unable to open PDF preview.'),
                        ),
                      );
                    }

                    return PDFView(
                      filePath: path,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      onRender: (pages) {
                        if (!mounted) return;
                        setState(() {
                          _pdfPageCount = pages;
                        });
                      },
                    );
                  },
                );
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file,
                          size: 48, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      const Text(
                          'Preview is not available for this file type.'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
