import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'rubric_upload_form.dart';

class TeachersRubricSidebar extends StatefulWidget {
  const TeachersRubricSidebar({super.key});

  @override
  State<TeachersRubricSidebar> createState() => _TeachersRubricSidebarState();
}

class _TeachersRubricSidebarState extends State<TeachersRubricSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final drawerW = screenW * 0.9 > 304 ? 304.0 : screenW * 0.9;

    return Drawer(
      backgroundColor: Colors.white, // make drawer host solid white
      child: SizedBox(
        width: drawerW,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),
                _buildUploadCard(theme),
                const SizedBox(height: 24),

                // Rubric Cards
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
      ),
    );
  }

  // ---------------------- Header -------------------------
  Widget _buildHeader(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'question_paper.teacher_rubrics'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'question_paper.close'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'question_paper.teacher_rubric_description'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------- Upload Card -------------------------
  Widget _buildUploadCard(ThemeData theme) {
    return Card(
      color: Colors.white, // ensure white
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'question_paper.or_upload_custom'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'question_paper.pdf_docx_excel'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleUpload,
                child: Text('question_paper.upload'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- Rubric Card -------------------------
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
      color: Colors.white, // ensure white
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Paper icon added to title for ALL cards
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rubricTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 15, // Custom size
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _item(semanticLabel, semanticMark),
            _item(coverageLabel, coverageMark),
            _item(relevanceLabel, relevanceMark),
            const Divider(),
            _item('question_paper.total'.tr(), 'question_paper.marks_100'.tr()),
          ],
        ),
      ),
    );
  }

  // ---------------------- Helper -------------------------
  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12, // Custom size for labels
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12, // Custom size for values
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpload() {
    showDialog(
      context: context,
      builder: (context) => const RubricUploadForm(),
    );
  }
}

void showTeachersRubricSidebar(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      final screenW = MediaQuery.of(buildContext).size.width;
      final drawerW = screenW * 0.9 > 304 ? 304.0 : screenW * 0.9;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          borderRadius: BorderRadius.zero,
          color: Colors.white, // ensure white host
          child: SizedBox(
            width: drawerW,
            height: double.infinity,
            child: const TeachersRubricSidebar(),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
  );
}
