import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:async';
// add JSON helpers
import 'dart:convert';

import '../../core/utils/blocking_progress_dialog.dart';
import '../../services/resource_service.dart';
import '../../services/chat_service.dart';

class SyllabusItem {
  final String title;
  final String subject;
  final String date;
  final String tags;
  final int sizeBytes;
  final String mimeType;
  SyllabusItem(
      {required this.title,
      required this.subject,
      required this.date,
      required this.tags,
      this.sizeBytes = 0,
      this.mimeType = ''});

  // add serialization for local persistence
  Map<String, dynamic> toJson() => {
        'title': title,
        'subject': subject,
        'date': date,
        'tags': tags,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
      };

  factory SyllabusItem.fromJson(Map<String, dynamic> json) => SyllabusItem(
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        date: json['date'] ?? '',
        tags: json['tags'] ?? '',
        sizeBytes:
            (json['sizeBytes'] is num) ? (json['sizeBytes'] as num).toInt() : 0,
        mimeType: (json['mimeType'] ?? '').toString(),
      );
}

class TeacherSyllabusContent extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final VoidCallback? onToggleLocale;
  final String? chatSessionId;

  const TeacherSyllabusContent(
      {super.key, this.onToggleTheme, this.onToggleLocale, this.chatSessionId});

  @override
  State<TeacherSyllabusContent> createState() => _TeacherSyllabusContentState();
}

class _TeacherSyllabusContentState extends State<TeacherSyllabusContent> {
  final List<SyllabusItem> _items = [];

  static const _prefsKeyPrefix = 'syllabus_items:';
  static const _legacyPrefsKey = 'syllabus_items';
  static const Set<String> _allowed = {'pdf', 'doc', 'docx'};

  String get _prefsKey =>
      '$_prefsKeyPrefix${widget.chatSessionId ?? 'no-session'}';

  @override
  void initState() {
    super.initState();
    _loadFromBackendThenCache();
  }

  Future<void> _loadFromBackendThenCache() async {
    final sessionId = widget.chatSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      await _loadItems();
      return;
    }

    try {
      final details = await ChatService.getChatSessionDetails(sessionId);
      final backendItems = details
          .allByType('syllabus')
          .map(
            (r) => SyllabusItem(
              title: r.filename.isNotEmpty
                  ? r.filename
                  : (r.resourceId.isNotEmpty ? 'Resource ${r.resourceId}' : ''),
              subject: tr('syllabus.file_subject_default'),
              date: '',
              tags: '',
              sizeBytes: r.sizeBytes,
              mimeType: r.mimeType,
            ),
          )
          .where((e) => e.title.isNotEmpty)
          .toList();

      if (!mounted) return;

      if (backendItems.isNotEmpty) {
        setState(() {
          _items
            ..clear()
            ..addAll(backendItems);
        });
        await _saveItems();
        return;
      }
    } catch (e) {
      // ignore and fall back to local cache
      // ignore: avoid_print
      print('Failed to load syllabus from backend: $e');
    }

    await _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    var listJson = prefs.getStringList(_prefsKey);
    // Migration fallback: older builds stored syllabus list globally.
    listJson ??= prefs.getStringList(_legacyPrefsKey);
    if (listJson == null) return;
    try {
      final decoded = listJson
          .map((s) => SyllabusItem.fromJson(
              s.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(s)) : {}))
          .toList();

      // Remove older seeded default examples if they were persisted previously.
      final filtered = decoded.where((item) {
        final isDefaultScience = item.title == 'Grade 10 Science Syllabus' &&
            item.subject == 'Science • Grade 10' &&
            item.date == '15/01/2024' &&
            item.tags == 'Physics, Chemistry, Biology';
        final isDefaultMath = item.title == 'Grade 11 Mathematics Syllabus' &&
            item.subject == 'Mathematics • Grade 11' &&
            item.date == '20/02/2024' &&
            item.tags == 'Algebra, Geometry, Trigonometry';
        return !(isDefaultScience || isDefaultMath);
      }).toList();

      setState(() {
        _items
          ..clear()
          ..addAll(filtered);
      });

      if (filtered.length != decoded.length) {
        await _saveItems();
      }
    } catch (_) {
      // ignore malformed storage
    }
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    // ensure List<String> for setStringList
    final List<String> listJson =
        _items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_prefsKey, listJson);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        // Using FileType.any avoids "No items" issues on some devices.
        // We validate the extension manually below.
        type: FileType.any,
      );

      if (result == null) {
        // user cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('syllabus.select_file_cancelled'))),
        );
        return;
      }

      final pickedFiles = result.files;
      if (pickedFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('syllabus.select_file_cancelled'))),
        );
        return;
      }

      // Validate extensions
      for (final f in pickedFiles) {
        final ext = f.extension?.toLowerCase();
        if (ext == null || !_allowed.contains(ext)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('syllabus.upload_error'))),
          );
          return;
        }
      }

      // Upload to backend for the active chat session (if available)
      if (widget.chatSessionId != null) {
        final List<MultipartFile> multipartFiles = [];

        for (final f in pickedFiles) {
          if (kIsWeb) {
            if (f.bytes != null) {
              multipartFiles.add(
                MultipartFile.fromBytes(f.bytes!, filename: f.name),
              );
            }
          } else {
            if (f.path != null) {
              multipartFiles.add(
                await MultipartFile.fromFile(f.path!, filename: f.name),
              );
            }
          }
        }

        if (multipartFiles.isNotEmpty) {
          final filename = pickedFiles.first.name;
          unawaited(
            showBlockingProgressDialog(
              context,
              message: 'Uploading $filename...',
            ),
          );
          // ignore: avoid_print
          print(
              'Uploading syllabus with chatSessionId: ${widget.chatSessionId}');
          try {
            await ResourceService.uploadSyllabus(
              files: multipartFiles,
              chatSessionId: widget.chatSessionId!,
            );
          } finally {
            if (mounted &&
                Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          }
        } else {
          // ignore: avoid_print
          print(
              'Skipping syllabus upload: File bytes/path missing. Web: $kIsWeb');
        }
      } else {
        // ignore: avoid_print
        print('Skipping syllabus upload: chatSessionId is null');
      }

      final filename = pickedFiles.first.name;
      final now = DateTime.now();
      final date =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      setState(() {
        for (final f in pickedFiles.reversed) {
          _items.insert(
            0,
            SyllabusItem(
              title: f.name,
              subject: tr('syllabus.file_subject_default'),
              date: date,
              tags: '',
              sizeBytes: f.size,
              mimeType: _mimeTypeFromExtension(f.extension),
            ),
          );
        }
      });
      await _saveItems();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('syllabus.upload_success', args: [filename]))));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('syllabus.upload_error'))));
    }
  }

  Future<bool> _confirmDelete(String title) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(tr('syllabus.delete_title')),
          // use namedArgs so translators can use {name}
          content:
              Text(tr('syllabus.delete_confirm', namedArgs: {'name': title})),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(tr('syllabus.cancel'))),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(tr('syllabus.delete'))),
          ],
        );
      },
    );
    return res == true;
  }

  void _deleteItem(int index) async {
    final item = _items[index];
    final ok = await _confirmDelete(item.title);
    if (!ok) return;
    setState(() {
      _items.removeAt(index);
    });
    await _saveItems();
    // show deletion notification with name
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('syllabus.deleted', args: [item.title]))));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity, // fit sidebar width (304)
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
            decoration: TextDecoration.none), // remove underline globally
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // line-style book icon (no bg)
                const Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFF0066FF),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  tr('syllabus.header'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                  color: isDark ? Colors.white : const Color(0xFF666666),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Intro paragraph
            Text(
              tr('syllabus.intro'),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            // Upload section -> calls _pickFile()
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
                    Text(tr('syllabus.upload_title'),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A1A))),
                    const SizedBox(height: 8),
                    Text(tr('syllabus.upload_subtitle'),
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFFAAAAAA)
                                : const Color(0xFF666666))),
                    const SizedBox(height: 16),
                    GestureDetector(
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
                                tr('syllabus.click_to_upload'),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? const Color(0xFFAAAAAA)
                                      : const Color(0xFF6B7A95),
                                  // decoration removed globally by DefaultTextStyle
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),

            const SizedBox(height: 18),

            // Uploaded list (dynamic)
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
                        Text(tr('syllabus.uploaded_section_title'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A))),
                        const SizedBox(height: 6),
                        Text(tr('syllabus.uploaded_section_subtitle'),
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFAAAAAA)
                                    : const Color(0xFF666666))),
                        const SizedBox(height: 12),
                        Column(
                          children: List.generate(_items.length, (i) {
                            final it = _items[i];
                            return Column(children: [
                              _buildSyllabusItem(it, i),
                              const SizedBox(height: 12),
                            ]);
                          }),
                        ),
                      ]),
                ),
              ),
            ),

            // Cancel button
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF404040)
                          : const Color(0xFFE5E5E5))),
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white : const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text(tr('syllabus.cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusItem(SyllabusItem item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = _formatMeta(item.mimeType, item.title, item.sizeBytes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color:
                  isDark ? const Color(0xFF404040) : const Color(0xFFECEFF1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Icon(Icons.article_outlined,
              color: Color(0xFF0066FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(item.title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteItem(index),
              color:
                  isDark ? const Color(0xFFCC6666) : const Color(0xFFFF4444)),
        ]),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            meta,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF888888) : const Color(0xFF888888),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Text(item.subject,
            style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFAAAAAA)
                    : const Color(0xFF666666))),
        const SizedBox(height: 6),
        Text('${tr('syllabus.uploaded')}: ${item.date}',
            style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF888888)
                    : const Color(0xFF888888))),
        const SizedBox(height: 6),
        Text(item.tags,
            style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFAAAAAA)
                    : const Color(0xFF666666))),
      ]),
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

void showSyllabusSidebar(BuildContext context, {String? chatSessionId}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, a, b) {
      final theme = Theme.of(context);
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: theme.colorScheme.surface, // was Colors.white
          borderRadius: BorderRadius.zero,
          child: SafeArea(
            child: SizedBox(
              width: 304,
              height: double.infinity,
              child: TeacherSyllabusContent(chatSessionId: chatSessionId),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(animation),
        child: child,
      );
    },
  );
}
