import 'package:flutter/material.dart';

class EvaluationHeader extends StatelessWidget implements PreferredSizeWidget {
  const EvaluationHeader({
    super.key,
    this.title = 'Recent Chats',
    this.onClose,
    this.onNewLearning,
    this.onNewEvaluation,
  });

  final String title;
  final VoidCallback? onClose;
  final VoidCallback? onNewLearning;
  final VoidCallback? onNewEvaluation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87, size: 20),
                  onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                )
              ],
            ),

            const SizedBox(height: 12),

  
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                hintText: 'Search chats...',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                filled: true,
                fillColor: Colors.grey[100],
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onNewLearning,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_outlined, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'New Learning Chat',
                          style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onNewEvaluation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, color: Colors.green[700], size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'New Evaluation Chat',
                          style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(180);
}
