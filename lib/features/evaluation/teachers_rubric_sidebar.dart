import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TeachersRubricSidebar extends StatefulWidget {
  const TeachersRubricSidebar({super.key});

  @override
  State<TeachersRubricSidebar> createState() => _TeachersRubricSidebarState();
}

class _TeachersRubricSidebarState extends State<TeachersRubricSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SizedBox(
        width: 304,
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
                  'balanced_evaluation'.tr(),
                  'balanced_semantic'.tr(), 'marks_40'.tr(),
                  'balanced_coverage'.tr(), 'marks_30'.tr(),
                  'balanced_relevance'.tr(), 'marks_30'.tr(),
                ),
                const SizedBox(height: 24),
                _buildRubricCard(
                  theme,
                  'understanding_focused'.tr(),
                  'understanding_semantic'.tr(), 'marks_60'.tr(),
                  'understanding_coverage'.tr(), 'marks_20'.tr(),
                  'understanding_relevance'.tr(), 'marks_20'.tr(),
                ),
                const SizedBox(height: 24),
                _buildRubricCard(
                  theme,
                  'content_focused'.tr(),
                  'content_semantic'.tr(), 'marks_30'.tr(),
                  'content_coverage'.tr(), 'marks_50'.tr(),
                  'content_relevance'.tr(), 'marks_20'.tr(),
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
                  'teacher_rubrics'.tr(),
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
                tooltip: 'close'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'teacher_rubric_description'.tr(),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'or_upload_custom'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'pdf_docx_excel'.tr(),
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
                child: Text('upload'.tr()),
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
  String semanticLabel, String semanticMark,
  String coverageLabel, String coverageMark,
  String relevanceLabel, String relevanceMark,
) {
  return Card(
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
                color: theme.colorScheme.primary,
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
          _item('total'.tr(), 'marks_100'.tr()),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('upload_message'.tr())),
    );
  }
}
