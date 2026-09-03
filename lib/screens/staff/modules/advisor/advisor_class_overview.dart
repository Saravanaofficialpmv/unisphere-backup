import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';

class AdvisorClassOverviewSection extends ConsumerWidget {
  final VoidCallback? onViewAll;
  final Function(String)? onFilterCategory;

  const AdvisorClassOverviewSection({
    super.key,
    this.onViewAll,
    this.onFilterCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(advisorClassSummaryProvider);

    final metrics = [
      {
        'label': 'Total Students',
        'value': '${summary.totalStudents}',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF16A34A),
        'bgColor': const Color(0xFF16A34A).withValues(alpha: 0.1),
        'filter': 'all',
      },
      {
        'label': 'Overall Attendance',
        'value': '${summary.overallAttendance}%',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFF0D9488),
        'bgColor': const Color(0xFF0D9488).withValues(alpha: 0.1),
        'filter': 'attendance',
      },
      {
        'label': 'Average CGPA',
        'value': '${summary.averageCgpa}',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF2563EB),
        'bgColor': const Color(0xFF2563EB).withValues(alpha: 0.1),
        'filter': 'cgpa',
      },
      {
        'label': 'Students At Risk',
        'value': '${summary.atRiskCount}',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFDC2626),
        'bgColor': const Color(0xFFDC2626).withValues(alpha: 0.1),
        'filter': 'at_risk',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CLASS OVERVIEW',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            if (onViewAll != null)
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.staffRole,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.staffRole,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: metrics.map((m) {
            final color = m['color'] as Color;
            final bgColor = m['bgColor'] as Color;
            final filterKey = m['filter'] as String;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      if (onFilterCategory != null) {
                        onFilterCategory!(filterKey);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: color.withValues(alpha: 0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.7),
                        ),
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              m['icon'] as IconData,
                              size: 18,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            m['value'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['label'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
