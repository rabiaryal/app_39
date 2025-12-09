import 'package:app_039/core/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/events_viewmodel.dart';
import '../models/event.dart';
import '../../../core/widgets/router.dart';
import '../../../core/widgets/event_timer_service.dart';
import '../../../core/widgets/app_text_style.dart';
import '../widgets/event_status_selector_widget.dart';
import '../../../core/widgets/unified_card.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen>
    with TickerProviderStateMixin {
  bool _isSelectionMode = false;
  Set<String> _selectedEventIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEventIds.clear();
      }
    });
  }

  Future<void> _deleteSelectedEvents() async {
    if (_selectedEventIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Selected Events',
          style: AppTextStyles.of(context).headline3,
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedEventIds.length} selected event(s)? This action cannot be undone.',
          style: AppTextStyles.of(context).body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.of(
                context,
              ).button.copyWith(color: Theme.of(context).primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTextStyles.of(
                context,
              ).button.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (String eventId in _selectedEventIds) {
        await ref.read(eventsProvider.notifier).deleteEvent(eventId);
      }
      setState(() {
        _selectedEventIds.clear();
        _isSelectionMode = false;
      });
      AppSnackBar.showDeleted(
        context,
        '${_selectedEventIds.length} event(s) deleted successfully',
      );
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimer();
    });
  }

  @override
  void dispose() {
    EventTimerService.dispose();
    super.dispose();
  }

  Future<void> _showQuickAddDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Quick Event',
                      style: AppTextStyles.of(context).headline3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Smart title field
              Text(
                'What\'s happening?',
                style: AppTextStyles.of(context).body2.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.of(context).body1,
                decoration: InputDecoration(
                  hintText: 'Give it a meaningful title...',
                  hintStyle: AppTextStyles.of(context).hint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Details (optional)',
                style: AppTextStyles.of(context).body2.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.of(context).body1,
                decoration: InputDecoration(
                  hintText: 'Add more context if you\'d like...',
                  hintStyle: AppTextStyles.of(context).hint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Maybe later',
                        style: AppTextStyles.of(context).button.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isNotEmpty) {
                          // Create event with smart defaults
                          final now = DateTime.now();
                          final newEvent = Event(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            title: titleController.text.trim(),
                            description:
                                descriptionController.text.trim().isEmpty
                                ? 'No additional details'
                                : descriptionController.text.trim(),
                            date: now,
                            startTime: now,
                            endTime: now.add(const Duration(hours: 1)),
                            repeatType: 'none',
                            priority: 'medium',
                            createdAt: now,
                            updatedAt: now,
                            status: EventStatus.notStarted,
                          );

                          await ref
                              .read(eventsProvider.notifier)
                              .addEvent(newEvent);
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);

                          AppSnackBar.showSuccess(
                            context,
                            'Event created! You can always edit it later.',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Event',
                        style: AppTextStyles.of(context).button.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showClearAllDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Events'),
        content: const Text(
          'Are you sure you want to clear all events? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleEventAction(String action, Event event) async {
    switch (action) {
      case 'edit':
        AppNavigation.goToEditEvent(context, event.id);
        break;
      case 'status':
        _showStatusSelector(context, event);
        break;
      case 'delete':
        final confirmed = await _showDeleteConfirmDialog(event);
        if (confirmed == true) {
          await ref.read(eventsProvider.notifier).deleteEvent(event.id);
          HapticFeedback.lightImpact();
          AppSnackBar.showDeleted(context, 'Event "${event.title}" deleted');
        }
        break;
    }
  }

  Future<bool?> _showDeleteConfirmDialog(Event event) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _initializeTimer() {
    final eventsState = ref.read(eventsProvider);
    final todayEvents = _getTodayEvents(eventsState.events);

    // Update the timer service callback to refresh this screen
    EventTimerService.initialize(todayEvents, (updatedEvents) {
      ref.read(eventsProvider.notifier).updateEventsFromTimer(updatedEvents);
    });
  }

  List<Event> _getTodayEvents(List<Event> allEvents) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allEvents.where((event) {
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      return eventDate.isAtSameMomentAs(today);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Event> _getYesterdayEvents(List<Event> allEvents) {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));

    return allEvents.where((event) {
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      return eventDate.isAtSameMomentAs(yesterday);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Event> _getTomorrowEvents(List<Event> allEvents) {
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    return allEvents.where((event) {
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      return eventDate.isAtSameMomentAs(tomorrow);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Get events grouped by date for upcoming days (after tomorrow)
  Map<DateTime, List<Event>> _getUpcomingEventsGroupedByDate(
    List<Event> allEvents,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    Map<DateTime, List<Event>> groupedEvents = {};

    for (final event in allEvents) {
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      // Only include events after tomorrow
      if (eventDate.isAfter(tomorrow)) {
        if (!groupedEvents.containsKey(eventDate)) {
          groupedEvents[eventDate] = [];
        }
        groupedEvents[eventDate]!.add(event);
      }
    }

    // Sort events within each day by start time
    groupedEvents.forEach((date, events) {
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    // Return sorted by date
    final sortedEntries = groupedEvents.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  // Format date for section headers (e.g., "Oct 13", "Oct 14")
  String _formatDateHeader(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildTimerDisplay(Event event) {
    final remainingTime = event.remainingTime;

    if (remainingTime == null || remainingTime <= Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Overdue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes.remainder(60);
    final seconds = remainingTime.inSeconds.remainder(60);

    String timeText;
    if (hours > 0) {
      timeText = '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      timeText = '${minutes}m ${seconds}s';
    } else {
      timeText = '${seconds}s';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: event.status == EventStatus.ongoing
            ? Colors.green
            : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        timeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimelineSection(
    String title,
    List<Event> events,
    Color color,
    IconData icon, {
    bool isToday = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Header with indicator
          Row(
            children: [
              // Timeline indicator line
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Section info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: AppTextStyles.of(context).headline3.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${events.length} event${events.length != 1 ? 's' : ''}',
                        style: AppTextStyles.of(context).caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Events List
          if (events.isEmpty)
            Container(
              margin: const EdgeInsets.only(left: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Center(
                child: Text(
                  'No events for $title',
                  style: AppTextStyles.of(
                    context,
                  ).body2.copyWith(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...events
                .map(
                  (event) => Container(
                    margin: const EdgeInsets.only(left: 20, bottom: 16),
                    child: EventCard(
                      event: event,
                      isSelectionMode: _isSelectionMode,
                      isSelected: _selectedEventIds.contains(event.id),
                      onSelectionChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedEventIds.add(event.id);
                          } else {
                            _selectedEventIds.remove(event.id);
                          }
                        });
                      },
                      onEdit: _isSelectionMode || !event.canEdit
                          ? null
                          : () =>
                                AppNavigation.goToEditEvent(context, event.id),
                      onStatusChange: _isSelectionMode
                          ? null
                          : () => _showStatusSelector(context, event),
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  void _showStatusSelector(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: EventStatusSelector(
          currentStatus: event.status,
          onStatusChanged: (newStatus) async {
            await ref
                .read(eventsProvider.notifier)
                .updateEventStatus(event.id, newStatus);
            AppSnackBar.showSuccess(
              context,
              'Event status updated to ${newStatus.displayName}',
            );
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(eventsProvider.notifier).deleteEvent(event.id);
              AppSnackBar.showDeleted(context, 'Event deleted successfully');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final allEvents = eventsState.events;
    final activeEvents = allEvents;

    // Show all active events
    final events = activeEvents;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedEventIds.length} selected'
              : 'Daily Activities',
          style: AppTextStyles.of(context).appBarTitle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (!_isSelectionMode)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text('View History'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.checklist),
                      SizedBox(width: 8),
                      Text('Select'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'history') {
                  AppNavigation.goToEventHistory(context);
                } else if (value == 'select') {
                  _toggleSelectionMode();
                }
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Today Section (Middle - at the top initially)
            SliverToBoxAdapter(
              child: _buildTimelineSection(
                'Today',
                _getTodayEvents(events),
                Colors.blue.shade700,
                Icons.today,
                isToday: true,
              ),
            ),

            // Yesterday Section (Top - appears when scrolling up)
            if (_getYesterdayEvents(events).isNotEmpty)
              SliverToBoxAdapter(
                child: _buildTimelineSection(
                  'Yesterday',
                  _getYesterdayEvents(events),
                  Colors.grey.shade400,
                  Icons.history,
                  isToday: false,
                ),
              ),

            // Tomorrow Section
            if (_getTomorrowEvents(events).isNotEmpty)
              SliverToBoxAdapter(
                child: _buildTimelineSection(
                  'Tomorrow',
                  _getTomorrowEvents(events),
                  Colors.green.shade400,
                  Icons.schedule,
                  isToday: true, // Use today's style
                ),
              ),

            // Upcoming Days Sections (Oct 13, Oct 14, etc.)
            ..._getUpcomingEventsGroupedByDate(events).entries.map((entry) {
              final date = entry.key;
              final dayEvents = entry.value;
              return SliverToBoxAdapter(
                child: _buildTimelineSection(
                  _formatDateHeader(date),
                  dayEvents,
                  Colors.blue.shade700, // Use today's color
                  Icons.event,
                  isToday: true, // Use today's style
                ),
              );
            }).toList(),

            // Empty state
            if (events.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events scheduled',
                          style: AppTextStyles.of(
                            context,
                          ).subtitle1.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to create your first event',
                          style: AppTextStyles.of(
                            context,
                          ).body2.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? _selectedEventIds.isNotEmpty
                ? FloatingActionButton.extended(
                    onPressed: _deleteSelectedEvents,
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.delete),
                    label: Text('Delete (${_selectedEventIds.length})'),
                  )
                : null
          : FloatingActionButton(
              onPressed: () => AppNavigation.goToAddEvent(context),
              child: const Icon(Icons.add),
              tooltip: 'Add Event',
            ),
    );
  }
}
