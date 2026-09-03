import 'package:flutter/foundation.dart';
import 'package:unisphere/models/academic_record_model.dart';
import 'package:unisphere/repositories/academic_record_repository.dart';

class AcademicRecordService {
  final AcademicRecordRepository _repository;

  AcademicRecordService({AcademicRecordRepository? repository})
      : _repository = repository ?? AcademicRecordRepository();

  /// Watch real-time academic records stream for a student
  Stream<List<AcademicRecord>> watchStudentRecords(
    String studentId, {
    String institutionId = 'default_institution',
  }) {
    return _repository.watchStudentAcademicRecords(
      studentId: studentId,
      institutionId: institutionId,
    );
  }

  /// One-time lookup of student records
  Future<List<AcademicRecord>> getStudentRecords(
    String studentId, {
    String institutionId = 'default_institution',
  }) {
    return _repository.getStudentAcademicRecords(
      studentId: studentId,
      institutionId: institutionId,
    );
  }

  /// Validate and publish an assessment component or entire subject mark record
  Future<bool> publishSubjectAcademicRecord({
    required String studentId,
    required String institutionId,
    required String academicYear,
    required int semester,
    required String courseCode,
    required String courseName,
    String? facultyId,
    required String facultyName,
    required String departmentId,
    required Map<String, AssessmentComponent> components,
    RetestResult? retest,
    String? remarks,
    required String updatedBy,
  }) async {
    // 1. Validation
    if (studentId.trim().isEmpty) {
      debugPrint('Validation failed: Student ID cannot be empty.');
      return false;
    }
    if (courseCode.trim().isEmpty) {
      debugPrint('Validation failed: Course Code cannot be empty.');
      return false;
    }
    if (semester < 1 || semester > 12) {
      debugPrint('Validation failed: Invalid semester $semester.');
      return false;
    }

    // Validate each component obtained <= max and >= 0
    for (final entry in components.entries) {
      final comp = entry.value;
      if (comp.obtained < 0 || comp.obtained > comp.max) {
        debugPrint('Validation failed for component ${entry.key}: obtained (${comp.obtained}) must be between 0 and max (${comp.max}).');
        return false;
      }
    }

    // 2. Compute internal marks and grade via institution calculation engine
    final totalInternal = AcademicCalculationEngine.calculateTotalInternalMarks(components);
    final internalSummary = InternalMarksSummary(obtained: totalInternal, max: AcademicCalculationEngine.maxInternalMarks);
    final grade = AcademicCalculationEngine.calculateGrade(totalInternal);

    final record = AcademicRecord(
      id: '${courseCode.toUpperCase()}_sem$semester'.toLowerCase(),
      studentId: studentId.trim(),
      institutionId: institutionId.trim(),
      academicYear: academicYear.trim(),
      semester: semester,
      courseCode: courseCode.toUpperCase().trim(),
      courseName: courseName.trim(),
      facultyId: facultyId,
      facultyName: facultyName.trim(),
      departmentId: departmentId.toUpperCase().trim(),
      assessmentComponents: components,
      internalMarks: internalSummary,
      retest: retest,
      grade: grade,
      remarks: remarks,
      status: 'Live Verified in Firebase',
      updatedAt: DateTime.now(),
      updatedBy: updatedBy,
    );

    return _repository.saveAcademicRecord(record);
  }

  /// Validate and batch upload academic records
  Future<bool> uploadBatchAcademicRecords(List<AcademicRecord> records) async {
    if (records.isEmpty) return true;
    for (final r in records) {
      if (r.studentId.isEmpty || r.courseCode.isEmpty) return false;
    }
    return _repository.batchSaveAcademicRecords(records);
  }
}
