import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart'; //  GoRouter

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

//  Wrapper Class
class RecentChatsPage extends StatelessWidget {
  const RecentChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Theme background
      // AppBar
      body: SafeArea(
        child: const RecentChatsDrawer(), // Drawer
      ),
    );
  }
}


class RecentChatsDrawer extends StatefulWidget {
  const RecentChatsDrawer({super.key});
  @override
  State<RecentChatsDrawer> createState() => _RecentChatsDrawerState();
}

class _RecentChatsDrawerState extends State<RecentChatsDrawer> {
  final List<ChatEntry> _all = [];
  String? _activeId;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Seed example data
    final now = DateTime.now();
    _all.addAll([
      ChatEntry(
        title: 'recent_chats.new_learning'.tr(),
        type: ChatType.learning,
        createdAt: now.subtract(const Duration(minutes: 0)),
      ),
      ChatEntry(
        title: 'recent_chats.new_learning'.tr(),
        type: ChatType.learning,
        createdAt: now.subtract(const Duration(minutes: 60)),
        messageCount: 1,
      ),
      ChatEntry(
        title: 'recent_chats.new_evaluation'.tr(),
        type: ChatType.evaluation,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);
    _activeId = _all.first.id;
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _create(ChatType type) {
    setState(() {
      final entry = ChatEntry(
        title: type == ChatType.learning
            ? 'recent_chats.new_learning'.tr()
            : 'recent_chats.new_evaluation'.tr(),
        type: type,
        createdAt: DateTime.now(),
      );
      _all.insert(0, entry);
      _activeId = entry.id;
    });
  }

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'recent_chats.less_minute'.tr();
    if (diff.inMinutes == 1) return 'recent_chats.minute_ago'.tr();
    if (diff.inMinutes < 60) {
      return 'recent_chats.minutes_ago'
          .tr(args: [diff.inMinutes.toString()]);
    }
    if (diff.inHours == 1) return 'recent_chats.hour_ago'.tr();
    return 'recent_chats.hours_ago'.tr(args: [diff.inHours.toString()]);
  }

  List<ChatEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where((c) => c.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    //  Theme Context
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onBackground;
    final subTextColor = theme.colorScheme.secondary;
    final primaryColor = theme.colorScheme.primary;


    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            color: cardColor, // Theme card color
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'recent_chats.header'.tr(),
                    style: theme.textTheme.titleMedium!.copyWith(color: textColor),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor), // Theme text color
                  onPressed: () => context.pop(), //  go_router
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
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                fillColor: cardColor, // Input background
                filled: true,
                hintText: 'recent_chats.search_hint'.tr(),
                hintStyle: TextStyle(color: subTextColor),
                prefixIcon: Icon(Icons.search, color: subTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
                  timeLabel: _relative(item.createdAt),
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
              color: cardColor, // Footer background
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
                  //  Settings page
                  onTap: () => context.go('/settings_teachers'),
                ),
                const Spacer(),
                _FooterButton(
                  icon: Icons.logout,
                  label: 'recent_chats.logout'.tr(),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onBackground;
    final primaryColor = theme.colorScheme.primary;

    final bg = isDark ? Colors.white10 : Colors.black.withOpacity(.04);
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: primaryColor), // Primary color for icons
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: textColor))),
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
    final textColor = Theme.of(context).colorScheme.onBackground;
    final subTextColor = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final iconData = entry.type == ChatType.learning
        ? Icons.menu_book_outlined
        : Icons.assignment_turned_in_outlined;
    final iconColor = entry.type == ChatType.learning ? primaryColor : Colors.green; // Use primary color for consistency

    final msg = entry.messageCount == 0
        ? 'recent_chats.messages_zero'.tr()
        : 'recent_chats.messages'.tr(args: [entry.messageCount.toString()]);

    final tile = ListTile(
      dense: true,
      leading: Icon(iconData, size: 20, color: iconColor), // only icon colored
      title: Text(
        entry.title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg, style: TextStyle(fontSize: 12, color: subTextColor)),
          Text(timeLabel, style: TextStyle(fontSize: 12, color: subTextColor)),
        ],
      ),
      onTap: onTap,
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
          // Active color should respect dark mode slightly
          color: isDark ? primaryColor.withOpacity(0.20) : primaryColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryColor, width: 1.2),
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
    final textColor = Theme.of(context).colorScheme.onBackground;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: textColor),
      label: Text(label, style: TextStyle(color: textColor)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

//*********************************************************************

/*
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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

  @override
  void initState() {
    super.initState();
    // Seed example data
    final now = DateTime.now();
    _all.addAll([
      ChatEntry(
        title: 'recent_chats.new_learning'.tr(),
        type: ChatType.learning,
        createdAt: now.subtract(const Duration(minutes: 0)),
      ),
      ChatEntry(
        title: 'recent_chats.new_learning'.tr(),
        type: ChatType.learning,
        createdAt: now.subtract(const Duration(minutes: 60)),
        messageCount: 1,
      ),
      ChatEntry(
        title: 'recent_chats.new_evaluation'.tr(),
        type: ChatType.evaluation,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);
    _activeId = _all.first.id;
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _create(ChatType type) {
    setState(() {
      final entry = ChatEntry(
        title: type == ChatType.learning
            ? 'recent_chats.new_learning'.tr()
            : 'recent_chats.new_evaluation'.tr(),
        type: type,
        createdAt: DateTime.now(),
      );
      _all.insert(0, entry);
      _activeId = entry.id;
    });
  }

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'recent_chats.less_minute'.tr();
    if (diff.inMinutes == 1) return 'recent_chats.minute_ago'.tr();
    if (diff.inMinutes < 60) {
      return 'recent_chats.minutes_ago'
          .tr(args: [diff.inMinutes.toString()]);
    }
    if (diff.inHours == 1) return 'recent_chats.hour_ago'.tr();
    return 'recent_chats.hours_ago'.tr(args: [diff.inHours.toString()]);
  }

  List<ChatEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where((c) => c.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      width: 360,
      backgroundColor: Colors.white, // force white background
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
            Divider(height: 1),
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
                    timeLabel: _relative(item.createdAt),
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
                    onTap: () {},
                  ),
                  const Spacer(),
                  _FooterButton(
                    icon: Icons.logout,
                    label: 'recent_chats.logout'.tr(),
                    onTap: () {},
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
    final iconColor = entry.type == ChatType.learning ? Colors.blue : Colors.green;

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
      onTap: onTap,
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
*/







