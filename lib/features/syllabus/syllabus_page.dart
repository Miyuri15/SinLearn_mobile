import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// add JSON helpers
import 'dart:convert';

class SyllabusItem {
  final String title;
  final String subject;
  final String date;
  final String tags;
  SyllabusItem(
      {required this.title,
      required this.subject,
      required this.date,
      required this.tags});

  // add serialization for local persistence
  Map<String, dynamic> toJson() => {
        'title': title,
        'subject': subject,
        'date': date,
        'tags': tags,
      };

  factory SyllabusItem.fromJson(Map<String, dynamic> json) => SyllabusItem(
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        date: json['date'] ?? '',
        tags: json['tags'] ?? '',
      );
}

class TeacherSyllabusContent extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final VoidCallback? onToggleLocale;

  const TeacherSyllabusContent(
      {super.key, this.onToggleTheme, this.onToggleLocale});

  @override
  State<TeacherSyllabusContent> createState() => _TeacherSyllabusContentState();
}

class _TeacherSyllabusContentState extends State<TeacherSyllabusContent> {
  final List<SyllabusItem> _items = [
    // initial examples (optional)
    SyllabusItem(
        title: 'Grade 10 Science Syllabus',
        subject: 'Science • Grade 10',
        date: '15/01/2024',
        tags: 'Physics, Chemistry, Biology'),
    SyllabusItem(
        title: 'Grade 11 Mathematics Syllabus',
        subject: 'Mathematics • Grade 11',
        date: '20/02/2024',
        tags: 'Algebra, Geometry, Trigonometry'),
  ];

  static const _prefsKey = 'syllabus_items';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getStringList(_prefsKey);
    if (listJson == null) return;
    try {
      final decoded = listJson
          .map((s) => SyllabusItem.fromJson(
              s.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(s)) : {}))
          .toList();
      setState(() {
        _items
          ..clear()
          ..addAll(decoded);
      });
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
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null) {
        // user cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('syllabus.select_file_cancelled'))),
        );
        return;
      }

      final file = result.files.single;
      final filename = file.name;
      final now = DateTime.now();
      final date =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      setState(() {
        _items.insert(
            0,
            SyllabusItem(
                title: filename,
                subject: tr('syllabus.file_subject_default'),
                date: date,
                tags: ''));
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
          backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
          title: Text(tr('syllabus.delete_title')),
          // use namedArgs so translators can use {name}
          content: Text(tr('syllabus.delete_confirm', namedArgs: {'name': title})),
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
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none), // remove underline globally
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // line-style book icon (no bg)
                Icon(
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
                    color: isDark ? Colors.white : Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                  color: isDark ? Colors.white : Color(0xFF666666),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Intro paragraph
            Text(
              tr('syllabus.intro'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Color(0xFFAAAAAA) : Color(0xFF666666),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            // Upload section -> calls _pickFile()
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF2A2A2A) : Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Color(0xFF404040) : Color(0xFFE5E5E5)),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
              ),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('syllabus.upload_title'),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                Text(tr('syllabus.upload_subtitle'),
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Color(0xFFAAAAAA) : Color(0xFF666666))),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Color(0xFF404040) : Color(0xFFDCE6F2),
                          width: 1.5),
                      color: isDark ? Color(0xFF222222) : Colors.white,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // use main app's upload icon
                          Icon(
                            Icons.file_upload_outlined,
                            size: 48,
                            color: isDark ? Color(0xFFAAAAAA) : Color(0xFF6B7A95),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr('syllabus.click_to_upload'),
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Color(0xFFAAAAAA) : Color(0xFF6B7A95),
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
                    color: isDark ? Color(0xFF2A2A2A) : Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Color(0xFF404040) : Color(0xFFE5E5E5)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('syllabus.uploaded_section_title'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white : Color(0xFF1A1A1A))),
                        const SizedBox(height: 6),
                        Text(tr('syllabus.uploaded_section_subtitle'),
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Color(0xFFAAAAAA)
                                    : Color(0xFF666666))),
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
                      color: isDark ? Color(0xFF404040) : Color(0xFFE5E5E5))),
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Color(0xFF1A1A1A),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: isDark ? Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? Color(0xFF404040) : Color(0xFFECEFF1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Icon(Icons.article_outlined, color: Color(0xFF0066FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(item.title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF1A1A1A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              icon: Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteItem(index),
              color: isDark ? Color(0xFFCC6666) : Color(0xFFFF4444)),
        ]),
        const SizedBox(height: 8),
        Text(item.subject,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Color(0xFFAAAAAA) : Color(0xFF666666))),
        const SizedBox(height: 6),
        Text('${tr('syllabus.uploaded')}: ${item.date}',
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Color(0xFF888888) : Color(0xFF888888))),
        const SizedBox(height: 6),
        Text(item.tags,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Color(0xFFAAAAAA) : Color(0xFF666666))),
      ]),
    );
  }
}

void showSyllabusSidebar(BuildContext context) {
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
              child: const TeacherSyllabusContent(),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
        child: child,
      );
    },
  );
}
