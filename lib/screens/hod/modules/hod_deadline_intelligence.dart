import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/hod_dashboard_provider.dart';
import '../../../services/hod_action_center_service.dart';

/// Layer 4: Deadline Intelligence
///
/// Tracks upcoming academic submissions, assessment cut-offs,
/// compliance files, and faculty council meetings.
class HodDeadlineIntelligence extends ConsumerWidget {
  final Function(int)? onNavigate;

  const HodDeadlineIntelligence({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlines = ref.watch(hodDepartmentDeadlinesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.hodRole.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 16,
                      color: AppColors.hodRole,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Upcoming Deadlines',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (deadlines.isNotEmpty ? AppColors.surfaceSecondary : AppColors.success.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                deadlines.isNotEmpty ? '${deadlines.length} Active' : 'All Clear',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: deadlines.isNotEmpty ? AppColors.textSecondary : AppColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Deadlines list or empty state
        if (deadlines.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.event_available_rounded, color: AppColors.success, size: 22),
                SizedBox(height: 6),
                Text(
                  'No upcoming academic deadlines',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: deadlines.map((item) => _buildDeadlineTile(item)).toList(),
          ),
      ],
    );
  }

  Widget _buildDeadlineTile(DepartmentDeadlineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isUrgent ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate?.call(item.targetRouteIndex),
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (item.isUrgent ? AppColors.warning : AppColors.primary).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.isUrgent ? Icons.timer_outlined : Icons.calendar_month_outlined,
                  size: 18,
                  color: item.isUrgent ? AppColors.warning : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isUrgent ? AppColors.warning.withValues(alpha: 0.12) : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.relativeTime,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item.isUrgent ? AppColors.warning : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
