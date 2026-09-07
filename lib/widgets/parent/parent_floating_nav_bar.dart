import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unisphere/core/constants/app_colors.dart';

/// Floating capsule navigation bar for the Parent Panel,
/// styled with the Unisphere Frosted Glass & Royal Blue Design System.
///
/// Order:
/// 1. More (Application icon -> opens navigation launcher sheet)
/// 2. Attendance (Calendar icon -> switches to Attendance History)
/// 3. Home (Home icon -> switches to Dashboard Home)
/// 4. Profile (Person icon -> switches to Parent Profile)
/// 5. Logout (Logout icon -> prompts sign-out confirmation sheet)
class ParentFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isMenuOpen;
  final bool isVisible;
  final VoidCallback onSidebarTap;
  final VoidCallback onAttendanceTap;
  final VoidCallback onHomeTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const ParentFloatingNavBar({
    super.key,
    required this.currentIndex,
    this.isMenuOpen = false,
    this.isVisible = true,
    required this.onSidebarTap,
    required this.onAttendanceTap,
    required this.onHomeTap,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  /// Map the overall parent dashboard index to the floating nav bar active slot.
  /// Slot 0: More (action / sub-modules)
  /// Slot 1: Attendance (index 1)
  /// Slot 2: Home (index 0)
  /// Slot 3: Profile (index 4)
  /// Slot 4: Logout (action)
  int get _activeSlot {
    if (isMenuOpen) return 0;
    if (currentIndex == 1) return 1;
    if (currentIndex == 0) return 2;
    if (currentIndex == 4) return 3;
    return 0; // Highlight Menu when any other module is active
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double barWidth = math.min(352.0, screenWidth - 32.0);
    const double barHeight = 68.0;
    const double itemSize = 44.0;
    const double horizontalPadding = 8.0;
    const double verticalPadding = 6.0;

    final activeSlot = _activeSlot;
    final bool hasActiveSlot = activeSlot >= 0;

    return RepaintBoundary(
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, 1.35),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: isVisible ? 1.0 : 0.0,
          child: Semantics(
            label: 'Parent Navigation Dock',
            child: Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  // Deep ambient glass shadow
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                  // Soft indigo tinted glow
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: kIsWeb ? 10 : 24,
                    sigmaY: kIsWeb ? 10 : 24,
                  ),
                child: Container(
                  decoration: BoxDecoration(
                    // Authentic Translucent Glassmorphism Gradient Surface
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.48),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double availableWidth = constraints.maxWidth;
                      final double slotWidth = availableWidth / 5;
                      final double availableHeight = constraints.maxHeight;
                      final double itemWidth = math.min(slotWidth - 8.0, 54.0);
                      const double itemHeight = 44.0;
                      final double topOffset = (availableHeight - itemHeight) / 2;

                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Animated sliding active Royal Blue capsule indicator with soft glow
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOutCubic,
                            left: hasActiveSlot
                                ? (activeSlot * slotWidth) + ((slotWidth - itemWidth) / 2)
                                : (2 * slotWidth) + ((slotWidth - itemWidth) / 2),
                            top: topOffset,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: hasActiveSlot ? 1.0 : 0.0,
                              child: Container(
                                width: itemWidth,
                                height: itemHeight,
                                decoration: BoxDecoration(
                                  // Crisp Royal Blue Gradient Capsule Indicator
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6), // Electric Light Blue
                                      Color(0xFF2563EB), // Brand Royal Blue
                                      Color(0xFF1D4ED8), // Deep Navy Blue
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(itemHeight / 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.38),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Navigation Item Icons (Order: More, Attendance, Home, Profile, Logout)
                          Row(
                            children: [
                              // 1. More (Application icon)
                              Expanded(
                                child: _NavBarItem(
                                  imageAsset: 'assets/application.png',
                                  icon: Icons.grid_view_rounded,
                                  tooltip: 'More Modules & Services',
                                  isActive: activeSlot == 0,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onSidebarTap();
                                  },
                                ),
                              ),

                              // 2. Attendance (Calendar icon)
                              Expanded(
                                child: _NavBarItem(
                                  imageAsset: 'assets/calendar-2.png',
                                  icon: Icons.calendar_month_outlined,
                                  tooltip: 'Attendance History',
                                  isActive: activeSlot == 1,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onAttendanceTap();
                                  },
                                ),
                              ),

                              // 3. Home (Home icon)
                              Expanded(
                                child: _NavBarItem(
                                  imageAsset: 'assets/home-3.png',
                                  icon: Icons.dashboard_rounded,
                                  tooltip: 'Dashboard Home',
                                  isActive: activeSlot == 2,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onHomeTap();
                                  },
                                ),
                              ),

                              // 4. Profile (Person icon)
                              Expanded(
                                child: _NavBarItem(
                                  imageAsset: 'assets/avatar.png',
                                  icon: Icons.person_outline_rounded,
                                  tooltip: 'Parent Profile',
                                  isActive: activeSlot == 3,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onProfileTap();
                                  },
                                ),
                              ),

                              // 5. Logout (Sign out icon)
                              Expanded(
                                child: _NavBarItem(
                                  imageAsset: 'assets/logout.png',
                                  icon: Icons.logout_rounded,
                                  tooltip: 'Sign Out',
                                  isActive: false,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  inactiveColor: AppColors.error.withValues(alpha: 0.85),
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    onLogoutTap();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData? icon;
  final String? imageAsset;
  final String tooltip;
  final bool isActive;
  final Color? inactiveColor;
  final double itemSize;
  final double iconSize;
  final VoidCallback onTap;

  const _NavBarItem({
    this.icon,
    this.imageAsset,
    required this.tooltip,
    required this.isActive,
    this.inactiveColor,
    this.itemSize = 46.0,
    this.iconSize = 22.0,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.12,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(Color color) {
    if (widget.imageAsset != null) {
      return Image.asset(
        widget.imageAsset!,
        width: widget.iconSize,
        height: widget.iconSize,
        fit: BoxFit.contain,
        color: color,
        errorBuilder: (_, __, ___) => Icon(
          widget.icon ?? Icons.grid_view_rounded,
          size: widget.iconSize,
          color: color,
        ),
      );
    }
    return Icon(
      widget.icon ?? Icons.circle,
      size: widget.iconSize,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Default inactive color: Slate 600
    final effectiveInactiveColor = widget.inactiveColor ?? const Color(0xFF64748B);

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Center(
              child: SizedBox(
                width: widget.itemSize,
                height: widget.itemSize,
                child: Center(
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: widget.isActive
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _buildIcon(Colors.white), // Pure white icon on Royal Blue active capsule
                    secondChild: _buildIcon(effectiveInactiveColor), // Slate gray / Coral red when inactive
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
