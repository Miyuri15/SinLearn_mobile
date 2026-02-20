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
    required this.responseLevel,
    required this.onResponseLevelChanged,
    required this.onSend,
  });

  final TextEditingController controller;
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

  String get responseLevel => widget.responseLevel;
  TextEditingController get controller => widget.controller;

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

    // ✅ this exists now (added at bottom)
    await _savePickedFile(context, file);

    if (!mounted) return;
    setState(() => _attachedFiles.add(file));
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
      const RecordConfig(encoder: AudioEncoder.wav),
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

    if (!mounted) return;
    setState(() {
      _pendingVoice = bytes;
      _isRecording = false;
    });

    AppToast.success(context, "Recording ready to send");
  }

  void _cancelRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
  }

  // ================= PLAYBACK =================

  Future<void> _togglePlayback() async {
    if (_pendingVoice == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() => _isPlaying = false);
    } else {
      if (_currentPosition == Duration.zero) {
        await _audioPlayer.play(BytesSource(_pendingVoice!));
      } else {
        await _audioPlayer.resume();
      }
      if (!mounted) return;
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
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
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(child: Center(child: _buildWaveform())),
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(color: Colors.white),
                ),
                Expanded(
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
                Text(
                  _formatDuration(_totalDuration),
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _pendingVoice = null;
                      _currentPosition = Duration.zero;
                      _totalDuration = Duration.zero;
                      _isPlaying = false;
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildSendButton(),
      ],
    );
  }

  Widget _buildSendButton() {
    return Container(
      height: 52,
      width: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF1E63FF),
        shape: BoxShape.circle,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: _send,
        child: const Icon(Icons.send_rounded, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording)
              _buildRecordingPanel()
            else if (_pendingVoice != null)
              _buildPlaybackBar()
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _pickAndAttachFile,
                            icon: const Icon(Icons.attach_file),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'ask_question_hint'.tr(),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _startRecording,
                            icon: const Icon(Icons.mic_none_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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

    final key = 'uploaded_${file.name}_${DateTime.now().millisecondsSinceEpoch}';
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
