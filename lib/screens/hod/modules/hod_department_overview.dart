import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/theme/app_animations.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';

class HodDepartmentOverview extends ConsumerWidget {
  final Function(int)? onNavigate;
  final VoidCallback? onNavigateToStudents;
  final VoidCallback? onNavigateToFaculty;
  final VoidCallback? onNavigateToClasses;
  final VoidCallback? onNavigateToAttendance;

  const HodDepartmentOverview({
    super.key,
    this.onNavigate,
    this.onNavigateToStudents,
    this.onNavigateToFaculty,
    this.onNavigateToClasses,
    this.onNavigateToAttendance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(hodDepartmentSummaryMetricsProvider);
    final textTheme = Theme.of(context).textTheme;

    final totalStudents = '${summary.totalStudents}';
    final totalFaculty = '${summary.totalFaculty}';
    final totalClasses = '${summary.totalClasses}';
    final attendanceText = summary.averageAttendance > 0 ? '${summary.averageAttendance}%' : '0%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Department Overview',
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ) ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 700;
            final int crossAxisCount = isDesktop ? 4 : 2;
            final double crossAxisSpacing = 12.0;
            final double totalSpacing = crossAxisSpacing * (crossAxisCount - 1);
            final double itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
            // Compact height for optimal mobile scanning
            final double itemHeight = isDesktop ? 128 : 120;
            final double childAspectRatio = itemWidth / itemHeight;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
              children: [
                _buildMetricCard(
                  context,
                  metric: totalStudents,
                  label: 'Students',
                  subtitle: 'Enrolled Students',
                  icon: Icons.school_outlined,
                  accentColor: AppColors.primary,
                  onTap: onNavigateToStudents ?? () => onNavigate?.call(4),
                ),
                _buildMetricCard(
                  context,
                  metric: totalFaculty,
                  label: 'Faculty',
                  subtitle: 'Faculty Members',
                  icon: Icons.badge_outlined,
                  accentColor: const Color(0xFF7C3AED),
                  onTap: onNavigateToFaculty ?? () => onNavigate?.call(3),
                ),
                _buildMetricCard(
                  context,
                  metric: totalClasses,
                  label: 'Active Classes',
                  subtitle: 'Current Classes',
                  icon: Icons.class_outlined,
                  accentColor: AppColors.hodRole,
                  onTap: onNavigateToClasses ?? () => onNavigate?.call(16),
                ),
                _buildMetricCard(
                  context,
                  metric: attendanceText,
                  label: 'Attendance',
                  subtitle: 'Department Attendance',
                  icon: Icons.how_to_reg_outlined,
                  accentColor: AppColors.success,
                  onTap: onNavigateToAttendance ?? () => onNavigate?.call(14),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String metric,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return AppCardPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      color: AppColors.cardBackground,
      border: Border.all(color: AppColors.border, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textTertiary,
                size: 11,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  metric,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
