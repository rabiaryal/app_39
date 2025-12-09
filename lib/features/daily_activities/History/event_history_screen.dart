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
    final historyEvents = allEvents;
    final filteredEvents = _searchQuery.isEmpty
        ? historyEvents
        : historyEvents.where((event) {
            final query = _searchQuery.toLowerCase();
            return event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query);
          }).toList();

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
          if (_showSearchBar)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search events...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
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
                          child: Dismissible(
                            key: Key(event.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
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
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (value) =>
                                          _toggleSelection(event.id),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: event.isCompleted
                                          ? Colors.green
                                          : Colors.grey,
                                      child: Icon(
                                        event.isCompleted
                                            ? Icons.check
                                            : Icons.event,
                                        color: Colors.white,
                                      ),
                                    ),
                              title: Text(
                                event.title,
                                style: TextStyle(
                                  decoration: event.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateTimeUtils.formatDateTime(event.date),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
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
                                        Icons.delete,
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
}
