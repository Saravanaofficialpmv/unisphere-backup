import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/student_model.dart';
import '../../../providers/hod_dashboard_provider.dart';
import '../../../widgets/common/apple_glass_card.dart';
import '../../../widgets/student/student_full_detail_modal.dart';

/// Student Insights module displaying key student metrics and at-risk monitoring.
class HodStudentInsights extends ConsumerWidget {
  final VoidCallback? onNavigateToStudents;

  const HodStudentInsights({
    super.key,
    this.onNavigateToStudents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(hodStudentsStreamProvider).valueOrNull ?? [];
    final riskStudents = ref.watch(hodStudentRiskListProvider);
    final analytics = ref.watch(hodAttendanceAnalyticsProvider);
    final summary = ref.watch(hodDepartmentSummaryProvider);

    // Compute academic risk count (<6.5 CGPA)
    final academicRiskCount = students.where((s) {
      final cgpa = double.tryParse(s.cgpa ?? '') ?? 10.0;
      return cgpa < 6.5;
    }).length;

    // Attendance risk count (<75%)
    final attendanceRiskCount = analytics.alert;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with required test label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.error, size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'STUDENTS REQUIRING ATTENTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (riskStudents.isNotEmpty ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${riskStudents.length} Students',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: riskStudents.isNotEmpty ? AppColors.error : AppColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 KPI Sub-chips
        Row(
          children: [
            Expanded(
              child: _buildMetricPill(
                label: 'Attendance <75%',
                value: '$attendanceRiskCount',
                icon: Icons.warning_amber_rounded,
                color: attendanceRiskCount > 0 ? AppColors.error : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricPill(
                label: 'CGPA <6.5',
                value: '$academicRiskCount',
                icon: Icons.trending_down_rounded,
                color: academicRiskCount > 0 ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricPill(
                label: 'Action Items',
                value: '${summary.pendingActionsCount}',
                icon: Icons.pending_actions_rounded,
                color: summary.pendingActionsCount > 0 ? AppColors.hodRole : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricPill(
                label: 'Top Att. ≥90%',
                value: '${analytics.exemplary}',
                icon: Icons.star_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // At-risk Student List or Empty Card
        if (riskStudents.isEmpty)
          AppleGlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 22),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'No students currently at academic risk',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ...riskStudents.take(5).map((student) => _buildStudentTile(context, student)),
              if (riskStudents.length > 5 && onNavigateToStudents != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onNavigateToStudents,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.hodRole,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Text('View All Flagged Students', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      label: const Icon(Icons.arrow_forward_rounded, size: 14),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, StudentModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showStudentFullDetailModal(context, student.toMap()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.error.withValues(alpha: 0.12),
                  child: Text(
                    student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.registerNumber,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sec ${student.section.isEmpty ? "A" : student.section} • Att: ${student.attendancePercent ?? "N/A"}% • CGPA: ${student.cgpa ?? "N/A"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
