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

    if (result == null) {
      if (mounted) {
        AppToast.warning(context, 'File selection cancelled');
      }
      return;
    }

    final file = result.files.first;
    await _savePickedFile(context, file);
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
    // TODO: Implement audio attachment logic here
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
    const barCount = 12;
    const maxBarHeight = 28.0;
    const minBarHeight = 6.0;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(barCount, (i) {
            final phase = (i / barCount) * math.pi * 2;
            final t = (_animController.value * math.pi * 2) + phase;
            final v = (math.sin(t) + 1) / 2; // 0..1
            final h = minBarHeight + (v * (maxBarHeight - minBarHeight));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                width: 6,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Recording panel UI with waveform and controls
  Widget _buildRecordingPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.red.shade50
            : Colors.red.shade900.withOpacity(0.16),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Recording indicator
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Waveform visualization
          Expanded(
            child: Center(child: _buildWaveform(context)),
          ),

          // Control buttons
          Row(
            children: [
              TextButton.icon(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                label: Text(
                  'Cancel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.mic_off, color: Colors.red),
                label: Text(
                  'Stop',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Display attached files as chips
  Widget _buildAttachedFilesView(ThemeData theme) {
    if (_attachedFiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: _attachedFiles.map((f) {
          return Chip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file, size: 16),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    '${f.name} • ${_formatSize(f.size)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() => _attachedFiles.remove(f));
            },
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Grade level selector widget
  Widget _buildGradeLevelSelector(ThemeData theme, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 4 : 6,
      ),
      constraints: BoxConstraints(
        minWidth: compact ? 110 : 120,
        maxWidth: compact ? 160 : 180,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'response_level'.tr(),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: compact ? 32 : 36,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: responseLevel,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'grade_6_8',
                    child: Text('Grades 6–8'),
                  ),
                  DropdownMenuItem(
                    value: 'grade_9_11',
                    child: Text('Grades 9–11'),
                  ),
                  DropdownMenuItem(
                    value: 'grade_12_13',
                    child: Text('Grades 12–13'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) widget.onResponseLevelChanged(v);
                },
                selectedItemBuilder: (context) => [
                  Center(child: Text('grade_6_8'.tr())),
                  Center(child: Text('grade_9_11'.tr())),
                  Center(child: Text('grade_12_13'.tr())),
                ],
                dropdownColor: theme.colorScheme.surface,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the text input field with attachment and mic buttons
  Widget _buildInputField(ThemeData theme, bool isSmallPhone) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.12),
        ),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 6,
            ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'ask_question_hint'.tr(),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            width: isSmallPhone ? 88 : 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _pickAndAttachFile,
                  icon: const Icon(Icons.attach_file),
                ),
                IconButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.mic : Icons.mic_none),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the send button
  Widget _buildSendButton() {
    return SizedBox(
      height: 52,
      width: 52,
      child: ElevatedButton(
        onPressed: _send,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E63FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 520;

            // Narrow layout (mobile)
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grade level selector (compact)
                  Row(
                    children: [
                      Text(
                        'response_level'.tr(),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGradeLevelSelector(theme, compact: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Attached files
                  _buildAttachedFilesView(theme),

                  // Recording panel
                  if (_isRecording) _buildRecordingPanel(context),

                  // Input row
                  Row(
                    children: [
                      Expanded(child: _buildInputField(theme, isSmallPhone)),
                      const SizedBox(width: 12),
                      _buildSendButton(),
                    ],
                  ),
                ],
              );
            }

            // Wide layout (desktop)
            return Column(
              children: [
                Row(
                  children: [
                    _buildGradeLevelSelector(theme),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 8),

                // Attached files
                _buildAttachedFilesView(theme),

                // Recording panel
                if (_isRecording) _buildRecordingPanel(context),

                // Input row
                Row(
                  children: [
                    Expanded(child: _buildInputField(theme, isSmallPhone)),
                    const SizedBox(width: 12),
                    _buildSendButton(),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Save picked file to local storage using SharedPreferences
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

    // Maintain a manifest of uploaded files
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
    AppToast.success(context, 'Saved ${file.name} locally');
  } catch (e) {
    AppToast.error(context, 'Error saving file: $e');
  }
}
