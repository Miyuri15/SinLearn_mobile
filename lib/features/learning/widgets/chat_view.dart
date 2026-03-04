import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/message.dart';
import 'resource_preview_sheet.dart';

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
                  onViewResource: (id) => showResourcePreviewSheet(context, id),
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
