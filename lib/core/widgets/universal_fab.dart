import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'universal_quick_add.dart';

/// Universal Floating Action Button that appears on all pages
/// Positioned at bottom-right, opens context-aware quick add modal
class UniversalFAB extends StatefulWidget {
  final QuickAddType type;
  final Function(String) onQuickAdd;

  const UniversalFAB({super.key, required this.type, required this.onQuickAdd});

  @override
  State<UniversalFAB> createState() => _UniversalFABState();
}

class _UniversalFABState extends State<UniversalFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Pulse animation on init
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward().then((_) => _controller.reverse());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  IconData get _icon {
    switch (widget.type) {
      case QuickAddType.task:
        return Icons.add_task_rounded;
      case QuickAddType.event:
        return Icons.event_rounded;
      case QuickAddType.transaction:
        return Icons.add_rounded;
      case QuickAddType.note:
        return Icons.note_add_rounded;
      case QuickAddType.appointment:
        return Icons.add_rounded;
    }
  }

  void _openQuickAdd() {
    HapticFeedback.mediumImpact();
    _controller.forward().then((_) => _controller.reverse());

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => UniversalQuickAddModal(
        type: widget.type,
        onSubmit: widget.onQuickAdd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 90, // Above bottom navigation
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: GestureDetector(
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) => _controller.reverse(),
                onTapCancel: () => _controller.reverse(),
                onTap: _openQuickAdd,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_color, _color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(_icon, color: Colors.white, size: 28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
