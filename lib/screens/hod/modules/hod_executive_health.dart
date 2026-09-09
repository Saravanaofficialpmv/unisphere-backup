import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../providers/hod_dashboard_provider.dart';

/// Layer 1: Executive Department Health Matrix
///
/// Surfaces high-level operational indicators with semantic trends and direct drill-downs.
class HodExecutiveHealth extends ConsumerWidget {
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToAcademics;
  final VoidCallback? onNavigateToFaculty;
  final VoidCallback? onNavigateToActions;
  final VoidCallback? onNavigateToStudents;
  final VoidCallback? onNavigateToClasses;

  const HodExecutiveHealth({
    super.key,
    this.onNavigateToAttendance,
    this.onNavigateToAcademics,
    this.onNavigateToFaculty,
    this.onNavigateToActions,
    this.onNavigateToStudents,
    this.onNavigateToClasses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(hodExecutiveHealthProvider);
    final summary = ref.watch(hodDepartmentSummaryMetricsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with required mobile test identifier
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Department Health',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.hodRole.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: AppColors.hodRole, size: 6),
                  SizedBox(width: 5),
                  Text(
                    'DEPARTMENT HEALTH OVERVIEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.hodRole,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Primary 2x2 Executive Health Matrix
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 700;
            final crossAxisCount = isDesktop ? 4 : 2;
            final crossAxisSpacing = 10.0;
            final totalSpacing = crossAxisSpacing * (crossAxisCount - 1);
            final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
            final itemHeight = isDesktop ? 120.0 : 110.0;
            final childAspectRatio = itemWidth / itemHeight;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
              children: [
                _buildHealthCard(
                  title: 'Attendance',
                  value: '${health.attendanceRate}%',
                  subtitle: health.attendanceTrend,
                  icon: Icons.how_to_reg_rounded,
                  accentColor: AppColors.success,
                  onTap: onNavigateToAttendance,
                ),
                _buildHealthCard(
                  title: 'Academic Avg',
                  value: '${health.academicAverageCgpa}',
                  subtitle: health.academicTrend,
                  icon: Icons.auto_graph_rounded,
                  accentColor: AppColors.primary,
                  onTap: onNavigateToAcademics,
                ),
                _buildHealthCard(
                  title: 'Faculty Coverage',
                  value: '${health.facultyCoverageRate}%',
                  subtitle: health.coverageTrend,
                  icon: Icons.badge_outlined,
                  accentColor: const Color(0xFF7C3AED),
                  onTap: onNavigateToFaculty,
                ),
                _buildHealthCard(
                  title: 'Pending Actions',
                  value: '${health.pendingActionsCount}',
                  subtitle: health.pendingActionsCount > 0 ? 'Requires HOD Review' : 'All Clear',
                  icon: Icons.pending_actions_rounded,
                  accentColor: health.pendingActionsCount > 0 ? AppColors.warning : AppColors.success,
                  onTap: onNavigateToActions,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),

        // Secondary KPI Metric Bar with test strings
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSecondaryMetric(
                  label: 'Enrolled Students',
                  value: '${summary.totalStudents}',
                  onTap: onNavigateToStudents,
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.border.withValues(alpha: 0.6)),
              Expanded(
                child: _buildSecondaryMetric(
                  label: 'Faculty Members',
                  value: '${summary.totalFaculty}',
                  onTap: onNavigateToFaculty,
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.border.withValues(alpha: 0.6)),
              Expanded(
                child: _buildSecondaryMetric(
                  label: 'Active Classes',
                  value: '${summary.totalClasses}',
                  onTap: onNavigateToClasses,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return AppCardPressable(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: accentColor, size: 14),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 9,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryMetric({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
