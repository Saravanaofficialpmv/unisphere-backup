import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unisphere/core/constants/app_colors.dart';

/// Floating capsule navigation dock for the Head of Department (HOD) Portal,
/// styled with the signature Unisphere Frosted Glass & Royal Indigo Blue Design System.
///
/// Destinations:
/// 1. Home (Home icon -> switches to HOD Operations Command Center)
/// 2. Staff (Badge icon -> switches to Faculty & Staff Directory)
/// 3. Students (School cap icon -> switches to Student Management)
/// 4. Reports (Insights icon -> switches to Reports & Academic Analytics)
/// 5. Logout (Logout icon -> triggers Sign Out confirmation sheet)
class HodFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isVisible;
  final VoidCallback onHomeTap;
  final VoidCallback onStaffTap;
  final VoidCallback onStudentsTap;
  final VoidCallback onReportsTap;
  final VoidCallback onLogoutTap;

  const HodFloatingNavBar({
    super.key,
    required this.currentIndex,
    this.isVisible = true,
    required this.onHomeTap,
    required this.onStaffTap,
    required this.onStudentsTap,
    required this.onReportsTap,
    required this.onLogoutTap,
  });

  /// Map the overall HOD dashboard index to the floating nav bar active slot.
  /// Slot 0: Home (index 0)
  /// Slot 1: Staff (index 3)
  /// Slot 2: Students (index 4 or 5)
  /// Slot 3: Reports (index 10)
  /// Slot 4: Logout (action button, no persistent active indicator)
  int get _activeSlot {
    if (currentIndex == 0) return 0;
    if (currentIndex == 3) return 1;
    if (currentIndex == 4 || currentIndex == 5) return 2;
    if (currentIndex == 10) return 3;
    return -1; // If viewing an inner drawer module or settings, no capsule indicator is active
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
            label: 'HOD Navigation Dock',
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
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 16,
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
                        Colors.white.withValues(alpha: 0.76),
                        Colors.white.withValues(alpha: 0.52),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.80),
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
                                : (0 * slotWidth) + ((slotWidth - itemWidth) / 2),
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
                                      AppColors.primaryLight, // Electric Light Blue
                                      AppColors.primary, // Brand Royal Blue
                                      AppColors.primaryDark, // Deep Navy Blue
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(itemHeight / 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.38),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Navigation Item Icons (Order: Home, Staff, Students, Reports, Settings)
                          Row(
                            children: [
                              // 1. Home
                              Expanded(
                                child: _NavBarItem(
                                  imageAsset: 'assets/home-3.png',
                                  icon: Icons.home_rounded,
                                  tooltip: 'Home',
                                  isActive: activeSlot == 0,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onHomeTap();
                                  },
                                ),
                              ),

                              // 2. Staff
                              Expanded(
                                child: _NavBarItem(
                                  icon: Icons.badge_rounded,
                                  tooltip: 'Staff',
                                  isActive: activeSlot == 1,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onStaffTap();
                                  },
                                ),
                              ),

                              // 3. Students
                              Expanded(
                                child: _NavBarItem(
                                  icon: Icons.school_rounded,
                                  tooltip: 'Students',
                                  isActive: activeSlot == 2,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onStudentsTap();
                                  },
                                ),
                              ),

                              // 4. Reports
                              Expanded(
                                child: _NavBarItem(
                                  icon: Icons.insights_rounded,
                                  tooltip: 'Reports',
                                  isActive: activeSlot == 3,
                                  itemSize: itemSize,
                                  iconSize: 24.0,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onReportsTap();
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
    this.itemSize = 44.0,
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
          widget.icon ?? Icons.circle,
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
    final effectiveInactiveColor = widget.inactiveColor ?? AppColors.textSecondary;

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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtly embedded label for semantic finders
                      Opacity(
                        opacity: 0.0,
                        child: Text(
                          widget.tooltip,
                          style: const TextStyle(fontSize: 1),
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: widget.isActive
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: _buildIcon(Colors.white),
                        secondChild: _buildIcon(effectiveInactiveColor),
                      ),
                    ],
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
