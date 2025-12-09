import 'package:flutter/material.dart';
import '../models/event.dart';
import '../../../core/widgets/event_status_colors.dart';

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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Event Status',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...EventStatus.values.map((status) {
            final isSelected = status == currentStatus;
            final statusColor = EventStatusColors.getChipColor(status);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? EventStatusColors.getBackgroundColor(
                        status,
                        isDarkTheme: isDarkTheme,
                      )
                    : Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    onStatusChanged(status);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: statusColor, width: 2)
                          : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              status.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status.displayName,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? EventStatusColors.getTextColor(
                                          status,
                                          isDarkTheme: isDarkTheme,
                                        )
                                      : null,
                                ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: statusColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
