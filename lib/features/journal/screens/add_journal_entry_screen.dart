import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/journal_entry.dart';
import '../viewmodels/journal_viewmodel.dart';

class AddJournalEntryScreen extends ConsumerStatefulWidget {
  final String? journalId;

  const AddJournalEntryScreen({super.key, this.journalId});

  @override
  ConsumerState<AddJournalEntryScreen> createState() =>
      _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends ConsumerState<AddJournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Mood _selectedMood = Mood.neutral;
  bool _isLoading = false;
  JournalEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    if (widget.journalId != null) {
      _loadExistingEntry();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingEntry() async {
    setState(() => _isLoading = true);

    try {
      final journalState = ref.read(journalProvider);
      _existingEntry = journalState.entries
          .where((entry) => entry.id == widget.journalId)
          .firstOrNull;

      if (_existingEntry != null) {
        _titleController.text = _existingEntry!.title;
        _contentController.text = _existingEntry!.content;
        _selectedMood = _existingEntry!.mood;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading entry: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.journalId != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood Selector
                      Text(
                        'How are you feeling?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMoodSelector(theme),

                      const SizedBox(height: 24),

                      // Title Field
                      Text(
                        'Title',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Give your entry a title...',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          if (value.trim().length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 24),

                      // Content Field
                      Text(
                        'What\'s on your mind?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 12,
                        decoration: const InputDecoration(
                          hintText:
                              'Write about your day, thoughts, or feelings...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter some content';
                          }
                          if (value.trim().length < 10) {
                            return 'Content must be at least 10 characters';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _saveEntry(isEditing),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'Update Entry' : 'Save Entry',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMoodSelector(ThemeData theme) {
    final moods = [
      {'mood': Mood.verySad, 'emoji': '😭', 'label': 'Very Sad'},
      {'mood': Mood.sad, 'emoji': '😢', 'label': 'Sad'},
      {'mood': Mood.neutral, 'emoji': '😐', 'label': 'Neutral'},
      {'mood': Mood.happy, 'emoji': '😊', 'label': 'Happy'},
      {'mood': Mood.veryHappy, 'emoji': '😄', 'label': 'Very Happy'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: moods.map((moodData) {
            final mood = moodData['mood'] as Mood;
            final isSelected = _selectedMood == mood;

            return InkWell(
              onTap: () => setState(() => _selectedMood = mood),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moodData['emoji'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      moodData['label'] as String,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _saveEntry(bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      if (isEditing && _existingEntry != null) {
        final updatedEntry = _existingEntry!.copyWith(
          title: title,
          content: content,
          mood: _selectedMood,
          updatedAt: DateTime.now(),
        );

        await ref.read(journalProvider.notifier).updateEntry(updatedEntry);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry updated successfully')),
          );
        }
      } else {
        final newEntry = JournalEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          content: content,
          mood: _selectedMood,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref.read(journalProvider.notifier).addEntry(newEntry);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry saved successfully')),
          );
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry() async {
    if (_existingEntry == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(journalProvider.notifier).deleteEntry(_existingEntry!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
