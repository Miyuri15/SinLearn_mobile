import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/resource_service.dart';
import '../../services/chat_service.dart';
import '../../core/utils/blocking_progress_dialog.dart';

class QuestionPaperPage extends StatefulWidget {
  final String? chatSessionId;
  const QuestionPaperPage({super.key, this.chatSessionId});

  @override
  State<QuestionPaperPage> createState() => _QuestionPaperPageState();
}

class _QuestionPaperPageState extends State<QuestionPaperPage> {
  PlatformFile? _file;
  String? _resourceId;
  String? _mimeType;
  static const Set<String> _allowed = {'pdf', 'doc', 'docx'};
  static const _prefsKeyPrefix = 'question_paper_file:';

  String get _prefsKey =>
      '$_prefsKeyPrefix${widget.chatSessionId ?? 'no-session'}';

  @override
  void initState() {
    super.initState();
    print(
        'QuestionPaperPage initialized with chatSessionId: ${widget.chatSessionId}');
    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    final sessionId = widget.chatSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      await _loadSavedFile();
      return;
    }

    try {
      final details = await ChatService.getChatSessionDetails(sessionId);
      final qp = details.questionPaper;
      if (qp != null) {
        final displayName = qp.filename.isNotEmpty
            ? qp.filename
            : (qp.resourceId.isNotEmpty ? 'Resource ${qp.resourceId}' : '');
        if (displayName.isEmpty) {
          await _loadSavedFile();
          return;
        }
        setState(() {
          _resourceId = qp.resourceId.isNotEmpty ? qp.resourceId : null;
          _mimeType = qp.mimeType;
          _file = PlatformFile(
            name: displayName,
            size: qp.sizeBytes,
          );
        });
        return;
      }
    } catch (e) {
      // ignore and fall back to local cache
      print('Failed to load question paper from backend: $e');
    }

    await _loadSavedFile();
  }

  Future<void> _loadSavedFile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(raw);
      final name = (data['name'] as String?) ?? '';
      if (name.isEmpty) return;
      // Hydrate minimal PlatformFile for UI display (no 'extension' named arg)
      setState(() {
        _resourceId = data['resourceId']?.toString();
        _mimeType = (data['mimeType'] as String?) ??
            _mimeTypeFromExtension(data['ext']?.toString());
        _file = PlatformFile(
          name: name,
          size: (data['size'] as int?) ?? 0,
          // bytes/path can be omitted; we only need name for display
        );
      });
    } catch (_) {
      // ignore malformed storage
    }
  }

  Future<void> _saveFile(PlatformFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'name': file.name,
      'ext': file.extension,
      'size': file.size,
      'resourceId': _resourceId,
      'mimeType': _mimeType,
      // 'path': file.path, // optional: uncomment if you need to persist path
      'savedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_prefsKey, payload);
  }

  Future<void> _clearSavedFile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _pickFile() async {
    try {
      // Using FileType.any to avoid issues where some Android devices show "No items"
      // when filtering by custom extensions. We validate the extension manually below.
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('question_paper.select_file_cancelled'))),
        );
        return;
      }
      final picked = result.files.first;
      final ext = picked.extension?.toLowerCase();
      if (ext == null || !_allowed.contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('question_paper.upload_error'))),
        );
        return;
      }

      if (widget.chatSessionId != null) {
        MultipartFile? multipartFile;

        if (kIsWeb) {
          if (picked.bytes != null) {
            multipartFile =
                MultipartFile.fromBytes(picked.bytes!, filename: picked.name);
          }
        } else {
          if (picked.path != null) {
            multipartFile = await MultipartFile.fromFile(picked.path!,
                filename: picked.name);
          }
        }

        if (multipartFile != null) {
          unawaited(
            showBlockingProgressDialog(
              context,
              message: 'Uploading ${picked.name}...',
            ),
          );
          print('Uploading file with chatSessionId: ${widget.chatSessionId}');
          try {
            final res = await ResourceService.uploadQuestionPaper(
              file: multipartFile,
              chatSessionId: widget.chatSessionId!,
            );
            _resourceId = res.resourceId;
            _mimeType = _mimeTypeFromExtension(picked.extension);
          } finally {
            if (mounted &&
                Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          }
        } else {
          print('Skipping upload: File bytes/path missing. Web: $kIsWeb');
        }
      } else {
        print('Skipping upload: chatSessionId is null');
      }

      setState(() => _file = picked);
      await _saveFile(picked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(tr('question_paper.upload_success', args: [picked.name]))),
      );
    } catch (e, stack) {
      print('Error picking/uploading file: $e');
      if (e is DioException) {
        print('DioError response data: ${e.response?.data}');
      }
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')), // Show actual error for debugging
      );
    }
  }

  Future<bool> _confirmDelete(String name) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(tr('question_paper.delete_title',
              args: [])), // optional title key if present
          content: Text(
              tr('question_paper.delete_confirm', namedArgs: {'name': name})),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(tr('question_paper.cancel'))),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(tr('question_paper.delete'))),
          ],
        );
      },
    );
    return res == true;
  }

  void _deleteFile() async {
    final name = _file?.name ?? '';
    if (name.isEmpty) return;
    final ok = await _confirmDelete(name);
    if (!ok) return;
    setState(() => _file = null);
    _mimeType = null;
    await _clearSavedFile();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('question_paper.deleted', args: [name]))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = _file == null
        ? ''
        : _formatMeta(_mimeType ?? '', _file!.name, _file!.size);

    return Container(
      width: double.infinity, // fit sidebar width (304)
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
            decoration: TextDecoration.none), // remove underline globally
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (same style as syllabus)
            Row(
              children: [
                const Icon(Icons.description_outlined,
                    color: Color(0xFF0066FF), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  // allow title to shrink and ellipsize
                  child: Text(
                    tr('question_paper.header'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                  color: isDark ? Colors.white : const Color(0xFF666666),
                  constraints: const BoxConstraints(
                      minWidth: 40, minHeight: 40), // compact
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Intro (same layout)
            Text(
              tr('question_paper.intro'),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),

            // Upload section card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E5E5)),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('question_paper.upload_title'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('question_paper.upload_subtitle'),
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF666666)),
                    ),
                    const SizedBox(height: 16),
                    Tooltip(
                      message: _file == null
                          ? tr('question_paper.click_to_upload')
                          : tr('question_paper.replace_file'),
                      waitDuration: const Duration(milliseconds: 250),
                      child: GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF404040)
                                    : const Color(0xFFDCE6F2),
                                width: 1.5),
                            color:
                                isDark ? const Color(0xFF222222) : Colors.white,
                          ),
                          child: Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // use main app's upload icon
                                  Icon(
                                    Icons.file_upload_outlined,
                                    size: 48,
                                    color: isDark
                                        ? const Color(0xFFAAAAAA)
                                        : const Color(0xFF6B7A95),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _file == null
                                        ? tr('question_paper.click_to_upload')
                                        : tr('question_paper.replace_file'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? const Color(0xFFAAAAAA)
                                          : const Color(0xFF6B7A95),
                                      // decoration removed globally by DefaultTextStyle
                                    ),
                                  ),
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(height: 18),

            // Uploaded section (single file preview, same card style)
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF404040)
                            : const Color(0xFFE5E5E5)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('question_paper.uploaded_section_title'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A))),
                        const SizedBox(height: 6),
                        Text(tr('question_paper.uploaded_section_subtitle'),
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFAAAAAA)
                                    : const Color(0xFF666666))),
                        const SizedBox(height: 12),
                        if (_file != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F1F1F)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF404040)
                                      : const Color(0xFFECEFF1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.article_outlined,
                                    color: Color(0xFF0066FF), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _file!.name,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1A1A1A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (meta.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          meta,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFF888888)
                                                : const Color(0xFF888888),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20),
                                  onPressed: _deleteFile,
                                  color: isDark
                                      ? const Color(0xFFCC6666)
                                      : const Color(0xFFFF4444),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(tr('question_paper.no_file'),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFAAAAAA)
                                      : const Color(0xFF666666))),
                      ]),
                ),
              ),
            ),

            // Footer Cancel (same style as syllabus)
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E5E5)),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.white : const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(tr('question_paper.cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mimeTypeFromExtension(String? ext) {
    final v = (ext ?? '').toLowerCase();
    switch (v) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return '';
    }
  }

  String _formatMeta(String mimeType, String filename, int sizeBytes) {
    final type = _typeLabel(mimeType, filename);
    final size = _formatBytes(sizeBytes);

    if (type.isEmpty && size.isEmpty) return '';
    if (type.isNotEmpty && size.isNotEmpty) return '$type • $size';
    return type.isNotEmpty ? type : size;
  }

  String _typeLabel(String mimeType, String filename) {
    final mt = mimeType.toLowerCase();
    if (mt.contains('pdf')) return 'PDF';
    if (mt.contains('word') || mt.contains('officedocument')) return 'DOC';

    final dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) return '';
    final ext = filename.substring(dot + 1).toUpperCase();
    return ext;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    const unit = 1024;
    if (bytes < unit) return '$bytes B';
    if (bytes < unit * unit) {
      final kb = bytes / unit;
      return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
    }
    final mb = bytes / (unit * unit);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }
}

void showQuestionPaperSidebar(BuildContext context, {String? chatSessionId}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      final theme = Theme.of(buildContext);
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: theme.colorScheme.surface, // was Colors.white
          borderRadius: BorderRadius.zero,
          child: SafeArea(
            child: SizedBox(
              width: 304,
              height: double.infinity,
              child: QuestionPaperPage(chatSessionId: chatSessionId),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(anim),
        child: child,
      );
    },
  );
}
