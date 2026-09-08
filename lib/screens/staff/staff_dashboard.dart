import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/main_sidebar.dart';
import 'package:unisphere/widgets/common/department_vision_sheet.dart';
import 'package:unisphere/widgets/common/notification_bell_button.dart';
import 'package:unisphere/widgets/common/notification_sheet.dart';
import 'package:unisphere/core/responsive/responsive_breakpoints.dart';
import 'package:unisphere/core/theme/app_animations.dart';
import 'package:unisphere/widgets/common/app_desktop_shell.dart';
import 'package:unisphere/widgets/common/app_desktop_header.dart';
import 'package:unisphere/widgets/common/unisphere_bottom_nav_bar.dart';
import 'package:unisphere/widgets/common/sign_out_confirmation_sheet.dart';

// Staff Modules
import 'package:unisphere/screens/staff/modules/staff_home/staff_home_dashboard.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_dashboard.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_student_directory.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_parent_communication.dart';
import 'package:unisphere/screens/staff/modules/staff_assignment_creation.dart';
import 'package:unisphere/screens/staff/modules/staff_submission_review.dart';
import 'package:unisphere/screens/staff/modules/staff_student_directory.dart';
import 'package:unisphere/screens/staff/modules/staff_attendance_marking.dart';
import 'package:unisphere/screens/staff/modules/staff_marks_upload.dart';
import 'package:unisphere/screens/staff/modules/staff_nptel_verification_screen.dart';
import 'package:unisphere/screens/staff/modules/class_advisor_edit_requests_screen.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';
import 'package:unisphere/screens/staff/modules/advisor_hackathon_verification_screen.dart';
import 'package:unisphere/screens/staff/modules/adviser_resume_bank_screen.dart';
import 'package:unisphere/screens/staff/modules/staff_question_paper_upload_screen.dart';
import 'package:unisphere/screens/hod/modules/hod_syllabus_management_screen.dart';
import 'package:unisphere/screens/staff/staff_profile_screen.dart';
import 'package:unisphere/screens/features/academic_schedule_detail_screen.dart';
import 'package:unisphere/screens/gallery/full_photo_gallery_screen.dart';
import 'package:unisphere/screens/student/modules/student_announcements_screen.dart';
import 'package:unisphere/screens/student/modules/student_library_screen.dart';
import 'package:unisphere/screens/staff/modules/shared/staff_access_denied_view.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_today_schedule_screen.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_pending_tasks_screen.dart';

enum StaffNavKey {
  dashboard,
  advisorDashboard,
  todayClasses,
  pendingTasks,
  advisorDirectory,
  parentCommunication,
  advisorApprovals,
  advisorEditRequests,
  advisorResumeBank,
  advisorNptel,
  advisorHackathons,
  timetable,
  attendance,
  marks,
  assignments,
  submissions,
  questionPapers,
  studentDirectory,
  syllabus,
  announcements,
  library,
  gallery,
  profile,
}

class StaffDashboard extends ConsumerStatefulWidget {
  final int initialIndex;
  const StaffDashboard({super.key, this.initialIndex = 0});

  @override
  ConsumerState<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends ConsumerState<StaffDashboard> {
  late int _currentIndex;
  bool _overrideTeachingMode = false;
  bool _isSidebarCollapsed = false;
  String? _selectedClassFilter;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int> _navigationHistory = [0];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  void didUpdateWidget(StaffDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() => _currentIndex = widget.initialIndex);
    }
  }

  void _handleNavigation(int index, {bool isBack = false}) {
    if (index == _currentIndex) return;

    if (!isBack) {
      _navigationHistory.add(_currentIndex);
    }

    setState(() {
      _currentIndex = index;
    });
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

  void _navigateToKey(StaffNavKey key, List<StaffNavKey> activeKeys) {
    final targetIndex = activeKeys.indexOf(key);
    if (targetIndex != -1) {
      _handleNavigation(targetIndex);
    }
  }

  void _handleLegacyTabNavigation(int idx, List<StaffNavKey> activeNavKeys) {
    StaffNavKey? targetKey;
    switch (idx) {
      case 0:
        targetKey = activeNavKeys.contains(StaffNavKey.advisorDashboard) && !_overrideTeachingMode
            ? StaffNavKey.advisorDashboard
            : StaffNavKey.dashboard;
        break;
      case 1:
        targetKey = StaffNavKey.syllabus;
        break;
      case 2:
        targetKey = StaffNavKey.assignments;
        break;
      case 3:
        targetKey = StaffNavKey.submissions;
        break;
      case 4:
        targetKey = StaffNavKey.studentDirectory;
        break;
      case 5:
        targetKey = StaffNavKey.advisorEditRequests;
        break;
      case 6:
        targetKey = StaffNavKey.advisorResumeBank;
        break;
      case 7:
        targetKey = StaffNavKey.advisorNptel;
        break;
      case 8:
        targetKey = StaffNavKey.advisorHackathons;
        break;
      case 9:
        targetKey = StaffNavKey.advisorDirectory;
        break;
      case 10:
        targetKey = StaffNavKey.marks;
        break;
      case 11:
        targetKey = StaffNavKey.profile;
        break;
      case 12:
        targetKey = StaffNavKey.timetable;
        break;
      case 13:
      case 17:
        targetKey = StaffNavKey.announcements;
        break;
      case 14:
        targetKey = StaffNavKey.attendance;
        break;
      case 15:
        targetKey = StaffNavKey.questionPapers;
        break;
      case 16:
        targetKey = StaffNavKey.advisorApprovals;
        break;
      case 18:
        targetKey = StaffNavKey.library;
        break;
      case 19:
        targetKey = StaffNavKey.gallery;
        break;
      case 20:
        targetKey = StaffNavKey.todayClasses;
        break;
      case 21:
        targetKey = StaffNavKey.pendingTasks;
        break;
      default:
        if (idx >= 0 && idx < activeNavKeys.length) {
          _handleNavigation(idx);
          return;
        }
        break;
    }

    if (targetKey != null) {
      _navigateToKey(targetKey, activeNavKeys);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppResponsive.isDesktop(context);
    final isAdvisor = ref.watch(isClassAdvisorProvider);
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final staff = profileAsync.valueOrNull;

    // ── Build Dynamic Navigation Keys Based on Active Role ──
    final List<StaffNavKey> activeNavKeys = [];
    final List<SidebarItem> sidebarItems = [];

    if (isAdvisor) {
      // Class Advisor Role Navigation (Advisor Mode + Faculty Mode)
      activeNavKeys.add(StaffNavKey.advisorDashboard);
      sidebarItems.add(SidebarItem(
        label: _overrideTeachingMode ? 'Teaching Dashboard' : 'Advisor Dashboard',
        icon: _overrideTeachingMode ? Icons.dashboard_rounded : Icons.stars_rounded,
        badge: _overrideTeachingMode ? 'TEACHING' : 'ADVISOR',
      ));

      activeNavKeys.add(StaffNavKey.advisorDirectory);
      sidebarItems.add(SidebarItem(
        label: 'Class Student Directory',
        icon: Icons.supervised_user_circle_outlined,
        badge: staff?.advisorSection ?? 'III CSE - A',
      ));

      activeNavKeys.add(StaffNavKey.parentCommunication);
      sidebarItems.add(SidebarItem(
        label: 'Parent Communication',
        icon: Icons.contact_phone_outlined,
      ));

      activeNavKeys.add(StaffNavKey.advisorApprovals);
      sidebarItems.add(SidebarItem(
        label: 'Student Approvals',
        icon: Icons.verified_user_outlined,
        badge: '3',
      ));

      activeNavKeys.add(StaffNavKey.advisorEditRequests);
      sidebarItems.add(SidebarItem(
        label: 'Profile Edit Requests',
        icon: Icons.edit_note_rounded,
        badge: '5',
      ));

      activeNavKeys.add(StaffNavKey.advisorResumeBank);
      sidebarItems.add(SidebarItem(
        label: 'Resume Bank',
        icon: Icons.description_outlined,
        badge: '45',
      ));

      activeNavKeys.add(StaffNavKey.advisorNptel);
      sidebarItems.add(SidebarItem(
        label: 'NPTEL Verification',
        icon: Icons.workspace_premium_outlined,
        badge: '8',
      ));

      activeNavKeys.add(StaffNavKey.advisorHackathons);
      sidebarItems.add(SidebarItem(
        label: 'Hackathon Approvals',
        icon: Icons.emoji_events_outlined,
        badge: '2',
      ));

      // Divider for Teaching & Subjects
      sidebarItems.add(SidebarItem.divider('TEACHING & FACULTY'));
      activeNavKeys.add(StaffNavKey.timetable); // maps to timetable
    } else {
      // Normal Staff Role Navigation (Strictly Teaching & Subject Features)
      activeNavKeys.add(StaffNavKey.dashboard);
      sidebarItems.add(SidebarItem(
        label: 'Staff Dashboard',
        icon: Icons.dashboard_rounded,
      ));
    }

    // Common Faculty Teaching Features (Available to Normal Staff and Class Advisor)
    if (!isAdvisor) {
      activeNavKeys.add(StaffNavKey.timetable);
    }
    sidebarItems.add(SidebarItem(
      label: 'Timetable & Schedule',
      icon: Icons.calendar_month_outlined,
    ));

    activeNavKeys.add(StaffNavKey.todayClasses);
    sidebarItems.add(SidebarItem(
      label: "Today's Schedule",
      icon: Icons.schedule_rounded,
    ));

    activeNavKeys.add(StaffNavKey.pendingTasks);
    sidebarItems.add(SidebarItem(
      label: 'Task Review Center',
      icon: Icons.pending_actions_rounded,
    ));

    activeNavKeys.add(StaffNavKey.attendance);
    sidebarItems.add(SidebarItem(
      label: 'Take Attendance',
      icon: Icons.how_to_reg_outlined,
    ));

    activeNavKeys.add(StaffNavKey.marks);
    sidebarItems.add(SidebarItem(
      label: 'Upload Marks',
      icon: Icons.grade_outlined,
    ));

    activeNavKeys.add(StaffNavKey.assignments);
    sidebarItems.add(SidebarItem(
      label: 'Give Assignment',
      icon: Icons.assignment_outlined,
    ));

    activeNavKeys.add(StaffNavKey.submissions);
    sidebarItems.add(SidebarItem(
      label: 'Review Submissions',
      icon: Icons.rate_review_outlined,
      badge: '12',
    ));

    activeNavKeys.add(StaffNavKey.questionPapers);
    sidebarItems.add(SidebarItem(
      label: 'Question Paper Upload',
      icon: Icons.upload_file_outlined,
    ));

    activeNavKeys.add(StaffNavKey.syllabus);
    sidebarItems.add(SidebarItem(
      label: isAdvisor ? 'Syllabus Management' : 'Assigned Subjects & Classes',
      icon: Icons.auto_stories_outlined,
    ));

    activeNavKeys.add(StaffNavKey.studentDirectory);
    sidebarItems.add(SidebarItem(
      label: 'Faculty Student Directory',
      icon: Icons.people_outline,
    ));

    activeNavKeys.add(StaffNavKey.announcements);
    sidebarItems.add(SidebarItem(
      label: 'Announcements',
      icon: Icons.campaign_outlined,
    ));

    activeNavKeys.add(StaffNavKey.library);
    sidebarItems.add(SidebarItem(
      label: 'Library Access',
      icon: Icons.local_library_outlined,
    ));

    activeNavKeys.add(StaffNavKey.gallery);
    sidebarItems.add(SidebarItem(
      label: 'Campus Photo Gallery',
      icon: Icons.collections_outlined,
      badge: 'Gallery',
    ));

    activeNavKeys.add(StaffNavKey.profile);
    sidebarItems.add(SidebarItem(
      label: 'My Profile',
      icon: Icons.person_outline,
    ));

    // ── Build Screen for Currently Selected Key ──
    final currentKey = (_currentIndex < activeNavKeys.length)
        ? activeNavKeys[_currentIndex]
        : activeNavKeys.first;

    Widget screenForNavKey(StaffNavKey navKey) {
      // ── RBAC Security Guard: Advisor-only keys restricted from Normal Staff ──
      final isAdvisorOnlyKey = navKey == StaffNavKey.advisorDirectory ||
          navKey == StaffNavKey.parentCommunication ||
          navKey == StaffNavKey.advisorApprovals ||
          navKey == StaffNavKey.advisorEditRequests ||
          navKey == StaffNavKey.advisorResumeBank ||
          navKey == StaffNavKey.advisorNptel ||
          navKey == StaffNavKey.advisorHackathons;

      if (isAdvisorOnlyKey && !isAdvisor) {
        return StaffAccessDeniedView(
          title: 'Advisor Access Required',
          message:
              'This module is restricted to designated Class Advisors. Your account has standard faculty teaching permissions.',
          onGoBack: () => _navigateToKey(StaffNavKey.dashboard, activeNavKeys),
        );
      }

      switch (navKey) {
        case StaffNavKey.advisorDashboard:
          if (!isAdvisor) {
            return StaffHomeDashboard(
              onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
              onNavigateToTab: (idx) => _handleLegacyTabNavigation(idx, activeNavKeys),
              onSwitchToAdvisorMode: null,
            );
          }
          return !_overrideTeachingMode
              ? AdvisorDashboard(
                  onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
                  onNavigateToTab: (idx) => _handleLegacyTabNavigation(idx, activeNavKeys),
                  onSwitchToTeachingMode: () => setState(() => _overrideTeachingMode = true),
                )
              : StaffHomeDashboard(
                  onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
                  onNavigateToTab: (idx) => _handleLegacyTabNavigation(idx, activeNavKeys),
                  onSwitchToAdvisorMode: () => setState(() => _overrideTeachingMode = false),
                );

        case StaffNavKey.dashboard:
          return StaffHomeDashboard(
            onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
            onNavigateToTab: (idx) => _handleLegacyTabNavigation(idx, activeNavKeys),
            onSwitchToAdvisorMode: isAdvisor ? () => setState(() => _overrideTeachingMode = false) : null,
          );

        case StaffNavKey.todayClasses:
          return StaffTodayScheduleScreen(
            onBack: _handleBackNavigation,
            onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
            onViewClassStudents: (section) {
              setState(() => _selectedClassFilter = section);
              _navigateToKey(
                isAdvisor ? StaffNavKey.advisorDirectory : StaffNavKey.studentDirectory,
                activeNavKeys,
              );
            },
          );

        case StaffNavKey.pendingTasks:
          return StaffPendingTasksScreen(
            onBack: _handleBackNavigation,
            onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
          );

        case StaffNavKey.advisorDirectory:
          return AdvisorStudentDirectoryScreen(
            onBack: _handleBackNavigation,
            initialFilter: _selectedClassFilter != null ? 'all' : null,
          );

        case StaffNavKey.parentCommunication:
          return AdvisorParentCommunicationScreen(onBack: _handleBackNavigation);

        case StaffNavKey.advisorApprovals:
          return const HodStudentVerificationsScreen();

        case StaffNavKey.advisorEditRequests:
          return const ClassAdvisorEditRequestsScreen();

        case StaffNavKey.advisorResumeBank:
          return AdviserResumeBankScreen(onBack: _handleBackNavigation);

        case StaffNavKey.advisorNptel:
          return const StaffNptelVerificationScreen();

        case StaffNavKey.advisorHackathons:
          return const AdvisorHackathonVerificationScreen();

        case StaffNavKey.timetable:
          return AcademicScheduleDetailScreen(onBack: _handleBackNavigation);

        case StaffNavKey.attendance:
          return StaffAttendanceMarkingModule(
            onBack: _handleBackNavigation,
          );

        case StaffNavKey.marks:
          return const StaffMarksUploadModule();

        case StaffNavKey.assignments:
          return StaffAssignmentCreation(
            onCreated: () => _navigateToKey(StaffNavKey.submissions, activeNavKeys),
          );

        case StaffNavKey.submissions:
          return const StaffSubmissionReview();

        case StaffNavKey.questionPapers:
          return StaffQuestionPaperUploadScreen(onBack: _handleBackNavigation);

        case StaffNavKey.studentDirectory:
          return StaffStudentDirectory(
            initialSection: _selectedClassFilter,
            onBack: _handleBackNavigation,
          );

        case StaffNavKey.syllabus:
          return const HodSyllabusManagementScreen();

        case StaffNavKey.announcements:
          return StudentAnnouncementsScreen(onBack: _handleBackNavigation);

        case StaffNavKey.library:
          return StudentLibraryScreen(onBack: _handleBackNavigation);

        case StaffNavKey.gallery:
          return FullPhotoGalleryScreen(onBack: _handleBackNavigation);

        case StaffNavKey.profile:
          return StaffProfileScreen(
            onBack: _handleBackNavigation,
            onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
          );
      }
    }

    if (isDesktop) {
      final user = ref.watch(authServiceProvider).currentUser;
      final profileAsync = ref.watch(currentStaffProfileStreamProvider);
      final isAdvisor = ref.watch(isClassAdvisorProvider);
      final staff = profileAsync.valueOrNull;
      final currentTitle = _currentIndex < sidebarItems.length
          ? sidebarItems[_currentIndex].label
          : 'Staff Portal';
      final staffName = staff?.fullName ?? user?.name ?? 'Faculty Member';
      final deptName = staff?.departmentName ?? user?.department ?? 'Computer Science';

      final isHomeTab = _currentIndex == 0;
      final roleHeaderTitle = (isAdvisor && !_overrideTeachingMode)
          ? 'Class Advisor Portal'
          : 'Faculty Management System';

      return AppDesktopShell(
        sidebar: _buildSidebar(sidebarItems),
        header: AppDesktopHeader(
          onBack: _currentIndex != 0 ? _handleBackNavigation : null,
          breadcrumbs: isHomeTab
              ? ['UniSphere', 'ERP Portal']
              : ['UniSphere', roleHeaderTitle, currentTitle],
          title: isHomeTab ? roleHeaderTitle : currentTitle,
          subtitle: (isAdvisor && !_overrideTeachingMode)
              ? 'Class Advisor Workspace • Student Governance'
              : 'Faculty Academic Workspace',
          departmentName: deptName,
          roleName: isAdvisor ? 'Advisor' : 'Staff',
          roleColor: AppColors.staffRole,
          userName: staffName,
          userPhotoUrl: staff?.photoPath,
          extraActions: [
            IconButton(
              icon: const Icon(Icons.school_rounded, color: AppColors.staffRole, size: 22),
              tooltip: 'Department Vision & POs',
              onPressed: () => showDepartmentVisionSheet(context),
            ),
          ],
          onProfileTap: () => _navigateToKey(StaffNavKey.profile, activeNavKeys),
          onLogoutTap: () => showSignOutConfirmationSheet(context, ref),
        ),
        body: FadeSlideTransition(
          transitionKey: ValueKey('staff_tab_$currentKey'),
          duration: const Duration(milliseconds: 180),
          child: screenForNavKey(currentKey),
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
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: null,
        appBar: currentKey == StaffNavKey.profile
            ? null
            : AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          leadingWidth: _currentIndex != 0 ? 54 : 0,
          titleSpacing: _currentIndex != 0 ? 8 : 16,
          centerTitle: false,
          shape: const Border(
            bottom: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          leading: _currentIndex != 0
              ? Builder(
                  builder: (context) => Container(
                    margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _handleBackNavigation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1E293B),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          title: _currentIndex == 0
              ? Row(
                  children: [
                    _buildVsbLogo(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'VSB COLLEGE',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                                ),
                                child: Text(
                                  'CSE',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8.5,
                                    color: const Color(0xFF475569),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1.5),
                          Row(
                            children: [
                              Container(
                                width: 5.5,
                                height: 5.5,
                                margin: const EdgeInsets.only(right: 4.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isAdvisor && !_overrideTeachingMode)
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF10B981),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ((isAdvisor && !_overrideTeachingMode)
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF10B981))
                                          .withValues(alpha: 0.45),
                                      blurRadius: 4,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  (isAdvisor && !_overrideTeachingMode)
                                      ? 'Class Advisor Portal'
                                      : 'Faculty Management System',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                    color: (isAdvisor && !_overrideTeachingMode)
                                        ? AppColors.staffRole
                                        : AppColors.textSecondary,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(
                  _currentIndex < sidebarItems.length
                      ? sidebarItems[_currentIndex].label
                      : 'Staff Portal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => showDepartmentVisionSheet(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.staffRole,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            NotificationBellButton(
              unreadCount: 3,
              onTap: () => showNotificationSheet(context),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _navigateToKey(StaffNavKey.profile, activeNavKeys),
              child: Container(
                margin: const EdgeInsets.only(right: 6, left: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: staff?.photoPath != null && staff!.photoPath!.isNotEmpty
                            ? NetworkImage(staff.photoPath!)
                            : const NetworkImage(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                              ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Tooltip(
              message: 'Log Out',
              child: Container(
                margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12, left: 2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => showSignOutConfirmationSheet(context, ref),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFEE2E2), width: 1),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: FadeSlideTransition(
                transitionKey: ValueKey('staff_tab_${currentKey.name}_$_currentIndex'),
                duration: const Duration(milliseconds: 180),
                child: screenForNavKey(currentKey),
              ),
            ),
                  if (currentKey != StaffNavKey.profile)
                    Positioned(
                      bottom: math.max(16.0, MediaQuery.of(context).padding.bottom + 10.0),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: UnisphereBottomNavBar(
                          activeSlot: _resolveStaffNavSlot(currentKey),
                          unreadNotificationsCount: 3,
                          classesLabel: 'Classes',
                          classesIcon: Icons.assignment_outlined,
                          classesActiveIcon: Icons.assignment_rounded,
                          onHomeTap: () => _navigateToKey(
                            isAdvisor && !_overrideTeachingMode
                                ? StaffNavKey.advisorDashboard
                                : StaffNavKey.dashboard,
                            activeNavKeys,
                          ),
                          onClassesTap: () => _navigateToKey(StaffNavKey.timetable, activeNavKeys),
                          onCenterTap: () => _showStaffQuickLauncher(context, activeNavKeys, isAdvisor),
                          onNotificationsTap: () => showNotificationSheet(context),
                          onProfileTap: () => _navigateToKey(StaffNavKey.profile, activeNavKeys),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  UnisphereNavSlot _resolveStaffNavSlot(StaffNavKey currentKey) {
    switch (currentKey) {
      case StaffNavKey.dashboard:
      case StaffNavKey.advisorDashboard:
        return UnisphereNavSlot.home;
      case StaffNavKey.timetable:
      case StaffNavKey.attendance:
        return UnisphereNavSlot.classes;
      case StaffNavKey.announcements:
        return UnisphereNavSlot.notifications;
      case StaffNavKey.profile:
        return UnisphereNavSlot.profile;
      default:
        return UnisphereNavSlot.home;
    }
  }

  void _showStaffQuickLauncher(
    BuildContext context,
    List<StaffNavKey> activeNavKeys,
    bool isAdvisor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF0044CC)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CustomPaint(painter: UnisphereULogoPainter()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unisphere Quick Hub',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Faculty & Advisor Shortcuts',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildLauncherChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Attendance',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToKey(StaffNavKey.attendance, activeNavKeys);
                  },
                ),
                _buildLauncherChip(
                  icon: Icons.upload_file_rounded,
                  label: 'Upload Marks',
                  color: const Color(0xFF0066FF),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToKey(StaffNavKey.marks, activeNavKeys);
                  },
                ),
                _buildLauncherChip(
                  icon: Icons.assignment_outlined,
                  label: 'Assignments',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToKey(StaffNavKey.assignments, activeNavKeys);
                  },
                ),
                _buildLauncherChip(
                  icon: Icons.rate_review_outlined,
                  label: 'Submissions',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToKey(StaffNavKey.submissions, activeNavKeys);
                  },
                ),
                _buildLauncherChip(
                  icon: Icons.quiz_outlined,
                  label: 'Question Papers',
                  color: const Color(0xFFEC4899),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToKey(StaffNavKey.questionPapers, activeNavKeys);
                  },
                ),
                _buildLauncherChip(
                  icon: Icons.people_alt_outlined,
                  label: 'Student Directory',
                  color: const Color(0xFF06B6D4),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToKey(StaffNavKey.studentDirectory, activeNavKeys);
                  },
                ),
                if (isAdvisor) ...[
                  _buildLauncherChip(
                    icon: Icons.verified_user_outlined,
                    label: 'Approvals',
                    color: const Color(0xFF059669),
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToKey(StaffNavKey.advisorApprovals, activeNavKeys);
                    },
                  ),
                  _buildLauncherChip(
                    icon: Icons.contact_emergency_outlined,
                    label: 'Parents',
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToKey(StaffNavKey.parentCommunication, activeNavKeys);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLauncherChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(List<SidebarItem> items) {
    final user = ref.watch(authServiceProvider).currentUser;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final isAdvisor = ref.watch(isClassAdvisorProvider);
    final staff = profileAsync.valueOrNull;

    return MainSidebar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        if (index < items.length && items[index].isDivider) return;
        _handleNavigation(index);
      },
      items: items,
      userName: staff?.fullName ?? user?.name ?? 'Faculty Member',
      userEmail: isAdvisor ? 'Class Advisor • CSE' : 'Faculty • CSE',
      profileUrl: staff?.photoPath ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      isCollapsed: _isSidebarCollapsed,
      onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
      roleBadge: isAdvisor ? 'ADVISOR' : 'STAFF',
      roleColor: AppColors.staffRole,
    );
  }

  Widget _buildVsbLogo() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Center(
            child: Text(
              'V',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 18,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
