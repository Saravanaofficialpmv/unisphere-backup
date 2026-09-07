import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/activity_log_model.dart';
import '../../../providers/hod_dashboard_provider.dart';
import '../../../widgets/common/apple_glass_card.dart';

/// Layer 5: Department Activity Timeline
///
/// Streams real-time audit trails and departmental events across attendance,
/// mark uploads, leave requests, and announcements.
class HodActivityTimeline extends ConsumerWidget {
  const HodActivityTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(hodRecentActivityStreamProvider);

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
                      Icons.history_rounded,
                      size: 16,
                      color: AppColors.hodRole,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Recent Department Activity',
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Real-time',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Activity List
        activityAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return AppleGlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_outline_rounded, color: AppColors.textTertiary, size: 20),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'No recent department activity recorded',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: logs.take(6).map((log) => _buildActivityTile(log)).toList(),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.hodRole),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Recent activity stream temporarily unavailable',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(ActivityLogModel log) {
    final meta = _getActivityMeta(log);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, size: 16, color: meta.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meta.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatRelativeTime(log.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  log.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ActivityMeta _getActivityMeta(ActivityLogModel log) {
    final mod = log.module.toLowerCase();
    final act = log.action.toLowerCase();

    if (mod.contains('leave') || act.contains('leave')) {
      return _ActivityMeta(title: 'Leave Request', icon: Icons.event_busy_outlined, color: AppColors.warning);
    } else if (mod.contains('od') || act.contains('od')) {
      return _ActivityMeta(title: 'On-Duty Application', icon: Icons.badge_outlined, color: AppColors.info);
    } else if (mod.contains('attend') || act.contains('attend')) {
      return _ActivityMeta(title: 'Attendance Posted', icon: Icons.fact_check_outlined, color: AppColors.success);
    } else if (mod.contains('announc') || act.contains('notice')) {
      return _ActivityMeta(title: 'Announcement', icon: Icons.campaign_outlined, color: AppColors.hodRole);
    } else if (mod.contains('academic') || mod.contains('timetable') || act.contains('timetable')) {
      return _ActivityMeta(title: 'Academic Schedule', icon: Icons.calendar_today_outlined, color: AppColors.primary);
    } else {
      return _ActivityMeta(
        title: log.action.isNotEmpty ? log.action : 'Department Update',
        icon: Icons.notifications_none_rounded,
        color: AppColors.hodRole,
      );
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}';
  }
}

class _ActivityMeta {
  final String title;
  final IconData icon;
  final Color color;

  const _ActivityMeta({
    required this.title,
    required this.icon,
    required this.color,
  });
}
