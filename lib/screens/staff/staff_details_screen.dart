import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/staff_details_model.dart';
import 'package:unisphere/models/staff_task_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/staff_service.dart';
import 'package:unisphere/services/supabase_service.dart';
import 'package:unisphere/services/academic_schedule_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/providers/gallery_provider.dart';
import 'package:unisphere/providers/attendance_system_provider.dart';
import 'package:unisphere/providers/academic_schedule_provider.dart';
import 'package:unisphere/controllers/question_paper_controller.dart';
import 'package:unisphere/controllers/hackathon_registration_controller.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class StaffDetailsScreen extends ConsumerStatefulWidget {
  final StaffDetailsModel? staffMember;
  final VoidCallback? onBack;
  final Function(int)? onNavigateToTab;

  const StaffDetailsScreen({
    super.key,
    this.staffMember,
    this.onBack,
    this.onNavigateToTab,
  });

  @override
  ConsumerState<StaffDetailsScreen> createState() => _StaffDetailsScreenState();
}

class _StaffDetailsScreenState extends ConsumerState<StaffDetailsScreen> {
  late StaffDetailsModel _staff;
  bool _isRefreshing = false;
  int _refreshEpoch = 0;
  DateTime? _lastRefreshedAt;
  int _activeNavTab =
      0; // 0: Overview, 1: Profile, 2: Courses, 3: Tasks, 4: Attendance, 5: Documents

  // State lists for Tasks & Submissions
  List<StaffTaskModel> _tasks = StaffTaskModel.defaultTasks;
  List<StudentTaskSubmission> _submissions =
      StudentTaskSubmission.defaultSubmissions;

  // Search and Filters
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  // Student Attendance State
  String _selectedAttendanceSection = 'CSE - Sec A';
  String _selectedAttendanceSubject = 'CS8691 - Machine Learning';
  String _selectedAttendanceSlot = 'Period 2 (10:00 AM - 11:00 AM)';

  final List<Map<String, dynamic>> _attendanceStudentList = [
    {'id': '20CS3012', 'name': 'Saran Kumar', 'isPresent': true, 'overall': 94},
    {'id': '20CS3025', 'name': 'Nandhini R', 'isPresent': true, 'overall': 98},
    {'id': '20CS3058', 'name': 'Vignesh S', 'isPresent': false, 'overall': 68},
    {
      'id': '20CS3004',
      'name': 'Aarav Sharma',
      'isPresent': true,
      'overall': 92,
    },
    {'id': '20CS3019', 'name': 'Bhavya Nair', 'isPresent': true, 'overall': 88},
    {
      'id': '20CS3032',
      'name': 'Karthik Raja',
      'isPresent': true,
      'overall': 85,
    },
    {'id': '20CS3041', 'name': 'Meera Patel', 'isPresent': true, 'overall': 90},
    {
      'id': '20CS3050',
      'name': 'Rohan Gupta',
      'isPresent': false,
      'overall': 72,
    },
    {'id': '20CS3064', 'name': 'Sanjay V.', 'isPresent': true, 'overall': 95},
    {
      'id': '20CS3077',
      'name': 'Vikram Singh',
      'isPresent': true,
      'overall': 91,
    },
  ];

  @override
  void initState() {
    super.initState();
    _staff = widget.staffMember ?? StaffDetailsModel.defaultTharaniKumar;
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    try {
      final currentUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
      final uid = currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        final staffDoc = await ref.read(staffServiceProvider).getStaffByUid(uid);
        if (mounted && staffDoc != null) {
          setState(() {
            _staff = _staff.copyWith(
              id: staffDoc.employeeId.isNotEmpty ? staffDoc.employeeId : _staff.id,
              name: staffDoc.fullName.isNotEmpty ? staffDoc.fullName : _staff.name,
              designation: staffDoc.designation.isNotEmpty ? staffDoc.designation : _staff.designation,
              department: staffDoc.departmentName.isNotEmpty ? staffDoc.departmentName : _staff.department,
              qualification: staffDoc.qualification ?? _staff.qualification,
              specialization: staffDoc.specialization.isNotEmpty ? staffDoc.specialization : _staff.specialization,
              experience: staffDoc.experienceYears > 0 ? '${staffDoc.experienceYears} Years' : _staff.experience,
              photoUrl: (staffDoc.photoPath != null && staffDoc.photoPath!.isNotEmpty) ? staffDoc.photoPath! : (currentUser?.profileImageUrl ?? _staff.photoUrl),
              email: (currentUser?.email != null && currentUser!.email.isNotEmpty) ? currentUser.email : _staff.email,
              phone: (currentUser?.phoneNumber != null && currentUser!.phoneNumber!.isNotEmpty) ? currentUser.phoneNumber! : _staff.phone,
            );
          });
        } else if (mounted && currentUser != null) {
          setState(() {
            _staff = _staff.copyWith(
              name: currentUser.name.isNotEmpty ? currentUser.name : _staff.name,
              email: currentUser.email.isNotEmpty ? currentUser.email : _staff.email,
              phone: (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) ? currentUser.phoneNumber! : _staff.phone,
              photoUrl: (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) ? currentUser.profileImageUrl! : _staff.photoUrl,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('StaffDetailsScreen _loadStaffData error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final startTime = DateTime.now();

      // Invalidate all core app and staff-specific Riverpod providers
      ref.invalidate(currentUserProvider);
      ref.invalidate(staffServiceProvider);
      ref.invalidate(allTimetablesStreamProvider);
      ref.invalidate(notificationProvider);
      ref.invalidate(announcementsStreamProvider);
      ref.invalidate(assignmentsStreamProvider);
      ref.invalidate(hodVerificationsStreamProvider);
      ref.invalidate(questionPaperControllerProvider);
      ref.invalidate(hackathonRegistrationProvider);
      ref.invalidate(recentPublishedAlbumsProvider);
      ref.invalidate(allPublishedAlbumsProvider);
      ref.invalidate(academicScheduleServiceProvider);
      ref.invalidate(userAcademicScheduleProvider);
      ref.invalidate(attendanceSystemProvider);
      ref.invalidate(allStudentsStreamProvider);

      // Reload staff live data from Firestore / Supabase / Auth
      await _loadStaffData();

      if (mounted) {
        setState(() {
          _refreshEpoch++;
          _lastRefreshedAt = DateTime.now();
        });
      }

      // Ensure full animation cycle completes for smooth, delightful visual timing
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 1200) {
        await Future.delayed(Duration(milliseconds: 1200 - elapsed));
      }
    } catch (e) {
      debugPrint('Staff realtime refresh error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AppLiquidPullToRefresh(
        onRefresh: _refreshData,
        gifAsset: 'assets/tibsy-dp.gif',
        child: _buildMainContent(isMobile),
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return SingleChildScrollView(
      key: ValueKey('staff_details_scroll_$_refreshEpoch'),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_activeNavTab == 0) ...[
                // 1. Staff Header Profile Card
                _buildStaffProfileCard(isMobile),
                const SizedBox(height: 16),

                // 2. Metric Counter Cards
                _buildMetricCounterCards(isMobile),
                const SizedBox(height: 16),

                // 4. Quick Actions
                _buildQuickActions(isMobile),
                const SizedBox(height: 16),

                // 4. Today's Schedule
                _buildTodaysSchedule(isMobile),
                const SizedBox(height: 16),

                // 5. Today's Highlights
                _buildTodaysHighlights(isMobile),
              ] else ...[
                // Back to Overview Dashboard header bar
                InkWell(
                  onTap: () => setState(() => _activeNavTab = 0),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Back to Overview Dashboard',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sub-module content router
                if (_activeNavTab == 1) ...[
                  _buildPersonalAndProfessionalCard(isMobile),
                ] else if (_activeNavTab == 3) ...[
                  _buildTasksModuleContent(isMobile),
                ] else if (_activeNavTab == 2) ...[
                  _buildCoursesTabContent(isMobile),
                ] else if (_activeNavTab == 4) ...[
                  _buildAttendanceTabContent(isMobile),
                ] else ...[
                  _buildDocumentsTabContent(isMobile),
                ],
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. REDESIGNED STAFF PROFILE CARD ────────────────────────────────────
  Widget _buildStaffProfileCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 32 : 36,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage: NetworkImage(_staff.photoUrl),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _staff.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          _staff.designation,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final staffAsync = ref.watch(currentStaffProfileStreamProvider);
                            final currentUser = ref.watch(currentUserProvider).value;
                            final isAdvisor = staffAsync.value?.isAdvisor ?? (currentUser?.role == UserRole.advisor);
                            final section = staffAsync.value?.advisorSection;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isAdvisor ? const Color(0xFFF5F3FF) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isAdvisor ? const Color(0xFFDDD6FE) : const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isAdvisor
                                    ? (section != null && section.isNotEmpty ? '🎓 Advisor ($section)' : '🎓 Class Advisor')
                                    : '👨‍🏫 Faculty',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isAdvisor ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          size: 14,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _staff.department,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() => _activeNavTab = 1);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: Color(0xFF6366F1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFA7F3D0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _lastRefreshedAt != null
                              ? 'Synced ${DateTime.now().difference(_lastRefreshedAt!).inMinutes == 0 ? 'just now' : '${DateTime.now().difference(_lastRefreshedAt!).inMinutes}m ago'}'
                              : 'Live Synced',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileMetaItem(
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFF2563EB),
                label: 'Staff ID',
                value: 'STF1024',
                imagePath: 'assets/images/profile_meta/staff_id.jpg',
              ),
              _buildProfileMetaItem(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF7C3AED),
                label: 'Email',
                value: 'thani.kumar\n@vsb.edu.in',
                imagePath: 'assets/images/profile_meta/email.jpg',
              ),
              _buildProfileMetaItem(
                icon: Icons.phone_outlined,
                iconColor: const Color(0xFF16A34A),
                label: 'Phone',
                value: '+91 98765\n43210',
                imagePath: 'assets/images/profile_meta/phone.jpg',
              ),
              _buildProfileMetaItem(
                icon: Icons.calendar_month_outlined,
                iconColor: const Color(0xFFEA580C),
                label: 'Join Date',
                value: '12 Aug 2022',
                imagePath: 'assets/images/profile_meta/join_date.jpg',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMetaItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? imagePath,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(icon, size: 20, color: iconColor);
                      },
                    ),
                  )
                : Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2.5. METRIC COUNTER CARDS ───────────────────────────────────────────
  Widget _buildMetricCounterCards(bool isMobile) {
    final metrics = [
      {
        'title': 'Assigned Classes',
        'value': '4 Classes',
        'subtitle': '180 Students Enrolled',
        'icon': Icons.school_rounded,
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
      },
      {
        'title': 'Pending Grading',
        'value': '12 Papers',
        'subtitle': 'Coursework evaluation',
        'icon': Icons.pending_actions_rounded,
        'iconBg': const Color(0xFFFFFBEB),
        'iconColor': const Color(0xFFD97706),
      },
      {
        'title': 'Low Attendance',
        'value': '3 Students',
        'subtitle': '< 75% threshold alert',
        'icon': Icons.warning_amber_rounded,
        'iconBg': const Color(0xFFFEF2F2),
        'iconColor': const Color(0xFFDC2626),
      },
      {
        'title': 'Active Notices',
        'value': '5 Published',
        'subtitle': 'Department circulars',
        'icon': Icons.campaign_rounded,
        'iconBg': const Color(0xFFF5F3FF),
        'iconColor': const Color(0xFF7C3AED),
      },
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCardItem(metrics[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCardItem(metrics[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCardItem(metrics[2])),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCardItem(metrics[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: metrics
          .map((m) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: _buildMetricCardItem(m),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMetricCardItem(Map<String, dynamic> metric) {
    final iconColor = metric['iconColor'] as Color;
    final iconBg = metric['iconBg'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(metric['icon'] as IconData, size: 18, color: iconColor),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric['value'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            metric['title'] as String,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            metric['subtitle'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. QUICK ACTIONS GRID ──────────────────────────────────────────────
  Widget _buildQuickActions(bool isMobile) {
    final staffAsync = ref.watch(currentStaffProfileStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isAdvisor = staffAsync.value?.isAdvisor ?? (currentUser?.role == UserRole.advisor);

    final List<Map<String, dynamic>> allActions = [
      {
        'label': 'Take Attendance',
        'icon': Icons.how_to_reg_rounded,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'borderColor': const Color(0xFFBFDBFE),
        'sidebarIndex': 12,
        'tab': 4,
        'requiresAdvisor': false,
      },
      {
        'label': 'Give Assignment',
        'icon': Icons.add_task_rounded,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
        'borderColor': const Color(0xFFDDD6FE),
        'sidebarIndex': 1,
        'tab': 3,
        'requiresAdvisor': false,
      },
      {
        'label': 'Review Work',
        'icon': Icons.checklist_rounded,
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFF0FDF4),
        'borderColor': const Color(0xFFBBF7D0),
        'sidebarIndex': 2,
        'tab': 3,
        'requiresAdvisor': false,
      },
      {
        'label': 'Upload Marks',
        'icon': Icons.upload_file_rounded,
        'color': const Color(0xFFEA580C),
        'bg': const Color(0xFFFFF7ED),
        'borderColor': const Color(0xFFFED7AA),
        'sidebarIndex': 9,
        'tab': 3,
        'requiresAdvisor': false,
      },
      {
        'label': 'Student Directory',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFF0F9FF),
        'borderColor': const Color(0xFFBAE6FD),
        'sidebarIndex': 3,
        'tab': 2,
        'requiresAdvisor': true,
      },
      {
        'label': 'Resume Bank',
        'icon': Icons.description_rounded,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
        'borderColor': const Color(0xFFFDE68A),
        'sidebarIndex': 4,
        'tab': 3,
        'requiresAdvisor': true,
      },
      {
        'label': 'Announcements',
        'icon': Icons.campaign_rounded,
        'color': const Color(0xFFE11D48),
        'bg': const Color(0xFFFEF2F2),
        'borderColor': const Color(0xFFFECDD3),
        'sidebarIndex': 15,
        'tab': 5,
        'requiresAdvisor': false,
      },
      {
        'label': 'Library Access',
        'icon': Icons.local_library_rounded,
        'color': const Color(0xFF4F46E5),
        'bg': const Color(0xFFEEF2FF),
        'borderColor': const Color(0xFFC7D2FE),
        'sidebarIndex': 16,
        'tab': 5,
        'requiresAdvisor': false,
      },
    ];

    final actions = allActions.where((a) => a['requiresAdvisor'] == false || isAdvisor).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions Hub',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(1);
                } else {
                  setState(() => _activeNavTab = 2);
                }
              },
              child: const Text(
                'View All Features',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = actions[index];
              final color = item['color'] as Color;
              final bg = item['bg'] as Color;
              final borderColor = item['borderColor'] as Color;

              return InkWell(
                onTap: () {
                  final sidebarIdx = item['sidebarIndex'] as int?;
                  if (sidebarIdx != null && widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(sidebarIdx);
                  } else {
                    setState(() => _activeNavTab = item['tab'] as int);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 98,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 4. TODAY'S SCHEDULE ─────────────────────────────────────────────────
  Widget _buildTodaysSchedule(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Schedule",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() => _activeNavTab = 2);
              },
              child: const Row(
                children: [
                  Text(
                    'View Timetable',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '09:00\nAM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Structures',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'III Year CSE - A Section',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 5. TODAY'S HIGHLIGHTS ───────────────────────────────────────────────
  Widget _buildTodaysHighlights(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Highlights",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildHighlightStatCard(
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF9333EA),
              bgColor: const Color(0xFFF3E8FF),
              count: '2',
              label: 'Classes Today',
            ),
            const SizedBox(width: 10),
            _buildHighlightStatCard(
              icon: Icons.assignment_rounded,
              iconColor: const Color(0xFF16A34A),
              bgColor: const Color(0xFFDCFCE7),
              count: '1',
              label: 'Pending Task',
            ),
            const SizedBox(width: 10),
            _buildHighlightStatCard(
              icon: Icons.notifications_rounded,
              iconColor: const Color(0xFFEA580C),
              bgColor: const Color(0xFFFFEDD5),
              count: '3',
              label: 'New Notices',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String count,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
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
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 12,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ── 3. TASKS MODULE CONTENT ──────────────────────────────────────────────
  Widget _buildTasksModuleContent(bool isMobile) {
    // Filter tasks
    final filteredTasks = _tasks.where((t) {
      if (_selectedStatusFilter != 'All' && t.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return t.title.toLowerCase().contains(q) ||
            t.subject.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module Title
        const Text(
          'Tasks Assigned to Students',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        // 4 Summary Overview Cards
        _buildTaskOverviewSummaryCards(isMobile),
        const SizedBox(height: 16),

        // Search & Filter Bar
        _buildSearchAndFiltersBar(isMobile),
        const SizedBox(height: 16),

        // Active Tasks Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Tasks',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedStatusFilter = 'Active'),
              child: const Text(
                'View All Tasks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Active Task Cards List
        if (filteredTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.assignment_outlined,
                  size: 36,
                  color: Color(0xFFCBD5E1),
                ),
                SizedBox(height: 8),
                Text(
                  'No tasks match selected filter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) =>
                _buildTaskCard(filteredTasks[idx], isMobile),
          ),
        const SizedBox(height: 16),

        // + Assign New Task Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAssignTaskModal(context),
            icon: const Icon(
              Icons.add_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            label: const Text(
              '+ Assign New Task',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Quick Actions Row
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        _buildQuickActionsHorizontalRow(isMobile),
        const SizedBox(height: 20),

        // Recent Submissions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Submissions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => _showSubmissionsListModal(context),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildRecentSubmissionsList(isMobile),
      ],
    );
  }

  // ── TASK OVERVIEW SUMMARY CARDS ──────────────────────────────────────────
  Widget _buildTaskOverviewSummaryCards(bool isMobile) {
    final total = _tasks.length + 15; // 18 total
    final active =
        _tasks.where((t) => t.status == 'Active').length + 4; // 6 active
    final completed = 9;
    final overdue = 3;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            '$total',
            'Total Tasks',
            Icons.assignment_rounded,
            const Color(0xFF2563EB),
            const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            '$active',
            'Active',
            Icons.play_circle_fill_rounded,
            const Color(0xFF16A34A),
            const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            '$completed',
            'Completed',
            Icons.check_circle_rounded,
            const Color(0xFF9333EA),
            const Color(0xFFF3E8FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            '$overdue',
            'Overdue',
            Icons.access_time_filled_rounded,
            const Color(0xFFDC2626),
            const Color(0xFFFEF2F2),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String count,
    String label,
    IconData icon,
    Color color,
    Color bgIconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgIconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH AND FILTERS BAR ───────────────────────────────────────────────
  Widget _buildSearchAndFiltersBar(bool isMobile) {
    final filters = [
      'All',
      'Active',
      'Completed',
      'Overdue',
      'Pending',
      'Submitted',
      'Graded',
    ];

    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search by task name, student, or reg no...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final filter = filters[i];
              final isSel = _selectedStatusFilter == filter;

              return ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSel,
                onSelected: (val) =>
                    setState(() => _selectedStatusFilter = filter),
                selectedColor: const Color(0xFF2563EB),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : const Color(0xFF475569),
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSel
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── TASK CARD ────────────────────────────────────────────────────────────
  Widget _buildTaskCard(StaffTaskModel task, bool isMobile) {
    final isPending = task.status == 'Pending';
    final badgeBg = isPending
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFDCFCE7);
    final badgeColor = isPending
        ? const Color(0xFFB45309)
        : const Color(0xFF15803D);

    return InkWell(
      onTap: () => _showTaskDetailsModal(context, task),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.description_rounded,
                color: isPending
                    ? const Color(0xFFF97316)
                    : const Color(0xFF2563EB),
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
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.status,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Subject: ${task.subject}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Assigned: ${task.assignedDate}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            size: 12,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${task.dueDate}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${task.studentsAssigned} Students',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.submissions} Submitted',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── QUICK ACTIONS HORIZONTAL ROW ─────────────────────────────────────────
  Widget _buildQuickActionsHorizontalRow(bool isMobile) {
    final actions = [
      {
        'icon': Icons.groups_rounded,
        'label': 'View\nStudents',
        'color': const Color(0xFF2563EB),
        'action': () => _showStudentListModal(context),
      },
      {
        'icon': Icons.description_outlined,
        'label': 'Check\nSubmissions',
        'color': const Color(0xFF16A34A),
        'action': () => _showSubmissionsListModal(context),
      },
      {
        'icon': Icons.star_rounded,
        'label': 'Grade\nSubmissions',
        'color': const Color(0xFF9333EA),
        'action': () => _showGradingSheetModal(context, _submissions.first),
      },
      {
        'icon': Icons.edit_calendar_rounded,
        'label': 'Extend\nDeadline',
        'color': const Color(0xFFEA580C),
        'action': () => _showExtendDeadlineModal(context),
      },
      {
        'icon': Icons.check_circle_outline_rounded,
        'label': 'Mark\nComplete',
        'color': const Color(0xFF0D9488),
        'action': () => _handleMarkCompleteAction(),
      },
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final act = actions[i];
          final color = act['color'] as Color;

          return InkWell(
            onTap: act['action'] as VoidCallback,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 88,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      act['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    act['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                      height: 1.1,
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

  void _handleMarkCompleteAction() {
    setState(() {
      _tasks = _tasks
          .map((t) => t.id == "TASK-1024" ? t.copyWith(status: "Completed") : t)
          .toList();
    });
    _showToast(
      context,
      'Task "Machine Learning Mini Project" marked as Completed!',
    );
  }

  // ── RECENT SUBMISSIONS LIST ──────────────────────────────────────────────
  Widget _buildRecentSubmissionsList(bool isMobile) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _submissions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final sub = _submissions[idx];
        final isSub = sub.status == 'Submitted' || sub.status == 'Graded';
        final badgeBg = isSub
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEF3C7);
        final badgeColor = isSub
            ? const Color(0xFF15803D)
            : const Color(0xFFB45309);

        return InkWell(
          onTap: () => _showGradeSubmissionModal(context, sub),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(sub.photoUrl),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            sub.studentName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sub.registerNo,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub.submittedAt != '-'
                            ? sub.submittedAt!
                            : 'Pending submission',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sub.status,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  sub.marks != null ? '${sub.marks}/${sub.maxMarks}' : '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: sub.marks != null
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── MODAL 1: ASSIGN NEW TASK FORM ────────────────────────────────────────
  void _showAssignTaskModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController(text: 'Machine Learning');
    final descCtrl = TextEditingController();
    final dueDateCtrl = TextEditingController(text: '28 Aug 2026');
    final marksCtrl = TextEditingController(text: '20');
    final instructionsCtrl = TextEditingController();
    String taskType = 'Assignment';
    String priority = 'High';
    String assignTarget = 'Entire Class';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_task_rounded, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text(
                          'Assign New Task to Students',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Task Title *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: subjectCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Subject *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Task Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: taskType,
                                decoration: const InputDecoration(
                                  labelText: 'Task Type',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    [
                                          'Assignment',
                                          'Mini Project',
                                          'Lab Task',
                                          'Case Study',
                                        ]
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(
                                              t,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) =>
                                    setModalState(() => taskType = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: priority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority',
                                  border: OutlineInputBorder(),
                                ),
                                items: ['High', 'Medium', 'Low']
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          p,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setModalState(() => priority = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: assignTarget,
                          decoration: const InputDecoration(
                            labelText: 'Assign To *',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              [
                                    'Entire Class',
                                    'Section A',
                                    'Section B',
                                    'Selected Students',
                                  ]
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,
                                      child: Text(
                                        a,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              setModalState(() => assignTarget = v!),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: dueDateCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Due Date',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: marksCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Marks',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: instructionsCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Instructions & Guidelines',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty ||
                            subjectCtrl.text.trim().isEmpty) {
                          _showToast(
                            context,
                            'Please fill in required fields (Title & Subject)',
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        final newTask = StaffTaskModel(
                          id: "TASK-102${_tasks.length + 7}",
                          title: titleCtrl.text.trim(),
                          subject: subjectCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty
                              ? "Class assignment task"
                              : descCtrl.text.trim(),
                          assignedBy: _staff.id,
                          assignedDate: "Today",
                          dueDate: dueDateCtrl.text.trim(),
                          year: "III Year",
                          department: _staff.department,
                          section: "A",
                          studentsAssigned: 40,
                          submissions: 0,
                          pending: 40,
                          maxMarks: int.tryParse(marksCtrl.text) ?? 20,
                          priority: priority,
                          status: "Active",
                          taskType: taskType,
                          instructions: instructionsCtrl.text.trim(),
                        );
                        setState(() {
                          _tasks.insert(0, newTask);
                        });
                        _showToast(
                          context,
                          'Task "${newTask.title}" assigned successfully!',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Assign Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── MODAL 2: TASK DETAILS & STUDENT-LEVEL TRACKING ──────────────────────
  void _showTaskDetailsModal(BuildContext context, StaffTaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.90,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task ID: ${task.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Information Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject: ${task.subject}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Assigned: ${task.assignedDate}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                'Due: ${task.dueDate}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              Text(
                                'Max Marks: ${task.maxMarks}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submission Summary Progress Bar
                    const Text(
                      'Student Submission Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: task.submissionRate / 100,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: const Color(0xFF16A34A),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSubmissionStatTile(
                          '${task.studentsAssigned}',
                          'Assigned',
                          const Color(0xFF2563EB),
                        ),
                        _buildSubmissionStatTile(
                          '${task.submissions}',
                          'Submitted',
                          const Color(0xFF16A34A),
                        ),
                        _buildSubmissionStatTile(
                          '${task.pending}',
                          'Pending',
                          const Color(0xFFF97316),
                        ),
                        _buildSubmissionStatTile(
                          '${(task.submissionRate).toStringAsFixed(0)}%',
                          'Rate',
                          const Color(0xFF9333EA),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Student-Level Tracking List
                    const Text(
                      'Student Submissions List',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _submissions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final sub = _submissions[i];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showGradeSubmissionModal(context, sub);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(sub.photoUrl),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.studentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      Text(
                                        sub.registerNo,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sub.status == 'Submitted'
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sub.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: sub.status == 'Submitted'
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  sub.marks != null
                                      ? '${sub.marks}/${sub.maxMarks}'
                                      : '-',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStatTile(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ── MODAL 3: GRADE SUBMISSION ────────────────────────────────────────────
  void _showGradeSubmissionModal(
    BuildContext context,
    StudentTaskSubmission sub,
  ) {
    final marksCtrl = TextEditingController(
      text: sub.marks != null ? sub.marks.toString() : '',
    );
    final feedbackCtrl = TextEditingController(text: sub.feedback ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFF9333EA)),
            const SizedBox(width: 8),
            Text(
              'Grade Submission: ${sub.studentName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Register No: ${sub.registerNo}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            if (sub.fileUrl != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sub.fileUrl!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: marksCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Marks Obtained (Max ${sub.maxMarks})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: feedbackCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Faculty Feedback & Remarks',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newMarks = int.tryParse(marksCtrl.text);
              Navigator.pop(ctx);
              setState(() {
                _submissions = _submissions.map((s) {
                  if (s.studentId == sub.studentId) {
                    return s.copyWith(
                      status: 'Graded',
                      marks: newMarks,
                      feedback: feedbackCtrl.text.trim(),
                    );
                  }
                  return s;
                }).toList();
              });
              _showToast(
                context,
                'Grade saved successfully for ${sub.studentName}!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
            ),
            child: const Text(
              'Save Grade',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK ACTIONS HELPERS ────────────────────────────────────────────────
  void _showStudentListModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned Students List (42 Students)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _submissions.length,
                itemBuilder: (ctx, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(_submissions[i].photoUrl),
                  ),
                  title: Text(_submissions[i].studentName),
                  subtitle: Text(_submissions[i].registerNo),
                  trailing: Text(
                    _submissions[i].status,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmissionsListModal(BuildContext context) {
    _showToast(context, 'Showing all 28 submitted student files...');
  }

  void _showGradingSheetModal(BuildContext context, StudentTaskSubmission sub) {
    _showGradeSubmissionModal(context, sub);
  }

  void _showExtendDeadlineModal(BuildContext context) {
    final dateCtrl = TextEditingController(text: '05 Sep 2026');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Extend Task Deadline'),
        content: TextField(
          controller: dateCtrl,
          decoration: const InputDecoration(labelText: 'New Due Date'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _tasks = _tasks
                    .map(
                      (t) => t.id == "TASK-1024"
                          ? t.copyWith(dueDate: dateCtrl.text)
                          : t,
                    )
                    .toList();
              });
              _showToast(
                context,
                'Task deadline extended to ${dateCtrl.text}!',
              );
            },
            child: const Text('Extend Deadline'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTabContent(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'Handled Courses & Subjects',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCourseShowcaseCard(
            'CS8691',
            'Machine Learning',
            'III Year / VI Sem',
            'Section A',
            '42 Students',
            'Lab 302',
            const Color(0xFF2563EB),
          ),
          const SizedBox(height: 10),
          _buildCourseShowcaseCard(
            'CS8079',
            'Python Programming',
            'III Year / VI Sem',
            'Section B',
            '38 Students',
            'Room 204',
            const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _buildCourseShowcaseCard(
            'CS8791',
            'Data Analytics',
            'III Year / VI Sem',
            'Section A',
            '35 Students',
            'Lab 105',
            const Color(0xFF9333EA),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseShowcaseCard(
    String code,
    String name,
    String sem,
    String sec,
    String count,
    String room,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ($code)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sem • $sec • $room',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTabContent(bool isMobile) {
    final presentCount = _attendanceStudentList
        .where((s) => s['isPresent'] == true)
        .length;
    final absentCount = _attendanceStudentList.length - presentCount;
    final percent = _attendanceStudentList.isEmpty
        ? 0
        : ((presentCount / _attendanceStudentList.length) * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Mark Class Attendance Main Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.how_to_reg_rounded,
                          color: Color(0xFFEA580C),
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Mark Attendance',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _markAllStudentsAttendance(true),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 13,
                                color: Color(0xFF16A34A),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'All Present',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _markAllStudentsAttendance(false),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.cancel_outlined,
                                size: 13,
                                color: Color(0xFFDC2626),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'All Absent',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
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
              const SizedBox(height: 12),

              // Session Selectors Row
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAttendanceSection,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Section',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: ['CSE - Sec A', 'CSE - Sec B', 'IT - Sec A']
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedAttendanceSection = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAttendanceSubject,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items:
                              [
                                    'CS8691 - Machine Learning',
                                    'CS8079 - Python Programming',
                                    'CS8791 - Data Analytics',
                                  ]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11.5),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedAttendanceSubject = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAttendanceSlot,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Time Slot / Period',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                              'Period 1 (09:00 AM - 10:00 AM)',
                              'Period 2 (10:00 AM - 11:00 AM)',
                              'Period 3 (11:15 AM - 12:15 PM)',
                              'Period 4 (01:30 PM - 02:30 PM)',
                            ]
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedAttendanceSlot = v!),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Attendance Counter Stats Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceCountStat(
                      '${_attendanceStudentList.length}',
                      'Total',
                      const Color(0xFF475569),
                    ),
                    _buildAttendanceCountStat(
                      '$presentCount',
                      'Present',
                      const Color(0xFF16A34A),
                    ),
                    _buildAttendanceCountStat(
                      '$absentCount',
                      'Absent',
                      const Color(0xFFDC2626),
                    ),
                    _buildAttendanceCountStat(
                      '$percent%',
                      'Present Rate',
                      const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Student Interactive Attendance List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attendanceStudentList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final s = _attendanceStudentList[idx];
                  final isPresent = s['isPresent'] == true;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPresent
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isPresent
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          child: Text(
                            s['name'].toString().substring(0, 1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isPresent
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Reg No: ${s['id']} • Overall: ${s['overall']}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              s['isPresent'] = !isPresent;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPresent
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPresent
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPresent ? 'PRESENT' : 'ABSENT',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Submit Class Attendance Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitClassAttendance,
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Submit Class Attendance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Faculty Monthly Log Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Faculty Monthly Attendance Log',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceStatTile(
                      '96%',
                      'Present Rate',
                      const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAttendanceStatTile(
                      '24',
                      'Working Days',
                      const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAttendanceStatTile(
                      '23',
                      'Present Days',
                      const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAttendanceStatTile(
                      '1',
                      'Casual Leave',
                      const Color(0xFFDC2626),
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

  void _markAllStudentsAttendance(bool isPresent) {
    setState(() {
      for (final s in _attendanceStudentList) {
        s['isPresent'] = isPresent;
      }
    });
  }

  void _submitClassAttendance() {
    final presentCount = _attendanceStudentList
        .where((s) => s['isPresent'] == true)
        .length;
    final total = _attendanceStudentList.length;
    _showToast(
      context,
      'Attendance for $_selectedAttendanceSection submitted! ($presentCount / $total Present)',
    );
  }

  Widget _buildAttendanceCountStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatTile(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTabContent(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: Color(0xFF0D9488),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Verified Faculty Documents',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDocumentShowcaseTile(
            'Ph.D. Degree Certificate',
            'Anna University • Verified PDF',
            '2.4 MB',
            '12 Jul 2020',
          ),
          const SizedBox(height: 10),
          _buildDocumentShowcaseTile(
            'Faculty Appointment Order',
            'VSB Engineering College • Official Order PDF',
            '1.1 MB',
            '12 Jul 2020',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentShowcaseTile(
    String title,
    String subtitle,
    String size,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFF0D9488),
              size: 20,
            ),
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
                const SizedBox(height: 2),
                Text(
                  '$subtitle • $size',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
            onPressed: () => _showToast(context, 'Downloading $title...'),
          ),
        ],
      ),
    );
  }

  // ── PERSONAL & PROFESSIONAL INFO CARD ────────────────────────────────────
  Widget _buildPersonalAndProfessionalCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPersonalInfoSection(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                ),
                _buildProfessionalInfoSection(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPersonalInfoSection()),
                Container(
                  width: 1,
                  height: 320,
                  color: const Color(0xFFF1F5F9),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
                Expanded(child: _buildProfessionalInfoSection()),
              ],
            ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildInfoRow('Full Name', _staff.name),
        _buildInfoRow('Date of Birth', _staff.dob),
        _buildInfoRow('Gender', _staff.gender),
        _buildInfoRow('Mobile Number', _staff.phone),
        _buildInfoRow('Email Address', _staff.email, isLink: true),
        _buildInfoRow('Address', _staff.address),
        _buildInfoRow('Blood Group', _staff.bloodGroup),
        _buildInfoRow('Emergency Contact', _staff.emergencyContact),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.business_center_rounded,
              color: Color(0xFF2563EB),
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Professional Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildInfoRow('Employee ID', _staff.id),
        _buildInfoRow('Designation', _staff.designation),
        _buildInfoRow('Department', _staff.department),
        _buildInfoRow('Qualification', _staff.qualification),
        _buildInfoRow('Specialization', _staff.specialization),
        _buildInfoRow('Date of Joining', _staff.joiningDate),
        _buildInfoRow('Total Experience', _staff.experience),
        _buildInfoRow('Employment Type', _staff.employmentType),
        _buildInfoRow('Staff Category', _staff.staffCategory),
        _buildInfoRow('Current Status', _staff.status),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isLink
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.1, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.75, size.height * 1.1, size.width, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

