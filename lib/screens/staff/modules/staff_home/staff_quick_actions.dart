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
        'icon': Icons.how_to_reg_rounded,
        'color': AppColors.staffRole,
        'bgColor': AppColors.staffRole.withValues(alpha: 0.1),
        'navKey': StaffNavKey.attendance,
        'tabIndex': 14,
      },
      {
        'label': 'Upload Marks',
        'icon': Icons.grade_rounded,
        'color': const Color(0xFF16A34A),
        'bgColor': const Color(0xFF16A34A).withValues(alpha: 0.1),
        'navKey': StaffNavKey.marks,
        'tabIndex': 10,
      },
      {
        'label': 'Assignments',
        'icon': Icons.assignment_rounded,
        'color': const Color(0xFFEA580C),
        'bgColor': const Color(0xFFEA580C).withValues(alpha: 0.1),
        'navKey': StaffNavKey.assignments,
        'tabIndex': 2,
      },
      {
        'label': 'Question Papers',
        'icon': Icons.upload_file_rounded,
        'color': const Color(0xFF2563EB),
        'bgColor': const Color(0xFF2563EB).withValues(alpha: 0.1),
        'navKey': StaffNavKey.questionPapers,
        'tabIndex': 15,
      },
      {
        'label': 'Submissions\nReview',
        'icon': Icons.rate_review_rounded,
        'color': const Color(0xFFDC2626),
        'bgColor': const Color(0xFFDC2626).withValues(alpha: 0.1),
        'navKey': StaffNavKey.submissions,
        'tabIndex': 3,
      },
      {
        'label': 'Schedule\nTimetable',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF9333EA),
        'bgColor': const Color(0xFF9333EA).withValues(alpha: 0.1),
        'navKey': StaffNavKey.timetable,
        'tabIndex': 12,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final item = actions[index];
            final color = item['color'] as Color;
            final bgColor = item['bgColor'] as Color;
            final tabIndex = item['tabIndex'] as int;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
                splashColor: color.withValues(alpha: 0.12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.15,
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
