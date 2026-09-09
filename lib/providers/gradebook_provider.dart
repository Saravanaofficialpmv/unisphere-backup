import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/academic_record_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/repositories/academic_record_repository.dart';
import 'package:unisphere/services/auth_service.dart';

// ── VSBEC GRADE SERVICE & UTILS ─────────────────────────────────────────────

class VsbecGradeCalculator {
  /// Returns grade point for VSBEC grading scale:
  /// O = 10, A+ = 9, A = 8, B+ = 7, B = 6, C = 5
  /// RA, SA, W are EXCLUDED (returns null).
  static double? getGradePoint(String grade) {
    switch (grade.toUpperCase().trim()) {
      case 'O':
        return 10.0;
      case 'A+':
        return 9.0;
      case 'A':
        return 8.0;
      case 'B+':
        return 7.0;
      case 'B':
        return 6.0;
      case 'C':
        return 5.0;
      case 'RA':
      case 'SA':
      case 'W':
      default:
        return null;
    }
  }

  static bool isExcludedGrade(String grade) {
    return getGradePoint(grade) == null;
  }

  static String getGradeDisplay(String grade) {
    final gp = getGradePoint(grade);
    if (gp != null) {
      return '$grade (${gp.toInt()})';
    }
    switch (grade.toUpperCase().trim()) {
      case 'RA':
        return 'RA (Re-Appear)';
      case 'SA':
        return 'SA (Shortage Att.)';
      case 'W':
        return 'W (Withdrawn)';
      default:
        return '$grade (Excluded)';
    }
  }
}

// ── DATA MODELS ─────────────────────────────────────────────────────────────

class SubjectModel {
  String id;
  String name;
  String code;
  int credits;
  String grade; // O, A+, A, B+, B, C, RA, SA, W
  String faculty;
  String internalMarks;
  String quizMarks;
  String examMarks;
  String totalMarks;
  String remarks;

  SubjectModel({
    String? id,
    required this.name,
    required this.code,
    required this.credits,
    required this.grade,
    this.faculty = 'Prof. Academic Lead',
    this.internalMarks = '18/20',
    this.quizMarks = '9/10',
    this.examMarks = '45/50',
    this.totalMarks = '72/80',
    this.remarks = 'Good conceptual understanding & lab performance.',
  }) : id = id ?? '${code}_${DateTime.now().millisecondsSinceEpoch}';

  double? get gradePoint => VsbecGradeCalculator.getGradePoint(grade);

  bool get isExcluded => VsbecGradeCalculator.isExcludedGrade(grade);

  bool get isPassed => gradePoint != null && gradePoint! >= 5.0;

  double get weightedPoints {
    final gp = gradePoint;
    if (gp == null) return 0.0;
    return credits * gp;
  }

  SubjectModel copyWith({
    String? name,
    String? code,
    int? credits,
    String? grade,
    String? faculty,
    String? internalMarks,
    String? quizMarks,
    String? examMarks,
    String? totalMarks,
    String? remarks,
  }) {
    return SubjectModel(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      credits: credits ?? this.credits,
      grade: grade ?? this.grade,
      faculty: faculty ?? this.faculty,
      internalMarks: internalMarks ?? this.internalMarks,
      quizMarks: quizMarks ?? this.quizMarks,
      examMarks: examMarks ?? this.examMarks,
      totalMarks: totalMarks ?? this.totalMarks,
      remarks: remarks ?? this.remarks,
    );
  }
}

class SemesterModel {
  int number;
  String name;
  List<SubjectModel> subjects;
  bool isCurrent;

  SemesterModel({
    required this.number,
    required this.name,
    required this.subjects,
    this.isCurrent = false,
  });

  /// Total credits of all registered subjects (including RA/SA/W)
  int get registeredCredits => subjects.fold(0, (sum, s) => sum + s.credits);

  /// Total credits of eligible subjects (EXCLUDING RA, SA, W)
  int get eligibleCredits =>
      subjects.where((s) => !s.isExcluded).fold(0, (sum, s) => sum + s.credits);

  /// Earned credits of passed subjects
  int get earnedCredits =>
      subjects.where((s) => s.isPassed).fold(0, (sum, s) => sum + s.credits);

  /// Sum of weighted grade points for eligible subjects
  double get totalWeightedPoints =>
      subjects.fold(0.0, (sum, s) => sum + s.weightedPoints);

  int get passedCount => subjects.where((s) => s.isPassed).length;

  int get failedCount => subjects.where((s) => s.grade == 'RA').length;

  int get excludedCount => subjects.where((s) => s.isExcluded).length;

  /// VSBEC SGPA Formula = Σ(Credit × Grade Point) / Σ(Eligible Credits)
  double get sgpa {
    int totalCreds = 0;
    double totalPoints = 0.0;

    for (var s in subjects) {
      final gp = s.gradePoint;
      if (gp == null) continue; // Excluded RA, SA, W
      totalCreds += s.credits;
      totalPoints += (s.credits * gp);
    }

    if (totalCreds == 0) return 0.0;
    return (totalPoints / totalCreds).clamp(0.0, 10.0);
  }

  SemesterModel copyWith({
    int? number,
    String? name,
    List<SubjectModel>? subjects,
    bool? isCurrent,
  }) {
    return SemesterModel(
      number: number ?? this.number,
      name: name ?? this.name,
      subjects: subjects ?? List.from(this.subjects),
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

// ── STATE MODEL ──────────────────────────────────────────────────────────────

class GradebookState {
  final List<SemesterModel> semesters;
  final int selectedSemesterIndex;

  GradebookState({
    required this.semesters,
    this.selectedSemesterIndex = 3,
  });

  /// VSBEC Credit-Weighted CGPA Formula =
  /// Σ(All Course Credits × All Course Grade Points) / Σ(All Eligible Course Credits)
  /// Excludes RA, SA, W.
  double get overallCgpa {
    int sumEligibleCredits = 0;
    double sumWeightedPoints = 0.0;

    for (var sem in semesters) {
      for (var sub in sem.subjects) {
        final gp = sub.gradePoint;
        if (gp == null) continue; // Exclude RA, SA, W
        sumEligibleCredits += sub.credits;
        sumWeightedPoints += (sub.credits * gp);
      }
    }

    if (sumEligibleCredits == 0) return 0.0;
    return (sumWeightedPoints / sumEligibleCredits).clamp(0.0, 10.0);
  }

  /// VSBEC Percentage Formula = CGPA × 10
  double get overallPercentage => overallCgpa * 10.0;

  int get overallEligibleCredits {
    return semesters.fold(0, (sum, sem) => sum + sem.eligibleCredits);
  }

  int get overallEarnedCredits {
    return semesters.fold(0, (sum, sem) => sum + sem.earnedCredits);
  }

  double get overallWeightedPoints {
    return semesters.fold(0.0, (sum, sem) => sum + sem.totalWeightedPoints);
  }

  double get currentSemSgpa {
    if (semesters.isEmpty) return 0.0;
    final idx = selectedSemesterIndex < semesters.length ? selectedSemesterIndex : 0;
    return semesters[idx].sgpa;
  }

  SemesterModel? get currentSemester {
    if (semesters.isEmpty) return null;
    final idx = selectedSemesterIndex < semesters.length ? selectedSemesterIndex : 0;
    return semesters[idx];
  }

  String get academicStanding {
    double cgpa = overallCgpa;
    if (cgpa >= 9.0) return 'First Class with Distinction';
    if (cgpa >= 7.5) return 'First Class';
    if (cgpa >= 6.0) return 'Second Class';
    if (cgpa >= 5.0) return 'Pass Class';
    return 'Re-Appear Required';
  }

  GradebookState copyWith({
    List<SemesterModel>? semesters,
    int? selectedSemesterIndex,
  }) {
    return GradebookState(
      semesters: semesters ?? this.semesters,
      selectedSemesterIndex: selectedSemesterIndex ?? this.selectedSemesterIndex,
    );
  }
}

// ── STATE NOTIFIER ───────────────────────────────────────────────────────────

class GradebookNotifier extends StateNotifier<GradebookState> {
  final AcademicRecordRepository _academicRepo = AcademicRecordRepository();
  StreamSubscription<List<AcademicRecord>>? _recordsSub;

  GradebookNotifier({UserModel? user}) : super(_initialState(user)) {
    _initStream(user);
  }

  void _initStream(UserModel? user) {
    if (user == null) return;
    final meta = user.metadata ?? <String, dynamic>{};
    final regNo = meta['registerNumber']?.toString().trim() ??
        meta['regNo']?.toString().trim() ??
        user.uid;

    if (regNo.isNotEmpty) {
      _recordsSub = _academicRepo.watchStudentAcademicRecords(studentId: regNo).listen((records) {
        if (records.isNotEmpty) {
          _mapRecordsToState(records);
        }
      }, onError: (_) {});
    }
  }

  void _mapRecordsToState(List<AcademicRecord> records) {
    final Map<int, List<SubjectModel>> semMap = {};
    for (int i = 1; i <= 8; i++) {
      semMap[i] = [];
    }

    for (final r in records) {
      final sem = r.semester;
      int credits = 3;
      if (r.courseName.toLowerCase().contains('lab')) {
        credits = 2;
      } else if (r.courseCode.startsWith('MA') || r.courseName.toLowerCase().contains('math')) {
        credits = 4;
      }

      final sub = SubjectModel(
        id: r.id.isNotEmpty ? r.id : '${r.courseCode}_sem$sem',
        name: r.courseName,
        code: r.courseCode,
        credits: credits,
        grade: r.grade.isNotEmpty ? r.grade : 'A',
        faculty: r.facultyName,
        internalMarks: r.internalMarks.display,
        examMarks: r.modelExam?.displayRaw ?? '45/50',
        totalMarks: '${r.internalMarks.obtained.toInt()}/${r.internalMarks.max.toInt()}',
        remarks: r.remarks ?? 'Good conceptual understanding & lab performance.',
      );
      semMap.putIfAbsent(sem, () => []).add(sub);
    }

    final newSemesters = semMap.entries.map((entry) {
      return SemesterModel(
        number: entry.key,
        name: 'Semester ${entry.key}',
        subjects: entry.value,
        isCurrent: entry.key == 4,
      );
    }).toList();

    state = state.copyWith(semesters: newSemesters);
  }

  @override
  void dispose() {
    _recordsSub?.cancel();
    super.dispose();
  }

  static GradebookState _initialState(UserModel? user) {
    final meta = user?.metadata ?? {};
    final double? dbCgpa = double.tryParse(meta['cgpa']?.toString() ?? '');
    final String sem4Grade = (dbCgpa ?? 0.0) >= 9.0 ? 'O' : ((dbCgpa ?? 0.0) >= 8.0 ? 'A+' : ((dbCgpa ?? 0.0) >= 7.0 ? 'A' : 'B+'));

    return GradebookState(
      selectedSemesterIndex: 3, // Default Sem 4 (Active Current Term)
      semesters: [
        SemesterModel(
          number: 1,
          name: 'Semester 1',
          subjects: [
            SubjectModel(name: 'Matrices and Calculus', code: 'MA3151', credits: 4, grade: 'A+'),
            SubjectModel(name: 'Engineering Physics', code: 'PH3151', credits: 3, grade: 'A'),
            SubjectModel(name: 'Engineering Chemistry', code: 'CY3151', credits: 3, grade: 'A+'),
            SubjectModel(name: 'Problem Solving and Python', code: 'GE3151', credits: 3, grade: 'O'),
            SubjectModel(name: 'Physics and Chemistry Lab', code: 'BS3171', credits: 2, grade: 'O'),
            SubjectModel(name: 'Python Programming Lab', code: 'GE3171', credits: 2, grade: 'O'),
          ],
        ),
        SemesterModel(
          number: 2,
          name: 'Semester 2',
          subjects: [
            SubjectModel(name: 'Statistics and Numerical Methods', code: 'MA3251', credits: 4, grade: 'A'),
            SubjectModel(name: 'Physics for Information Science', code: 'PH3256', credits: 3, grade: 'A+'),
            SubjectModel(name: 'Engineering Graphics', code: 'GE3251', credits: 4, grade: 'B+'),
            SubjectModel(name: 'Programming in C', code: 'CS3251', credits: 3, grade: 'O'),
            SubjectModel(name: 'Basic Electrical & Electronics', code: 'BE3251', credits: 3, grade: 'A'),
            SubjectModel(name: 'Programming in C Lab', code: 'CS3271', credits: 2, grade: 'O'),
          ],
        ),
        SemesterModel(
          number: 3,
          name: 'Semester 3',
          subjects: [
            SubjectModel(name: 'Discrete Mathematics', code: 'MA3354', credits: 4, grade: 'A+'),
            SubjectModel(name: 'Digital Principles and Computer Org', code: 'CS3351', credits: 4, grade: 'A'),
            SubjectModel(name: 'Data Structures', code: 'CS3301', credits: 3, grade: 'O'),
            SubjectModel(name: 'Object Oriented Programming', code: 'CS3391', credits: 3, grade: 'A+'),
            SubjectModel(name: 'Data Structures Lab', code: 'CS3311', credits: 2, grade: 'O'),
            SubjectModel(name: 'OOP Java Lab', code: 'CS3381', credits: 2, grade: 'O'),
          ],
        ),
        SemesterModel(
          number: 4,
          name: 'Semester 4',
          isCurrent: true,
          subjects: [
            SubjectModel(name: 'Design & Analysis of Algorithms', code: 'CS3401', credits: 4, grade: sem4Grade),
            SubjectModel(name: 'Database Management Systems', code: 'CS3492', credits: 3, grade: sem4Grade),
            SubjectModel(name: 'Operating Systems', code: 'CS3451', credits: 3, grade: sem4Grade),
            SubjectModel(name: 'Computer Networks', code: 'CS3491', credits: 3, grade: sem4Grade),
            SubjectModel(name: 'Environmental Sciences & Sustainability', code: 'GE3451', credits: 2, grade: 'A+'),
            SubjectModel(name: 'DBMS Laboratory', code: 'CS3461', credits: 2, grade: 'O'),
            SubjectModel(name: 'Operating Systems Laboratory', code: 'CS3481', credits: 2, grade: 'O'),
          ],
        ),
        SemesterModel(
          number: 5,
          name: 'Semester 5',
          subjects: [], // Awaiting marks
        ),
        SemesterModel(
          number: 6,
          name: 'Semester 6',
          subjects: [], // Awaiting marks
        ),
        SemesterModel(
          number: 7,
          name: 'Semester 7',
          subjects: [], // Awaiting marks
        ),
        SemesterModel(
          number: 8,
          name: 'Semester 8',
          subjects: [], // Awaiting marks
        ),
      ],
    );
  }

  void selectSemester(int index) {
    if (index >= 0 && index < state.semesters.length) {
      state = state.copyWith(selectedSemesterIndex: index);
    }
  }

  void addSemester(String name) {
    final nextNum = state.semesters.length + 1;
    final newSem = SemesterModel(
      number: nextNum,
      name: name,
      subjects: [],
    );
    state = state.copyWith(
      semesters: [...state.semesters, newSem],
      selectedSemesterIndex: state.semesters.length,
    );
  }

  void removeSemester(int index) {
    if (state.semesters.length <= 1) return;
    final newSemesters = List<SemesterModel>.from(state.semesters)..removeAt(index);
    final newIndex = state.selectedSemesterIndex >= newSemesters.length
        ? newSemesters.length - 1
        : state.selectedSemesterIndex;
    state = state.copyWith(
      semesters: newSemesters,
      selectedSemesterIndex: newIndex,
    );
  }

  void addSubjectToSemester(int semIndex, SubjectModel subject) {
    if (semIndex < 0 || semIndex >= state.semesters.length) return;
    final sem = state.semesters[semIndex];
    final updatedSubjects = [...sem.subjects, subject];
    final updatedSem = sem.copyWith(subjects: updatedSubjects);

    final updatedSemesters = List<SemesterModel>.from(state.semesters);
    updatedSemesters[semIndex] = updatedSem;

    state = state.copyWith(semesters: updatedSemesters);
  }

  void updateSubjectInSemester(int semIndex, SubjectModel updatedSubject) {
    if (semIndex < 0 || semIndex >= state.semesters.length) return;
    final sem = state.semesters[semIndex];
    final updatedSubjects = sem.subjects.map((s) {
      return s.id == updatedSubject.id ? updatedSubject : s;
    }).toList();

    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    final updatedSemesters = List<SemesterModel>.from(state.semesters);
    updatedSemesters[semIndex] = updatedSem;

    state = state.copyWith(semesters: updatedSemesters);
  }

  void removeSubjectFromSemester(int semIndex, String subjectId) {
    if (semIndex < 0 || semIndex >= state.semesters.length) return;
    final sem = state.semesters[semIndex];
    final updatedSubjects = sem.subjects.where((s) => s.id != subjectId).toList();

    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    final updatedSemesters = List<SemesterModel>.from(state.semesters);
    updatedSemesters[semIndex] = updatedSem;

    state = state.copyWith(semesters: updatedSemesters);
  }

  void resetToDefaults() {
    state = _initialState(null);
  }
}

// ── PROVIDER DECLARATION ─────────────────────────────────────────────────────

final gradebookProvider =
    StateNotifierProvider<GradebookNotifier, GradebookState>((ref) {
  final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
  return GradebookNotifier(user: user);
});
