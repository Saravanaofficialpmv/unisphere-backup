import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';

class StaffRecentActivitySection extends ConsumerWidget {
  final Function(int)? onNavigateToTab;
  final Function(StaffNavKey)? onNavigateToKey;

  const StaffRecentActivitySection({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(staffRecentActivityStreamProvider);
    final activityList = activityAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT ACTIVITY',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            InkWell(
              onTap: () {
                if (onNavigateToKey != null) {
                  onNavigateToKey!(StaffNavKey.announcements);
                } else {
                  onNavigateToTab?.call(0);
                }
              },
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activityList.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = activityList[index];
              final type = item['type']?.toString() ?? '';

              IconData icon = Icons.notifications_active_rounded;
              Color iconColor = AppColors.staffRole;
              Color iconBg = AppColors.staffRole.withValues(alpha: 0.1);

              if (type == 'marks') {
                icon = Icons.check_circle_rounded;
                iconColor = const Color(0xFF16A34A);
                iconBg = const Color(0xFFDCFCE7);
              } else if (type == 'attendance') {
                icon = Icons.check_circle_rounded;
                iconColor = const Color(0xFF2563EB);
                iconBg = const Color(0xFFEFF6FF);
              } else if (type == 'assignment') {
                icon = Icons.assignment_turned_in_rounded;
                iconColor = const Color(0xFFEA580C);
                iconBg = const Color(0xFFFFF7ED);
              } else if (type == 'submission') {
                icon = Icons.description_rounded;
                iconColor = const Color(0xFFDC2626);
                iconBg = const Color(0xFFFEF2F2);
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (type == 'marks') {
                      onNavigateToKey != null ? onNavigateToKey!(StaffNavKey.marks) : onNavigateToTab?.call(10);
                    } else if (type == 'attendance') {
                      onNavigateToKey != null ? onNavigateToKey!(StaffNavKey.attendance) : onNavigateToTab?.call(14);
                    } else if (type == 'assignment') {
                      onNavigateToKey != null ? onNavigateToKey!(StaffNavKey.assignments) : onNavigateToTab?.call(2);
                    } else if (type == 'submission') {
                      onNavigateToKey != null ? onNavigateToKey!(StaffNavKey.submissions) : onNavigateToTab?.call(3);
                    } else {
                      onNavigateToKey != null ? onNavigateToKey!(StaffNavKey.announcements) : onNavigateToTab?.call(0);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 16, color: iconColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: GoogleFonts.manrope(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['timestamp'] ?? '',
                                style: GoogleFonts.manrope(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
