// lib/features/learning/widgets/chat_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/message.dart';
import '../../../models/xai_models.dart';
import 'message_bubble.dart';
import 'resource_preview_sheet.dart';

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.messages,
    this.isLoading = false,
    this.sendProgressText,
    this.onExplainMessage,
  });

  final List<Message> messages;
  final bool isLoading;
  final String? sendProgressText;
  final Future<XaiResponse> Function(String messageId)? onExplainMessage;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty && !widget.isLoading) {
      return const _EmptyStateView();
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            final isFirst = index == 0;
            final prevMessage = isFirst ? null : widget.messages[index - 1];
            final currentMessage = widget.messages[index];

            bool showDateSeparator = false;
            if (prevMessage != null) {
              final prevDate = DateTime(
                prevMessage.time.year,
                prevMessage.time.month,
                prevMessage.time.day,
              );
              final currDate = DateTime(
                currentMessage.time.year,
                currentMessage.time.month,
                currentMessage.time.day,
              );
              if (currDate.difference(prevDate).inDays > 0) {
                showDateSeparator = true;
              }
            } else {
              showDateSeparator = true;
            }

            return Column(
              children: [
                if (showDateSeparator)
                  _DateSeparator(date: currentMessage.time),
                MessageBubble(
                  message: currentMessage,
                  onViewResource: (id) => showResourcePreviewSheet(context, id),
                  onExplainMessage: widget.onExplainMessage,
                ),
              ],
            );
          },
        ),

        // Loading Indicators
        if (widget.isLoading)
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _LoadingIndicator(),
          ),

        if (widget.sendProgressText != null)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _ProgressIndicator(text: widget.sendProgressText!),
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
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            DateFormat.yMMMd().format(date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('SinLearn is thinking...'),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final String text;
  const _ProgressIndicator({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start a conversation',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type a question to begin learning',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: const [
                  _SuggestionChip(label: "Translate Sinhala text"),
                  _SuggestionChip(label: "Explain a math problem"),
                  _SuggestionChip(label: "Summarize a document"),
                ],
              ),
            ],
          ),
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
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
