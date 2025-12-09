import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils.dart';
import 'app_text_style.dart';
import '../../features/daily_activities/models/event.dart';
import '../../features/notes/models/note.dart';

/// A unified card widget that provides consistent design across all features
class UnifiedCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final DateTime? date;
  final Color statusColor;
  final String statusText;
  final String? statusEmoji;
  final String? category;
  final String? amount; // For transactions
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStatusTap;
  final Widget? leading;
  final List<Widget>? trailing;
  final List<String>? tags;
  final bool isCompleted;
  final Color? cardColor;
  final double elevation;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const UnifiedCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.date,
    required this.statusColor,
    required this.statusText,
    this.statusEmoji,
    this.category,
    this.amount,
    this.onTap,
    this.onLongPress,
    this.onStatusTap,
    this.leading,
    this.trailing,
    this.tags,
    this.isCompleted = false,
    this.cardColor,
    this.elevation = 2,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final defaultCardColor = cardColor ?? Theme.of(context).cardColor;

    return Container(
      margin: margin,
      child: Card(
        elevation: elevation,
        color: defaultCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          onLongPress: onLongPress != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading widget (if provided)
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],

                    // Main content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Status Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTextStyles.of(context).subtitle1
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        color: isCompleted
                                            ? Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color
                                                  ?.withValues(alpha: 0.6)
                                            : null,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status Chip
                              GestureDetector(
                                onTap: onStatusTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (statusEmoji != null) ...[
                                        Text(
                                          statusEmoji!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Subtitle
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: AppTextStyles.of(context).body2.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],

                          // Description
                          if (description != null &&
                              description!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              description!,
                              style: AppTextStyles.of(context).body1.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Amount (for transactions)
                    if (amount != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        amount!,
                        style: AppTextStyles.of(context).subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: statusColor,
                        ),
                      ),
                    ],

                    // Trailing widgets
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      ...trailing!,
                    ],
                  ],
                ),

                // Bottom Row (Date, Category, Tags)
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Date
                    if (date != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateTimeUtils.formatDate(date!),
                        style: AppTextStyles.of(context).caption.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    // Category
                    if (category != null && category!.isNotEmpty) ...[
                      if (date != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category!,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),
                  ],
                ),

                // Tags
                if (tags != null && tags!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags!.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Specialized card for different entity types
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStatusChange;
  final double elevation;
  final Color? cardColor;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const EventCard({
    super.key,
    required this.event,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.elevation = 3,
    this.cardColor,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getEventStatusColor(event.status);
    final defaultCardColor = cardColor ?? Theme.of(context).cardColor;
    final canEditEvent = event.canEdit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: elevation,
        color: defaultCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: isSelectionMode
              ? () => onSelectionChanged?.call(!isSelected)
              : (canEditEvent && onEdit != null
                    ? () {
                        HapticFeedback.lightImpact();
                        onEdit!();
                      }
                    : null),
          onLongPress: isSelectionMode
              ? null
              : () => onSelectionChanged?.call(!isSelected),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Checkbox, Title ---- Status
                Row(
                  children: [
                    // Selection checkbox
                    if (isSelectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) =>
                            onSelectionChanged?.call(value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                    ],

                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: AppTextStyles.of(context).subtitle1
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Edit lock indicator
                          if (!canEditEvent && !isSelectionMode) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onStatusChange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event.status.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.status.displayName,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Line 2: Description
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: AppTextStyles.of(context).body1.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Line 3: Time period only (with larger font)
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Time period
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatTimePeriod(event.startTime, event.endTime),
                        style: AppTextStyles.of(context).body1.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),

                // Line 4: Category and Timer row (timer centered)
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Category (left side)
                    if (event.category != null && event.category!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.label,
                            size: 14,
                            color: statusColor.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              event.category!,
                              style: TextStyle(
                                color: statusColor.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Spacer to center timer
                    const Spacer(),

                    // Timer (centered)
                    _buildTimeCondition(context),

                    // Spacer to keep balance if no category
                    if (event.category == null || event.category!.isEmpty)
                      const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCondition(BuildContext context) {
    final now = DateTime.now();
    final eventStart = event.startTime;
    final eventEnd = event.endTime;

    // Calculate time difference
    final timeDifference = eventStart.difference(now);
    final isEventInFuture = timeDifference.inMinutes > 0;
    final isEventActive = event.status == EventStatus.ongoing;

    String timeText;
    Color timeColor;
    IconData timeIcon;

    if (isEventInFuture) {
      // Event hasn't started yet - show time remaining
      final hoursLeft = timeDifference.inHours;
      final minutesLeft = timeDifference.inMinutes % 60;

      if (hoursLeft >= 1) {
        timeText = '$hoursLeft ${hoursLeft == 1 ? 'hour' : 'hours'} left';
        timeColor = hoursLeft <= 2
            ? Colors.red
            : hoursLeft <= 4
            ? Colors.orange
            : Colors.blue;
      } else {
        timeText =
            '$minutesLeft ${minutesLeft == 1 ? 'minute' : 'minutes'} left';
        timeColor = minutesLeft <= 30 ? Colors.red : Colors.orange;
      }
      timeIcon = Icons.schedule;
    } else if (isEventActive && eventEnd != null) {
      // Event is active - show time elapsed and total duration
      final timeElapsed = now.difference(eventStart);
      final totalDuration = eventEnd.difference(eventStart);
      final hoursElapsed = timeElapsed.inHours;
      final minutesElapsed = timeElapsed.inMinutes % 60;
      final totalHours = totalDuration.inHours;
      final totalMinutes = totalDuration.inMinutes % 60;

      String elapsedText = hoursElapsed > 0
          ? '${hoursElapsed}h ${minutesElapsed}m'
          : '${minutesElapsed}m';
      String totalText = totalHours > 0
          ? '${totalHours}h ${totalMinutes}m'
          : '${totalMinutes}m';

      timeText = '$elapsedText / $totalText elapsed';
      timeColor = Colors.green;
      timeIcon = Icons.play_circle_filled;
    } else if (event.status == EventStatus.completed) {
      // Event is completed
      final actualDuration = eventEnd != null
          ? eventEnd.difference(eventStart)
          : const Duration(hours: 1); // Default duration for display

      final hours = actualDuration.inHours;
      final minutes = actualDuration.inMinutes % 60;

      timeText = hours > 0
          ? 'Completed in ${hours}h ${minutes}m'
          : 'Completed in ${minutes}m';
      timeColor = Colors.green;
      timeIcon = Icons.check_circle;
    } else {
      // Event has passed but not marked as done
      final timePassed = now.difference(eventStart);
      final hoursPassed = timePassed.inHours;
      final minutesPassed = timePassed.inMinutes % 60;

      if (hoursPassed >= 1) {
        timeText = '$hoursPassed ${hoursPassed == 1 ? 'hour' : 'hours'} ago';
      } else {
        timeText =
            '$minutesPassed ${minutesPassed == 1 ? 'minute' : 'minutes'} ago';
      }
      timeColor = Colors.grey;
      timeIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: timeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: timeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(timeIcon, size: 16, color: timeColor),
          const SizedBox(width: 6),
          Text(
            timeText,
            style: TextStyle(
              color: timeColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTimePeriod(DateTime startTime, DateTime? endTime) {
    // Helper function to format time as "4 AM" or "8:30 PM"
    String formatTime(DateTime time) {
      int hour = time.hour;
      String period = hour >= 12 ? 'PM' : 'AM';

      // Convert to 12-hour format
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour = hour - 12;
      }

      // Add minutes if not zero
      if (time.minute == 0) {
        return '$hour $period';
      } else {
        return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
      }
    }

    final startTimeStr = formatTime(startTime);

    // If no end time, it's an instant event
    if (endTime == null) {
      return '$startTimeStr (Instant)';
    }

    final endTimeStr = formatTime(endTime);
    final duration = endTime.difference(startTime);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    String durationText;
    if (hours > 0 && minutes > 0) {
      durationText =
          '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'min' : 'mins'}';
    } else if (hours > 0) {
      durationText = '$hours ${hours == 1 ? 'hour' : 'hours'}';
    } else {
      durationText = '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }

    return '$startTimeStr - $endTimeStr ($durationText)';
  }

  static Color _getEventStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.completed:
        return Colors.green;
      case EventStatus.ongoing:
        return Colors.blue;
      case EventStatus.notStarted:
        return Colors.grey;
    }
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStatusChange;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const NoteCard({
    super.key,
    required this.note,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSelectionMode
              ? () => onSelectionChanged?.call(!isSelected)
              : onEdit,
          onLongPress: isSelectionMode
              ? null
              : () => onSelectionChanged?.call(!isSelected),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Selection checkbox and Title
                Row(
                  children: [
                    // Selection checkbox
                    if (isSelectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) =>
                            onSelectionChanged?.call(value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Title
                    Expanded(
                      child: Text(
                        note.title,
                        style: AppTextStyles.of(context).subtitle1.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Line 2: Content preview - Display all words
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note.content,
                    style: AppTextStyles.of(context).body1.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Line 3: Word count and date info
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatWordCountAndDate(note),
                        style: AppTextStyles.of(context).body1.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),

                // Line 4: Category and Tags row
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Category (left side)
                    if (note.category != null && note.category!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.label,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              note.category!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Spacer to center tags
                    const Spacer(),

                    // Tags (centered-right)
                    if (note.tags != null && note.tags!.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: note.tags!.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    // Spacer to keep balance if no category
                    if (note.category == null || note.category!.isEmpty)
                      const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatWordCountAndDate(Note note) {
    final wordCount = note.content.isNotEmpty
        ? note.content.trim().split(RegExp(r'\s+')).length
        : 0;

    final dateStr = _formatRelativeDate(note.updatedAt);
    return '$wordCount ${wordCount == 1 ? 'word' : 'words'} • $dateStr';
  }

  static String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
