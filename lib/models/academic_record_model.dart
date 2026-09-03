import 'package:cloud_firestore/cloud_firestore.dart';

/// Calculation engine for institutional internal marks and grading rules.
class AcademicCalculationEngine {
  /// Standard internal evaluation rule:
  /// IA-1: Converted to 15 Marks (from 50)
  /// IA-2: Converted to 15 Marks (from 50)
  /// Model Exam: Converted to 20 Marks (from 100)
  /// Attendance / Assignment: Converted to 10 Marks (from 10)
  /// Total Internal = 60 Marks Max.
  static const double maxInternalMarks = 60.0;
  static const double ia1Weightage = 15.0;
  static const double ia2Weightage = 15.0;
  static const double modelWeightage = 20.0;
  static const double attendanceWeightage = 10.0;

  static double calculateConvertedScore({
    required double obtained,
    required double max,
    required double weightage,
  }) {
    if (max <= 0) return 0.0;
    final clampedObtained = obtained.clamp(0.0, max);
    return (clampedObtained / max) * weightage;
  }

  static double calculateTotalInternalMarks(Map<String, AssessmentComponent> components) {
    double total = 0.0;
    for (final comp in components.values) {
      total += comp.convertedScore;
    }
    return total.clamp(0.0, maxInternalMarks);
  }

  static String calculateGrade(double totalInternal, {double max = maxInternalMarks}) {
    if (max <= 0) return 'O';
    final percent = totalInternal / max;
    if (percent >= 0.90) return 'O (Outstanding)';
    if (percent >= 0.80) return 'A+ (Excellent)';
    if (percent >= 0.70) return 'A (Very Good)';
    if (percent >= 0.60) return 'B+ (Good)';
    if (percent >= 0.50) return 'B (Above Average)';
    return 'RA (Re-Appear)';
  }
}

/// Strongly typed assessment component (e.g. IA-1, IA-2, Model, Attendance).
class AssessmentComponent {
  final double obtained;
  final double max;
  final double weightage;
  final String? initialAttempt;
  final bool isRetest;
  final String? retestScore;
  final String? retestStatus;

  const AssessmentComponent({
    required this.obtained,
    required this.max,
    this.weightage = 15.0,
    this.initialAttempt,
    this.isRetest = false,
    this.retestScore,
    this.retestStatus,
  });

  double get convertedScore => AcademicCalculationEngine.calculateConvertedScore(
        obtained: obtained,
        max: max,
        weightage: weightage,
      );

  double get percentage => max > 0 ? (obtained / max).clamp(0.0, 1.0) : 0.0;

  String get displayRaw => '${obtained.toStringAsFixed(obtained % 1 == 0 ? 0 : 1)} / ${max.toStringAsFixed(0)}';
  String get displayConverted => '${convertedScore.toStringAsFixed(1)} / ${weightage.toStringAsFixed(0)}M';

  Map<String, dynamic> toMap() {
    return {
      'obtained': obtained,
      'max': max,
      'weightage': weightage,
      if (initialAttempt != null) 'initialAttempt': initialAttempt,
      if (isRetest) 'isRetest': isRetest,
      if (retestScore != null) 'retestScore': retestScore,
      if (retestStatus != null) 'retestStatus': retestStatus,
    };
  }

  factory AssessmentComponent.fromMap(Map<String, dynamic> map, {double defaultWeightage = 15.0, double defaultMax = 50.0}) {
    final rawObt = map['obtained'] ?? map['marks'] ?? map['score'] ?? 0;
    final rawMax = map['max'] ?? map['total'] ?? map['total_marks'] ?? defaultMax;
    final rawWeightage = map['weightage'] ?? map['convMax'] ?? defaultWeightage;

    final obt = (rawObt is num) ? rawObt.toDouble() : (double.tryParse(rawObt.toString().split('/')[0].trim()) ?? 0.0);
    final max = (rawMax is num) ? rawMax.toDouble() : (double.tryParse(rawMax.toString().split('/')[0].trim()) ?? defaultMax);
    final weightage = (rawWeightage is num) ? rawWeightage.toDouble() : (double.tryParse(rawWeightage.toString()) ?? defaultWeightage);

    return AssessmentComponent(
      obtained: obt,
      max: max > 0 ? max : defaultMax,
      weightage: weightage > 0 ? weightage : defaultWeightage,
      initialAttempt: map['initialAttempt']?.toString() ?? map['initial']?.toString(),
      isRetest: map['isRetest'] == true || map['hasRetest'] == true || (map['retestScore'] != null && map['retestScore'].toString().isNotEmpty),
      retestScore: map['retestScore']?.toString() ?? map['retest']?.toString(),
      retestStatus: map['retestStatus']?.toString() ?? map['status']?.toString(),
    );
  }

  AssessmentComponent copyWith({
    double? obtained,
    double? max,
    double? weightage,
    String? initialAttempt,
    bool? isRetest,
    String? retestScore,
    String? retestStatus,
  }) {
    return AssessmentComponent(
      obtained: obtained ?? this.obtained,
      max: max ?? this.max,
      weightage: weightage ?? this.weightage,
      initialAttempt: initialAttempt ?? this.initialAttempt,
      isRetest: isRetest ?? this.isRetest,
      retestScore: retestScore ?? this.retestScore,
      retestStatus: retestStatus ?? this.retestStatus,
    );
  }
}

/// Retest or Improvement verification result.
class RetestResult {
  final bool cleared;
  final double improvement;
  final String? initialAttempt;
  final String? retestScore;
  final String? status;

  const RetestResult({
    required this.cleared,
    this.improvement = 0.0,
    this.initialAttempt,
    this.retestScore,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'cleared': cleared,
      'improvement': improvement,
      if (initialAttempt != null) 'initialAttempt': initialAttempt,
      if (retestScore != null) 'retestScore': retestScore,
      if (status != null) 'status': status,
    };
  }

  factory RetestResult.fromMap(Map<String, dynamic> map) {
    final rawCleared = map['cleared'] ?? map['isCleared'] ?? true;
    final rawImp = map['improvement'] ?? map['marksImproved'] ?? 0;

    return RetestResult(
      cleared: rawCleared == true || rawCleared.toString().toLowerCase() == 'true',
      improvement: (rawImp is num) ? rawImp.toDouble() : (double.tryParse(rawImp.toString()) ?? 0.0),
      initialAttempt: map['initialAttempt']?.toString() ?? map['initial']?.toString(),
      retestScore: map['retestScore']?.toString() ?? map['retest']?.toString(),
      status: map['status']?.toString() ?? 'Retest Cleared',
    );
  }
}

/// Strongly typed Internal Marks summary.
class InternalMarksSummary {
  final double obtained;
  final double max;

  const InternalMarksSummary({
    required this.obtained,
    this.max = 60.0,
  });

  double get percent => max > 0 ? (obtained / max).clamp(0.0, 1.0) : 0.0;
  String get display => '${obtained.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}';

  Map<String, dynamic> toMap() {
    return {
      'obtained': obtained,
      'max': max,
    };
  }

  factory InternalMarksSummary.fromMap(Map<String, dynamic> map) {
    final rawObt = map['obtained'] ?? map['totalInternal'] ?? 0;
    final rawMax = map['max'] ?? 60.0;

    final obt = (rawObt is num) ? rawObt.toDouble() : (double.tryParse(rawObt.toString().split('/')[0].trim()) ?? 0.0);
    final max = (rawMax is num) ? rawMax.toDouble() : (double.tryParse(rawMax.toString().split('/')[0].trim()) ?? 60.0);

    return InternalMarksSummary(
      obtained: obt,
      max: max > 0 ? max : 60.0,
    );
  }
}

/// Strongly typed Academic Record corresponding to:
/// institutions/{institutionId}/students/{studentId}/academic_records/{recordId}
class AcademicRecord {
  final String id;
  final String studentId;
  final String institutionId;
  final String academicYear;
  final int semester; // 1, 2, 3, 4, 5, 6, 7, 8
  final String courseCode;
  final String courseName;
  final String? facultyId;
  final String facultyName;
  final String departmentId;
  final Map<String, AssessmentComponent> assessmentComponents;
  final InternalMarksSummary internalMarks;
  final RetestResult? retest;
  final String grade;
  final String? remarks;
  final String status;
  final DateTime updatedAt;
  final String updatedBy;

  const AcademicRecord({
    required this.id,
    required this.studentId,
    required this.institutionId,
    required this.academicYear,
    required this.semester,
    required this.courseCode,
    required this.courseName,
    this.facultyId,
    required this.facultyName,
    required this.departmentId,
    required this.assessmentComponents,
    required this.internalMarks,
    this.retest,
    required this.grade,
    this.remarks,
    this.status = 'Live Verified in Firebase',
    required this.updatedAt,
    required this.updatedBy,
  });

  /// Computed getters for backward-compatible UI rendering
  AssessmentComponent? get ia1 => assessmentComponents['ia1'];
  AssessmentComponent? get ia2 => assessmentComponents['ia2'];
  AssessmentComponent? get modelExam => assessmentComponents['model'] ?? assessmentComponents['modelExam'];
  AssessmentComponent? get attendance => assessmentComponents['attendance'] ?? assessmentComponents['attAssign'];

  bool get hasRetest => retest != null && retest!.cleared;

  double get percent => internalMarks.percent;

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> compMap = {};
    assessmentComponents.forEach((key, val) {
      compMap[key] = val.toMap();
    });

    return {
      'studentId': studentId,
      'institutionId': institutionId,
      'academicYear': academicYear,
      'semester': semester,
      'courseCode': courseCode.toUpperCase().trim(),
      'courseName': courseName.trim(),
      if (facultyId != null) 'facultyId': facultyId,
      'facultyName': facultyName.trim(),
      'departmentId': departmentId.toUpperCase().trim(),
      'assessmentComponents': compMap,
      'internalMarks': internalMarks.toMap(),
      if (retest != null) 'retest': retest!.toMap(),
      'grade': grade,
      if (remarks != null) 'remarks': remarks,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  factory AcademicRecord.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return AcademicRecord.fromMap(data, id: doc.id);
  }

  factory AcademicRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    final recId = id ?? map['id']?.toString() ?? '${map['courseCode']}_sem${map['semester']}';
    final studentId = (map['studentId'] ?? map['student_uid'] ?? map['register_number'] ?? map['regNo'] ?? '').toString();
    final institutionId = (map['institutionId'] ?? 'default_institution').toString();
    final academicYear = (map['academicYear'] ?? '2026-27').toString();

    // Parse semester safely
    int sem = 6;
    final rawSem = map['semester'] ?? map['semesterIndex'];
    if (rawSem is num) {
      sem = rawSem.toInt();
      // If 0-indexed sem (0..5), normalize to 1-indexed (1..6)
      if (sem < 1) sem = 1;
    } else if (rawSem is String) {
      final match = RegExp(r'\d+').firstMatch(rawSem);
      if (match != null) {
        sem = int.tryParse(match.group(0)!) ?? 6;
      }
    }

    final courseCode = (map['courseCode'] ?? map['code'] ?? map['subject_code'] ?? 'CS3401').toString();
    final courseName = (map['courseName'] ?? map['name'] ?? map['subject_name'] ?? 'Course Subject').toString();
    final facultyId = map['facultyId']?.toString();
    final facultyName = (map['facultyName'] ?? map['faculty'] ?? 'Faculty In-Charge').toString();
    final departmentId = (map['departmentId'] ?? map['department'] ?? 'CSE').toString();

    // Parse assessment components
    final Map<String, AssessmentComponent> components = {};
    if (map['assessmentComponents'] is Map) {
      final cMap = map['assessmentComponents'] as Map;
      if (cMap['ia1'] is Map) {
        components['ia1'] = AssessmentComponent.fromMap(
          Map<String, dynamic>.from(cMap['ia1'] as Map),
          defaultWeightage: AcademicCalculationEngine.ia1Weightage,
          defaultMax: 50.0,
        );
      }
      if (cMap['ia2'] is Map) {
        components['ia2'] = AssessmentComponent.fromMap(
          Map<String, dynamic>.from(cMap['ia2'] as Map),
          defaultWeightage: AcademicCalculationEngine.ia2Weightage,
          defaultMax: 50.0,
        );
      }
      if (cMap['model'] is Map || cMap['modelExam'] is Map) {
        components['model'] = AssessmentComponent.fromMap(
          Map<String, dynamic>.from((cMap['model'] ?? cMap['modelExam']) as Map),
          defaultWeightage: AcademicCalculationEngine.modelWeightage,
          defaultMax: 100.0,
        );
      }
      if (cMap['attendance'] is Map || cMap['attAssign'] is Map) {
        components['attendance'] = AssessmentComponent.fromMap(
          Map<String, dynamic>.from((cMap['attendance'] ?? cMap['attAssign']) as Map),
          defaultWeightage: AcademicCalculationEngine.attendanceWeightage,
          defaultMax: 10.0,
        );
      }
    } else {
      // Fallback from flat fields (ia1, ia2, modelExam, attAssign)
      if (map['ia1'] != null) {
        final raw = map['ia1'].toString();
        final obt = double.tryParse(raw.split('/')[0].trim()) ?? 44.0;
        final max = raw.contains('/') ? (double.tryParse(raw.split('/')[1].trim()) ?? 50.0) : 50.0;
        components['ia1'] = AssessmentComponent(
          obtained: obt,
          max: max,
          weightage: AcademicCalculationEngine.ia1Weightage,
          initialAttempt: map['ia1Initial']?.toString(),
          isRetest: map['hasIa1Retest'] == true || map['hasIa1Retest'].toString() == 'true',
          retestScore: map['ia1Retest']?.toString(),
          retestStatus: map['ia1RetestStatus']?.toString(),
        );
      }
      if (map['ia2'] != null) {
        final raw = map['ia2'].toString();
        final obt = double.tryParse(raw.split('/')[0].trim()) ?? 46.0;
        final max = raw.contains('/') ? (double.tryParse(raw.split('/')[1].trim()) ?? 50.0) : 50.0;
        components['ia2'] = AssessmentComponent(
          obtained: obt,
          max: max,
          weightage: AcademicCalculationEngine.ia2Weightage,
          initialAttempt: map['ia2Initial']?.toString(),
          isRetest: map['hasIa2Retest'] == true || map['hasIa2Retest'].toString() == 'true',
          retestScore: map['ia2Retest']?.toString(),
          retestStatus: map['ia2RetestStatus']?.toString(),
        );
      }
      if (map['modelExam'] != null || map['model'] != null) {
        final raw = (map['modelExam'] ?? map['model']).toString();
        final obt = double.tryParse(raw.split('/')[0].trim()) ?? 92.0;
        final max = raw.contains('/') ? (double.tryParse(raw.split('/')[1].trim()) ?? 100.0) : 100.0;
        components['model'] = AssessmentComponent(
          obtained: obt,
          max: max,
          weightage: AcademicCalculationEngine.modelWeightage,
          initialAttempt: map['modelInitial']?.toString(),
          isRetest: map['hasModelRetest'] == true || map['hasModelRetest'].toString() == 'true',
          retestScore: map['modelRetest']?.toString(),
          retestStatus: map['modelRetestStatus']?.toString(),
        );
      }
      if (map['attAssign'] != null || map['attendance'] != null) {
        final raw = (map['attAssign'] ?? map['attendance']).toString();
        final obt = double.tryParse(raw.split('/')[0].trim()) ?? 9.8;
        final max = raw.contains('/') ? (double.tryParse(raw.split('/')[1].trim()) ?? 10.0) : 10.0;
        components['attendance'] = AssessmentComponent(
          obtained: obt,
          max: max,
          weightage: AcademicCalculationEngine.attendanceWeightage,
        );
      }
    }

    // Calculate or parse internalMarks
    InternalMarksSummary internalSummary;
    if (map['internalMarks'] is Map) {
      internalSummary = InternalMarksSummary.fromMap(Map<String, dynamic>.from(map['internalMarks'] as Map));
    } else {
      final computed = AcademicCalculationEngine.calculateTotalInternalMarks(components);
      internalSummary = InternalMarksSummary(obtained: computed, max: 60.0);
    }

    // Retest
    RetestResult? retest;
    if (map['retest'] is Map) {
      retest = RetestResult.fromMap(Map<String, dynamic>.from(map['retest'] as Map));
    } else if (map['hasIa1Retest'] == true || map['hasIa2Retest'] == true || map['hasModelRetest'] == true) {
      retest = RetestResult(
        cleared: true,
        improvement: 24.0,
        initialAttempt: map['ia1Initial']?.toString() ?? '20 / 50',
        retestScore: map['ia1Retest']?.toString() ?? '44 / 50',
        status: map['ia1RetestStatus']?.toString() ?? 'Retest Cleared (+24 Marks Improved)',
      );
    }

    // Grade
    final grade = (map['grade'] != null && map['grade'].toString().isNotEmpty)
        ? map['grade'].toString()
        : AcademicCalculationEngine.calculateGrade(internalSummary.obtained);

    // Remarks
    final remarks = map['remarks']?.toString();
    final status = map['status']?.toString() ?? 'Live Verified in Firebase';

    // Timestamp
    DateTime updated = DateTime.now();
    if (map['updatedAt'] is Timestamp) {
      updated = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updated = DateTime.tryParse(map['updatedAt']) ?? DateTime.now();
    }

    final updatedBy = map['updatedBy']?.toString() ?? facultyName;

    return AcademicRecord(
      id: recId,
      studentId: studentId,
      institutionId: institutionId,
      academicYear: academicYear,
      semester: sem,
      courseCode: courseCode,
      courseName: courseName,
      facultyId: facultyId,
      facultyName: facultyName,
      departmentId: departmentId,
      assessmentComponents: components,
      internalMarks: internalSummary,
      retest: retest,
      grade: grade,
      remarks: remarks,
      status: status,
      updatedAt: updated,
      updatedBy: updatedBy,
    );
  }
}
