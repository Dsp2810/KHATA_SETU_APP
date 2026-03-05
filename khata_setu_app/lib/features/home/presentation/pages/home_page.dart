import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../sync/presentation/widgets/sync_banner.dart';

class HomePage extends StatefulWidget {
  final Widget child;

  const HomePage({super.key, required this.child});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  late AnimationController _rippleController;

  final List<_BottomNavItem> _navItems = const [
    _BottomNavItem(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      labelKey: 'navHome',
      route: RouteConstants.dashboard,
    ),
    _BottomNavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      labelKey: 'navCustomers',
      route: RouteConstants.customers,
    ),
    _BottomNavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      labelKey: 'navLedger',
      route: RouteConstants.ledger,
    ),
    _BottomNavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      labelKey: 'navInventory',
      route: RouteConstants.inventory,
    ),
    _BottomNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      labelKey: 'navSettings',
      route: RouteConstants.settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _indicatorAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeOutCubic,
    ));

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) {
        if (_currentIndex != i) {
          setState(() {
            _currentIndex = i;
          });
        }
        break;
      }
    }
  }

  void _onNavTap(int index) {
    if (_currentIndex != index) {
      final oldIndex = _currentIndex;
      _indicatorAnimation = Tween<double>(
        begin: oldIndex.toDouble(),
        end: index.toDouble(),
      ).animate(CurvedAnimation(
        parent: _indicatorController,
        curve: Curves.easeOutCubic,
      ));
      _indicatorController.forward(from: 0);

      _rippleController.forward(from: 0);
      HapticFeedback.lightImpact();

      setState(() {
        _currentIndex = index;
      });
      context.go(_navItems[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(child: widget.child),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isDark ? 30 : 10,
              sigmaY: isDark ? 30 : 10,
            ),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: context.navColor.withValues(alpha: isDark ? 0.85 : 0.92),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(
                  color: isDark
                      ? context.glassBorderColor.withValues(alpha: 0.3)
                      : AppColors.borderLight.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: context.navShadow,
              ),
              child: Stack(
                children: [
                  // Fluid indicator (subtle top line)
                  AnimatedBuilder(
                    animation: _indicatorAnimation,
                    builder: (context, child) {
                      return _FluidIndicator(
                        position: _indicatorAnimation.value.isNaN
                            ? _currentIndex.toDouble()
                            : _indicatorAnimation.value,
                        itemCount: _navItems.length,
                        isDark: isDark,
                      );
                    },
                  ),
                  // Nav items
                  Row(
                    children: List.generate(_navItems.length, (index) {
                      final isActive = _currentIndex == index;
                      return Expanded(
                        child: _NavItemWidget(
                          item: _navItems[index],
                          isActive: isActive,
                          isDark: isDark,
                          onTap: () => _onNavTap(index),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FluidIndicator extends StatelessWidget {
  final double position;
  final int itemCount;
  final bool isDark;

  const _FluidIndicator({
    required this.position,
    required this.itemCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sectionWidth = constraints.maxWidth / itemCount;
        final left = sectionWidth * position + (sectionWidth - 48) / 2;

        return Positioned(
          top: 0,
          left: left,
          child: Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItemWidget extends StatefulWidget {
  final _BottomNavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isDark ? AppColors.primaryLight : AppColors.primary;
    final inactiveColor = widget.isDark ? AppColors.grey500 : AppColors.grey400;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      widget.isActive ? widget.item.activeIcon : widget.item.icon,
                      key: ValueKey(widget.isActive),
                      size: 24,
                      color: widget.isActive ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                      color: widget.isActive ? activeColor : inactiveColor,
                      letterSpacing: 0.2,
                    ),
                    child: Text(widget.item.localizedLabel(context)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  final String route;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    required this.route,
  });

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (labelKey) {
      case 'navHome': return l10n.navHome;
      case 'navCustomers': return l10n.navCustomers;
      case 'navLedger': return l10n.navLedger;
      case 'navInventory': return l10n.navInventory;
      case 'navSettings': return l10n.navSettings;
      default: return labelKey;
    }
  }
}
