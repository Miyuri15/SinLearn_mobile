import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../features/evaluation/teachers_rubric_sidebar.dart';
import '../features/syllabus/syllabus_page.dart';
import '../features/question_paper/question_paper_page.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;
  final VoidCallback onMenuPressed;
  final VoidCallback onRightIconPressed;
  final VoidCallback onAddPressed;
  final VoidCallback? onRubricApplied;
  final String? chatSessionId;
  final bool enableSidebars;

  const MainAppBar({
    super.key,
    required this.selectedIndex,
    required this.onSegmentSelected,
    required this.onMenuPressed,
    required this.onRightIconPressed,
    required this.onAddPressed,
    this.onRubricApplied,
    this.chatSessionId,
    this.enableSidebars = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
        elevation: 0,
        color: theme.colorScheme.surface, // was Colors.white
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // was Colors.white
            border:
                Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // LEFT MENU ICON -> Recent Chats
                Builder(
                  builder: (ctx) {
                    return IconButton(
                      icon: Icon(Icons.menu,
                          size: 24, color: theme.colorScheme.onSurface),
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
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5), // was 0xFFF7F9FC
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

                // TEACHERS RUBRIC -> right-side sidebar
                // show rubric icon only in Evaluation mode (selectedIndex == 1)
                if (enableSidebars && selectedIndex == 1)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Tooltip(
                      message: 'question_paper.select_rubric_tooltip'.tr(),
                      waitDuration: const Duration(milliseconds: 250),
                      child: IconButton(
                        icon: Icon(Icons.document_scanner,
                            size: 20, color: theme.colorScheme.onSurface),
                        padding: const EdgeInsets.all(8),
                        splashRadius: 20,
                        onPressed: () => showTeachersRubricSidebar(
                          context,
                          onRubricApplied: onRubricApplied,
                          chatSessionId: chatSessionId,
                        ),
                      ),
                    ),
                  ),

                // BOOK ICON -> Syllabus (sidebar)
                if (enableSidebars) ...[
                  Builder(
                    builder: (ctx) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Tooltip(
                          message: 'syllabus.upload_title'.tr(),
                          waitDuration: const Duration(milliseconds: 250),
                          child: IconButton(
                            icon: Icon(Icons.book,
                                size: 20, color: theme.colorScheme.onSurface),
                            padding: const EdgeInsets.all(8),
                            splashRadius: 20,
                            onPressed: () => showSyllabusSidebar(
                              ctx,
                              chatSessionId: chatSessionId,
                            ), // opens as right panel
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (ctx) {
                      return Tooltip(
                        message: 'question_paper.upload_title'.tr(),
                        waitDuration: const Duration(milliseconds: 250),
                        child: IconButton(
                          icon: Icon(Icons.add,
                              size: 22, color: theme.colorScheme.onSurface),
                          padding: const EdgeInsets.all(8),
                          splashRadius: 20,
                          onPressed: () => showQuestionPaperSidebar(
                            ctx,
                            chatSessionId: chatSessionId,
                          ), // opens as right panel
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ));
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
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.cardColor : Colors.transparent, // was white
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  if (theme.brightness == Brightness.light)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Icon(icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.onSurface
                : theme.iconTheme.color),
      ),
    );
  }
}
