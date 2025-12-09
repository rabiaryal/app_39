import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/dashboard.dart';
import '../../features/daily_activities/UI/events_screen.dart';
import '../../features/journal/screens/journal_home_page.dart';
import '../../features/notes/UI/notes_screen.dart';

// Provider to manage current tab index
final currentTabProvider = StateProvider<int>((ref) => 0);

class PersistentNavigation extends ConsumerStatefulWidget {
  const PersistentNavigation({super.key});

  @override
  ConsumerState<PersistentNavigation> createState() =>
      _PersistentNavigationState();
}

class _PersistentNavigationState extends ConsumerState<PersistentNavigation> {
  late PageController _pageController;
  bool _isPageChanging = false; // Flag to prevent conflicts

  // Keep screens in memory to avoid rebuilding
  final List<Widget> _screens = const [
    OptimizedDashboardScreen(),
    EventsScreen(),
    JournalHistoryScreen(),
    NotesScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.event, 'Events'),
    _NavItem(Icons.book, 'Journal'),
    _NavItem(Icons.note, 'Notes'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        onPageChanged: (index) {
          if (!_isPageChanging) {
            ref.read(currentTabProvider.notifier).state = index;
            HapticFeedback.selectionClick();
          }
        },
        itemCount: _screens.length,
        itemBuilder: (context, index) {
          return _screens[index];
        },
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        height: 58,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            _navItems.length,
            (index) => _buildNavItem(index, currentTab, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, int currentTab, bool isDark) {
    final isSelected = currentTab == index;
    final item = _navItems[index];
    final color = isSelected
        ? (isDark ? Colors.tealAccent : Colors.blue)
        : (isDark ? Colors.grey[500] : Colors.grey[600]);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateTo(index),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: 22),
                if (isSelected) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(int index) {
    if (index < 0 || index >= _screens.length) return;

    // Update the tab state immediately for instant color change
    ref.read(currentTabProvider.notifier).state = index;

    _isPageChanging = true;
    HapticFeedback.selectionClick();
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          _isPageChanging = false;
        });
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}
