import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

enum TeachingSessionStatus { liveNow, upcoming, completed }

class StaffTodayScheduleScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final Function(StaffNavKey)? onNavigateToKey;
  final Function(String section)? onViewClassStudents;

  const StaffTodayScheduleScreen({
    super.key,
    this.onBack,
    this.onNavigateToKey,
    this.onViewClassStudents,
  });

  @override
  ConsumerState<StaffTodayScheduleScreen> createState() => _StaffTodayScheduleScreenState();
}

class _StaffTodayScheduleScreenState extends ConsumerState<StaffTodayScheduleScreen> {
  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/staff');
    }
  }

  TeachingSessionStatus _calculateSessionStatus(Map<String, dynamic> session) {
    if (session['isAttendanceTaken'] == true) {
      return TeachingSessionStatus.completed;
    }

    final startTimeStr = session['startTime']?.toString() ?? '';
    final endTimeStr = session['endTime']?.toString() ?? '';

    try {
      final now = DateTime.now();
      final timeFormat = DateFormat('hh:mm a');

      if (startTimeStr.isNotEmpty && endTimeStr.isNotEmpty) {
        final parsedStart = timeFormat.parse(startTimeStr.trim());
        final parsedEnd = timeFormat.parse(endTimeStr.trim());

        final start = DateTime(now.year, now.month, now.day, parsedStart.hour, parsedStart.minute);
        final end = DateTime(now.year, now.month, now.day, parsedEnd.hour, parsedEnd.minute);

        if (now.isAfter(start) && now.isBefore(end)) {
          return TeachingSessionStatus.liveNow;
        } else if (now.isAfter(end)) {
          return TeachingSessionStatus.completed;
        }
      }
    } catch (_) {
      // Fallback if parsing fails
    }

    return TeachingSessionStatus.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(staffTodayScheduleStreamProvider);
    final isAdvisor = ref.watch(isClassAdvisorProvider);
    final authUser = ref.watch(currentUserProvider).valueOrNull ?? ref.watch(authServiceProvider).currentUser;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final staff = profileAsync.valueOrNull;

    final String staffName = (staff?.fullName != null && staff!.fullName.trim().isNotEmpty)
        ? staff.fullName
        : ((authUser?.fullName != null && authUser!.fullName.trim().isNotEmpty)
            ? authUser.fullName
            : 'Faculty Member');

    final String staffDept = (staff?.departmentName != null && staff!.departmentName.trim().isNotEmpty)
        ? staff.departmentName
        : (authUser?.metadata?['department']?.toString() ?? 'Computer Science & Engineering');

    final now = DateTime.now();
    final dateFormatted = DateFormat('EEEE, MMMM d, yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: _handleBack,
        ),
        title: Text(
          "Today's Teaching Schedule",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
            onPressed: () => ref.invalidate(staffTodayScheduleStreamProvider),
            tooltip: 'Refresh Schedule',
          ),
        ],
      ),
      body: scheduleAsync.when(
        loading: () => Center(child: Loader.page()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load today\'s schedule',
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please check your network and try again.',
                  style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(staffTodayScheduleStreamProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.staffRole,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (sessions) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Summary Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F172A), // Slate 900
                            Color(0xFF1E3A8A), // Blue 900
                            Color(0xFF2563EB), // Blue 600
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                                    const SizedBox(width: 5),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 190),
                                      child: Text(
                                        dateFormatted,
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '${sessions.length} Sessions',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF6EE7B7),
                                  ),
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
                            staffDept,
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFBFDBFE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Session Section Label ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'TODAY\'S TEACHING SESSIONS',
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
                          '${sessions.length} Scheduled',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Empty State ──
                    if (sessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.event_available_rounded, size: 40, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Classes Today',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You have no teaching lectures or lab sessions scheduled for today.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: () {
                                if (widget.onNavigateToKey != null) {
                                  widget.onNavigateToKey!(StaffNavKey.timetable);
                                }
                              },
                              icon: const Icon(Icons.calendar_month_outlined, size: 16),
                              label: const Text('View Full Timetable'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Builder(
                        builder: (context) {
                          final sortedSessions = [...sessions]..sort((a, b) {
                              final aStart = a['startTime']?.toString() ?? '';
                              final bStart = b['startTime']?.toString() ?? '';
                              return aStart.compareTo(bStart);
                            });

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedSessions.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final session = sortedSessions[index];
                              final status = _calculateSessionStatus(session);
                              return _buildSessionCard(context, session, status, isAdvisor, staffDept);
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                    // ── View Full Weekly Timetable Card Action ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Academic & Timetable Schedule',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'View complete department semester timetable',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (widget.onNavigateToKey != null) {
                                widget.onNavigateToKey!(StaffNavKey.timetable);
                              }
                            },
                            child: Text(
                              'View All',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSessionCard(
    BuildContext context,
    Map<String, dynamic> session,
    TeachingSessionStatus status,
    bool isAdvisor,
    String defaultDept,
  ) {
    final String subjectName = session['subjectName']?.toString() ?? 'Course Session';
    final String subjectCode = session['subjectCode']?.toString() ?? 'CS';
    final String className = session['className']?.toString() ?? 'Class Section';
    final String startTime = session['startTime']?.toString() ?? '09:00 AM';
    final String endTime = session['endTime']?.toString() ?? '10:00 AM';
    final String room = session['room']?.toString() ?? 'Lecture Hall';
    final String department = session['department']?.toString() ?? defaultDept;
    final bool isAttendanceTaken = session['isAttendanceTaken'] == true;

    Color badgeBg;
    Color badgeText;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case TeachingSessionStatus.liveNow:
        badgeBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        badgeText = const Color(0xFF059669);
        statusLabel = 'Live Now';
        statusIcon = Icons.sensors_rounded;
        break;
      case TeachingSessionStatus.completed:
        badgeBg = const Color(0xFF64748B).withValues(alpha: 0.12);
        badgeText = const Color(0xFF475569);
        statusLabel = isAttendanceTaken ? 'Completed • Attendance Marked' : 'Completed';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case TeachingSessionStatus.upcoming:
        badgeBg = const Color(0xFF2563EB).withValues(alpha: 0.1);
        badgeText = const Color(0xFF2563EB);
        statusLabel = 'Upcoming';
        statusIcon = Icons.schedule_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == TeachingSessionStatus.liveNow
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: status == TeachingSessionStatus.liveNow ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: status == TeachingSessionStatus.liveNow
                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Time & Status Badge ──
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '$startTime – $endTime',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  constraints: const BoxConstraints(maxWidth: 115),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: badgeText),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: badgeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Subject Title & Code ──
            Text(
              subjectCode.isNotEmpty ? '$subjectName ($subjectCode)' : subjectName,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),

            // ── Meta Details: Room, Section, Department ──
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMetaChip(Icons.meeting_room_outlined, room),
                _buildMetaChip(Icons.groups_outlined, className),
                if (department.isNotEmpty) _buildMetaChip(Icons.domain_rounded, department),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // ── Actions Row: Take Attendance + View Class Students ──
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigateToKey != null) {
                      widget.onNavigateToKey!(StaffNavKey.attendance);
                    }
                  },
                  icon: Icon(
                    isAttendanceTaken ? Icons.edit_note_rounded : Icons.how_to_reg_rounded,
                    size: 16,
                  ),
                  label: Text(isAttendanceTaken ? 'Update Attendance' : 'Take Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAttendanceTaken ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB),
                    foregroundColor: isAttendanceTaken ? const Color(0xFF334155) : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (widget.onViewClassStudents != null) {
                      widget.onViewClassStudents!(className);
                    } else if (widget.onNavigateToKey != null) {
                      widget.onNavigateToKey!(
                        isAdvisor ? StaffNavKey.advisorDirectory : StaffNavKey.studentDirectory,
                      );
                    }
                  },
                  icon: const Icon(Icons.people_outline_rounded, size: 16),
                  label: const Text('View Students'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
