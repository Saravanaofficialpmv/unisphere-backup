import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/models/staff_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/staff_service.dart';
import 'package:unisphere/services/user_session_service.dart';
import 'package:unisphere/services/supabase_service.dart';
import 'package:unisphere/services/academic_schedule_service.dart';
import 'package:unisphere/providers/academic_schedule_provider.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/widgets/common/notification_sheet.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

import 'package:unisphere/screens/staff/modules/staff_assignment_creation.dart';
import 'package:unisphere/screens/staff/modules/staff_submission_review.dart';
import 'package:unisphere/screens/staff/modules/staff_student_directory.dart';
import 'package:unisphere/screens/staff/modules/staff_attendance_marking.dart';
import 'package:unisphere/screens/staff/modules/staff_marks_upload.dart';
import 'package:unisphere/screens/staff/modules/staff_nptel_verification_screen.dart';
import 'package:unisphere/screens/staff/modules/class_advisor_edit_requests_screen.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';
import 'package:unisphere/screens/staff/modules/advisor_hackathon_verification_screen.dart';

import 'package:unisphere/widgets/common/main_sidebar.dart';
import 'package:unisphere/widgets/common/notification_bell_button.dart';
import 'package:unisphere/screens/gallery/full_photo_gallery_screen.dart';
import 'package:unisphere/screens/student/modules/student_announcements_screen.dart';
import 'package:unisphere/screens/student/modules/student_library_screen.dart';
import 'package:unisphere/screens/features/academic_schedule_detail_screen.dart';

import 'package:unisphere/screens/staff/modules/adviser_resume_bank_screen.dart';
import 'package:unisphere/screens/staff/modules/staff_question_paper_upload_screen.dart';
import 'package:unisphere/screens/staff/staff_details_screen.dart';
import 'package:unisphere/screens/hod/modules/hod_syllabus_management_screen.dart';
import 'package:unisphere/screens/profile/profile_screen.dart';
import 'package:unisphere/core/theme/app_animations.dart';

String _resolveStaffName(StaffModel? profile, UserModel? user) {
  final profileName = profile?.fullName.trim();
  if (profileName != null && profileName.isNotEmpty && profileName != 'Demo Staff' && profileName != 'Staff Member') {
    return profileName;
  }
  final userName = user?.name.trim();
  if (userName != null && userName.isNotEmpty && userName != 'Demo Staff' && userName != 'User') {
    return userName;
  }
  if (profileName != null && profileName.isNotEmpty) {
    return profileName;
  }
  return 'Dr. K. Tharani Kumar';
}

class StaffDashboard extends ConsumerStatefulWidget {
  const StaffDashboard({super.key});

  @override
  ConsumerState<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends ConsumerState<StaffDashboard> {
  int _currentIndex = 0;
  Key _staffDetailsKey = UniqueKey();
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

  List<_StaffModuleTab> _buildAllModuleTabs() {
    return [
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'Staff Home', icon: Icons.dashboard_outlined),
        screen: StaffDetailsScreen(key: _staffDetailsKey, onBack: () => _handleNavigation(0)),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'Syllabus Management', icon: Icons.auto_stories_outlined),
        screen: const HodSyllabusManagementScreen(),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'Give Assignment', icon: Icons.assignment_outlined),
        screen: StaffAssignmentCreation(onCreated: () => _handleNavigation(3)),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Review Submissions',
          icon: Icons.rate_review_outlined,
          badge: '12',
        ),
        screen: const StaffSubmissionReview(),
      ),

      // ── SPECIAL ADVISOR MODULES (Gated to Class Advisors assigned by HOD) ──
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Student Directory',
          icon: Icons.people_outline,
          badge: 'ADVISOR',
        ),
        screen: const StaffStudentDirectory(),
        requiresAdvisor: true,
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Resume Bank',
          icon: Icons.description_outlined,
          badge: 'ADVISOR',
        ),
        screen: AdviserResumeBankScreen(onBack: _handleBackNavigation),
        requiresAdvisor: true,
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Profile Edit Requests',
          icon: Icons.edit_note_rounded,
          badge: 'ADVISOR',
        ),
        screen: const ClassAdvisorEditRequestsScreen(),
        requiresAdvisor: true,
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Student Approvals',
          icon: Icons.verified_user_outlined,
          badge: 'ADVISOR',
        ),
        screen: const HodStudentVerificationsScreen(),
        requiresAdvisor: true,
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'NPTEL Verification',
          icon: Icons.workspace_premium_outlined,
          badge: 'ADVISOR',
        ),
        screen: const StaffNptelVerificationScreen(),
        requiresAdvisor: true,
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Hackathon Approvals',
          icon: Icons.emoji_events_outlined,
          badge: 'ADVISOR',
        ),
        screen: const AdvisorHackathonVerificationScreen(),
        requiresAdvisor: true,
      ),

      // ── STANDARD TEACHING MODULES (Available to All Staff) ──
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'Upload Marks', icon: Icons.grade_outlined),
        screen: const StaffMarksUploadModule(),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'My Profile', icon: Icons.person_outline),
        screen: ProfileScreen(onBack: _handleBackNavigation),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Academic Schedule',
          icon: Icons.calendar_month_outlined,
        ),
        screen: AcademicScheduleDetailScreen(onBack: _handleBackNavigation),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'DIVIDER', icon: Icons.minimize),
        screen: const SizedBox.shrink(),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'Take Attendance', icon: Icons.how_to_reg_outlined),
        screen: const StaffAttendanceMarkingModule(),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Question Paper Upload',
          icon: Icons.upload_file_outlined,
        ),
        screen: StaffQuestionPaperUploadScreen(onBack: _handleBackNavigation),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(
          label: 'Campus Photo Gallery',
          icon: Icons.collections_outlined,
          badge: 'Gallery',
        ),
        screen: FullPhotoGalleryScreen(onBack: _handleBackNavigation),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'Announcements', icon: Icons.campaign_outlined),
        screen: StudentAnnouncementsScreen(onBack: _handleBackNavigation),
      ),
      _StaffModuleTab(
        sidebarItem: SidebarItem(label: 'Library Access', icon: Icons.local_library_outlined),
        screen: StudentLibraryScreen(onBack: _handleBackNavigation),
      ),
    ];
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
      _staffDetailsKey = UniqueKey();
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final currentUser =
        ref.watch(currentUserProvider).value ??
        ref.watch(authServiceProvider).currentUser;
    final staffProfileAsync = ref.watch(currentStaffProfileStreamProvider);
    final staffProfile = staffProfileAsync.value;
    final staffName = _resolveStaffName(staffProfile, currentUser);

    final isAdvisor = staffProfile?.isAdvisor ?? (currentUser?.role == UserRole.advisor);
    final advisorSection = staffProfile?.advisorSection;

    final allTabs = _buildAllModuleTabs();
    final activeTabs = allTabs.where((t) => !t.requiresAdvisor || isAdvisor).toList();
    final sidebarItems = activeTabs.map((t) => t.sidebarItem).toList();
    final screens = activeTabs.map((t) => t.screen).toList();
    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning! ☀️'
        : (hour < 17 ? 'Good Afternoon! ☀️' : 'Good Evening! 🌙');

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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                safeIndex == 0 && !(_innerNavigatorKey.currentState?.canPop() ?? false)
                    ? Icons.menu_rounded
                    : Icons.arrow_back_ios_new_rounded,
                color: const Color(0xFF1E293B),
                size: 20,
              ),
              onPressed: () {
                if (_innerNavigatorKey.currentState?.canPop() ?? false) {
                  _innerNavigatorKey.currentState?.pop();
                } else if (safeIndex != 0) {
                  _handleBackNavigation();
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
            ),
          ),
          title: safeIndex == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isAdvisor ? const Color(0xFFF5F3FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isAdvisor ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isAdvisor
                                ? (advisorSection != null && advisorSection.isNotEmpty
                                    ? 'Advisor ($advisorSection)'
                                    : 'Class Advisor')
                                : 'Teaching Faculty',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isAdvisor ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      staffName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                )
              : Text(
                  sidebarItems[safeIndex].label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: NotificationBellButton(
                unreadCount: 3,
                onTap: () => showNotificationSheet(context),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            if (isDesktop) _buildSidebar(sidebarItems),
            Expanded(
              child: ClipRect(
                child: Navigator(
                  key: _innerNavigatorKey,
                  onGenerateRoute: (settings) {
                    final activeScreen = screens[safeIndex];
                    return MaterialPageRoute(
                      builder: (_) => FadeSlideTransition(
                        transitionKey: ValueKey('staff_tab_$safeIndex'),
                        child: activeScreen,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(List<SidebarItem> items) {
    final currentUser =
        ref.watch(currentUserProvider).value ??
        ref.watch(authServiceProvider).currentUser;
    final staffProfileAsync = ref.watch(currentStaffProfileStreamProvider);
    final staffProfile = staffProfileAsync.value;
    final userName = _resolveStaffName(staffProfile, currentUser);
    final userEmail =
        (currentUser?.email != null && currentUser!.email.trim().isNotEmpty)
        ? currentUser.email
        : 'tharani.kumar@vsbec.edu.in';

    return MainSidebar(
      selectedIndex: _currentIndex < items.length ? _currentIndex : 0,
      onDestinationSelected: _handleNavigation,
      items: items,
      userName: userName,
      userEmail: userEmail,
    );
  }
}

class _StaffModuleTab {
  final SidebarItem sidebarItem;
  final Widget screen;
  final bool requiresAdvisor;

  const _StaffModuleTab({
    required this.sidebarItem,
    required this.screen,
    this.requiresAdvisor = false,
  });
}

class StaffHomeScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;
  const StaffHomeScreen({super.key, this.onNavigate});

  @override
  ConsumerState<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends ConsumerState<StaffHomeScreen> {
  bool _isReturningUser = true;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      final currentUser = ref.read(authServiceProvider).currentUser;
      final uid = currentUser?.uid ?? '';
      final sessionService = ref.read(userSessionServiceProvider);
      final isReturning = await sessionService.isReturningUser(uid);
      if (mounted) {
        setState(() {
          _isReturningUser = isReturning;
        });
      }
      if (!isReturning && uid.isNotEmpty) {
        await sessionService.markUserSessionSeen(uid);
      }
    } catch (e) {
      debugPrint('Error checking staff user session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final currentUser =
        ref.watch(currentUserProvider).value ??
        ref.watch(authServiceProvider).currentUser;
    final staffProfileAsync = ref.watch(currentStaffProfileStreamProvider);
    final staffProfile = staffProfileAsync.value;
    final staffName = _resolveStaffName(staffProfile, currentUser);

    return AppLiquidPullToRefresh(
      gifAsset: 'assets/tibsy-dp.gif',
      onRefresh: () async {
        ref.invalidate(currentUserProvider);
        ref.invalidate(staffServiceProvider);
        ref.invalidate(allTimetablesStreamProvider);
        ref.invalidate(notificationProvider);
        ref.invalidate(announcementsStreamProvider);
        ref.invalidate(assignmentsStreamProvider);
        ref.invalidate(academicScheduleServiceProvider);
        ref.invalidate(userAcademicScheduleProvider);
        ref.invalidate(allStudentsStreamProvider);
        await Future.delayed(const Duration(milliseconds: 1200));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 28,
          vertical: isMobile ? 16 : 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Purple Gradient Welcome Banner
                _buildWelcomeCard(staffName, isMobile),
                const SizedBox(height: 20),

              // 2. Metrics Statistics Grid (6 Stat Cards)
              _buildMetricsGrid(isMobile),
              const SizedBox(height: 24),

              // 3. Quick Actions Section
              _buildQuickActionsSection(context, isMobile),
              const SizedBox(height: 24),

              // 4. Upcoming Classes Section
              _buildUpcomingClassesSection(context, isMobile),
              const SizedBox(height: 24),

              // 5. Pending Leave Requests Section
              _buildPendingLeaveRequestsSection(context, isMobile),
              const SizedBox(height: 24),

              // 6. Recent Faculty Section
              _buildRecentFacultySection(context, isMobile),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildWelcomeCard(String name, bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 140 : 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4338CA), // Deep Indigo
            Color(0xFF4F46E5), // Royal Purple Blue
            Color(0xFF6366F1), // Bright Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background College Building Vector Graphic
            Positioned(
              right: -10,
              bottom: -10,
              top: -10,
              width: isMobile ? 180 : 260,
              child: CustomPaint(painter: CollegeBuildingPainter()),
            ),
            // Text Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 24,
                vertical: isMobile ? 18 : 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isReturningUser ? 'Welcome back,' : 'Welcome,',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Have a great day at VSB College!',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 3;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth < 400 ? 1.05 : 1.35,
          children: [
            _buildStatCard(
              '128',
              'Total Faculty',
              'All Members',
              Icons.groups_rounded,
              const Color(0xFFEEF2FF),
              const Color(0xFF4F46E5),
              isMobile,
            ),
            _buildStatCard(
              '110',
              'Active Faculty',
              'Currently Working',
              Icons.how_to_reg_rounded,
              const Color(0xFFECFDF5),
              const Color(0xFF10B981),
              isMobile,
            ),
            _buildStatCard(
              '06',
              'On Leave',
              'Currently on Leave',
              Icons.calendar_month_rounded,
              const Color(0xFFFFF7ED),
              const Color(0xFFF97316),
              isMobile,
            ),
            _buildStatCard(
              '12',
              'Departments',
              'Total Departments',
              Icons.domain_rounded,
              const Color(0xFFEFF6FF),
              const Color(0xFF2563EB),
              isMobile,
            ),
            _buildStatCard(
              '8.6',
              'Years',
              'Avg. Experience',
              Icons.business_center_rounded,
              const Color(0xFFFDF2F8),
              const Color(0xFFD946EF),
              isMobile,
            ),
            _buildStatCard(
              '05',
              'New Faculty',
              'This Month',
              Icons.person_add_alt_1_rounded,
              const Color(0xFFE0F2FE),
              const Color(0xFF0284C7),
              isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color bgIconColor,
    Color iconColor,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 36 : 42,
                height: isMobile ? 36 : 42,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: isMobile ? 18 : 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 11.5 : 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 9.5 : 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onNavigate?.call(4),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionButton(
              'Add Faculty',
              Icons.person_add_outlined,
              const Color(0xFFEEF2FF),
              const Color(0xFF4F46E5),
              onTap: () => _showAddFacultyDialog(context),
            ),
            _buildQuickActionButton(
              'Faculty List',
              Icons.fact_check_outlined,
              const Color(0xFFECFDF5),
              const Color(0xFF10B981),
              onTap: () => widget.onNavigate?.call(4),
            ),
            _buildQuickActionButton(
              'Attendance',
              Icons.calendar_month_outlined,
              const Color(0xFFFFF7ED),
              const Color(0xFFF97316),
              onTap: () => widget.onNavigate?.call(14),
            ),
            _buildQuickActionButton(
              'Leave Requests',
              Icons.assignment_outlined,
              const Color(0xFFFDF2F8),
              const Color(0xFFDB2777),
              onTap: () => widget.onNavigate?.call(7),
            ),
            _buildQuickActionButton(
              'Reports',
              Icons.trending_up_rounded,
              const Color(0xFFEFF6FF),
              const Color(0xFF2563EB),
              onTap: () => widget.onNavigate?.call(10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color bgCircleColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: bgCircleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassesSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onNavigate?.call(12),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildUpcomingClassItem(
                '09:00 AM',
                'Data Structures',
                'CSE - III Year A',
                'Room 301',
                const Color(0xFFDCFCE7),
                const Color(0xFF15803D),
              ),
              const Divider(
                height: 20,
                thickness: 0.6,
                color: Color(0xFFF1F5F9),
              ),
              _buildUpcomingClassItem(
                '10:00 AM',
                'Database Management',
                'CSE - II Year B',
                'Room 202',
                const Color(0xFFDBEAFE),
                const Color(0xFF1D4ED8),
              ),
              const Divider(
                height: 20,
                thickness: 0.6,
                color: Color(0xFFF1F5F9),
              ),
              _buildUpcomingClassItem(
                '11:00 AM',
                'Operating Systems',
                'CSE - III Year B',
                'Room 205',
                const Color(0xFFF3E8FF),
                const Color(0xFF7E22CE),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCBD5E1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCBD5E1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingClassItem(
    String time,
    String subject,
    String department,
    String room,
    Color bgChipColor,
    Color textChipColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 75,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4338CA),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                department,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgChipColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            room,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: textChipColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingLeaveRequestsSection(
    BuildContext context,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pending Leave Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onNavigate?.call(7),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildLeaveRequestItem(
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
                'Dr. Sarah Johnson',
                'Professor - CSE',
                'Annual Leave',
                '2 Days',
                'May 20, 2024',
              ),
              const Divider(
                height: 20,
                thickness: 0.6,
                color: Color(0xFFF1F5F9),
              ),
              _buildLeaveRequestItem(
                'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
                'Mr. Michael Brown',
                'Associate Professor - ECE',
                'Medical Leave',
                '3 Days',
                'May 21, 2024',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveRequestItem(
    String avatarUrl,
    String name,
    String designation,
    String leaveType,
    String duration,
    String date,
  ) {
    return Row(
      children: [
        CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                designation,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              leaveType,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              duration,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              date,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentFacultySection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Faculty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onNavigate?.call(4),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => widget.onNavigate?.call(4),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mrs. Emily Davis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Assistant Professor',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Mechanical Engineering',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddFacultyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final deptController = TextEditingController();
    final desigController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'Add New Faculty',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Faculty Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deptController,
                decoration: const InputDecoration(
                  labelText: 'Department (e.g. CSE, ECE)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: desigController,
                decoration: const InputDecoration(
                  labelText: 'Designation (e.g. Asst. Professor)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Faculty "${nameController.text.isEmpty ? 'Member' : nameController.text}" added successfully!',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Add Faculty'),
            ),
          ],
        );
      },
    );
  }
}

class CollegeBuildingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final centerX = size.width * 0.55;
    final topY = size.height * 0.18;

    // Triangle pediment
    final path = Path();
    path.moveTo(centerX, topY);
    path.lineTo(centerX - 45, topY + 25);
    path.lineTo(centerX + 45, topY + 25);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, fillPaint);

    // Dome on top
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, topY - 8), radius: 14),
      math.pi,
      math.pi,
      false,
      paint,
    );
    // Spire
    canvas.drawLine(
      Offset(centerX, topY - 22),
      Offset(centerX, topY - 32),
      paint,
    );

    // Facade rectangle
    final facadeRect = Rect.fromLTRB(
      centerX - 50,
      topY + 25,
      centerX + 50,
      size.height - 10,
    );
    canvas.drawRect(facadeRect, paint);

    // Vertical columns
    for (int i = -3; i <= 3; i += 2) {
      final colX = centerX + i * 12;
      canvas.drawLine(
        Offset(colX, topY + 25),
        Offset(colX, size.height - 10),
        paint,
      );
    }

    // Archway entrance
    final archRect = Rect.fromLTRB(
      centerX - 12,
      size.height - 35,
      centerX + 12,
      size.height - 10,
    );
    canvas.drawRect(archRect, paint);
    canvas.drawArc(
      Rect.fromLTWH(centerX - 12, size.height - 47, 24, 24),
      math.pi,
      math.pi,
      false,
      paint,
    );

    // Side wing left
    final leftWing = Rect.fromLTRB(
      centerX - 95,
      topY + 40,
      centerX - 50,
      size.height - 10,
    );
    canvas.drawRect(leftWing, paint);
    canvas.drawRect(Rect.fromLTWH(centerX - 85, topY + 50, 10, 14), paint);
    canvas.drawRect(Rect.fromLTWH(centerX - 68, topY + 50, 10, 14), paint);

    // Side wing right
    final rightWing = Rect.fromLTRB(
      centerX + 50,
      topY + 40,
      centerX + 95,
      size.height - 10,
    );
    canvas.drawRect(rightWing, paint);
    canvas.drawRect(Rect.fromLTWH(centerX + 58, topY + 50, 10, 14), paint);
    canvas.drawRect(Rect.fromLTWH(centerX + 75, topY + 50, 10, 14), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
