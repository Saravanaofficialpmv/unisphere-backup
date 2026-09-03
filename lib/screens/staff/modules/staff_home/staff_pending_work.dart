import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';

class StaffPendingWorkSection extends ConsumerWidget {
  final Function(int)? onNavigateToTab;

  const StaffPendingWorkSection({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(staffPendingWorkStreamProvider);
    final pendingList = pendingAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PENDING WORK',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            InkWell(
              onTap: () {
                if (onNavigateToTab != null) {
                  onNavigateToTab!(3); // Review Submissions
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
            itemCount: pendingList.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = pendingList[index];
              final priority = item['priority']?.toString().toLowerCase() ?? 'medium';
              final action = item['action']?.toString() ?? '';

              IconData icon = Icons.info_outline_rounded;
              Color iconColor = const Color(0xFF64748B);
              Color iconBg = const Color(0xFFF1F5F9);

              if (priority == 'urgent' || item['title'].toString().contains('Attendance')) {
                icon = Icons.warning_amber_rounded;
                iconColor = const Color(0xFFD97706);
                iconBg = const Color(0xFFFFFBEB);
              } else if (priority == 'high' || item['title'].toString().contains('Marks')) {
                icon = Icons.error_outline_rounded;
                iconColor = const Color(0xFFDC2626);
                iconBg = const Color(0xFFFEF2F2);
              } else if (item['title'].toString().contains('Assignment')) {
                icon = Icons.folder_open_rounded;
                iconColor = const Color(0xFF2563EB);
                iconBg = const Color(0xFFEFF6FF);
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (action == 'upload_marks') {
                      onNavigateToTab?.call(10);
                    } else if (action == 'take_attendance') {
                      onNavigateToTab?.call(14);
                    } else if (action == 'review_submissions') {
                      onNavigateToTab?.call(3);
                    } else if (action == 'upload_qp') {
                      onNavigateToTab?.call(15);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 18, color: iconColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'] ?? '',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['dueDate'] ?? '',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item['dueDate'].toString().contains('Today') ||
                                    item['dueDate'].toString().contains('Sep 10')
                                ? const Color(0xFFDC2626)
                                : AppColors.textSecondary,
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
