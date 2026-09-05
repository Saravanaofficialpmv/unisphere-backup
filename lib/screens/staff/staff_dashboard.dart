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
import 'package:unisphere/core/theme/app_animations.dart';

enum StaffNavKey {
  dashboard,
  advisorDashboard,
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
  const StaffDashboard({super.key});

  @override
  ConsumerState<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends ConsumerState<StaffDashboard> {
  int _currentIndex = 0;
  bool _overrideTeachingMode = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _innerNavigatorKey = GlobalKey<NavigatorState>();
  final List<int> _navigationHistory = [0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _handleNavigation(int index, {bool isBack = false}) {
    if (_innerNavigatorKey.currentState?.canPop() ?? false) {
      _innerNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
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
    if (_innerNavigatorKey.currentState?.canPop() ?? false) {
      _innerNavigatorKey.currentState?.pop();
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
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
              onNavigateToTab: (idx) => _handleNavigation(idx),
              onSwitchToAdvisorMode: null,
            );
          }
          return !_overrideTeachingMode
              ? AdvisorDashboard(
                  onNavigateToTab: (idx) {
                    if (idx == 12) {
                      _navigateToKey(StaffNavKey.timetable, activeNavKeys);
                    } else if (idx == 3) {
                      _navigateToKey(StaffNavKey.submissions, activeNavKeys);
                    } else if (idx == 14) {
                      _navigateToKey(StaffNavKey.attendance, activeNavKeys);
                    } else if (idx == 17) {
                      _navigateToKey(StaffNavKey.announcements, activeNavKeys);
                    } else {
                      _handleNavigation(idx);
                    }
                  },
                  onSwitchToTeachingMode: () => setState(() => _overrideTeachingMode = true),
                )
              : StaffHomeDashboard(
                  onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
                  onNavigateToTab: (idx) => _handleNavigation(idx),
                  onSwitchToAdvisorMode: () => setState(() => _overrideTeachingMode = false),
                );

        case StaffNavKey.dashboard:
          return StaffHomeDashboard(
            onNavigateToKey: (key) => _navigateToKey(key, activeNavKeys),
            onNavigateToTab: (idx) => _handleNavigation(idx),
            onSwitchToAdvisorMode: isAdvisor ? () => setState(() => _overrideTeachingMode = false) : null,
          );

        case StaffNavKey.advisorDirectory:
          return AdvisorStudentDirectoryScreen(onBack: _handleBackNavigation);

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
          return const StaffAttendanceMarkingModule();

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
          return const StaffStudentDirectory();

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: isDesktop ? null : Drawer(child: _buildSidebar(sidebarItems)),
        appBar: currentKey == StaffNavKey.profile
            ? null
            : AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                _currentIndex == 0 && !(_innerNavigatorKey.currentState?.canPop() ?? false)
                    ? Icons.menu_rounded
                    : Icons.arrow_back_ios_new_rounded,
                color: const Color(0xFF1E293B),
                size: 20,
              ),
              onPressed: () {
                if (_innerNavigatorKey.currentState?.canPop() ?? false) {
                  _innerNavigatorKey.currentState?.pop();
                } else if (_currentIndex != 0) {
                  _handleBackNavigation();
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
            ),
          ),
          title: _currentIndex == 0
              ? Row(
                  children: [
                    _buildVsbLogo(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VSB COLLEGE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            (isAdvisor && !_overrideTeachingMode)
                                ? 'Class Advisor Portal'
                                : 'Faculty Management System',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                              color: (isAdvisor && !_overrideTeachingMode)
                                  ? AppColors.staffRole
                                  : AppColors.textSecondary,
                            ),
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
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.school_rounded,
                color: AppColors.staffRole,
                size: 22,
              ),
              tooltip: 'Department Vision & POs',
              onPressed: () => showDepartmentVisionSheet(context),
            ),
            NotificationBellButton(
              unreadCount: 3,
              onTap: () => showNotificationSheet(context),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _navigateToKey(StaffNavKey.profile, activeNavKeys),
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.staffRole.withValues(alpha: 0.1),
                  backgroundImage: staff?.photoPath != null && staff!.photoPath!.isNotEmpty
                      ? NetworkImage(staff.photoPath!)
                      : const NetworkImage(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                        ),
                ),
              ),
            ),
          ],
        ),
        body: isDesktop
            ? Row(
                children: [
                  _buildSidebar(sidebarItems),
                  const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                  Expanded(
                    child: ClipRect(
                      child: Navigator(
                        key: _innerNavigatorKey,
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (_) => FadeSlideTransition(
                            transitionKey: ValueKey('staff_tab_${currentKey.name}_$_currentIndex'),
                            duration: const Duration(milliseconds: 180),
                            child: screenForNavKey(currentKey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ClipRect(
                child: Navigator(
                  key: _innerNavigatorKey,
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (_) => FadeSlideTransition(
                      transitionKey: ValueKey('staff_tab_${currentKey.name}_$_currentIndex'),
                      duration: const Duration(milliseconds: 180),
                      child: screenForNavKey(currentKey),
                    ),
                  ),
                ),
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
    );
  }

  Widget _buildVsbLogo() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.staffRole,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'V',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
