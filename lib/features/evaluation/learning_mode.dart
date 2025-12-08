import 'package:flutter/material.dart';
import 'evaluation_text.dart';
import 'heder.dart';

class LearningModePage extends StatefulWidget {
  const LearningModePage({super.key});

  @override
  State<LearningModePage> createState() => _LearningModePageState();
}

class _LearningModePageState extends State<LearningModePage> {
  int _modeIndex = 0;
  String _responseLevel = 'Grades 9-11';
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isRecording = false;
  int _selectedChatIndex = 0;
  List<Map<String, dynamic>> _chatList = [
    {'title': 'New Learning Chat', 'subtitle': '0 messages • less than a minute ago', 'icon': Icons.menu_book_outlined, 'type': 'learning'},
    {'title': 'New Evaluation Chat', 'subtitle': '1 messages • 33 minutes ago', 'icon': Icons.assignment_turned_in_outlined, 'type': 'evaluation'},
    {'title': 'New Learning Chat', 'subtitle': '0 messages • about 1 hour ago', 'icon': Icons.menu_book_outlined, 'type': 'learning'},
  ];

  void _addNewChat(String type) {
    setState(() {
      _chatList.insert(0, {
        'title': type == 'learning' ? 'New Learning Chat' : 'New Evaluation Chat',
        'subtitle': '0 messages • just now',
        'icon': type == 'learning' ? Icons.menu_book_outlined : Icons.assignment_turned_in_outlined,
        'type': type,
      });
      _selectedChatIndex = 0; // Select the newly created chat
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isWide ? null : AppBar(title: const Text('Learning')),
      body: Stack(
        children: [
          Row(
            children: [
              if (isWide) _Sidebar(
                theme: theme,
                searchController: _searchController,
                chatList: _chatList,
                selectedChatIndex: _selectedChatIndex,
                onChatSelected: (index) => setState(() => _selectedChatIndex = index),
                onNewLearning: () => _addNewChat('learning'),
                onNewEvaluation: () => _addNewChat('evaluation'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SegmentButton(
                                  selected: _modeIndex == 0,
                                  icon: Icons.menu_book_outlined,
                                  label: 'Learning Mode',
                                  onTap: () => setState(() => _modeIndex = 0),
                                ),
                                _SegmentButton(
                                  selected: _modeIndex == 1,
                                  icon: Icons.assignment_turned_in_outlined,
                                  label: 'Evaluation Mode',
                                  onTap: () {
                                    // Navigate to the Evaluation (text) page
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const EvaluationTextPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.book_outlined, size: 18),
                            label: const Text('Syllabus'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(1000, 80, 0, 0),
                                items: const [
                                  PopupMenuItem(value: 'question', child: Text('Question Paper')),
                                  PopupMenuItem(value: 'rubric', child: Text('Rubric')),
                                ],
                              ).then((value) {
                                if (value == 'question') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Question Paper selected')),
                                  );
                                } else if (value == 'rubric') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Rubric selected')),
                                  );
                                }
                              });
                            },
                            tooltip: 'New',
                            icon: const Icon(Icons.add, color: Colors.black, size: 24),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const Expanded(child: _EmptyChatView()),
                    const Divider(height: 1),
                    _InputBar(
                      controller: _inputController,
                      responseLevel: _responseLevel,
                      onResponseLevelChanged: (v) => setState(() => _responseLevel = v),
                      onVoicePressed: () => setState(() => _isRecording = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isRecording)
            RecordingOverlay(
              onCancel: () => setState(() => _isRecording = false),
              onStop: () {
                setState(() => _isRecording = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recording stopped')),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.selected, required this.label, required this.onTap, this.icon});
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
   
    final isLearningMode = icon == Icons.menu_book_outlined;
    final selectedColor = isLearningMode ? Colors.green[700] : Colors.green[700];
    final backgroundColor = isLearningMode 
        ? Colors.green.withOpacity(0.10) 
        : Colors.green.withOpacity(0.10);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? backgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? selectedColor : theme.iconTheme.color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? selectedColor : theme.textTheme.bodyMedium?.color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.theme,
    required this.searchController,
    required this.chatList,
    required this.selectedChatIndex,
    required this.onChatSelected,
    required this.onNewLearning,
    required this.onNewEvaluation,
  });
  final ThemeData theme;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> chatList;
  final int selectedChatIndex;
  final ValueChanged<int> onChatSelected;
  final VoidCallback onNewLearning;
  final VoidCallback onNewEvaluation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EvaluationHeader(
            onNewLearning: onNewLearning,
            onNewEvaluation: onNewEvaluation,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: chatList.length,
                itemBuilder: (context, index) => _ChatListItem(
                  title: chatList[index]['title'],
                  subtitle: chatList[index]['subtitle'],
                  icon: chatList[index]['icon'],
                  isSelected: index == selectedChatIndex,
                  onTap: () => onChatSelected(index),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.settings, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text('Settings', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                const Spacer(),
                Icon(Icons.logout, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text('Logout', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700], size: 20),
        title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: Colors.blue.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Start your conversation in Sinhala', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Type a question or use voice input', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.responseLevel, required this.onResponseLevelChanged, this.onVoicePressed});
  final TextEditingController controller;
  final String responseLevel;
  final ValueChanged<String> onResponseLevelChanged;
  final VoidCallback? onVoicePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            // response level pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Text('Response Level', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: responseLevel,
                    underline: const SizedBox(),
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'Grades 6-8', child: Text('Grades 6-8')),
                      DropdownMenuItem(value: 'Grades 9-11', child: Text('Grades 9-11')),
                      DropdownMenuItem(value: 'Grades 12+', child: Text('Grades 12+')),
                    ],
                    onChanged: (v) {
                      if (v != null) onResponseLevelChanged(v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          hintText: 'Ask a question...',
                          hintStyle: TextStyle(color: Colors.black45),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Attach file',
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file, color: Colors.black54),
                    ),
                    IconButton(
                      tooltip: 'Voice input',
                      onPressed: onVoicePressed ?? () {},
                      icon: const Icon(Icons.mic_none, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 52,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Icon(Icons.send_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
