// lib/features/learning/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/message.dart';
import '../../../models/xai_models.dart';
import '../../../services/message_service.dart';
import '../../../core/utils/app_toast.dart';
import 'grade_label.dart';
import 'safety_summary.dart';
import 'xai_panel.dart';
// Add this import at the top of message_bubble.dart
import 'package:flutter/services.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Function(String) onViewResource;
  final Future<XaiResponse> Function(String messageId)? onExplainMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onViewResource,
    this.onExplainMessage,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _copied = false;
  bool _showXAI = false;
  bool _isFetchingXAI = false;
  XaiExplanation? _localXAI;
  String? _xaiUnavailableMessage;

  @override
  void initState() {
    super.initState();
    _localXAI = widget.message.xaiExplanation != null
        ? XaiExplanation.fromJson(widget.message.xaiExplanation!)
        : null;
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.message.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  Future<void> _handleToggleXAI() async {
    final next = !_showXAI;
    setState(() => _showXAI = next);

    if (next && _localXAI == null && !_isFetchingXAI) {
      setState(() {
        _isFetchingXAI = true;
        _xaiUnavailableMessage = null;
      });

      try {
        if (widget.message.messageId == null) {
          throw Exception('Missing message ID');
        }

        final response =
            await widget.onExplainMessage!(widget.message.messageId!);
        final explanation = response.xaiExplanation;
        final hasSummary =
            (explanation?.explanationSummary?.trim().isNotEmpty ?? false);

        if (mounted) {
          setState(() {
            _localXAI = hasSummary ? explanation : null;
            _xaiUnavailableMessage = hasSummary
                ? null
                : 'XAI explanation is not available for this message.';
            _isFetchingXAI = false;
          });
        }
      } catch (e) {
        final rawMessage = e.toString().toLowerCase();
        final isNotAvailableError = rawMessage.contains('not available') ||
            rawMessage.contains('xai explanation');

        if (mounted) {
          setState(() {
            _localXAI = null;
            _xaiUnavailableMessage = isNotAvailableError
                ? 'XAI explanation is not available for this message.'
                : 'Unable to load explanation right now. Please try again.';
            _isFetchingXAI = false;
          });

          if (!isNotAvailableError) {
            AppToast.error(context, 'Failed to load explanation');
          }
        }
      }
    }
  }

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
    final isUser = widget.message.fromUser;
    final hasGradeLevel =
        (widget.message.gradeLevel?.trim().isNotEmpty ?? false);
    final hasSafetySummary = !isUser &&
        widget.message.safetySummary != null &&
        widget.message.safetySummary!.isNotEmpty;
    final canShowExplain =
        !isUser && hasSafetySummary && widget.onExplainMessage != null;
    final hasInfoBarContent =
        hasGradeLevel || hasSafetySummary || canShowExplain;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message Container
            Container(
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1E63FF) : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border:
                    !isUser ? Border.all(color: Colors.grey.shade200) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (only for AI messages)
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Assistant',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Copy Button
                          Tooltip(
                            message: _copied ? 'Copied!' : 'Copy',
                            child: InkWell(
                              onTap: _handleCopy,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _copied
                                      ? Colors.green.withOpacity(0.1)
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _copied ? Icons.check : Icons.copy,
                                  size: 14,
                                  color: _copied
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Message Content
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      isUser ? 12 : 8,
                      16,
                      isUser ? 12 : 8,
                    ),
                    child: SelectableText(
                      widget.message.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser ? Colors.white : null,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // Attachments and Resources (same as before)
                  if (widget.message.attachments != null &&
                      widget.message.attachments!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: widget.message.attachments!
                            .map((file) => _AttachmentTile(
                                  name: file.name,
                                  isUser: isUser,
                                  icon: Icons.upload_file,
                                  subtitle: 'Uploaded file',
                                ))
                            .toList(),
                      ),
                    ),

                  if (widget.message.resourceIds != null &&
                      widget.message.resourceIds!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: widget.message.resourceIds!
                            .map((id) => GestureDetector(
                                  onTap: () => widget.onViewResource(id),
                                  child: _AttachmentTile(
                                    name: 'Learning Resource',
                                    isUser: isUser,
                                    icon: Icons.menu_book,
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

            // Info Bar for AI Messages
            if (!isUser && hasInfoBarContent)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // First row: Grade and Safety
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (hasGradeLevel)
                                GradeLabel(
                                    gradeLevel: widget.message.gradeLevel!),
                              if (hasSafetySummary)
                                SafetySummary(
                                    summary: widget.message.safetySummary!),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (canShowExplain) ...[
                      // Explain button row
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: _handleToggleXAI,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _showXAI
                                    ? Colors.indigo.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _showXAI
                                      ? Colors.indigo.withOpacity(0.3)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.psychology,
                                    size: 14,
                                    color: _showXAI
                                        ? Colors.indigo
                                        : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isFetchingXAI
                                        ? 'Loading...'
                                        : _showXAI
                                            ? 'Hide Details'
                                            : 'Explain This',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _showXAI
                                          ? Colors.indigo
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // XAI Panel
            if (_showXAI && canShowExplain)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: XAIPanel(
                  explanation: _localXAI,
                  isLoading: _isFetchingXAI,
                  unavailableMessage: _xaiUnavailableMessage,
                ),
              ),

            // Hint for first-time users
            if (!_showXAI && canShowExplain)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Text(
                  'Click "Explain This" to see how I got this answer',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                DateFormat('h:mm a').format(widget.message.time),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
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
        color: isUser ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isUser ? Colors.white.withOpacity(0.3) : Colors.white,
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
                    color: isUser
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: isUser ? Colors.white70 : Colors.grey.shade400,
            ),
        ],
      ),
    );
  }
}
