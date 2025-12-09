import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system.dart';
import 'app_text_style.dart';

/// Batch Operations Bar
/// Appears at bottom when items are selected
/// Provides bulk actions: Delete, Complete, Move, etc.
class BatchOperationsBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;
  final VoidCallback onCancel;
  final bool showCompleteAction;
  final bool showMoveAction;

  const BatchOperationsBar({
    super.key,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onCancel,
    this.onDelete,
    this.onComplete,
    this.onMove,
    this.showCompleteAction = true,
    this.showMoveAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection info and controls
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacingBase,
                vertical: AppDesignSystem.spacingMd,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onCancel();
                    },
                    tooltip: 'Cancel selection',
                  ),
                  SizedBox(width: AppDesignSystem.spacingSm),
                  Expanded(
                    child: Text(
                      '$selectedCount item${selectedCount != 1 ? 's' : ''} selected',
                      style: AppTextStyles.of(
                        context,
                      ).body1.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onSelectAll();
                    },
                    child: const Text('Select All'),
                  ),
                  SizedBox(width: AppDesignSystem.spacingXs),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onDeselectAll();
                    },
                    child: const Text('Deselect All'),
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDesignSystem.spacingBase,
                0,
                AppDesignSystem.spacingBase,
                AppDesignSystem.spacingBase,
              ),
              child: Row(
                children: [
                  if (showCompleteAction && onComplete != null) ...[
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.check_circle_rounded,
                        label: 'Complete',
                        color: AppDesignSystem.success,
                        onPressed: onComplete!,
                      ),
                    ),
                    SizedBox(width: AppDesignSystem.spacingSm),
                  ],
                  if (showMoveAction && onMove != null) ...[
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.drive_file_move_rounded,
                        label: 'Move',
                        color: AppDesignSystem.info,
                        onPressed: onMove!,
                      ),
                    ),
                    SizedBox(width: AppDesignSystem.spacingSm),
                  ],
                  if (onDelete != null)
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: AppDesignSystem.danger,
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          _showDeleteConfirmation(context);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacingBase,
          vertical: AppDesignSystem.spacingMd,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Items', style: AppTextStyles.of(context).headline3),
        content: Text(
          'Are you sure you want to delete $selectedCount item${selectedCount != 1 ? 's' : ''}? This action cannot be undone.',
          style: AppTextStyles.of(context).body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.of(context).button),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppDesignSystem.danger,
            ),
            child: Text(
              'Delete',
              style: AppTextStyles.of(context).button.copyWith(
                color: AppDesignSystem.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selection Mode Wrapper
/// Wraps a list item to add checkbox selection capability
class SelectableItem extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SelectableItem({
    super.key,
    required this.child,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppDesignSystem.animationFast,
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: AppDesignSystem.primaryBlue, width: 2)
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            child,
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedScale(
                  duration: AppDesignSystem.animationFast,
                  scale: isSelectionMode ? 1.0 : 0.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppDesignSystem.primaryBlue
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppDesignSystem.primaryBlue
                            : AppDesignSystem.gray300,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
