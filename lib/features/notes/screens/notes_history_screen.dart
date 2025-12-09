import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../../../core/widgets/router.dart';

class NotesHistoryScreen extends ConsumerStatefulWidget {
  const NotesHistoryScreen({super.key});

  @override
  ConsumerState<NotesHistoryScreen> createState() => _NotesHistoryScreenState();
}

class _NotesHistoryScreenState extends ConsumerState<NotesHistoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'date'; // date, title, category

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              const PopupMenuItem(value: 'title', child: Text('Sort by Title')),
              const PopupMenuItem(
                value: 'category',
                child: Text('Sort by Category'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => AppNavigation.goToAddNote(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notesProvider.notifier).loadNotes(),
        child: Column(
          children: [
            // Search and category filter
            if (_searchQuery.isNotEmpty) _buildSearchDisplay(context),

            // Category filter
            _buildCategoryFilter(context),

            // Notes list
            Expanded(
              child: notesState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : notesState.error != null
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
                          Text('Error loading notes: ${notesState.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(notesProvider.notifier).loadNotes(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : () {
                      final filteredNotes = _filterAndSortNotes(
                        notesState.notes,
                      );

                      if (filteredNotes.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          return _buildNoteCard(context, filteredNotes[index]);
                        },
                      );
                    }(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchDisplay(BuildContext context) {
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
            Icons.search,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Search: "$_searchQuery"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final notesState = ref.watch(notesProvider);

    if (notesState.isLoading || notesState.error != null) {
      return Container(height: 56);
    }

    // Extract unique categories
    final categories = [
      'all',
      ...notesState.notes
          .map((note) => note.category.toString().split('.').last)
          .toSet()
          .toList(),
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return FilterChip(
            label: Text(category == 'all' ? 'All' : category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, dynamic note) {
    final title = note.title ?? 'Untitled';
    final content = note.content ?? '';
    final category = note.category.toString().split('.').last;
    final createdAt = note.createdAt ?? DateTime.now();
    final updatedAt = note.updatedAt;

    final categoryColor = _getCategoryColor(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to note detail/edit screen
          // AppNavigation.goToNoteDetail(context, note.id);
        },
        borderRadius: BorderRadius.circular(12),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created ${_formatDate(createdAt)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (updatedAt != null && updatedAt != createdAt) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updated ${_formatDate(updatedAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
            Icons.note_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No notes found' : 'No notes yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Create your first note to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterAndSortNotes(List<dynamic> notes) {
    var filtered = notes.where((note) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final title = (note.title ?? '').toLowerCase();
        final content = (note.content ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !content.contains(query)) {
          return false;
        }
      }

      // Filter by category
      if (_selectedCategory != 'all') {
        final category = note.category.toString().split('.').last;
        if (category != _selectedCategory) return false;
      }

      return true;
    }).toList();

    // Sort notes
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) {
          final titleA = a.title ?? '';
          final titleB = b.title ?? '';
          return titleA.compareTo(titleB);
        });
        break;
      case 'category':
        filtered.sort((a, b) {
          final categoryA = a.category.toString().split('.').last;
          final categoryB = b.category.toString().split('.').last;
          return categoryA.compareTo(categoryB);
        });
        break;
      case 'date':
      default:
        filtered.sort((a, b) {
          final dateA = a.updatedAt ?? a.createdAt ?? DateTime.now();
          final dateB = b.updatedAt ?? b.createdAt ?? DateTime.now();
          return dateB.compareTo(dateA); // Newest first
        });
        break;
    }

    return filtered;
  }

  Color _getCategoryColor(String category) {
    // Generate consistent colors for categories
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];

    final index = category.hashCode % colors.length;
    return colors[index.abs()];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'just now';
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchText = _searchQuery;
        return AlertDialog(
          title: const Text('Search Notes'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter search terms...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              searchText = value;
            },
            controller: TextEditingController(text: _searchQuery),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = searchText;
                });
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
