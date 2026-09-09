import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/repositories/repositories.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/activity_log_service.dart';
import 'package:unisphere/services/hod_action_center_service.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';
import 'package:unisphere/providers/post_od_provider.dart';

// ── 1. Authenticated HOD User ID Provider ──
final currentHodUidProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull ?? ref.watch(authServiceProvider).currentUser;
  final uid = user?.uid ?? '';
  return uid;
});

// ── 2. Authenticated HOD Department Resolution Provider ──
final currentHodDepartmentProvider = FutureProvider<DepartmentModel>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull ?? ref.watch(authServiceProvider).currentUser;
  final String hodUid = (user?.uid != null && user!.uid.isNotEmpty)
      ? user.uid
      : ref.watch(currentHodUidProvider);
  final deptRepo = ref.watch(departmentRepositoryProvider);
  return deptRepo.getDepartmentForHod(
    hodId: hodUid,
    userDeptName: user?.departmentName ?? user?.department,
    userDeptId: user?.departmentId,
    hodName: user?.fullName ?? user?.name,
  );
});

// ── 3. Department ID Provider ──
final hodDepartmentIdProvider = Provider<String>((ref) {
  final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
  if (dept != null && dept.departmentId.isNotEmpty) {
    return dept.departmentId;
  }
  final user = ref.watch(currentUserProvider).valueOrNull ?? ref.watch(authServiceProvider).currentUser;
  if (user?.departmentId != null && user!.departmentId!.isNotEmpty) {
    return user.departmentId!;
  }
  final userDept = user?.departmentName ?? user?.department;
  if (userDept != null && userDept.isNotEmpty) {
    return DepartmentRepository.deriveDepartmentId(userDept);
  }
  return 'DEP-CSE';
});

// ── 4. Department-Scoped Students Stream ──
final hodStudentsStreamProvider = StreamProvider<List<StudentModel>>((ref) {
  final deptId = ref.watch(hodDepartmentIdProvider);
  final studentRepo = ref.watch(studentRepositoryProvider);
  return studentRepo.watchStudentsByDepartment(deptId);
});

// ── 5. Department-Scoped Staff Stream ──
final hodStaffStreamProvider = StreamProvider<List<StaffModel>>((ref) {
  final deptId = ref.watch(hodDepartmentIdProvider);
  final staffRepo = ref.watch(staffRepositoryProvider);
  return staffRepo.watchStaffByDepartment(deptId);
});

// ── 6. Department-Scoped Staff Assignments Stream ──
final hodAssignmentsStreamProvider =
    StreamProvider<List<StaffAssignmentModel>>((ref) {
  final deptId = ref.watch(hodDepartmentIdProvider);
  final staffRepo = ref.watch(staffRepositoryProvider);
  return staffRepo.watchAssignmentsByDepartment(deptId);
});

// ── 7. Department-Scoped Leave & OD Requests Stream ──
final hodLeaveRequestsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final deptId = ref.watch(hodDepartmentIdProvider);
  final staffRepo = ref.watch(staffRepositoryProvider);
  return staffRepo.watchDepartmentLeaveRequests(deptId);
});

// ── 8. Department Academic Charter Stream ──
final hodDepartmentCharterStreamProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  final deptId = ref.watch(hodDepartmentIdProvider);
  final deptRepo = ref.watch(departmentRepositoryProvider);
  return deptRepo.watchDepartmentCharter(deptId);
});

// ── 9. Department Summary Metrics Model ──
class HodDepartmentSummary {
  final int totalStudents;
  final int totalFaculty;
  final int totalAdvisors;
  final int totalClasses;
  final double averageAttendance;
  final double averageCgpa;
  final int atRiskCount;
  final int pendingActionsCount;
  final int presentTodayCount;
  final int pendingLeavesCount;
  final int pendingODsCount;
  final int pendingVerificationsCount;

  const HodDepartmentSummary({
    required this.totalStudents,
    required this.totalFaculty,
    required this.totalAdvisors,
    required this.totalClasses,
    required this.averageAttendance,
    required this.averageCgpa,
    required this.atRiskCount,
    required this.pendingActionsCount,
    required this.presentTodayCount,
    required this.pendingLeavesCount,
    required this.pendingODsCount,
    required this.pendingVerificationsCount,
  });

  static const empty = HodDepartmentSummary(
    totalStudents: 0,
    totalFaculty: 0,
    totalAdvisors: 0,
    totalClasses: 0,
    averageAttendance: 0.0,
    averageCgpa: 0.0,
    atRiskCount: 0,
    pendingActionsCount: 0,
    presentTodayCount: 0,
    pendingLeavesCount: 0,
    pendingODsCount: 0,
    pendingVerificationsCount: 0,
  );
}

// ── 10. Live Computed Department Summary Metrics Provider ──
final hodDepartmentSummaryMetricsProvider = Provider<HodDepartmentSummary>((ref) {
  final students = ref.watch(hodStudentsStreamProvider).valueOrNull ?? [];
  final staff = ref.watch(hodStaffStreamProvider).valueOrNull ?? [];
  final assignments = ref.watch(hodAssignmentsStreamProvider).valueOrNull ?? [];
  final leaves = ref.watch(hodLeaveRequestsStreamProvider).valueOrNull ?? [];
  final verifications = ref.watch(hodVerificationsStreamProvider).valueOrNull ?? [];
  final postOdState = ref.watch(postOdProvider);

  // 1. Students & Classes Calculations
  final totalStudents = students.length;
  final classesSet = <String>{};
  double sumAttendance = 0;
  double sumCgpa = 0;
  int attendanceCount = 0;
  int cgpaCount = 0;
  int atRisk = 0;

  for (final s in students) {
    if (s.section.isNotEmpty) classesSet.add(s.section);
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
      if (cgpa < 6.5 && (att == null || att >= 75.0)) atRisk++;
    }

    if (s.academicStatus.toLowerCase() == 'at risk' && (att == null || att >= 75.0)) {
      atRisk++;
    }
  }

  // 2. Staff & Advisors Calculations
  final totalFaculty = staff.length;
  final advisorStaffIds = <String>{};
  for (final a in assignments) {
    if (a.isClassAdvisor && a.status == 'active') {
      advisorStaffIds.add(a.staffId);
    }
  }
  for (final s in staff) {
    if (s.isAdvisor) advisorStaffIds.add(s.userId);
  }

  // 3. Pending Actions
  final pendingLeaves = leaves.where((l) {
    final status = (l['status'] ?? '').toString().toLowerCase();
    final type = (l['type'] ?? l['leaveCategory'] ?? '').toString().toLowerCase();
    return status.contains('pending') && !type.contains('duty') && !type.contains('od');
  }).length;

  final pendingODs = leaves.where((l) {
    final status = (l['status'] ?? '').toString().toLowerCase();
    final type = (l['type'] ?? l['leaveCategory'] ?? '').toString().toLowerCase();
    return status.contains('pending') && (type.contains('duty') || type.contains('od'));
  }).length;

  final pendingVerifications = verifications.where((v) => v['status'] == 'pending_hod').length;
  final pendingPostOd = postOdState.outcomes.where((o) => o.hodStatus == 'Pending HOD Verification').length;

  final pendingTotal = pendingLeaves + pendingODs + pendingVerifications + pendingPostOd;

  final avgAtt = attendanceCount > 0 ? (sumAttendance / attendanceCount) : 0.0;
  final avgCgpa = cgpaCount > 0 ? (sumCgpa / cgpaCount) : 0.0;
  final presentToday = totalStudents > 0 ? (totalStudents * (avgAtt > 0 ? avgAtt / 100 : 0.94)).round() : 0;

  return HodDepartmentSummary(
    totalStudents: totalStudents,
    totalFaculty: totalFaculty,
    totalAdvisors: advisorStaffIds.length,
    totalClasses: classesSet.length,
    averageAttendance: double.parse(avgAtt.toStringAsFixed(1)),
    averageCgpa: double.parse(avgCgpa.toStringAsFixed(2)),
    atRiskCount: atRisk,
    pendingActionsCount: pendingTotal,
    presentTodayCount: presentToday,
    pendingLeavesCount: pendingLeaves,
    pendingODsCount: pendingODs,
    pendingVerificationsCount: pendingVerifications + pendingPostOd,
  );
});

final hodDepartmentSummaryProvider = hodDepartmentSummaryMetricsProvider;

// ── 11. Students Requiring Attention (At Risk) Provider ──
final hodStudentRiskListProvider = Provider<List<StudentModel>>((ref) {
  final students = ref.watch(hodStudentsStreamProvider).valueOrNull ?? [];
  if (students.isEmpty) return [];

  return students.where((s) {
    final att = double.tryParse(s.attendancePercent ?? '') ?? 100.0;
    final cgpa = double.tryParse(s.cgpa ?? '') ?? 10.0;
    return att < 75.0 || cgpa < 6.5 || s.academicStatus.toLowerCase() == 'at risk';
  }).toList();
});

// ── 12. Department Attendance Analytics Breakdown ──
class AttendanceDistribution {
  final int exemplary; // >= 90%
  final int good; // 80% - 89%
  final int borderline; // 75% - 79%
  final int alert; // < 75%
  final int total;

  const AttendanceDistribution({
    required this.exemplary,
    required this.good,
    required this.borderline,
    required this.alert,
    required this.total,
  });

  double get exemplaryPct => total > 0 ? exemplary / total : 0.0;
  double get goodPct => total > 0 ? good / total : 0.0;
  double get borderlinePct => total > 0 ? borderline / total : 0.0;
  double get alertPct => total > 0 ? alert / total : 0.0;
}

final hodAttendanceAnalyticsProvider = Provider<AttendanceDistribution>((ref) {
  final students = ref.watch(hodStudentsStreamProvider).valueOrNull ?? [];
  if (students.isEmpty) {
    return const AttendanceDistribution(exemplary: 0, good: 0, borderline: 0, alert: 0, total: 0);
  }

  int ex = 0, gd = 0, bl = 0, al = 0;
  for (final s in students) {
    final att = double.tryParse(s.attendancePercent ?? '') ?? 85.0;
    if (att >= 90.0) {
      ex++;
    } else if (att >= 80.0) {
      gd++;
    } else if (att >= 75.0) {
      bl++;
    } else {
      al++;
    }
  }

  return AttendanceDistribution(exemplary: ex, good: gd, borderline: bl, alert: al, total: students.length);
});

// ── 13. Department CGPA Analytics Breakdown ──
class CgpaDistribution {
  final int distinction; // >= 9.0
  final int firstClass; // 8.0 - 8.9
  final int secondClass; // 7.0 - 7.9
  final int reAppear; // < 7.0
  final int total;

  const CgpaDistribution({
    required this.distinction,
    required this.firstClass,
    required this.secondClass,
    required this.reAppear,
    required this.total,
  });

  double get distinctionPct => total > 0 ? distinction / total : 0.0;
  double get firstClassPct => total > 0 ? firstClass / total : 0.0;
  double get secondClassPct => total > 0 ? secondClass / total : 0.0;
  double get reAppearPct => total > 0 ? reAppear / total : 0.0;
}

final hodAcademicAnalyticsProvider = Provider<CgpaDistribution>((ref) {
  final students = ref.watch(hodStudentsStreamProvider).valueOrNull ?? [];
  if (students.isEmpty) {
    return const CgpaDistribution(distinction: 0, firstClass: 0, secondClass: 0, reAppear: 0, total: 0);
  }

  int dist = 0, fc = 0, sc = 0, ra = 0;
  for (final s in students) {
    final cgpa = double.tryParse(s.cgpa ?? '') ?? 8.0;
    if (cgpa >= 9.0) {
      dist++;
    } else if (cgpa >= 8.0) {
      fc++;
    } else if (cgpa >= 7.0) {
      sc++;
    } else {
      ra++;
    }
  }

  return CgpaDistribution(
    distinction: dist,
    firstClass: fc,
    secondClass: sc,
    reAppear: ra,
    total: students.length,
  );
});

// ── 14. Department Recent Activity Stream Provider ──
final hodRecentActivityStreamProvider = StreamProvider<List<ActivityLogModel>>((ref) {
  final activityService = ref.watch(activityLogServiceProvider);
  return activityService.watchRecentActivity(limit: 10);
});

// ── 15. Department Today Schedule Provider ──
class DepartmentScheduleItem {
  final String period;
  final String time;
  final String courseCode;
  final String subject;
  final String facultyName;
  final String room;
  final String yearSection;
  final bool isLive;

  const DepartmentScheduleItem({
    required this.period,
    required this.time,
    required this.courseCode,
    required this.subject,
    required this.facultyName,
    required this.room,
    required this.yearSection,
    this.isLive = false,
  });

  String get courseName => subject;
  String get section => yearSection;
}

final hodTodayScheduleProvider = Provider<List<DepartmentScheduleItem>>((ref) {
  return const [];
});

// ── 16. Student Risk Profiles Provider ──
final hodStudentRiskProfilesProvider = Provider<List<StudentRiskProfile>>((ref) {
  final students = ref.watch(hodStudentsStreamProvider).valueOrNull ?? [];
  final list = <StudentRiskProfile>[];

  for (final s in students) {
    final att = double.tryParse(s.attendancePercent ?? '') ?? 100.0;
    final cgpa = double.tryParse(s.cgpa ?? '') ?? 10.0;
    final isAttRisk = att < 75.0;
    final isCgpaRisk = cgpa < 6.5;
    final isFlagged = s.academicStatus.toLowerCase() == 'at risk';

    if (isAttRisk || isCgpaRisk || isFlagged) {
      final reasons = <String>[];
      if (isAttRisk) reasons.add('Attendance (${att.toStringAsFixed(1)}% < 75%)');
      if (isCgpaRisk) reasons.add('CGPA (${cgpa.toStringAsFixed(2)} < 6.50)');
      if (isFlagged && !isAttRisk && !isCgpaRisk) reasons.add('Flagged by Class Advisor');

      final priority = (isAttRisk && isCgpaRisk) || att < 65.0
          ? HodPriorityLevel.critical
          : (isAttRisk ? HodPriorityLevel.high : HodPriorityLevel.medium);

      list.add(StudentRiskProfile(
        student: s,
        riskLevel: priority,
        reasons: reasons,
        attendance: att,
        cgpa: cgpa,
        isAttendanceRisk: isAttRisk,
        isAcademicRisk: isCgpaRisk,
      ));
    }
  }

  list.sort((a, b) {
    final pComp = a.riskLevel.index.compareTo(b.riskLevel.index);
    if (pComp != 0) return pComp;
    return a.attendance.compareTo(b.attendance);
  });
  return list;
});

// ── 17. Intelligent Action Center Provider (Smart Priority Engine) ──
final hodActionCenterProvider = Provider<List<HodActionItem>>((ref) {
  final summary = ref.watch(hodDepartmentSummaryMetricsProvider);
  final riskProfiles = ref.watch(hodStudentRiskProfilesProvider);

  final items = <HodActionItem>[];

  // 1. Critical Attendance Risk
  final criticalStudents = riskProfiles.where((r) => r.riskLevel == HodPriorityLevel.critical).toList();
  if (criticalStudents.isNotEmpty) {
    items.add(HodActionItem(
      id: 'att_critical',
      category: 'attendance',
      title: 'Critical Attendance Deficit',
      contextDescription: '${criticalStudents.length} student${criticalStudents.length > 1 ? "s" : ""} below 65% mandatory threshold requiring advisory summon.',
      deadline: 'Immediate Action',
      priority: HodPriorityLevel.critical,
      actionLabel: 'Review Students',
      targetRouteIndex: 4, // Student Management
      icon: Icons.shield_outlined,
    ));
  } else if (riskProfiles.isNotEmpty) {
    items.add(HodActionItem(
      id: 'att_warning',
      category: 'attendance',
      title: 'Attendance Risk Threshold (<75%)',
      contextDescription: '${riskProfiles.length} student${riskProfiles.length > 1 ? "s" : ""} flagged below 75% semester requirement.',
      deadline: 'Before Next Cycle Test',
      priority: HodPriorityLevel.high,
      actionLabel: 'View Flagged Students',
      targetRouteIndex: 4,
      icon: Icons.warning_amber_rounded,
    ));
  }

  // 2. Pending Leave Applications
  if (summary.pendingLeavesCount > 0) {
    items.add(HodActionItem(
      id: 'pending_leaves',
      category: 'leave',
      title: 'Pending Leave Applications',
      contextDescription: '${summary.pendingLeavesCount} student/staff leave request${summary.pendingLeavesCount > 1 ? "s" : ""} awaiting HOD signature.',
      deadline: 'Today by 5:00 PM',
      priority: summary.pendingLeavesCount > 3 ? HodPriorityLevel.critical : HodPriorityLevel.high,
      actionLabel: 'Review Requests',
      targetRouteIndex: 19, // Leave & OD Approvals
      icon: Icons.event_busy_outlined,
    ));
  }

  // 3. Pending OD / On-Duty Applications
  if (summary.pendingODsCount > 0) {
    items.add(HodActionItem(
      id: 'pending_ods',
      category: 'od',
      title: 'Pending On-Duty (OD) Endorsements',
      contextDescription: '${summary.pendingODsCount} symposium & contest OD application${summary.pendingODsCount > 1 ? "s" : ""} awaiting approval.',
      deadline: 'Upcoming Events',
      priority: HodPriorityLevel.medium,
      actionLabel: 'Approve ODs',
      targetRouteIndex: 19,
      icon: Icons.badge_outlined,
    ));
  }

  // 4. Student Certificate & Profile Verifications
  if (summary.pendingVerificationsCount > 0) {
    items.add(HodActionItem(
      id: 'pending_verifications',
      category: 'verification',
      title: 'Student Certificate Verifications',
      contextDescription: '${summary.pendingVerificationsCount} NPTEL / internship verification${summary.pendingVerificationsCount > 1 ? "s" : ""} pending HOD seal.',
      deadline: 'Semester Credit Cycle',
      priority: HodPriorityLevel.medium,
      actionLabel: 'Verify Documents',
      targetRouteIndex: 5, // Student Verifications
      icon: Icons.verified_user_outlined,
    ));
  }

  // 5. Academic Exam / Marks Moderation
  final marksDocs = ref.watch(hodMarksDocumentsStreamProvider).valueOrNull ?? [];
  final pendingMarks = marksDocs.where((d) => d.approvalStatus.toLowerCase().contains('pending')).length;
  if (pendingMarks > 0) {
    items.add(HodActionItem(
      id: 'marks_internal_review',
      category: 'marks',
      title: 'Exam Marks Moderation',
      contextDescription: '$pendingMarks internal marks submission${pendingMarks > 1 ? "s" : ""} awaiting HOD moderation.',
      deadline: 'Moderation Window Open',
      priority: HodPriorityLevel.high,
      actionLabel: 'Review Marks',
      targetRouteIndex: 17, // Examination & Marks
      icon: Icons.assessment_outlined,
    ));
  }

  items.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  return items;
});

// ── 18. Faculty Workload Intelligence Provider ──
final hodFacultyWorkloadProvider = Provider<List<FacultyWorkloadSummary>>((ref) {
  final staff = ref.watch(hodStaffStreamProvider).valueOrNull ?? [];
  final assignments = ref.watch(hodAssignmentsStreamProvider).valueOrNull ?? [];

  if (staff.isEmpty) return [];

  return staff.map((s) {
    final staffAssignments = assignments.where((a) => a.staffId == s.userId && a.status == 'active').toList();
    final subjectCount = staffAssignments.length;
    final periods = subjectCount * 4;
    final loadPct = (periods / 16.0) * 100;
    final status = loadPct > 105
        ? FacultyWorkloadStatus.overloaded
        : (loadPct < 70 ? FacultyWorkloadStatus.underutilized : FacultyWorkloadStatus.balanced);

    return FacultyWorkloadSummary(
      staff: s,
      assignedSubjectsCount: subjectCount,
      weeklyPeriodsCount: periods,
      workloadStatus: status,
      loadPercentage: loadPct,
    );
  }).toList();
});

// ── 19. Department Deadlines Intelligence Provider ──
final hodDepartmentDeadlinesProvider = Provider<List<DepartmentDeadlineItem>>((ref) {
  return const [];
});

// ── 20. Executive Department Health Provider ──
final hodExecutiveHealthProvider = Provider<ExecutiveDepartmentHealth>((ref) {
  final summary = ref.watch(hodDepartmentSummaryMetricsProvider);
  final staff = ref.watch(hodStaffStreamProvider).valueOrNull ?? [];
  final leaves = ref.watch(hodLeaveRequestsStreamProvider).valueOrNull ?? [];

  final totalFac = summary.totalFaculty > 0 ? summary.totalFaculty : staff.length;
  final onLeave = leaves.where((l) => (l['status'] ?? '').toString().toLowerCase() == 'approved').length;
  final coverageRate = totalFac > 0 ? (((totalFac - onLeave) / totalFac) * 100).clamp(0.0, 100.0) : 0.0;

  final hasAtt = summary.averageAttendance > 0;
  final hasCgpa = summary.averageCgpa > 0;
  final hasFaculty = totalFac > 0;

  return ExecutiveDepartmentHealth(
    attendanceRate: summary.averageAttendance,
    academicAverageCgpa: summary.averageCgpa,
    facultyCoverageRate: double.parse(coverageRate.toStringAsFixed(1)),
    pendingActionsCount: summary.pendingActionsCount,
    totalStudents: summary.totalStudents,
    totalFaculty: totalFac,
    activeClasses: summary.totalClasses,
    attendanceTrend: hasAtt ? '+${summary.averageAttendance}% recorded' : 'No attendance data',
    academicTrend: hasCgpa ? 'Avg CGPA ${summary.averageCgpa}' : 'No grades recorded',
    coverageTrend: hasFaculty ? '${totalFac - onLeave} of $totalFac on duty' : 'No faculty enrolled',
  );
});

// ── 21. HOD Exam Evaluation Status Stream Provider ──
final hodEvaluationStatusStreamProvider = StreamProvider.family<List<ExamEvaluationSubjectStatus>, ({String examTitle, int semester})>((ref, arg) {
  final deptId = ref.watch(hodDepartmentIdProvider);
  final repo = ref.watch(examManagementRepositoryProvider);
  return repo.watchDepartmentEvaluationStatus(
    departmentId: deptId,
    examTitle: arg.examTitle,
    semester: arg.semester,
  );
});

// ── 22. HOD Marks Documents Stream Provider ──
final hodMarksDocumentsStreamProvider = StreamProvider<List<MarksDocumentModel>>((ref) {
  final deptId = ref.watch(hodDepartmentIdProvider);
  final repo = ref.watch(examManagementRepositoryProvider);
  return repo.watchDepartmentMarksDocuments(deptId);
});

// ── 23. HOD Department Rank List Stream Provider ──
final hodDepartmentRankListProvider = StreamProvider.family<List<DepartmentRankItem>, int?>((ref, semester) {
  final deptId = ref.watch(hodDepartmentIdProvider);
  final repo = ref.watch(examManagementRepositoryProvider);
  return repo.watchDepartmentRankList(deptId, semester: semester);
});
