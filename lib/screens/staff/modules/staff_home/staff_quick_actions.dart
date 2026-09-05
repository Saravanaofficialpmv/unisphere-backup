import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';

class StaffQuickActionsSection extends StatelessWidget {
  final Function(int)? onNavigateToTab;
  final Function(StaffNavKey)? onNavigateToKey;
  final VoidCallback? onTasksPressed;

  const StaffQuickActionsSection({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToKey,
    this.onTasksPressed,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'label': 'Attendance',
        'sublabel': 'Mark & Track',
        'icon': Icons.how_to_reg_rounded,
        'imageAsset': 'assets/images/quick_actions/action_attendance_3d.jpg',
        'gradient': const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        'navKey': StaffNavKey.attendance,
        'tabIndex': 14,
      },
      {
        'label': 'Upload Marks',
        'sublabel': 'Enter Grades',
        'icon': Icons.grade_rounded,
        'imageAsset': 'assets/images/quick_actions/action_marks_3d.jpg',
        'gradient': const [Color(0xFF10B981), Color(0xFF059669)],
        'navKey': StaffNavKey.marks,
        'tabIndex': 10,
      },
      {
        'label': 'Assignments',
        'sublabel': 'Create & View',
        'icon': Icons.assignment_rounded,
        'imageAsset': 'assets/images/quick_actions/action_assignments_3d.jpg',
        'gradient': const [Color(0xFFF97316), Color(0xFFEA580C)],
        'navKey': StaffNavKey.assignments,
        'tabIndex': 2,
      },
      {
        'label': 'Question Papers',
        'sublabel': 'Exam Vault',
        'icon': Icons.upload_file_rounded,
        'imageAsset': 'assets/images/quick_actions/action_questions_3d.jpg',
        'gradient': const [Color(0xFF3B82F6), Color(0xFF2563EB)],
        'navKey': StaffNavKey.questionPapers,
        'tabIndex': 15,
      },
      {
        'label': 'Submissions\nReview',
        'sublabel': 'Evaluate',
        'icon': Icons.rate_review_rounded,
        'imageAsset': 'assets/images/quick_actions/action_submissions_3d.jpg',
        'gradient': const [Color(0xFFF43F5E), Color(0xFFE11D48)],
        'navKey': StaffNavKey.submissions,
        'tabIndex': 3,
      },
      {
        'label': 'Schedule\nTimetable',
        'sublabel': 'Weekly Plan',
        'icon': Icons.calendar_month_rounded,
        'imageAsset': 'assets/images/quick_actions/action_timetable_3d.jpg',
        'gradient': const [Color(0xFFA855F7), Color(0xFF7C3AED)],
        'navKey': StaffNavKey.timetable,
        'tabIndex': 12,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'QUICK ACTIONS',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '6 SHORTCUTS',
                    style: GoogleFonts.manrope(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4F46E5),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 3x2 Quick Action Grid ──
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.90,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final item = actions[index];
            final gradient = item['gradient'] as List<Color>;
            final primaryColor = gradient.first;
            final imageAsset = item['imageAsset'] as String?;
            final tabIndex = item['tabIndex'] as int;

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () {
                  final navKey = item['navKey'] as StaffNavKey?;
                  if (navKey != null && onNavigateToKey != null) {
                    onNavigateToKey!(navKey);
                  } else if (tabIndex == -1) {
                    if (onTasksPressed != null) {
                      onTasksPressed!();
                    }
                  } else if (onNavigateToTab != null) {
                    onNavigateToTab!(tabIndex);
                  }
                },
                borderRadius: BorderRadius.circular(18),
                splashColor: primaryColor.withValues(alpha: 0.14),
                highlightColor: primaryColor.withValues(alpha: 0.06),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        primaryColor.withValues(alpha: 0.035),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.16),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── 3D Icon Container ──
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: imageAsset != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.asset(
                                  imageAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),

                      // ── Title Label ──
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
