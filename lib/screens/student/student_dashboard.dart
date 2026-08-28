import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/theme/app_animations_kit.dart';
import 'package:unisphere/widgets/common/app_progress_indicators.dart';
import 'package:unisphere/screens/student/modules/student_upcoming_tasks_screen.dart';
import 'package:unisphere/widgets/common/main_sidebar.dart';
import 'package:unisphere/screens/student/gradebook_screen.dart';
import 'package:unisphere/screens/features/feature_hub_screen.dart';
import 'package:unisphere/screens/features/fees_screen.dart';
import 'package:unisphere/screens/features/hackathons_screen.dart';
import 'package:unisphere/models/hackathon_registration_model.dart';
import 'package:unisphere/controllers/hackathon_controller.dart';
import 'package:unisphere/controllers/hackathon_registration_controller.dart';
import 'package:unisphere/screens/features/certifications_screen.dart';
import 'package:unisphere/screens/features/achievements_screen.dart';
import 'package:unisphere/screens/features/events_screen.dart';
import 'package:unisphere/screens/profile/profile_screen.dart';
import 'package:unisphere/widgets/student/student_profile_completion_sheet.dart';
import 'package:unisphere/screens/student/modules/student_attendance_screen.dart';
import 'package:unisphere/screens/student/modules/student_announcements_screen.dart';
import 'package:unisphere/widgets/common/notification_sheet.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/screens/features/exams_detail_screen.dart';
import 'package:unisphere/providers/academic_overview_provider.dart';
import 'package:unisphere/providers/semester_attendance_provider.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';
import 'package:unisphere/screens/features/leetcode_detail_screen.dart';
import 'package:unisphere/screens/features/github_detail_screen.dart';
import 'package:unisphere/widgets/common/department_vision_sheet.dart';
import 'package:unisphere/widgets/common/notification_bell_button.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/user_session_service.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/widgets/student/student_membership_modal.dart';

import 'package:unisphere/widgets/common/recent_photos_section.dart';
import 'package:unisphere/screens/gallery/full_photo_gallery_screen.dart';
import 'package:unisphere/screens/student/cgpa_details_screen.dart';
import 'package:unisphere/screens/features/academic_schedule_detail_screen.dart';
import 'package:unisphere/providers/academic_schedule_provider.dart';
import 'package:unisphere/providers/gallery_provider.dart';
import 'package:unisphere/providers/post_od_provider.dart';
import 'package:unisphere/providers/gradebook_provider.dart';
import 'package:unisphere/core/theme/app_animations.dart';





import 'package:unisphere/screens/student/modules/student_resume_screen.dart';
import 'package:unisphere/screens/student/modules/student_syllabus_screen.dart';
import 'package:unisphere/screens/student/modules/student_pyq_screen.dart';
import 'package:unisphere/widgets/student/student_floating_nav_bar.dart';
import 'package:unisphere/widgets/student/student_navigation_sheet.dart';
import 'package:unisphere/widgets/common/sign_out_confirmation_sheet.dart';
import 'package:unisphere/screens/parent/parent_dashboard.dart' show ParentDashboard;

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentIndex = 0;
  bool _isNavigationSheetOpen = false;
  bool _isDockVisible = true;
  bool _openGpaPlannerInGradebook = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _innerNavigatorKey = GlobalKey<NavigatorState>();
  final List<int> _navigationHistory = [0];

  @override
  void initState() {
    super.initState();
  }

  final List<SidebarItem> _sidebarItems = [
    SidebarItem(label: 'Home Dashboard', icon: Icons.dashboard_outlined),
    SidebarItem(label: 'Timetable', icon: Icons.calendar_month_outlined),
    SidebarItem(label: 'Upcoming Tasks', icon: Icons.task_alt_outlined),
    SidebarItem(label: 'Attendance Tracker', icon: Icons.calendar_today_outlined),
    SidebarItem(label: 'Academic Marks', icon: Icons.bar_chart_outlined),
    SidebarItem(label: 'Examinations & Hall Ticket', icon: Icons.badge_outlined, badge: 'Exams'),
    SidebarItem(label: 'Important Days & Schedule', icon: Icons.event_note_rounded, badge: 'Official'),
    SidebarItem(label: 'CGPA & Target Planner', icon: Icons.calculate_outlined),
    SidebarItem(label: 'Academic Syllabus', icon: Icons.menu_book_outlined, badge: 'Official'),
    SidebarItem(label: 'Question Papers & PYQ', icon: Icons.quiz_outlined, badge: 'PYQ'),
    SidebarItem(label: 'Fees & Payments', icon: Icons.payments_outlined),
    SidebarItem.divider('CAREER & SKILLS'),
    SidebarItem(label: 'Hackathons', icon: Icons.sports_score_outlined, badge: 'Live'),
    SidebarItem(label: 'Certifications', icon: Icons.workspace_premium_outlined, badge: 'Verified'),
    SidebarItem(label: 'LeetCode Tracker', icon: Icons.code_rounded, badge: 'DSA'),
    SidebarItem(label: 'GitHub Dev Portfolio', icon: Icons.terminal_rounded, badge: 'Git'),
    SidebarItem(label: 'Achievements & Badges', icon: Icons.emoji_events_outlined),
    SidebarItem(label: 'Campus Events & Fests', icon: Icons.event_outlined),
    SidebarItem(label: 'Feature Hub & Tools', icon: Icons.grid_view_rounded),
    SidebarItem(label: 'Professional Resume', icon: Icons.description_outlined, badge: 'Resume'),
    SidebarItem.divider('CAMPUS LIFE'),
    SidebarItem(label: 'Campus Photo Gallery', icon: Icons.collections_outlined, badge: 'New'),
    SidebarItem(label: 'Official Announcements', icon: Icons.campaign_outlined),
    SidebarItem.divider('ACCOUNT'),
    SidebarItem(label: 'My Profile', icon: Icons.person_outline),
  ];

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return StudentHomeScreen(
          onNavigateToTab: _handleNavigation,
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 1:
        return InteractiveTimetableScreen(onBack: _handleBackNavigation);
      case 2:
        return StudentUpcomingTasksScreen(onBack: _handleBackNavigation);
      case 3:
        return StudentAttendanceScreen(onBack: _handleBackNavigation);
      case 4:
        return GradebookScreen(
          key: ValueKey('gradebook_$_openGpaPlannerInGradebook'),
          initialShowPlanner: _openGpaPlannerInGradebook,
          onBack: _handleBackNavigation,
        );
      case 5:
        return ExamsDetailScreen(onBack: _handleBackNavigation);
      case 6:
        return AcademicScheduleDetailScreen(onBack: _handleBackNavigation);
      case 7:
        return CgpaDetailsScreen(onBack: _handleBackNavigation);
      case 8:
        return StudentSyllabusScreen(onBack: _handleBackNavigation);
      case 9:
        return StudentPyqScreen(onBack: _handleBackNavigation);
      case 10:
        return FeesScreen(onBack: _handleBackNavigation);
      case 12:
        return HackathonsScreen(onBack: _handleBackNavigation);
      case 13:
        return CertificationsScreen(onBack: _handleBackNavigation);
      case 14:
        return LeetCodeDetailScreen(onBack: _handleBackNavigation);
      case 15:
        return GitHubDetailScreen(onBack: _handleBackNavigation);
      case 16:
        return AchievementsScreen(onBack: _handleBackNavigation);
      case 17:
        return EventsScreen(onBack: _handleBackNavigation);
      case 18:
        return FeatureHubScreen(
          onNavigateToTab: _handleNavigation,
          onBack: _handleBackNavigation,
        );
      case 19:
        return StudentResumeScreen(
          onBack: _handleBackNavigation,
          onNavigateToTab: _handleNavigation,
        );
      case 21:
        return FullPhotoGalleryScreen(onBack: _handleBackNavigation);
      case 22:
        return StudentAnnouncementsScreen(onBack: _handleBackNavigation);
      case 24:
        return ProfileScreen(onBack: _handleBackNavigation);
      default:
        return StudentHomeScreen(
          onNavigateToTab: _handleNavigation,
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
    }
  }


  void _handleNavigation(int index, {bool openCalculator = false, bool isBack = false}) {
    if (_innerNavigatorKey.currentState?.canPop() ?? false) {
      _innerNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    if (index == _currentIndex && !_openGpaPlannerInGradebook) return;

    if (!isBack && index != _currentIndex) {
      _navigationHistory.add(_currentIndex);
    }

    setState(() {
      _currentIndex = index;
      _openGpaPlannerInGradebook = openCalculator;
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
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    if (currentUser?.role == UserRole.parent) {
      return const ParentDashboard();
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
        appBar: null,
        body: Stack(
          children: [
            NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.reverse && _isDockVisible) {
                  if (notification.metrics.pixels > 35) {
                    setState(() => _isDockVisible = false);
                  }
                } else if (notification.direction == ScrollDirection.forward && !_isDockVisible) {
                  setState(() => _isDockVisible = true);
                }
                return false;
              },
              child: Row(
                children: [
                  if (isDesktop) _buildSidebar(),
                  Expanded(
                    child: ClipRect(
                      child: Navigator(
                        key: _innerNavigatorKey,
                        onGenerateRoute: (settings) {
                          return MaterialPageRoute(
                            builder: (_) => SmoothPageTransition(
                              currentIndex: _currentIndex,
                              child: _buildScreen(_currentIndex),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Floating Capsule Bottom Navigation Bar (Mobile / Tablet)
            if (!isDesktop)
              Positioned(
                bottom: math.max(16.0, MediaQuery.of(context).padding.bottom + 10.0),
                left: 0,
                right: 0,
                child: Center(
                  child: StudentFloatingNavBar(
                    currentIndex: _currentIndex,
                    isMenuOpen: _isNavigationSheetOpen,
                    isVisible: _isDockVisible && !_isNavigationSheetOpen,
                    onSidebarTap: () async {
                      setState(() => _isNavigationSheetOpen = true);
                      await showStudentNavigationSheet(
                        context: context,
                        selectedIndex: _currentIndex,
                        onDestinationSelected: _handleNavigation,
                        items: _sidebarItems,
                      );
                      if (mounted) {
                        setState(() => _isNavigationSheetOpen = false);
                      }
                    },
                    onHomeTap: () => _handleNavigation(0),
                    onResumeTap: () => _handleNavigation(19),
                    onProfileTap: () => _handleNavigation(24),
                    onLogoutTap: () => showSignOutConfirmationSheet(context, ref),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final userName = (currentUser?.name != null && currentUser!.name.trim().isNotEmpty)
        ? currentUser.name
        : 'Student User';
    final userEmail = (currentUser?.email != null && currentUser!.email.trim().isNotEmpty)
        ? currentUser.email
        : 'student@unisphere.edu';

    return MainSidebar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _handleNavigation,
      items: _sidebarItems,
      userName: userName,
      userEmail: userEmail,
    );
  }
}

// ─────────────────────────────────────────
//  Smooth Page Switcher (Section 2)
// ─────────────────────────────────────────
class SmoothPageTransition extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const SmoothPageTransition({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideTransition(
      transitionKey: ValueKey('student_tab_$currentIndex'),
      duration: const Duration(milliseconds: 160),
      child: child,
    );
  }
}

// ─────────────────────────────────────────
//  Home Screen
// ─────────────────────────────────────────
class StudentHomeScreen extends ConsumerStatefulWidget {
  final Function(int index, {bool openCalculator}) onNavigateToTab;
  final VoidCallback? onOpenDrawer;

  const StudentHomeScreen({
    super.key,
    required this.onNavigateToTab,
    this.onOpenDrawer,
  });

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _academicOverviewPageIndex = 0;
  int _refreshEpoch = 0;
  bool _isReturningUser = false;
  bool _dismissedVerifiedBanner = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTimeLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hackathons = ref.read(hackathonControllerProvider).hackathons;
      ref.read(hackathonRegistrationProvider.notifier).runAutomatedRemindersCheck(hackathons);
    });
  }

  Future<void> _checkFirstTimeLogin() async {
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
      debugPrint('Error checking student user session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;

    return SafeArea(
      child: Column(
        children: [
              // Home Top Header Bar & Search Bar (Pinned & Stable on scroll - Seamless background)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // Profile Avatar + Greetings & Student Details
                            Expanded(
                              child: _buildWelcomeSection(),
                            ),
                            // Department Vision & Outcomes Button
                            IconButton(
                              icon: const Icon(
                                Icons.school_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              tooltip: 'Department Vision & Outcomes',
                              onPressed: () => showDepartmentVisionSheet(context),
                            ),
                            const SizedBox(width: 4),
                            // Notification Bell Action Icon
                            NotificationBellButton(
                              unreadCount: unreadCount,
                              onTap: () {
                                showNotificationSheet(
                                  context,
                                  onNavigateToTab: widget.onNavigateToTab,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 1. Universal Search Bar (Pill Gradient Design - Fixed & Stable)
                        _buildSearchBar(context),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: AppLiquidPullToRefresh(
                      onRefresh: () async {
                        // Trigger visual re-animation across all dashboard cards & metrics
                        if (mounted) {
                          setState(() {
                            _refreshEpoch++;
                          });
                        }

                        // Concurrently refresh real-time stats (LeetCode, GitHub, LinkedIn)
                        // and invalidate all core app providers for notifications, announcements, marks, and timetable
                        final statsFuture = ref.read(academicOverviewProvider.notifier).refreshAllStats();

                        ref.invalidate(academicOverviewProvider);
                        ref.invalidate(semesterAttendanceProvider);
                        ref.invalidate(allTimetablesStreamProvider);
                        ref.invalidate(notificationProvider);
                        ref.invalidate(hackathonControllerProvider);
                        ref.invalidate(recentPublishedAlbumsProvider);
                        ref.invalidate(allPublishedAlbumsProvider);
                        ref.invalidate(postOdProvider);
                        ref.invalidate(userAcademicScheduleProvider);
                        ref.invalidate(gradebookProvider);

                        await Future.wait([
                          statsFuture,
                          Future.delayed(const Duration(milliseconds: 1000)),
                        ]);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Verification Banner (Prompt to complete profile & submit to HOD)
                      _buildProfileCompletionBanner(),
                      _buildMembershipReminderBanner(),
                      _buildHackathonTeamLeaderActionBanner(),

                      // 2. Academic Overview Card with background glow
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -20,
                            left: 20,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF3F51B5).withValues(alpha: 0.45),
                                    const Color(0xFF3F51B5).withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            right: 40,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF69F0AE).withValues(alpha: 0.35),
                                    const Color(0xFF69F0AE).withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _buildAcademicOverviewCard(context),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildProfileConnectionBanner(context),
                      const SizedBox(height: 16),
                      _buildQuickActions(),

                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Today\'s Classes',
                        () => widget.onNavigateToTab(1),
                      ),
                      const SizedBox(height: 12),
                      _buildTodaysClasses(),
                      const SizedBox(height: 24),
                      const RecentPhotosSection(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildProfileCompletionBanner() {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user?.role != UserRole.student) return const SizedBox.shrink();

    final regNo = user?.metadata?['registerNumber']?.toString().trim() ?? '';
    final studentId = regNo.isNotEmpty ? regNo : (user?.uid ?? '');

    return StreamBuilder<Map<String, dynamic>?>(
      stream: ref.watch(firebaseFirestoreServiceProvider).getFullStudentProfileStream(studentId),
      builder: (context, snapshot) {
        final profileDoc = snapshot.data ?? {};
        final meta = user?.metadata ?? {};

        // Resolve latest status from live Firestore doc or user metadata
        final status = (profileDoc['verificationStatus'] ??
                profileDoc['completionStatus'] ??
                meta['verificationStatus'] ??
                meta['profileCompletionStatus'] ??
                'incomplete')
            .toString()
            .toLowerCase();

        // 1. If submitted / pending HOD verification, hide this banner completely (Requirement: "once submitted then no need to show this here")
        final isPending = status == 'pending_hod' ||
            status == 'submitted' ||
            status == 'pending' ||
            status == 'under_review';
        if (isPending) {
          return const SizedBox.shrink();
        }

        // 2. If approved / verified, show approved badge for 1 day (24 hours), then auto-remove (Requirement: "once apprives then show that approved status ....then after 1day remove that also")
        final isApproved = status == 'approved' || status == 'verified';
        if (isApproved) {
          if (_dismissedVerifiedBanner) return const SizedBox.shrink();

          DateTime? verifiedAt;
          final rawVerified = profileDoc['verifiedAt'] ?? meta['verifiedAt'] ?? meta['approvedAt'];
          if (rawVerified is String) {
            verifiedAt = DateTime.tryParse(rawVerified);
          } else if (rawVerified is Timestamp) {
            verifiedAt = rawVerified.toDate();
          }

          // If more than 24 hours have elapsed since approval, auto-remove the banner
          if (verifiedAt != null) {
            final elapsed = DateTime.now().difference(verifiedAt);
            if (elapsed.inHours >= 24) {
              return const SizedBox.shrink();
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBBF7D0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🟢 360° Profile Verified & Approved',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF15803D)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your profile details have been verified and approved by HOD.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF16A34A)),
                  tooltip: 'Dismiss',
                  onPressed: () {
                    setState(() {
                      _dismissedVerifiedBanner = true;
                    });
                  },
                ),
              ],
            ),
          );
        }

        // 3. If rejected, show revision required banner with HOD reason and Edit/Resubmit button
        final isRejected = status == 'rejected' || status == 'needs_revision' || status == 'correction_required';
        if (isRejected) {
          final reason = profileDoc['rejectionReason']?.toString() ??
              meta['rejectionReason']?.toString() ??
              'HOD requested revision of your uploaded profile details.';
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔴 Profile Revision Required',
                        style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Reason: $reason',
                        style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const StudentProfileCompletionSheet(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Edit & Resubmit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          );
        }

        // 4. Default: Incomplete / Draft (Not submitted yet) -> Show "Complete Your Profile"
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_ind_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎓 Complete Your Profile',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Fill in your personal, academic, accommodation & transport details for HOD verification.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const StudentProfileCompletionSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  'Complete Now →',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembershipReminderBanner() {
    final user = ref.watch(authServiceProvider).currentUser;
    final meta = user?.metadata ?? {};

    // Only applicable for student role
    if (user?.role != UserRole.student) return const SizedBox.shrink();

    final hasMembership = meta['hasMembership'];

    // If membership status is already recorded/updated, hide the banner completely
    if (hasMembership != null) return const SizedBox.shrink();

    // REMINDER BANNER for unrecorded membership status:
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ Technical Society Membership Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                SizedBox(height: 2),
                Text('Are you an active ISTE, CSI, IEEE, or other society member? Tap to record your status & ID.', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => StudentMembershipModal.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 34),
            ),
            child: const Text('Update →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildHackathonTeamLeaderActionBanner() {
    final registrations = ref.watch(hackathonRegistrationProvider);
    final user = ref.watch(authServiceProvider).currentUser;

    final studentId = user?.uid ?? 'STU-2026-042';
    final leaderRegs = registrations.where((r) => r.studentId == studentId || r.studentId == 'STU-2026-042').toList();

    if (leaderRegs.isEmpty) return const SizedBox.shrink();

    // Find any registration that requires Team Leader action
    HackathonRegistrationModel? actionReq;
    for (final r in leaderRegs) {
      if (r.isCorrectionRequired || !r.hasExternalRegId || !r.hasScreenshotProof || !r.hasRequiredMembers) {
        actionReq = r;
        break;
      }
    }

    if (actionReq == null) return const SizedBox.shrink();

    String reasonTitle = '⚠️ Hackathon Team Leader Action Required';
    String reasonMessage = 'Please complete your team details for "${actionReq.hackathonTitle}".';

    if (actionReq.isCorrectionRequired) {
      reasonTitle = '🔴 Advisor Requested Correction: ${actionReq.hackathonTitle}';
      reasonMessage = 'Note: "${actionReq.advisorCorrectionNotes ?? "Please update screenshot proof."}"';
    } else if (!actionReq.hasExternalRegId) {
      reasonTitle = '📝 Enter External Reg ID: ${actionReq.hackathonTitle}';
      reasonMessage = 'Please submit your external portal registration ID for team "${actionReq.teamName}".';
    } else if (!actionReq.hasScreenshotProof) {
      reasonTitle = '📸 Upload Registration Proof: ${actionReq.hackathonTitle}';
      reasonMessage = 'Upload your external portal screenshot proof to verify team "${actionReq.teamName}".';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Color(0xFFC2410C), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reasonTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF9A3412)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reasonMessage,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7C2D12), height: 1.3),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => widget.onNavigateToTab(7), // Navigate to Hackathons Tab
            icon: const Icon(Icons.touch_app_rounded, size: 16),
            label: const Text('Complete Team Details (Manage Team)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's Classes (Live Cloud Firestore Sync) ───────────────────────
  Widget _buildTodaysClasses() {
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final email = user?.email.toLowerCase().trim() ?? '';
    final isDemo = email == 'saravanapmvofficial@gmail.com' || (user != null && user.uid == 'DEMO-STU');

    final meta = user?.metadata ?? {};
    final String userYear = meta['academicYear']?.toString().trim() ?? '3rd Year';
    final String userSection = meta['section']?.toString().trim() ?? 'CS-A';

    final allTimetables = ref.watch(allTimetablesStreamProvider).value ?? [];

    // Find timetable matching user's Year & Section
    Map<String, dynamic>? matchedTimetable;
    for (var tt in allTimetables) {
      final ttYear = tt['year']?.toString().trim() ?? '';
      final ttSec = tt['section']?.toString().trim() ?? '';
      if (ttYear.toLowerCase() == userYear.toLowerCase() && ttSec.toLowerCase() == userSection.toLowerCase()) {
        matchedTimetable = tt;
        break;
      }
    }

    if (matchedTimetable != null) {
      final List rawPeriods = matchedTimetable['periods'] as List? ?? [];

      if (rawPeriods.isNotEmpty) {
        final List<Widget> periodCards = [];
        for (int i = 0; i < rawPeriods.length; i++) {
          final p = rawPeriods[i];
          final time = p['time']?.toString() ?? '09:00';
          final period = p['period']?.toString() ?? 'AM';
          final title = p['title']?.toString() ?? p['subject']?.toString() ?? 'Lecture Period ${i + 1}';
          final timeRange = p['timeRange']?.toString() ?? '09:00 AM - 10:00 AM';
          final room = p['room']?.toString() ?? 'Classroom';

          periodCards.add(
            _buildClassCard(
              time: time,
              period: period,
              title: title,
              timeRange: timeRange,
              room: room,
              accentColor: i % 2 == 0 ? const Color(0xFF2563EB) : const Color(0xFF10B981),
              icon: i % 2 == 0 ? Icons.menu_book_rounded : Icons.computer_rounded,
              iconBg: i % 2 == 0 ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
              isLive: i == 0,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Color(0xFF2563EB), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'HOD OFFICIAL CLASS TIMETABLE ($userYear • $userSection)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
            ...periodCards,
          ],
        );
      }
    }

    if (isDemo) {
      return Column(
        children: [
          _buildClassCard(
            time: '09:00',
            period: 'AM',
            title: 'Advanced Mathematics',
            timeRange: '09:00 AM – 10:30 AM',
            room: 'Room 302',
            accentColor: const Color(0xFF5C6BC0),
            icon: Icons.calculate_rounded,
            iconBg: const Color(0xFFEDE7F6),
          ),
          _buildClassCard(
            time: '11:00',
            period: 'AM',
            title: 'Computer Science',
            timeRange: '11:00 AM – 12:30 PM',
            room: 'Lab 1',
            accentColor: const Color(0xFF26A69A),
            icon: Icons.computer_rounded,
            iconBg: const Color(0xFFE0F2F1),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_seat_rounded, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            'No Today\'s Schedule Uploaded for $userYear ($userSection)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your HOD will publish official class timetables here.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard({
    required String time,
    required String period,
    required String title,
    required String timeRange,
    required String room,
    required Color accentColor,
    required IconData icon,
    required Color iconBg,
    bool isLive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF2D3142),
                ),
              ),
              Text(
                period,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF2D3142),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLive) ...[
                      const SizedBox(width: 6),
                      const AppLivePulseDot(label: 'LIVE', size: 6),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$timeRange • $room',
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Universal Quick Search Bar (Pill Gradient Design) ──────────────
  Widget _buildSearchBar(BuildContext context) {
    return InkWell(
      onTap: () => _showSearchModal(context),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 54,
        padding: const EdgeInsets.all(2), // Gradient border width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF34D399), // Mint Green
              Color(0xFFF472B6), // Soft Pink
              Color(0xFF3B82F6), // Royal Blue
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              // Left Magnifying Search Icon
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF1E3A8A),
                size: 22,
              ),
              const SizedBox(width: 12),
              // Placeholder Text
              const Expanded(
                child: Text(
                  'Search subjects, assignments, timetable, marks...',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Right Filled Royal Blue Circle with White Lightning Bolt
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D4ED8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x331D4ED8),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    String query = '';
    final List<Map<String, dynamic>> allSearchItems = [
      {'title': 'Timetable & Class Schedule', 'subtitle': 'Daily periods & lab rooms', 'icon': Icons.calendar_today_rounded, 'color': const Color(0xFF5C6BC0), 'tabIndex': 1},
      {'title': 'Upcoming Tasks & Coursework', 'subtitle': 'Pending deadlines, homework & lab submissions', 'icon': Icons.task_alt_rounded, 'color': const Color(0xFF0D9488), 'tabIndex': 2},
      {'title': 'Attendance Tracker', 'subtitle': '86% attendance & working days', 'icon': Icons.pie_chart_rounded, 'color': const Color(0xFF3F51B5), 'tabIndex': 3},
      {'title': 'Internal & University Marks', 'subtitle': 'Faculty internal & COE university results', 'icon': Icons.grade_rounded, 'color': const Color(0xFFEF5350), 'tabIndex': 4},
      {'title': 'Examinations & Hall Ticket', 'subtitle': 'IA schedule, university dates & seating', 'icon': Icons.badge_outlined, 'color': const Color(0xFF4F46E5), 'tabIndex': 5},
      {'title': 'Important Days & Schedule', 'subtitle': 'Official academic calendar, CAT dates & holidays', 'icon': Icons.event_note_rounded, 'color': const Color(0xFF1E40AF), 'tabIndex': 6},
      {'title': 'CGPA & Target Planner', 'subtitle': 'Semester GPA forecasting & targets', 'icon': Icons.calculate_rounded, 'color': const Color(0xFF2563EB), 'tabIndex': 7},
      {'title': 'Academic Syllabus', 'subtitle': 'Subject curriculum & unit breakdowns', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFFD97706), 'tabIndex': 8},
      {'title': 'Question Papers & PYQ', 'subtitle': 'University papers, IATs & solved question banks', 'icon': Icons.quiz_rounded, 'color': const Color(0xFF4F46E5), 'tabIndex': 9},
      {'title': 'Fees & Dues Payment', 'subtitle': 'Tuition & hostel fee receipts', 'icon': Icons.school_rounded, 'color': const Color(0xFFFFA726), 'tabIndex': 10},
      {'title': 'Hackathons & Coding', 'subtitle': 'Inter-college hackathons & wins', 'icon': Icons.code_rounded, 'color': const Color(0xFF8B5CF6), 'tabIndex': 12},
      {'title': 'Certifications & Badges', 'subtitle': 'NPTEL, Coursera & AWS certificates', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFF10B981), 'tabIndex': 13},
      {'title': 'LeetCode Coding Tracker', 'subtitle': 'DSA solved count & contest rank', 'icon': Icons.code_rounded, 'color': const Color(0xFFEA580C), 'tabIndex': 14},
      {'title': 'GitHub Dev Portfolio', 'subtitle': 'Repositories & commit contributions', 'icon': Icons.terminal_rounded, 'color': const Color(0xFF0F172A), 'tabIndex': 15},
      {'title': 'Achievements & Honors', 'subtitle': 'Academic & sports trophies', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFFF59E0B), 'tabIndex': 16},
      {'title': 'Campus Events & Symposia', 'subtitle': 'Department fests & cultural events', 'icon': Icons.event_rounded, 'color': const Color(0xFFEC4899), 'tabIndex': 17},
      {'title': 'Feature Hub & Tools', 'subtitle': 'All campus portals & quick tools', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFF64748B), 'tabIndex': 18},
      {'title': 'Professional Resume', 'subtitle': 'Auto-generated dynamic A4 resume & completeness', 'icon': Icons.description_rounded, 'color': const Color(0xFF2563EB), 'tabIndex': 19},
      {'title': 'Campus Photo Gallery', 'subtitle': 'Event photos & fest highlights', 'icon': Icons.collections_rounded, 'color': const Color(0xFF0284C7), 'tabIndex': 21},
      {'title': 'Announcements & Circulars', 'subtitle': 'Official HOD & College notifications', 'icon': Icons.campaign_rounded, 'color': const Color(0xFFEA580C), 'tabIndex': 22},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredItems = allSearchItems.where((item) {
            final title = item['title'].toString().toLowerCase();
            final subtitle = item['subtitle'].toString().toLowerCase();
            final q = query.toLowerCase();
            return q.isEmpty || title.contains(q) || subtitle.contains(q);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 14),

                TextField(
                  autofocus: true,
                  onChanged: (val) => setModalState(() => query = val),
                  decoration: InputDecoration(
                    hintText: 'Search features, tools, assignments, marks...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setModalState(() => query = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  query.isEmpty ? 'Quick Portal Shortcuts' : 'Search Results (${filteredItems.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: filteredItems.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching features found.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                tileColor: const Color(0xFFF8FAFC),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ((item['color'] as Color?) ?? const Color(0xFF2563EB)).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(item['icon'] as IconData, color: (item['color'] as Color?) ?? const Color(0xFF2563EB), size: 20),
                                ),
                                title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text(item['subtitle'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  widget.onNavigateToTab(item['tabIndex'] as int);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Welcome Header ──────────────────────
  Widget _buildWelcomeSection() {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final displayName = (currentUser?.name != null && currentUser!.name.trim().isNotEmpty)
        ? currentUser.name
        : 'Student User';
    final dept = currentUser?.metadata?['department']?.toString().isNotEmpty == true
        ? currentUser!.metadata!['department'].toString()
        : 'Computer Science';
    final year = currentUser?.metadata?['year']?.toString().isNotEmpty == true
        ? currentUser!.metadata!['year'].toString()
        : '3rd Year';
    final userSubtitle = '$dept • $year';

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFFE8EAF6),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isReturningUser ? 'Hello, Welcome Back! 👋' : 'Hello, Welcome! 👋',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                userSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileConnectionBanner(BuildContext context) {
    final overviewData = ref.watch(academicOverviewProvider);

    final bool isLeetCodeConnected = overviewData.leetcodeUsername.trim().isNotEmpty;

    // If both profiles are connected, don't show the prompt banner
    if (isLeetCodeConnected) {
      return const SizedBox.shrink();
    }

    final List<String> missingProfiles = [];
    if (!isLeetCodeConnected) missingProfiles.add('LeetCode');

    final String missingText = missingProfiles.join(' & ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDBA74)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFEA580C),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Action Required: Connect $missingText Profile',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9A3412),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Pending Link',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Link your $missingText account to track daily problem solves, public repos, and display your verified developer rank to faculty.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC2410C),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LeetCodeDetailScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.link_rounded, size: 14),
                      label: Text('Connect $missingText Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Academic Overview Card ───────────────
  Widget _buildAcademicOverviewCard(BuildContext context) {
    final overviewData = ref.watch(academicOverviewProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: StatefulBuilder(
        builder: (cardCtx, setCardState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Title + Slide Indicator Dots + Details Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Academic Overview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3142),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Animated Slide Dots (● ○ ○)
                      Row(
                        children: List.generate(3, (index) {
                          final isActive = index == _academicOverviewPageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 4),
                            width: isActive ? 14 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF3F51B5)
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => widget.onNavigateToTab(19),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Resume',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Slideable PageView Container
              SizedBox(
                height: 62,
                child: PageView(
                  onPageChanged: (index) {
                    if (_academicOverviewPageIndex != index) {
                      setCardState(() {
                        _academicOverviewPageIndex = index;
                      });
                    }
                  },
                  children: [
                    // ── Slide 1: Attendance & Current CGPA ──
                    Row(
                      children: [
                        // Metric 1: Attendance (Semester-Wise & HOD Working Days) -> Opens Attendance screen (Tab 4)
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            onTap: () => widget.onNavigateToTab(3),
                            borderRadius: BorderRadius.circular(12),
                            child: Consumer(
                              builder: (context, ref, _) {
                                final semState = ref.watch(semesterAttendanceProvider);
                                final semData = semState.selectedSemesterData;
                                final double semPercentage = semData.attendancePercentage;

                                Color statusBgColor = const Color(0xFFE8F5E9);
                                Color statusTextColor = const Color(0xFF2E7D32);
                                if (semData.statusLabel == 'Safe Margin') {
                                  statusBgColor = const Color(0xFFFEF3C7);
                                  statusTextColor = const Color(0xFFB45309);
                                } else if (semData.statusLabel == 'Critical') {
                                  statusBgColor = const Color(0xFFFEE2E2);
                                  statusTextColor = const Color(0xFFDC2626);
                                }

                                return Row(
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      key: ValueKey('attendance_gauge_${semPercentage}_$_refreshEpoch'),
                                      tween: Tween<double>(begin: 0.0, end: (semPercentage / 100.0).clamp(0.0, 1.0)),
                                      duration: const Duration(milliseconds: 900),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, animPercent, _) {
                                        return AppCircularGauge(
                                          radius: 22.0,
                                          lineWidth: 4.5,
                                          percent: animPercent,
                                          center: AppCountUpText(
                                            key: ValueKey('attendance_text_${semPercentage}_$_refreshEpoch'),
                                            end: semPercentage,
                                            suffix: '%',
                                            style: const TextStyle(
                                              color: Color(0xFF2D3142),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                          progressColor: const Color(0xFF3F51B5),
                                          backgroundColor: const Color(
                                            0xFF3F51B5,
                                          ).withValues(alpha: 0.12),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 4,
                                            runSpacing: 2,
                                            children: [
                                              const Text(
                                                'Attendance',
                                                style: TextStyle(
                                                  color: Color(0xFF757575),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusBgColor,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  semData.statusLabel,
                                                  style: TextStyle(
                                                    color: statusTextColor,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.arrow_upward_rounded,
                                                color: Color(0xFF2E7D32),
                                                size: 12,
                                              ),
                                              const SizedBox(width: 1),
                                              Expanded(
                                                child: Text(
                                                  '${semData.monthlyTrendPercentage.toInt()}% this month',
                                                  style: const TextStyle(
                                                    color: Color(0xFF2E7D32),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        // Divider
                        Container(
                          height: 40,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        // Metric 2: CGPA -> Opens Gradebook (Tab 5)
                        Expanded(
                          flex: 4,
                          child: InkWell(
                            onTap: () => widget.onNavigateToTab(4),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  overviewData.cgpaLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF757575),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    AppCountUpText(
                                      key: ValueKey('cgpa_text_${overviewData.cgpa}_$_refreshEpoch'),
                                      end: overviewData.cgpa,
                                      precision: 2,
                                      style: const TextStyle(
                                        color: Color(0xFF2D3142),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.arrow_upward_rounded,
                                            color: Color(0xFF2E7D32),
                                            size: 10,
                                          ),
                                          const SizedBox(width: 1),
                                          Text(
                                            '${overviewData.cgpaTrend > 0 ? '' : ''}${overviewData.cgpaTrend.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFF2E7D32),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Slide 2: Total OD Days & LeetCode Solved ──
                    Row(
                      children: [
                        // Metric 1: Total OD Days (Navigates to Attendance & OD Panel)
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StudentAttendanceScreen(
                                    onBack: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 4,
                                        runSpacing: 2,
                                        children: [
                                          const Text(
                                            'Total OD',
                                            style: TextStyle(
                                              color: Color(0xFF757575),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              overviewData.odStatus,
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      AppCountUpText(
                                        key: ValueKey('od_text_${overviewData.odDays}_$_refreshEpoch'),
                                        end: overviewData.odDays.toDouble(),
                                        suffix: ' Days',
                                        style: const TextStyle(
                                          color: Color(0xFF2D3142),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Divider
                        Container(
                          height: 36,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        // Metric 2: LeetCode Solved
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const LeetCodeDetailScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    const Text(
                                      'LeetCode',
                                      style: TextStyle(
                                        color: Color(0xFF757575),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (overviewData.leetcodeUsername.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7ED),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: const Color(0xFFFFEDD5),
                                          ),
                                        ),
                                        child: Text(
                                          '@${overviewData.leetcodeUsername}',
                                          style: const TextStyle(
                                            color: Color(0xFFEA580C),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                AppCountUpText(
                                  key: ValueKey('leetcode_text_${overviewData.leetcodeSolved}_$_refreshEpoch'),
                                  end: overviewData.leetcodeSolved.toDouble(),
                                  suffix: ' Solved',
                                  style: const TextStyle(
                                    color: Color(0xFF2D3142),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Slide 3: GitHub Repos & Stars ──
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const GitHubDetailScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          // Metric 1: GitHub Repos
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Icon(
                                    Icons.terminal_rounded,
                                    color: Color(0xFF0F172A),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 4,
                                        runSpacing: 2,
                                        children: [
                                          const Text(
                                            'GitHub Repos',
                                            style: TextStyle(
                                              color: Color(0xFF757575),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '@${overviewData.githubUsername}',
                                              style: const TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '${overviewData.githubRepos} Repos',
                                        style: const TextStyle(
                                          color: Color(0xFF2D3142),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(
                            height: 36,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                          // Metric 2: Stars & Commits
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'GitHub Contributions',
                                  style: TextStyle(
                                    color: Color(0xFF757575),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      '${overviewData.githubStars} ⭐ Stars',
                                      style: const TextStyle(
                                        color: Color(0xFF2D3142),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFFA7F3D0),
                                        ),
                                      ),
                                      child: Text(
                                        '${overviewData.githubCommits} Commits',
                                        style: const TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

    );
  }

  // ── Quick Actions ────────────────────────
  Widget _buildQuickActions() {
    final row1Actions = [
      {
        'image': 'assets/calendar-2.png',
        'label': 'Timetable',
        'color': const Color(0xFF5C6BC0),
        'type': 'timetable',
      },
      {
        'image': 'assets/to-do-list.png',
        'label': 'Upcoming Tasks',
        'color': const Color(0xFF0D9488),
        'type': 'tasks',
      },
      {
        'image': 'assets/exam.png',
        'label': 'Grades',
        'color': const Color(0xFFEF5350),
        'type': 'grades',
      },
      {
        'image': 'assets/course.png',
        'label': 'Syllabus',
        'color': const Color(0xFFD97706),
        'iconBg': const Color(0xFFFEF3C7),
        'type': 'syllabus',
      },
    ];

    final row2Actions = [
      {
        'image': 'assets/certificate.png',
        'label': 'Certifications',
        'color': const Color(0xFF4F46E5),
        'iconBg': const Color(0xFFEEF2FF),
        'type': 'certifications',
      },
      {
        'image': 'assets/announcement.png',
        'label': 'Announcement',
        'color': const Color(0xFFEA580C),
        'iconBg': const Color(0xFFFEF3C7),
        'type': 'announcement',
      },
      {
        'image': 'assets/exams.png',
        'label': 'Exams',
        'color': const Color(0xFF0284C7),
        'iconBg': const Color(0xFFE0F2FE),
        'type': 'exams',
      },
      {
        'image': 'assets/more.png',
        'label': 'More',
        'color': const Color(0xFF475569),
        'iconBg': const Color(0xFFF1F5F9),
        'type': 'more',
      },
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row1Actions
              .map((action) => Expanded(child: _buildQuickActionButton(action)))
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row2Actions
              .map((action) => Expanded(child: _buildQuickActionButton(action)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(Map<String, dynamic> action) {
    final label = action['label'] as String;
    final type = action['type'] as String;
    final Color mainColor = (action['color'] as Color?) ?? (action['iconColor'] as Color?) ?? const Color(0xFF2563EB);
    final Color bgColor = (action['iconBg'] as Color?) ?? mainColor.withValues(alpha: 0.1);
    final Color borderColor = mainColor.withValues(alpha: 0.2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (type == 'dept_vision') {
            showDepartmentVisionSheet(context);
          } else if (type == 'timetable') {
            widget.onNavigateToTab(1);
          } else if (type == 'tasks' || type == 'assignments' || type == 'upcoming_tasks') {
            widget.onNavigateToTab(2);
          } else if (type == 'grades') {
            widget.onNavigateToTab(4);
          } else if (type == 'syllabus') {
            widget.onNavigateToTab(8);
          } else if (type == 'pyq' || type == 'question_papers') {
            widget.onNavigateToTab(9);
          } else if (type == 'attendance') {
            widget.onNavigateToTab(3);
          } else if (type == 'fees') {
            widget.onNavigateToTab(10);
          } else if (type == 'certifications') {
            widget.onNavigateToTab(13);
          } else if (type == 'announcement') {
            widget.onNavigateToTab(22);
          } else if (type == 'exams') {
            widget.onNavigateToTab(5);
          } else if (type == 'more') {
            widget.onNavigateToTab(18);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: action.containsKey('image')
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              action['image'] as String,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _renderSuggestedIcon(type, mainColor),
                            ),
                          )
                        : action.containsKey('icon')
                        ? Icon(
                            action['icon'] as IconData,
                            color: mainColor,
                            size: 26,
                          )
                        : _renderSuggestedIcon(
                            type,
                            mainColor,
                          ),
                  ),
                  if (type == 'announcement')
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF616161),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderSuggestedIcon(String type, Color mainColor) {
    switch (type) {
      case 'certifications':
        return Icon(Icons.workspace_premium_rounded, size: 28, color: mainColor);
      case 'announcement':
        return Icon(Icons.campaign_rounded, size: 28, color: mainColor);
      case 'syllabus':
        return Icon(Icons.menu_book_rounded, size: 28, color: mainColor);
      case 'grades':
        return Icon(Icons.bar_chart_rounded, size: 28, color: mainColor);
      case 'tasks':
        return Icon(Icons.task_alt_rounded, size: 28, color: mainColor);
      case 'timetable':
        return Icon(Icons.calendar_month_outlined, size: 28, color: mainColor);
      case 'pyq':
      case 'question_papers':
        return Icon(Icons.quiz_rounded, size: 28, color: mainColor);
      case 'exams':
        return Icon(Icons.badge_outlined, size: 28, color: mainColor);
      case 'fees':
        return Icon(Icons.payments_outlined, size: 28, color: mainColor);
      case 'more':
        return Icon(Icons.grid_view_rounded, size: 28, color: mainColor);
      default:
        return Icon(Icons.widgets_outlined, size: 28, color: mainColor);
    }
  }


  // ── Section Header ────────────────────────
  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3142),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See All',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

}

class StudentIDCardFlipModal extends ConsumerStatefulWidget {
  const StudentIDCardFlipModal({super.key});

  @override
  ConsumerState<StudentIDCardFlipModal> createState() => _StudentIDCardFlipModalState();
}

class _StudentIDCardFlipModalState extends ConsumerState<StudentIDCardFlipModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  void _toggleFlip() {
    if (_controller.isAnimating) return;
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final meta = user?.metadata ?? {};

    final String studentName = (meta['fullName'] ?? meta['name'] ?? user?.name ?? 'SARAVANA PERUMAL S').toString().toUpperCase().trim();
    final String branch = (meta['branch'] ?? meta['department'] ?? meta['course'] ?? 'B.Tech - AI&DS').toString().toUpperCase().trim();
    final String regNo = (meta['registerNumber'] ?? meta['regNo'] ?? '922523243100').toString().trim();
    final String dob = (meta['dob'] ?? meta['dateOfBirth'] ?? '12.11.2005').toString().trim();
    final String bloodGroup = (meta['bloodGroup'] ?? 'O+').toString().trim();
    final String course = (meta['course'] ?? meta['degree'] ?? 'B.Tech - AI&DS').toString().trim();
    final String validity = (meta['validity'] ?? '2023 - 2027').toString().trim();
    final String photoUrl = (user?.profileImageUrl ?? meta['photoUrl'] ?? meta['avatarUrl'] ?? '').toString().trim();

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 25,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Drag Handle & Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0F3E8B,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.badge_rounded,
                            color: Color(0xFF0F3E8B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Official Student ID Card (CR80)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              _isFront
                                  ? 'Front Side • Tap card or button to flip 🔄'
                                  : 'Back Side • Tap card or button to flip 🔄',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 3D Flippable CR80 ID Card Display Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleFlip,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final angle = _animation.value * math.pi;
                        final isBack = angle >= (math.pi / 2);

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateY(angle),
                          alignment: Alignment.center,
                          child: isBack
                              ? Transform(
                                  transform: Matrix4.identity()
                                    ..rotateY(math.pi),
                                  alignment: Alignment.center,
                                  child: _buildBackCard(),
                                )
                              : _buildFrontCard(
                                  studentName: studentName,
                                  branch: branch,
                                  regNo: regNo,
                                  dob: dob,
                                  bloodGroup: bloodGroup,
                                  course: course,
                                  validity: validity,
                                  photoUrl: photoUrl,
                                ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Controls
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleFlip,
                          icon: const Icon(
                            Icons.flip_camera_android_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isFront
                                ? 'Flip to Back Side 🔄'
                                : 'Flip to Front Side 🔄',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F3E8B),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(
                              color: Color(0xFF0F3E8B),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Digital Student ID downloaded successfully!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text(
                            'Download ID Card',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3E8B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportPhotoAvatar(String photoUrl) {
    Widget defaultFallback = Container(
      color: Colors.white,
      child: const Icon(
        Icons.person_rounded,
        size: 50,
        color: Color(0xFF024CAA),
      ),
    );

    if (photoUrl.isEmpty) {
      return defaultFallback;
    }

    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    return defaultFallback;
  }

  // ── FRONT SIDE CARD (CR80 Aspect Ratio 1:1.587) ──
  Widget _buildFrontCard({
    required String studentName,
    required String branch,
    required String regNo,
    required String dob,
    required String bloodGroup,
    required String course,
    required String validity,
    required String photoUrl,
  }) {
    return AppParallaxTiltCard(
      child: Container(
        width: 310,
        height: 492,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // White Base Background
              Positioned.fill(child: Container(color: Colors.white)),

              // Card Layout
              Column(
                children: [
                  // Top Header Section: Lanyard Hole + VSB Header Logo Asset
                  Container(
                    color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Lanyard Slot Cutout
                      Container(
                        width: 44,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // VSB College Header Logo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Image.asset(
                          'assets/vsb_header_logo.png',
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _buildFallbackHeaderLogo(),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),

                // Middle Blue Curved Wave Area with Student Photo & Core Details
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Curved Blue Background Shape
                      ClipPath(
                        clipper: VsbFrontWaveClipper(),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF024CAA),
                                Color(0xFF0952B9),
                                Color(0xFF00388A),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      // Student Info
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),
                          // Student Passport Photo Avatar
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildPassportPhotoAvatar(photoUrl),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            branch,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE0F2FE),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'REG. NO: $regNo',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lower White Details Section
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Attributes Grid
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                _buildFrontSpecRow(
                                  Icons.calendar_today_rounded,
                                  'DATE OF BIRTH',
                                  dob,
                                ),
                                const SizedBox(height: 6),
                                _buildFrontSpecRow(
                                  Icons.bloodtype_rounded,
                                  'BLOOD GROUP',
                                  bloodGroup,
                                ),
                                const SizedBox(height: 6),
                                _buildFrontSpecRow(
                                  Icons.school_rounded,
                                  'COURSE',
                                  course,
                                ),
                                const SizedBox(height: 6),
                                _buildFrontSpecRow(
                                  Icons.event_available_rounded,
                                  'VALIDITY',
                                  validity,
                                ),
                              ],
                            ),
                          ),

                          // Right QR Code
                          Container(
                            width: 82,
                            height: 82,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF024CAA),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 54,
                                  color: Color(0xFF0F172A),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF024CAA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Signature Block
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Column(
                            children: [
                              Text(
                                'Saravana',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'cursive',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF024CAA),
                                ),
                              ),
                              Text(
                                'PRINCIPAL',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Blue Footer Bar
                Container(
                  height: 12,
                  width: double.infinity,
                  color: const Color(0xFF024CAA),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFallbackHeaderLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFEF08A),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDC2626),
              border: Border.all(color: const Color(0xFFCA8A04), width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VSB ENGINEERING COLLEGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF024CAA),
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                '(AN AUTONOMOUS INSTITUTION)',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrontSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF024CAA).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 11, color: const Color(0xFF024CAA)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── BACK SIDE CARD (CR80 Aspect Ratio 1:1.587) ──
  Widget _buildBackCard() {
    return AppParallaxTiltCard(
      child: Container(
        width: 310,
        height: 492,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Top Blue Section (Wave Curved Bottom)
            ClipPath(
              clipper: VsbBackWaveClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF024CAA),
                      Color(0xFF0952B9),
                      Color(0xFF00388A),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Lanyard Slot Cutout
                    Container(
                      width: 44,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'VSB ENGINEERING COLLEGE',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      '(AN AUTONOMOUS INSTITUTION)',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBAE6FD),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(width: 44, height: 1.5, color: Colors.white38),
                    const SizedBox(height: 10),

                    _buildBackBadgeRow(
                      Icons.verified_user_rounded,
                      'Approved by AICTE, New Delhi and Affiliated to Anna University, Chennai',
                    ),
                    const SizedBox(height: 6),
                    _buildBackBadgeRow(
                      Icons.verified_rounded,
                      'NBA Accredited Courses',
                    ),
                    const SizedBox(height: 6),
                    _buildBackBadgeRow(
                      Icons.star_rounded,
                      'NAAC Accredited & ISO Certified Institution',
                    ),
                  ],
                ),
              ),
            ),

            // Lower White Contact & Instructions Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackContactRow(
                      Icons.location_on_rounded,
                      'KARUDAYAMPALAYAM PO,\nKARUR - 639 111',
                    ),
                    const SizedBox(height: 5),
                    _buildBackContactRow(
                      Icons.phone_rounded,
                      'Phone: 99944 96212, 82200 80832,\n82705 96212',
                    ),
                    const SizedBox(height: 5),
                    _buildBackContactRow(
                      Icons.language_rounded,
                      'www.vsbec.ac.in',
                    ),
                    const SizedBox(height: 5),
                    _buildBackContactRow(
                      Icons.email_rounded,
                      'info@vsbec.ac.in',
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'INSTRUCTIONS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF024CAA),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '• This card is the property of VSB Engineering College.',
                      style: TextStyle(
                        fontSize: 7.5,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      '• This card is non-transferable.',
                      style: TextStyle(
                        fontSize: 7.5,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      '• Carry this card at all times within the campus.',
                      style: TextStyle(
                        fontSize: 7.5,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      '• Loss of this card must be reported immediately to the administration.',
                      style: TextStyle(
                        fontSize: 7.5,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // Barcode & Reg No
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              34,
                              (i) => Container(
                                width: (i % 4 == 0)
                                    ? 2.5
                                    : ((i % 2 == 0) ? 1.8 : 1.0),
                                height: 26,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.0,
                                ),
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '922523243100',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Blue Footer Bar
            Container(
              height: 12,
              width: double.infinity,
              color: const Color(0xFF024CAA),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBackBadgeRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF024CAA).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 11, color: const Color(0xFF024CAA)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Custom Wave Clippers for VSB ID Card ──
class VsbFrontWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 14);
    path.quadraticBezierTo(size.width * 0.5, -10, size.width, 14);
    path.lineTo(size.width, size.height - 16);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 14,
      0,
      size.height - 16,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class VsbBackWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 16);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 14,
      0,
      size.height - 16,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class InteractiveTimetable extends ConsumerStatefulWidget {
  const InteractiveTimetable({super.key});

  @override
  ConsumerState<InteractiveTimetable> createState() => _InteractiveTimetableState();
}

class _InteractiveTimetableState extends ConsumerState<InteractiveTimetable> {
  int _selectedDayIndex =
      0; // 0 = Mon, 1 = Tue, 2 = Wed, 3 = Thu, 4 = Fri, 5 = Sat
  int? _selectedClassIndex =
      1; // Default select 1 (e.g. Computer Science live class)
  bool _simulateRealtimeUpdates = false;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  final List<List<Map<String, dynamic>>> _timetableData = [
    // Monday
    [
      {
        'time': '09:00',
        'period': 'AM',
        'title': 'Advanced Mathematics',
        'timeRange': '09:00 AM – 10:30 AM',
        'room': 'Room 302',
        'lecturer': 'Dr. Sarah Vance',
        'accentColor': const Color(0xFF5C6BC0),
        'icon': Icons.calculate_rounded,
        'iconBg': const Color(0xFFEDE7F6),
        'isLive': false,
      },
      {
        'time': '11:00',
        'period': 'AM',
        'title': 'Computer Science',
        'timeRange': '11:00 AM – 12:30 PM',
        'room': 'Lab 1',
        'lecturer': 'Prof. Alan Turing',
        'accentColor': const Color(0xFF26A69A),
        'icon': Icons.computer_rounded,
        'iconBg': const Color(0xFFE0F2F1),
        'isLive': true, // highlighted as ongoing
      },
      {
        'time': '02:00',
        'period': 'PM',
        'title': 'Physics Lab',
        'timeRange': '02:00 PM – 03:30 PM',
        'room': 'Lab 3',
        'lecturer': 'Dr. Marie Curie',
        'accentColor': const Color(0xFFFFA726),
        'icon': Icons.science_rounded,
        'iconBg': const Color(0xFFFFF3E0),
        'isLive': false,
      },
    ],
    // Tuesday
    [
      {
        'time': '09:30',
        'period': 'AM',
        'title': 'Database Systems',
        'timeRange': '09:30 AM – 11:00 AM',
        'room': 'Room 104',
        'lecturer': 'Dr. Grace Hopper',
        'accentColor': const Color(0xFF29B6F6),
        'icon': Icons.storage_rounded,
        'iconBg': const Color(0xFFE1F5FE),
        'isLive': false,
      },
      {
        'time': '11:30',
        'period': 'AM',
        'title': 'Software Engineering',
        'timeRange': '11:30 AM – 01:00 PM',
        'room': 'Room 205',
        'lecturer': 'Prof. Margaret Hamilton',
        'accentColor': const Color(0xFF66BB6A),
        'icon': Icons.code_rounded,
        'iconBg': const Color(0xFFE8F5E9),
        'isLive': false,
        'status': 'rescheduled',
        'statusText': 'Rescheduled to 02:00 PM',
      },
      {
        'time': '03:00',
        'period': 'PM',
        'title': 'Communication Skills',
        'timeRange': '03:00 PM – 04:30 PM',
        'room': 'Seminar Hall',
        'lecturer': 'Prof. Dale Carnegie',
        'accentColor': const Color(0xFFAB47BC),
        'icon': Icons.record_voice_over_rounded,
        'iconBg': const Color(0xFFF3E5F5),
        'isLive': false,
      },
    ],
    // Wednesday
    [
      {
        'time': '09:00',
        'period': 'AM',
        'title': 'Advanced Mathematics',
        'timeRange': '09:00 AM – 10:30 AM',
        'room': 'Room 302',
        'lecturer': 'Dr. Sarah Vance',
        'accentColor': const Color(0xFF5C6BC0),
        'icon': Icons.calculate_rounded,
        'iconBg': const Color(0xFFEDE7F6),
        'isLive': false,
      },
      {
        'time': '11:00',
        'period': 'AM',
        'title': 'Computer Science',
        'timeRange': '11:00 AM – 12:30 PM',
        'room': 'Lab 1',
        'lecturer': 'Prof. Alan Turing',
        'accentColor': const Color(0xFF26A69A),
        'icon': Icons.computer_rounded,
        'iconBg': const Color(0xFFE0F2F1),
        'isLive': false,
      },
      {
        'time': '01:30',
        'period': 'PM',
        'title': 'Discrete Structures',
        'timeRange': '01:30 PM – 03:00 PM',
        'room': 'Room 310',
        'lecturer': 'Dr. Ada Lovelace',
        'accentColor': const Color(0xFFEC407A),
        'icon': Icons.hub_rounded,
        'iconBg': const Color(0xFFFCE4EC),
        'isLive': false,
      },
    ],
    // Thursday
    [
      {
        'time': '10:00',
        'period': 'AM',
        'title': 'Database Systems',
        'timeRange': '10:00 AM – 11:30 AM',
        'room': 'Room 104',
        'lecturer': 'Dr. Grace Hopper',
        'accentColor': const Color(0xFF29B6F6),
        'icon': Icons.storage_rounded,
        'iconBg': const Color(0xFFE1F5FE),
        'isLive': false,
      },
      {
        'time': '12:00',
        'period': 'PM',
        'title': 'Software Engineering',
        'timeRange': '12:00 PM – 01:30 PM',
        'room': 'Room 205',
        'lecturer': 'Prof. Margaret Hamilton',
        'accentColor': const Color(0xFFEF5350),
        'icon': Icons.code_rounded,
        'iconBg': const Color(0xFFFFEBEE),
        'isLive': false,
        'status': 'cancelled',
        'statusText': 'Cancelled Today',
      },
      {
        'time': '02:30',
        'period': 'PM',
        'title': 'Web Development',
        'timeRange': '02:30 PM – 04:00 PM',
        'room': 'Lab 2',
        'lecturer': 'Prof. Tim Berners-Lee',
        'accentColor': const Color(0xFF26A69A),
        'icon': Icons.web_rounded,
        'iconBg': const Color(0xFFE0F2F1),
        'isLive': false,
      },
    ],
    // Friday
    [
      {
        'time': '09:00',
        'period': 'AM',
        'title': 'Digital Logic Design',
        'timeRange': '09:00 AM – 10:30 AM',
        'room': 'Lab 4',
        'lecturer': 'Dr. Claude Shannon',
        'accentColor': const Color(0xFF26A69A),
        'icon': Icons.memory_rounded,
        'iconBg': const Color(0xFFE0F2F1),
        'isLive': false,
      },
      {
        'time': '11:00',
        'period': 'AM',
        'title': 'Discrete Structures',
        'timeRange': '11:00 AM – 12:30 PM',
        'room': 'Room 310',
        'lecturer': 'Dr. Ada Lovelace',
        'accentColor': const Color(0xFFEC407A),
        'icon': Icons.hub_rounded,
        'iconBg': const Color(0xFFFCE4EC),
        'isLive': false,
      },
      {
        'time': '02:00',
        'period': 'PM',
        'title': 'Seminar / Guest Lecture',
        'timeRange': '02:00 PM – 03:30 PM',
        'room': 'Auditorium',
        'lecturer': 'Invited Speakers',
        'accentColor': const Color(0xFF5C6BC0),
        'icon': Icons.groups_rounded,
        'iconBg': const Color(0xFFEDE7F6),
        'isLive': false,
      },
    ],
    // Saturday
    [
      {
        'time': '10:00',
        'period': 'AM',
        'title': 'Project Work / Mentorship',
        'timeRange': '10:00 AM – 12:00 PM',
        'room': 'Lab 1',
        'lecturer': 'Internal Faculty',
        'accentColor': const Color(0xFFFF7043),
        'icon': Icons.lightbulb_outline_rounded,
        'iconBg': const Color(0xFFFBE9E7),
        'isLive': false,
      },
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final email = user?.email.toLowerCase().trim() ?? '';
    final isDemo = email == 'saravanapmvofficial@gmail.com' || (user != null && user.uid == 'DEMO-STU');

    final meta = user?.metadata ?? {};
    final userYear = meta['year']?.toString() ?? '3rd Year';
    final userSec = meta['section']?.toString() ?? 'CS-A';

    final timetables = ref.watch(allTimetablesStreamProvider).value ?? [];
    final docId = '${userYear.replaceAll(' ', '_')}_${userSec.replaceAll(' ', '_')}'.toLowerCase();
    final uploadedDoc = timetables.firstWhere((t) => t['id'] == docId, orElse: () => {});
    final hasUploadedFile = uploadedDoc.isNotEmpty && uploadedDoc['fileName'] != null;

    List<Map<String, dynamic>> classes = [];
    if (uploadedDoc.isNotEmpty && uploadedDoc['periods'] != null && (uploadedDoc['periods'] as List).isNotEmpty) {
      final rawPeriods = uploadedDoc['periods'] as List;
      classes = rawPeriods.map((p) {
        return {
          'time': '09:00',
          'period': 'AM',
          'title': p['subject']?.toString() ?? 'Class Period',
          'timeRange': p['period']?.toString() ?? '09:00 AM – 10:00 AM',
          'room': p['room']?.toString() ?? 'Classroom',
          'lecturer': p['staff']?.toString() ?? 'Faculty Member',
          'accentColor': const Color(0xFF2563EB),
          'icon': Icons.class_rounded,
          'iconBg': const Color(0xFFEFF6FF),
          'isLive': false,
        };
      }).toList();
    } else if (isDemo) {
      classes = _timetableData[_selectedDayIndex % _timetableData.length];
    } else {
      classes = [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HOD Uploaded Timetable File Banner (Excel, PDF, CSV, Image)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'OFFICIAL HOD CLASS TIMETABLE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$userYear ($userSec)',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (hasUploadedFile) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uploadedDoc['fileName'] ?? 'Timetable Document',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Format: ${uploadedDoc['fileType'] ?? 'Excel Sheet (.xlsx)'} • Verified by HOD',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📥 Downloading ${uploadedDoc['fileName']} for $userYear ($userSec)...'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download Timetable File (Excel/PDF)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'Default Class Timetable displayed below. HOD will upload official Excel/PDF timetable document for your Year & Section.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                ),
              ],
            ],
          ),
        ),

        // Header with live updates simulator toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Interactive Class Periods',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3142),
              ),
            ),
            Row(
              children: [
                const Text(
                  'Live Updates',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _simulateRealtimeUpdates,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        _simulateRealtimeUpdates = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Day Selector Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_days.length, (index) {
              final isSelected = _selectedDayIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                    _selectedClassIndex = null;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isSelected ? 0.15 : 0.03,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: Text(
                    _days[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF616161),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Classes Grid/List
        if (classes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.calendar_month_outlined, size: 44, color: AppColors.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                const Text(
                  'No Class Schedule Uploaded Yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your HOD will upload the official timetable document and period schedule for $userYear ($userSec).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          )
        else
          ...classes.asMap().entries.map((entry) {
            final classIndex = entry.key;
            final c = entry.value;

            // Apply simulation changes if toggled
            String? status = c['status'] as String?;
            String? statusText = c['statusText'] as String?;

            if (_simulateRealtimeUpdates &&
                _selectedDayIndex == 0 &&
                c['title'] == 'Advanced Mathematics') {
              // Simulate rescheduling Advanced Mathematics on Monday
              status = 'rescheduled';
              statusText = 'Rescheduled to 01:00 PM';
            }

            final isLive = c['isLive'] as bool && !_simulateRealtimeUpdates;
            final isCancelled = status == 'cancelled';
            final isRescheduled = status == 'rescheduled';
            final isSelectedCard = _selectedClassIndex == classIndex;

            final accentColor = isCancelled
                ? const Color(0xFFE53935)
                : (c['accentColor'] as Color);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedClassIndex = isSelectedCard ? null : classIndex;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelectedCard
                      ? Colors.white
                      : (isLive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.95)),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelectedCard
                      ? Border.all(
                          color: const Color(0xFF2563EB),
                          width: 2.5,
                        ) // Vibrant Blue outline on click!
                      : (isLive
                            ? Border.all(
                                color: const Color(0xFF10B981),
                                width: 1.5,
                              ) // Emerald green border for Live class!
                            : Border.all(
                                color: const Color(0xFFEEEEEE),
                                width: 1,
                              )),
                  boxShadow: [
                    BoxShadow(
                      color: isSelectedCard
                          ? const Color(0xFF2563EB).withValues(
                              alpha: 0.22,
                            ) // Blue glow shadow on click!
                          : (isLive
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.03)),
                      blurRadius: isSelectedCard ? 12 : (isLive ? 12 : 8),
                      offset: isSelectedCard
                          ? const Offset(0, 4)
                          : const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Time column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            isRescheduled ? '01:00' : (c['time'] as String),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isCancelled
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFF2D3142),
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            c['period'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Indicator
                      Container(
                        width: 3,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: const Color(0xFF2D3142),
                                      decoration: isCancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isLive)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFF81C784),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.fiber_manual_record,
                                          color: Colors.green,
                                          size: 8,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'LIVE NOW',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Lecturer: ${c['lecturer']}',
                                    style: const TextStyle(
                                      color: Color(0xFF757575),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isCancelled || isRescheduled) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCancelled
                                          ? const Color(0xFFFFEBEE)
                                          : const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusText!,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isCancelled
                                            ? const Color(0xFFD32F2F)
                                            : const Color(0xFFEF6C00),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: c['iconBg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          c['icon'] as IconData,
                          color: c['accentColor'] as Color,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class InteractiveTimetableScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const InteractiveTimetableScreen({super.key, this.onBack});

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              UnisphereHeaderCard(
                title: 'Interactive Timetable & Schedule',
                subtitle: 'Real-Time Class Schedule & Lecture Rooms',
                onBack: () => _handleBack(context),
              ),
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: InteractiveTimetable(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Modals ───────────────────────────────────────────────────

void showClassMaterialsModal(
  BuildContext context,
  Map<String, String> classData,
) {
  final title = classData['title'] ?? 'Course';
  final code = classData['code'] ?? 'CS301';
  final isLive = classData['status'] == 'Live Now';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (isLive) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.video_call_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Online Session Active',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        Text(
                          'Hosted via Zoom • Room ID: 884 902 119',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Join Room',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Course Lecture Materials & Resources',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildMaterialItem(
            Icons.picture_as_pdf_rounded,
            'Unit 3: Lecture Slides & Architecture',
            'PDF • 4.2 MB',
            const Color(0xFFDC2626),
            const Color(0xFFFEF2F2),
          ),
          const SizedBox(height: 10),
          _buildMaterialItem(
            Icons.folder_zip_rounded,
            'Lab Exercises & Sample Code',
            'ZIP • 8.5 MB',
            const Color(0xFFD97706),
            const Color(0xFFFEF3C7),
          ),
          const SizedBox(height: 10),
          _buildMaterialItem(
            Icons.play_circle_fill_rounded,
            'Recorded Video Session (Class 14)',
            'MP4 • 45 min',
            const Color(0xFF059669),
            const Color(0xFFECFDF5),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Widget _buildMaterialItem(
  IconData icon,
  String title,
  String subtitle,
  Color color,
  Color bg,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const Icon(Icons.download_rounded, color: Color(0xFF2563EB), size: 20),
      ],
    ),
  );
}

void showRoomLocationModal(
  BuildContext context,
  Map<String, String> classData,
) {
  final title = classData['title'] ?? 'Course';
  final room = classData['room'] ?? 'Room 302';
  final time = classData['time'] ?? '09:00 AM';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Campus Navigation',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$title ($room)',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.domain_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            'Tech Park Block B • Floor 3',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Session: $time',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_seat_rounded,
                          size: 16,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Capacity: 60 Seats',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
