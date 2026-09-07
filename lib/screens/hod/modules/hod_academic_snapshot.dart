import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/widgets/common/app_progress_indicators.dart';

class HodAcademicSnapshot extends ConsumerWidget {
  final Function(int)? onNavigate;
  final VoidCallback? onNavigateToSchedule;

  const HodAcademicSnapshot({
    super.key,
    this.onNavigate,
    this.onNavigateToSchedule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(hodDepartmentSummaryMetricsProvider);
    final textTheme = Theme.of(context).textTheme;

    final attendancePct = summary.averageAttendance > 0 ? summary.averageAttendance : 92.4;
    // Normalized 74 working days completed out of 90 total academic semester days
    const completedDays = 74;
    const totalDays = 90;
    const workingDaysRatio = completedDays / totalDays;
    const classesCompletedPct = 0.84;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Academic Snapshot',
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
            InkWell(
              onTap: onNavigateToSchedule ?? () => onNavigate?.call(18), // Academic Schedule & Days
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Academic Calendar →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.hodRole,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Current Semester badge and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.hodRole.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_rounded, color: AppColors.hodRole, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Semester',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Even Semester (Semesters 4, 6 & 8)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'On Schedule',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 14),

              // Progress metric 1: Working Days
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Working Days',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  Text(
                    '$completedDays / $totalDays Days (${(workingDaysRatio * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AppLinearProgressBar(
                lineHeight: 6.0,
                percent: workingDaysRatio,
                progressColor: AppColors.primary,
                backgroundColor: AppColors.backgroundSubtle,
                borderRadius: 6.0,
              ),

              const SizedBox(height: 14),

              // Progress metric 2: Classes Completed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Classes & Syllabus Coverage',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${(classesCompletedPct * 100).toStringAsFixed(0)}% Completed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AppLinearProgressBar(
                lineHeight: 6.0,
                percent: classesCompletedPct,
                progressColor: AppColors.hodRole,
                backgroundColor: AppColors.backgroundSubtle,
                borderRadius: 6.0,
              ),

              const SizedBox(height: 14),

              // Metric 3: Average Attendance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.how_to_reg_rounded, size: 16, color: AppColors.success),
                        SizedBox(width: 8),
                        Text(
                          'Average Attendance Rate',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      '$attendancePct%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
