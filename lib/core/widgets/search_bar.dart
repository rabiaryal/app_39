import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void show() {
    setState(() {
      _isVisible = true;
    });
    _animationController.forward();
  }

  void hide() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                          widget.onClear?.call();
                        },
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: hide,
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Extension to easily add search functionality to screens
class SearchableScreen extends StatefulWidget {
  final Widget child;
  final String searchHint;
  final Function(String) onSearch;

  const SearchableScreen({
    super.key,
    required this.child,
    required this.searchHint,
    required this.onSearch,
  });

  @override
  State<SearchableScreen> createState() => _SearchableScreenState();
}

class _SearchableScreenState extends State<SearchableScreen> {
  final GlobalKey<_AppSearchBarState> _searchKey = GlobalKey();

  void showSearch() {
    _searchKey.currentState?.show();
  }

  void hideSearch() {
    _searchKey.currentState?.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppSearchBar(
            key: _searchKey,
            hintText: widget.searchHint,
            onChanged: widget.onSearch,
            autofocus: true,
          ),
        ),
      ],
    );
  }
}
