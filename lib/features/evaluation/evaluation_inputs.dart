import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';

class EvaluationInputPage extends StatefulWidget {
  const EvaluationInputPage({super.key});

  @override
  State<EvaluationInputPage> createState() => _EvaluationTextPageState();
}

class _EvaluationTextPageState extends State<EvaluationInputPage> {
  int _selectedSegment = 1;
  final TextEditingController _totalMarksController = TextEditingController();
  final TextEditingController _mainQuestionsController = TextEditingController();
  final TextEditingController _requiredQuestionsController = TextEditingController();
  // Removed: final TextEditingController _subQuestionsController = TextEditingController();

  bool _isFileUploaded = false;
  Map<String, dynamic> _allocatedMarks = {};
  bool _showAllocateMarksPopup = false;
  int _currentQuestionIndex = 0;
  List<TextEditingController> _subQuestionMarkControllers = [];

  static const Color primaryBlue = Color(0xFF2196F3);

  @override
  void dispose() {
    _totalMarksController.dispose();
    _mainQuestionsController.dispose();
    _requiredQuestionsController.dispose();
    // Removed: _subQuestionsController.dispose();
    _disposeSubQuestionControllers();
    super.dispose();
  }

  void _disposeSubQuestionControllers() {
    for (var controller in _subQuestionMarkControllers) {
      controller.dispose();
    }
    _subQuestionMarkControllers.clear();
  }

  void _initializePopup() {
    _disposeSubQuestionControllers();
    final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;

    if (mainQuestions > 0) {
      for (int i = 1; i <= mainQuestions; i++) {
        _allocatedMarks['Q$i'] = {};
        // Start with one default sub-question
        _allocatedMarks['Q$i']['S1'] = '';
      }
      _updateSubQuestionControllers();
    }
  }

  void _updateSubQuestionControllers() {
    _disposeSubQuestionControllers();
    final currentQuestion = _currentQuestionIndex + 1;
    final subQuestions = _allocatedMarks['Q$currentQuestion']?.length ?? 1;

    for (int i = 1; i <= subQuestions; i++) {
      final controller = TextEditingController(
          text: _allocatedMarks['Q$currentQuestion']?['S$i']?.toString() ?? '');
      _subQuestionMarkControllers.add(controller);
    }
  }

  void _saveCurrentQuestionMarks() {
    final currentQuestion = _currentQuestionIndex + 1;
    final subQuestions = _allocatedMarks['Q$currentQuestion']?.length ?? 0;

    for (int i = 1; i <= subQuestions; i++) {
      if (i - 1 < _subQuestionMarkControllers.length) {
        _allocatedMarks['Q$currentQuestion']['S$i'] = _subQuestionMarkControllers[i - 1].text;
      }
    }
  }

  void _showAllocateMarksDialog() {
    final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;

    if (mainQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('evaluation.validNumbersRequired'.tr())),
      );
      return;
    }

    _initializePopup();
    setState(() {
      _showAllocateMarksPopup = true;
      _currentQuestionIndex = 0;
    });
  }

  void _showViewMarksDialog() {
    final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;

    if (_allocatedMarks.isEmpty || mainQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('evaluation.noMarksAllocated'.tr())),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('evaluation.allocatedMarks'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _allocatedMarks.entries.map((question) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${question.key}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...question.value.entries.map((subQuestion) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text('${subQuestion.key}: ${subQuestion.value}'),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  void _saveToLocalStorage() {
    final evaluationData = {
      'totalMarks': _totalMarksController.text,
      'mainQuestions': _mainQuestionsController.text,
      'requiredQuestions': _requiredQuestionsController.text,
      'allocatedMarks': _allocatedMarks,
      'fileUploaded': _isFileUploaded,
    };

    print('Saved to local storage: $evaluationData');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('evaluation.dataSaved'.tr())),
    );
  }

  bool _canSubmit() {
    return _totalMarksController.text.isNotEmpty &&
        _mainQuestionsController.text.isNotEmpty &&
        _requiredQuestionsController.text.isNotEmpty &&
        _isFileUploaded &&
        _allocatedMarks.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      drawer: const RecentChatsDrawer(),
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        onSegmentSelected: (index) {
          setState(() => _selectedSegment = index);
        },
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back Button Row
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    tooltip: 'common.back'.tr(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'evaluation.evaluationDetails'.tr(),
                                    style: isMobile
                                        ? theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.black)
                                        : theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.black),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (!isMobile) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(width: 48), // Spacer to align with title
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() => _isFileUploaded = true);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('evaluation.fileUploaded'.tr())),
                                        );
                                      },
                                      icon: const Icon(Icons.upload_file, color: Colors.white),
                                      label: Text('evaluation.uploadFile'.tr(),
                                          style: const TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() => _isFileUploaded = true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('evaluation.fileUploaded'.tr())),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file, color: Colors.white),
                                  label: Text('evaluation.uploadFile'.tr(),
                                      style: const TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              _buildInputField(
                                  controller: _totalMarksController,
                                  label: 'evaluation.totalMarks'.tr(),
                                  hintText: 'evaluation.enterTotalMarks'.tr(),
                                  icon: Icons.score,
                                  isDarkMode: isDarkMode),
                              const SizedBox(height: 16),
                              _buildInputField(
                                  controller: _mainQuestionsController,
                                  label: 'evaluation.mainQuestions'.tr(),
                                  hintText: 'evaluation.enterMainQuestions'.tr(),
                                  icon: Icons.format_list_numbered,
                                  isDarkMode: isDarkMode),
                              const SizedBox(height: 16),
                              _buildInputField(
                                  controller: _requiredQuestionsController,
                                  label: 'evaluation.requiredQuestions'.tr(),
                                  hintText: 'evaluation.enterRequiredQuestions'.tr(),
                                  icon: Icons.assignment_turned_in,
                                  isDarkMode: isDarkMode),
                              const SizedBox(height: 24),
                              if (isMobile)
                                Column(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _showAllocateMarksDialog,
                                      icon: const Icon(Icons.add_chart, color: Colors.white),
                                      label: Text('evaluation.allocateMarks'.tr(),
                                          style: const TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        minimumSize: const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _showViewMarksDialog,
                                      icon: Icon(Icons.visibility, color: primaryBlue),
                                      label: Text('evaluation.viewMarks'.tr(),
                                          style: TextStyle(color: primaryBlue)),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        side: BorderSide(color: primaryBlue),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _showAllocateMarksDialog,
                                        icon: const Icon(Icons.add_chart, color: Colors.white),
                                        label: Text('evaluation.allocateMarks'.tr(),
                                            style: const TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryBlue,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _showViewMarksDialog,
                                        icon: Icon(Icons.visibility, color: primaryBlue),
                                        label: Text('evaluation.viewMarks'.tr(),
                                            style: TextStyle(color: primaryBlue)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: BorderSide(color: primaryBlue),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              
                              // Action Buttons inside the card
                              const SizedBox(height: 32),
                              Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                              const SizedBox(height: 24),
                              
                              if (isMobile)
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              _totalMarksController.clear();
                                              _mainQuestionsController.clear();
                                              _requiredQuestionsController.clear();
                                              setState(() {
                                                _isFileUploaded = false;
                                                _allocatedMarks.clear();
                                              });
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              side: BorderSide(color: primaryBlue),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text('common.cancel'.tr(),
                                                style: TextStyle(color: primaryBlue)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _canSubmit()
                                                ? () {
                                                    _saveToLocalStorage();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'evaluation.submittedSuccessfully'.tr())),
                                                    );
                                                  }
                                                : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _canSubmit() ? primaryBlue : Colors.grey,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text('common.submit'.tr(),
                                                style: const TextStyle(color: Colors.white)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        _totalMarksController.clear();
                                        _mainQuestionsController.clear();
                                        _requiredQuestionsController.clear();
                                        setState(() {
                                          _isFileUploaded = false;
                                          _allocatedMarks.clear();
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        side: BorderSide(color: primaryBlue),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text('common.cancel'.tr(),
                                          style: TextStyle(color: primaryBlue)),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton(
                                      onPressed: _canSubmit()
                                          ? () {
                                              _saveToLocalStorage();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'evaluation.submittedSuccessfully'.tr())),
                                              );
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _canSubmit() ? primaryBlue : Colors.grey,
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text('common.submit'.tr(),
                                          style: const TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_showAllocateMarksPopup)
            _AllocateMarksPopup(
              theme: theme,
              currentQuestionIndex: _currentQuestionIndex,
              mainQuestionsCount: int.tryParse(_mainQuestionsController.text) ?? 0,
              subQuestionMarkControllers: _subQuestionMarkControllers,
              allocatedMarks: _allocatedMarks,
              onAddSubQuestion: () {
                final currentQuestion = _currentQuestionIndex + 1;
                final newSubQuestionNumber = (_allocatedMarks['Q$currentQuestion']?.length ?? 0) + 1;
                
                // Add new sub-question to the allocated marks structure
                _allocatedMarks['Q$currentQuestion']['S$newSubQuestionNumber'] = '';
                
                // Update controllers
                _updateSubQuestionControllers();
                
                // Trigger rebuild
                if (mounted) {
                  setState(() {});
                }
              },
              onPrevious: () {
                _saveCurrentQuestionMarks();
                if (_currentQuestionIndex > 0) {
                  setState(() {
                    _currentQuestionIndex--;
                    _updateSubQuestionControllers();
                  });
                }
              },
              onNext: () {
                _saveCurrentQuestionMarks();
                final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;
                if (_currentQuestionIndex < mainQuestions - 1) {
                  setState(() {
                    _currentQuestionIndex++;
                    _updateSubQuestionControllers();
                  });
                }
              },
              onDone: () {
                _saveCurrentQuestionMarks();
                _saveToLocalStorage();
                setState(() => _showAllocateMarksPopup = false);
              },
              onClose: () => setState(() => _showAllocateMarksPopup = false),
              isDarkMode: isDarkMode,
              isMobile: isMobile,
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            prefixIcon: Icon(icon, color: primaryBlue),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryBlue, width: 2)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
          ),
        ),
      ],
    );
  }
}

class _AllocateMarksPopup extends StatelessWidget {
  const _AllocateMarksPopup({
    required this.theme,
    required this.currentQuestionIndex,
    required this.mainQuestionsCount,
    required this.subQuestionMarkControllers,
    required this.allocatedMarks,
    required this.onAddSubQuestion,
    required this.onPrevious,
    required this.onNext,
    required this.onDone,
    required this.onClose,
    required this.isDarkMode,
    required this.isMobile,
  });

  final ThemeData theme;
  final int currentQuestionIndex;
  final int mainQuestionsCount;
  final List<TextEditingController> subQuestionMarkControllers;
  final Map<String, dynamic> allocatedMarks;
  final VoidCallback onAddSubQuestion;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onDone;
  final VoidCallback onClose;
  final bool isDarkMode;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final currentQuestion = currentQuestionIndex + 1;
    final subQuestionsCount = allocatedMarks['Q$currentQuestion']?.length ?? 1;

    return Dialog(
      insetPadding:
          isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(20),
      child: Container(
        width: isMobile ? double.infinity : 600,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                      '${'evaluation.addMarks'.tr()} - ${'evaluation.question'.tr()} ${currentQuestionIndex + 1}',
                      style: (isMobile
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close,
                        color: isDarkMode ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sub-questions count text
            Text(
              '${'evaluation.enterMarksForSubQuestions'.tr()} (${'evaluation.total'.tr()}: $subQuestionsCount)',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
            ),
            
            const SizedBox(height: 24),
            
            // Sub-question input fields
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Sub-question fields
                    ...List.generate(subQuestionMarkControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: subQuestionMarkControllers[index],
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: '${'evaluation.subQuestion'.tr()} ${index + 1}',
                            labelStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                            hintText: 'evaluation.enterMarks'.tr(),
                            hintStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Color(0xFF2196F3),
                                    width: 2)),
                            prefixIcon: const Icon(Icons.arrow_right,
                                color: Color(0xFF2196F3)),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                          ),
                        ),
                      );
                    }),
                    
                    // Add sub-question button (centered under the input fields)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            onPressed: onAddSubQuestion,
                            icon: Icon(Icons.add, color: Color(0xFF2196F3)),
                            iconSize: isMobile ? 20 : 24,
                            tooltip: 'evaluation.addSubQuestion'.tr(),
                            padding: EdgeInsets.all(isMobile ? 8 : 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Navigation buttons
            if (isMobile)
              Column(
                children: [
                  if (currentQuestionIndex > 0)
                    OutlinedButton.icon(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF2196F3)),
                      label: Text('common.previous'.tr(),
                          style:
                              const TextStyle(color: Color(0xFF2196F3))),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Color(0xFF2196F3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  const SizedBox(height: 12),
                  if (currentQuestionIndex < mainQuestionsCount - 1)
                    ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text('common.next'.tr(),
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2196F3),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: onDone,
                      icon: const Icon(Icons.done, color: Colors.white),
                      label: Text('common.done'.tr(),
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2196F3),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentQuestionIndex > 0)
                    OutlinedButton.icon(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF2196F3)),
                      label: Text('common.previous'.tr(),
                          style:
                              const TextStyle(color: Color(0xFF2196F3))),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2196F3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    )
                  else
                    const SizedBox(width: 100),
                  if (currentQuestionIndex < mainQuestionsCount - 1)
                    ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text('common.next'.tr(),
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: onDone,
                      icon: const Icon(Icons.done, color: Colors.white),
                      label: Text('common.done'.tr(),
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}