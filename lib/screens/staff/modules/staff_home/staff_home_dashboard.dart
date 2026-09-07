import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/theme/app_animations.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/modules/shared/staff_metric_card.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_pending_work.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_quick_actions.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_recent_activity.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_subjects_section.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_today_schedule.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

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
    final authUser = ref.watch(currentUserProvider).valueOrNull ?? ref.watch(authServiceProvider).currentUser;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final isAdvisor = ref.watch(isClassAdvisorProvider);
    final advisorAssignment = ref.watch(activeClassAdvisorAssignmentProvider);
    final staff = profileAsync.valueOrNull;

    final todayClassesCount = ref.watch(staffTodayClassesCountProvider);
    final pendingTasksCount = ref.watch(staffPendingTasksCountProvider);
    final attendanceMetric = ref.watch(staffMonthlyAttendanceMetricProvider);

    final String staffName = (staff?.fullName != null && staff!.fullName.trim().isNotEmpty)
        ? staff.fullName
        : ((authUser?.fullName != null && authUser!.fullName.trim().isNotEmpty)
            ? authUser.fullName
            : (authUser?.email.contains('@') == true
                ? authUser!.email.split('@').first
                : 'Faculty Member'));

    final String staffDesignation = (staff?.designation != null && staff!.designation.trim().isNotEmpty)
        ? staff.designation
        : (authUser?.metadata?['designation']?.toString() ?? 'Faculty Member');

    final String staffDept = (staff?.departmentName != null && staff!.departmentName.trim().isNotEmpty)
        ? (staff.departmentName.contains('CSE') ? 'CSE Department' : staff.departmentName)
        : (authUser?.metadata?['department']?.toString() ?? 'Computer Science & Engineering');

    final String advisorSection = advisorAssignment?.className ??
        advisorAssignment?.section ??
        staff?.advisorSection ??
        'Assigned Section';

    final String dashboardSubtitle = isAdvisor
        ? 'You are viewing your teaching & advisor dashboard\nAdvisor • $advisorSection'
        : 'You are viewing your teaching dashboard\nNo class advisor assignment.';

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
              // ── 1. Top Deep Blue / Navy Hero Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F172A), // Slate 900
                      Color(0xFF1E3A8A), // Blue 900
                      Color(0xFF1D4ED8), // Blue 700
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.30),
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
                        color: const Color(0xFFDBEAFE),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staffName,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$staffDesignation • $staffDept',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF93C5FD),
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
                            color: isAdvisor
                                ? AppColors.staffRole.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAdvisor
                                  ? AppColors.staffRole.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAdvisor ? Icons.stars_rounded : Icons.person_outline_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAdvisor ? 'Class Advisor' : 'Normal Staff',
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
                          AppPressable(
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
                                    Icons.swap_horiz_rounded,
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
                    const Divider(height: 1, color: Color(0xFF1E40AF)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dashboardSubtitle,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFBFDBFE),
                              height: 1.25,
                            ),
                          ),
                        ),
                        _StaffViewProfileButton(
                          onNavigate: () {
                            if (onNavigateToKey != null) {
                              onNavigateToKey!(StaffNavKey.profile);
                            } else if (onNavigateToTab != null) {
                              onNavigateToTab!(11);
                            } else {
                              context.push('/staff/profile');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── 2. Top Metric Cards (Today's Classes, Pending Tasks, Attendance) ──
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StaffMetricCard(
                        title: "Today's Classes",
                        value: "$todayClassesCount",
                        subtitle: "Scheduled",
                        progress: todayClassesCount > 0 ? (todayClassesCount / 6.0).clamp(0.2, 1.0) : 0.0,
                        imageAsset: "assets/images/metric_classes_3d.jpg",
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF2563EB),
                        gradientColors: const [
                          Color(0xFF2563EB),
                          Color(0xFF3B82F6),
                        ],
                        onTap: () {
                          if (onNavigateToKey != null) {
                            onNavigateToKey!(StaffNavKey.todayClasses);
                          } else if (onNavigateToTab != null) {
                            onNavigateToTab!(20);
                          } else {
                            context.push('/staff/today-classes');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StaffMetricCard(
                        title: "Pending Tasks",
                        value: "$pendingTasksCount",
                        subtitle: "To Review",
                        progress: pendingTasksCount > 0 ? (pendingTasksCount / 10.0).clamp(0.2, 1.0) : 0.0,
                        imageAsset: "assets/images/metric_tasks_3d.jpg",
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: const Color(0xFFF97316),
                        gradientColors: const [
                          Color(0xFFF97316),
                          Color(0xFFEA580C),
                        ],
                        onTap: () {
                          if (onNavigateToKey != null) {
                            onNavigateToKey!(StaffNavKey.pendingTasks);
                          } else if (onNavigateToTab != null) {
                            onNavigateToTab!(21);
                          } else {
                            context.push('/staff/tasks');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StaffMetricCard(
                        title: "Attendance",
                        value: attendanceMetric.formattedPercentage,
                        subtitle: "This Month",
                        progress: attendanceMetric.progress,
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
                          } else if (onNavigateToTab != null) {
                            onNavigateToTab!(14);
                          } else {
                            context.push('/staff/attendance');
                          }
                        },
                      ),
                    ),
                  ],
                ),
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

class _StaffViewProfileButton extends StatefulWidget {
  final VoidCallback onNavigate;

  const _StaffViewProfileButton({required this.onNavigate});

  @override
  State<_StaffViewProfileButton> createState() => _StaffViewProfileButtonState();
}

class _StaffViewProfileButtonState extends State<_StaffViewProfileButton> {
  bool _isLoading = false;
  DateTime? _lastTapTime;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < const Duration(milliseconds: 700)) {
      return; // Debounce rapid multi-taps
    }
    _lastTapTime = now;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    widget.onNavigate();
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF93C5FD).withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 80,
                height: 16,
                child: Center(
                  child: Loader.button(size: 14),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'View My Profile',
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

