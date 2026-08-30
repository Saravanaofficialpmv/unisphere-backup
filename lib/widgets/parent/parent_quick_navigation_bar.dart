import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// 3D Glassmorphic Pocket Folder Quick Navigation Bar (Reference Design)
///
/// Features 5 authentic frosted glass pocket cards:
/// 1. Academics (Purple graduation cap)
/// 2. Attendance (Emerald pie chart)
/// 3. Exams (Sky blue document)
/// 4. Updates (Coral orange bell + live badge)
/// 5. More (Slate 4-grid)
///
/// Each item features a tinted backplate, vivid icon, and an optical
/// frosted glass front sleeve with gaussian blur, glossy refraction,
/// and tactile micro-scale physics.
/// ─────────────────────────────────────────────────────────────────────────────
class ParentQuickNavigationBar extends StatelessWidget {
  final VoidCallback onAcademicsTap;
  final VoidCallback onAttendanceTap;
  final VoidCallback onExamsTap;
  final VoidCallback onUpdatesTap;
  final VoidCallback onMoreTap;
  final int? updatesBadgeCount;

  const ParentQuickNavigationBar({
    super.key,
    required this.onAcademicsTap,
    required this.onAttendanceTap,
    required this.onExamsTap,
    required this.onUpdatesTap,
    required this.onMoreTap,
    this.updatesBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _GlassPocketCard(
              label: 'Academics',
              icon: Icons.school_rounded,
              backGradientStart: const Color(0xFFFAF5FF),
              backGradientEnd: const Color(0xFFF3E8FF),
              backBorderColor: const Color(0xFFE9D5FF),
              iconColor: const Color(0xFF9333EA),
              glowColor: const Color(0xFF9333EA),
              tooltip: 'Academic Performance & Marks',
              onTap: onAcademicsTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _GlassPocketCard(
              label: 'Attendance',
              icon: Icons.pie_chart_rounded,
              backGradientStart: const Color(0xFFF0FDF4),
              backGradientEnd: const Color(0xFFDCFCE7),
              backBorderColor: const Color(0xFFBBF7D0),
              iconColor: const Color(0xFF059669),
              glowColor: const Color(0xFF059669),
              tooltip: 'Attendance & Shortage Alerts',
              onTap: onAttendanceTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _GlassPocketCard(
              label: 'Exams',
              icon: Icons.description_rounded,
              backGradientStart: const Color(0xFFF0F9FF),
              backGradientEnd: const Color(0xFFE0F2FE),
              backBorderColor: const Color(0xFFBAE6FD),
              iconColor: const Color(0xFF0284C7),
              glowColor: const Color(0xFF0284C7),
              tooltip: 'Exam Schedules & Results',
              onTap: onExamsTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _GlassPocketCard(
              label: 'Updates',
              icon: Icons.notifications_rounded,
              backGradientStart: const Color(0xFFFFF7ED),
              backGradientEnd: const Color(0xFFFFEDD5),
              backBorderColor: const Color(0xFFFED7AA),
              iconColor: const Color(0xFFEA580C),
              glowColor: const Color(0xFFEA580C),
              badgeCount: updatesBadgeCount,
              tooltip: 'Announcements & Notifications',
              onTap: onUpdatesTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _GlassPocketCard(
              label: 'More',
              icon: Icons.grid_view_rounded,
              backGradientStart: const Color(0xFFF8FAFC),
              backGradientEnd: const Color(0xFFF1F5F9),
              backBorderColor: const Color(0xFFE2E8F0),
              iconColor: const Color(0xFF334155),
              glowColor: const Color(0xFF334155),
              tooltip: 'More Parent Modules & Services',
              onTap: onMoreTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPocketCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backGradientStart;
  final Color backGradientEnd;
  final Color backBorderColor;
  final Color iconColor;
  final Color glowColor;
  final String tooltip;
  final VoidCallback onTap;
  final int? badgeCount;

  const _GlassPocketCard({
    required this.label,
    required this.icon,
    required this.backGradientStart,
    required this.backGradientEnd,
    required this.backBorderColor,
    required this.iconColor,
    required this.glowColor,
    required this.tooltip,
    required this.onTap,
    this.badgeCount,
  });

  @override
  State<_GlassPocketCard> createState() => _GlassPocketCardState();
}

class _GlassPocketCardState extends State<_GlassPocketCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.badgeCount ?? 0;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: 94,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. Back Plate / Card Base with Soft Color Glow
                Positioned(
                  top: 0,
                  left: 4,
                  right: 4,
                  height: 84,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.backGradientStart,
                          widget.backGradientEnd,
                        ],
                      ),
                      border: Border.all(
                        color: widget.backBorderColor,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.glowColor.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: const Alignment(0, -0.65),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 27,
                      ),
                    ),
                  ),
                ),

                // 2. Notification Badge (if any) on Top-Right
                if (count > 0)
                  Positioned(
                    top: -2,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                // 3. Front Optical Frosted Glass Pocket Plate (3D Glassmorphism)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 52,
                  child: CustomPaint(
                    painter: _PocketShadowPainter(glowColor: widget.glowColor),
                    child: ClipPath(
                      clipper: const _PocketClipper(),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.72),
                                Colors.white.withValues(alpha: 0.38),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.88),
                              width: 1.5,
                            ),
                          ),
                          child: Align(
                            alignment: const Alignment(0, 0.40),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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

/// Custom Clipper to render the slanted 3D pocket top lip
class _PocketClipper extends CustomClipper<Path> {
  const _PocketClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    const double radius = 14.0;
    // Slanted top edge: Left starts at y = 8, right reaches y = 0
    path.moveTo(0, 8 + radius);
    path.quadraticBezierTo(0, 8, radius, 6.5);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom Painter to render soft 3D ambient shadow underneath the glass pocket
class _PocketShadowPainter extends CustomPainter {
  final Color glowColor;

  const _PocketShadowPainter({required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = glowColor.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    const double radius = 14.0;
    path.moveTo(0, 8 + radius);
    path.quadraticBezierTo(0, 8, radius, 6.5);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.close();

    canvas.drawPath(path.shift(const Offset(0, 4)), paint);
  }

  @override
  bool shouldRepaint(covariant _PocketShadowPainter oldDelegate) =>
      oldDelegate.glowColor != glowColor;
}
