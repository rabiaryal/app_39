import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/router.dart';
import '../../core/theme.dart';

class CommonBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final bool isScrolled;

  const CommonBottomNavigation({
    super.key,
    required this.currentIndex,
    this.isScrolled = false,
  });

  @override
  State<CommonBottomNavigation> createState() => _CommonBottomNavigationState();
}

class _CommonBottomNavigationState extends State<CommonBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconScaleAnimations;
  late List<Animation<double>> _iconRotationAnimations;
  late List<AnimationController> _backgroundControllers;
  late List<Animation<double>> _backgroundAnimations;
  late List<AnimationController> _labelControllers;
  late List<Animation<Offset>> _labelSlideAnimations;
  late List<Animation<double>> _labelFadeAnimations;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  int _lastTappedIndex = -1;
  bool _isPressed = false;

  final List<NavItem> _navItems = [
    NavItem(
      Icons.dashboard_outlined,
      Icons.dashboard_rounded,
      'Dashboard',
      Colors.blue,
    ),
    NavItem(Icons.event_outlined, Icons.event_rounded, 'Events', Colors.purple),
    NavItem(
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
      'Finance',
      Colors.green,
    ),
    NavItem(
      Icons.sticky_note_2_outlined,
      Icons.sticky_note_2_rounded,
      'Notes',
      Colors.pink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialAnimations();
  }

  void _initializeAnimations() {
    // Icon animations
    _iconControllers = List.generate(
      _navItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _iconScaleAnimations = _iconControllers
        .map(
          (controller) => Tween<double>(begin: 1.0, end: 1.3).animate(
            CurvedAnimation(parent: controller, curve: Curves.elasticOut),
          ),
        )
        .toList();

    _iconRotationAnimations = _iconControllers
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 0.1).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();

    // Background animations
    _backgroundControllers = List.generate(
      _navItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 350),
        vsync: this,
      ),
    );

    _backgroundAnimations = _backgroundControllers
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
          ),
        )
        .toList();

    // Label animations
    _labelControllers = List.generate(
      _navItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _labelSlideAnimations = _labelControllers
        .map(
          (controller) =>
              Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
              ),
        )
        .toList();

    _labelFadeAnimations = _labelControllers
        .map(
          (controller) => Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
        )
        .toList();

    // Ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Floating animation for the entire nav bar
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  void _startInitialAnimations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateActiveItem(widget.currentIndex);
      _floatingController.repeat(reverse: true);
    });
  }

  void _updateActiveItem(int index) {
    for (int i = 0; i < _navItems.length; i++) {
      if (i == index) {
        _iconControllers[i].forward();
        _backgroundControllers[i].forward();
        _labelControllers[i].forward();
      } else {
        _iconControllers[i].reverse();
        _backgroundControllers[i].reverse();
        _labelControllers[i].reverse();
      }
    }
  }

  @override
  void didUpdateWidget(CommonBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _updateActiveItem(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    for (var controller in _iconControllers) controller.dispose();
    for (var controller in _backgroundControllers) controller.dispose();
    for (var controller in _labelControllers) controller.dispose();
    _rippleController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              left: 20,
              right: 20,
            ),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: _getEnhancedShadows(isDark),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _getBackgroundGradient(isDark),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        _buildGlowingBackground(isDark),
                        _buildRippleEffect(screenWidth, isDark),
                        _buildNavItems(screenWidth),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowingBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isDark ? Colors.cyan : Colors.blue).withOpacity(0.05),
              (isDark ? Colors.purple : Colors.purple).withOpacity(0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRippleEffect(double screenWidth, bool isDark) {
    if (_lastTappedIndex == -1) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        final itemWidth = (screenWidth - 40) / 4;
        final rippleSize = 60 * _rippleAnimation.value;

        return Positioned(
          left:
              (_lastTappedIndex * itemWidth) +
              (itemWidth / 2) -
              (rippleSize / 2),
          top: 40 - (rippleSize / 2),
          child: Container(
            width: rippleSize,
            height: rippleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _navItems[_lastTappedIndex].color.withOpacity(
                    0.3 * (1 - _rippleAnimation.value),
                  ),
                  _navItems[_lastTappedIndex].color.withOpacity(
                    0.1 * (1 - _rippleAnimation.value),
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItems(double screenWidth) {
    return Row(
      children: List.generate(_navItems.length, (index) {
        final isSelected = widget.currentIndex == index;
        return Expanded(
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () => _onNavItemTap(index),
            child: AnimatedScale(
              scale: _isPressed && isSelected ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: _buildNavItem(index, isSelected),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavItem(int index, bool isSelected) {
    final navItem = _navItems[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _iconScaleAnimations[index],
        _iconRotationAnimations[index],
        _backgroundAnimations[index],
        _labelSlideAnimations[index],
        _labelFadeAnimations[index],
      ]),
      builder: (context, child) {
        return Container(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with background
              Stack(
                alignment: Alignment.center,
                children: [
                  // Animated background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? RadialGradient(
                              colors: [
                                navItem.color.withOpacity(
                                  0.2 * _backgroundAnimations[index].value,
                                ),
                                navItem.color.withOpacity(
                                  0.05 * _backgroundAnimations[index].value,
                                ),
                              ],
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: navItem.color.withOpacity(
                                  0.3 * _backgroundAnimations[index].value,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  // Icon
                  Transform.scale(
                    scale: _iconScaleAnimations[index].value,
                    child: Transform.rotate(
                      angle: _iconRotationAnimations[index].value,
                      child: Icon(
                        isSelected
                            ? navItem.selectedIcon
                            : navItem.unselectedIcon,
                        color: isSelected
                            ? navItem.color
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Label with slide animation
              ClipRect(
                child: SlideTransition(
                  position: _labelSlideAnimations[index],
                  child: FadeTransition(
                    opacity: _labelFadeAnimations[index],
                    child: Text(
                      navItem.label,
                      style: TextStyle(
                        color: isSelected ? navItem.color : Colors.transparent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 2),

              // Active indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 6 : 0,
                height: isSelected ? 6 : 0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? RadialGradient(
                          colors: [
                            navItem.color,
                            navItem.color.withOpacity(0.5),
                          ],
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: navItem.color.withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LinearGradient _getBackgroundGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[900]!.withOpacity(0.9),
          Colors.grey[850]!.withOpacity(0.8),
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.grey[50]!.withOpacity(0.8),
        ],
      );
    }
  }

  List<BoxShadow> _getEnhancedShadows(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.8)
            : Colors.grey.withOpacity(0.15),
        blurRadius: 30,
        offset: const Offset(0, 10),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: isDark
            ? Colors.cyan.withOpacity(0.1)
            : Colors.blue.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 5),
        spreadRadius: -5,
      ),
    ];
  }

  void _onNavItemTap(int index) {
    if (index == widget.currentIndex) return;

    HapticFeedback.mediumImpact();

    // Start ripple effect
    _lastTappedIndex = index;
    _rippleController.reset();
    _rippleController.forward();

    // Update animations
    _updateActiveItem(index);

    // Navigation logic
    switch (index) {
      case 0:
        AppNavigation.goToDashboard(context);
        break;
      case 1:
        AppNavigation.goToEvents(context);
        break;
      case 2:
        AppNavigation.goToJournal(context);
        break;
      case 3:
        AppNavigation.goToNotes(context);
        break;
    }
  }
}

class NavItem {
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final String label;
  final Color color;

  NavItem(this.unselectedIcon, this.selectedIcon, this.label, this.color);
}
