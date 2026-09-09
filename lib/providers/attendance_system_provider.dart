import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/attendance_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/repositories/attendance_repository.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';

/// Combined State for the rebuilt Attendance System
class AttendanceSystemState {
  final Map<int, HodSemesterConfig> hodSemesterConfigs;
  final List<SemesterAttendance> studentSemesters;
  final int selectedSemesterIndex;
  final List<AttendanceRecord> attendanceLogs;
  final List<DailyAttendanceLog> dailyLogs;
  final List<LeaveRequestModel> leaveRequests;

  const AttendanceSystemState({
    required this.hodSemesterConfigs,
    required this.studentSemesters,
    this.selectedSemesterIndex = 3, // Default Sem 4 (Active)
    required this.attendanceLogs,
    required this.dailyLogs,
    required this.leaveRequests,
  });

  SemesterAttendance get selectedSemester {
    if (selectedSemesterIndex >= 0 && selectedSemesterIndex < studentSemesters.length) {
      return studentSemesters[selectedSemesterIndex];
    }
    return studentSemesters.last;
  }

  SemesterAttendance get activeSemester {
    return studentSemesters.firstWhere(
      (s) => s.isCurrentSemester,
      orElse: () => studentSemesters.last,
    );
  }

  AttendanceSystemState copyWith({
    Map<int, HodSemesterConfig>? hodSemesterConfigs,
    List<SemesterAttendance>? studentSemesters,
    int? selectedSemesterIndex,
    List<AttendanceRecord>? attendanceLogs,
    List<DailyAttendanceLog>? dailyLogs,
    List<LeaveRequestModel>? leaveRequests,
  }) {
    return AttendanceSystemState(
      hodSemesterConfigs: hodSemesterConfigs ?? this.hodSemesterConfigs,
      studentSemesters: studentSemesters ?? this.studentSemesters,
      selectedSemesterIndex: selectedSemesterIndex ?? this.selectedSemesterIndex,
      attendanceLogs: attendanceLogs ?? this.attendanceLogs,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      leaveRequests: leaveRequests ?? this.leaveRequests,
    );
  }
}

class AttendanceSystemNotifier extends StateNotifier<AttendanceSystemState> {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  StreamSubscription<List<AttendanceRecord>>? _attendanceSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _leaveSub;

  AttendanceSystemNotifier({UserModel? user}) : super(_buildInitialState(user)) {
    _initStreams(user);
  }

  void _initStreams(UserModel? user) {
    if (user == null) return;
    final meta = user.metadata ?? <String, dynamic>{};
    final regNo = meta['registerNumber']?.toString().trim() ??
        meta['regNo']?.toString().trim() ??
        user.uid;

    if (regNo.isNotEmpty) {
      _attendanceSub = _attendanceRepo.watchStudentAttendance(regNo).listen((records) {
        if (records.isNotEmpty) {
          final pct = _attendanceRepo.calculateAttendancePercentage(records);
          final int activeAttended = ((pct / 100.0) * 90).round();

          final updatedSemesters = state.studentSemesters.map((s) {
            if (s.isCurrentSemester) {
              return s.copyWith(attendedWorkingDays: activeAttended);
            }
            return s;
          }).toList();

          state = state.copyWith(
            attendanceLogs: records,
            studentSemesters: updatedSemesters,
          );
        }
      }, onError: (e) {
        debugPrint('Attendance stream listener error: $e');
      });

      try {
        final firestore = FirebaseFirestore.instance;
        _leaveSub = firestore
            .collection('leave_requests')
            .where(Filter.or(
              Filter('studentId', isEqualTo: regNo),
              Filter('student_id', isEqualTo: regNo),
              Filter('studentUid', isEqualTo: regNo),
              Filter('registerNumber', isEqualTo: regNo),
            ))
            .snapshots()
            .listen((snap) {
          if (snap.docs.isNotEmpty) {
            final leaves = snap.docs.map((doc) => LeaveRequestModel.fromMap(doc.data(), doc.id)).toList();
            state = state.copyWith(leaveRequests: leaves);
          }
        }, onError: (e) {
          debugPrint('Leave requests stream error: $e');
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _leaveSub?.cancel();
    super.dispose();
  }

  static AttendanceSystemState _buildInitialState(UserModel? user) {
    final meta = user?.metadata ?? {};
    final double? dbAtt = double.tryParse(meta['attendance']?.toString() ?? '');
    final double targetAtt = dbAtt ?? 0.0;
    final int sem4Attended = ((targetAtt / 100.0) * 90).round();

    return AttendanceSystemState(
      hodSemesterConfigs: {
        1: const HodSemesterConfig(semesterNumber: 1, semesterName: 'Semester 1 (1st Year)', totalWorkingDays: 90),
        2: const HodSemesterConfig(semesterNumber: 2, semesterName: 'Semester 2 (1st Year)', totalWorkingDays: 90),
        3: const HodSemesterConfig(semesterNumber: 3, semesterName: 'Semester 3 (2nd Year)', totalWorkingDays: 95),
        4: const HodSemesterConfig(semesterNumber: 4, semesterName: 'Semester 4 (2nd Year)', totalWorkingDays: 90),
        5: const HodSemesterConfig(semesterNumber: 5, semesterName: 'Semester 5 (3rd Year)', totalWorkingDays: 90),
        6: const HodSemesterConfig(semesterNumber: 6, semesterName: 'Semester 6 (3rd Year)', totalWorkingDays: 90),
        7: const HodSemesterConfig(semesterNumber: 7, semesterName: 'Semester 7 (4th Year)', totalWorkingDays: 90),
        8: const HodSemesterConfig(semesterNumber: 8, semesterName: 'Semester 8 (4th Year)', totalWorkingDays: 90),
      },
      studentSemesters: [
        for (int i = 1; i <= 8; i++)
          SemesterAttendance(
            semesterNumber: i,
            semesterName: 'Semester $i',
            attendedWorkingDays: i == 4 ? sem4Attended : 0,
            totalWorkingDays: i == 3 ? 95 : 90,
            isCurrentSemester: i == 4,
            subjects: const [],
          ),
      ],
      selectedSemesterIndex: 3,
      dailyLogs: const [],
      attendanceLogs: const [],
      leaveRequests: const [],
    );
  }

  /// HOD updates total working days for a semester
  void updateSemesterWorkingDaysByHod(int semNumber, int newWorkingDays) {
    if (newWorkingDays <= 0) return;

    final updatedConfigs = Map<int, HodSemesterConfig>.from(state.hodSemesterConfigs);
    updatedConfigs[semNumber] = (updatedConfigs[semNumber] ?? HodSemesterConfig(semesterNumber: semNumber, semesterName: 'Semester $semNumber', totalWorkingDays: newWorkingDays))
        .copyWith(totalWorkingDays: newWorkingDays);

    final updatedSemesters = state.studentSemesters.map((s) {
      if (s.semesterNumber == semNumber) {
        final double currentAttPct = s.attendancePercentage;
        final newAttended = ((currentAttPct / 100.0) * newWorkingDays).round();
        return s.copyWith(
          totalWorkingDays: newWorkingDays,
          attendedWorkingDays: newAttended,
        );
      }
      return s;
    }).toList();

    state = state.copyWith(
      hodSemesterConfigs: updatedConfigs,
      studentSemesters: updatedSemesters,
    );

    // Save to Firestore so student view reads updated working days from HOD
    FirebaseFirestoreService().saveSemesterWorkingDays(semNumber, newWorkingDays);
  }

  /// Change active selected semester index
  void selectSemesterIndex(int index) {
    if (index >= 0 && index < state.studentSemesters.length) {
      state = state.copyWith(selectedSemesterIndex: index);
    }
  }

  /// Staff submits session attendance for a class
  void submitStaffSessionAttendance({
    required String subjectCode,
    required String subjectName,
    required String facultyName,
    required String timeSlot,
    required List<Map<String, dynamic>> studentResults,
  }) {
    final now = DateTime.now();
    final newLogs = <AttendanceRecord>[];

    for (final s in studentResults) {
      final isPresent = s['isPresent'] as bool? ?? true;
      final status = isPresent ? AttendanceStatus.present : AttendanceStatus.absent;
      final studentId = (s['id'] ?? s['studentId'] ?? s['studentUid'] ?? s['registerNumber'] ?? 'student_1').toString().trim();
      final studentName = (s['name'] ?? s['studentName'] ?? 'Student').toString().trim();

      newLogs.add(
        AttendanceRecord(
          id: '${now.millisecondsSinceEpoch}_$studentId',
          studentUid: studentId,
          studentName: studentName,
          subjectCode: subjectCode,
          subjectName: subjectName,
          date: now,
          timeSlot: timeSlot,
          status: status,
          facultyName: facultyName,
        ),
      );
    }

    state = state.copyWith(
      attendanceLogs: [...newLogs, ...state.attendanceLogs],
    );

    // Persist real-time records to Cloud Firestore and update student metrics
    _attendanceRepo.markBatchAttendance(newLogs).ignore();
  }

  /// Student submits a new Leave / OD application
  void addLeaveRequest(LeaveRequestModel request) {
    state = state.copyWith(
      leaveRequests: [request, ...state.leaveRequests],
    );

    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('leave_requests')
          .doc(request.id)
          .set(request.toMap(), SetOptions(merge: true))
          .ignore();
    } catch (e) {
      debugPrint('Firestore save leave request error: $e');
    }
  }
}

final attendanceSystemProvider =
    StateNotifierProvider<AttendanceSystemNotifier, AttendanceSystemState>(
  (ref) {
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    return AttendanceSystemNotifier(user: user);
  },
);
