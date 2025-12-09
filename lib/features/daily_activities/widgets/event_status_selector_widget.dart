import 'package:flutter/material.dart';
import '../models/event.dart';
import '../../../core/widgets/event_status_colors.dart';
import '../../../core/widgets/app_text_style.dart';

class EventStatusSelector extends StatelessWidget {
  final EventStatus currentStatus;
  final Function(EventStatus) onStatusChanged;

  const EventStatusSelector({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.label_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text('Change Status', style: AppTextStyles.of(context).headline3),
            ],
          ),
          const SizedBox(height: 20),

          // Status options
          ...EventStatus.values.map((status) {
            final isSelected = status == currentStatus;
            final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  onStatusChanged(status);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EventStatusColors.getBackgroundColor(
                            status,
                            isDarkTheme: isDarkTheme,
                          )
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? EventStatusColors.getChipColor(status)
                          : Theme.of(context).dividerColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EventStatusColors.getChipColor(status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.displayName,
                              style: AppTextStyles.of(context).body1.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getStatusDescription(status),
                              style: AppTextStyles.of(context).caption.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: EventStatusColors.getChipColor(status),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Cancel', style: AppTextStyles.of(context).button),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(EventStatus status) {
    switch (status) {
      case EventStatus.notStarted:
        return 'Ready to begin when you are';
      case EventStatus.ongoing:
        return 'Currently working on this';
      case EventStatus.completed:
        return 'Completed and finished';
    }
  }
}
