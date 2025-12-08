import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RubricUploadForm extends StatefulWidget {
  const RubricUploadForm({super.key});

  @override
  State<RubricUploadForm> createState() => _RubricUploadFormState();
}

class _RubricUploadFormState extends State<RubricUploadForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController semanticController = TextEditingController(text: '40');
  final TextEditingController coverageController = TextEditingController(text: '30');
  final TextEditingController relevanceController = TextEditingController(text: '30');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // ✅ Rounded corners
      ),
      backgroundColor: Colors.white, // was theme.colorScheme.background
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Title ---
              Text(
                'select_rubric'.tr(), // ✅ Localized
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),

              // --- Subtopic ---
              Text(
                'total_value_note'.tr(), // Add this key to JSON for "The entered value total should 100%"
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              // --- Input fields ---
              _buildPercentageField('content_semantic', semanticController),
              const SizedBox(height: 8),
              _buildPercentageField('content_coverage', coverageController),
              const SizedBox(height: 8),
              _buildPercentageField('content_relevance', relevanceController),
              const SizedBox(height: 20),

              // --- Submit button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // ✅ Blue button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded button
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _submit,
                  child: Text(
                    'submit'.tr(), // ✅ Localized
                    style: const TextStyle(fontSize: 16, color: Colors.white),
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
        labelText: key.tr(), // ✅ Localized field label
        suffixText: '%',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final num? val = num.tryParse(value);
        if (val == null || val < 0 || val > 100) return 'Enter 0-100';
        return null;
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final total = int.parse(semanticController.text) +
          int.parse(coverageController.text) +
          int.parse(relevanceController.text);

      if (total != 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('total_error'.tr())), // ✅ Localized total error
        );
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('upload_message'.tr())), // ✅ Localized upload message
      );
    }
  }

  @override
  void dispose() {
    semanticController.dispose();
    coverageController.dispose();
    relevanceController.dispose();
    super.dispose();
  }
}
