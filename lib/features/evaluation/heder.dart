import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EvaluationHeader extends StatelessWidget implements PreferredSizeWidget {
  const EvaluationHeader({
    super.key,
    this.title = 'Recent Chats',
    this.onClose,
  });

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Primary accent used in images
    const primaryBlue = Color(0xFF1E63FF);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // left menu
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),

                // centered segmented pill with two icon tabs (book / checklist)
                Expanded(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // left pill (book)
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Icon(Icons.menu_book_outlined, color: primaryBlue),
                              ),
                            ),
                          ),
                          // slight gap
                          const SizedBox(width: 8),
                          // right pill (checklist)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Icon(Icons.checklist_rtl_outlined, color: Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // right icons (document, book, plus)
                IconButton(icon: const Icon(Icons.insert_drive_file_outlined), onPressed: () {}),
                IconButton(icon: const Icon(Icons.book_outlined), onPressed: () {}),
                IconButton(icon: const Icon(Icons.add), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 12),

            // search row below header (keeps the same behavior but lighter)
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'recent_chats.search_hint'.tr(),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(160);
}
