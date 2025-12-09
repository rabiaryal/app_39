import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_text_style.dart';

/// Universal Quick Add Modal that adapts to current page context
class UniversalQuickAddModal extends ConsumerStatefulWidget {
  final QuickAddType type;
  final Function(String) onSubmit;

  const UniversalQuickAddModal({
    super.key,
    required this.type,
    required this.onSubmit,
  });

  @override
  ConsumerState<UniversalQuickAddModal> createState() =>
      _UniversalQuickAddModalState();
}

class _UniversalQuickAddModalState
    extends ConsumerState<UniversalQuickAddModal> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _placeholder {
    switch (widget.type) {
      case QuickAddType.task:
        return 'Add a task... (e.g., "Call dentist")';
      case QuickAddType.event:
        return 'Add an event... (e.g., "Meeting tomorrow 3pm")';
      case QuickAddType.transaction:
        return 'Add transaction... (e.g., "Coffee \$5.50")';
      case QuickAddType.note:
        return 'Add a note... (e.g., "Meeting notes")';
      case QuickAddType.appointment:
        return 'Add appointment... (e.g., "Doctor Oct 15 2pm")';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case QuickAddType.task:
        return Icons.task_alt_rounded;
      case QuickAddType.event:
        return Icons.event_rounded;
      case QuickAddType.transaction:
        return Icons.account_balance_wallet_rounded;
      case QuickAddType.note:
        return Icons.sticky_note_2_rounded;
      case QuickAddType.appointment:
        return Icons.calendar_today_rounded;
    }
  }

  Color get _color {
    switch (widget.type) {
      case QuickAddType.task:
        return Colors.orange;
      case QuickAddType.event:
        return Colors.purple;
      case QuickAddType.transaction:
        return Colors.green;
      case QuickAddType.note:
        return Colors.pink;
      case QuickAddType.appointment:
        return Colors.blue;
    }
  }

  void _handleSubmit() {
    if (_controller.text.trim().isEmpty) return;

    HapticFeedback.mediumImpact();
    widget.onSubmit(_controller.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleSubmit();
          }
        }
      },
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping modal
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _color.withOpacity(0.1),
                            _color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_icon, color: _color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Quick Add ${widget.type.name.capitalize()}',
                              style: AppTextStyles.of(context).headline3,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Input
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: AppTextStyles.of(context).body1,
                            maxLines: widget.type == QuickAddType.note ? 5 : 1,
                            decoration: InputDecoration(
                              hintText: _placeholder,
                              hintStyle: AppTextStyles.of(context).hint,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _color, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onSubmitted: (_) => _handleSubmit(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Press Enter to add • Esc to cancel',
                            style: AppTextStyles.of(
                              context,
                            ).caption.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.of(context).button,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: _color,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Add ${widget.type.name.capitalize()}',
                                style: AppTextStyles.of(context).button
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum QuickAddType { task, event, transaction, note, appointment }

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
