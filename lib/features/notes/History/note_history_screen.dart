import 'package:app_039/core/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../../../core/utils.dart';
import '../models/note.dart';
import '../../../core/widgets/app_text_style.dart';

class NoteHistoryScreen extends ConsumerStatefulWidget {
  const NoteHistoryScreen({super.key});

  @override
  ConsumerState<NoteHistoryScreen> createState() => _NoteHistoryScreenState();
}

class _NoteHistoryScreenState extends ConsumerState<NoteHistoryScreen> {
  String _searchQuery = '';
  final Set<String> _selectedItems = {};
  bool _isSelectionMode = false;
  bool _showSearchBar = false;

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final allNotes = notesState.notes;
    final historyNotes = allNotes;
    final filteredNotes = _searchQuery.isEmpty
        ? historyNotes
        : historyNotes.where((note) {
            final query = _searchQuery.toLowerCase();
            return note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedItems.length} selected'
              : 'Note History',
          style: AppTextStyles.of(context).appBarTitle,
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
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: AppTextStyles.of(context).hint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: AppTextStyles.of(context).body1,
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),
          Expanded(
            child: notesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No note history found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 100,
                    ),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      final isSelected = _selectedItems.contains(note.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Dismissible(
                          key: Key(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await _showDeleteDialog(note.title);
                          },
                          onDismissed: (direction) {
                            _deleteNote(note);
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: _isSelectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (value) =>
                                        _toggleSelection(note.id),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getNoteStatusColor(
                                        note.status,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getNoteStatusColor(
                                          note.status,
                                        ).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.note,
                                      color: _getNoteStatusColor(note.status),
                                      size: 24,
                                    ),
                                  ),
                            title: Text(
                              note.title,
                              style: AppTextStyles.of(
                                context,
                              ).body1.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  note.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.of(context).body2,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getNoteStatusColor(
                                          note.status,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        note.status.displayName,
                                        style: AppTextStyles.of(context).caption
                                            .copyWith(
                                              color: _getNoteStatusColor(
                                                note.status,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    if (note.category != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${note.category}',
                                        style: AppTextStyles.of(
                                          context,
                                        ).caption,
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(
                                      DateTimeUtils.formatDateTime(
                                        note.updatedAt,
                                      ),
                                      style: AppTextStyles.of(context).caption
                                          .copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onLongPress: () => _enterSelectionMode(note.id),
                            onTap: _isSelectionMode
                                ? () => _toggleSelection(note.id)
                                : null,
                            trailing: _isSelectionMode
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteNote(note),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getNoteStatusColor(NoteStatus status) {
    switch (status) {
      case NoteStatus.notStarted:
        return Colors.orange;
      case NoteStatus.active:
        return Colors.blue;
      case NoteStatus.done:
        return Colors.green;
      case NoteStatus.urgent:
        return Colors.red;
    }
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
    final confirmed = await _showDeleteDialog('${_selectedItems.length} notes');
    if (confirmed == true) {
      for (final id in _selectedItems) {
        await ref.read(notesProvider.notifier).deleteNote(id);
      }
      AppSnackBar.showDeleted(
        context,
        '${_selectedItems.length} notes deleted',
      );
      _exitSelectionMode();
    }
  }

  void _deleteNote(Note note) async {
    await ref.read(notesProvider.notifier).deleteNote(note.id);
    AppSnackBar.showDeleted(context, 'Note deleted from history');
  }

  Future<bool?> _showDeleteDialog(String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note', style: AppTextStyles.of(context).headline3),
        content: Text(
          'Are you sure you want to delete $itemName?',
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
  }

  void _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All History',
          style: AppTextStyles.of(context).headline3,
        ),
        content: Text(
          'Are you sure you want to delete all note history? This action cannot be undone.',
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
              'Clear All',
              style: AppTextStyles.of(
                context,
              ).button.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notesState = ref.read(notesProvider);
      final historyNotes = notesState.notes;

      for (final note in historyNotes) {
        await ref.read(notesProvider.notifier).deleteNote(note.id);
      }

      AppSnackBar.showDeleted(context, 'All note history cleared');
    }
  }
}
