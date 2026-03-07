// lib/features/learning/widgets/chat_input_bar.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinlearn_mobile/core/utils/app_toast.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.canSendTextWithoutAttachment,
    required this.responseLevel,
    required this.onResponseLevelChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool canSendTextWithoutAttachment;
  final String responseLevel;
  final ValueChanged<String> onResponseLevelChanged;

  /// Supports voice
  final Future<void> Function(
    String text,
    List<PlatformFile> attachments,
    Uint8List? voiceBytes,
  ) onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final List<PlatformFile> _attachedFiles = [];
  Uint8List? _pendingVoice;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  late final AnimationController _animController;

  // Grade selector state
  bool _showGradeSelector = false;

  final List<Map<String, dynamic>> _gradeLevels = const [
    {'value': 'grade_6_8', 'label': 'Grades 6-8', 'color': Colors.green},
    {'value': 'grade_9_11', 'label': 'Grades 9-11', 'color': Colors.blue},
    {'value': 'grade_12_13', 'label': 'Grades 12-13', 'color': Colors.purple},
    {
      'value': 'grade_12_plus',
      'label': 'Grades 12+',
      'color': Colors.deepPurple
    },
  ];

  String get responseLevel => widget.responseLevel;
  TextEditingController get controller => widget.controller;
  String? _pendingVoicePath;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _totalDuration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _currentPosition = p);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ================= GRADE SELECTOR HELPERS =================

  String _getGradeLabel(String value) {
    final grade = _gradeLevels.firstWhere(
      (g) => g['value'] == value,
      orElse: () => _gradeLevels[1],
    );
    return grade['label'];
  }

  Color _getGradeColor(String value) {
    final grade = _gradeLevels.firstWhere(
      (g) => g['value'] == value,
      orElse: () => _gradeLevels[1],
    );
    return grade['color'];
  }

  // ================= FILE HANDLING =================

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndAttachFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );

    if (result == null) return;

    final file = result.files.first;

    await _savePickedFile(context, file);

    if (!mounted) return;
    setState(() => _attachedFiles.add(file));
  }

  Widget _buildAttachmentsPreview() {
    if (_attachedFiles.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: _attachedFiles.map((file) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(file.extension ?? ''),
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatSize(file.size),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _attachedFiles.remove(file);
                    });
                  },
                  splashRadius: 24,
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // ================= VOICE RECORDING =================

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      AppToast.error(context, "Microphone permission denied");
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
      ),
      path: path,
    );

    if (!mounted) return;

    setState(() => _isRecording = true);
    _animController.repeat();
  }

  Future<void> _stopRecording() async {
    _animController.stop();

    final path = await _recorder.stop();
    if (path == null) return;

    final file = File(path);
    final bytes = await file.readAsBytes();

    debugPrint("Voice saved at: $path");
    debugPrint("Voice size: ${bytes.length}");

    if (!mounted) return;

    setState(() {
      _pendingVoicePath = path;
      _pendingVoice = bytes;
      _isRecording = false;
    });
  }

  void _cancelRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
  }

  // ================= PLAYBACK =================

  Future<void> _togglePlayback() async {
    if (_pendingVoicePath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioPlayer.play(DeviceFileSource(_pendingVoicePath!));

      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  bool get _canSend {
    if (widget.isSending) return false;
    if (_pendingVoice != null || _attachedFiles.isNotEmpty) return true;

    final hasText = controller.text.trim().isNotEmpty;
    return widget.canSendTextWithoutAttachment && hasText;
  }

  // ================= SEND =================

  Future<void> _send() async {
    final text = controller.text.trim();

    if (text.isEmpty && _attachedFiles.isEmpty && _pendingVoice == null) return;

    await widget.onSend(
      text,
      List<PlatformFile>.from(_attachedFiles),
      _pendingVoice,
    );

    if (!mounted) return;
    setState(() {
      controller.clear();
      _attachedFiles.clear();

      _pendingVoice = null;
      _pendingVoicePath = null;

      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _isPlaying = false;
    });
  }

  // ================= UI COMPONENTS =================

  Widget _buildWaveform() {
    const barCount = 15;
    const maxBarHeight = 32.0;
    const minBarHeight = 4.0;

    return AnimatedBuilder(
      animation: _animController,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(barCount, (i) {
            final phase = (i / barCount) * math.pi * 2;
            final t = (_animController.value * math.pi * 2) + phase;
            final v = (math.sin(t) + 1) / 2;
            final h = minBarHeight + (v * (maxBarHeight - minBarHeight));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildRecordingPanel() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Center(child: _buildWaveform())),
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline),
            splashRadius: 24,
          ),
          IconButton(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _togglePlayback,
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            splashRadius: 24,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            padding: EdgeInsets.zero,
          ),
          Text(
            _formatDuration(_currentPosition),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: _currentPosition.inMilliseconds.toDouble(),
                max: _totalDuration.inMilliseconds
                    .toDouble()
                    .clamp(1, double.infinity),
                onChanged: (v) async {
                  await _audioPlayer.seek(
                    Duration(milliseconds: v.toInt()),
                  );
                },
              ),
            ),
          ),
          Text(
            _formatDuration(_totalDuration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _pendingVoice = null;
                _pendingVoicePath = null;
                _currentPosition = Duration.zero;
                _totalDuration = Duration.zero;
                _isPlaying = false;
              });
            },
            icon: const Icon(Icons.close, color: Colors.white),
            splashRadius: 24,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            padding: EdgeInsets.zero,
          )
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: _canSend ? const Color(0xFF1E63FF) : Colors.grey.shade300,
        shape: BoxShape.circle,
        boxShadow: _canSend
            ? [
                BoxShadow(
                  color: const Color(0xFF1E63FF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: _canSend ? _send : null,
          child: Center(
            child: widget.isSending
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
  // ================= COMPACT GRADE SELECTOR UI =================

  Widget _buildGradeSelector() {
    final color = _getGradeColor(widget.responseLevel);

    return Container(
      height: 40, // Fixed height - shorter than input bar
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Level:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.responseLevel,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: color,
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                isDense: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    widget.onResponseLevelChanged(newValue);
                  }
                },
                items: _gradeLevels.map<DropdownMenuItem<String>>((grade) {
                  return DropdownMenuItem<String>(
                    value: grade['value'],
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: grade['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          grade['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasVoice = _pendingVoicePath != null || _isRecording;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasVoice) _buildGradeSelector(),

            // Attachments Preview
            if (_attachedFiles.isNotEmpty) _buildAttachmentsPreview(),

            // Recording/Playback UI
            if (_isRecording)
              _buildRecordingPanel()
            else if (_pendingVoicePath != null)
              Row(
                children: [
                  // Playback bar (expanded)
                  Expanded(
                    child: _buildPlaybackBar(),
                  ),
                  const SizedBox(width: 8),
                  // Send button for voice
                  _buildSendButton(),
                ],
              )
            else
              // Main Input Row (full height)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text Input Container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed:
                                widget.isSending ? null : _pickAndAttachFile,
                            icon: const Icon(Icons.attach_file),
                            splashRadius: 24,
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              onChanged: (_) => setState(() {}),
                              enabled: !widget.isSending,
                              maxLines: null,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'Ask a question...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                widget.isSending ? null : _startRecording,
                            icon: const Icon(Icons.mic_none_rounded),
                            splashRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSendButton(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Add this at bottom of the same file
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
  } catch (e) {
    AppToast.error(context, 'Error saving file: $e');
  }
}
