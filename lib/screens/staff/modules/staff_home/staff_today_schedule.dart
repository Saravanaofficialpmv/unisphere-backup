import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/modules/shared/staff_schedule_card.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';

class StaffTodayScheduleSection extends ConsumerWidget {
  final Function(int)? onNavigateToTab;
  final Function(StaffNavKey)? onNavigateToKey;
  final VoidCallback? onTakeAttendancePressed;

  const StaffTodayScheduleSection({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToKey,
    this.onTakeAttendancePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(staffTodayScheduleStreamProvider);
    final scheduleList = scheduleAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with "View All >"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "TODAY'S SCHEDULE",
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
                  onNavigateToKey!(StaffNavKey.todayClasses);
                } else if (onNavigateToTab != null) {
                  onNavigateToTab!(20);
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

        // Schedule items list
        if (scheduleList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Center(
              child: Text(
                'No classes scheduled for today',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scheduleList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = scheduleList[index];
              return StaffScheduleCard(
                startTime: item['startTime'] ?? '09:00 AM',
                endTime: item['endTime'] ?? '10:00 AM',
                subjectName: item['subjectName'] ?? 'Course Name',
                className: item['className'] ?? 'Class Section',
                room: item['room'] ?? 'Hall',
                isAttendanceTaken: item['isAttendanceTaken'] ?? false,
                onTakeAttendance: () {
                  if (onTakeAttendancePressed != null) {
                    onTakeAttendancePressed!();
                  } else if (onNavigateToKey != null) {
                    onNavigateToKey!(StaffNavKey.attendance);
                  } else if (onNavigateToTab != null) {
                    onNavigateToTab!(14); // Take Attendance module
                  }
                },
              );
            },
          ),
        const SizedBox(height: 12),

        // Full Schedule button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              if (onNavigateToKey != null) {
                onNavigateToKey!(StaffNavKey.todayClasses);
              } else if (onNavigateToTab != null) {
                onNavigateToTab!(20);
              }
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text(
              'View Full Schedule',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.staffRole,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
