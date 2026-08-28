import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/parent_service.dart';
import 'package:unisphere/services/institution_service.dart';
import 'package:unisphere/services/user_session_service.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:flutter/services.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/widgets/common/notification_sheet.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';
import 'package:unisphere/widgets/common/main_sidebar.dart';
import 'package:unisphere/widgets/parent/parent_floating_nav_bar.dart';
import 'package:unisphere/widgets/parent/parent_navigation_sheet.dart';
import 'package:unisphere/widgets/parent/parent_quick_navigation_bar.dart';
import 'package:unisphere/widgets/parent/parent_summary_carousel.dart';
import 'package:unisphere/widgets/common/sign_out_confirmation_sheet.dart';
import 'package:unisphere/screens/parent/parent_profile_screen.dart';
import 'package:unisphere/widgets/common/recent_photos_section.dart';
import 'package:unisphere/screens/gallery/full_photo_gallery_screen.dart';
import 'package:unisphere/screens/student/modules/student_announcements_screen.dart';
import 'package:unisphere/screens/features/events_screen.dart';
import 'package:unisphere/screens/features/exams_detail_screen.dart';
import 'package:unisphere/screens/features/academic_schedule_detail_screen.dart';
import 'package:unisphere/screens/student/modules/student_upcoming_tasks_screen.dart';
import 'package:unisphere/screens/features/certifications_screen.dart';
import 'package:unisphere/core/theme/app_animations.dart';


class StudentWard {
  final String id;
  final String name;
  final String regNo;
  final String department;
  final String yearSection;
  final String attendance;
  final double attendancePercent;
  final String cgpa;
  final String feesDue;
  final String academicStatus;
  final Color statusColor;
  final String avatarInitials;

  StudentWard({
    required this.id,
    required this.name,
    required this.regNo,
    required this.department,
    required this.yearSection,
    required this.attendance,
    required this.attendancePercent,
    required this.cgpa,
    required this.feesDue,
    required this.academicStatus,
    required this.statusColor,
    required this.avatarInitials,
  });
}

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  int _currentIndex = 0;
  bool _isNavigationSheetOpen = false;
  bool _isDockVisible = true;
  ParentStudentWard? _activeWard;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _innerNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initActiveWard());
  }

  Future<void> _initActiveWard() async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    final userKey = currentUser?.uid ?? currentUser?.email ?? '';
    final parentService = ref.read(parentServiceProvider);

    final wards = await parentService.getStudentWardsForParent(userKey, currentUser: currentUser);

    if (wards.isNotEmpty && mounted) {
      final activeReg = userKey.isNotEmpty ? await parentService.getActiveWardPreference(userKey) : null;
      final selected = (activeReg != null && activeReg.isNotEmpty)
          ? wards.firstWhere((w) => w.regNo.toUpperCase() == activeReg.toUpperCase(), orElse: () => wards.first)
          : wards.first;

      setState(() => _activeWard = selected);
      ref.read(activeParentWardProvider.notifier).state = selected;
    }
  }

  void _handleWardChanged(ParentStudentWard ward) {
    setState(() => _activeWard = ward);
    ref.read(activeParentWardProvider.notifier).state = ward;
  }

  static final List<SidebarItem> parentSidebarItems = [
    SidebarItem(label: 'Dashboard Home', icon: Icons.dashboard_outlined),
    SidebarItem(label: 'Attendance History', icon: Icons.pie_chart_outline_rounded),
    SidebarItem(label: 'Performance Marks', icon: Icons.school_outlined),
    SidebarItem(label: 'Institutional Alerts', icon: Icons.notifications_active_outlined, badge: 'New'),
    SidebarItem(label: 'Parent Profile', icon: Icons.person_outline),
    SidebarItem.divider('CAMPUS & CHILD SERVICES'),
    SidebarItem(label: 'Exams & Results', icon: Icons.description_outlined),
    SidebarItem(label: 'Class Timetable', icon: Icons.schedule_outlined),
    SidebarItem(label: 'Campus Photo Gallery', icon: Icons.collections_outlined, badge: 'Gallery'),
    SidebarItem(label: 'Events & Fests', icon: Icons.event_outlined),
    SidebarItem(label: 'Assignments & Tasks', icon: Icons.assignment_outlined),
    SidebarItem(label: 'Certificates & Docs', icon: Icons.verified_outlined),
    SidebarItem(label: 'Transport Details', icon: Icons.bus_alert_outlined),
  ];

  List<SidebarItem> get _sidebarItems => parentSidebarItems;

  final List<int> _navigationHistory = [0];

  Widget _buildScreen(int index) {
    final activeWard = _activeWard ?? ref.watch(activeParentWardProvider) ?? ref.read(parentServiceProvider).getDefaultStudentWards().first;

    switch (index) {
      case 0:
        return ParentHomeScreen(
          selectedWard: activeWard,
          onWardChanged: _handleWardChanged,
          onNavigateToTab: _handleNavigation,
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 1:
        return ParentAttendanceDetailTab(
          selectedWard: activeWard,
          onNavigateToTab: _handleNavigation,
        );
      case 2:
        return ParentAcademicPerformanceTab(
          selectedWard: activeWard,
          onNavigateToTab: _handleNavigation,
        );
      case 3:
        return StudentAnnouncementsScreen(onBack: _handleBackNavigation);
      case 4:
        return ParentProfileScreen(onBack: _handleBackNavigation);
      case 5:
        return ExamsDetailScreen(onBack: _handleBackNavigation);
      case 6:
        return AcademicScheduleDetailScreen(onBack: _handleBackNavigation);
      case 7:
        return FullPhotoGalleryScreen(onBack: _handleBackNavigation);
      case 8:
        return EventsScreen(onBack: _handleBackNavigation);
      case 9:
        return StudentUpcomingTasksScreen(onBack: _handleBackNavigation);
      case 10:
        return CertificationsScreen(onBack: _handleBackNavigation);
      case 11:
        return const Center(child: Text('School Transport Map'));
      default:
        return ParentHomeScreen(
          selectedWard: activeWard,
          onWardChanged: _handleWardChanged,
          onNavigateToTab: _handleNavigation,
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
    }
  }

  void _handleNavigation(int index, {bool isBack = false}) {
    if (_innerNavigatorKey.currentState?.canPop() ?? false) {
      _innerNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
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
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    if (isDesktop) _buildSidebar(),
                    Expanded(
                      child: ClipRect(
                        child: Navigator(
                          key: _innerNavigatorKey,
                          onGenerateRoute: (settings) {
                            return MaterialPageRoute(
                              builder: (_) => FadeSlideTransition(
                                transitionKey: ValueKey('parent_tab_$_currentIndex'),
                                duration: const Duration(milliseconds: 180),
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
            ),
            // Floating Capsule Bottom Navigation Bar (Mobile / Tablet)
            if (!isDesktop)
              Positioned(
                bottom: math.max(16.0, MediaQuery.of(context).padding.bottom + 10.0),
                left: 0,
                right: 0,
                child: Center(
                  child: ParentFloatingNavBar(
                    currentIndex: _currentIndex,
                    isMenuOpen: _isNavigationSheetOpen,
                    isVisible: _isDockVisible && !_isNavigationSheetOpen,
                    onSidebarTap: () async {
                      setState(() => _isNavigationSheetOpen = true);
                      await showParentNavigationSheet(
                        context: context,
                        selectedIndex: _currentIndex,
                        onDestinationSelected: _handleNavigation,
                        items: _sidebarItems,
                      );
                      if (mounted) {
                        setState(() => _isNavigationSheetOpen = false);
                      }
                    },
                    onAttendanceTap: () => _handleNavigation(1),
                    onHomeTap: () => _handleNavigation(0),
                    onProfileTap: () => _handleNavigation(4),
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
        : 'Parent User';
    final userEmail = (currentUser?.email != null && currentUser!.email.trim().isNotEmpty)
        ? currentUser.email
        : 'parent@unisphere.edu';

    return MainSidebar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _handleNavigation,
      items: _sidebarItems,
      userName: userName,
      userEmail: userEmail,
    );
  }
}

class ParentHomeScreen extends ConsumerStatefulWidget {
  final Function(int index)? onNavigateToTab;
  final VoidCallback? onOpenDrawer;
  final ParentStudentWard? selectedWard;
  final ValueChanged<ParentStudentWard>? onWardChanged;

  const ParentHomeScreen({
    super.key,
    this.onNavigateToTab,
    this.onOpenDrawer,
    this.selectedWard,
    this.onWardChanged,
  });

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> with SingleTickerProviderStateMixin {
  late List<ParentStudentWard> _wards;
  late ParentStudentWard _selectedWard;
  String _selectedTrendMode = 'CGPA'; // 'CGPA' or 'SGPA'
  bool _isRefreshing = false;
  int _refreshEpoch = 0;
  bool _isReturningUser = true;

  String get _parentDisplayName {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final name = currentUser?.name;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    return 'Parent / Guardian';
  }

  String get _parentDisplayEmail {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final email = currentUser?.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }
    return 'parent@unisphere.edu';
  }

  @override
  void initState() {
    super.initState();
    final parentService = ref.read(parentServiceProvider);
    _wards = parentService.getDefaultStudentWards();
    _selectedWard = widget.selectedWard ?? _wards.first;
    _checkUserSession();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadParentWards());
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
      debugPrint('Error checking parent user session: $e');
    }
  }

  @override
  void didUpdateWidget(ParentHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedWard != null && widget.selectedWard!.id != _selectedWard.id) {
      setState(() {
        _selectedWard = widget.selectedWard!;
      });
    }
  }

  Future<void> _loadParentWards() async {
    try {
      final currentUser = ref.read(authServiceProvider).currentUser;
      final parentService = ref.read(parentServiceProvider);
      final userKey = currentUser?.uid ?? currentUser?.email ?? '';
      if (userKey.isNotEmpty) {
        final fetchedWards = await parentService.getStudentWardsForParent(userKey, currentUser: currentUser);
        final activePref = await parentService.getActiveWardPreference(userKey);

        if (fetchedWards.isNotEmpty && mounted) {
          setState(() {
            _wards = fetchedWards;
            if (activePref != null && activePref.isNotEmpty) {
              _selectedWard = _wards.firstWhere(
                (w) => w.regNo.toUpperCase() == activePref.toUpperCase(),
                orElse: () => _wards.first,
              );
            } else if (widget.selectedWard != null) {
              _selectedWard = _wards.firstWhere(
                (w) => w.id == widget.selectedWard!.id,
                orElse: () => _wards.first,
              );
            } else {
              _selectedWard = _wards.first;
            }
          });
          ref.read(activeParentWardProvider.notifier).state = _selectedWard;
        }
      }
    } catch (e) {
      debugPrint('Error loading parent wards: $e');
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isRefreshing = true;
      _refreshEpoch++;
    });

    final currentUser = ref.read(authServiceProvider).currentUser;
    final parentService = ref.read(parentServiceProvider);
    final userKey = currentUser?.uid ?? currentUser?.email ?? '';
    
    final freshWards = await parentService.getStudentWardsForParent(userKey, currentUser: currentUser);

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      setState(() {
        _wards = freshWards;
        _selectedWard = _wards.firstWhere(
          (w) => w.id == _selectedWard.id,
          orElse: () => _wards.first,
        );
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Parent portal updated with latest sync',
                style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Column(
      children: [
        // 🌟 PINNED & STABLE TOP HEADER & SEARCH BAR (Does not jitter on scroll)
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 28 : 16,
            12,
            isDesktop ? 28 : 16,
            10,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. TOP PARENT WELCOME & NOTIFICATION & REFRESH BAR
                  _buildParentTopWelcomeBar(context),

                  const SizedBox(height: 12),

                  // 2. SEARCH & QUICK ACTION BAR (Pinned & Fixed)
                  _buildSearchBarAndQuickAction(context),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),

        // 🌟 SCROLLABLE DASHBOARD BODY WRAPPED IN LIQUID PULL-TO-REFRESH
        Expanded(
          child: AppLiquidPullToRefresh(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              key: ValueKey('parent_home_scroll_$_refreshEpoch'),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 28 : 16,
                vertical: 14,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. STUDENT IDENTITY PROFILE CARD
                      _buildStudentIdentityCard(context),

                      const SizedBox(height: 14),

                      // 4. HORIZONTALLY SLIDING TOP SUMMARY CAROUSEL
                      ParentSummaryCarousel(
                        selectedWard: _selectedWard,
                        onNavigateToTab: widget.onNavigateToTab,
                      ),

                      const SizedBox(height: 18),

                      // 5. 5 CIRCULAR QUICK LAUNCHER ACTION BUTTONS
                      _buildFiveQuickLauncherIcons(context),

                      const SizedBox(height: 20),

                      // 6. RECENT UPDATES & BULLETINS
                      _buildRecentUpdatesCard(context),

                      const SizedBox(height: 22),

                      // 8. ACADEMIC PERFORMANCE TREND & INSIGHT CARD
                      _buildAcademicPerformanceTrendSection(context, isDesktop),

                      const SizedBox(height: 28),

                      // 8. CAMPUS RECENT PHOTO GALLERY
                      const RecentPhotosSection(),

                      // Clearance for floating bottom navigation bar
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TOP PARENT HEADER (WELCOME BAR WITH REFRESH BUTTON)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildParentTopWelcomeBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Parent Profile Avatar
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
          ),
        ),
        const SizedBox(width: 12),

        // Welcome Text & Ward Connection
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    _isReturningUser ? 'Hello, Welcome Back!' : 'Hello, Welcome!',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                _parentDisplayName,
                style: GoogleFonts.manrope(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              InkWell(
                onTap: () => _showStudentSelectorSheet(context),
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Parent of ',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      _selectedWard.name,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right Action Button: Notification Bell with Live Badge
        Consumer(
          builder: (context, ref, _) {
            final unreadCount = ref.watch(notificationProvider).unreadCount;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showNotificationSheet(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/bell_ring_2.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/bell-ring-2.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.notifications_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. GRADIENT BORDER SEARCH & QUICK ACTION PILL
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBarAndQuickAction(BuildContext context) {
    return InkWell(
      onTap: () => _showParentSearchModal(context),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 54,
        padding: const EdgeInsets.all(2), // Gradient border width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF10B981), // Mint Emerald Green
              Color(0xFF94A3B8), // Slate transition
              Color(0xFFEC4899), // Vibrant Pink / Rose
              Color(0xFF6366F1), // Indigo
              Color(0xFF2563EB), // Royal Blue
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
                  'Search academics, attendance, exams, updates...',
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showParentNavigationSheet(
                      context: context,
                      selectedIndex: 0,
                      onDestinationSelected: (idx) => widget.onNavigateToTab?.call(idx),
                      items: _ParentDashboardState.parentSidebarItems,
                      userName: _parentDisplayName,
                      userEmail: _parentDisplayEmail,
                    );
                  },
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
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
                    child: const Center(
                      child: Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParentSearchModal(BuildContext context) {
    String query = '';
    final List<Map<String, dynamic>> parentSearchItems = [
      {'title': 'Academics & Performance Marks', 'subtitle': 'Internal test scores, GPA/CGPA & academic analysis', 'icon': Icons.school_rounded, 'color': const Color(0xFF7C3AED), 'tabIndex': 2},
      {'title': 'Attendance History & Shortage Alerts', 'subtitle': 'Subject attendance percentage & shortage alerts', 'icon': Icons.pie_chart_outline_rounded, 'color': const Color(0xFF10B981), 'tabIndex': 1},
      {'title': 'Exams, Schedules & Results', 'subtitle': 'Examination timetable, test venues & performance', 'icon': Icons.description_rounded, 'color': const Color(0xFF2563EB), 'tabIndex': 5},
      {'title': 'Important Announcements & Circulars', 'subtitle': 'Official college notices, academic policies & holiday lists', 'icon': Icons.campaign_rounded, 'color': const Color(0xFFEA580C), 'tabIndex': 3},
      {'title': 'Class Timetable & Schedule', 'subtitle': 'Daily lecture timetable & faculty sessions', 'icon': Icons.schedule_rounded, 'color': const Color(0xFF6366F1), 'tabIndex': 6},
      {'title': 'Assignments & Tasks Progress', 'subtitle': 'Homework, projects & submission deadlines', 'icon': Icons.assignment_rounded, 'color': const Color(0xFFD97706), 'tabIndex': 9},
      {'title': 'Certificates & Documents', 'subtitle': 'Academic bonafide, grade sheets & certificates', 'icon': Icons.verified_rounded, 'color': const Color(0xFF0284C7), 'tabIndex': 10},
      {'title': 'Parent Profile & Contact Info', 'subtitle': 'Guardian details, phone number & ward mappings', 'icon': Icons.person_rounded, 'color': const Color(0xFF475569), 'tabIndex': 4},
      {'title': 'Campus Photo Gallery', 'subtitle': 'Annual events, technical symposia & student fests', 'icon': Icons.collections_rounded, 'color': const Color(0xFF0284C7), 'tabIndex': 7},
      {'title': 'College Events & Fests', 'subtitle': 'Campus festivals, conferences & guest talks', 'icon': Icons.event_rounded, 'color': const Color(0xFF8B5CF6), 'tabIndex': 8},
      {'title': 'College Transport Details', 'subtitle': 'Bus routes, pickup timing & driver contacts', 'icon': Icons.directions_bus_rounded, 'color': const Color(0xFF0D9488), 'tabIndex': 11},
      {'title': 'Notifications & Alerts Feed', 'subtitle': 'All urgent push notifications and reminders', 'icon': Icons.notifications_active_rounded, 'color': const Color(0xFFEF4444), 'isNotification': true},
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredItems = parentSearchItems.where((item) {
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
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search Field inside Modal
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type to search academics, attendance, exams, updates...',
                      hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                setModalState(() => query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() => query = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Quick Search Results (${filteredItems.length})',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 8),
                                Text(
                                  'No matching portal features found',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final Color itemColor = item['color'] as Color;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(item['icon'] as IconData, color: itemColor, size: 20),
                                ),
                                title: Text(
                                  item['title'] as String,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  item['subtitle'] as String,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFFCBD5E1)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  if (item['isNotification'] == true) {
                                    showNotificationSheet(context);
                                  } else if (item['tabIndex'] != null) {
                                    widget.onNavigateToTab?.call(item['tabIndex'] as int);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. STUDENT IDENTITY PROFILE CARD (DYNAMIC PER ACTIVE WARD)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStudentIdentityCard(BuildContext context) {
    final rawDept = _selectedWard.department;
    final deptName = (rawDept.contains('Artificial') || rawDept.contains('AI') || rawDept.contains('Data Science'))
        ? 'AI & Data Science'
        : (rawDept.contains('Computer')
            ? 'Computer Science'
            : (rawDept.contains('Electronics')
                ? 'Electronics & Comm.'
                : (rawDept.contains('Mechanical')
                    ? 'Mechanical Engg'
                    : (rawDept.contains('Civil') ? 'Civil Engg' : rawDept))));

    final deptIcon = (rawDept.contains('Artificial') || rawDept.contains('AI') || rawDept.contains('Data'))
        ? Icons.memory_rounded
        : (rawDept.contains('Computer')
            ? Icons.computer_rounded
            : Icons.school_rounded);

    return InkWell(
      onTap: () => _showStudentSelectorSheet(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Student Photo Avatar with Active Green Dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  ),
                  child: ClipOval(
                    child: _buildWardPhotoAvatar(_selectedWard.photoUrl, _selectedWard.avatarInitials, size: 58),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Name, Active Tag, RegNo, and Department Chip (Year & Section removed)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _selectedWard.name,
                          style: GoogleFonts.manrope(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reg No: ${_selectedWard.regNo}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildSmallTag(
                    deptIcon,
                    deptName,
                    const Color(0xFFEFF6FF),
                    const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // College / Institution Branding (Dynamic per Admin Configuration)
            Consumer(
              builder: (context, ref, _) {
                final collegeName = ref.watch(collegeNameProvider);
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 108),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Color(0xFF4F46E5), size: 24),
                      const SizedBox(height: 3),
                      Text(
                        collegeName,
                        style: GoogleFonts.manrope(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                          height: 1.15,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTag(IconData icon, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 3.5),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWardPhotoAvatar(String? photoUrl, String initials, {double size = 48, bool isSelected = false}) {
    final cleanUrl = photoUrl?.trim() ?? '';
    Widget fallback = Container(
      width: size,
      height: size,
      color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.manrope(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (cleanUrl.isEmpty) return fallback;

    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return Image.network(
        cleanUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
      );
    }
    return fallback;
  }

  void _showStudentSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Active Student Ward',
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Switch profile view to monitor another student ward',
                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ..._wards.map((ward) {
                final isSelected = ward.id == _selectedWard.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0F6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);

                      setState(() => _selectedWard = ward);
                      ref.read(activeParentWardProvider.notifier).state = ward;
                      widget.onWardChanged?.call(ward);

                      final currentUser = ref.read(authServiceProvider).currentUser;
                      final userKey = currentUser?.uid ?? currentUser?.email ?? '';
                      if (userKey.isNotEmpty) {
                        await ref.read(parentServiceProvider).saveActiveWardPreference(
                          parentUidOrEmail: userKey,
                          wardRegNo: ward.regNo,
                        );
                      }

                      if (!mounted) return;
                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Active profile switched to ${ward.name}',
                                style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildWardPhotoAvatar(
                                ward.photoUrl,
                                ward.avatarInitials,
                                size: 48,
                                isSelected: isSelected,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ward.name,
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    ward.regNo,
                                    if (ward.department != '-' && ward.department.isNotEmpty) ward.department,
                                    if (ward.currentSemester != '-' && ward.currentSemester.isNotEmpty) ward.currentSemester,
                                    if (ward.currentYear != '-' && ward.currentYear.isNotEmpty) ward.currentYear,
                                  ].join(' • '),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showAddStudentWardDialog(context);
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Color(0xFF2563EB)),
                label: Text(
                  '+ Link Another Student Ward (Sibling)',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: Color(0xFF93C5FD), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStudentWardDialog(BuildContext context) {
    final regController = TextEditingController();
    Map<String, dynamic>? studentMatch;
    bool isSearching = false;
    bool isSaving = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Link Sibling / Another Student Ward',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter your other child\'s College Register Number to monitor both wards under one parent login.',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: regController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Child Register Number',
                        hintText: 'e.g. 24ECE2018 or RA2111003010001',
                        prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF2563EB)),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (studentMatch != null
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                                : null),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        errorText: errorText,
                      ),
                      onChanged: (val) async {
                        final clean = val.trim().toUpperCase();
                        if (clean.length >= 3) {
                          setDialogState(() {
                            isSearching = true;
                            errorText = null;
                          });
                          final match = await ref.read(parentServiceProvider).lookupStudentByRegNo(clean);

                          // Ignore stale async response if user changed the input while query was in flight
                          if (regController.text.trim().toUpperCase() != clean) {
                            return;
                          }

                          final alreadyLinked = _wards.any((w) => w.regNo.trim().toUpperCase() == clean);

                          setDialogState(() {
                            isSearching = false;
                            if (alreadyLinked) {
                              studentMatch = null;
                              errorText = 'Student is already linked to your account';
                            } else if (match != null) {
                              studentMatch = match;
                              errorText = null;
                            } else {
                              studentMatch = null;
                              if (clean.length == 12 || clean.length >= 8) {
                                errorText = 'No student record found for "$clean"';
                              } else {
                                errorText = null;
                              }
                            }
                          });
                        } else {
                          setDialogState(() {
                            isSearching = false;
                            studentMatch = null;
                            errorText = null;
                          });
                        }
                      },
                    ),
                    if (studentMatch != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: _buildWardPhotoAvatar(
                                  studentMatch!['photoUrl']?.toString(),
                                  (studentMatch!['avatarInitials'] ?? 'ST').toString(),
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentMatch!['fullName'] ?? studentMatch!['name'] ?? 'Student',
                                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                  Text(
                                    '${studentMatch!['departmentName'] ?? studentMatch!['department']} • ${studentMatch!['semester'] ?? 'Semester IV'}',
                                    style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF166534)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dlgCtx).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (studentMatch == null || isSaving)
                                ? null
                                : () async {
                                    setDialogState(() => isSaving = true);
                                    final dlgNav = Navigator.of(dlgCtx);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final currentUser = ref.read(authServiceProvider).currentUser;
                                    final userKey = currentUser?.uid ?? currentUser?.email ?? '';
                                    final regNo = regController.text.trim().toUpperCase();

                                    final success = await ref.read(parentServiceProvider).linkAdditionalChild(
                                      parentUidOrEmail: userKey,
                                      childRegisterNumber: regNo,
                                      parentName: currentUser?.name ?? 'Parent / Guardian',
                                      phone: currentUser?.phone,
                                    );

                                    if (success) {
                                      if (studentMatch != null) {
                                        ref.read(parentServiceProvider).cacheStudentProfile(regNo, studentMatch!);
                                      }
                                      final updatedWards = await ref.read(parentServiceProvider).getStudentWardsForParent(userKey, currentUser: currentUser);
                                      final newWard = updatedWards.firstWhere(
                                        (w) => w.regNo.toUpperCase() == regNo,
                                        orElse: () => updatedWards.last,
                                      );

                                      if (mounted) {
                                        setState(() {
                                          _wards = updatedWards;
                                          _selectedWard = newWard;
                                        });
                                      }
                                      ref.read(activeParentWardProvider.notifier).state = newWard;
                                      widget.onWardChanged?.call(newWard);

                                      await ref.read(parentServiceProvider).saveActiveWardPreference(
                                        parentUidOrEmail: userKey,
                                        wardRegNo: newWard.regNo,
                                      );

                                      if (!mounted) return;
                                      dlgNav.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Successfully linked and switched to ${newWard.name}!'),
                                          backgroundColor: const Color(0xFF16A34A),
                                        ),
                                      );
                                    } else {
                                      setDialogState(() {
                                        isSaving = false;
                                        errorText = 'Could not link student. Please try again.';
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Link & Switch Ward', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  // ───────────────────────────────────────────────────────────────────────────
  // 5. 5 CIRCULAR QUICK LAUNCHER ACTION BUTTONS (PARENT QUICK NAVIGATION BAR)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFiveQuickLauncherIcons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final unreadCount = ref.watch(notificationProvider).unreadCount;
        return ParentQuickNavigationBar(
          onAcademicsTap: () => widget.onNavigateToTab?.call(2),
          onAttendanceTap: () => widget.onNavigateToTab?.call(1),
          onExamsTap: () => widget.onNavigateToTab?.call(5),
          onUpdatesTap: () => showNotificationSheet(context),
          updatesBadgeCount: unreadCount,
          onMoreTap: () {
            showParentNavigationSheet(
              context: context,
              selectedIndex: 0,
              onDestinationSelected: (idx) => widget.onNavigateToTab?.call(idx),
              items: _ParentDashboardState.parentSidebarItems,
              userName: _parentDisplayName,
              userEmail: _parentDisplayEmail,
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6B. RECENT UPDATES CARD (LIVE STREAMED NOTIFICATIONS)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecentUpdatesCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final notificationsState = ref.watch(notificationProvider);
        final liveItems = notificationsState.items.take(4).toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
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
                    children: [
                      Text(
                        'Recent Updates',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (notificationsState.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${notificationsState.unreadCount} NEW',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  InkWell(
                    onTap: () => showNotificationSheet(context),
                    child: Text(
                      'View All',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (liveItems.isNotEmpty)
                ...liveItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecentUpdateRow(
                      icon: item.icon,
                      iconBg: item.iconBgColor,
                      iconColor: item.iconColor,
                      title: item.title,
                      time: item.timeAgo,
                      isUnread: item.isUnread,
                      onTap: () => showNotificationSheet(context),
                    ),
                  );
                })
              else ...[
                _buildRecentUpdateRow(
                  icon: Icons.campaign_rounded,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFEA580C),
                  title: 'Internal marks published',
                  time: 'Today, 10:30 AM',
                  onTap: () => widget.onNavigateToTab?.call(2),
                ),
                const SizedBox(height: 12),
                _buildRecentUpdateRow(
                  icon: Icons.calendar_month_rounded,
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Exam timetable updated',
                  time: 'Yesterday, 04:15 PM',
                  onTap: () => widget.onNavigateToTab?.call(5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentUpdateRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String time,
    required VoidCallback onTap,
    bool isUnread = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. ACADEMIC PERFORMANCE TREND & INSIGHT CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAcademicPerformanceTrendSection(BuildContext context, bool isDesktop) {
    final chartWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Academic Performance Trend',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTrendMode,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  items: const [
                    DropdownMenuItem(value: 'CGPA', child: Text('CGPA', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 'SGPA', child: Text('SGPA', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTrendMode = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Custom Smooth Bezier Trend Chart
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: _AcademicTrendChartPainter(
              values: _selectedTrendMode == 'CGPA'
                  ? const [7.80, 8.12, 8.45, 8.72]
                  : const [8.20, 8.50, 8.60, 8.90],
              labels: const ['Sem 2', 'Sem 3', 'Sem 4', 'Sem 5'],
              lineColor: const Color(0xFF6366F1),
              fillGradientStart: const Color(0xFF6366F1).withValues(alpha: 0.28),
            ),
          ),
        ),
      ],
    );

    final insightCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 18),
              const SizedBox(width: 6),
              Text(
                'Performance Insight',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Alex\'s academic performance is consistently improving.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Great job! Keep it up! ',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6D28D9),
                  ),
                ),
                const TextSpan(text: '💪', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => widget.onNavigateToTab?.call(2),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Details',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF7C3AED)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: chartWidget),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: insightCard),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chartWidget,
                const SizedBox(height: 16),
                insightCard,
              ],
            ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: SMOOTH BEZIER ACADEMIC TREND LINE CHART
// ───────────────────────────────────────────────────────────────────────────
class _AcademicTrendChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final Color fillGradientStart;

  _AcademicTrendChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.fillGradientStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const double paddingLeft = 32.0;
    const double paddingRight = 32.0;
    const double paddingTop = 28.0;
    const double paddingBottom = 26.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final double minVal = values.reduce(math.min) - 0.5;
    final double maxVal = values.reduce(math.max) + 0.5;
    final double range = (maxVal - minVal) <= 0 ? 1.0 : (maxVal - minVal);

    // Compute coordinate points
    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = paddingLeft + (i * chartWidth / (values.length - 1));
      final double normalizedY = (values[i] - minVal) / range;
      final double y = paddingTop + chartHeight - (normalizedY * chartHeight);
      points.add(Offset(x, y));
    }

    // Build smooth cubic Bezier path
    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = i > 0 ? points[i - 1] : points[i];
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      final Offset p3 = i < points.length - 2 ? points[i + 2] : p2;

      final double cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final double cp1y = p1.dy + (p2.dy - p0.dy) / 6;

      final double cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final double cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // Paint Area Gradient Fill underneath
    final Path fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [fillGradientStart, fillGradientStart.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, paddingTop, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Paint Smooth Line Stroke
    final Paint linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF818CF8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw Data Point Nodes & Value Callouts
    for (int i = 0; i < points.length; i++) {
      final p = points[i];

      // Outer glow circle
      canvas.drawCircle(
        p,
        6.5,
        Paint()..color = const Color(0xFF6366F1).withValues(alpha: 0.25),
      );

      // Node ring
      canvas.drawCircle(
        p,
        4.5,
        Paint()
          ..color = const Color(0xFF4F46E5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // White inner dot
      canvas.drawCircle(
        p,
        3.0,
        Paint()..color = Colors.white,
      );

      // Value label text above node
      final textSpan = TextSpan(
        text: values[i].toStringAsFixed(2),
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(p.dx - (textPainter.width / 2), p.dy - 20));

      // X-Axis Semester Label below
      final labelSpan = TextSpan(
        text: labels[i],
        style: GoogleFonts.manrope(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(p.dx - (labelPainter.width / 2), paddingTop + chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _AcademicTrendChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}

// FULL TAB VIEW FOR ATTENDANCE HISTORY (TAB 1)
class ParentAttendanceDetailTab extends StatelessWidget {
  final Function(int index)? onNavigateToTab;
  final ParentStudentWard? selectedWard;

  const ParentAttendanceDetailTab({
    super.key,
    this.onNavigateToTab,
    this.selectedWard,
  });

  @override
  Widget build(BuildContext context) {
    final ward = selectedWard;
    final double attendancePercent = ward?.attendancePercent ?? 0.0;
    final int presentCount = ward?.presentCount ?? 0;
    final int absentCount = ward?.absentCount ?? 0;
    final int totalCount = presentCount + absentCount;
    final String wardName = ward?.name ?? 'Student';
    final String wardDept = ward?.department ?? 'Department of Engineering';

    final List<Map<String, dynamic>> subjects = (ward != null && ward.subjectGrades.isNotEmpty)
        ? ward.subjectGrades.map((sg) {
            final attended = (sg.subjectName.length * 3) % 8 + 27;
            final total = attended + (sg.grade.contains('O') ? 2 : (sg.grade.contains('A+') ? 4 : 5));
            final pct = (attended / total).clamp(0.0, 1.0);
            return {
              'code': sg.subjectCode,
              'name': sg.subjectName,
              'attended': attended,
              'total': total,
              'percent': pct,
              'status': pct >= 0.85 ? 'SAFE' : (pct >= 0.75 ? 'WARNING' : 'CRITICAL'),
              'buffer': '+${(attended - (total * 0.75).ceil()).clamp(0, 20)} classes buffer',
            };
          }).toList()
        : [
            {'code': 'CS601', 'name': 'Core Algorithms & Data Structures', 'attended': 32, 'total': 35, 'percent': 0.914, 'status': 'SAFE', 'buffer': '+6 classes buffer'},
            {'code': 'CS602', 'name': 'Database Management Systems (DBMS)', 'attended': 28, 'total': 32, 'percent': 0.875, 'status': 'SAFE', 'buffer': '+4 classes buffer'},
            {'code': 'CS603', 'name': 'Operating Systems & Architecture', 'attended': 28, 'total': 33, 'percent': 0.848, 'status': 'SAFE', 'buffer': '+3 classes buffer'},
            {'code': 'CS604', 'name': 'Computer Networks & Security', 'attended': 27, 'total': 30, 'percent': 0.900, 'status': 'SAFE', 'buffer': '+4 classes buffer'},
          ];

    final double cutoffPercent = 0.75;
    final double marginAboveCutoff = ((attendancePercent - cutoffPercent) * 100).clamp(0.0, 100.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (onNavigateToTab != null) onNavigateToTab!(0);
                },
              ),
              Text(
                'Complete Attendance Log',
                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overall Gauge Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                AppCircularGauge(
                  radius: 40.0,
                  lineWidth: 8.0,
                  percent: attendancePercent,
                  center: Text('${(attendancePercent * 100).toStringAsFixed(1)}%', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OVERALL ATTENDANCE', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                      Text('$wardName • $wardDept', style: GoogleFonts.manrope(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('$presentCount / $totalCount Total Classes Attended (${marginAboveCutoff.toStringAsFixed(1)}% above cutoff)', style: GoogleFonts.manrope(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Shortage Alert & Regulations Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Shortage Status: Zero Alerts',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF14532D),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SAFE',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Minimum 75% attendance is required for semester exams. All current subjects for $wardName exceed the cutoff with zero shortage warnings.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF166534),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Subject-wise Attendance Progress', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          Column(
            children: subjects.map((s) {
              final double p = s['percent'];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('${s['code']} - ${s['name']}', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(s['status'], style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${s['attended']} attended out of ${s['total']} classes • ${s['buffer']}', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                        Text('${(p * 100).toStringAsFixed(1)}%', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppLinearProgressBar(
                      lineHeight: 8.0,
                      percent: p,
                      backgroundColor: const Color(0xFFF1F5F9),
                      progressColor: const Color(0xFF059669),
                      borderRadius: 4.0,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

// FULL TAB VIEW FOR PERFORMANCE MARKS & CGPA (TAB 2)
class ParentAcademicPerformanceTab extends StatelessWidget {
  final Function(int index)? onNavigateToTab;
  final ParentStudentWard? selectedWard;

  const ParentAcademicPerformanceTab({
    super.key,
    this.onNavigateToTab,
    this.selectedWard,
  });

  @override
  Widget build(BuildContext context) {
    final ward = selectedWard;
    final String cgpa = ward?.cgpa ?? '8.8';
    final String wardName = ward?.name ?? 'Student';
    final String wardDept = ward?.department ?? 'Department of Engineering';
    final String currentSem = ward?.currentSemester ?? 'VI Semester';

    final List<Map<String, String>> currentSemSubjects = (ward != null && ward.subjectGrades.isNotEmpty)
        ? ward.subjectGrades.map((sg) {
            return {
              'subject': '${sg.subjectName} (${sg.subjectCode})',
              'marks': '${sg.grade.contains('O') ? '92' : (sg.grade.contains('A+') ? '86' : '82')}/100',
              'grade': '${sg.grade} (${sg.grade.contains('O') ? 'Outstanding' : (sg.grade.contains('A+') ? 'Excellent' : 'Very Good')})',
              'progress': sg.grade.contains('O') ? '0.92' : (sg.grade.contains('A+') ? '0.86' : '0.82'),
            };
          }).toList()
        : [
            {'subject': 'Core Algorithms & Data Structures (CS601)', 'marks': '94/100', 'grade': 'O (Outstanding)', 'progress': '0.94'},
            {'subject': 'Database Management Systems (CS602)', 'marks': '88/100', 'grade': 'A+ (Excellent)', 'progress': '0.88'},
            {'subject': 'Operating Systems & Architecture (CS603)', 'marks': '85/100', 'grade': 'A (Very Good)', 'progress': '0.85'},
            {'subject': 'Computer Networks & Security (CS604)', 'marks': '90/100', 'grade': 'O (Outstanding)', 'progress': '0.90'},
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (onNavigateToTab != null) onNavigateToTab!(0);
                },
              ),
              Text(
                'Academic Performance & Progress',
                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CUMULATIVE GRADE POINT AVERAGE', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                    Text(cgpa, style: GoogleFonts.manrope(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('$wardName • $wardDept', style: GoogleFonts.manrope(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
                      child: Text(ward?.academicStatus ?? 'Good Standing', style: GoogleFonts.manrope(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text('${ward?.currentYear ?? 'III Year'} • $currentSem', style: GoogleFonts.manrope(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Subject-wise Progress & Marks', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          _buildSemesterCard('$currentSem (Current Semester)', cgpa, 'A+ Grade', currentSemSubjects),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(String title, String sgpa, String overall, List<Map<String, String>> subs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('SGPA: $sgpa', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              ),
            ],
          ),
          const Divider(height: 20),
          ...subs.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(s['subject']!, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                        Text('${s['marks']} (${s['grade']})', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppLinearProgressBar(
                      lineHeight: 6.0,
                      percent: double.tryParse(s['progress'] ?? '0.8') ?? 0.8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      progressColor: const Color(0xFF2563EB),
                      borderRadius: 3.0,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// NATIVE STABLE FLUTTER GAUGE WIDGET (REPLACES PERCENT_INDICATOR TO PREVENT SEMANTICS ASSERTIONS)
class AppCircularGauge extends StatelessWidget {
  final double radius;
  final double lineWidth;
  final double percent;
  final Widget center;
  final Color progressColor;
  final Color backgroundColor;

  const AppCircularGauge({
    super.key,
    required this.radius,
    required this.lineWidth,
    required this.percent,
    required this.center,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              strokeWidth: lineWidth,
              strokeAlign: CircularProgressIndicator.strokeAlignInside,
              color: progressColor,
              backgroundColor: backgroundColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          center,
        ],
      ),
    );
  }
}

// NATIVE STABLE FLUTTER PROGRESS BAR (REPLACES PERCENT_INDICATOR TO PREVENT SEMANTICS ASSERTIONS)
class AppLinearProgressBar extends StatelessWidget {
  final double lineHeight;
  final double percent;
  final Color progressColor;
  final Color backgroundColor;
  final double borderRadius;

  const AppLinearProgressBar({
    super.key,
    required this.lineHeight,
    required this.percent,
    required this.progressColor,
    required this.backgroundColor,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: lineHeight,
        child: LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          color: progressColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

// =============================================================================
// STANDALONE DIALOG & CARD WIDGETS WITH ISOLATED WIDGET TREE IDENTITY
// PREVENTS PARENTDATA AND SEMANTICS DISCREPANCIES IN FLUTTER RENDERFLEX PASSES
// =============================================================================

class MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String val;
  final String label;

  const MiniStatCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.val,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(height: 4),
            Text(val, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 9, color: const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class AttendanceSubjectCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String code;
  final String name;
  final String faculty;
  final String ratio;
  final String percentStr;
  final String status;
  final Color statusColor;
  final double progress;
  final Color barColor;

  const AttendanceSubjectCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.code,
    required this.name,
    required this.faculty,
    required this.ratio,
    required this.percentStr,
    required this.status,
    required this.statusColor,
    required this.progress,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$code $name',
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      faculty,
                      style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ratio, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: Text(percentStr, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(status, style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppLinearProgressBar(
            lineHeight: 6.0,
            percent: progress,
            backgroundColor: const Color(0xFFF1F5F9),
            progressColor: barColor,
            borderRadius: 4.0,
          ),
        ],
      ),
    );
  }
}

class AttendanceOverviewDialog extends StatelessWidget {
  final String studentName;
  final String registerNum;
  final Function(int)? onNavigateToTab;

  const AttendanceOverviewDialog({
    super.key,
    required this.studentName,
    required this.registerNum,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP HEADER ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF059669), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Overview',
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          '$studentName ($registerNum)',
                          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Good Standing',
                                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Semester: Jan – May 2025',
                                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // OVERALL ATTENDANCE SUMMARY CONTAINER
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    AppCircularGauge(
                      radius: 44.0,
                      lineWidth: 9.0,
                      percent: 0.885,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '88.5%',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            'Overall\nAttendance',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(fontSize: 9, color: const Color(0xFF64748B), height: 1.1),
                          ),
                        ],
                      ),
                      progressColor: const Color(0xFF059669),
                      backgroundColor: const Color(0xFFD1FAE5),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'SAFE • ABOVE 80%',
                                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You\'re maintaining excellent attendance!',
                            style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              MiniStatCard(
                                icon: Icons.calendar_month_rounded,
                                iconBg: Color(0xFFEFF6FF),
                                iconColor: Color(0xFF2563EB),
                                val: '131',
                                label: 'Classes Attended',
                              ),
                              SizedBox(width: 8),
                              MiniStatCard(
                                icon: Icons.edit_calendar_rounded,
                                iconBg: Color(0xFFFCE7F3),
                                iconColor: Color(0xFFDB2777),
                                val: '147',
                                label: 'Total Classes',
                              ),
                              SizedBox(width: 8),
                              MiniStatCard(
                                icon: Icons.percent_rounded,
                                iconBg: Color(0xFFFFEDD5),
                                iconColor: Color(0xFFEA580C),
                                val: '88.5%',
                                label: 'Overall Percentage',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // NOTIFICATION ALERT BANNER BOX
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E7FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF4338CA), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Great job! Keep your attendance above 80% to maintain your academic standing.',
                        style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF3730A3), fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.close_rounded, color: Color(0xFF6366F1), size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SUBJECT BREAKDOWN HEADER & SORT DROPDOWN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Subject Breakdown',
                      style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sort by: Percentage',
                          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF475569)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // SUBJECT CARDS LIST
              const AttendanceSubjectCard(
                icon: Icons.code_rounded,
                iconBg: Color(0xFFEFF6FF),
                iconColor: Color(0xFF2563EB),
                code: 'CS301',
                name: 'Data Structures',
                faculty: 'Mr. David Williams',
                ratio: '32 / 35',
                percentStr: '91.4%',
                status: 'Excellent',
                statusColor: Color(0xFF15803D),
                progress: 0.914,
                barColor: Color(0xFF2563EB),
              ),
              const AttendanceSubjectCard(
                icon: Icons.desktop_windows_rounded,
                iconBg: Color(0xFFDCFCE7),
                iconColor: Color(0xFF166534),
                code: 'CS302',
                name: 'Operating Systems',
                faculty: 'Dr. Sarah Thompson',
                ratio: '28 / 33',
                percentStr: '84.8%',
                status: 'Good',
                statusColor: Color(0xFF15803D),
                progress: 0.848,
                barColor: Color(0xFF059669),
              ),
              const AttendanceSubjectCard(
                icon: Icons.dns_rounded,
                iconBg: Color(0xFFF3E8FF),
                iconColor: Color(0xFF7C3AED),
                code: 'CS303',
                name: 'Database Systems',
                faculty: 'Mr. James Anderson',
                ratio: '28 / 32',
                percentStr: '87.5%',
                status: 'Good',
                statusColor: Color(0xFF15803D),
                progress: 0.875,
                barColor: Color(0xFF7C3AED),
              ),
              const AttendanceSubjectCard(
                icon: Icons.calculate_rounded,
                iconBg: Color(0xFFFFEDD5),
                iconColor: Color(0xFFC2410C),
                code: 'MA301',
                name: 'Discrete Mathematics',
                faculty: 'Dr. Lisa Brown',
                ratio: '27 / 30',
                percentStr: '90.0%',
                status: 'Excellent',
                statusColor: Color(0xFF15803D),
                progress: 0.900,
                barColor: Color(0xFFEA580C),
              ),
              const AttendanceSubjectCard(
                icon: Icons.science_rounded,
                iconBg: Color(0xFFCFFAFE),
                iconColor: Color(0xFF0E7490),
                code: 'CS304',
                name: 'Web Tech Lab',
                faculty: 'Mr. Robert Johnson',
                ratio: '16 / 17',
                percentStr: '94.1%',
                status: 'Excellent',
                statusColor: Color(0xFF15803D),
                progress: 0.941,
                barColor: Color(0xFF0891B2),
              ),

              const SizedBox(height: 16),

              // BOTTOM MOTIVATIONAL TARGET CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDD6FE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF7C3AED), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keep It Up!',
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF6D28D9)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You\'re doing great! Your attendance is above the required 80% threshold.',
                                style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF7C3AED), height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          AppCircularGauge(
                            radius: 18.0,
                            lineWidth: 4.0,
                            percent: 0.885,
                            center: Text('88.5%', style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF6D28D9))),
                            progressColor: const Color(0xFF7C3AED),
                            backgroundColor: const Color(0xFFDDD6FE),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Target Goal: 90%', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6D28D9))),
                                Text('Attend 16 more classes to reach 90% target', style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF7C3AED))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // BOTTOM ACTION BUTTONS ROW
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text('Download Report', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E293B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (onNavigateToTab != null) {
                            onNavigateToTab!(1);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 18),
                        label: Text('Open Complete Attendance Log', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CgpaAnalyticsDialog extends StatelessWidget {
  final String studentName;
  final String registerNum;
  final Function(int)? onNavigateToTab;

  const CgpaAnalyticsDialog({
    super.key,
    required this.studentName,
    required this.registerNum,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF2563EB), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CGPA & Grade Analytics',
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          '$studentName ($registerNum)',
                          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    AppCircularGauge(
                      radius: 44.0,
                      lineWidth: 9.0,
                      percent: 0.892,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '8.2',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 20, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            'Overall\nCGPA',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(fontSize: 9, color: const Color(0xFF64748B), height: 1.1),
                          ),
                        ],
                      ),
                      progressColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFEFF6FF),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, color: Color(0xFF15803D), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'GOOD STANDING',
                                  style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Consistently maintaining Grade A+ & O across technical courses.',
                            style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text('Download Marksheet', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E293B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onNavigateToTab?.call(2);
                        },
                        icon: const Icon(Icons.bar_chart_rounded, size: 18),
                        label: Text('Open Full Grade History', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AcademicStandingDialog extends StatelessWidget {
  final String studentName;
  final String registerNum;
  final String academicStatus;
  final Function(int)? onNavigateToTab;

  const AcademicStandingDialog({
    super.key,
    required this.studentName,
    required this.registerNum,
    required this.academicStatus,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_user_outlined, color: Color(0xFF059669), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Academic Standing',
                                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                studentName,
                                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildStatusItem(Icons.verified_rounded, 'Standing Status', academicStatus, const Color(0xFF059669)),
              _buildStatusItem(Icons.school_rounded, 'Registration', 'Semester 5 (Autumn 2026 Active)', const Color(0xFF2563EB)),
              _buildStatusItem(Icons.stars_rounded, 'Total Credits Tally', '48 / 160 Credits Completed', const Color(0xFF7C3AED)),
              _buildStatusItem(Icons.gavel_rounded, 'Disciplinary Record', 'Clean • Zero Warnings or Penalties', AppColors.success),
              _buildStatusItem(Icons.work_history_rounded, 'Placement Eligibility', 'Eligible for On-Campus Placement Drives', AppColors.primary),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Close Academic Profile', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String title, String val, Color valColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: valColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: valColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: valColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
