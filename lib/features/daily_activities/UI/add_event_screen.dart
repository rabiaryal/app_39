import 'package:app_039/core/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../viewmodels/events_viewmodel.dart';
import '../../../core/utils.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  final String? eventId;

  const AddEventScreen({super.key, this.eventId});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _categoryFocus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  );
  bool _isLoading = false;
  bool _hasStartedTyping = false;
  Event? _existingEvent;
  String _selectedRepeat = 'None';

  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  final List<Map<String, dynamic>> _repeatOptions = [
    {'value': 'None', 'icon': Icons.event_note},
    {'value': 'Every Day', 'icon': Icons.today},
    {'value': 'Once a Week', 'icon': Icons.date_range},
    {'value': 'Once a Month', 'icon': Icons.calendar_month},
  ];

  List<String> _dynamicCategories = [
    'Work',
    'Personal',
    'Meeting',
    'Health',
    'Education',
    'Travel',
    'Social',
  ];

  String _selectedCategory = '';
  int? _selectedDuration;

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );

    if (widget.eventId != null) {
      _loadExistingEvent();
    }

    // Add listeners for form progress tracking
    _titleController.addListener(() => _updateProgress());
    _descriptionController.addListener(() => _updateProgress());
    _categoryController.addListener(() => _updateProgress());

    // Set default category to the first one
    if (_dynamicCategories.isNotEmpty) {
      _selectedCategory = _dynamicCategories[0];
      _categoryController.text = _selectedCategory;
    }

    // Start fade animation
    _fadeController?.forward();
  }

  void _loadExistingEvent() {
    final eventsState = ref.read(eventsProvider);
    _existingEvent = eventsState.events.firstWhere(
      (e) => e.id == widget.eventId,
    );
    if (_existingEvent != null) {
      _titleController.text = _existingEvent!.title;
      _descriptionController.text = _existingEvent!.description;
      _categoryController.text = _existingEvent!.category ?? '';
      _selectedCategory = _existingEvent!.category ?? '';

      // Add category to dynamic categories if it doesn't exist
      if (_existingEvent!.category != null &&
          _existingEvent!.category!.isNotEmpty &&
          !_dynamicCategories.contains(_existingEvent!.category!)) {
        _dynamicCategories.insert(0, _existingEvent!.category!);
      }

      _selectedDate = _existingEvent!.date;
      _startTime = TimeOfDay.fromDateTime(_existingEvent!.startTime);
      _endTime = _existingEvent!.endTime != null
          ? TimeOfDay.fromDateTime(_existingEvent!.endTime!)
          : null;
      _selectedRepeat = _existingEvent!.repeatType ?? 'None';
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final hasContent =
        _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _categoryController.text.isNotEmpty;

    if (hasContent != _hasStartedTyping) {
      setState(() {
        _hasStartedTyping = hasContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.eventId != null;

    // Calculate form progress
    final totalFields = 4;
    int filledFields = 0;
    if (_titleController.text.isNotEmpty) filledFields++;
    if (_descriptionController.text.isNotEmpty) filledFields++;
    if (_categoryController.text.isNotEmpty) filledFields++;
    if (_selectedDate != DateTime.now() || _startTime != TimeOfDay.now())
      filledFields++;

    final progress = filledFields / totalFields;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Event' : 'Create New Event',
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
                padding: const EdgeInsets.all(16),
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
                        'Plan your events with clear details and timing to stay organized and productive.',
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

                    // Basic Information Section
                    _buildSectionHeader(
                      context,
                      'Event Details',
                      Icons.event_outlined,
                    ),
                    const SizedBox(height: 16),

                    _buildSmartTextField(
                      context: context,
                      controller: _titleController,
                      focusNode: _titleFocus,
                      label: 'Event Title',
                      hint: 'What\'s happening?',
                      icon: Icons.title,
                      isRequired: true,
                      maxLines: 1,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                      onSubmitted: (_) => _descriptionFocus.requestFocus(),
                    ),

                    const SizedBox(height: 20),

                    _buildSmartTextField(
                      context: context,
                      controller: _descriptionController,
                      focusNode: _descriptionFocus,
                      label: 'Description (Optional)',
                      hint: 'Add more details about this event...',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      onSubmitted: (_) => _categoryFocus.requestFocus(),
                    ),

                    const SizedBox(height: 32),

                    // Date & Time Section
                    _buildSectionHeader(
                      context,
                      'Date & Time',
                      Icons.schedule_outlined,
                    ),
                    const SizedBox(height: 16),

                    _buildDateTimeSection(context),

                    const SizedBox(height: 32),

                    // Repeat Section
                    _buildSectionHeader(
                      context,
                      'Repeat Event',
                      Icons.repeat_outlined,
                    ),
                    const SizedBox(height: 16),

                    _buildRepeatSection(context),

                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: _buildSaveButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
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
              setState(() {
                _selectedCategory = category;
                _categoryController.text = category;
              });
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
                  setState(() {
                    _dynamicCategories.insert(
                      0,
                      newCategory,
                    ); // Add at first position
                    _selectedCategory = newCategory;
                    _categoryController.text = newCategory;
                  });
                  Navigator.of(context).pop();
                } else if (_dynamicCategories.contains(newCategory)) {
                  // Show snackbar for duplicate
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
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
      ),
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildDateTimeItem(
            context,
            Icons.calendar_today,
            'Date',
            DateTimeUtils.formatDate(_selectedDate),
            _selectDate,
          ),
          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
          _buildDateTimeItem(
            context,
            Icons.access_time,
            'Start Time',
            _startTime.format(context),
            () => _selectTime(true),
          ),
          // Duration Tags Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Duration',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDurationTags(context),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
          _buildDateTimeItem(
            context,
            Icons.access_time_filled,
            'End Time',
            _endTime != null
                ? _getEndTimeDisplayText(_endTime!)
                : 'No end time',
            () => _selectTime(false),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationTags(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final durations = [1, 2, 3, 4, 5]; // Hours

    return Row(
      children: durations.map((hours) {
        final isSelected = _selectedDuration == hours;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => _setDuration(hours),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.3)
                        : colorScheme.outline.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$hours',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      hours == 1 ? 'hour' : 'hours',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }

  Widget _buildRepeatSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: _repeatOptions.map((repeat) {
          final isSelected = _selectedRepeat == repeat['value'];
          final isLast = repeat == _repeatOptions.last;
          return GestureDetector(
            onTap: () => setState(() => _selectedRepeat = repeat['value']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Icon(
                    repeat['icon'],
                    size: 20,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      repeat['value'],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.eventId != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveEvent,
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
                      isEditing ? 'Update Event' : 'Create Event',
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : (_endTime ?? _startTime),
    );
    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
          // Reset selected duration when start time changes manually
          _selectedDuration = null;
          // Auto-adjust end time if it's before start time (only if endTime is set)
          if (_endTime != null &&
              (_endTime!.hour < _startTime.hour ||
                  (_endTime!.hour == _startTime.hour &&
                      _endTime!.minute <= _startTime.minute))) {
            // Add one hour to start time as default
            final startMinutes = _startTime.hour * 60 + _startTime.minute;
            final endMinutes = startMinutes + 60; // Add 1 hour
            _endTime = TimeOfDay(
              hour: (endMinutes ~/ 60) % 24,
              minute: endMinutes % 60,
            );
          }
        } else {
          _endTime = time;
          // Reset selected duration when end time changes manually
          _selectedDuration = null;
        }
      });
    }
  }

  void _setDuration(int hours) {
    setState(() {
      // Track selected duration
      _selectedDuration = hours;

      // Calculate end time based on start time + duration
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = startMinutes + (hours * 60);

      // Handle day overflow properly
      final endHour = (endMinutes ~/ 60) % 24;
      final endMinute = endMinutes % 60;

      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }

  String _getEndTimeDisplayText(TimeOfDay endTime) {
    final endTimeText = endTime.format(context);

    // Check if end time spans to next day
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      return '$endTimeText +1 day';
    }

    return endTimeText;
  }

  Future<void> _saveEvent() async {
    print("save evetns called");
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Create event object for validation
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    DateTime? endDateTime;
    if (_endTime != null) {
      endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // If end time is before start time, it means the event spans to the next day
      if (endDateTime.isBefore(startDateTime) ||
          endDateTime.isAtSameMomentAs(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
    }

    // No need for additional validation since we handle midnight spanning above

    try {
      final event = Event(
        id:
            _existingEvent?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        priority: null, // Priority removed from UI
        repeatType: _selectedRepeat,
        createdAt: _existingEvent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_existingEvent != null) {
        await ref.read(eventsProvider.notifier).updateEvent(event);
      } else {
        await ref.read(eventsProvider.notifier).addEvent(event);
      }

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(
          context,
          _existingEvent != null
              ? 'Event updated successfully'
              : 'Event created successfully',
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
