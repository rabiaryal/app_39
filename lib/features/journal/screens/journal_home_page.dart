import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/router.dart';
import '../viewmodels/journal_viewmodel.dart';
import '../models/journal_entry.dart';

class JournalHistoryScreen extends ConsumerStatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  ConsumerState<JournalHistoryScreen> createState() =>
      _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends ConsumerState<JournalHistoryScreen> {
  String _selectedMood = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(journalProvider.notifier).loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journal'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search),
        //     onPressed: _showSearchDialog,
        //   ),
        // ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppNavigation.goToAddJournal(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(journalProvider.notifier).loadEntries();
        },
        child: journalState.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : journalState.error != null
            ? _buildErrorState(context, journalState.error!)
            : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final journalState = ref.watch(journalProvider);
    final filteredEntries = _filterEntries(journalState.entries);

    return Column(
      children: [
        // Stats Card
        _buildStatsCard(context, filteredEntries),

        // Mood Filter
        _buildMoodFilter(context),

        // Search Display
        if (_searchQuery.isNotEmpty) _buildSearchBadge(context),

        // Entries List
        Expanded(
          child: filteredEntries.isEmpty
              ? _buildEmptyState(context)
              : _buildEntriesList(context, filteredEntries),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, List<JournalEntry> entries) {
    final theme = Theme.of(context);
    final totalEntries = entries.length;
    final thisWeekEntries = entries.where((entry) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      return entry.createdAt.isAfter(weekAgo);
    }).length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.book,
                  'Total',
                  totalEntries.toString(),
                ),
              ),
              Container(width: 1, height: 40, color: theme.dividerColor),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.calendar_today,
                  'This Week',
                  thisWeekEntries.toString(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodFilter(BuildContext context) {
    final moods = [
      {'key': 'all', 'label': 'All', 'emoji': '📝'},
      {'key': 'veryHappy', 'label': 'Very Happy', 'emoji': '😄'},
      {'key': 'happy', 'label': 'Happy', 'emoji': '😊'},
      {'key': 'neutral', 'label': 'Neutral', 'emoji': '😐'},
      {'key': 'sad', 'label': 'Sad', 'emoji': '😢'},
      {'key': 'verySad', 'label': 'Very Sad', 'emoji': '😭'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mood = moods[index];
          final isSelected = _selectedMood == mood['key'];

          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood['emoji']!),
                const SizedBox(width: 6),
                Text(mood['label']!),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedMood = mood['key']!);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 18,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Searching: "$_searchQuery"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            onPressed: () => setState(() => _searchQuery = ''),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(BuildContext context, List<JournalEntry> entries) {
    final groupedEntries = _groupEntriesByDate(entries);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedEntries.length,
      itemBuilder: (context, index) {
        final entry = groupedEntries.entries.elementAt(index);
        final date = entry.key;
        final dayEntries = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(context, date),
            const SizedBox(height: 8),
            ...dayEntries.map((e) => _buildEntryCard(context, e)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    String dateLabel;
    if (entryDate == today) {
      dateLabel = 'Today';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        dateLabel,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, JournalEntry entry) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => AppNavigation.goToEditJournalEntry(context, entry.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.mood.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.mood.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(entry.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              if (entry.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  entry.content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedMood != 'all'
                  ? 'No entries found'
                  : 'Start Your Journal',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedMood != 'all'
                  ? 'Try adjusting your filters'
                  : 'Capture your thoughts, feelings, and experiences',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                print('Empty state button pressed - attempting navigation');
                try {
                  AppNavigation.goToAddJournalEntry(context);
                  print('Empty state navigation call completed');
                } catch (e) {
                  print('Empty state navigation error: $e');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Entry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(journalProvider.notifier).loadEntries(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<JournalEntry> _filterEntries(List<JournalEntry> entries) {
    var filtered = entries.where((entry) {
      // Filter by mood
      if (_selectedMood != 'all') {
        final moodKey = 'Mood.$_selectedMood';
        if (entry.mood.toString() != moodKey) return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatches = entry.title.toLowerCase().contains(query);
        final contentMatches = entry.content.toLowerCase().contains(query);
        if (!titleMatches && !contentMatches) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Map<DateTime, List<JournalEntry>> _groupEntriesByDate(
    List<JournalEntry> entries,
  ) {
    final grouped = <DateTime, List<JournalEntry>>{};

    for (final entry in entries) {
      final entryDate = entry.createdAt;
      final dateKey = DateTime(entryDate.year, entryDate.month, entryDate.day);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(entry);
    }

    return grouped;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchText = _searchQuery;
        return AlertDialog(
          title: const Text('Search Entries'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by title or content...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => searchText = value,
            controller: TextEditingController(text: _searchQuery),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _searchQuery = searchText);
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}
