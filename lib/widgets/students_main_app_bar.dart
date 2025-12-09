import 'package:flutter/material.dart';
import '../features/evaluation/students_rubric_selection_screen.dart';
import '../features/recent_chat/recent_chats_page.dart';
import '../features/syllabus/syllabus_page.dart';
import '../features/question_paper/question_paper_page.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;
  final VoidCallback onMenuPressed;
  final VoidCallback onRightIconPressed;
  final VoidCallback onAddPressed;

  const MainAppBar({
    super.key,
    required this.selectedIndex,
    required this.onSegmentSelected,
    required this.onMenuPressed,
    required this.onRightIconPressed,
    required this.onAddPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 0,
      color: Colors.white,
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE6ECF2), width: 1),
          ),
        ),
        child: Row(
          children: [
            // LEFT MENU ICON
            Builder(
              builder: (ctx) {
                return IconButton(
                  icon: const Icon(Icons.menu, size: 24, color: Color(0xFF344054)),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  padding: const EdgeInsets.all(8),
                  splashRadius: 20,
                );
              },
            ),

            const SizedBox(width: 16),

            // SEGMENT BUTTONS (Book | Clipboard)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    icon: Icons.menu_book_outlined,
                    isSelected: selectedIndex == 0,
                    onTap: () => onSegmentSelected(0),
                  ),
                  _SegmentButton(
                    icon: Icons.assignment_turned_in_outlined,
                    isSelected: selectedIndex == 1,
                    onTap: () => onSegmentSelected(1),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // RUBRIC (students) -> right-side sidebar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F9FC),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: const EdgeInsets.all(8),
                splashRadius: 20,
                icon: const Icon(Icons.document_scanner, size: 20, color: Color(0xFF344054)),
                onPressed: () => showRubricSelectionSidebar(context),
              ),
            ),

            // BOOK ICON -> Syllabus (sidebar)
            Builder(
              builder: (ctx) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F9FC),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
                    splashRadius: 20,
                    icon: const Icon(Icons.book, size: 20, color: Color(0xFF344054)),
                    onPressed: () => showSyllabusSidebar(ctx), // opens as right panel
                  ),
                );
              },
            ),

            const SizedBox(width: 8),

            // ADD BUTTON -> Question Paper (sidebar)
            Builder(
              builder: (ctx) {
                return IconButton(
                  padding: const EdgeInsets.all(8),
                  splashRadius: 20,
                  icon: const Icon(Icons.add, size: 22, color: Color(0xFF344054)),
                  onPressed: () => showQuestionPaperSidebar(ctx), // opens as right panel
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.black : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}
