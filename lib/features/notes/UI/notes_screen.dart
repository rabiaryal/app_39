import 'package:app_039/core/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../models/note.dart';
import '../../../core/widgets/router.dart';
import '../../../core/widgets/refresh_system.dart';
import '../../../core/widgets/app_text_style.dart';
import '../../../core/widgets/unified_card.dart';
import '../widgets/note_status_selector_widget.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _isSelectionMode = false;
  Set<String> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    // Load notes when screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotes();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNoteIds.clear();
      }
    });
  }

  Future<void> _deleteSelectedNotes() async {
    if (_selectedNoteIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Selected Notes',
          style: AppTextStyles.of(context).headline3,
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedNoteIds.length} selected note(s)? This action cannot be undone.',
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
      for (String noteId in _selectedNoteIds) {
        await ref.read(notesProvider.notifier).deleteNote(noteId);
      }
      setState(() {
        _selectedNoteIds.clear();
        _isSelectionMode = false;
      });
      AppSnackBar.showDeleted(
        context,
        '${_selectedNoteIds.length} note(s) deleted successfully',
      );
    }
  }

  void _showStatusSelector(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: NoteStatusSelector(
          currentStatus: note.status,
          onStatusChanged: (newStatus) async {
            await ref
                .read(notesProvider.notifier)
                .updateNoteStatus(note.id, newStatus);
            AppSnackBar.showSuccess(
              context,
              'Note status updated to ${newStatus.displayName}',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final allNotes = notesState.notes;

    // Filter active notes (30 days old or newer)
    final activeNotes = allNotes;

    // No search filtering - show all active notes
    final notes = activeNotes;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedNoteIds.length} selected' : 'Notes',
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'history':
                    AppNavigation.goToNotesHistory(context);
                    break;
                  case 'select':
                    _toggleSelectionMode();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 8),
                      Text(
                        'View History',
                        style: AppTextStyles.of(context).body2,
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      const Icon(Icons.checklist),
                      const SizedBox(width: 8),
                      Text('Select', style: AppTextStyles.of(context).body2),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notesState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${notesState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(notesProvider.notifier).loadNotes(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildContent(context, notes),
      floatingActionButton: _isSelectionMode
          ? _selectedNoteIds.isNotEmpty
                ? FloatingActionButton.extended(
                    onPressed: _deleteSelectedNotes,
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.delete),
                    label: Text('Delete (${_selectedNoteIds.length})'),
                  )
                : null
          : FloatingActionButton(
              onPressed: () => AppNavigation.goToAddNote(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildContent(BuildContext context, List<Note> notes) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notesProvider.notifier).loadNotes();
      },
      child: Column(
        children: [
          // Stats Card
          _buildStatsCard(context, notes),

          // Notes List
          Expanded(
            child: notes.isEmpty
                ? _buildEmptyState(context)
                : _buildNotesList(context, notes),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, List<Note> notes) {
    final theme = Theme.of(context);
    final totalNotes = notes.length;
    final thisWeekNotes = notes.where((note) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      return note.createdAt.isAfter(weekAgo);
    }).length;
    final pinnedNotes = notes.where((note) => note.isPinned).length;

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
                  Icons.note,
                  'Total',
                  totalNotes.toString(),
                ),
              ),
              Container(width: 1, height: 40, color: theme.dividerColor),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.push_pin,
                  'Pinned',
                  pinnedNotes.toString(),
                ),
              ),
              Container(width: 1, height: 40, color: theme.dividerColor),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.calendar_today,
                  'This Week',
                  thisWeekNotes.toString(),
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
        Icon(icon, color: theme.colorScheme.primary, size: 24),
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

  Widget _buildNotesList(BuildContext context, List<Note> notes) {
    final groupedNotes = _groupNotesByDate(notes);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedNotes.length,
      itemBuilder: (context, index) {
        final entry = groupedNotes.entries.elementAt(index);
        final date = entry.key;
        final dayNotes = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(context, date),
            const SizedBox(height: 8),
            ...dayNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NoteCard(
                  note: note,
                  isSelectionMode: _isSelectionMode,
                  isSelected: _selectedNoteIds.contains(note.id),
                  onSelectionChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedNoteIds.add(note.id);
                      } else {
                        _selectedNoteIds.remove(note.id);
                      }
                    });
                  },
                  onEdit: _isSelectionMode
                      ? null
                      : () {
                          AppNavigation.goToEditNote(context, note.id);
                        },
                  onStatusChange: _isSelectionMode
                      ? null
                      : () {
                          _showStatusSelector(context, note);
                        },
                ),
              ),
            ),
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
    final noteDate = DateTime(date.year, date.month, date.day);

    String dateLabel;
    if (noteDate == today) {
      dateLabel = 'Today';
    } else if (noteDate == today.subtract(const Duration(days: 1))) {
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

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_outlined,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Notes Available',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You haven\'t created any notes yet. Tap the button below to get started.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => AppNavigation.goToAddNote(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Note'),
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
      ),
    );
  }

  Map<DateTime, List<Note>> _groupNotesByDate(List<Note> notes) {
    final grouped = <DateTime, List<Note>>{};

    for (final note in notes) {
      final noteDate = note.createdAt;
      final dateKey = DateTime(noteDate.year, noteDate.month, noteDate.day);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(note);
    }

    // Sort notes within each day by creation time (newest first)
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return grouped;
  }
}
