import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/modules/shared/staff_metric_card.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_pending_work.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_quick_actions.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_recent_activity.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_subjects_section.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_today_schedule.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';

class StaffHomeDashboard extends ConsumerWidget {
  final Function(int)? onNavigateToTab;
  final Function(StaffNavKey)? onNavigateToKey;
  final VoidCallback? onSwitchToAdvisorMode;

  const StaffHomeDashboard({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToKey,
    this.onSwitchToAdvisorMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final isAdvisor = ref.watch(isClassAdvisorProvider);

    final staff = profileAsync.valueOrNull ??
        StaffModel(
          userId: 'DEMO-STF',
          employeeId: 'STF1024',
          fullName: 'Dr. Arun Kumar',
          departmentId: 'DEPT-CSE',
          departmentName: 'CSE Department',
          designation: 'Assistant Professor',
          specialization: 'Computer Science',
          assignedClasses: ['III CSE - A', 'II CSE - B', 'IV CSE - A'],
          assignedSubjects: ['Machine Learning', 'Data Structures', 'Artificial Intelligence'],
        );

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : (hour < 17 ? 'Good Afternoon,' : 'Good Evening,');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Dark Navy Hero Card matching Mockup ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E1B4B),
                      Color(0xFF2E1065),
                      Color(0xFF3B0764),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E1065).withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDDD6FE),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff.fullName,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${staff.designation} • ${staff.departmentName.contains('CSE') ? 'CSE Department' : staff.departmentName}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFC4B5FD),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Normal Staff',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAdvisor && onSwitchToAdvisorMode != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onSwitchToAdvisorMode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.staffRole,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.stars_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Switch to Advisor Mode',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFF4C1D95)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'You are viewing your teaching dashboard\nNo class advisor assignment.',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFC4B5FD),
                              height: 1.25,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            if (onNavigateToKey != null) {
                              onNavigateToKey!(StaffNavKey.profile);
                            } else {
                              onNavigateToTab?.call(11);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC4B5FD)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'View My Profile',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── 2. Top Metric Cards (Today's Classes, Pending Tasks, Attendance) ──
              Row(
                children: [
                  Expanded(
                    child: StaffMetricCard(
                      title: "Today's Classes",
                      value: "3",
                      imageAsset: "assets/images/metric_classes_3d.jpg",
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFF6366F1),
                      gradientColors: const [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                      onTap: () {
                        if (onNavigateToKey != null) {
                          onNavigateToKey!(StaffNavKey.timetable);
                        } else {
                          onNavigateToTab?.call(12);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StaffMetricCard(
                      title: "Pending Tasks",
                      value: "5",
                      imageAsset: "assets/images/metric_tasks_3d.jpg",
                      icon: Icons.assignment_turned_in_rounded,
                      iconColor: const Color(0xFFF97316),
                      gradientColors: const [
                        Color(0xFFF97316),
                        Color(0xFFEA580C),
                      ],
                      onTap: () {
                        if (onNavigateToKey != null) {
                          onNavigateToKey!(StaffNavKey.submissions);
                        } else {
                          onNavigateToTab?.call(3);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StaffMetricCard(
                      title: "Attendance",
                      value: "92%",
                      subtitle: "(This Month)",
                      imageAsset: "assets/images/metric_attendance_3d.jpg",
                      icon: Icons.donut_large_rounded,
                      iconColor: const Color(0xFF10B981),
                      gradientColors: const [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                      onTap: () {
                        if (onNavigateToKey != null) {
                          onNavigateToKey!(StaffNavKey.attendance);
                        } else {
                          onNavigateToTab?.call(14);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 3. Responsive Main Grid (Desktop 2-Col vs Mobile Stack) ──
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StaffTodayScheduleSection(
                            onNavigateToTab: onNavigateToTab,
                            onNavigateToKey: onNavigateToKey,
                          ),
                          const SizedBox(height: 20),
                          StaffSubjectsSection(
                            onNavigateToTab: onNavigateToTab,
                            onNavigateToKey: onNavigateToKey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Column
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StaffQuickActionsSection(
                            onNavigateToTab: onNavigateToTab,
                            onNavigateToKey: onNavigateToKey,
                          ),
                          const SizedBox(height: 20),
                          StaffPendingWorkSection(
                            onNavigateToTab: onNavigateToTab,
                            onNavigateToKey: onNavigateToKey,
                          ),
                          const SizedBox(height: 20),
                          StaffRecentActivitySection(
                            onNavigateToTab: onNavigateToTab,
                            onNavigateToKey: onNavigateToKey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Mobile single column flow
                StaffTodayScheduleSection(
                  onNavigateToTab: onNavigateToTab,
                  onNavigateToKey: onNavigateToKey,
                ),
                const SizedBox(height: 20),
                StaffQuickActionsSection(
                  onNavigateToTab: onNavigateToTab,
                  onNavigateToKey: onNavigateToKey,
                ),
                const SizedBox(height: 20),
                StaffSubjectsSection(
                  onNavigateToTab: onNavigateToTab,
                  onNavigateToKey: onNavigateToKey,
                ),
                const SizedBox(height: 20),
                StaffPendingWorkSection(
                  onNavigateToTab: onNavigateToTab,
                  onNavigateToKey: onNavigateToKey,
                ),
                const SizedBox(height: 20),
                StaffRecentActivitySection(
                  onNavigateToTab: onNavigateToTab,
                  onNavigateToKey: onNavigateToKey,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
