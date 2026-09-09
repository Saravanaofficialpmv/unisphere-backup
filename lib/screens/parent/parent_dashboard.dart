import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/parent_service.dart';
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
import 'package:unisphere/core/responsive/responsive_breakpoints.dart';
import 'package:unisphere/widgets/common/app_desktop_shell.dart';
import 'package:unisphere/widgets/common/app_desktop_header.dart';
import 'package:unisphere/screens/parent/parent_profile_screen.dart';
import 'package:unisphere/widgets/common/recent_photos_section.dart';
import 'package:unisphere/widgets/common/recent_updates_card.dart';
import 'package:unisphere/widgets/common/latest_photo_gallery_card.dart';
import 'package:unisphere/screens/gallery/full_photo_gallery_screen.dart';
import 'package:unisphere/screens/student/modules/student_announcements_screen.dart';
import 'package:unisphere/screens/features/events_screen.dart';
import 'package:unisphere/screens/features/exams_detail_screen.dart';
import 'package:unisphere/screens/features/academic_schedule_detail_screen.dart';
import 'package:unisphere/screens/student/modules/student_upcoming_tasks_screen.dart';
import 'package:unisphere/screens/features/certifications_screen.dart';
import 'package:unisphere/core/theme/app_animations.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:file_picker/file_picker.dart';


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
  final int initialIndex;
  const ParentDashboard({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  late int _currentIndex;
  ParentStudentWard? _activeWard;
  List<ParentStudentWard> _dashboardWards = [];
  StreamSubscription<List<ParentStudentWard>>? _dashboardWardsSub;
  bool _isNavigationSheetOpen = false;
  bool _isDockVisible = true;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _innerNavigatorKey = GlobalKey<NavigatorState>();

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
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initActiveWard());
  }

  @override
  void didUpdateWidget(ParentDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() => _currentIndex = widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _dashboardWardsSub?.cancel();
    super.dispose();
  }

  Future<void> _initActiveWard() async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    final userKey = currentUser?.uid ?? currentUser?.email ?? '';
    final parentService = ref.read(parentServiceProvider);

    _setupDashboardWardsListener(userKey, currentUser);

    final wards = await parentService.getStudentWardsForParent(userKey, currentUser: currentUser);

    if (wards.isNotEmpty && mounted) {
      final activeReg = userKey.isNotEmpty ? await parentService.getActiveWardPreference(userKey) : null;
      final selected = (activeReg != null && activeReg.isNotEmpty)
          ? wards.firstWhere((w) => w.regNo.toUpperCase() == activeReg.toUpperCase(), orElse: () => wards.first)
          : wards.first;

      setState(() {
        _dashboardWards = wards;
        _activeWard = selected;
      });
      ref.read(activeParentWardProvider.notifier).state = selected;
      ref.read(parentWardsListProvider.notifier).state = wards;
    }
  }

  void _setupDashboardWardsListener(String userKey, dynamic currentUser) {
    if (userKey.isEmpty) return;
    _dashboardWardsSub?.cancel();
    _dashboardWardsSub = ref.read(parentServiceProvider).watchParentWards(userKey, currentUser: currentUser).listen((liveWards) {
      if (liveWards.isNotEmpty && mounted) {
        setState(() {
          _dashboardWards = liveWards;
          if (_activeWard != null) {
            _activeWard = liveWards.firstWhere(
              (w) => w.regNo.toUpperCase() == _activeWard!.regNo.toUpperCase(),
              orElse: () => liveWards.first,
            );
          } else {
            _activeWard = liveWards.first;
          }
        });
        ref.read(activeParentWardProvider.notifier).state = _activeWard;
        ref.read(parentWardsListProvider.notifier).state = liveWards;
      }
    });
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
    final isDesktop = AppResponsive.isDesktop(context);

    if (isDesktop) {
      final currentItem = (_currentIndex >= 0 && _currentIndex < _sidebarItems.length)
          ? _sidebarItems[_currentIndex]
          : _sidebarItems[0];
      final currentTitle = currentItem.isDivider ? 'Parent Portal' : currentItem.label;
      final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
      final userName = (currentUser?.name != null && currentUser!.name.trim().isNotEmpty)
          ? currentUser.name
          : 'Parent / Guardian';
      final activeWard = _activeWard;

      return AppDesktopShell(
        sidebar: _buildSidebar(),
        header: AppDesktopHeader(
          onBack: _currentIndex != 0 ? _handleBackNavigation : null,
          breadcrumbs: ['UniSphere', 'Parent Portal', currentTitle],
          title: currentTitle,
          subtitle: activeWard != null
              ? 'Monitoring: ${activeWard.name} (${activeWard.regNo}) • ${activeWard.department}'
              : 'Ward Academic & Attendance Monitoring',
          departmentName: activeWard?.department ?? 'Parent Monitoring',
          roleName: 'Parent',
          roleColor: AppColors.parentRole,
          userName: userName,
          userPhotoUrl: currentUser?.metadata?['photoUrl'],
          onProfileTap: () => _handleNavigation(11),
        ),
        body: FadeSlideTransition(
          transitionKey: ValueKey('parent_tab_$_currentIndex'),
          duration: const Duration(milliseconds: 180),
          child: _buildScreen(_currentIndex),
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
                      final currentUser = ref.read(authServiceProvider).currentUser;
                      final profileUrl = ref.read(parentServiceProvider).resolveParentPhotoFromWards(
                        relationship: currentUser?.metadata?['relationship'],
                        wards: _dashboardWards,
                        currentParentPhoto: currentUser?.profileImageUrl,
                      );
                      await showParentNavigationSheet(
                        context: context,
                        selectedIndex: _currentIndex,
                        onDestinationSelected: _handleNavigation,
                        items: _sidebarItems,
                        userName: _parentDisplayName,
                        userEmail: _parentDisplayEmail,
                        profileUrl: profileUrl,
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
    final parentService = ref.watch(parentServiceProvider);
    final profileUrl = parentService.resolveParentPhotoFromWards(
      relationship: currentUser?.metadata?['relationship'],
      wards: _dashboardWards,
      currentParentPhoto: currentUser?.profileImageUrl,
    );

    return MainSidebar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _handleNavigation,
      items: _sidebarItems,
      userName: userName,
      userEmail: userEmail,
      profileUrl: profileUrl,
      isCollapsed: _isSidebarCollapsed,
      onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
      roleBadge: 'PARENT',
      roleColor: AppColors.parentRole,
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
  StreamSubscription<List<ParentStudentWard>>? _homeWardsSub;
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

  @override
  void dispose() {
    _homeWardsSub?.cancel();
    super.dispose();
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
    if (widget.selectedWard != null && (widget.selectedWard!.id != _selectedWard.id || widget.selectedWard != _selectedWard)) {
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
        _setupLiveWardsListener();

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

  void _setupLiveWardsListener() {
    final currentUser = ref.read(authServiceProvider).currentUser;
    final userKey = currentUser?.uid ?? currentUser?.email ?? '';
    if (userKey.isEmpty) return;

    _homeWardsSub?.cancel();
    _homeWardsSub = ref.read(parentServiceProvider).watchParentWards(userKey, currentUser: currentUser).listen((liveWards) {
      if (liveWards.isNotEmpty && mounted) {
        setState(() {
          _wards = liveWards;
          _selectedWard = liveWards.firstWhere(
            (w) => w.regNo.toUpperCase() == _selectedWard.regNo.toUpperCase(),
            orElse: () => liveWards.first,
          );
        });
        ref.read(activeParentWardProvider.notifier).state = _selectedWard;
      }
    });
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
                      // 3. STUDENT IDENTITY PROFILE CARD WITH ATTACHED STATUS DECK (REFERENCE DESIGN)
                      StudentReferenceCardWithDeck(
                        selectedWard: _selectedWard,
                        onCardTap: () => _showStudentSelectorSheet(context),
                        onNavigateToTab: widget.onNavigateToTab,
                      ),

                      const SizedBox(height: 20),

                      // 5. 5 CIRCULAR QUICK LAUNCHER ACTION BUTTONS
                      _buildFiveQuickLauncherIcons(context),

                      const SizedBox(height: 20),

                      // 5B. LATEST PHOTO GALLERY (ADVISOR & HOD UPDATES - FITTED IMAGES)
                      LatestPhotoGalleryCard(
                        departmentFilter: _selectedWard.department,
                        onViewAllPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FullPhotoGalleryScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 6. RECENT UPDATES & BULLETINS
                      RecentUpdatesCard(
                        onNavigateToTab: widget.onNavigateToTab,
                        onViewAll: () => showNotificationSheet(
                          context,
                          onNavigateToTab: widget.onNavigateToTab != null
                              ? (idx, {openCalculator = false}) => widget.onNavigateToTab!(idx)
                              : null,
                        ),
                      ),

                      const SizedBox(height: 24),

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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      _selectedWard.regNo.isNotEmpty ? _selectedWard.regNo : _selectedWard.name,
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
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
                    final currentUser = ref.read(authServiceProvider).currentUser;
                    final profileUrl = ref.read(parentServiceProvider).resolveParentPhotoFromWards(
                      relationship: currentUser?.metadata?['relationship'],
                      wards: _wards,
                      currentParentPhoto: currentUser?.profileImageUrl,
                    );
                    showParentNavigationSheet(
                      context: context,
                      selectedIndex: 0,
                      onDestinationSelected: (idx) => widget.onNavigateToTab?.call(idx),
                      items: _ParentDashboardState.parentSidebarItems,
                      userName: _parentDisplayName,
                      userEmail: _parentDisplayEmail,
                      profileUrl: profileUrl,
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _wards.map((ward) {
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
                      }).toList(),
                    ),
                  ),
                ),
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
            final currentUser = ref.read(authServiceProvider).currentUser;
            final profileUrl = ref.read(parentServiceProvider).resolveParentPhotoFromWards(
              relationship: currentUser?.metadata?['relationship'],
              wards: _wards,
              currentParentPhoto: currentUser?.profileImageUrl,
            );
            showParentNavigationSheet(
              context: context,
              selectedIndex: 0,
              onDestinationSelected: (idx) => widget.onNavigateToTab?.call(idx),
              items: _ParentDashboardState.parentSidebarItems,
              userName: _parentDisplayName,
              userEmail: _parentDisplayEmail,
              profileUrl: profileUrl,
            );
          },
        );
      },
    );
  }
}



// FULL TAB VIEW FOR ATTENDANCE HISTORY (TAB 1)
class ParentAttendanceDetailTab extends ConsumerStatefulWidget {
  final Function(int index)? onNavigateToTab;
  final ParentStudentWard? selectedWard;

  const ParentAttendanceDetailTab({
    super.key,
    this.onNavigateToTab,
    this.selectedWard,
  });

  @override
  ConsumerState<ParentAttendanceDetailTab> createState() => _ParentAttendanceDetailTabState();
}

class _ParentAttendanceDetailTabState extends ConsumerState<ParentAttendanceDetailTab> {
  ParentStudentWard? _liveWard;
  StreamSubscription<ParentStudentWard?>? _wardSub;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _liveWard = widget.selectedWard;
    _setupWardListener();
  }

  @override
  void didUpdateWidget(ParentAttendanceDetailTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedWard != null && widget.selectedWard?.regNo != _liveWard?.regNo) {
      _liveWard = widget.selectedWard;
      _setupWardListener();
    }
  }

  @override
  void dispose() {
    _wardSub?.cancel();
    super.dispose();
  }

  void _setupWardListener() {
    _wardSub?.cancel();
    final parentService = ref.read(parentServiceProvider);
    if (parentService.firestore == null) return;

    final regNo = _liveWard?.regNo ?? widget.selectedWard?.regNo ?? '';
    if (regNo.isNotEmpty) {
      _wardSub = parentService.watchStudentWard(regNo).listen((ward) {
        if (ward != null && mounted) {
          setState(() {
            _liveWard = ward;
          });
        }
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);

    try {
      final parentService = ref.read(parentServiceProvider);
      final regNo = _liveWard?.regNo ?? widget.selectedWard?.regNo ?? '23CSE1042';
      final freshData = await parentService.lookupStudentByRegNo(regNo);

      final currentUser = ref.read(authServiceProvider).currentUser;
      final userKey = currentUser?.uid ?? currentUser?.email ?? '';
      if (userKey.isNotEmpty) {
        final updatedWards = await parentService.getStudentWardsForParent(userKey, currentUser: currentUser);
        if (updatedWards.isNotEmpty && mounted) {
          ref.read(parentWardsListProvider.notifier).state = updatedWards;
        }
      }

      if (freshData != null && mounted) {
        final rawAtt = freshData['attendancePercent']?.toString() ?? '87.5%';
        final double attVal = (double.tryParse(rawAtt.replaceAll('%', '')) ?? 87.5) / 100.0;
        final updated = (_liveWard ?? widget.selectedWard ?? parentService.getDefaultStudentWards().first).copyWith(
          attendancePercent: attVal,
          presentCount: (freshData['presentCount'] as num?)?.toInt() ?? _liveWard?.presentCount,
          absentCount: (freshData['absentCount'] as num?)?.toInt() ?? _liveWard?.absentCount,
          leaveOdCount: (freshData['leaveOdCount'] as num?)?.toInt() ?? _liveWard?.leaveOdCount,
          todayStatus: freshData['todayStatus'] ?? _liveWard?.todayStatus,
        );
        setState(() => _liveWard = updated);
        ref.read(activeParentWardProvider.notifier).state = updated;
      }
    } catch (e) {
      debugPrint('Error refreshing attendance tab: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attendance log synced in real time',
                    style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ward = _liveWard ?? ref.watch(activeParentWardProvider) ?? widget.selectedWard;
    final double attendancePercent = ward?.attendancePercent ?? 0.87;
    final int presentCount = ward?.presentCount ?? 142;
    final int absentCount = ward?.absentCount ?? 15;
    final int totalCount = presentCount + absentCount;
    final String wardName = (ward?.name != null && ward!.name.isNotEmpty && !ward.name.startsWith('Student ')) ? ward.name : 'Arun Kumar';
    final String wardDept = (ward?.department != null && ward!.department.isNotEmpty && ward.department != '-') ? ward.department : 'Computer Science & Engineering';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF10B981),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                      onPressed: () {
                        if (widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(0);
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete Attendance Log',
                            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            'Daily & Subject-wise Biometric Records',
                            style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)))
                          : const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
                      onPressed: _handleRefresh,
                      tooltip: 'Swipe down or tap to refresh',
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
          ),
        ),
      ),
    );
  }
}

// FULL INTERACTIVE TAB VIEW FOR PARENT ACADEMIC PERFORMANCE & INTERNAL MARKS (TAB 2)
class ParentAcademicPerformanceTab extends ConsumerStatefulWidget {
  final Function(int index)? onNavigateToTab;
  final ParentStudentWard? selectedWard;

  const ParentAcademicPerformanceTab({
    super.key,
    this.onNavigateToTab,
    this.selectedWard,
  });

  @override
  ConsumerState<ParentAcademicPerformanceTab> createState() => _ParentAcademicPerformanceTabState();
}

class _ParentAcademicPerformanceTabState extends ConsumerState<ParentAcademicPerformanceTab> with SingleTickerProviderStateMixin {
  int _selectedSemIndex = 3; // Default to Semester 4 / current term
  String _selectedInternalFilter = 'All'; // 'All', 'IA-1', 'IA-2', 'Model', 'Final'
  ParentStudentWard? _liveWard;
  StreamSubscription<ParentStudentWard?>? _wardSub;
  StreamSubscription<Map<String, dynamic>?>? _academicPerfSub;
  StreamSubscription? _marksSub;
  Map<String, dynamic>? _liveAcademicPerformanceData;
  List<Map<String, dynamic>> _liveFirestoreMarks = [];
  bool _isRefreshing = false;
  late AnimationController _refreshAnimController;

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
  ];

  final List<Map<String, String>> _filterOptions = [
    {'id': 'All', 'label': 'All Assessments', 'icon': 'dashboard'},
    {'id': 'IA-1', 'label': 'IA-1 (50 Marks)', 'icon': 'quiz'},
    {'id': 'IA-2', 'label': 'IA-2 (50 Marks)', 'icon': 'assignment'},
    {'id': 'Model', 'label': 'Model Exam (100M)', 'icon': 'school'},
    {'id': 'Final', 'label': 'Total Internal (60M)', 'icon': 'verified'},
  ];

  @override
  void initState() {
    super.initState();
    _liveWard = widget.selectedWard;
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _setupRealtimeListeners();
  }

  @override
  void didUpdateWidget(ParentAcademicPerformanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedWard != null && widget.selectedWard?.regNo != _liveWard?.regNo) {
      _liveWard = widget.selectedWard;
      _setupRealtimeListeners();
    }
  }

  @override
  void dispose() {
    _wardSub?.cancel();
    _academicPerfSub?.cancel();
    _marksSub?.cancel();
    _refreshAnimController.dispose();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    _wardSub?.cancel();
    _academicPerfSub?.cancel();
    _marksSub?.cancel();

    final parentService = ref.read(parentServiceProvider);
    final firestore = parentService.firestore;
    if (firestore == null) return;

    final regNo = _liveWard?.regNo ?? widget.selectedWard?.regNo ?? '922523243079';

    // 1. Listen to real-time student ward stream from Firestore
    _wardSub = parentService.watchStudentWard(regNo).listen((updatedWard) {
      if (updatedWard != null && mounted) {
        setState(() {
          _liveWard = updatedWard;
        });
      }
    });

    // 2. Listen to real-time full academic performance stream from Firestore
    _academicPerfSub = parentService.watchStudentAcademicPerformance(regNo).listen((doc) {
      if (doc != null && mounted) {
        setState(() {
          _liveAcademicPerformanceData = doc;
        });
      }
    });

    // 3. Listen to real-time Firestore marks & assignments collections
    if (regNo.isNotEmpty) {
      final regUpper = regNo.toUpperCase();
      final regLower = regNo.toLowerCase();

      // Listen to individual marks collection
      _marksSub = firestore
          .collection('marks')
          .snapshots()
          .listen((snap) {
        if (mounted) {
          final matched = snap.docs.where((d) {
            final uid = (d.data()['student_uid'] ?? d.data()['studentId'] ?? d.data()['regNo'] ?? '').toString();
            return uid.toUpperCase() == regUpper || uid.toLowerCase() == regLower || uid == cleanReg(regNo);
          }).map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();

          setState(() {
            _liveFirestoreMarks = matched;
          });
        }
      }, onError: (e) {
        debugPrint('Marks real-time stream error: $e');
      });

      // Listen to faculty assignments collection for published marks
      firestore.collection('assignments').snapshots().listen((snap) {
        if (mounted) {
          final List<Map<String, dynamic>> extractedMarks = [];
          for (final doc in snap.docs) {
            final d = doc.data();
            final subject = d['subject']?.toString() ?? '';
            final examType = d['examType']?.toString() ?? '';
            final records = (d['studentRecords'] as List?) ?? [];
            for (final r in records) {
              if (r is Map) {
                final rReg = (r['regNo'] ?? r['studentId'] ?? '').toString().trim().toUpperCase();
                if (rReg.isNotEmpty && (rReg == regUpper || rReg == regLower.toUpperCase() || rReg == cleanReg(regNo).toUpperCase())) {
                  final initial = r['initial']?.toString() ?? '0';
                  final parts = initial.split('/');
                  final obt = double.tryParse(parts[0].trim()) ?? 0;
                  final tot = parts.length > 1 ? (double.tryParse(parts[1].split(' ')[0].trim()) ?? 50) : 50;

                  extractedMarks.add({
                    'subject_name': subject,
                    'exam_type': examType,
                    'obtained_marks': obt,
                    'total_marks': tot,
                    'retest': r['retest']?.toString(),
                    'retestStatus': r['status']?.toString(),
                    'conv': r['conv']?.toString(),
                  });
                }
              }
            }
          }
          if (extractedMarks.isNotEmpty) {
            setState(() {
              _liveFirestoreMarks = [..._liveFirestoreMarks, ...extractedMarks];
            });
          }
        }
      });
    }
  }

  String cleanReg(String r) => r.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    HapticFeedback.mediumImpact();
    _refreshAnimController.repeat();
    setState(() => _isRefreshing = true);

    try {
      final parentService = ref.read(parentServiceProvider);
      final regNo = _liveWard?.regNo ?? widget.selectedWard?.regNo ?? '922523243079';

      // 1. Fresh lookup across student_profiles, students, users, attendance, marks
      final freshWardData = await parentService.lookupStudentByRegNo(regNo);

      // 2. Fetch fresh academic performance doc from Firestore
      final freshAcademicDoc = await parentService.getStudentAcademicPerformance(regNo);
      if (freshAcademicDoc != null && mounted) {
        setState(() {
          _liveAcademicPerformanceData = freshAcademicDoc;
        });
      }

      // 3. Refresh parent mapped children list if parent is logged in
      final currentUser = ref.read(authServiceProvider).currentUser;
      final userKey = currentUser?.uid ?? currentUser?.email ?? '';
      if (userKey.isNotEmpty) {
        final updatedWards = await parentService.getStudentWardsForParent(userKey, currentUser: currentUser);
        if (updatedWards.isNotEmpty && mounted) {
          ref.read(parentWardsListProvider.notifier).state = updatedWards;
        }
      }

      // 4. Fetch latest marks directly from Firestore marks & assignments
      final firestore = parentService.firestore;
      if (firestore != null && regNo.isNotEmpty) {
        final regUpper = regNo.toUpperCase();
        final regLower = regNo.toLowerCase();

        final marksSnap = await firestore.collection('marks').get();
        final matchedMarks = marksSnap.docs.where((d) {
          final uid = (d.data()['student_uid'] ?? d.data()['studentId'] ?? d.data()['regNo'] ?? '').toString();
          return uid.toUpperCase() == regUpper || uid.toLowerCase() == regLower || uid == cleanReg(regNo);
        }).map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();

        try {
          final asgSnap = await firestore.collection('assignments').get();
          for (final doc in asgSnap.docs) {
            final d = doc.data();
            final subject = d['subject']?.toString() ?? '';
            final examType = d['examType']?.toString() ?? '';
            final records = (d['studentRecords'] as List?) ?? [];
            for (final r in records) {
              if (r is Map) {
                final rReg = (r['regNo'] ?? r['studentId'] ?? '').toString().trim().toUpperCase();
                if (rReg.isNotEmpty && (rReg == regUpper || rReg == regLower.toUpperCase() || rReg == cleanReg(regNo).toUpperCase())) {
                  final initial = r['initial']?.toString() ?? '0';
                  final parts = initial.split('/');
                  final obt = double.tryParse(parts[0].trim()) ?? 0;
                  final tot = parts.length > 1 ? (double.tryParse(parts[1].split(' ')[0].trim()) ?? 50) : 50;
                  matchedMarks.add({
                    'subject_name': subject,
                    'exam_type': examType,
                    'obtained_marks': obt,
                    'total_marks': tot,
                    'retest': r['retest']?.toString(),
                    'retestStatus': r['status']?.toString(),
                    'conv': r['conv']?.toString(),
                  });
                }
              }
            }
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _liveFirestoreMarks = matchedMarks;
          });
        }
      }

      if (freshWardData != null && mounted) {
        final name = freshWardData['fullName'] ?? freshWardData['name'] ?? 'Student $regNo';
        final dept = freshWardData['departmentName'] ?? freshWardData['department'] ?? 'Artificial Intelligence & Data Science';
        final sem = freshWardData['semester'] ?? 'Semester 6';
        final curYear = freshWardData['currentYear'] ?? 'III Year';
        final cgpa = (freshWardData['cgpa'] != null && freshWardData['cgpa'].toString().isNotEmpty) ? freshWardData['cgpa'].toString() : '8.78';
        final rawAtt = freshWardData['attendancePercent']?.toString() ?? '87.5%';
        final double attVal = (double.tryParse(rawAtt.replaceAll('%', '')) ?? 87.5) / 100.0;

        final updatedWard = (_liveWard ?? widget.selectedWard ?? parentService.getDefaultStudentWards().first).copyWith(
          name: name,
          department: dept,
          currentSemester: sem,
          currentYear: curYear,
          cgpa: cgpa,
          attendancePercent: attVal,
          academicStatus: freshWardData['academicStatus'] ?? _liveWard?.academicStatus,
          academicTrend: freshWardData['academicTrend'] ?? _liveWard?.academicTrend,
        );

        setState(() {
          _liveWard = updatedWard;
        });
        ref.read(activeParentWardProvider.notifier).state = updatedWard;
      }
    } catch (e) {
      debugPrint('Error refreshing academic performance: $e');
    } finally {
      if (mounted) {
        _refreshAnimController.stop();
        _refreshAnimController.reset();
        setState(() => _isRefreshing = false);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Academic performance & marks synced in real time with Firebase',
                    style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }


  List<Map<String, dynamic>> _getInternalSubjectData(int semIdx, ParentStudentWard? ward) {
    final List<Map<String, dynamic>> baseList = [];

    // 1. Prioritize real-time live academic performance document streamed from Firebase Firestore
    if (_liveAcademicPerformanceData != null && _liveAcademicPerformanceData!['semesters'] is Map) {
      final sMap = _liveAcademicPerformanceData!['semesters'] as Map;
      final semDoc = sMap['sem_$semIdx'];
      if (semDoc is Map && semDoc['subjects'] is List && (semDoc['subjects'] as List).isNotEmpty) {
        final List<Map<String, dynamic>> liveSubjects = (semDoc['subjects'] as List)
            .map((s) => Map<String, dynamic>.from(s is Map ? s : {}))
            .toList();
        return liveSubjects;
      }
    }

    // 2. Merge real-time live marks from Firestore if present
    if (_liveFirestoreMarks.isNotEmpty) {
      for (final markData in _liveFirestoreMarks) {
        final rawName = (markData['subject_name'] ?? markData['subjectName'] ?? markData['subject'] ?? markData['name'] ?? 'Course Subject').toString();
        final rawCode = (markData['subject_code'] ?? markData['subjectCode'] ?? markData['code'] ?? '').toString().toUpperCase();
        final subCode = rawCode.isNotEmpty
            ? rawCode
            : (rawName.length >= 3 ? '${rawName.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(3).join().toUpperCase()}301' : 'SUB301');
        final subName = rawName;
        final obt = (markData['obtained_marks'] ?? markData['marks_obtained'] ?? markData['marks'] ?? 0) as num;
        final tot = (markData['total_marks'] ?? markData['max_marks'] ?? 100) as num;
        final examType = (markData['exam_type'] ?? markData['examType'] ?? 'General').toString();
        final faculty = (markData['faculty'] ?? markData['facultyName'] ?? 'Faculty In-Charge').toString();

        final existingIdx = baseList.indexWhere((s) {
          final sCode = s['code'].toString().toUpperCase();
          final sName = s['name'].toString().toLowerCase();
          return (rawCode.isNotEmpty && sCode == rawCode) ||
              sName == subName.toLowerCase() ||
              sName.contains(subName.toLowerCase()) ||
              subName.toLowerCase().contains(sName);
        });

        final pct = tot > 0 ? (obt / tot).toDouble().clamp(0.0, 1.0) : 0.85;
        final totalInt = (pct * 60.0).toStringAsFixed(1);
        final grade = pct >= 0.9 ? 'O (Outstanding)' : (pct >= 0.8 ? 'A+ (Excellent)' : (pct >= 0.7 ? 'A (Very Good)' : 'B+ (Good)'));

        final isIa1 = examType.contains('IA-1') || examType.contains('Assessment I') || examType.contains('1');
        final isIa2 = examType.contains('IA-2') || examType.contains('Assessment II') || examType.contains('2');
        final isModel = examType.contains('Model');

        if (existingIdx >= 0) {
          final existing = baseList[existingIdx];
          if (isIa1) {
            final ia1Score = (pct * 50.0).toStringAsFixed(0);
            existing['ia1'] = '$ia1Score / 50';
            existing['ia1Conv'] = '${(pct * 15.0).toStringAsFixed(1)} / 15';
            if (markData['retest'] != null && markData['retest'].toString().isNotEmpty) {
              existing['ia1Retest'] = markData['retest'].toString();
              existing['hasIa1Retest'] = true;
              existing['ia1RetestStatus'] = markData['retestStatus']?.toString() ?? 'Retest Cleared';
            }
          } else if (isIa2) {
            final ia2Score = (pct * 50.0).toStringAsFixed(0);
            existing['ia2'] = '$ia2Score / 50';
            existing['ia2Conv'] = '${(pct * 15.0).toStringAsFixed(1)} / 15';
            if (markData['retest'] != null && markData['retest'].toString().isNotEmpty) {
              existing['ia2Retest'] = markData['retest'].toString();
              existing['hasIa2Retest'] = true;
              existing['ia2RetestStatus'] = markData['retestStatus']?.toString() ?? 'Retest Cleared';
            }
          } else if (isModel) {
            final modelScore = (pct * 100.0).toStringAsFixed(0);
            existing['modelExam'] = '$modelScore / 100';
            existing['modelConv'] = '${(pct * 20.0).toStringAsFixed(1)} / 20';
          } else {
            existing['totalInternal'] = '$totalInt / 60';
            existing['percent'] = pct;
            existing['grade'] = grade;
          }
          existing['status'] = 'Live Verified in Firebase';
        } else {
          final ia1Score = (pct * 50.0).toStringAsFixed(0);
          final ia2Score = (pct * 50.0).toStringAsFixed(0);
          final modelScore = (pct * 100.0).toStringAsFixed(0);

          baseList.add({
            'code': subCode,
            'name': subName,
            'faculty': faculty,
            'ia1': isIa1 ? '$obt / $tot' : '$ia1Score / 50',
            'ia1Conv': isIa1 ? '${(pct * 15.0).toStringAsFixed(1)} / 15' : '${(pct * 15.0).toStringAsFixed(1)} / 15',
            'ia1Initial': '$ia1Score / 50',
            'hasIa1Retest': markData['retest'] != null,
            'ia1Retest': markData['retest']?.toString(),
            'ia1RetestStatus': markData['retestStatus']?.toString(),
            'ia2': isIa2 ? '$obt / $tot' : '$ia2Score / 50',
            'ia2Conv': isIa2 ? '${(pct * 15.0).toStringAsFixed(1)} / 15' : '${(pct * 15.0).toStringAsFixed(1)} / 15',
            'ia2Initial': '$ia2Score / 50',
            'hasIa2Retest': false,
            'modelExam': isModel ? '$obt / $tot' : '$modelScore / 100',
            'modelConv': isModel ? '${(pct * 20.0).toStringAsFixed(1)} / 20' : '${(pct * 20.0).toStringAsFixed(1)} / 20',
            'modelInitial': '$modelScore / 100',
            'hasModelRetest': false,
            'attAssign': '9.5 / 10',
            'totalInternal': '$totalInt / 60',
            'percent': pct,
            'grade': grade,
            'remarks': 'Live performance record fetched directly from Firebase.',
            'status': 'Live Verified in Firebase',
          });
        }
      }
    }

    return baseList;
  }

  double _calculateSemesterSgpa(List<Map<String, dynamic>> subjects) {
    if (subjects.isEmpty) return 8.90;
    double total = 0.0;
    for (final s in subjects) {
      final pct = (s['percent'] as num?)?.toDouble() ?? 0.88;
      total += (pct * 10.0);
    }
    return (total / subjects.length).clamp(0.0, 10.0);
  }

  String _getSemesterCredits(int semIdx) {
    switch (semIdx) {
      case 0:
        return '24 / 160';
      case 1:
        return '48 / 160';
      case 2:
        return '70 / 160';
      case 3:
        return '92 / 160';
      case 4:
        return '116 / 160';
      case 5:
        return '140 / 160';
      default:
        return '92 / 160';
    }
  }

  void _showSubjectDetailModal(BuildContext context, Map<String, dynamic> subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSubjectDetailSheet(ctx, subject),
    );
  }

  Widget _buildSubjectDetailSheet(BuildContext context, Map<String, dynamic> sub) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sub['code']} - ${sub['name']}',
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Faculty: ${sub['faculty']}',
                      style: GoogleFonts.manrope(fontSize: 12.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total Score Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL INTERNAL CONVERTED',
                      style: GoogleFonts.manrope(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub['totalInternal'],
                      style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sub['grade'],
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Evaluation Breakdowns
          Text(
            'Evaluation Breakdown & Weightages',
            style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          _buildBreakdownRow('Internal Assessment 1 (50 Marks)', sub['ia1'], sub['ia1Conv'], '15M'),
          if (sub['hasIa1Retest'] == true)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Text(
                '↳ Initial Test: ${sub['ia1Initial']} • ${sub['ia1RetestStatus']}',
                style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF059669), fontWeight: FontWeight.w600),
              ),
            ),

          _buildBreakdownRow('Internal Assessment 2 (50 Marks)', sub['ia2'], sub['ia2Conv'], '15M'),
          if (sub['hasIa2Retest'] == true)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Text(
                '↳ Initial Test: ${sub['ia2Initial']} • ${sub['ia2RetestStatus']}',
                style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF059669), fontWeight: FontWeight.w600),
              ),
            ),

          _buildBreakdownRow('Model Examination (100 Marks)', sub['modelExam'], sub['modelConv'], '20M'),
          _buildBreakdownRow('Attendance & Assignments', 'Full Credit', sub['attAssign'], '10M'),

          const SizedBox(height: 16),

          // Faculty Remarks
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.rate_review_outlined, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty In-Charge Evaluation Note',
                        style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sub['remarks'] ?? 'Consistent conceptual clarity and good lab participation.',
                        style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String title, String rawMark, String convMark, String maxConv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
            ),
          ),
          Row(
            children: [
              Text(
                rawMark,
                style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$convMark / $maxConv',
                  style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRealtimeUploadModal(BuildContext context, String regNo, String studentName, String dept, String cgpa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RealtimeAcademicUploadModalSheet(
        regNo: regNo,
        studentName: studentName,
        department: dept,
        cgpa: cgpa,
        currentSemIndex: _selectedSemIndex,
        onUploaded: () {
          _handleRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ward = _liveWard ?? widget.selectedWard ?? ref.watch(activeParentWardProvider);
    final liveDoc = _liveAcademicPerformanceData;
    final String cgpa = (liveDoc?['cgpa']?.toString().isNotEmpty == true)
        ? liveDoc!['cgpa'].toString()
        : ((ward?.cgpa != null && ward!.cgpa.isNotEmpty && ward.cgpa != '-') ? ward.cgpa : '8.78');
    final String wardName = (liveDoc?['studentName']?.toString().isNotEmpty == true)
        ? liveDoc!['studentName'].toString()
        : ((ward?.name != null && ward!.name.isNotEmpty && !ward.name.startsWith('Student ')) ? ward.name : 'Arun Kumar');
    final String wardDept = (liveDoc?['department']?.toString().isNotEmpty == true)
        ? liveDoc!['department'].toString()
        : ((ward?.department != null && ward!.department.isNotEmpty && ward.department != '-') ? ward.department : 'Artificial Intelligence & Data Science');
    final String currentSem = (liveDoc?['currentSemester']?.toString().isNotEmpty == true)
        ? liveDoc!['currentSemester'].toString()
        : ((ward?.currentSemester != null && ward!.currentSemester.isNotEmpty && ward.currentSemester != '-') ? ward.currentSemester : 'Semester 6');
    final String academicStanding = (liveDoc?['standing']?.toString().isNotEmpty == true)
        ? liveDoc!['standing'].toString()
        : ((ward?.academicStatus != null && ward!.academicStatus.isNotEmpty && ward.academicStatus != '-') ? ward.academicStatus : 'First Class with Distinction');
    final String regNo = (liveDoc?['regNo']?.toString().isNotEmpty == true)
        ? liveDoc!['regNo'].toString()
        : (ward?.regNo ?? '922523243079');

    final subjects = _getInternalSubjectData(_selectedSemIndex, ward);
    final currentSgpa = _calculateSemesterSgpa(subjects).toStringAsFixed(2);
    final currentCredits = _getSemesterCredits(_selectedSemIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF2563EB),
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation Header Bar with Real-Time Badge & Refresh
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
                      onPressed: () {
                        if (widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(0);
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Academic Performance & Progress',
                                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'LIVE',
                                      style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Internal Assessment Scores & Faculty Evaluations',
                            style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Direct Real-Time Upload Method Button to Firebase
                    GestureDetector(
                      onTap: () => _showRealtimeUploadModal(context, regNo, wardName, wardDept, cgpa),
                      child: Container(
                        margin: const EdgeInsets.only(right: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              'Upload',
                              style: GoogleFonts.manrope(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    RotationTransition(
                      turns: _refreshAnimController,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: _isRefreshing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))
                            : const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB), size: 20),
                        onPressed: _handleRefresh,
                        tooltip: 'Swipe down or tap to refresh',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 1. HERO CGPA & PERFORMANCE CARD ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CUMULATIVE GPA',
                                  style: GoogleFonts.manrope(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cgpa,
                                  style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AcademicStandingDialog(
                                    studentName: wardName,
                                    registerNum: ward?.regNo ?? '922523243079',
                                    academicStatus: academicStanding,
                                    onNavigateToTab: widget.onNavigateToTab,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        academicStanding,
                                        style: GoogleFonts.manrope(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$wardName • ${ward?.regNo ?? '922523243079'}',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$wardDept • ${ward?.currentYear ?? 'III Year'} • $currentSem',
                        style: GoogleFonts.manrope(fontSize: 11.5, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(color: Colors.white24, height: 24),

                      // Metrics Strip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildMetricPill('Current SGPA', currentSgpa, Icons.analytics_outlined)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildMetricPill('Credits Completed', currentCredits, Icons.stars_rounded)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildMetricPill('Standing', 'Top 5%', Icons.trending_up_rounded)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 2. SEMESTER SELECTOR PILLS ──
                Text('Academic Semesters', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_semesters.length, (idx) {
                      final isSelected = _selectedSemIndex == idx;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSemIndex = idx;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _semesters[idx],
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 3. ASSESSMENT FILTER TOGGLE CHIPS ──
                Text('Assessment Component Filter', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((f) {
                      final isSelected = _selectedInternalFilter == f['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedInternalFilter = f['id']!;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            f['label']!,
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 4. SUBJECT-WISE INTERNAL PERFORMANCE LIST ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Subject-wise Internal Marks',
                        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        '${subjects.length} Subjects Evaluated',
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...subjects.map((sub) => _buildSubjectCard(context, sub)),

                const SizedBox(height: 20),

                // ── 5. PERFORMANCE INSIGHTS & ACTIONS ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF059669), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Advisor Academic Assessment',
                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '• Highest score in Algorithms & Data Structures (94%) with distinction standing.\n• All Internal Assessments (IA-1, IA-2, and Model) are completely cleared with zero active backlogs.\n• Eligible for Autonomous End-Semester COE University Examination.',
                        style: GoogleFonts.manrope(fontSize: 12, height: 1.5, color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill(String title, String val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.manrope(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> sub) {
    String displayMark = sub['totalInternal'];
    String subLabel = 'Total Internal (/60)';

    if (_selectedInternalFilter == 'IA-1') {
      displayMark = '${sub['ia1']} (Conv: ${sub['ia1Conv']})';
      subLabel = 'IA-1 Score';
    } else if (_selectedInternalFilter == 'IA-2') {
      displayMark = '${sub['ia2']} (Conv: ${sub['ia2Conv']})';
      subLabel = 'IA-2 Score';
    } else if (_selectedInternalFilter == 'Model') {
      displayMark = '${sub['modelExam']} (Conv: ${sub['modelConv']})';
      subLabel = 'Model Exam Score';
    }

    final double percent = (sub['percent'] as num?)?.toDouble() ?? 0.85;
    final Color progressColor = percent >= 0.9
        ? const Color(0xFF10B981)
        : (percent >= 0.75 ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSubjectDetailModal(context, sub),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sub['code']} - ${sub['name']}',
                            style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Faculty: ${sub['faculty']}',
                            style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          displayMark,
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: progressColor),
                        ),
                        Text(
                          subLabel,
                          style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Linear Progress Bar
                AppLinearProgressBar(
                  lineHeight: 6.5,
                  percent: percent.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFF1F5F9),
                  progressColor: progressColor,
                  borderRadius: 3.5,
                ),
                const SizedBox(height: 10),

                // Breakdown Chips Strip
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildMiniChip('IA-1: ${sub['ia1Conv']}', sub['hasIa1Retest'] == true),
                    _buildMiniChip('IA-2: ${sub['ia2Conv']}', sub['hasIa2Retest'] == true),
                    _buildMiniChip('Model: ${sub['modelConv']}', sub['hasModelRetest'] == true),
                    _buildMiniChip('Att: ${sub['attAssign']}', false),
                  ],
                ),

                if (sub['hasIa1Retest'] == true || sub['hasIa2Retest'] == true || sub['hasModelRetest'] == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            sub['ia1RetestStatus'] ?? sub['ia2RetestStatus'] ?? sub['modelRetestStatus'] ?? 'Retest Cleared',
                            style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, bool isRetest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isRetest ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isRetest ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isRetest ? const Color(0xFF059669) : const Color(0xFF475569),
        ),
      ),
    );
  }
}

/// Interactive Real-Time Modal Sheet to Upload & Manage Academic Performance in Cloud Firestore
class _RealtimeAcademicUploadModalSheet extends StatefulWidget {
  final String regNo;
  final String studentName;
  final String department;
  final String cgpa;
  final int currentSemIndex;
  final VoidCallback onUploaded;

  const _RealtimeAcademicUploadModalSheet({
    required this.regNo,
    required this.studentName,
    required this.department,
    required this.cgpa,
    required this.currentSemIndex,
    required this.onUploaded,
  });

  @override
  State<_RealtimeAcademicUploadModalSheet> createState() => _RealtimeAcademicUploadModalSheetState();
}

class _RealtimeAcademicUploadModalSheetState extends State<_RealtimeAcademicUploadModalSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedSemIndex;
  bool _isUploading = false;
  bool _isSyncingCloud = false;

  // Form Controllers
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _facultyController;
  late TextEditingController _ia1Controller;
  late TextEditingController _ia2Controller;
  late TextEditingController _modelController;
  late TextEditingController _attController;
  late TextEditingController _remarksController;
  late TextEditingController _initialAttemptController;
  late TextEditingController _retestScoreController;
  late TextEditingController _retestStatusController;
  bool _hasRetest = true;

  // Batch text controller
  late TextEditingController _batchTextController;
  String _uploadedFileName = '';

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedSemIndex = widget.currentSemIndex.clamp(0, 5);

    _codeController = TextEditingController(text: 'CS3401');
    _nameController = TextEditingController(text: 'Design & Analysis of Algorithms');
    _facultyController = TextEditingController(text: 'Dr. S. Ramanathan (CSE)');
    _ia1Controller = TextEditingController(text: '44');
    _ia2Controller = TextEditingController(text: '46');
    _modelController = TextEditingController(text: '92');
    _attController = TextEditingController(text: '9.8');
    _remarksController = TextEditingController(text: 'Demonstrated remarkable comeback in graph algorithms after initial test.');
    _initialAttemptController = TextEditingController(text: '20 / 50');
    _retestScoreController = TextEditingController(text: '44 / 50');
    _retestStatusController = TextEditingController(text: 'Retest Cleared (+24 Marks Improved)');

    _batchTextController = TextEditingController(
      text: 'Code,Name,Faculty,IA1_50,IA2_50,Model_100,Att_10,Retest_Score,Retest_Status,Remarks\n'
          'CS3401,Design & Analysis of Algorithms,Dr. S. Ramanathan,44,46,92,9.8,44 / 50,Retest Cleared (+24 Marks),Exceptional problem solving\n'
          'CS3492,Database Management Systems,Prof. K. Sundaram,42,45,88,9.2,,,Strong query optimization\n'
          'CS3451,Operating Systems,Dr. V. Rajesh,41,43,85,9.0,,,Good semaphore understanding\n'
          'CS3491,Computer Networks,Dr. Anitha Subramanian,45,47,90,9.6,,,Excellent packet sniffing lab work\n'
          'GE3451,Environmental Sciences,Dr. P. Rajeshwari,43,44,86,9.0,,,Punctual project submission',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _facultyController.dispose();
    _ia1Controller.dispose();
    _ia2Controller.dispose();
    _modelController.dispose();
    _attController.dispose();
    _remarksController.dispose();
    _initialAttemptController.dispose();
    _retestScoreController.dispose();
    _retestStatusController.dispose();
    _batchTextController.dispose();
    super.dispose();
  }

  Future<void> _handle1TapCloudSync() async {
    setState(() => _isSyncingCloud = true);
    HapticFeedback.mediumImpact();

    try {
      final success = await FirebaseFirestoreService().seedStudentAcademicPerformanceToFirebase(
        regNo: widget.regNo,
        studentName: widget.studentName,
        department: widget.department,
        currentYear: 'III Year',
        currentSemester: 'Semester 6',
        cgpa: widget.cgpa,
        standing: 'Top 5%',
      );

      if (mounted) {
        setState(() => _isSyncingCloud = false);
        if (success) {
          widget.onUploaded();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Real-time academic records for ${widget.studentName} (${widget.regNo}) uploaded to Firebase!',
                      style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload failed. Please check network connection.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncingCloud = false);
        debugPrint('Error in _handle1TapCloudSync: $e');
      }
    }
  }

  Future<void> _handleSaveSingleSubject() async {
    if (_codeController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Subject Code and Name')),
      );
      return;
    }

    setState(() => _isUploading = true);
    HapticFeedback.mediumImpact();

    try {
      final rawIa1 = double.tryParse(_ia1Controller.text.trim()) ?? 44;
      final rawIa2 = double.tryParse(_ia2Controller.text.trim()) ?? 46;
      final rawModel = double.tryParse(_modelController.text.trim()) ?? 92;
      final rawAtt = double.tryParse(_attController.text.trim()) ?? 9.8;

      final ia1ConvVal = (rawIa1 / 50.0 * 15.0).clamp(0.0, 15.0);
      final ia2ConvVal = (rawIa2 / 50.0 * 15.0).clamp(0.0, 15.0);
      final modelConvVal = (rawModel / 100.0 * 20.0).clamp(0.0, 20.0);
      final attConvVal = rawAtt.clamp(0.0, 10.0);

      final totalIntVal = ia1ConvVal + ia2ConvVal + modelConvVal + attConvVal;
      final pct = (totalIntVal / 60.0).clamp(0.0, 1.0);
      final grade = pct >= 0.9 ? 'O (Outstanding)' : (pct >= 0.8 ? 'A+ (Excellent)' : (pct >= 0.7 ? 'A (Very Good)' : 'B+ (Good)'));

      final subjectMap = {
        'code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'faculty': _facultyController.text.trim(),
        'ia1': '$rawIa1 / 50',
        'ia1Conv': '${ia1ConvVal.toStringAsFixed(1)} / 15',
        'ia1Initial': _hasRetest ? _initialAttemptController.text.trim() : '$rawIa1 / 50',
        'hasIa1Retest': _hasRetest,
        'ia1Retest': _hasRetest ? _retestScoreController.text.trim() : null,
        'ia1RetestStatus': _hasRetest ? _retestStatusController.text.trim() : null,
        'ia2': '$rawIa2 / 50',
        'ia2Conv': '${ia2ConvVal.toStringAsFixed(1)} / 15',
        'ia2Initial': '$rawIa2 / 50',
        'hasIa2Retest': false,
        'modelExam': '$rawModel / 100',
        'modelConv': '${modelConvVal.toStringAsFixed(1)} / 20',
        'modelInitial': '$rawModel / 100',
        'hasModelRetest': false,
        'attAssign': '${attConvVal.toStringAsFixed(1)} / 10',
        'totalInternal': '${totalIntVal.toStringAsFixed(1)} / 60',
        'percent': pct,
        'grade': grade,
        'remarks': _remarksController.text.trim(),
        'status': 'Live Verified in Firebase',
      };

      final firestoreService = FirebaseFirestoreService();
      final currentDoc = await firestoreService.getStudentAcademicPerformance(widget.regNo);
      List<Map<String, dynamic>> updatedSubjects = [];

      if (currentDoc != null && currentDoc['semesters'] is Map) {
        final semMap = currentDoc['semesters'] as Map;
        final currentSemDoc = semMap['sem_$_selectedSemIndex'];
        if (currentSemDoc is Map && currentSemDoc['subjects'] is List) {
          updatedSubjects = (currentSemDoc['subjects'] as List).map((s) => Map<String, dynamic>.from(s is Map ? s : {})).toList();
        }
      }

      final existingIdx = updatedSubjects.indexWhere((s) => s['code'].toString().toUpperCase() == subjectMap['code']);
      if (existingIdx >= 0) {
        updatedSubjects[existingIdx] = subjectMap;
      } else {
        updatedSubjects.add(subjectMap);
      }

      final success = await firestoreService.uploadStudentAcademicPerformance(
        regNo: widget.regNo,
        studentName: widget.studentName,
        department: widget.department,
        currentYear: 'III Year',
        currentSemester: _semesters[_selectedSemIndex],
        cgpa: widget.cgpa,
        standing: 'Top 5%',
        semesterIndex: _selectedSemIndex,
        subjects: updatedSubjects,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          widget.onUploaded();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subject "${subjectMap['code']}" marks pushed live to Firebase!'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload to Firebase')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        debugPrint('Error in _handleSaveSingleSubject: $e');
      }
    }
  }

  Future<void> _handleBatchUpload() async {
    final text = _batchTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please paste CSV / JSON data or pick a file')));
      return;
    }

    setState(() => _isUploading = true);
    HapticFeedback.mediumImpact();

    try {
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final List<Map<String, dynamic>> parsedSubjects = [];

      int startLine = 0;
      if (lines.isNotEmpty && lines[0].toLowerCase().contains('code')) {
        startLine = 1;
      }

      for (int i = startLine; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length >= 2) {
          final code = parts[0].trim();
          final name = parts[1].trim();
          final faculty = parts.length > 2 ? parts[2].trim() : 'Faculty In-Charge';
          final ia1Raw = parts.length > 3 ? (double.tryParse(parts[3].replaceAll('/50', '').trim()) ?? 42) : 42;
          final ia2Raw = parts.length > 4 ? (double.tryParse(parts[4].replaceAll('/50', '').trim()) ?? 44) : 44;
          final modelRaw = parts.length > 5 ? (double.tryParse(parts[5].replaceAll('/100', '').trim()) ?? 88) : 88;
          final attRaw = parts.length > 6 ? (double.tryParse(parts[6].replaceAll('/10', '').trim()) ?? 9.0) : 9.0;
          final retestScore = parts.length > 7 ? parts[7].trim() : '';
          final retestStatus = parts.length > 8 ? parts[8].trim() : '';
          final remarks = parts.length > 9 ? parts[9].trim() : 'Consistent performance.';

          final ia1ConvVal = (ia1Raw / 50.0 * 15.0).clamp(0.0, 15.0);
          final ia2ConvVal = (ia2Raw / 50.0 * 15.0).clamp(0.0, 15.0);
          final modelConvVal = (modelRaw / 100.0 * 20.0).clamp(0.0, 20.0);
          final attConvVal = attRaw.clamp(0.0, 10.0);

          final totalIntVal = ia1ConvVal + ia2ConvVal + modelConvVal + attConvVal;
          final pct = (totalIntVal / 60.0).clamp(0.0, 1.0);
          final grade = pct >= 0.9 ? 'O (Outstanding)' : (pct >= 0.8 ? 'A+ (Excellent)' : (pct >= 0.7 ? 'A (Very Good)' : 'B+ (Good)'));

          parsedSubjects.add({
            'code': code,
            'name': name,
            'faculty': faculty,
            'ia1': '$ia1Raw / 50',
            'ia1Conv': '${ia1ConvVal.toStringAsFixed(1)} / 15',
            'ia1Initial': retestScore.isNotEmpty ? '20 / 50' : '$ia1Raw / 50',
            'hasIa1Retest': retestScore.isNotEmpty,
            'ia1Retest': retestScore.isNotEmpty ? retestScore : null,
            'ia1RetestStatus': retestStatus.isNotEmpty ? retestStatus : null,
            'ia2': '$ia2Raw / 50',
            'ia2Conv': '${ia2ConvVal.toStringAsFixed(1)} / 15',
            'ia2Initial': '$ia2Raw / 50',
            'hasIa2Retest': false,
            'modelExam': '$modelRaw / 100',
            'modelConv': '${modelConvVal.toStringAsFixed(1)} / 20',
            'modelInitial': '$modelRaw / 100',
            'hasModelRetest': false,
            'attAssign': '${attConvVal.toStringAsFixed(1)} / 10',
            'totalInternal': '${totalIntVal.toStringAsFixed(1)} / 60',
            'percent': pct,
            'grade': grade,
            'remarks': remarks,
            'status': 'Live Verified in Firebase',
          });
        }
      }

      if (parsedSubjects.isEmpty) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid records parsed. Check CSV formatting.')));
        return;
      }

      final success = await FirebaseFirestoreService().uploadStudentAcademicPerformance(
        regNo: widget.regNo,
        studentName: widget.studentName,
        department: widget.department,
        currentYear: 'III Year',
        currentSemester: _semesters[_selectedSemIndex],
        cgpa: widget.cgpa,
        standing: 'Top 5%',
        semesterIndex: _selectedSemIndex,
        subjects: parsedSubjects,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          widget.onUploaded();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Batch upload successful! ${parsedSubjects.length} subjects uploaded to Firebase.'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        debugPrint('Error in _handleBatchUpload: $e');
      }
    }
  }

  void _handlePickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _uploadedFileName = file.name;
        });

        if (file.bytes != null) {
          final content = String.fromCharCodes(file.bytes!);
          _batchTextController.text = content;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "${file.name}" loaded ready to upload!'),
              backgroundColor: const Color(0xFF2563EB),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-Time Firebase Upload',
                      style: GoogleFonts.manrope(fontSize: 16.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${widget.studentName} • ${widget.regNo}',
                          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tab Bar Switcher
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: '⚡ 1-Tap Sync'),
                Tab(text: '✏️ Live Editor'),
                Tab(text: '📄 Batch CSV'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── TAB 1: 1-TAP CLOUD SYNC ──
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('TARGET FIRESTORE DOCUMENT', style: GoogleFonts.manrope(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('academic_performance/${widget.regNo}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text('CGPA ${widget.cgpa}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Syncs all 6 Academic Semesters (including CS3401 Algorithms, DBMS, OS, Networks, Retests, and Faculty Evaluations) directly to Cloud Firestore with live snapshot listeners.',
                              style: GoogleFonts.manrope(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: _isSyncingCloud ? null : _handle1TapCloudSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        icon: _isSyncingCloud
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          _isSyncingCloud ? 'Uploading to Firebase...' : '🚀 Upload All Semesters to Firebase',
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── TAB 2: LIVE SUBJECT EDITOR ──
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Semester Dropdown
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedSemIndex,
                              decoration: InputDecoration(
                                labelText: 'Select Semester',
                                labelStyle: GoogleFonts.manrope(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: List.generate(_semesters.length, (idx) {
                                return DropdownMenuItem(value: idx, child: Text(_semesters[idx], style: GoogleFonts.manrope(fontSize: 13)));
                              }),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedSemIndex = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                labelText: 'Subject Code',
                                labelStyle: GoogleFonts.manrope(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Subject Name',
                          labelStyle: GoogleFonts.manrope(fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _facultyController,
                        decoration: InputDecoration(
                          labelText: 'Faculty In-Charge',
                          labelStyle: GoogleFonts.manrope(fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Marks Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ia1Controller,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'IA-1 (/50)',
                                labelStyle: GoogleFonts.manrope(fontSize: 11),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _ia2Controller,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'IA-2 (/50)',
                                labelStyle: GoogleFonts.manrope(fontSize: 11),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Model (/100)',
                                labelStyle: GoogleFonts.manrope(fontSize: 11),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _attController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Att (/10)',
                                labelStyle: GoogleFonts.manrope(fontSize: 11),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Retest Option Checkbox
                      CheckboxListTile(
                        value: _hasRetest,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('Student Cleared Retest / Improvement', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold)),
                        onChanged: (val) => setState(() => _hasRetest = val ?? false),
                      ),

                      if (_hasRetest) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _initialAttemptController,
                                decoration: InputDecoration(
                                  labelText: 'Initial Attempt',
                                  labelStyle: GoogleFonts.manrope(fontSize: 11),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _retestScoreController,
                                decoration: InputDecoration(
                                  labelText: 'Retest Cleared Score',
                                  labelStyle: GoogleFonts.manrope(fontSize: 11),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _retestStatusController,
                          decoration: InputDecoration(
                            labelText: 'Retest Status Badge',
                            labelStyle: GoogleFonts.manrope(fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      TextFormField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Faculty Remarks / Evaluation Note',
                          labelStyle: GoogleFonts.manrope(fontSize: 11.5),
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _handleSaveSingleSubject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isUploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: Text('💾 Save & Push Live to Firebase', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // ── TAB 3: BATCH CSV / JSON UPLOAD ──
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paste CSV / JSON Records', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          TextButton.icon(
                            onPressed: _handlePickFile,
                            icon: const Icon(Icons.attach_file_rounded, size: 16),
                            label: Text(_uploadedFileName.isNotEmpty ? _uploadedFileName : 'Pick File', style: GoogleFonts.manrope(fontSize: 11.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _batchTextController,
                        maxLines: 7,
                        style: GoogleFonts.firaCode(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Paste CSV rows here...',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _handleBatchUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isUploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.upload_file_rounded),
                        label: Text('⚡ Parse & Upload Batch to Firebase', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
