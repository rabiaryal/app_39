import 'package:app_039/core/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../models/note.dart';
import '../../../core/widgets/router.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/refresh_system.dart';
import '../../../core/widgets/note_status_colors.dart';
import '../../../core/widgets/app_text_style.dart';
import '../widgets/note_status_selector_widget.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with TickerProviderStateMixin {
  bool _showSearchBar = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _searchAnimationController;

  // Smart search suggestions
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _updateSearchSuggestions();
    });
  }

  void _updateSearchSuggestions() {
    final notesState = ref.read(notesProvider);
    final allNotes = notesState.notes;

    if (_searchQuery.isEmpty) {
      _searchSuggestions = [];
      _showSuggestions = false;
      return;
    }

    // Generate smart suggestions from existing content
    final suggestions = <String>{};

    // Add matching tags
    for (final note in allNotes) {
      if (note.tags != null) {
        for (final tag in note.tags!) {
          if (tag.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              tag.toLowerCase() != _searchQuery.toLowerCase()) {
            suggestions.add('#$tag');
          }
        }
      }

      // Add matching status names
      if (note.status.displayName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) &&
          note.status.displayName.toLowerCase() != _searchQuery.toLowerCase()) {
        suggestions.add(note.status.displayName);
      }
    }

    _searchSuggestions = suggestions.take(5).toList();
    _showSuggestions = _searchSuggestions.isNotEmpty;
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _searchAnimationController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchQuery = '';
        _showSuggestions = false;
        _searchFocusNode.unfocus();
      }
    });
  }

  void _applySuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _searchQuery = suggestion;
      _showSuggestions = false;
    });
    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }

  void _showStatusSelector(BuildContext context, Note note) {
    HapticFeedback.mediumImpact();
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
            HapticFeedback.lightImpact();
            AppSnackBar.showSuccess(
              context,
              'Note status updated to ${newStatus.displayName}',
            );
          },
        ),
      ),
    );
  }

  Future<void> _showQuickAddDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

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
                      Icons.lightbulb_outline,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Quick Note',
                      style: AppTextStyles.of(context).headline3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Smart title field with auto-suggestions
              Text(
                'What\'s on your mind?',
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
                controller: contentController,
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
                          // Create note with smart defaults
                          final newNote = Note(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            title: titleController.text.trim(),
                            content: contentController.text.trim().isEmpty
                                ? 'No additional details'
                                : contentController.text.trim(),
                            date: DateTime.now(),
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            status: NoteStatus.active, // Smart default
                          );

                          await ref
                              .read(notesProvider.notifier)
                              .addNote(newNote);
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);

                          AppSnackBar.showSuccess(
                            context,
                            'Note created! You can always edit it later.',
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
                        'Save Note',
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
        title: const Text('Clear All Notes'),
        content: const Text(
          'Are you sure you want to clear all notes? This action cannot be undone.',
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

  void _handleNoteAction(String action, Note note) async {
    switch (action) {
      case 'edit':
        AppNavigation.goToEditNote(context, note.id);
        break;
      case 'status':
        _showStatusSelector(context, note);
        break;
      case 'delete':
        final confirmed = await _showDeleteConfirmDialog(note);
        if (confirmed == true) {
          await ref.read(notesProvider.notifier).deleteNote(note.id);
          HapticFeedback.lightImpact();
          AppSnackBar.showDeleted(context, 'Note "${note.title}" deleted');
        }
        break;
    }
  }

  Future<bool?> _showDeleteConfirmDialog(Note note) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
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

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final allNotes = notesState.notes;
    final activeNotes = allNotes;

    // Enhanced search with better filtering
    final notes = _showSearchBar && _searchQuery.isNotEmpty
        ? activeNotes.where((note) {
            final query = _searchQuery.toLowerCase();
            return note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query) ||
                (note.tags?.any((tag) => tag.toLowerCase().contains(query)) ??
                    false) ||
                note.status.displayName.toLowerCase().contains(query);
          }).toList()
        : activeNotes;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showSearchBar
              ? Container(
                  key: const ValueKey('search'),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        style: AppTextStyles.of(context).body1,
                        decoration: InputDecoration(
                          hintText:
                              'Search by title, content, tags, or status...',
                          border: InputBorder.none,
                          hintStyle: AppTextStyles.of(
                            context,
                          ).hint.copyWith(fontSize: 14),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Icon(
                                    Icons.clear,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                    size: 20,
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (value) => _onSearchChanged(),
                      ),
                    ],
                  ),
                )
              : Text(
                  'Notes',
                  key: const ValueKey('title'),
                  style: AppTextStyles.of(context).appBarTitle,
                ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_showSearchBar) ...[
            // Search results counter
            if (_searchQuery.isNotEmpty)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notes.length} found',
                    style: AppTextStyles.of(context).caption.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
              tooltip: 'Close search',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              tooltip: 'Search notes',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: (value) async {
                HapticFeedback.selectionClick();
                switch (value) {
                  case 'history':
                    AppNavigation.goToNotesHistory(context);
                    break;
                  case 'clear_all':
                    final confirmed = await _showClearAllDialog();
                    if (confirmed == true) {
                      await ref.read(notesProvider.notifier).clearAllNotes();
                      HapticFeedback.lightImpact();
                      AppSnackBar.showDeleted(
                        context,
                        'All notes cleared. You can always start fresh!',
                      );
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 12),
                      Text('View History'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Clear All Notes'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search suggestions overlay
              if (_showSearchBar && _showSuggestions)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Quick suggestions',
                          style: AppTextStyles.of(context).caption.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...List.generate(_searchSuggestions.length, (index) {
                        final suggestion = _searchSuggestions[index];
                        return InkWell(
                          onTap: () => _applySuggestion(suggestion),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  suggestion.startsWith('#')
                                      ? Icons.tag
                                      : Icons.circle,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  suggestion,
                                  style: AppTextStyles.of(context).body2,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

              // Main content
              Expanded(
                child: notesState.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading your notes...'),
                          ],
                        ),
                      )
                    : notesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Oops! Something went wrong',
                              style: AppTextStyles.of(context).headline3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notesState.error!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.of(context).body2.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  ref.read(notesProvider.notifier).loadNotes(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _showSearchBar && _searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.note_add,
                                size: 48,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showSearchBar && _searchQuery.isNotEmpty
                                  ? 'No notes match your search'
                                  : 'Ready to capture your thoughts?',
                              style: AppTextStyles.of(context).headline3,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showSearchBar && _searchQuery.isNotEmpty
                                  ? 'Try a different search term or create a new note'
                                  : 'Tap the + button to add your first note',
                              style: AppTextStyles.of(context).body2.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_showSearchBar && _searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showQuickAddDialog();
                                },
                                icon: const Icon(Icons.add),
                                label: Text(
                                  'Create "${_searchQuery.length > 20 ? "${_searchQuery.substring(0, 20)}..." : _searchQuery}"',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : AppRefreshIndicator(
                        onRefresh: () async {
                          await ref.read(notesProvider.notifier).loadNotes();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 100,
                          ),
                          itemCount: notes.length,
                          itemBuilder: (context, index) =>
                              _buildNoteCard(notes[index], index),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showQuickAddDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildNoteCard(Note note, int index) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final statusBackgroundColor = NoteStatusColors.getBackgroundColor(
      note.status,
      isDarkTheme: isDarkTheme,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: statusBackgroundColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            AppNavigation.goToEditNote(context, note.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Enhanced status indicator
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NoteStatusColors.getChipColor(note.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note.status.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title with better typography
                    Expanded(
                      child: Text(
                        note.title,
                        style: AppTextStyles.of(
                          context,
                        ).headline3.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Simplified menu
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      tooltip: 'Note options',
                      onSelected: (value) => _handleNoteAction(value, note),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 12),
                              Text('Edit Note'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.label_outlined),
                              SizedBox(width: 12),
                              Text('Change Status'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Content preview
                if (note.content.isNotEmpty)
                  Text(
                    note.content,
                    style: AppTextStyles.of(context).body2.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Enhanced bottom section
                Row(
                  children: [
                    // Interactive status chip
                    GestureDetector(
                      onTap: () => _showStatusSelector(context, note),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: NoteStatusColors.getChipColor(note.status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              note.status.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              note.status.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Time stamp with better formatting
                    Text(
                      DateTimeUtils.formatDateTime(note.updatedAt),
                      style: AppTextStyles.of(context).caption.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Tags with improved design
                if (note.tags?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: note.tags!.take(5).map((tag) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _showSearchBar = true;
                            _searchController.text = tag;
                            _searchQuery = tag;
                            _updateSearchSuggestions();
                            _searchFocusNode.requestFocus();
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: AppTextStyles.of(context).caption.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ], // close the if block for tags
              ], // close the children for the Column in _buildNoteCard
            ), // close the Padding in _buildNoteCard
          ), // close the InkWell in _buildNoteCard
        ), // close the Card in _buildNoteCard
      ), // close the Container in _buildNoteCard
    ); // close the _buildNoteCard widget
  }
}
