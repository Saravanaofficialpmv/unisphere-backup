import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modern, premium, minimal quick navigation dashboard component for the Parent Portal.
///
/// Provides 5 parent-focused categories:
/// 1. Academics (Graduation cap icon)
/// 2. Attendance (Attendance/progress chart icon)
/// 3. Exams (Exam/document outline icon)
/// 4. Updates (Notification bell icon)
/// 5. More (Four-grid icon)
///
/// Features smooth tap micro-scale animations, pastel tinted circular backgrounds,
/// light borders, soft ambient elevation, and mobile-responsive layout.
class ParentQuickNavigationBar extends StatelessWidget {
  final VoidCallback onAcademicsTap;
  final VoidCallback onAttendanceTap;
  final VoidCallback onExamsTap;
  final VoidCallback onUpdatesTap;
  final VoidCallback onMoreTap;

  const ParentQuickNavigationBar({
    super.key,
    required this.onAcademicsTap,
    required this.onAttendanceTap,
    required this.onExamsTap,
    required this.onUpdatesTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _QuickNavItemButton(
              label: 'Academics',
              icon: Icons.school_outlined,
              bgColor: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
              tooltip: 'Academic Performance & Marks',
              onTap: onAcademicsTap,
            ),
          ),
          Expanded(
            child: _QuickNavItemButton(
              label: 'Attendance',
              icon: Icons.pie_chart_outline_rounded,
              bgColor: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF059669),
              tooltip: 'Attendance & Shortage Alerts',
              onTap: onAttendanceTap,
            ),
          ),
          Expanded(
            child: _QuickNavItemButton(
              label: 'Exams',
              icon: Icons.description_outlined,
              bgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              tooltip: 'Exam Schedules & Results',
              onTap: onExamsTap,
            ),
          ),
          Expanded(
            child: _QuickNavItemButton(
              label: 'Updates',
              icon: Icons.notifications_active_outlined,
              bgColor: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFEA580C),
              tooltip: 'Announcements & Notifications',
              onTap: onUpdatesTap,
            ),
          ),
          Expanded(
            child: _QuickNavItemButton(
              label: 'More',
              icon: Icons.grid_view_rounded,
              bgColor: const Color(0xFFF1F5F9),
              iconColor: const Color(0xFF334155),
              tooltip: 'More Parent Modules & Services',
              onTap: onMoreTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickNavItemButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickNavItemButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_QuickNavItemButton> createState() => _QuickNavItemButtonState();
}

class _QuickNavItemButtonState extends State<_QuickNavItemButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.iconColor.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                    boxShadow: _isPressed
                        ? []
                        : [
                            BoxShadow(
                              color: widget.iconColor.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
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
