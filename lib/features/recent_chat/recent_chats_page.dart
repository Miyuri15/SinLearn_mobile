import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sinlearn_mobile/core/network/token_storage.dart';
import 'package:sinlearn_mobile/features/auth/auth_page.dart';
import '../settings/Settings_Teachers.dart';
import '../../main.dart' show MyApp;
import '../evaluation/learning_mode.dart';
import '../evaluation/evaluation_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/chat_service.dart';
import 'package:timeago/timeago.dart' as timeago;

// Model
class ChatEntry {
  static int _next = 0;
  ChatEntry({
    required this.title,
    required this.type,
    required this.createdAt,
    this.messageCount = 0,
    String? id,
  }) : id = id ?? (++_next).toString(); // monotonic id

  final String id;
  final String title;
  final ChatType type;
  final DateTime createdAt;
  int messageCount;
}

enum ChatType { learning, evaluation }

class RecentChatsDrawer extends StatefulWidget {
  const RecentChatsDrawer({super.key}); // fixed missing brace
  @override
  State<RecentChatsDrawer> createState() => _RecentChatsDrawerState();
}

class _RecentChatsDrawerState extends State<RecentChatsDrawer> {
  final List<ChatEntry> _all = [];
  String? _activeId;
  final _search = TextEditingController();
  final int _version = 0;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _seedInitialChats() async {
    // No-op: We don't want fake chats anymore.
  }

  Future<void> _loadChats() async {
    try {
      final sessions = await ChatService.listChatSessions();
      if (!mounted) return;

      setState(() {
        _all
          ..clear()
          ..addAll(sessions.map((s) => ChatEntry(
                id: s.id,
                title: s.title ??
                    (s.mode == 'learning'
                        ? 'recent_chats.new_learning'.tr()
                        : 'recent_chats.new_evaluation'.tr()),
                type: s.mode == 'learning'
                    ? ChatType.learning
                    : ChatType.evaluation,
                createdAt: DateTime.tryParse(s.createdAt) ?? DateTime.now(),
                messageCount: 0,
              )));

        // Sort by createdAt desc
        _all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (_all.isNotEmpty) {
          _activeId = _all.first.id;
        }
      });
    } catch (e) {
      print("Error loading chats: $e");
      // If API fails, maybe show empty or cached?
      // For now, let's not seed fake data to avoid confusion.
    }
  }

  Future<void> _saveChats() async {
    // We might not need to save to local storage if we are fully API driven,
    // but keeping it for offline support could be useful.
    // However, syncing is complex. Let's skip saving for now to rely on API.
  }

  Future<void> _create(ChatType type) async {
    try {
      final session = await ChatService.createChatSession(
        mode: type == ChatType.learning ? 'learning' : 'evaluation',
        title: type == ChatType.learning
            ? 'recent_chats.new_learning'.tr()
            : 'recent_chats.new_evaluation'.tr(),
      );

      final entry = ChatEntry(
        id: session.id,
        title: session.title ??
            (type == ChatType.learning
                ? 'recent_chats.new_learning'.tr()
                : 'recent_chats.new_evaluation'.tr()),
        type: type,
        createdAt: DateTime.now(),
      );

      setState(() {
        _all.insert(0, entry);
        _activeId = entry.id;
      });
      await _saveChats();

      if (!mounted) return;
      // Close the drawer first, then navigate to the appropriate interface
      Navigator.of(context).pop();
      if (type == ChatType.learning) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const LearningModePage()));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EvaluationTextPage(chatSessionId: entry.id)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
      }
    }
  }

  String _relative(DateTime time, BuildContext context) {
    return timeago.format(
      time,
      locale: context.locale.languageCode,
    );
  }

  List<ChatEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  // Refresh on build if storage changed (e.g., after returning to this drawer)
  void _checkVersionAndReload() async {
    final prefs = await SharedPreferences.getInstance();
    final latest = prefs.getInt('recent_chats_version') ?? 0;
    if (latest != _version) {
      await _loadChats();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkVersionAndReload());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Drawer(
      width: 360,
      // replace hard-coded white with themed surface color
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'recent_chats.header'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'close',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'recent_chats.search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  isDense: true,
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ActionButton(
                    icon: Icons.menu_book_outlined,
                    label: 'recent_chats.new_learning'.tr(),
                    onTap: () => _create(ChatType.learning),
                  ),
                  const SizedBox(height: 8),
                  _ActionButton(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'recent_chats.new_evaluation'.tr(),
                    onTap: () => _create(ChatType.evaluation),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // List
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                padding: const EdgeInsets.only(bottom: 8),
                itemBuilder: (ctx, i) {
                  final item = _filtered[i];
                  final active = item.id == _activeId;
                  return _RecentItem(
                    key: ValueKey(item.id), // stable key
                    entry: item,
                    timeLabel: _relative(item.createdAt, context),
                    active: active,
                    onTap: () => setState(() => _activeId = item.id),
                    isDark: isDark,
                  );
                },
              ),
            ),
            // Footer
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  _FooterButton(
                    icon: Icons.settings,
                    label: 'recent_chats.settings'.tr(),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingTeachers(
                            isDark:
                                Theme.of(context).brightness == Brightness.dark,
                            // connect settings toggle to app theme
                            toggleTheme: (v) =>
                                MyApp.of(context).toggleTheme(v),
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  _FooterButton(
                    icon: Icons.logout,
                    label: 'recent_chats.logout'.tr(),
                    onTap: () async {
                      await TokenStorage.clear();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthPage(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white10 : Colors.black.withOpacity(.04);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({
    super.key,
    required this.entry,
    required this.timeLabel,
    required this.active,
    required this.onTap,
    required this.isDark,
  });
  final ChatEntry entry;
  final String timeLabel;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final iconData = entry.type == ChatType.learning
        ? Icons.menu_book_outlined
        : Icons.assignment_turned_in_outlined;
    final iconColor =
        entry.type == ChatType.learning ? Colors.blue : Colors.green;

    final msg = entry.messageCount == 0
        ? 'recent_chats.messages_zero'.tr()
        : 'recent_chats.messages'.tr(args: [entry.messageCount.toString()]);

    final tile = ListTile(
      dense: true,
      leading: Icon(iconData, size: 20, color: iconColor), // only icon colored
      title: Text(
        entry.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg, style: const TextStyle(fontSize: 12)),
          Text(timeLabel, style: const TextStyle(fontSize: 12)),
        ],
      ),
      onTap: () {
        onTap();
        // navigate to interface for this chat type
        Navigator.of(context).pop();
        if (entry.type == ChatType.learning) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LearningModePage()));
        } else {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EvaluationTextPage(chatSessionId: entry.id)));
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    if (!active) {
      return Padding(
        key: key,
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
        child: tile,
      );
    }
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue, width: 1.2),
        ),
        child: tile,
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
