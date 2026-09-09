import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/hod_dashboard_provider.dart';
import '../../../widgets/common/apple_glass_card.dart';

/// Faculty Overview module displaying real-time faculty attendance, status, and workload metrics.
class HodFacultyOverview extends ConsumerWidget {
  final VoidCallback? onNavigateToStaff;

  const HodFacultyOverview({
    super.key,
    this.onNavigateToStaff,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(hodDepartmentSummaryProvider);
    final staffList = ref.watch(hodStaffStreamProvider).valueOrNull ?? [];
    final leaves = ref.watch(hodLeaveRequestsStreamProvider).valueOrNull ?? [];
    final schedule = ref.watch(hodTodayScheduleProvider);

    // Calculate dynamic metrics
    final totalFaculty = summary.totalFaculty > 0 ? summary.totalFaculty : staffList.length;
    final onLeaveCount = leaves.where((l) {
      final s = (l['status'] ?? '').toString().toLowerCase();
      return s == 'approved' || s == 'pending';
    }).length;
    final presentToday = (totalFaculty - onLeaveCount).clamp(0, totalFaculty);
    final classesToday = schedule.isNotEmpty ? schedule.length : (summary.totalClasses > 0 ? summary.totalClasses * 2 : 0);

    return AppleGlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.hodRole.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      size: 18,
                      color: AppColors.hodRole,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Faculty Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (onNavigateToStaff != null)
                TextButton(
                  onPressed: onNavigateToStaff,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Manage Staff',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.hodRole,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.hodRole),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Metric Tiles in 2x2 layout
          Row(
            children: [
              Expanded(
                child: _buildFacultyMetric(
                  label: 'Faculty Members',
                  value: '$totalFaculty',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFacultyMetric(
                  label: 'Present Today',
                  value: '$presentToday',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFacultyMetric(
                  label: 'On Leave',
                  value: '$onLeaveCount',
                  icon: Icons.event_busy_outlined,
                  color: onLeaveCount > 0 ? AppColors.warning : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFacultyMetric(
                  label: 'Classes Today',
                  value: '$classesToday',
                  icon: Icons.menu_book_outlined,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer info pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${summary.totalAdvisors} Appointed Class Advisors active this semester',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
