import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RubricSelectionSidebar extends StatefulWidget {
  const RubricSelectionSidebar({super.key});

  @override
  State<RubricSelectionSidebar> createState() => _RubricSelectionSidebarState();
}

class _RubricSelectionSidebarState extends State<RubricSelectionSidebar> {
  String? _selectedRubric;

  // localization keys for standard rubrics (defined in JSON)
  final List<String> _standardRubrics = [
    'question_paper.rubric_general_writing',
    'question_paper.rubric_math_problem_solving',
    'question_paper.rubric_science_lab_report',
    'question_paper.rubric_language_arts',
    'question_paper.rubric_history_essay',
    'question_paper.rubric_creative_writing',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final drawerW = screenW * 0.9 > 304 ? 304.0 : screenW * 0.9;

    return Drawer(
      backgroundColor: theme.colorScheme.surface, // was Colors.white
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
                Card(
                  elevation: theme.brightness == Brightness.light ? 2 : 0,
                  color: theme.cardColor, // was Colors.white
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'choose_a_rubric'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'question_paper.standard_rubrics'.tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRubricsDropdown(theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: theme.brightness == Brightness.light ? 2 : 0,
                  color: theme.cardColor, // was Colors.white
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'pdf_docx_excel'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleUpload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor: theme.colorScheme.onSurface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'upload'.tr(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                  'select_rubric'.tr(),
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
            'standard_rubrics'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16), // Add bottom padding for the border
        ],
      ),
    );
  }

  Widget _buildRubricsDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedRubric,
      decoration: InputDecoration(
        labelText: 'select_a_rubric'.tr(),
        labelStyle: TextStyle(
          fontSize: 10, // Custom label size
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      borderRadius: BorderRadius.circular(8),
      dropdownColor: theme.colorScheme.surface,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      items: _standardRubrics.map((String rubricKey) {
        return DropdownMenuItem<String>(
          value: rubricKey,
          child: Text(rubricKey.tr()),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedRubric = newValue;
        });
      },
      icon: Icon(
        Icons.arrow_drop_down,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  void _handleUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('upload_message'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

void showRubricSelectionSidebar(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      final theme = Theme.of(buildContext);
      final screenW = MediaQuery.of(buildContext).size.width;
      final drawerW = screenW * 0.9 > 304 ? 304.0 : screenW * 0.9;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: theme.colorScheme.surface, // was Colors.white
          borderRadius: BorderRadius.zero,
          child: SizedBox(
            width: drawerW,
            height: double.infinity,
            child: const RubricSelectionSidebar(),
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

