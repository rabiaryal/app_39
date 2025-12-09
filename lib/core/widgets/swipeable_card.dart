import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'snackbar.dart';

/// Enhanced swipeable card with:
/// - Swipe right: Complete/Mark done (green)
/// - Swipe left: Delete (red)
/// - Undo functionality
/// - Visual feedback while swiping
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final bool showCompleteAction;
  final String itemName;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onComplete,
    this.onDelete,
    this.showCompleteAction = true,
    this.itemName = 'Item',
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left to delete
          return await _showDeleteConfirmation(context);
        } else if (direction == DismissDirection.startToEnd &&
            widget.showCompleteAction) {
          // Swipe right to complete
          HapticFeedback.mediumImpact();
          widget.onComplete?.call();
          _showUndoSnackbar(context, 'completed');
          return false; // Don't actually dismiss
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          HapticFeedback.heavyImpact();
          widget.onDelete?.call();
        }
      },
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.green,
        icon: Icons.check_circle_rounded,
        label: 'Complete',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete_rounded,
        label: 'Delete',
      ),
      child: widget.child,
    );
  }

  Widget _buildSwipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${widget.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUndoSnackbar(BuildContext context, String action) {
    AppSnackBar.showSuccess(context, '${widget.itemName} marked as $action');
  }
}
