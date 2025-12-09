import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/events_viewmodel.dart';
import '../../../core/widgets/router.dart';

class EventsHistoryScreen extends ConsumerStatefulWidget {
  const EventsHistoryScreen({super.key});

  @override
  ConsumerState<EventsHistoryScreen> createState() =>
      _EventsHistoryScreenState();
}

class _EventsHistoryScreenState extends ConsumerState<EventsHistoryScreen> {
  String _selectedFilter = 'all'; // all, completed, ongoing, upcoming
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Load events when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsProvider.notifier).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => AppNavigation.goToAddEvent(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(eventsProvider.notifier).loadEvents(),
        child: Column(
          children: [
            // Filter chips
            _buildFilterChips(context),

            // Date range filter
            if (_startDate != null || _endDate != null)
              _buildDateRangeDisplay(context),

            // Events list
            Expanded(
              child: eventsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : eventsState.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text('Error loading events: ${eventsState.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(eventsProvider.notifier).loadEvents(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : () {
                      final filteredEvents = _filterEvents(eventsState.events);

                      if (filteredEvents.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      // Group events by date
                      final groupedEvents = _groupEventsByDate(filteredEvents);

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedEvents.length,
                        itemBuilder: (context, index) {
                          final entry = groupedEvents.entries.elementAt(index);
                          final date = entry.key;
                          final dayEvents = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateHeader(context, date),
                              const SizedBox(height: 8),
                              ...dayEvents.map(
                                (event) => _buildEventCard(context, event),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      );
                    }(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'upcoming', 'label': 'Upcoming'},
      {'key': 'ongoing', 'label': 'Ongoing'},
      {'key': 'completed', 'label': 'Completed'},
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];

          return FilterChip(
            label: Text(filter['label']!),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter['key']!;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildDateRangeDisplay(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '${_startDate != null ? DateFormat('MMM d').format(_startDate!) : 'Start'} - '
            '${_endDate != null ? DateFormat('MMM d').format(_endDate!) : 'End'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    String dateLabel;
    if (eventDate == today) {
      dateLabel = 'Today';
    } else if (eventDate == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Yesterday';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = DateFormat('EEEE, MMM d').format(date);
    }

    return Text(
      dateLabel,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, dynamic event) {
    final title = event.title ?? 'Untitled Event';
    final description = event.description ?? '';
    final status = event.status.toString().split('.').last;
    final startTime = event.startTime;
    final endTime = event.endTime;

    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
            if (startTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('HH:mm').format(startTime)}'
                    '${endTime != null ? ' - ${DateFormat('HH:mm').format(endTime)}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add a new event',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterEvents(List<dynamic> events) {
    var filtered = events.where((event) {
      // Filter by status
      if (_selectedFilter != 'all') {
        final status = event.status.toString().split('.').last;
        if (status != _selectedFilter) return false;
      }

      // Filter by date range
      final eventDate = event.startTime;
      if (eventDate != null) {
        if (_startDate != null && eventDate.isBefore(_startDate!)) return false;
        if (_endDate != null && eventDate.isAfter(_endDate!)) return false;
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    filtered.sort((a, b) {
      final dateA = a.startTime ?? DateTime.now();
      final dateB = b.startTime ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  Map<DateTime, List<dynamic>> _groupEventsByDate(List<dynamic> events) {
    final grouped = <DateTime, List<dynamic>>{};

    for (final event in events) {
      final eventDate = event.startTime ?? DateTime.now();
      final dateKey = DateTime(eventDate.year, eventDate.month, eventDate.day);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(event);
    }

    return grouped;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'upcoming':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Select Date Range'),
              trailing: const Icon(Icons.date_range),
              onTap: () async {
                Navigator.pop(context);
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (range != null) {
                  setState(() {
                    _startDate = range.start;
                    _endDate = range.end;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
