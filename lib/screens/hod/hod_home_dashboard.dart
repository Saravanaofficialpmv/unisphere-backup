import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/user_session_service.dart';
import 'package:unisphere/widgets/common/apple_glass_card.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

import 'modules/hod_command_header.dart';
import 'modules/hod_executive_health.dart';
import 'modules/hod_action_center.dart';
import 'modules/hod_student_health_center.dart';
import 'modules/hod_faculty_health_center.dart';
import 'modules/hod_academic_performance_center.dart';
import 'modules/hod_today_operations.dart';
import 'modules/hod_deadline_intelligence.dart';
import 'modules/hod_activity_timeline.dart';

/// HOD Department Academic ERP Command Center Home Dashboard.
///
/// Features a 5-layer operational architecture:
/// 1. Department Status (Executive Health Matrix & Header)
/// 2. Attention / Priorities (Intelligent Action Center with Smart Priority Engine)
/// 3. Performance / Insights (Student Risk Engine, Faculty Workload, Academic Performance)
/// 4. Operations / Today (Today's Live Sessions & Deadline Intelligence)
/// 5. Actions / Workflows (Recent Activity Audit Trails & Action Launchers)
class HodHomeDashboard extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const HodHomeDashboard({super.key, this.onNavigate});

  @override
  ConsumerState<HodHomeDashboard> createState() => _HodHomeDashboardState();
}

class _HodHomeDashboardState extends ConsumerState<HodHomeDashboard> {
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
      debugPrint('Error checking HOD user session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 800;
    final bool isMobile = screenWidth < 600;

    return DataLoaderView(
      isLoading: false,
      child: AmbientGlassBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Layer 1: Top Command Header
              HodCommandHeader(isReturningUser: _isReturningUser),
              const SizedBox(height: 18),

              // Layer 1: Executive Department Health
              HodExecutiveHealth(
                onNavigateToAttendance: () => widget.onNavigate?.call(14),
                onNavigateToAcademics: () => widget.onNavigate?.call(10),
                onNavigateToFaculty: () => widget.onNavigate?.call(3),
                onNavigateToActions: () => widget.onNavigate?.call(19),
                onNavigateToStudents: () => widget.onNavigate?.call(4),
                onNavigateToClasses: () => widget.onNavigate?.call(16),
              ),
              const SizedBox(height: 20),

              // Responsive Layout for Layers 2 - 5
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Operational Priorities, Students & Academics)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HodActionCenter(
                            onNavigate: widget.onNavigate,
                          ),
                          const SizedBox(height: 20),
                          HodStudentHealthCenter(
                            onNavigateToStudents: () => widget.onNavigate?.call(4),
                          ),
                          const SizedBox(height: 20),
                          HodAcademicPerformanceCenter(
                            onNavigateToAcademics: () => widget.onNavigate?.call(10),
                            onNavigateToSchedule: () => widget.onNavigate?.call(18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Column (Live Operations, Faculty Workload, Deadlines & Timeline)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HodTodayOperations(
                            onNavigateToTimetable: () => widget.onNavigate?.call(16),
                          ),
                          const SizedBox(height: 20),
                          HodFacultyHealthCenter(
                            onNavigateToStaff: () => widget.onNavigate?.call(3),
                          ),
                          const SizedBox(height: 20),
                          HodDeadlineIntelligence(
                            onNavigate: widget.onNavigate,
                          ),
                          const SizedBox(height: 20),
                          const HodActivityTimeline(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // Mobile Vertical Flow (<800px)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HodActionCenter(
                      onNavigate: widget.onNavigate,
                    ),
                    const SizedBox(height: 18),
                    HodStudentHealthCenter(
                      onNavigateToStudents: () => widget.onNavigate?.call(4),
                    ),
                    const SizedBox(height: 18),
                    HodFacultyHealthCenter(
                      onNavigateToStaff: () => widget.onNavigate?.call(3),
                    ),
                    const SizedBox(height: 18),
                    HodAcademicPerformanceCenter(
                      onNavigateToAcademics: () => widget.onNavigate?.call(10),
                      onNavigateToSchedule: () => widget.onNavigate?.call(18),
                    ),
                    const SizedBox(height: 18),
                    HodTodayOperations(
                      onNavigateToTimetable: () => widget.onNavigate?.call(16),
                    ),
                    const SizedBox(height: 18),
                    HodDeadlineIntelligence(
                      onNavigate: widget.onNavigate,
                    ),
                    const SizedBox(height: 18),
                    const HodActivityTimeline(),
                    const SizedBox(height: 36),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
