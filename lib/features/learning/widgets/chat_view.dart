import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../services/resource_service.dart';
import '../../../models/message.dart';

/// Displays the chat message list with modern bubble styling and attachment previews.
class ChatView extends StatelessWidget {
  const ChatView({
    super.key,
    required this.messages,
    this.isLoading = false,
    this.sendProgressText,
  });

  final List<Message> messages;
  final bool isLoading;
  final String? sendProgressText;

  /// Show resource viewer in-app (no external URL)
  void _viewResource(BuildContext context, String resourceId) {
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
        child: _ResourcePreviewSheet(resourceId: resourceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !isLoading) {
      return const _EmptyStateView();
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              16, 20, 16, 100), // Extra bottom padding for input
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final isFirst = index == 0;
            final prevMessage = isFirst ? null : messages[index - 1];
            final currentMessage = messages[index];

            // Check if we should show date separator (e.g., if day changed)
            bool showDateSeparator = false;
            if (prevMessage != null) {
              final prevDate = DateTime(prevMessage.time.year,
                  prevMessage.time.month, prevMessage.time.day);
              final currDate = DateTime(currentMessage.time.year,
                  currentMessage.time.month, currentMessage.time.day);
              if (currDate.difference(prevDate).inDays > 0) {
                showDateSeparator = true;
              }
            } else {
              showDateSeparator = true; // Show for first message
            }

            return Column(
              children: [
                if (showDateSeparator)
                  _DateSeparator(date: currentMessage.time),
                _MessageBubble(
                  message: currentMessage,
                  onViewResource: (id) => _viewResource(context, id),
                ),
              ],
            );
          },
        ),
        if (isLoading)
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                elevation: 4,
                shape: StadiumBorder(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text("SinLearn is thinking..."),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (sendProgressText != null)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                elevation: 4,
                shape: const StadiumBorder(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(sendProgressText!),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              DateFormat.yMMMd().format(date),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcePreviewSheet extends StatefulWidget {
  const _ResourcePreviewSheet({required this.resourceId});

  final String resourceId;

  @override
  State<_ResourcePreviewSheet> createState() => _ResourcePreviewSheetState();
}

class _ResourcePreviewSheetState extends State<_ResourcePreviewSheet> {
  late final Future<Uint8List> _resourceFuture;
  Future<String?>? _pdfFilePathFuture;

  @override
  void initState() {
    super.initState();
    _resourceFuture = ResourceService.viewResource(widget.resourceId);
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
      final dir = await Directory.systemTemp.createTemp('sinlearn_preview_');
      final file = File('${dir.path}/resource_preview.pdf');
      await file.writeAsBytes(bytes, flush: true);
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

class _MessageBubble extends StatelessWidget {
  final Message message;
  final Function(String) onViewResource;

  const _MessageBubble({
    required this.message,
    required this.onViewResource,
  });

  String _formatGradeLevel(String gradeLevel) {
    switch (gradeLevel) {
      case 'grade_6_8':
        return 'Grades 6-8';
      case 'grade_9_11':
        return 'Grades 9-11';
      case 'grade_12_13':
        return 'Grades 12-13';
      case 'grade_12_plus':
        return 'Grades 12+';
      default:
        return gradeLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.fromUser;

    // Design variables
    final bubbleColor = isUser
        ? const Color(0xFF1E63FF)
        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4);

    final textColor = isUser ? Colors.white : theme.textTheme.bodyLarge?.color;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isUser ? 20 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 20),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Grade Badge (Only for AI)
            if (!isUser && message.gradeLevel != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4, left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Text(
                  _formatGradeLevel(message.gradeLevel!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),

            // Main Bubble
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Content
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        height: 1.4,
                      ),
                    ),

                  // Attachments (Local)
                  if (message.attachments != null &&
                      message.attachments!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: message.attachments!
                            .map((file) => _AttachmentTile(
                                  name: file.name,
                                  isUser: isUser,
                                  icon: Icons.upload_file,
                                  subtitle: 'Uploaded file',
                                ))
                            .toList(),
                      ),
                    ),

                  // Resources (API)
                  if (message.resourceIds != null &&
                      message.resourceIds!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: message.resourceIds!
                            .map((id) => GestureDetector(
                                  onTap: () => onViewResource(id),
                                  child: _AttachmentTile(
                                    name: 'Learning Resource',
                                    isUser: isUser,
                                    icon: Icons.menu_book_rounded,
                                    subtitle: 'Tap to view content',
                                    showArrow: true,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                DateFormat('h:mm a').format(message.time),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.disabledColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isUser;
  final IconData icon;
  final bool showArrow;

  const _AttachmentTile({
    required this.name,
    required this.subtitle,
    required this.isUser,
    required this.icon,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isUser ? Colors.white : const Color(0xFF1E63FF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        isUser ? Colors.white.withOpacity(0.8) : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            Icon(Icons.arrow_forward_ios,
                size: 10, color: isUser ? Colors.white70 : Colors.grey),
        ],
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.auto_awesome, size: 48, color: theme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'start_conversation'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'type_question'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 40),

            // Suggestion Chips (Optional visual flair)
            const Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(label: "Translate Sinhala text"),
                _SuggestionChip(label: "Explain a math problem"),
                _SuggestionChip(label: "Summarize a document"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
