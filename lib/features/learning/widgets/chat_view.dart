import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/message.dart';

/// Displays the chat message list with support for text, attachments, and resources.
///
/// Features:
/// - User vs AI message styling
/// - Grade level badges
/// - Local file attachments display
/// - Resource attachments from API (clickable)
/// - Timestamps
/// - Empty state with helpful prompts
class ChatView extends StatelessWidget {
  const ChatView({
    super.key,
    required this.messages,
    this.isLoading = false,
  });

  final List<Message> messages;
  final bool isLoading;

  /// Format grade level string for display
  String _formatGradeLevel(String gradeLevel) {
    switch (gradeLevel) {
      case 'grade_6_8':
      case 'grades_6_8':
        return 'Grades 6-8';
      case 'grade_9_11':
      case 'grades_9_11':
        return 'Grades 9-11';
      case 'grade_12_13':
      case 'grades_12_13':
        return 'Grades 12-13';
      case 'grade_12_plus':
      case 'grades_12_plus':
        return 'Grades 12+';
      default:
        return gradeLevel;
    }
  }

  /// Show resource viewer dialog
  void _viewResource(BuildContext context, String resourceId) async {
    final resourceUrl =
        'http://127.0.0.1:8000/api/v1/resources/$resourceId/view';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.attach_file),
            const SizedBox(width: 8),
            const Expanded(child: Text('Resource')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Resource URL display
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        resourceUrl,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        // TODO: Implement clipboard copy
                        debugPrint('Copy URL: $resourceUrl');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Resource preview (could be enhanced with WebView)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description, size: 64),
                      const SizedBox(height: 16),
                      Text('Resource ID: $resourceId'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement url_launcher integration
                          debugPrint('Opening: $resourceUrl');
                        },
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Open in Browser'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a single message bubble
  Widget _buildMessageBubble(BuildContext context, Message message) {
    final theme = Theme.of(context);
    final align =
        message.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor =
        message.fromUser ? const Color(0xFF1E63FF) : theme.colorScheme.surface;
    final textColor =
        message.fromUser ? Colors.white : theme.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: align,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grade level badge
                if (message.gradeLevel != null)
                  _buildGradeLevelBadge(theme, message, textColor),

                // Message text
                if (message.text.isNotEmpty)
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),

                // Local file attachments
                if (message.attachments != null &&
                    message.attachments!.isNotEmpty)
                  _buildLocalAttachments(theme, message, textColor),

                // Resource attachments from API
                if (message.resourceIds != null &&
                    message.resourceIds!.isNotEmpty)
                  _buildResourceAttachments(context, theme, message, textColor),

                // Timestamp
                const SizedBox(height: 6),
                Text(
                  '${MaterialLocalizations.of(context).formatShortDate(message.time)} '
                  '${TimeOfDay.fromDateTime(message.time).format(context)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor?.withOpacity(0.7) ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build grade level badge
  Widget _buildGradeLevelBadge(
    ThemeData theme,
    Message message,
    Color? textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: message.fromUser
            ? Colors.white.withOpacity(0.15)
            : theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatGradeLevel(message.gradeLevel!),
        style: theme.textTheme.bodySmall?.copyWith(
          color: message.fromUser
              ? Colors.white.withOpacity(0.9)
              : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build local file attachments
  Widget _buildLocalAttachments(
    ThemeData theme,
    Message message,
    Color? textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: message.attachments!.map((file) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: message.fromUser
                    ? Colors.white.withOpacity(0.06)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file, size: 16),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build resource attachments from API
  Widget _buildResourceAttachments(
    BuildContext context,
    ThemeData theme,
    Message message,
    Color? textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: message.resourceIds!.map((resourceId) {
            return InkWell(
              onTap: () => _viewResource(context, resourceId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: message.fromUser
                      ? Colors.white.withOpacity(0.12)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: message.fromUser
                        ? Colors.white.withOpacity(0.3)
                        : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 18,
                      color: textColor?.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        'Resource',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor?.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: textColor?.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'start_conversation'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'type_question'.tr(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[450],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (messages.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(context, messages[index]);
      },
    );
  }
}
