import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Navigation slots for the Unisphere Bottom Navigation Bar.
enum UnisphereNavSlot {
  home,
  classes,
  center,
  notifications,
  profile,
}

/// Ultra-Modern Frosted Glass Floating Capsule Bottom Navigation Bar
/// designed according to the Unisphere iOS / Modern Design System.
///
/// Features:
/// 1. Home tab with frosted card container & active glowing dot
/// 2. Classes / Schedule tab with checklist icon
/// 3. Center elevated glowing circular Unisphere "U" action button
/// 4. Notifications tab with unread count red badge dot
/// 5. Profile tab with user outline icon
class UnisphereBottomNavBar extends StatelessWidget {
  final UnisphereNavSlot activeSlot;
  final bool isVisible;
  final int unreadNotificationsCount;
  final String classesLabel;
  final IconData? classesIcon;
  final IconData? classesActiveIcon;
  final Color? activeColor;
  final VoidCallback onHomeTap;
  final VoidCallback onClassesTap;
  final VoidCallback onCenterTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const UnisphereBottomNavBar({
    super.key,
    required this.activeSlot,
    this.isVisible = true,
    this.unreadNotificationsCount = 0,
    this.classesLabel = 'Classes',
    this.classesIcon,
    this.classesActiveIcon,
    this.activeColor,
    required this.onHomeTap,
    required this.onClassesTap,
    required this.onCenterTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double barWidth = math.min(390.0, screenWidth - 24.0);
    const double barHeight = 72.0;
    final primaryActiveColor = activeColor ?? const Color(0xFF2563EB);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1.4),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            boxShadow: [
              // Ambient soft glass shadow
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              // Electric blue subtle glow
              BoxShadow(
                color: primaryActiveColor.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  // Translucent ice-blue frosted glass surface
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.92),
                      const Color(0xFFEFF6FF).withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  children: [
                    // 1. Home
                    Expanded(
                      child: _NavItem(
                        label: 'Home',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        activeColor: primaryActiveColor,
                        isActive: activeSlot == UnisphereNavSlot.home,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onHomeTap();
                        },
                      ),
                    ),

                    // 2. Classes / Schedule
                    Expanded(
                      child: _NavItem(
                        label: classesLabel,
                        icon: classesIcon ?? Icons.assignment_outlined,
                        activeIcon: classesActiveIcon ?? Icons.assignment_rounded,
                        activeColor: primaryActiveColor,
                        isActive: activeSlot == UnisphereNavSlot.classes,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onClassesTap();
                        },
                      ),
                    ),

                    // 3. Center Elevated Unisphere "U" Logo Button
                    _CenterActionButton(
                      activeColor: primaryActiveColor,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onCenterTap();
                      },
                    ),

                    // 4. Notifications
                    Expanded(
                      child: _NavItem(
                        label: 'Notifications',
                        icon: Icons.notifications_none_rounded,
                        activeIcon: Icons.notifications_rounded,
                        activeColor: primaryActiveColor,
                        isActive: activeSlot == UnisphereNavSlot.notifications,
                        hasBadge: unreadNotificationsCount > 0,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onNotificationsTap();
                        },
                      ),
                    ),

                    // 5. Profile
                    Expanded(
                      child: _NavItem(
                        label: 'Profile',
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        activeColor: primaryActiveColor,
                        isActive: activeSlot == UnisphereNavSlot.profile,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onProfileTap();
                        },
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

/// A single tab item in the Unisphere Bottom Nav Bar
class _NavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final bool hasBadge;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    this.hasBadge = false,
    this.activeColor = const Color(0xFF2563EB),
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor;
    const inactiveColor = Color(0xFF475569);

    return GestureDetector(
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: widget.isActive
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  )
                : const BoxDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon + Badge
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      widget.isActive ? widget.activeIcon : widget.icon,
                      size: 23,
                      color: widget.isActive ? activeColor : inactiveColor,
                    ),
                    if (widget.hasBadge)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                // Text Label
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                    color: widget.isActive ? activeColor : inactiveColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                // Active Blue Dot
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isActive ? 1.0 : 0.0,
                  child: Container(
                    width: 4.5,
                    height: 4.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Center elevated floating action button with Unisphere "U" Logo
class _CenterActionButton extends StatefulWidget {
  final Color activeColor;
  final VoidCallback onTap;

  const _CenterActionButton({
    this.activeColor = const Color(0xFF2563EB),
    required this.onTap,
  });

  @override
  State<_CenterActionButton> createState() => _CenterActionButtonState();
}

class _CenterActionButtonState extends State<_CenterActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
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

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor;

    return GestureDetector(
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
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Glowing outer halo dish
              gradient: LinearGradient(
                colors: [
                  activeColor.withValues(alpha: 0.35),
                  activeColor.withValues(alpha: 0.12),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.6),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: 1.5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      activeColor,
                      const Color(0xFF1D4ED8), // Royal Deep Navy
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(
                      painter: UnisphereULogoPainter(),
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

/// Custom painter that draws the iconic curved Unisphere "U" logo mark
class UnisphereULogoPainter extends CustomPainter {
  const UnisphereULogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Main solid white "U" stroke
    final mainPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(w * 0.26, h * 0.18);
    path.lineTo(w * 0.26, h * 0.58);
    path.cubicTo(
      w * 0.26, h * 0.88,
      w * 0.74, h * 0.88,
      w * 0.74, h * 0.58,
    );
    path.lineTo(w * 0.74, h * 0.18);

    canvas.drawPath(path, mainPaint);

    // 2. Translucent ribbon overlap highlight (right curve)
    final ribbonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.20
      ..strokeCap = StrokeCap.round;

    final ribbonPath = Path();
    ribbonPath.moveTo(w * 0.74, h * 0.40);
    ribbonPath.cubicTo(
      w * 0.74, h * 0.80,
      w * 0.50, h * 0.86,
      w * 0.42, h * 0.82,
    );

    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
