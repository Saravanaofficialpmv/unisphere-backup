import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/providers/academic_overview_provider.dart';
import 'package:unisphere/widgets/common/app_kpi_card.dart';
import 'package:unisphere/widgets/common/app_page_header.dart';
import 'package:unisphere/widgets/common/app_responsive_grid.dart';
import 'package:unisphere/widgets/common/latest_photo_gallery_card.dart';
import 'package:unisphere/widgets/student/student_profile_completion_banner.dart';

/// Professional desktop-first Home Command Center for the Student Portal.
/// Designed specifically for widescreen viewports (>= 800px) with high data density.
class StudentDesktopHomeView extends ConsumerWidget {
  final Function(int index, {bool openCalculator}) onNavigateToTab;

  const StudentDesktopHomeView({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final overviewData = ref.watch(academicOverviewProvider);

    final String studentName = currentUser?.fullName ??
        currentUser?.name ??
        (currentUser?.email.split('@').first ?? 'Student');
    final String regNo = (currentUser?.metadata?['registerNumber'] ??
            currentUser?.metadata?['regNo'] ??
            '')
        .toString()
        .trim();
    final String deptName = currentUser?.metadata?['department']?.toString() ??
        currentUser?.departmentName ??
        currentUser?.department ??
        '';
    final String semester = currentUser?.metadata?['semester']?.toString() ??
        currentUser?.metadata?['year']?.toString() ??
        '';

    final String cgpaValue = overviewData.cgpa > 0
        ? overviewData.cgpa.toStringAsFixed(2)
        : '-';
    final String attendanceValue = overviewData.attendancePercentage > 0
        ? '${overviewData.attendancePercentage.toStringAsFixed(1)}%'
        : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Page Header with Title and Quick Action Buttons
          AppPageHeader(
            title: 'Student Academic Command Center',
            subtitle: 'Welcome back, $studentName${deptName.isNotEmpty ? ' • B.Tech $deptName' : ''}${semester.isNotEmpty ? ' • $semester' : ''}${regNo.isNotEmpty ? ' • Reg: $regNo' : ''}',
            icon: Icons.dashboard_rounded,
            accentColor: AppColors.studentRole,
            actions: [
              OutlinedButton.icon(
                onPressed: () => StudentProfileCompletionBanner.openSheet(context),
                icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                label: const Text('Complete Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E40AF),
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigateToTab(1),
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const Text('Timetable Schedule'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigateToTab(5),
                icon: const Icon(Icons.badge_outlined, size: 16),
                label: const Text('Hall Ticket & Exams'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => onNavigateToTab(19),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Professional Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.studentRole,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          // 2. Interactive Profile Completion Banner (Draft / Under Review / Revision / Verified)
          const StudentProfileCompletionBanner(
            margin: EdgeInsets.only(top: 20, bottom: 20),
          ),

          // 3. High-Density KPI Row (4 Core Metrics)
          AppResponsiveGrid(
            spacing: 16,
            runSpacing: 16,
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 2,
            largeDesktopColumns: 4,
            children: [
              AppKpiCard(
                title: 'Cumulative GPA',
                value: '$cgpaValue CGPA',
                subtitle: 'Target: 9.00 • Class Rank: Top 5%',
                icon: Icons.calculate_rounded,
                accentColor: AppColors.primary,
                trend: '+0.12 CGPA',
                isPositiveTrend: true,
                badge: 'Standing: Excellent',
                onTap: () => onNavigateToTab(7),
              ),
              AppKpiCard(
                title: 'Overall Attendance',
                value: attendanceValue,
                subtitle: 'Min Requirement: 75% • Total 262 Hrs',
                icon: Icons.calendar_today_rounded,
                accentColor: AppColors.success,
                trend: 'Compliant',
                isPositiveTrend: true,
                badge: 'Exam Eligible',
                onTap: () => onNavigateToTab(3),
              ),
              AppKpiCard(
                title: 'Tasks & Deadlines',
                value: '4 Active',
                subtitle: '2 Submissions due this week',
                icon: Icons.assignment_turned_in_rounded,
                accentColor: AppColors.warning,
                badge: 'Action Needed',
                onTap: () => onNavigateToTab(2),
              ),
              AppKpiCard(
                title: 'Degree Earned Credits',
                value: '124 / 160',
                subtitle: 'Semester VI • 77.5% Curriculum Complete',
                icon: Icons.school_rounded,
                accentColor: AppColors.timetableAccent,
                badge: 'On Track',
                onTap: () => onNavigateToTab(4),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. Main Desktop 2-Column Split View (65% Left / 35% Right)
          LayoutBuilder(
            builder: (context, constraints) {
              final isUltraWide = constraints.maxWidth >= 1000;

              if (!isUltraWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAcademicScheduleCard(context),
                    const SizedBox(height: 20),
                    _buildQuickActionHub(context),
                    const SizedBox(height: 20),
                    _buildNoticeBoardCard(context),
                    const SizedBox(height: 20),
                    const LatestPhotoGalleryCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Primary Content (62% width)
                  Expanded(
                    flex: 62,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAcademicScheduleCard(context),
                        const SizedBox(height: 20),
                        _buildExamAndMarksSnapshot(context, overviewData),
                        const SizedBox(height: 20),
                        _buildCodingAndSkillsCard(context, overviewData),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right Command Panel (38% width)
                  Expanded(
                    flex: 38,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildVerifiedProfileCard(context, currentUser, studentName, regNo, deptName, semester),
                        const SizedBox(height: 20),
                        _buildQuickActionHub(context),
                        const SizedBox(height: 20),
                        _buildNoticeBoardCard(context),
                        const SizedBox(height: 20),
                        const LatestPhotoGalleryCard(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicScheduleCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Today's Academic Schedule",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => onNavigateToTab(1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('Full Timetable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.event_available_outlined, size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text('No classes scheduled for today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                const Text('Check the full timetable for upcoming schedules.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamAndMarksSnapshot(BuildContext context, AcademicOverviewData overview) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.gradesAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Continuous Assessment & Internal Marks',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => onNavigateToTab(4),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('Gradebook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSubjectMetricBox('CS3601', 'Cloud Systems', '48 / 50', '96%', AppColors.success),
              const SizedBox(width: 12),
              _buildSubjectMetricBox('AI3502', 'Deep Learning', '45 / 50', '90%', AppColors.primary),
              const SizedBox(width: 12),
              _buildSubjectMetricBox('CS3602', 'Comp Networks', '44 / 50', '88%', AppColors.info),
              const SizedBox(width: 12),
              _buildSubjectMetricBox('IT3501', 'Web Architecture', '47 / 50', '94%', AppColors.timetableAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectMetricBox(String code, String title, String score, String pct, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(code, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                Text(pct, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(score, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCodingAndSkillsCard(BuildContext context, AcademicOverviewData overview) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.terminal_rounded, size: 20, color: AppColors.primaryDark),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Developer Profile & Coding Progress',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => onNavigateToTab(14),
                    icon: const Icon(Icons.code_rounded, size: 14),
                    label: const Text('LeetCode', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => onNavigateToTab(15),
                    icon: const Icon(Icons.hub_rounded, size: 14),
                    label: const Text('GitHub', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.code_rounded, color: Colors.amber, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('LeetCode Problems', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('${overview.leetcodeSolved} Solved', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fork_right_rounded, color: Colors.blueGrey, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GitHub Commits (Year)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('${overview.githubCommits} Commits', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedProfileCard(
    BuildContext context,
    UserModel? user,
    String name,
    String regNo,
    String dept,
    String sem,
  ) {
    final meta = user?.metadata ?? {};
    final batch = meta['batch']?.toString() ?? (meta['year'] != null ? '${meta['year']}' : '—');
    final advisor = meta['advisorName']?.toString() ?? meta['advisor']?.toString() ?? '—';
    final email = (user?.email != null && user!.email.isNotEmpty) ? user.email : '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Reg: $regNo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('VERIFIED STUDENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _buildProfileDetailRow('Department', dept.isNotEmpty ? dept : '—'),
          const SizedBox(height: 6),
          _buildProfileDetailRow('Current Batch', batch),
          const SizedBox(height: 6),
          _buildProfileDetailRow('Academic Advisor', advisor),
          const SizedBox(height: 6),
          _buildProfileDetailRow('College Email', email),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionHub(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.grid_view_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Institutional ERP Shortcuts',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildShortcutChip('Fee Payment', Icons.payments_outlined, AppColors.feesAccent, () => onNavigateToTab(10)),
              _buildShortcutChip('Exams & Hall Ticket', Icons.badge_outlined, AppColors.gradesAccent, () => onNavigateToTab(5)),
              _buildShortcutChip('PYQ Papers', Icons.quiz_outlined, AppColors.timetableAccent, () => onNavigateToTab(9)),
              _buildShortcutChip('Academic Syllabus', Icons.menu_book_outlined, AppColors.assignmentAccent, () => onNavigateToTab(8)),
              _buildShortcutChip('Hackathons', Icons.sports_score_outlined, AppColors.hackathonAccent, () => onNavigateToTab(12)),
              _buildShortcutChip('Certifications', Icons.workspace_premium_outlined, AppColors.eventsAccent, () => onNavigateToTab(13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeBoardCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.campaign_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Campus Notice Board',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onNavigateToTab(22),
                child: const Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildNoticeItem('Internal Assessment II Timetable released by COE', '2 hours ago', true),
          const SizedBox(height: 8),
          _buildNoticeItem('Final Year Project Phase 1 Demonstration dates announced', 'Yesterday', false),
          const SizedBox(height: 8),
          _buildNoticeItem('Annual Technical Symposium registration is now live', '3 days ago', false),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String title, String time, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUrgent ? AppColors.error : AppColors.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
