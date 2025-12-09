import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global keyboard shortcuts handler
/// Ctrl/Cmd + N: Quick add
/// Ctrl/Cmd + F: Search
/// Ctrl/Cmd + /: Show shortcuts help
class KeyboardShortcutsHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onQuickAdd;
  final VoidCallback? onSearch;
  final VoidCallback? onShowHelp;

  const KeyboardShortcutsHandler({
    super.key,
    required this.child,
    this.onQuickAdd,
    this.onSearch,
    this.onShowHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Ctrl/Cmd + N: Quick Add
          if ((HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed) &&
              event.logicalKey == LogicalKeyboardKey.keyN) {
            onQuickAdd?.call();
            return KeyEventResult.handled;
          }

          // Ctrl/Cmd + F: Search
          if ((HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed) &&
              event.logicalKey == LogicalKeyboardKey.keyF) {
            onSearch?.call();
            return KeyEventResult.handled;
          }

          // Ctrl/Cmd + /: Show shortcuts help
          if ((HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed) &&
              event.logicalKey == LogicalKeyboardKey.slash) {
            onShowHelp?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Shows keyboard shortcuts help dialog
void showKeyboardShortcutsHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard_rounded, size: 24),
          SizedBox(width: 12),
          Text('Keyboard Shortcuts'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShortcutSection('Global', [
              _ShortcutItem('Ctrl/Cmd + N', 'Quick Add'),
              _ShortcutItem('Ctrl/Cmd + F', 'Search'),
              _ShortcutItem('Ctrl/Cmd + /', 'Show Shortcuts'),
              _ShortcutItem('Esc', 'Close Modal'),
              _ShortcutItem('Enter', 'Submit/Open'),
            ]),
            const SizedBox(height: 16),
            _buildShortcutSection('Tasks', [
              _ShortcutItem('Space', 'Toggle Complete'),
              _ShortcutItem('D', 'Delete'),
              _ShortcutItem('E', 'Edit'),
              _ShortcutItem('1/2/3', 'Set Priority'),
            ]),
            const SizedBox(height: 16),
            _buildShortcutSection('Navigation', [
              _ShortcutItem('↑/↓', 'Navigate List'),
              _ShortcutItem('Tab', 'Next Item'),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

Widget _buildShortcutSection(String title, List<_ShortcutItem> shortcuts) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      ...shortcuts.map(
        (shortcut) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Text(
                  shortcut.key,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shortcut.description,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ShortcutItem {
  final String key;
  final String description;

  _ShortcutItem(this.key, this.description);
}
