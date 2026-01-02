import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rubric_upload_form.dart';

class TeachersRubricSidebar extends StatefulWidget {
  const TeachersRubricSidebar({super.key});

  @override
  State<TeachersRubricSidebar> createState() => _TeachersRubricSidebarState();
}

class _TeachersRubricSidebarState extends State<TeachersRubricSidebar> {
  bool hasRubric = false;
  int? semantic, coverage, relevance;

  @override
  void initState() {
    super.initState();
    _loadRubric();
  }

  Future<void> _loadRubric() async {
    final prefs = await SharedPreferences.getInstance();

    final exists = prefs.getBool('hasRubric') ?? false;

    if (exists) {
      setState(() {
        hasRubric = true;
        semantic = prefs.getInt('semantic') ?? 0;
        coverage = prefs.getInt('coverage') ?? 0;
        relevance = prefs.getInt('relevance') ?? 0;
      });
    }
  }

  Future<void> _removeRubric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('semantic');
    await prefs.remove('coverage');
    await prefs.remove('relevance');
    await prefs.setBool('hasRubric', false);

    setState(() {
      hasRubric = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Rubric removed successfully")),
    );
  }

  void _viewRubric() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Current Rubric"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Semantic: $semantic%"),
              Text("Coverage: $coverage%"),
              Text("Relevance: $relevance%"),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final drawerW = screenW * 0.9 > 304 ? 304.0 : screenW * 0.9;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SizedBox(
        width: drawerW,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),

              // ----------- SHOW BUTTONS ONLY IF RUBRIC EXISTS -----------
              if (hasRubric) ...[
                _rubricButtonsRow(),
                const SizedBox(height: 20),
              ],

              _buildUploadCard(theme),
              const SizedBox(height: 24),

              // Normal Cards (unchanged)
              _buildRubricCard(
                theme,
                'question_paper.balanced_evaluation'.tr(),
                'question_paper.balanced_semantic'.tr(),
                'question_paper.marks_40'.tr(),
                'question_paper.balanced_coverage'.tr(),
                'question_paper.marks_30'.tr(),
                'question_paper.balanced_relevance'.tr(),
                'question_paper.marks_30'.tr(),
              ),

              const SizedBox(height: 24),

              _buildRubricCard(
                theme,
                'question_paper.understanding_focused'.tr(),
                'question_paper.understanding_semantic'.tr(),
                'question_paper.marks_60'.tr(),
                'question_paper.understanding_coverage'.tr(),
                'question_paper.marks_20'.tr(),
                'question_paper.understanding_relevance'.tr(),
                'question_paper.marks_20'.tr(),
              ),

              const SizedBox(height: 24),

              _buildRubricCard(
                theme,
                'question_paper.content_focused'.tr(),
                'question_paper.content_semantic'.tr(),
                'question_paper.marks_30'.tr(),
                'question_paper.content_coverage'.tr(),
                'question_paper.marks_50'.tr(),
                'question_paper.content_relevance'.tr(),
                'question_paper.marks_20'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            'question_paper.teacher_rubrics'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close))
        ]),
        Text(
          'question_paper.teacher_rubric_description'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // ---------------- Upload Card ----------------
  Widget _buildUploadCard(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('question_paper.or_upload_custom'.tr(),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'question_paper.pdf_docx_excel'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                child: Text('question_paper.upload'.tr()),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const RubricUploadForm(),
                  ).then((_) => _loadRubric());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Custom Card ----------------
  Widget _buildRubricCard(
    ThemeData theme,
    String rubricTitle,
    String semanticLabel,
    String semanticMark,
    String coverageLabel,
    String coverageMark,
    String relevanceLabel,
    String relevanceMark,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Icon(Icons.description, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rubricTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _row(semanticLabel, semanticMark),
          _row(coverageLabel, coverageMark),
          _row(relevanceLabel, relevanceMark),
          const Divider(),
          _row('question_paper.total'.tr(), 'question_paper.marks_100'.tr()),
        ]),
      ),
    );
  }

  Widget _row(String labelText, String valueText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(labelText, style: const TextStyle(fontSize: 12)),
        Text(valueText, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onTap,
      {bool danger = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: danger ? Colors.red : Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

Widget _rubricButtonsRow() {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _viewRubric,
          icon: const Icon(Icons.visibility, size: 18),
          label: Text('question_paper.view_rubric'.tr()), // <-- localized
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _removeRubric,
          icon: const Icon(Icons.delete, size: 18),
          label: Text('question_paper.remove_rubric'.tr()), // <-- localized
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    ],
  );
}

}

void showTeachersRubricSidebar(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final theme = Theme.of(dialogContext);
      final screenWidth = MediaQuery.of(dialogContext).size.width;

      // SAFE drawer width (never NaN or null)
      final double drawerWidth = (screenWidth * 0.8).clamp(250.0, 350.0);

      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: drawerWidth,
            height: double.infinity,
            color: theme.colorScheme.surface,
            child: const TeachersRubricSidebar(),
          ),
        ),
      );
            
},
    transitionBuilder: (context, anim, secondaryAnim, child) {
      final offsetAnim = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
      ));
  
      return SlideTransition(position: offsetAnim, child: child);
    },
  );
}
