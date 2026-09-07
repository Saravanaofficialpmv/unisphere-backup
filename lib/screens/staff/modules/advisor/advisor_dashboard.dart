import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_academic_performance.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_announcements.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_attendance.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_attention_section.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_class_overview.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_leave_od.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_student_directory.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_tasks.dart';
import 'package:unisphere/screens/staff/modules/shared/staff_metric_card.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';

class AdvisorDashboard extends ConsumerStatefulWidget {
  final Function(int)? onNavigateToTab;
  final Function(StaffNavKey)? onNavigateToKey;
  final VoidCallback? onSwitchToTeachingMode;

  const AdvisorDashboard({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToKey,
    this.onSwitchToTeachingMode,
  });

  @override
  ConsumerState<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends ConsumerState<AdvisorDashboard> {
  String? _activeDirectoryFilter;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final advisorAssignment = ref.watch(activeClassAdvisorAssignmentProvider);
    final summary = ref.watch(advisorClassSummaryProvider);

    final staff = profileAsync.valueOrNull ??
        StaffModel(
          userId: 'DEMO-STF',
          employeeId: 'STF1024',
          fullName: 'Dr. Arun Kumar',
          departmentId: 'DEPT-CSE',
          departmentName: 'CSE Department',
          designation: 'Assistant Professor',
          specialization: 'Computer Science',
          assignedClasses: ['III CSE - A'],
          assignedSubjects: ['Machine Learning'],
          isAdvisor: true,
          advisorSection: 'III CSE - A',
          advisorAcademicYear: '2025–26',
        );

    final sectionName = advisorAssignment?.className ?? advisorAssignment?.classId ?? staff.advisorSection ?? 'III CSE - A';
    final academicYear = advisorAssignment?.academicYear ?? staff.advisorAcademicYear ?? '2025–26';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : (hour < 17 ? 'Good Afternoon,' : 'Good Evening,');

    if (_activeDirectoryFilter != null) {
      return AdvisorStudentDirectoryScreen(
        initialFilter: _activeDirectoryFilter,
        onBack: () => setState(() => _activeDirectoryFilter = null),
      );
    }

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
              // ── 1. Header with Hero Banner, Advisor Badge & Switch Mode Button ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E1B4B),
                      Color(0xFF2E1065),
                      Color(0xFF4C1D95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C1D95).withValues(alpha: 0.25),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
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
                                'Class Advisor',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFF4C1D95)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You are the class advisor for',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFC4B5FD),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$sectionName • Academic Year $academicYear',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onSwitchToTeachingMode != null)
                          OutlinedButton(
                            onPressed: widget.onSwitchToTeachingMode,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC4B5FD)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Go to Teaching View',
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

              // ── 2. Top Metric Cards ──
              Row(
                children: [
                  Expanded(
                    child: StaffMetricCard(
                      title: 'Students',
                      value: '${summary.totalStudents}',
                      icon: Icons.groups_rounded,
                      iconColor: AppColors.staffRole,
                      gradientColors: const [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                      isDense: true,
                      onTap: () => setState(() => _activeDirectoryFilter = 'all'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StaffMetricCard(
                      title: 'Attendance',
                      value: '${summary.overallAttendance.toInt()}%',
                      icon: Icons.insights_rounded,
                      iconColor: const Color(0xFF10B981),
                      gradientColors: const [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                      isDense: true,
                      onTap: () => setState(() => _activeDirectoryFilter = 'attendance'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StaffMetricCard(
                      title: 'Avg CGPA',
                      value: '${summary.averageCgpa}',
                      icon: Icons.school_rounded,
                      iconColor: const Color(0xFF2563EB),
                      gradientColors: const [
                        Color(0xFF3B82F6),
                        Color(0xFF1D4ED8),
                      ],
                      isDense: true,
                      onTap: () => setState(() => _activeDirectoryFilter = 'top'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StaffMetricCard(
                      title: 'At Risk',
                      value: '${summary.atRiskCount}',
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFDC2626),
                      gradientColors: const [
                        Color(0xFFEF4444),
                        Color(0xFFDC2626),
                      ],
                      isDense: true,
                      onTap: () => setState(() => _activeDirectoryFilter = 'at_risk'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 3. Class Overview ──
              AdvisorClassOverviewSection(
                onViewAll: () => setState(() => _activeDirectoryFilter = 'all'),
                onFilterCategory: (filter) => setState(() => _activeDirectoryFilter = filter),
              ),
              const SizedBox(height: 20),

              // ── 4. Class Attendance Ring + Students Requiring Attention ──
              AdvisorClassAttendanceSection(
                onViewAllStudents: () => setState(() => _activeDirectoryFilter = 'all'),
              ),
              const SizedBox(height: 20),

              // ── 5. Academic Performance (Internal 1, 2, Assignments + Top/Needs Cards) ──
              AdvisorAcademicPerformanceSection(
                onViewDetails: () => setState(() => _activeDirectoryFilter = 'all'),
                onFilterPerformers: (filter) => setState(() => _activeDirectoryFilter = filter),
              ),
              const SizedBox(height: 20),

              // ── 6. Students Requiring Attention (4 Categories: Low Attendance, Academic Risk, etc.) ──
              AdvisorAttentionSection(
                onCategorySelected: (category) => setState(() => _activeDirectoryFilter = category),
              ),
              const SizedBox(height: 20),

              // ── 7. Advisor Tasks Checklist ──
              AdvisorTasksSection(
                onViewAll: () {
                  if (widget.onNavigateToKey != null) {
                    widget.onNavigateToKey!(StaffNavKey.submissions);
                  } else {
                    widget.onNavigateToTab?.call(3);
                  }
                },
              ),
              const SizedBox(height: 20),

              // ── 8. Class Announcements & Leave/OD Approvals ──
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: AdvisorAnnouncementsSection(
                        onViewAll: () {
                          if (widget.onNavigateToKey != null) {
                            widget.onNavigateToKey!(StaffNavKey.announcements);
                          } else {
                            widget.onNavigateToTab?.call(13);
                          }
                        },
                        onNewAnnouncement: () {
                          if (widget.onNavigateToKey != null) {
                            widget.onNavigateToKey!(StaffNavKey.announcements);
                          } else {
                            widget.onNavigateToTab?.call(13);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 5,
                      child: AdvisorLeaveODSection(
                        onViewAll: () {
                          if (widget.onNavigateToKey != null) {
                            widget.onNavigateToKey!(StaffNavKey.advisorApprovals);
                          } else {
                            widget.onNavigateToTab?.call(16);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                AdvisorAnnouncementsSection(
                  onViewAll: () {
                    if (widget.onNavigateToKey != null) {
                      widget.onNavigateToKey!(StaffNavKey.announcements);
                    } else {
                      widget.onNavigateToTab?.call(13);
                    }
                  },
                  onNewAnnouncement: () {
                    if (widget.onNavigateToKey != null) {
                      widget.onNavigateToKey!(StaffNavKey.announcements);
                    } else {
                      widget.onNavigateToTab?.call(13);
                    }
                  },
                ),
                const SizedBox(height: 20),
                AdvisorLeaveODSection(
                  onViewAll: () {
                    if (widget.onNavigateToKey != null) {
                      widget.onNavigateToKey!(StaffNavKey.advisorApprovals);
                    } else {
                      widget.onNavigateToTab?.call(16);
                    }
                  },
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
