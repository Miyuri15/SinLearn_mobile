import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinlearn_mobile/core/utils/app_toast.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.responseLevel,
    required this.onResponseLevelChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final String responseLevel;
  final ValueChanged<String> onResponseLevelChanged;
  final void Function(String text, List<PlatformFile> attachments) onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final List<PlatformFile> _attachedFiles = [];

  String get responseLevel => widget.responseLevel;
  TextEditingController get controller => widget.controller;

  // Recording state + animation
  bool _isRecording = false;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Format file size for display (B, KB, MB)
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Open file picker and attach the selected file
  Future<void> _pickAndAttachFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );

    if (result == null) return; // Silent return on cancel

    final file = result.files.first;
    // Note: In a real app, you might want to save async to not block UI
    _savePickedFile(context, file);

    if (!mounted) return;
    setState(() => _attachedFiles.add(file));
  }

  /// Start audio recording
  void _startRecording() {
    setState(() => _isRecording = true);
    _animController.repeat();
  }

  /// Stop audio recording
  void _stopRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
    // TODO: Implement actual audio attachment logic here
  }

  /// Cancel audio recording
  void _cancelRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
  }

  /// Send the message with attached files
  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty && _attachedFiles.isEmpty) return;

    widget.onSend(
      text,
      List<PlatformFile>.from(_attachedFiles),
    );

    setState(() {
      controller.clear();
      _attachedFiles.clear();
    });
  }

  /// Animated waveform widget for recording visualization
  Widget _buildWaveform(BuildContext context) {
    const barCount = 15; // Increased slightly for fuller look
    const maxBarHeight = 32.0;
    const minBarHeight = 4.0;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (i) {
            final phase = (i / barCount) * math.pi * 2;
            final t = (_animController.value * math.pi * 2) + phase;
            final v = (math.sin(t) + 1) / 2; // 0..1
            final h = minBarHeight + (v * (maxBarHeight - minBarHeight));

            // Middle bars are taller, edge bars smaller (Audio wave shape)
            final bellCurve = math.sin((i / (barCount - 1)) * math.pi);
            final adjustedHeight = h * (0.5 + (0.5 * bellCurve));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                width: 4,
                height: adjustedHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Modern Recording Panel
  Widget _buildRecordingPanel(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.red.shade800 : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          // Pulse Animation Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 0.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1 + (value * 0.2)),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.red, size: 20),
              );
            },
            onEnd: () {}, // Loop could be added here if needed
          ),

          const SizedBox(width: 16),
          Expanded(child: Center(child: _buildWaveform(context))),
          const SizedBox(width: 16),

          // Actions
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline, size: 22),
            color: theme.hintColor,
            tooltip: 'Cancel',
          ),
          IconButton(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop_circle_outlined, size: 26),
            color: Colors.red,
            tooltip: 'Finish',
          ),
        ],
      ),
    );
  }

  /// Display attached files as chips
  Widget _buildAttachedFilesView(ThemeData theme) {
    if (_attachedFiles.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: _attachedFiles.map((f) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description, size: 16, color: theme.primaryColor),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.name.length > 20
                          ? '${f.name.substring(0, 18)}...'
                          : f.name,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatSize(f.size),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _attachedFiles.remove(f)),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 14, color: theme.hintColor),
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Modern Grade Selector (Pill Shape)
  Widget _buildGradeLevelSelector(ThemeData theme) {
    final levels = {
      'grade_6_8': 'Grades 6–8',
      'grade_9_11': 'Grades 9–11',
      'grade_12_13': 'Grades 12–13',
    };

    return PopupMenuButton<String>(
      initialValue: responseLevel,
      onSelected: widget.onResponseLevelChanged,
      position: PopupMenuPosition.over,
      offset: const Offset(0, -120), // Pop upwards
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => levels.entries.map((entry) {
        return PopupMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Icon(
                entry.key == responseLevel
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                size: 18,
                color: entry.key == responseLevel
                    ? theme.primaryColor
                    : theme.disabledColor,
              ),
              const SizedBox(width: 12),
              Text(entry.value.tr()),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 16, color: theme.primaryColor),
            const SizedBox(width: 6),
            Text(
              levels[responseLevel]?.tr() ?? '',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }

  /// Input Field with integrated icons
  Widget _buildInputField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade300
              : Colors.grey.shade800,
          width: 1,
        ),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // File Attach Button
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: IconButton(
              onPressed: _pickAndAttachFile,
              icon: Icon(Icons.attach_file, color: theme.hintColor),
              tooltip: 'Attach file',
            ),
          ),

          // Text Input
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'ask_question_hint'.tr(),
                  hintStyle: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14, // Aligns text with buttons
                  ),
                ),
              ),
            ),
          ),

          // Mic Button
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 4),
            child: IconButton(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic_none_rounded),
              color: theme.hintColor,
              tooltip: 'Record voice',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // We use a Column to stack the Grade Selector, File Preview, and Input
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Grade Selector (Left Aligned for cleaner look)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGradeLevelSelector(theme),
                // You could add a 'Clear Chat' or 'History' button here if needed
              ],
            ),

            const SizedBox(height: 12),

            // File Attachments (Horizontal Scroll)
            _buildAttachedFilesView(theme),

            // Main Input Area
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isRecording
                  ? _buildRecordingPanel(context)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _buildInputField(theme)),
                        const SizedBox(width: 10),

                        // Send Button
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E63FF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E63FF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _send,
                              borderRadius: BorderRadius.circular(26),
                              child: const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper for local storage (Unchanged logic, kept for functionality)
Future<void> _savePickedFile(BuildContext context, PlatformFile file) async {
  try {
    final bytes = file.bytes;
    if (bytes == null) {
      AppToast.error(context, 'Unable to read file bytes');
      return;
    }

    final key =
        'uploaded_${file.name}_${DateTime.now().millisecondsSinceEpoch}';
    final base64Str = base64Encode(bytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, base64Str);

    const manifestKey = 'uploaded_files_manifest';
    final manifestJson = prefs.getString(manifestKey);
    List<Map<String, dynamic>> manifest = [];

    if (manifestJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(manifestJson);
        manifest = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        manifest = [];
      }
    }

    manifest.insert(0, {
      'key': key,
      'name': file.name,
      'size': file.size,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString(manifestKey, jsonEncode(manifest));
    // Toast removed to reduce noise, logic kept
  } catch (e) {
    AppToast.error(context, 'Error saving file: $e');
  }
}
