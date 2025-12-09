import 'package:app_039/core/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../viewmodels/notes_viewmodel.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const AddNoteScreen({super.key, this.noteId});

  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();

  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();
  final _categoryFocus = FocusNode();

  bool _isLoading = false;
  bool _hasStartedTyping = false;
  Note? _existingNote;

  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  List<String> _dynamicCategories = [
    'Work',
    'Personal',
    'Ideas',
    'Project',
    'Meeting',
    'Research',
    'Learning',
    'Todo',
  ];

  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController!, curve: Curves.easeIn));

    if (widget.noteId != null) {
      _loadExistingNote();
    } else {
      _fadeController!.forward();
    }

    // Listen for typing to show progress
    _titleController.addListener(_updateProgress);
    _contentController.addListener(_updateProgress);
    _categoryController.addListener(_updateProgress);

    // Auto-focus title when creating new note
    if (widget.noteId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  Future<void> _loadExistingNote() async {
    try {
      final notesState = ref.read(notesProvider);
      _existingNote = notesState.notes.firstWhere((n) => n.id == widget.noteId);

      _titleController.text = _existingNote!.title;
      _contentController.text = _existingNote!.content;
      _categoryController.text = _existingNote!.category ?? '';
      _selectedCategory = _existingNote!.category ?? '';

      // Add category to dynamic categories if it doesn't exist
      if (_existingNote!.category != null &&
          _existingNote!.category!.isNotEmpty &&
          !_dynamicCategories.contains(_existingNote!.category!)) {
        _dynamicCategories.insert(0, _existingNote!.category!);
      }

      _fadeController!.forward();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to load note');
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final hasContent =
        _titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty ||
        _categoryController.text.isNotEmpty;

    if (hasContent != _hasStartedTyping && mounted) {
      setState(() {
        _hasStartedTyping = hasContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.noteId != null;

    // Calculate form progress
    final totalFields = 3;
    int filledFields = 0;
    if (_titleController.text.isNotEmpty) filledFields++;
    if (_contentController.text.isNotEmpty) filledFields++;
    if (_categoryController.text.isNotEmpty) filledFields++;

    final progress = filledFields / totalFields;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Note' : 'Create New Note',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
        child: Column(
          children: [
            // Progress indicator
            if (_hasStartedTyping)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

            // Helpful tip
            if (!_hasStartedTyping)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Capture your thoughts, ideas, and important information to organize your mind and boost productivity.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 8),

                    // Quick Category Selection
                    _buildSectionHeader(
                      context,
                      'Quick Categories',
                      Icons.category_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryChips(context),
                    const SizedBox(height: 24),

                    // Note Details Section
                    _buildSectionHeader(
                      context,
                      'Note Details',
                      Icons.note_outlined,
                    ),
                    const SizedBox(height: 16),

                    _buildSmartTextField(
                      context: context,
                      controller: _titleController,
                      focusNode: _titleFocus,
                      label: 'Note Title',
                      hint: 'What\'s this note about?',
                      icon: Icons.title,
                      isRequired: true,
                      maxLines: 1,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter a note title';
                        }
                        return null;
                      },
                      onSubmitted: (_) => _contentFocus.requestFocus(),
                    ),

                    const SizedBox(height: 20),

                    _buildSmartTextField(
                      context: context,
                      controller: _contentController,
                      focusNode: _contentFocus,
                      label: 'Content',
                      hint:
                          'Write your thoughts, ideas, or information here...',
                      icon: Icons.description_outlined,
                      maxLines: 8,
                      isRequired: true,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter some content';
                        }
                        return null;
                      },
                      onSubmitted: (_) => _categoryFocus.requestFocus(),
                    ),

                    const SizedBox(height: 32),

                    const SizedBox(height: 100), // Space for save button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildSaveButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.noteId != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveNote,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: _isLoading ? 0 : 3,
            shadowColor: colorScheme.primary.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onPrimary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEditing ? Icons.save : Icons.add, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Update Note' : 'Create Note',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Dynamic category chips
        ..._dynamicCategories.map((category) {
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  _selectedCategory = category;
                  _categoryController.text = category;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
        // Add new category button
        GestureDetector(
          onTap: () => _showAddCategoryDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.primary, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Add',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add New Category',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: categoryController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newCategory = categoryController.text.trim();
                if (newCategory.isNotEmpty &&
                    !_dynamicCategories.contains(newCategory)) {
                  if (mounted) {
                    setState(() {
                      _dynamicCategories.insert(0, newCategory);
                      _selectedCategory = newCategory;
                      _categoryController.text = newCategory;
                    });
                  }
                  Navigator.of(context).pop();
                } else if (_dynamicCategories.contains(newCategory)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category "$newCategory" already exists'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmartTextField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: colorScheme.primary),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.error, width: 1),
            ),
            labelStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
          onFieldSubmitted: onSubmitted,
        ),
      ],
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final note = Note(
        id:
            _existingNote?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        status: NoteStatus.active,
        tags: [], // Can be extended later
        isPinned: false,
        date: DateTime.now(),
        createdAt: _existingNote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_existingNote != null) {
        await ref.read(notesProvider.notifier).updateNote(note);
      } else {
        await ref.read(notesProvider.notifier).addNote(note);
      }

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(
          context,
          _existingNote != null
              ? 'Note updated successfully'
              : 'Note created successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
