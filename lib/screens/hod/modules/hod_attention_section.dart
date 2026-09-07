import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/theme/app_animations.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';

class HodAttentionSection extends ConsumerWidget {
  final Function(int)? onNavigate;
  final VoidCallback? onNavigateToLeaves;
  final VoidCallback? onNavigateToVerifications;
  final VoidCallback? onNavigateToFacultyUpdates;
  final VoidCallback? onNavigateToAcademicApprovals;

  const HodAttentionSection({
    super.key,
    this.onNavigate,
    this.onNavigateToLeaves,
    this.onNavigateToVerifications,
    this.onNavigateToFacultyUpdates,
    this.onNavigateToAcademicApprovals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(hodDepartmentSummaryMetricsProvider);
    final textTheme = Theme.of(context).textTheme;

    final academicApprovals = summary.pendingVerificationsCount;
    final leaveRequests = summary.pendingLeavesCount;
    final studentIssues = summary.atRiskCount;
    final facultyUpdates = summary.pendingODsCount;
    final totalAttention = academicApprovals + leaveRequests + studentIssues + facultyUpdates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Needs Your Attention',
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
                if (totalAttention > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalAttention',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warningDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (totalAttention > 0)
              Text(
                'Action Required',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warningDark,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (totalAttention == 0)
          _buildAllCaughtUpEmptyState(context)
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _buildAttentionRow(
                    context,
                    title: 'Academic Approvals',
                    description: academicApprovals > 0 ? '$academicApprovals verifications pending' : 'All student verifications reviewed',
                    countText: academicApprovals > 0 ? '$academicApprovals pending' : 'Cleared',
                    icon: Icons.fact_check_outlined,
                    isPending: academicApprovals > 0,
                    statusColor: academicApprovals > 0 ? AppColors.warning : AppColors.success,
                    onTap: onNavigateToAcademicApprovals ?? () => onNavigate?.call(15),
                    showDivider: true,
                  ),
                  _buildAttentionRow(
                    context,
                    title: 'Leave Requests',
                    description: leaveRequests > 0 ? '$leaveRequests leave applications awaiting signature' : 'No pending department leaves',
                    countText: leaveRequests > 0 ? '$leaveRequests pending' : 'Cleared',
                    icon: Icons.event_busy_outlined,
                    isPending: leaveRequests > 0,
                    statusColor: leaveRequests > 0 ? AppColors.warning : AppColors.success,
                    onTap: onNavigateToLeaves ?? () => onNavigate?.call(19),
                    showDivider: true,
                  ),
                  _buildAttentionRow(
                    context,
                    title: 'Student Issues',
                    description: studentIssues > 0 ? '$studentIssues students flagged with attendance/CGPA risk' : 'No students at immediate academic risk',
                    countText: studentIssues > 0 ? '$studentIssues alert' : 'Normal',
                    icon: Icons.warning_amber_rounded,
                    isPending: studentIssues > 0,
                    statusColor: studentIssues > 0 ? AppColors.error : AppColors.success,
                    onTap: onNavigateToVerifications ?? () => onNavigate?.call(5),
                    showDivider: true,
                  ),
                  _buildAttentionRow(
                    context,
                    title: 'Faculty Updates',
                    description: facultyUpdates > 0 ? '$facultyUpdates on-duty / workload updates pending' : 'All faculty workloads up-to-date',
                    countText: facultyUpdates > 0 ? '$facultyUpdates updates' : 'Synced',
                    icon: Icons.sync_rounded,
                    isPending: facultyUpdates > 0,
                    statusColor: facultyUpdates > 0 ? AppColors.info : AppColors.success,
                    onTap: onNavigateToFacultyUpdates ?? () => onNavigate?.call(3),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttentionRow(
    BuildContext context, {
    required String title,
    required String description,
    required String countText,
    required IconData icon,
    required bool isPending,
    required Color statusColor,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        AppPressable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    countText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider,
            indent: 62,
            endIndent: 14,
          ),
      ],
    );
  }

  Widget _buildAllCaughtUpEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're all caught up",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No pending approvals, leaves, or student alerts requiring action.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
