import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import 'dart:convert';

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
  
  bool _isDataSaved = false;
  Map<String, dynamic> _allocatedMarks = {};
  bool _showAllocateMarksPopup = false;
  int _currentQuestionIndex = 0;
  List<TextEditingController> _subQuestionMarkControllers = [];

  static const Color primaryBlue = Color(0xFF2196F3);
  static const String _storageKey = 'evaluation_data';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    
    // Add listeners to validate required questions and trigger rebuild
    _mainQuestionsController.addListener(() {
      _validateRequiredQuestions();
      setState(() {}); // Trigger rebuild when main questions change
    });
    _requiredQuestionsController.addListener(() {
      _validateRequiredQuestions();
      setState(() {}); // Trigger rebuild when required questions change
    });
    _totalMarksController.addListener(() {
      setState(() {}); // Trigger rebuild when total marks change
    });
  }

  void _validateRequiredQuestions() {
    if (_mainQuestionsController.text.isNotEmpty && 
        _requiredQuestionsController.text.isNotEmpty) {
      final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;
      final requiredQuestions = int.tryParse(_requiredQuestionsController.text) ?? 0;
      
      if (requiredQuestions > mainQuestions && mainQuestions > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('evaluation.requiredQuestionsExceed'.tr()),
              backgroundColor: Colors.red,
            ),
          );
          // Update the controller value
          _requiredQuestionsController.text = mainQuestions.toString();
          // No need to call setState here as the listener will trigger it
        });
      }
    }
  }

  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);
    
    if (savedData != null) {
      try {
        final Map<String, dynamic> data = json.decode(savedData);
        
        setState(() {
          _totalMarksController.text = data['totalMarks']?.toString() ?? '';
          _mainQuestionsController.text = data['mainQuestions']?.toString() ?? '';
          _requiredQuestionsController.text = data['requiredQuestions']?.toString() ?? '';
          
          // Fix for type conversion issue
          if (data['allocatedMarks'] != null) {
            _allocatedMarks = Map<String, dynamic>.from(data['allocatedMarks']);
          }
          
          _isDataSaved = true;
        });
      } catch (e) {
        print('Error loading saved data: $e');
      }
    }
  }

  @override
  void dispose() {
    _totalMarksController.dispose();
    _mainQuestionsController.dispose();
    _requiredQuestionsController.dispose();
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
        final questionKey = 'Q$i';
        if (!_allocatedMarks.containsKey(questionKey)) {
          _allocatedMarks[questionKey] = <String, dynamic>{};
          // Start with one default sub-question
          _allocatedMarks[questionKey]['S1'] = '';
        }
      }
      _updateSubQuestionControllers();
    }
  }

  void _updateSubQuestionControllers() {
    _disposeSubQuestionControllers();
    final currentQuestion = _currentQuestionIndex + 1;
    final questionKey = 'Q$currentQuestion';
    
    // Ensure the question exists in allocated marks
    if (!_allocatedMarks.containsKey(questionKey)) {
      _allocatedMarks[questionKey] = <String, dynamic>{'S1': ''};
    }
    
    final subQuestions = _allocatedMarks[questionKey]!.length;

    for (int i = 1; i <= subQuestions; i++) {
      final subQuestionKey = 'S$i';
      final markValue = _allocatedMarks[questionKey]?[subQuestionKey]?.toString() ?? '';
      final controller = TextEditingController(text: markValue);
      _subQuestionMarkControllers.add(controller);
    }
  }

  void _saveCurrentQuestionMarks() {
    final currentQuestion = _currentQuestionIndex + 1;
    final questionKey = 'Q$currentQuestion';
    
    if (!_allocatedMarks.containsKey(questionKey)) {
      _allocatedMarks[questionKey] = <String, dynamic>{};
    }
    
    final subQuestions = _subQuestionMarkControllers.length;

    for (int i = 1; i <= subQuestions; i++) {
      final subQuestionKey = 'S$i';
      if (i - 1 < _subQuestionMarkControllers.length) {
        _allocatedMarks[questionKey][subQuestionKey] = _subQuestionMarkControllers[i - 1].text;
      }
    }
  }

  void _showAllocateMarksDialog() {
    final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;
    final requiredQuestions = int.tryParse(_requiredQuestionsController.text) ?? 0;

    if (mainQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('evaluation.validNumbersRequired'.tr())),
      );
      return;
    }

    if (requiredQuestions > mainQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('evaluation.requiredQuestionsExceed'.tr()),
          backgroundColor: Colors.red,
        ),
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
              final questionData = question.value as Map<String, dynamic>;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${question.key}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...questionData.entries.map((subQuestion) {
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

  bool _canAllocateMarks() {
    final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;
    final requiredQuestions = int.tryParse(_requiredQuestionsController.text) ?? 0;
    
    return _totalMarksController.text.isNotEmpty &&
        _mainQuestionsController.text.isNotEmpty &&
        _requiredQuestionsController.text.isNotEmpty &&
        mainQuestions > 0 &&
        requiredQuestions <= mainQuestions;
  }

  bool _canSubmit() {
    final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;
    final requiredQuestions = int.tryParse(_requiredQuestionsController.text) ?? 0;
    
    // Check if all sub-questions have marks allocated
    bool allSubQuestionsHaveMarks = true;
    if (_allocatedMarks.isNotEmpty) {
      for (int i = 1; i <= mainQuestions; i++) {
        final questionKey = 'Q$i';
        if (_allocatedMarks.containsKey(questionKey)) {
          final subQuestions = _allocatedMarks[questionKey] as Map<String, dynamic>;
          for (var subQuestion in subQuestions.values) {
            if (subQuestion.toString().isEmpty) {
              allSubQuestionsHaveMarks = false;
              break;
            }
          }
        } else {
          allSubQuestionsHaveMarks = false;
        }
        if (!allSubQuestionsHaveMarks) break;
      }
    }
    
    return _totalMarksController.text.isNotEmpty &&
        _mainQuestionsController.text.isNotEmpty &&
        _requiredQuestionsController.text.isNotEmpty &&
        requiredQuestions <= mainQuestions &&
        _allocatedMarks.isNotEmpty &&
        allSubQuestionsHaveMarks;
  }

  Future<void> _saveToLocalStorage() async {
    if (!_canSubmit()) return;
    
    final evaluationData = {
      'totalMarks': _totalMarksController.text,
      'mainQuestions': _mainQuestionsController.text,
      'requiredQuestions': _requiredQuestionsController.text,
      'allocatedMarks': _allocatedMarks,
      'savedAt': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(evaluationData));
    await prefs.setBool('paper_config_confirmed', true);
    
    setState(() {
      _isDataSaved = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('evaluation.dataSaved'.tr())),
    );
  }

  Future<void> _removeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    
    setState(() {
      _totalMarksController.clear();
      _mainQuestionsController.clear();
      _requiredQuestionsController.clear();
      _allocatedMarks.clear();
      _isDataSaved = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('evaluation.dataRemoved'.tr())),
    );
  }

  void _resetForm() {
    setState(() {
      _totalMarksController.clear();
      _mainQuestionsController.clear();
      _requiredQuestionsController.clear();
      _allocatedMarks.clear();
      _isDataSaved = false;
    });
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
                                  const Spacer(),
                                  if (_isDataSaved)
                                    IconButton(
                                      onPressed: _removeData,
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'evaluation.removeData'.tr(),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

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
                                      onPressed: _canAllocateMarks() ? _showAllocateMarksDialog : null,
                                      icon: const Icon(Icons.add_chart, color: Colors.white),
                                      label: Text('evaluation.allocateMarks'.tr(),
                                          style: const TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _canAllocateMarks() ? primaryBlue : Colors.grey,
                                        minimumSize: const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _isDataSaved ? _showViewMarksDialog : null,
                                      icon: Icon(Icons.edit, color: _isDataSaved ? primaryBlue : Colors.grey),
                                      label: Text('evaluation.viewEditMarks'.tr(),
                                          style: TextStyle(color: _isDataSaved ? primaryBlue : Colors.grey)),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        side: BorderSide(color: _isDataSaved ? primaryBlue : Colors.grey),
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
                                        onPressed: _canAllocateMarks() ? _showAllocateMarksDialog : null,
                                        icon: const Icon(Icons.add_chart, color: Colors.white),
                                        label: Text('evaluation.allocateMarks'.tr(),
                                            style: const TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _canAllocateMarks() ? primaryBlue : Colors.grey,
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
                                        onPressed: _isDataSaved ? _showViewMarksDialog : null,
                                        icon: Icon(Icons.visibility, color: _isDataSaved ? primaryBlue : Colors.grey),
                                        label: Text('evaluation.viewEditMarks'.tr(),
                                            style: TextStyle(color: _isDataSaved ? primaryBlue : Colors.grey)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: BorderSide(color: _isDataSaved ? primaryBlue : Colors.grey),
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
                                            onPressed: _resetForm,
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
                                            onPressed: _canSubmit() ? _saveToLocalStorage : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _canSubmit() ? primaryBlue : Colors.grey,
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
                                      onPressed: _resetForm,
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
                                      onPressed: _canSubmit() ? _saveToLocalStorage : null,
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
            AllocateMarksPopup(
              theme: theme,
              currentQuestionIndex: _currentQuestionIndex,
              mainQuestionsCount: int.tryParse(_mainQuestionsController.text) ?? 0,
              subQuestionMarkControllers: _subQuestionMarkControllers,
              allocatedMarks: _allocatedMarks,
              onAddSubQuestion: () {
                final currentQuestion = _currentQuestionIndex + 1;
                final questionKey = 'Q$currentQuestion';
                
                if (!_allocatedMarks.containsKey(questionKey)) {
                  _allocatedMarks[questionKey] = <String, dynamic>{};
                }
                
                final newSubQuestionNumber = (_allocatedMarks[questionKey]!.length) + 1;
                
                // Add new sub-question to the allocated marks structure
                _allocatedMarks[questionKey]['S$newSubQuestionNumber'] = '';
                
                // Create a new controller for the new sub-question
                _subQuestionMarkControllers.add(TextEditingController());
                
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
                setState(() => _showAllocateMarksPopup = false);
                
                // Check if all sub-questions have marks
                bool allHaveMarks = true;
                final mainQuestions = int.tryParse(_mainQuestionsController.text) ?? 0;
                for (int i = 1; i <= mainQuestions; i++) {
                  final questionKey = 'Q$i';
                  if (_allocatedMarks.containsKey(questionKey)) {
                    final subQuestions = _allocatedMarks[questionKey] as Map<String, dynamic>;
                    for (var subQuestion in subQuestions.values) {
                      if (subQuestion.toString().isEmpty) {
                        allHaveMarks = false;
                        break;
                      }
                    }
                  }
                  if (!allHaveMarks) break;
                }
                
                if (!allHaveMarks) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('evaluation.fillAllSubQuestionMarks'.tr()),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
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

class AllocateMarksPopup extends StatefulWidget {
  const AllocateMarksPopup({
    Key? key,
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
  }) : super(key: key);

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
  State<AllocateMarksPopup> createState() => _AllocateMarksPopupState();
}

class _AllocateMarksPopupState extends State<AllocateMarksPopup> {
  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.currentQuestionIndex + 1;
    final questionKey = 'Q$currentQuestion';
    final subQuestionsCount = widget.allocatedMarks.containsKey(questionKey) 
        ? widget.allocatedMarks[questionKey]!.length 
        : 1;

    return Dialog(
      insetPadding:
          widget.isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(20),
      child: Container(
        width: widget.isMobile ? double.infinity : 600,
        padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
        decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
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
                      '${'evaluation.addMarks'.tr()} - ${'evaluation.question'.tr()} ${widget.currentQuestionIndex + 1}',
                      style: (widget.isMobile
                              ? widget.theme.textTheme.titleLarge
                              : widget.theme.textTheme.headlineSmall)
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.white : Colors.black),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close,
                        color: widget.isDarkMode ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              '${'evaluation.enterMarksForSubQuestions'.tr()} (${'evaluation.total'.tr()}: $subQuestionsCount)',
              style: widget.theme.textTheme.bodyLarge
                  ?.copyWith(color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700]),
            ),
            
            const SizedBox(height: 24),
            
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...List.generate(widget.subQuestionMarkControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: widget.subQuestionMarkControllers[index],
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: '${'evaluation.subQuestion'.tr()} ${index + 1}',
                            labelStyle: TextStyle(
                                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                            hintText: 'evaluation.enterMarks'.tr(),
                            hintStyle: TextStyle(
                                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: widget.isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: widget.isDarkMode
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
                            fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[50],
                          ),
                        ),
                      );
                    }),
                    
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
                            onPressed: widget.onAddSubQuestion,
                            icon: Icon(Icons.add, color: Color(0xFF2196F3)),
                            iconSize: widget.isMobile ? 20 : 24,
                            tooltip: 'evaluation.addSubQuestion'.tr(),
                            padding: EdgeInsets.all(widget.isMobile ? 8 : 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (widget.isMobile)
              Column(
                children: [
                  if (widget.currentQuestionIndex > 0)
                    OutlinedButton.icon(
                      onPressed: widget.onPrevious,
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
                  if (widget.currentQuestionIndex < widget.mainQuestionsCount - 1)
                    ElevatedButton.icon(
                      onPressed: widget.onNext,
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
                      onPressed: widget.onDone,
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
                  if (widget.currentQuestionIndex > 0)
                    OutlinedButton.icon(
                      onPressed: widget.onPrevious,
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
                  if (widget.currentQuestionIndex < widget.mainQuestionsCount - 1)
                    ElevatedButton.icon(
                      onPressed: widget.onNext,
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
                      onPressed: widget.onDone,
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