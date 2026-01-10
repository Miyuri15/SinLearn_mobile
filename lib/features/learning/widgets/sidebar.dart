import 'package:flutter/material.dart';
import '../../recent_chat/recent_chats_page.dart';

/// Sidebar widget for wide screen layouts.
///
/// Displays the recent chats drawer as a persistent sidebar
/// when screen width is >= 900px.
class LearningModeSidebar extends StatelessWidget {
  const LearningModeSidebar({
    super.key,
    required this.theme,
    required this.searchController,
  });

  final ThemeData theme;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return const RecentChatsDrawer();
  }
}
