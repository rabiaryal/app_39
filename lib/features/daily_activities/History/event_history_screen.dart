import 'package:app_039/core/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/events_viewmodel.dart';
import '../../../core/utils.dart';
import '../models/event.dart';

class EventHistoryScreen extends ConsumerStatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  ConsumerState<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends ConsumerState<EventHistoryScreen> {
  String _searchQuery = '';
  final Set<String> _selectedItems = {};
  bool _isSelectionMode = false;
  bool _showSearchBar = false;
  String _selectedFilter = 'all'; // all, completed, pending, today, week, month
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Ensure events are loaded when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsProvider.notifier).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final allEvents = eventsState.events;
    final historyEvents = _getFilteredEvents(allEvents);
    final filteredEvents = _searchQuery.isEmpty
        ? historyEvents
        : historyEvents.where((event) {
            final query = _searchQuery.toLowerCase();
            return event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query) ||
                (event.category?.toLowerCase().contains(query) ?? false);
          }).toList();

    final stats = _calculateStats(filteredEvents);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedItems.length} selected'
              : 'Event History',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                  if (!_showSearchBar) _searchQuery = '';
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _showFilters ? Theme.of(context).primaryColor : null,
              ),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Clear All History',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedItems.isNotEmpty ? _deleteSelected : null,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (_showSearchBar)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search events, categories...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),

          // Filter Bar
          if (_showFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedFilter,
                          decoration: InputDecoration(
                            labelText: 'Filter by',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Events'),
                            ),
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text('Completed'),
                            ),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'today',
                              child: Text('Today'),
                            ),
                            DropdownMenuItem(
                              value: 'week',
                              child: Text('This Week'),
                            ),
                            DropdownMenuItem(
                              value: 'month',
                              child: Text('This Month'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value ?? 'all';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showDateRangePicker(),
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${DateTimeUtils.formatDate(_startDate!)} - ${DateTimeUtils.formatDate(_endDate!)}'
                              : 'Date Range',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (_startDate != null ||
                      _endDate != null ||
                      _selectedFilter != 'all')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Active filters: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              children: [
                                if (_selectedFilter != 'all')
                                  Chip(
                                    label: Text(
                                      _selectedFilter.toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    onDeleted: () =>
                                        setState(() => _selectedFilter = 'all'),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (_startDate != null && _endDate != null)
                                  Chip(
                                    label: Text(
                                      '${DateTimeUtils.formatDate(_startDate!)} - ${DateTimeUtils.formatDate(_endDate!)}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    onDeleted: () => setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                    }),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Statistics Card
          if (historyEvents.isNotEmpty && !_isSelectionMode)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      stats['total'].toString(),
                      Icons.event,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Completed',
                      stats['completed'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Pending',
                      stats['pending'].toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Success Rate',
                      '${stats['successRate']}%',
                      Icons.trending_up,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: eventsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEvents.isEmpty
                ? RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(eventsProvider.notifier).loadEvents();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No event history found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Pull to refresh',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(eventsProvider.notifier).loadEvents();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 100,
                      ),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        final isSelected = _selectedItems.contains(event.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Dismissible(
                            key: Key(event.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await _showDeleteDialog(event.title);
                            },
                            onDismissed: (direction) {
                              _deleteEvent(event);
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (value) =>
                                          _toggleSelection(event.id),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: event.isCompleted
                                            ? Colors.green.withOpacity(0.1)
                                            : _getEventStatusColor(
                                                event.status,
                                              ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: event.isCompleted
                                              ? Colors.green
                                              : _getEventStatusColor(
                                                  event.status,
                                                ),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        event.isCompleted
                                            ? Icons.check
                                            : _getEventStatusIcon(event.status),
                                        color: event.isCompleted
                                            ? Colors.green
                                            : _getEventStatusColor(
                                                event.status,
                                              ),
                                      ),
                                    ),
                              title: Text(
                                event.title,
                                style: TextStyle(
                                  decoration: event.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      event.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateTimeUtils.formatDateTime(
                                          event.date,
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (event.category != null &&
                                          event.category!.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.label,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getEventStatusColor(
                                              event.status,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            event.category!,
                                            style: TextStyle(
                                              color: _getEventStatusColor(
                                                event.status,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              onLongPress: () => _enterSelectionMode(event.id),
                              onTap: _isSelectionMode
                                  ? () => _toggleSelection(event.id)
                                  : null,
                              trailing: _isSelectionMode
                                  ? null
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteEvent(event),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _enterSelectionMode(String itemId) {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.clear();
      _selectedItems.add(itemId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _deleteSelected() async {
    final confirmed = await _showDeleteDialog(
      '${_selectedItems.length} events',
    );
    if (confirmed == true) {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleting ${_selectedItems.length} events...'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      for (final id in _selectedItems) {
        await ref.read(eventsProvider.notifier).deleteEvent(id);
      }

      AppSnackBar.showDeleted(
        context,
        '${_selectedItems.length} events deleted locally and syncing to cloud',
      );
      _exitSelectionMode();
    }
  }

  void _deleteEvent(Event event) async {
    await ref.read(eventsProvider.notifier).deleteEvent(event.id);
    AppSnackBar.showDeleted(
      context,
      'Event "${event.title}" deleted locally and syncing to cloud',
    );
  }

  Future<bool?> _showDeleteDialog(String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete $itemName?'),
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

  void _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all event history? This will delete events from both local storage and cloud backup. This action cannot be undone.',
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

    if (confirmed == true) {
      final eventsState = ref.read(eventsProvider);
      final historyEvents = eventsState.events;

      // Show progress indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleting ${historyEvents.length} events...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      for (final event in historyEvents) {
        await ref.read(eventsProvider.notifier).deleteEvent(event.id);
      }

      AppSnackBar.showDeleted(
        context,
        'All event history cleared from local storage and syncing to cloud',
      );
    }
  }

  // Helper Methods
  List<Event> _getFilteredEvents(List<Event> allEvents) {
    final now = DateTime.now();
    List<Event> filtered = allEvents;

    switch (_selectedFilter) {
      case 'completed':
        filtered = filtered.where((event) => event.isCompleted).toList();
        break;
      case 'pending':
        filtered = filtered.where((event) => !event.isCompleted).toList();
        break;
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        filtered = filtered.where((event) {
          return event.date.isAfter(
                today.subtract(const Duration(seconds: 1)),
              ) &&
              event.date.isBefore(tomorrow);
        }).toList();
        break;
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        filtered = filtered.where((event) {
          return event.date.isAfter(
                weekStart.subtract(const Duration(seconds: 1)),
              ) &&
              event.date.isBefore(weekEnd);
        }).toList();
        break;
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        filtered = filtered.where((event) {
          return event.date.isAfter(
                monthStart.subtract(const Duration(seconds: 1)),
              ) &&
              event.date.isBefore(monthEnd);
        }).toList();
        break;
    }

    // Apply date range filter if set
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((event) {
        return event.date.isAfter(
              _startDate!.subtract(const Duration(seconds: 1)),
            ) &&
            event.date.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Map<String, int> _calculateStats(List<Event> events) {
    final total = events.length;
    final completed = events.where((e) => e.isCompleted).length;
    final pending = total - completed;
    final successRate = total > 0 ? ((completed / total) * 100).round() : 0;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'successRate': successRate,
    };
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  // Helper methods for event status colors and icons
  Color _getEventStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.completed:
        return Colors.green;
      case EventStatus.ongoing:
        return Colors.blue;
      case EventStatus.notStarted:
        return Colors.orange;
    }
  }

  IconData _getEventStatusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.completed:
        return Icons.check_circle;
      case EventStatus.ongoing:
        return Icons.play_circle_filled;
      case EventStatus.notStarted:
        return Icons.schedule;
    }
  }
}
