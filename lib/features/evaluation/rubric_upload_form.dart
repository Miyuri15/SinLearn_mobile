import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RubricUploadForm extends StatefulWidget {
  final VoidCallback? onRubricApplied;
  final String? chatSessionId;

  const RubricUploadForm({
    super.key,
    this.onRubricApplied,
    this.chatSessionId,
  });

  @override
  State<RubricUploadForm> createState() => _RubricUploadFormState();
}

class _RubricUploadFormState extends State<RubricUploadForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController semanticController =
      TextEditingController(text: '40');
  final TextEditingController coverageController =
      TextEditingController(text: '30');
  final TextEditingController relevanceController =
      TextEditingController(text: '30');

  String? totalError; // <-- for inline error display

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_rubric'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'total_value_note'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              _buildPercentageField('content_semantic', semanticController),
              const SizedBox(height: 8),
              _buildPercentageField('content_coverage', coverageController),
              const SizedBox(height: 8),
              _buildPercentageField('content_relevance', relevanceController),
              const SizedBox(height: 12),

              // <-- Show total error inline
              if (totalError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    totalError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'submit'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageField(String key, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'question_paper.$key'.tr(),
        suffixText: '%',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'required'.tr();
        final num? val = num.tryParse(value);
        if (val == null || val < 0 || val > 100) {
          return 'enter_0_100'.tr();
        }
        return null;
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final semantic = int.parse(semanticController.text);
    final coverage = int.parse(coverageController.text);
    final relevance = int.parse(relevanceController.text);
    final total = semantic + coverage + relevance;

    if (total != 100) {
      setState(() {
        totalError = 'total_error'.tr(); // <-- show inline error
      });
      return;
    }

    // Clear previous error
    setState(() {
      totalError = null;
    });

    // Save rubric to local storage
    final prefs = await SharedPreferences.getInstance();
    // Save as custom rubric data
    final sid = widget.chatSessionId;
    if (sid != null && sid.isNotEmpty) {
      await prefs.setInt('custom_semantic:$sid', semantic);
      await prefs.setInt('custom_coverage:$sid', coverage);
      await prefs.setInt('custom_relevance:$sid', relevance);
      await prefs.setBool('hasCustomRubric:$sid', true);
    }

    // Legacy (non-session) keys
    await prefs.setInt('custom_semantic', semantic);
    await prefs.setInt('custom_coverage', coverage);
    await prefs.setInt('custom_relevance', relevance);
    await prefs.setBool('hasCustomRubric', true);

    if (!mounted) return;
    Navigator.pop(context);
    widget.onRubricApplied?.call();

    // Use current context before the dialog is disposed.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('upload_message'.tr())),
    );
  }

  @override
  void dispose() {
    semanticController.dispose();
    coverageController.dispose();
    relevanceController.dispose();
    super.dispose();
  }
}
