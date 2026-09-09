import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';

/// Configuration for a semester set by Head of Department (HOD)
class SemesterWorkingDaysConfig {
  final int semesterNumber;
  final String semesterName;
  final int totalWorkingDays;
  final double minimumRequiredPercentage; // e.g. 75.0%

  const SemesterWorkingDaysConfig({
    required this.semesterNumber,
    required this.semesterName,
    required this.totalWorkingDays,
    this.minimumRequiredPercentage = 75.0,
  });

  SemesterWorkingDaysConfig copyWith({
    int? totalWorkingDays,
    double? minimumRequiredPercentage,
  }) {
    return SemesterWorkingDaysConfig(
      semesterNumber: semesterNumber,
      semesterName: semesterName,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      minimumRequiredPercentage: minimumRequiredPercentage ?? this.minimumRequiredPercentage,
    );
  }
}

/// Student's attendance record for a specific semester
class StudentSemesterAttendanceData {
  final int semesterNumber;
  final String semesterName;
  final int attendedWorkingDays;
  final int totalWorkingDays; // Configured by HOD
  final double monthlyTrendPercentage; // e.g. 5.0%
  final bool isCurrentSemester;
  final List<Map<String, dynamic>> subjectBreakdown;

  const StudentSemesterAttendanceData({
    required this.semesterNumber,
    required this.semesterName,
    required this.attendedWorkingDays,
    required this.totalWorkingDays,
    this.monthlyTrendPercentage = 5.0,
    this.isCurrentSemester = false,
    this.subjectBreakdown = const [],
  });

  /// Calculate semester-wise attendance percentage based on HOD working days
  double get attendancePercentage {
    if (totalWorkingDays <= 0) return 0.0;
    final pct = (attendedWorkingDays / totalWorkingDays) * 100.0;
    return pct > 100.0 ? 100.0 : pct;
  }

  /// Status badge label: Good, Safe Margin, Critical
  String get statusLabel {
    final pct = attendancePercentage;
    if (pct >= 85.0) return 'Good';
    if (pct >= 75.0) return 'Safe Margin';
    return 'Critical';
  }

  /// Safe margin days description
  String get safeMarginText {
    final pct = attendancePercentage;
    if (pct >= 85.0) return 'Safe Margin: Can skip up to 4 days';
    if (pct >= 75.0) return 'Warning: Attend next 3 classes!';
    return 'Shortage Alert: Below 75% requirement';
  }

  StudentSemesterAttendanceData copyWith({
    int? attendedWorkingDays,
    int? totalWorkingDays,
    double? monthlyTrendPercentage,
    bool? isCurrentSemester,
    List<Map<String, dynamic>>? subjectBreakdown,
  }) {
    return StudentSemesterAttendanceData(
      semesterNumber: semesterNumber,
      semesterName: semesterName,
      attendedWorkingDays: attendedWorkingDays ?? this.attendedWorkingDays,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      monthlyTrendPercentage: monthlyTrendPercentage ?? this.monthlyTrendPercentage,
      isCurrentSemester: isCurrentSemester ?? this.isCurrentSemester,
      subjectBreakdown: subjectBreakdown ?? this.subjectBreakdown,
    );
  }
}

/// Main state combining HOD semester configs and student semester attendance
class SemesterAttendanceState {
  final Map<int, SemesterWorkingDaysConfig> hodSemesterConfigs;
  final List<StudentSemesterAttendanceData> studentSemesters;
  final int selectedSemesterIndex;

  const SemesterAttendanceState({
    required this.hodSemesterConfigs,
    required this.studentSemesters,
    this.selectedSemesterIndex = 3, // Default Sem 4 (Active)
  });

  StudentSemesterAttendanceData get selectedSemesterData {
    if (selectedSemesterIndex >= 0 && selectedSemesterIndex < studentSemesters.length) {
      return studentSemesters[selectedSemesterIndex];
    }
    return studentSemesters.last;
  }

  StudentSemesterAttendanceData get activeSemesterData {
    return studentSemesters.firstWhere(
      (s) => s.isCurrentSemester,
      orElse: () => studentSemesters.last,
    );
  }

  SemesterAttendanceState copyWith({
    Map<int, SemesterWorkingDaysConfig>? hodSemesterConfigs,
    List<StudentSemesterAttendanceData>? studentSemesters,
    int? selectedSemesterIndex,
  }) {
    return SemesterAttendanceState(
      hodSemesterConfigs: hodSemesterConfigs ?? this.hodSemesterConfigs,
      studentSemesters: studentSemesters ?? this.studentSemesters,
      selectedSemesterIndex: selectedSemesterIndex ?? this.selectedSemesterIndex,
    );
  }
}

class SemesterAttendanceNotifier extends StateNotifier<SemesterAttendanceState> {
  SemesterAttendanceNotifier({UserModel? user}) : super(_buildInitialState(user));

  static SemesterAttendanceState _buildInitialState(UserModel? user) {
    final meta = user?.metadata ?? {};
    final double? dbAtt = double.tryParse(meta['attendance']?.toString() ?? '');
    final double targetAtt = dbAtt ?? 0.0;
    final int sem4Attended = ((targetAtt / 100.0) * 90).round();

    return SemesterAttendanceState(
      hodSemesterConfigs: {
        1: const SemesterWorkingDaysConfig(semesterNumber: 1, semesterName: 'Semester 1', totalWorkingDays: 90),
        2: const SemesterWorkingDaysConfig(semesterNumber: 2, semesterName: 'Semester 2', totalWorkingDays: 90),
        3: const SemesterWorkingDaysConfig(semesterNumber: 3, semesterName: 'Semester 3', totalWorkingDays: 95),
        4: const SemesterWorkingDaysConfig(semesterNumber: 4, semesterName: 'Semester 4', totalWorkingDays: 90),
        5: const SemesterWorkingDaysConfig(semesterNumber: 5, semesterName: 'Semester 5', totalWorkingDays: 90),
        6: const SemesterWorkingDaysConfig(semesterNumber: 6, semesterName: 'Semester 6', totalWorkingDays: 90),
        7: const SemesterWorkingDaysConfig(semesterNumber: 7, semesterName: 'Semester 7', totalWorkingDays: 85),
        8: const SemesterWorkingDaysConfig(semesterNumber: 8, semesterName: 'Semester 8', totalWorkingDays: 80),
      },
      studentSemesters: [
        for (int i = 1; i <= 8; i++)
          StudentSemesterAttendanceData(
            semesterNumber: i,
            semesterName: 'Semester $i',
            attendedWorkingDays: i == 4 ? sem4Attended : 0,
            totalWorkingDays: i == 3 ? 95 : (i == 7 ? 85 : (i == 8 ? 80 : 90)),
            monthlyTrendPercentage: 0.0,
            isCurrentSemester: i == 4,
            subjectBreakdown: const [],
          ),
      ],
      selectedSemesterIndex: 3,
    );
  }

  /// HOD updates total working days for a specific semester
  void updateSemesterWorkingDaysByHod(int semesterNumber, int newWorkingDays) {
    if (newWorkingDays <= 0) return;

    final updatedConfigs = Map<int, SemesterWorkingDaysConfig>.from(state.hodSemesterConfigs);
    if (updatedConfigs.containsKey(semesterNumber)) {
      updatedConfigs[semesterNumber] = updatedConfigs[semesterNumber]!.copyWith(totalWorkingDays: newWorkingDays);
    } else {
      updatedConfigs[semesterNumber] = SemesterWorkingDaysConfig(
        semesterNumber: semesterNumber,
        semesterName: 'Semester $semesterNumber',
        totalWorkingDays: newWorkingDays,
      );
    }

    final updatedStudentSemesters = state.studentSemesters.map((s) {
      if (s.semesterNumber == semesterNumber) {
        return s.copyWith(totalWorkingDays: newWorkingDays);
      }
      return s;
    }).toList();

    state = state.copyWith(
      hodSemesterConfigs: updatedConfigs,
      studentSemesters: updatedStudentSemesters,
    );
  }

  /// Change active selected semester tab/view
  void selectSemesterIndex(int index) {
    if (index >= 0 && index < state.studentSemesters.length) {
      state = state.copyWith(selectedSemesterIndex: index);
    }
  }

  /// Update student attended days
  void updateStudentAttendedDays(int semesterNumber, int newAttendedDays) {
    final updatedSemesters = state.studentSemesters.map((s) {
      if (s.semesterNumber == semesterNumber) {
        return s.copyWith(attendedWorkingDays: newAttendedDays);
      }
      return s;
    }).toList();

    state = state.copyWith(studentSemesters: updatedSemesters);
  }
}

final semesterAttendanceProvider =
    StateNotifierProvider<SemesterAttendanceNotifier, SemesterAttendanceState>(
  (ref) {
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    return SemesterAttendanceNotifier(user: user);
  },
);
