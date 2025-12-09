import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';

class QuestionPaperPage extends StatefulWidget {
  const QuestionPaperPage({super.key});

  @override
  State<QuestionPaperPage> createState() => _QuestionPaperPageState();
}

class _QuestionPaperPageState extends State<QuestionPaperPage> {
  PlatformFile? _file;
  static const Set<String> _allowed = {'pdf', 'doc', 'docx'};

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: _allowed.toList(),
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
      setState(() => _file = picked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('question_paper.upload_success', args: [picked.name]))),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('question_paper.upload_error'))),
      );
    }
  }

  void _deleteFile() {
    final name = _file?.name ?? '';
    setState(() => _file = null);
    if (name.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('question_paper.deleted', args: [name]))),
      );
    }
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
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none), // remove underline globally
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (same style as syllabus)
            Row(
              children: [
                Icon(Icons.description_outlined, color: const Color(0xFF0066FF), size: 22),
                const SizedBox(width: 12),
                Expanded( // allow title to shrink and ellipsize
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
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40), // compact
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
                color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),

            // Upload section card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E5E5)),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  tr('question_paper.upload_title'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('question_paper.upload_subtitle'),
                  style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666)),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF404040) : const Color(0xFFDCE6F2), width: 1.5),
                      color: isDark ? const Color(0xFF222222) : Colors.white,
                    ),
                    child: Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        // use main app's upload icon
                        Icon(
                          Icons.file_upload_outlined,
                          size: 48,
                          color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7A95),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _file == null
                              ? tr('question_paper.click_to_upload')
                              : tr('question_paper.replace_file'),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7A95),
                            // decoration removed globally by DefaultTextStyle
                          ),
                        ),
                      ]),
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
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E5E5)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('question_paper.uploaded_section_title'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                    const SizedBox(height: 6),
                    Text(tr('question_paper.uploaded_section_subtitle'), style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666))),
                    const SizedBox(height: 12),
                    if (_file != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFF404040) : const Color(0xFFECEFF1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.article_outlined, color: Color(0xFF0066FF), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _file!.name,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: _deleteFile,
                              color: isDark ? const Color(0xFFCC6666) : const Color(0xFFFF4444),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(tr('question_paper.no_file'), style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666))),
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
                border: Border.all(color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E5E5)),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(tr('question_paper.cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
void showQuestionPaperSidebar(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
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
              child: const QuestionPaperPage(),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
        child: child,
      );
    },
  );
}
