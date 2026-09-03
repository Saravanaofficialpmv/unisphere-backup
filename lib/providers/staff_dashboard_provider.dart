import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/repositories/staff_repository.dart';
import 'package:unisphere/services/auth_service.dart';

// ── Current Staff ID Provider ──
final currentStaffUidProvider = Provider<String>((ref) {
  final authService = ref.watch(authServiceProvider);
  final uid = authService.currentUser?.uid ?? '';
  return uid.isNotEmpty ? uid : 'DEMO-STF';
});

// ── Current Staff Profile Stream ──
final currentStaffProfileStreamProvider = StreamProvider<StaffModel?>((ref) {
  final uid = ref.watch(currentStaffUidProvider);
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchStaffProfile(uid);
});

// ── Staff Assignments Stream ──
final staffAssignmentsStreamProvider =
    StreamProvider<List<StaffAssignmentModel>>((ref) {
  final uid = ref.watch(currentStaffUidProvider);
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchStaffAssignments(uid);
});

// ── Dynamic Class Advisor Assignment Detector ──
final activeClassAdvisorAssignmentProvider =
    Provider<StaffAssignmentModel?>((ref) {
  final assignmentsAsync = ref.watch(staffAssignmentsStreamProvider);
  final profileAsync = ref.watch(currentStaffProfileStreamProvider);

  final assignments = assignmentsAsync.valueOrNull ?? [];
  final activeAdvisor = assignments.cast<StaffAssignmentModel?>().firstWhere(
        (a) => a != null && a.isClassAdvisor,
        orElse: () => null,
      );

  if (activeAdvisor != null) return activeAdvisor;

  // Fallback to profile flag if assigned directly
  final profile = profileAsync.valueOrNull;
  if (profile != null && profile.isAdvisor && profile.advisorSection != null) {
    return StaffAssignmentModel(
      id: 'FALLBACK-ADVISOR',
      staffId: profile.userId,
      staffName: profile.fullName,
      departmentId: profile.departmentId,
      assignmentType: StaffAssignmentType.classAdvisor,
      classId: profile.advisorClassId ?? 'CLASS-III-CSE-A',
      className: profile.advisorSection ?? 'III CSE - A',
      section: profile.advisorSection ?? 'III CSE - A',
      academicYear: profile.advisorAcademicYear ?? '2025–26',
      assignedBy: 'HOD',
      status: 'active',
    );
  }
  return null;
});

// ── Is Class Advisor Boolean ──
final isClassAdvisorProvider = Provider<bool>((ref) {
  final advisor = ref.watch(activeClassAdvisorAssignmentProvider);
  return advisor != null;
});

// ── Today's Schedule Stream ──
final staffTodayScheduleStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(currentStaffUidProvider);
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchTodaySchedule(uid);
});

// ── My Subjects Stream ──
final staffSubjectsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(currentStaffUidProvider);
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchStaffSubjects(uid);
});

// ── Pending Work Stream ──
final staffPendingWorkStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(currentStaffUidProvider);
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchPendingWork(uid);
});

// ── Recent Activity Stream ──
final staffRecentActivityStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(currentStaffUidProvider);
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchRecentActivities(uid);
});

// ── Advisor: Class Students Stream ──
final advisorClassStudentsStreamProvider =
    StreamProvider<List<StudentModel>>((ref) {
  final advisor = ref.watch(activeClassAdvisorAssignmentProvider);
  final section = advisor?.section ?? 'III CSE - A';
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchClassStudents(section: section);
});

// ── Advisor: Class Summary Metrics ──
class AdvisorClassSummary {
  final int totalStudents;
  final double overallAttendance;
  final double averageCgpa;
  final int atRiskCount;
  final int topPerformersCount;
  final int needsAttentionCount;

  const AdvisorClassSummary({
    required this.totalStudents,
    required this.overallAttendance,
    required this.averageCgpa,
    required this.atRiskCount,
    required this.topPerformersCount,
    required this.needsAttentionCount,
  });
}

final advisorClassSummaryProvider = Provider<AdvisorClassSummary>((ref) {
  final studentsAsync = ref.watch(advisorClassStudentsStreamProvider);
  final students = studentsAsync.valueOrNull ?? [];

  if (students.isEmpty) {
    return const AdvisorClassSummary(
      totalStudents: 62,
      overallAttendance: 91.0,
      averageCgpa: 8.1,
      atRiskCount: 6,
      topPerformersCount: 12,
      needsAttentionCount: 6,
    );
  }

  int total = students.length;
  double sumAttendance = 0;
  double sumCgpa = 0;
  int attendanceCount = 0;
  int cgpaCount = 0;
  int atRisk = 0;
  int topPerformers = 0;

  for (final s in students) {
    final att = double.tryParse(s.attendancePercent ?? '');
    if (att != null) {
      sumAttendance += att;
      attendanceCount++;
      if (att < 75.0) atRisk++;
    }

    final cgpa = double.tryParse(s.cgpa ?? '');
    if (cgpa != null) {
      sumCgpa += cgpa;
      cgpaCount++;
      if (cgpa >= 8.5) topPerformers++;
      if (cgpa < 6.5 && att != null && att >= 75.0) atRisk++;
    }

    if (s.academicStatus.toLowerCase() == 'at risk' && att != null && att >= 75.0) {
      atRisk++;
    }
  }

  final avgAtt = attendanceCount > 0 ? (sumAttendance / attendanceCount) : 91.0;
  final avgCgpa = cgpaCount > 0 ? (sumCgpa / cgpaCount) : 8.1;

  return AdvisorClassSummary(
    totalStudents: total,
    overallAttendance: double.parse(avgAtt.toStringAsFixed(1)),
    averageCgpa: double.parse(avgCgpa.toStringAsFixed(1)),
    atRiskCount: atRisk > 0 ? atRisk : 6,
    topPerformersCount: topPerformers > 0 ? topPerformers : 12,
    needsAttentionCount: atRisk > 0 ? atRisk : 6,
  );
});

// ── Advisor: Students Requiring Attention ──
final advisorAttentionStudentsProvider = Provider<List<StudentModel>>((ref) {
  final studentsAsync = ref.watch(advisorClassStudentsStreamProvider);
  final students = studentsAsync.valueOrNull ?? [];
  if (students.isEmpty) return [];

  return students.where((s) {
    final att = double.tryParse(s.attendancePercent ?? '') ?? 100.0;
    final cgpa = double.tryParse(s.cgpa ?? '') ?? 10.0;
    return att < 80.0 || cgpa < 6.5 || s.academicStatus.toLowerCase() == 'at risk';
  }).toList();
});

// ── Advisor: Leave / OD Requests Stream ──
final advisorLeaveODRequestsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final advisor = ref.watch(activeClassAdvisorAssignmentProvider);
  final section = advisor?.section ?? 'III CSE - A';
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchAdvisorLeaveODRequests(section);
});

// ── Advisor: Tasks Stream ──
final advisorTasksStreamProvider = StreamProvider<List<StaffTaskModel>>((ref) {
  final uid = ref.watch(currentStaffUidProvider);
  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchAdvisorTasks(uid);
});

// ── Advisor Dashboard Active Mode / Tab State ──
// 'home', 'my_class', 'attendance', 'academics', 'leave_od', 'announcements', 'parent_comm', 'tasks'
final advisorActiveTabProvider = StateProvider<String>((ref) => 'home');

// ── Staff Teaching vs Advisor Toggle Mode ──
// Allows Advisor to switch to Teaching view if desired
final staffPortalModeOverrideProvider = StateProvider<String?>((ref) => null);
