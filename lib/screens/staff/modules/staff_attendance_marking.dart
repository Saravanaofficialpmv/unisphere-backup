import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/attendance_system_provider.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class StaffAttendanceMarkingModule extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final String? initialSection;
  final String? initialSubject;
  final String? initialTimeSlot;

  const StaffAttendanceMarkingModule({
    super.key,
    this.onBack,
    this.initialSection,
    this.initialSubject,
    this.initialTimeSlot,
  });

  @override
  ConsumerState<StaffAttendanceMarkingModule> createState() =>
      _StaffAttendanceMarkingModuleState();
}

class _StaffAttendanceMarkingModuleState
    extends ConsumerState<StaffAttendanceMarkingModule> {
  late String _selectedSection;
  late String _selectedSubject;
  late String _selectedSlot;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _rosterSectionKey = GlobalKey();

  final List<String> _availableSections = [
    'CS-A',
    'CS-B',
    'CS-C',
    'III CSE - A',
    'III CSE - B',
    'IV CSE - A',
    'IV CSE - B',
  ];

  final List<String> _availableSubjects = [
    'CS301 - Computer Networks',
    'CS302 - Database Systems',
    'CS303 - Web Technology',
    'CS304 - Software Engineering',
    'CS305 - AI & Machine Learning',
  ];

  final List<String> _availableSlots = [
    '09:00 - 10:00 AM',
    '10:15 - 11:15 AM',
    '11:30 AM - 12:30 PM',
    '01:30 - 02:30 PM',
    '02:30 - 03:30 PM',
  ];

  final List<Map<String, dynamic>> _studentsList = [
    {'id': '917722104001', 'name': 'Aarav Sharma', 'isPresent': true},
    {'id': '917722104002', 'name': 'Aditi Rao', 'isPresent': true},
    {'id': '917722104003', 'name': 'Bhavya Nair', 'isPresent': true},
    {'id': '917722104018', 'name': 'Deepak Kumar', 'isPresent': false},
    {'id': '917722104022', 'name': 'Karthik Raja', 'isPresent': true},
    {'id': '917722104030', 'name': 'Meera Patel', 'isPresent': true},
    {'id': '917722104045', 'name': 'Rohan Gupta', 'isPresent': true},
    {'id': '917722104052', 'name': 'Sanjay V.', 'isPresent': false},
    {'id': '917722104060', 'name': 'Tanvi Iyer', 'isPresent': true},
    {'id': '917722104068', 'name': 'Vikram Singh', 'isPresent': true},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection ?? 'CS-A';
    _selectedSubject = widget.initialSubject ?? 'CS301 - Computer Networks';
    _selectedSlot = widget.initialTimeSlot ?? '09:00 - 10:00 AM';

    if (!_availableSections.contains(_selectedSection)) {
      _availableSections.insert(0, _selectedSection);
    }
    if (!_availableSubjects.contains(_selectedSubject)) {
      _availableSubjects.insert(0, _selectedSubject);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _markAll(bool present) {
    setState(() {
      for (final s in _studentsList) {
        s['isPresent'] = present;
      }
    });
  }

  void _selectSessionForMarking(Map<String, dynamic> session) {
    final sec = session['className']?.toString() ?? 'CS-A';
    final subj = session['subjectName']?.toString() ?? 'CS301 - Computer Networks';
    final start = session['startTime']?.toString() ?? '09:00 AM';
    final end = session['endTime']?.toString() ?? '10:00 AM';
    final slot = '$start - $end';

    setState(() {
      if (!_availableSections.contains(sec)) {
        _availableSections.insert(0, sec);
      }
      _selectedSection = sec;

      final matchingSubj = _availableSubjects.firstWhere(
        (s) => s.toLowerCase().contains(subj.toLowerCase()),
        orElse: () => _availableSubjects.first,
      );
      _selectedSubject = matchingSubj;

      if (!_availableSlots.contains(slot)) {
        _availableSlots.insert(0, slot);
      }
      _selectedSlot = slot;
    });

    // Smooth scroll down to marking roster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rosterSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _rosterSectionKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _submitAttendance() {
    final code = _selectedSubject.split(' - ')[0];
    final name = _selectedSubject.contains(' - ')
        ? _selectedSubject.split(' - ')[1]
        : _selectedSubject;

    ref.read(attendanceSystemProvider.notifier).submitStaffSessionAttendance(
          subjectCode: code,
          subjectName: name,
          facultyName: 'Staff Faculty Member',
          timeSlot: _selectedSlot,
          studentResults: _studentsList,
        );

    final presentCount =
        _studentsList.where((s) => s['isPresent'] == true).length;
    final total = _studentsList.length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance submitted! ($presentCount / $total Present) for $_selectedSection',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final presentCount =
        _studentsList.where((s) => s['isPresent'] == true).length;
    final absentCount = _studentsList.length - presentCount;
    final attendanceMetric = ref.watch(staffMonthlyAttendanceMetricProvider);
    final todayScheduleAsync = ref.watch(staffTodayScheduleStreamProvider);
    final sessions = todayScheduleAsync.valueOrNull ?? [];

    final authUser = ref.watch(currentUserProvider).valueOrNull ??
        ref.watch(authServiceProvider).currentUser;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final staff = profileAsync.valueOrNull;

    final String staffName = (staff?.fullName != null &&
            staff!.fullName.trim().isNotEmpty)
        ? staff.fullName
        : ((authUser?.fullName != null && authUser!.fullName.trim().isNotEmpty)
            ? authUser.fullName
            : 'Faculty Member');

    final String staffDept = (staff?.departmentName != null &&
            staff!.departmentName.trim().isNotEmpty)
        ? staff.departmentName
        : (authUser?.metadata?['department']?.toString() ??
            'Computer Science & Engineering');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.onBack != null
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Color(0xFF0F172A)),
                onPressed: widget.onBack,
              ),
              title: Text(
                'Staff Attendance Management',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      size: 20, color: Color(0xFF64748B)),
                  onPressed: () {
                    ref.invalidate(attendanceSystemProvider);
                    ref.invalidate(staffTodayScheduleStreamProvider);
                  },
                  tooltip: 'Refresh Attendance Data',
                ),
              ],
            )
          : null,
      body: AppLiquidPullToRefresh(
        gifAsset: 'assets/tibsy-dp.gif',
        onRefresh: () async {
          ref.invalidate(attendanceSystemProvider);
          ref.invalidate(staffTodayScheduleStreamProvider);
          ref.invalidate(staffSubjectsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 1000));
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Header Banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF064E3B), // Emerald 900
                          Color(0xFF047857), // Emerald 700
                          Color(0xFF059669), // Emerald 600
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.25)),
                              ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        size: 13, color: Colors.white),
                                    const SizedBox(width: 5),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 180),
                                      child: Text(
                                        'Faculty Attendance Control',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ),
                            Text(
                              DateFormat('MMM d, yyyy').format(DateTime.now()),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD1FAE5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          staffName,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$staffDept • Active Semester Sessions',
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFA7F3D0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── 1. Attendance Summary Row (Single Source of Truth) ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceSummaryCard(
                          title: "Today's Attendance",
                          value: sessions.isNotEmpty
                              ? '${((sessions.where((s) => s['isAttendanceTaken'] == true).length / sessions.length) * 100).round()}%'
                              : '92%',
                          subtitle: '${sessions.length} Sessions Scheduled',
                          icon: Icons.today_rounded,
                          color: const Color(0xFF2563EB),
                          progress: sessions.isNotEmpty
                              ? (sessions.where((s) => s['isAttendanceTaken'] == true).length / sessions.length)
                              : 0.92,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAttendanceSummaryCard(
                          title: "This Week's Attendance",
                          value: '90%',
                          subtitle: '18 Total Sessions',
                          icon: Icons.date_range_rounded,
                          color: const Color(0xFFF59E0B),
                          progress: 0.90,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAttendanceSummaryCard(
                          title: "This Month's Attendance",
                          value: attendanceMetric.formattedPercentage,
                          subtitle: 'Overall Teaching Rate',
                          icon: Icons.donut_large_rounded,
                          color: const Color(0xFF10B981),
                          progress: attendanceMetric.progress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── 2. Classes Requiring Attendance (Today's Schedule) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'CLASSES REQUIRING ATTENDANCE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sessions.length} Today',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (sessions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: Color(0xFF10B981), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All scheduled classes have their attendance submitted for today.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final session = sessions[idx];
                        final bool isMarked =
                            session['isAttendanceTaken'] == true;
                        final String sec =
                            session['className']?.toString() ?? 'CS-A';
                        final String subj = session['subjectName']?.toString() ??
                            'Course Subject';
                        final String time =
                            '${session['startTime'] ?? '09:00 AM'} - ${session['endTime'] ?? '10:00 AM'}';
                        final String room =
                            session['room']?.toString() ?? 'Lecture Hall';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isMarked
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFFDE68A),
                            ),
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
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMarked
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isMarked
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_actions_rounded,
                                  color: isMarked
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subj,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$sec • $time • $room',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () =>
                                    _selectSessionForMarking(session),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMarked
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFF059669),
                                  foregroundColor: isMarked
                                      ? const Color(0xFF334155)
                                      : Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                child: Text(isMarked
                                    ? 'View Attendance'
                                    : 'Take Attendance'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 28),

                  // ── 3. Interactive Attendance Session Marking Tool ──
                  Container(
                    key: _rosterSectionKey,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SESSION ATTENDANCE ROSTER',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Section',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _availableSections.contains(_selectedSection)
                                            ? _selectedSection
                                            : _availableSections.first,
                                        items: _availableSections
                                            .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s,
                                                    style: GoogleFonts.manrope(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold))))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedSection = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time Slot',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _availableSlots.contains(_selectedSlot)
                                            ? _selectedSlot
                                            : _availableSlots.first,
                                        items: _availableSlots
                                            .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s,
                                                    style: GoogleFonts.manrope(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold))))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedSlot = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Subject',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _availableSubjects.contains(_selectedSubject)
                                  ? _selectedSubject
                                  : _availableSubjects.first,
                              items: _availableSubjects
                                  .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s,
                                          style: GoogleFonts.manrope(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold))))
                              .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSubject = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── 4. Roster Counter & Presets ──
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              'Present: $presentCount',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              'Absent: $absentCount',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () => _markAll(true),
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                size: 16),
                            label: Text(
                              'All Present',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _markAll(false),
                            icon: const Icon(Icons.highlight_off_rounded,
                                size: 16, color: AppColors.error),
                            label: Text(
                              'All Absent',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 5. Student List Roster ──
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _studentsList.length,
                    itemBuilder: (context, index) {
                      final student = _studentsList[index];
                      final bool isPresent = student['isPresent'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPresent
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isPresent
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFFEE2E2),
                                  child: Text(
                                    student['name'][0],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPresent
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'],
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      'Reg: ${student['id']}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: isPresent,
                              activeThumbColor: const Color(0xFF059669),
                              onChanged: (val) {
                                setState(() {
                                  student['isPresent'] = val;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── 6. Submit Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submitAttendance,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        'Submit Session Attendance',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 9.5,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
