import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/repositories/department_repository.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/main_sidebar.dart';
import 'package:unisphere/widgets/common/notification_sheet.dart';
import 'package:unisphere/widgets/common/department_vision_sheet.dart';
import 'package:unisphere/widgets/common/notification_bell_button.dart';
import 'package:unisphere/widgets/hod/hod_floating_nav_bar.dart';
import 'package:unisphere/core/responsive/responsive_breakpoints.dart';
import 'package:unisphere/widgets/common/app_desktop_shell.dart';
import 'package:unisphere/widgets/common/app_desktop_header.dart';
import 'package:unisphere/widgets/common/sign_out_confirmation_sheet.dart';

import 'hod_home_dashboard.dart';
import 'modules/hod_staff_management.dart';
import 'modules/hod_student_management.dart';
import 'modules/hod_academic_management.dart';
import 'modules/hod_attendance_management.dart';
import 'modules/hod_exam_management.dart';
import 'modules/hod_timetable_management.dart';
import 'modules/hod_leave_management.dart';
import 'modules/hod_announcements.dart';
import 'modules/hod_reports_analytics.dart';
import 'modules/hod_settings.dart';
import 'modules/hod_charter_upload_screen.dart';
import 'modules/hod_album_management_screen.dart';
import 'modules/hod_hackathon_management_screen.dart';

import '../staff/modules/hod_student_verifications_screen.dart';
import '../staff/modules/staff_nptel_verification_screen.dart';
import '../staff/modules/class_advisor_edit_requests_screen.dart';
import '../gallery/full_photo_gallery_screen.dart';
import '../common/manual_notification_composer_screen.dart';
import 'modules/hod_academic_schedule_screen.dart';
import 'modules/hod_resume_bank_screen.dart';
import 'modules/hod_syllabus_management_screen.dart';
import 'package:unisphere/core/theme/app_animations.dart';

class HodShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const HodShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HodShell> createState() => _HodShellState();
}

class _HodShellState extends ConsumerState<HodShell> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<SidebarItem> _sidebarItems = [
    SidebarItem(label: 'Home Dashboard', icon: Icons.dashboard_outlined), // 0
    SidebarItem(label: 'Dept Notifications', icon: Icons.send_rounded, badge: 'HOD'), // 1
    SidebarItem(label: 'Photo Albums Manager', icon: Icons.collections_outlined, badge: 'Gallery'), // 2
    SidebarItem(label: 'Staff Management', icon: Icons.badge_outlined), // 3
    SidebarItem(label: 'Student Management', icon: Icons.school_outlined), // 4
    SidebarItem(label: 'Student Verifications', icon: Icons.verified_user_outlined, badge: 'Verify'), // 5
    SidebarItem(label: 'Dept. Resume Bank', icon: Icons.description_outlined, badge: 'Resumes'), // 6
    SidebarItem(label: 'Profile Edit Requests', icon: Icons.edit_note_rounded, badge: 'Requests'), // 7
    SidebarItem(label: 'NPTEL Cert. Verification', icon: Icons.verified_user_outlined, badge: 'NPTEL'), // 8
    SidebarItem(label: 'Hackathons & Contests', icon: Icons.emoji_events_outlined, badge: 'HOD'), // 9
    SidebarItem(label: 'Reports & Analytics', icon: Icons.insights_outlined), // 10
    SidebarItem(label: 'Department Settings', icon: Icons.settings_outlined), // 11
    SidebarItem.divider('ACADEMIC MODULES'), // 12
    SidebarItem(label: 'Syllabus Management', icon: Icons.menu_book_rounded, badge: 'Syllabus'), // 13
    SidebarItem(label: 'Attendance Management', icon: Icons.fact_check_outlined), // 14
    SidebarItem(label: 'Academic Administration', icon: Icons.school_outlined), // 15
    SidebarItem(label: 'Timetable Management', icon: Icons.calendar_month_outlined), // 16
    SidebarItem(label: 'Examination & Marks', icon: Icons.assessment_outlined), // 17
    SidebarItem(label: 'Academic Schedule & Days', icon: Icons.event_note_rounded, badge: 'Official'), // 18
    SidebarItem(label: 'Leave & OD Approvals', icon: Icons.pending_actions_outlined, badge: '5'), // 19
    SidebarItem(label: 'CO / PO / PSO Uploads', icon: Icons.upload_file_rounded, badge: 'New'), // 20
    SidebarItem(label: 'Announcements', icon: Icons.campaign_outlined), // 21
    SidebarItem(label: 'Campus Photo Gallery', icon: Icons.collections_bookmark_outlined), // 22
  ];

  late final List<Widget> _screens;
  final List<int> _navigationHistory = [0];
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      HodHomeDashboard(onNavigate: _handleNavigation), // 0
      const ManualNotificationComposerScreen(), // 1
      const HodAlbumManagementScreen(), // 2
      const HodStaffManagement(), // 3
      const HodStudentManagement(), // 4
      const HodStudentVerificationsScreen(), // 5
      const HodResumeBankScreen(), // 6
      const ClassAdvisorEditRequestsScreen(), // 7
      const StaffNptelVerificationScreen(), // 8
      const HodHackathonManagementScreen(), // 9
      const HodReportsAnalytics(), // 10
      const HodSettings(), // 11
      const SizedBox.shrink(), // 12: Divider ACADEMIC MODULES
      const HodSyllabusManagementScreen(), // 13
      const HodAttendanceManagement(), // 14
      const HodAcademicManagement(), // 15
      const HodTimetableManagement(), // 16
      const HodExamManagement(), // 17
      const HodAcademicScheduleScreen(), // 18
      const HodLeaveManagement(), // 19
      const HodCharterUploadScreen(), // 20
      const HodAnnouncements(), // 21
      const FullPhotoGalleryScreen(), // 22
    ];
  }

  @override
  void didUpdateWidget(HodShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() => _currentIndex = widget.initialIndex);
    }
  }

  void _handleNavigation(int index, {bool isBack = false}) {
    if (index < 0 || index >= _screens.length) return;
    if (index < _sidebarItems.length && _sidebarItems[index].isDivider) return;
    if (index == _currentIndex) return;

    if (!isBack) {
      _navigationHistory.add(_currentIndex);
    }

    setState(() => _currentIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _handleBackNavigation() {
    if (_navigationHistory.isNotEmpty) {
      final prev = _navigationHistory.removeLast();
      _handleNavigation(prev, isBack: true);
    } else if (_currentIndex != 0) {
      _handleNavigation(0, isBack: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppResponsive.isDesktop(context);

    if (isDesktop) {
      final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
      final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
      final deptCode = (dept?.code != null && dept!.code.isNotEmpty && dept.code != 'CSE')
          ? dept.code
          : (currentUser?.departmentName != null && currentUser!.departmentName!.isNotEmpty
              ? DepartmentRepository.deriveDepartmentCode(currentUser.departmentName)
              : (currentUser?.department != null && currentUser!.department!.isNotEmpty
                  ? DepartmentRepository.deriveDepartmentCode(currentUser.department)
                  : (dept?.code ?? 'HOD')));
      final currentItem = (_currentIndex >= 0 && _currentIndex < _sidebarItems.length)
          ? _sidebarItems[_currentIndex]
          : _sidebarItems[0];
      final titleText = _currentIndex == 0
          ? '$deptCode Department Portal'
          : (currentItem.isDivider ? '$deptCode Portal' : currentItem.label);
      final userName = (currentUser?.fullName != null && currentUser!.fullName.trim().isNotEmpty)
          ? currentUser.fullName
          : ((currentUser?.name != null && currentUser!.name.trim().isNotEmpty)
              ? currentUser.name
              : 'Head of Department');

      return AppDesktopShell(
        sidebar: _buildSidebar(),
        header: AppDesktopHeader(
          onBack: _currentIndex != 0 ? _handleBackNavigation : null,
          breadcrumbs: _currentIndex == 0
              ? ['UniSphere', '$deptCode Department']
              : ['UniSphere', '$deptCode Department', titleText],
          title: titleText,
          subtitle: '$deptCode • HOD Governance & Management Center',
          departmentName: deptCode,
          roleName: 'HOD',
          roleColor: AppColors.hodRole,
          userName: userName,
          userPhotoUrl: currentUser?.metadata?['photoUrl'],
          extraActions: [
            IconButton(
              icon: const Icon(Icons.bolt_rounded, color: AppColors.hodRole),
              tooltip: 'Department Operations Action Center',
              onPressed: () => _showQuickActionsModal(context),
            ),
            IconButton(
              icon: const Icon(Icons.school_rounded, color: AppColors.hodRole),
              tooltip: 'My Dept Vision & Outcomes',
              onPressed: () => showDepartmentVisionSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.hodRole),
              tooltip: 'Department Settings',
              onPressed: () => _handleNavigation(11),
            ),
          ],
        ),
        body: FadeSlideTransition(
          transitionKey: ValueKey('hod_tab_$_currentIndex'),
          child: _screens[_currentIndex < _screens.length ? _currentIndex : 0],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Consumer(
          builder: (context, ref, _) {
            final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
            final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
            final deptCode = (dept?.code != null && dept!.code.isNotEmpty && dept.code != 'CSE')
                ? dept.code
                : (currentUser?.departmentName != null && currentUser!.departmentName!.isNotEmpty
                    ? DepartmentRepository.deriveDepartmentCode(currentUser.departmentName)
                    : (currentUser?.department != null && currentUser!.department!.isNotEmpty
                        ? DepartmentRepository.deriveDepartmentCode(currentUser.department)
                        : (dept?.code ?? 'HOD')));
            final currentItem = (_currentIndex >= 0 && _currentIndex < _sidebarItems.length)
                ? _sidebarItems[_currentIndex]
                : null;
            final titleText = _currentIndex == 0
                ? '$deptCode Department Portal'
                : (currentItem != null && !currentItem.isDivider ? currentItem.label : '$deptCode Portal');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (!isDesktop || _currentIndex != 0) ...[
                      const Icon(Icons.shield_outlined, color: AppColors.hodRole, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        titleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                if (_currentIndex == 0)
                  const Text(
                    'HOD Portal • Department Command Center',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            );
          },
        ),
        leading: _currentIndex == 0
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.shield_outlined, color: AppColors.hodRole, size: 24),
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: _handleBackNavigation,
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: AppColors.hodRole),
            tooltip: 'Department Operations Action Center',
            onPressed: () => _showQuickActionsModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.school_rounded, color: AppColors.hodRole),
            tooltip: 'My Dept Vision & Outcomes',
            onPressed: () => showDepartmentVisionSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            tooltip: 'Department Settings',
            onPressed: () => _handleNavigation(11),
          ),
          NotificationBellButton(
            onTap: () => showNotificationSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebar(),
                Expanded(
                  child: FadeSlideTransition(
                    transitionKey: ValueKey('hod_tab_$_currentIndex'),
                    child: _screens[_currentIndex < _screens.length ? _currentIndex : 0],
                  ),
                ),
              ],
            )
          : FadeSlideTransition(
              transitionKey: ValueKey('hod_tab_$_currentIndex'),
              child: _screens[_currentIndex < _screens.length ? _currentIndex : 0],
            ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(),
      floatingActionButton: null,
    ),
  );
}

  Widget _buildSidebar() {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final userName = (currentUser?.fullName != null && currentUser!.fullName.trim().isNotEmpty)
        ? currentUser.fullName
        : ((currentUser?.name != null && currentUser!.name.trim().isNotEmpty)
            ? currentUser.name
            : 'Head of Department');
    final userEmail = (currentUser?.email != null && currentUser!.email.trim().isNotEmpty)
        ? currentUser.email
        : 'hod@unisphere.edu';

    return MainSidebar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _handleNavigation,
      items: _sidebarItems,
      userName: userName,
      userEmail: userEmail,
      isCollapsed: _isSidebarCollapsed,
      onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
      roleBadge: 'HOD',
      roleColor: AppColors.hodRole,
    );
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: HodFloatingNavBar(
          currentIndex: _currentIndex,
          onHomeTap: () => _handleNavigation(0),
          onStaffTap: () => _handleNavigation(3),
          onStudentsTap: () => _handleNavigation(4),
          onReportsTap: () => _handleNavigation(10),
          onLogoutTap: () => showSignOutConfirmationSheet(context, ref),
        ),
      ),
    );
  }

  void _showQuickActionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.hodRole.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppColors.hodRole, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Quick Department Actions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildQuickActionTile(
                  context,
                  icon: Icons.campaign_outlined,
                  title: 'Broadcast Dept Announcement',
                  subtitle: 'Send notices to faculty, students, or classes',
                  targetIndex: 21,
                ),
                _buildQuickActionTile(
                  context,
                  icon: Icons.pending_actions_outlined,
                  title: 'Approve Pending Leave / OD',
                  subtitle: 'Review student & faculty leave applications',
                  targetIndex: 19,
                ),
                _buildQuickActionTile(
                  context,
                  icon: Icons.insights_outlined,
                  title: 'Generate Department Report',
                  subtitle: 'Export attendance, marks, and faculty workload',
                  targetIndex: 10,
                ),
                _buildQuickActionTile(
                  context,
                  icon: Icons.badge_outlined,
                  title: 'Assign Class Advisor / Staff',
                  subtitle: 'Manage faculty assignments and class duties',
                  targetIndex: 3,
                ),
                _buildQuickActionTile(
                  context,
                  icon: Icons.assessment_outlined,
                  title: 'Review Exam Schedules',
                  subtitle: 'Manage internal exams, halls, and marks',
                  targetIndex: 17,
                ),
                _buildQuickActionTile(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: 'Student Verifications',
                  subtitle: 'Approve certificates, internships, and profiles',
                  targetIndex: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int targetIndex,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            _handleNavigation(targetIndex);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.hodRole.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.hodRole, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
