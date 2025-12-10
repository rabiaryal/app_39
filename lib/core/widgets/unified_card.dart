import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStatusChange;
  final Future<bool> Function(EventStatus)? onStatusChangeWithValidation;
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
    this.onStatusChangeWithValidation,
    this.elevation = 3,
    this.cardColor,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every 30 seconds for ongoing events, every minute for others
    _startTimer();
  }

  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.status != widget.event.status ||
        oldWidget.event.startTime != widget.event.startTime ||
        oldWidget.event.endTime != widget.event.endTime) {
      // Event status or time changed, restart timer with appropriate interval
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    // For ongoing events, update every 30 seconds for more responsive timer
    // For other events, update every minute
    final interval = widget.event.status == EventStatus.ongoing
        ? const Duration(seconds: 30)
        : const Duration(minutes: 1);

    _timer = Timer.periodic(interval, (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getEventStatusColor(widget.event.status);
    final defaultCardColor = widget.cardColor ?? Theme.of(context).cardColor;
    final canEditEvent = widget.event.canEdit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: widget.elevation,
        color: defaultCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: widget.isSelectionMode
              ? () => widget.onSelectionChanged?.call(!widget.isSelected)
              : (canEditEvent && widget.onEdit != null
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onEdit!();
                      }
                    : null),
          onLongPress: widget.isSelectionMode
              ? null
              : () => widget.onSelectionChanged?.call(!widget.isSelected),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: widget.isSelected
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
                    if (widget.isSelectionMode) ...[
                      Checkbox(
                        value: widget.isSelected,
                        onChanged: (value) =>
                            widget.onSelectionChanged?.call(value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                    ],

                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.event.title,
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
                          if (!canEditEvent && !widget.isSelectionMode) ...[
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
                      onTap: () => _showStatusChangeDialog(context),
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
                              widget.event.status.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.event.status.displayName,
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
                if (widget.event.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
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
                        _formatTimePeriod(
                          widget.event.startTime,
                          widget.event.endTime,
                        ),
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
                    if (widget.event.category != null &&
                        widget.event.category!.isNotEmpty)
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
                              widget.event.category!,
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
                    if (widget.event.category == null ||
                        widget.event.category!.isEmpty)
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
    final eventStart = widget.event.startTime;
    final eventEnd = widget.event.endTime;

    // Calculate time difference
    final timeDifference = eventStart.difference(now);
    final isEventInFuture = timeDifference.inMinutes > 0;
    final isEventActive = widget.event.status == EventStatus.ongoing;

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
    } else if (widget.event.status == EventStatus.completed) {
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

  void _showStatusChangeDialog(BuildContext context) {
    final currentStatus = widget.event.status;
    final availableStatuses = EventStatus.values
        .where((status) => status != currentStatus)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current status: ${currentStatus.emoji} ${currentStatus.displayName}',
            ),
            const SizedBox(height: 16),
            const Text('Select new status:'),
            const SizedBox(height: 12),
            ...availableStatuses.map(
              (status) => ListTile(
                leading: Text(
                  status.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(status.displayName),
                subtitle: _getStatusDescription(currentStatus, status),
                onTap: () => _handleStatusChange(context, status),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget? _getStatusDescription(
    EventStatus currentStatus,
    EventStatus newStatus,
  ) {
    if (currentStatus == EventStatus.notStarted &&
        newStatus == EventStatus.ongoing) {
      return const Text(
        'Will start now and update time frame',
        style: TextStyle(fontSize: 12, color: Colors.blue),
      );
    } else if (newStatus == EventStatus.completed) {
      return const Text(
        'Mark as completed',
        style: TextStyle(fontSize: 12, color: Colors.green),
      );
    }
    return null;
  }

  void _handleStatusChange(BuildContext context, EventStatus newStatus) async {
    Navigator.of(context).pop();

    if (widget.onStatusChangeWithValidation != null) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final success = await widget.onStatusChangeWithValidation!(newStatus);
        Navigator.of(context).pop(); // Close loading

        if (!success) {
          // Show error message - the error is already set in the view model
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot change status due to conflicts'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        } else {
          // Show success message
          String message = 'Status updated successfully';
          if (widget.event.status == EventStatus.notStarted &&
              newStatus == EventStatus.ongoing) {
            message = 'Event started! Time frame updated to current time.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } else if (widget.onStatusChange != null) {
      // Fallback to simple status change
      widget.onStatusChange!();
    }
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

class NoteCard extends StatefulWidget {
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
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.status != widget.note.status ||
        oldWidget.note.updatedAt != widget.note.updatedAt) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    // Update every minute for time-sensitive status changes
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

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
          onTap: widget.isSelectionMode
              ? () => widget.onSelectionChanged?.call(!widget.isSelected)
              : widget.onEdit,
          onLongPress: widget.isSelectionMode
              ? null
              : () => widget.onSelectionChanged?.call(!widget.isSelected),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: widget.isSelected
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
                    if (widget.isSelectionMode) ...[
                      Checkbox(
                        value: widget.isSelected,
                        onChanged: (value) =>
                            widget.onSelectionChanged?.call(value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Title
                    Expanded(
                      child: Text(
                        widget.note.title,
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
                if (widget.note.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.note.content,
                    style: AppTextStyles.of(context).body1.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Line 3: Status-based time display
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _getNoteStatusIcon(widget.note.status),
                      size: 16,
                      color: _getNoteStatusColor(widget.note.status),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _buildNoteTimeDisplay(),
                        style: AppTextStyles.of(context).body1.copyWith(
                          color: _getNoteStatusColor(widget.note.status),
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
                    if (widget.note.category != null &&
                        widget.note.category!.isNotEmpty)
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
                              widget.note.category!,
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
                    if (widget.note.tags != null &&
                        widget.note.tags!.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: widget.note.tags!.take(3).map((tag) {
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
                    if (widget.note.category == null ||
                        widget.note.category!.isEmpty)
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

  // Helper methods for note status
  Color _getNoteStatusColor(NoteStatus status) {
    switch (status) {
      case NoteStatus.notStarted:
        return Colors.grey;
      case NoteStatus.active:
        return Colors.blue;
      case NoteStatus.done:
        return Colors.green;
      case NoteStatus.urgent:
        return Colors.red;
    }
  }

  IconData _getNoteStatusIcon(NoteStatus status) {
    switch (status) {
      case NoteStatus.notStarted:
        return Icons.radio_button_unchecked;
      case NoteStatus.active:
        return Icons.access_time;
      case NoteStatus.done:
        return Icons.check_circle;
      case NoteStatus.urgent:
        return Icons.priority_high;
    }
  }

  String _buildNoteTimeDisplay() {
    final now = DateTime.now();

    switch (widget.note.status) {
      case NoteStatus.notStarted:
        return 'Created ${_formatRelativeDate(widget.note.createdAt)}';
      case NoteStatus.active:
        final duration = now.difference(widget.note.updatedAt);
        if (duration.inDays > 0) {
          return 'Active for ${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'}';
        } else if (duration.inHours > 0) {
          return 'Active for ${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
        } else {
          return 'Active for ${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'}';
        }
      case NoteStatus.done:
        return 'Completed ${_formatRelativeDate(widget.note.updatedAt)}';
      case NoteStatus.urgent:
        return 'Urgent - Updated ${_formatRelativeDate(widget.note.updatedAt)}';
    }
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
