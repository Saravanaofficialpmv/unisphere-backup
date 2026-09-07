import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/services/storage_service.dart';

final marksImportServiceProvider = Provider<MarksImportService>((ref) {
  return MarksImportService();
});

class MarksPermissionException implements Exception {
  final String message;
  MarksPermissionException(this.message);
  @override
  String toString() => message;
}

class MarksValidationErrorItem {
  final int rowNumber;
  final String registerNumber;
  final String studentName;
  final String field;
  final String errorMessage;

  MarksValidationErrorItem({
    required this.rowNumber,
    required this.registerNumber,
    this.studentName = '',
    required this.field,
    required this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
        'rowNumber': rowNumber,
        'registerNumber': registerNumber,
        'studentName': studentName,
        'field': field,
        'errorMessage': errorMessage,
      };
}

class MarksValidationResult {
  final bool isValid;
  final int totalCount;
  final int successCount;
  final int errorCount;
  final List<Map<String, dynamic>> validRecords;
  final List<MarksValidationErrorItem> errors;

  MarksValidationResult({
    required this.isValid,
    required this.totalCount,
    required this.successCount,
    required this.errorCount,
    required this.validRecords,
    required this.errors,
  });

  bool get hasErrors => !isValid || errorCount > 0 || errors.isNotEmpty;
}

class MarksImportService {
  final FirebaseFirestore? _firestore;
  final StorageService _storageService;

  MarksImportService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore ?? _tryGetFirestore(),
        _storageService = storageService ?? StorageService();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Permission Check: Verifies whether the current user is authorized to manage the requested assessment
  static void verifyUploadPermission({
    required UserRole userRole,
    required String assessmentType,
    required String userDepartmentId,
    required String targetDepartmentId,
  }) {
    final cleanAssessment = assessmentType.toLowerCase().trim();
    final isFinalSemester = cleanAssessment == 'final_semester' || cleanAssessment.contains('final');

    if (isFinalSemester) {
      if (userRole != UserRole.hod && userRole != UserRole.admin) {
        throw MarksPermissionException(
          'ACCESS DENIED: Final Semester / University marks can only be uploaded and published by the Head of Department (HOD).',
        );
      }
    } else {
      // Internal, Retest, Model Exam, Assignment
      final isStaffOrAbove = userRole == UserRole.staff ||
          userRole == UserRole.advisor ||
          userRole == UserRole.hod ||
          userRole == UserRole.admin;

      if (!isStaffOrAbove) {
        throw MarksPermissionException(
          'ACCESS DENIED: You do not have faculty or HOD privileges to upload marks.',
        );
      }
    }
  }

  /// Validates a list of raw marks extracted from an Excel, CSV, or document template
  Future<MarksValidationResult> validateRecords({
    required List<Map<String, dynamic>> rawRecords,
    required double maxMarks,
    required String departmentId,
  }) async {
    final List<MarksValidationErrorItem> errors = [];
    final List<Map<String, dynamic>> validRecords = [];
    final Set<String> seenRegNumbers = {};

    for (int i = 0; i < rawRecords.length; i++) {
      final row = rawRecords[i];
      final rowNum = i + 1;

      final regNo = (row['regNo'] ?? row['registerNumber'] ?? row['studentId'] ?? '').toString().trim();
      final name = (row['name'] ?? row['studentName'] ?? row['fullName'] ?? 'Student').toString().trim();

      // 1. Validate Register Number
      if (regNo.isEmpty) {
        errors.add(MarksValidationErrorItem(
          rowNumber: rowNum,
          registerNumber: 'EMPTY',
          studentName: name,
          field: 'registerNumber',
          errorMessage: 'Register number cannot be empty.',
        ));
        continue;
      }

      if (regNo.length < 4 || !RegExp(r'^[a-zA-Z0-9]{4,20}$').hasMatch(regNo)) {
        errors.add(MarksValidationErrorItem(
          rowNumber: rowNum,
          registerNumber: regNo,
          studentName: name,
          field: 'registerNumber',
          errorMessage: 'Register number format "$regNo" is invalid. Must be at least 4 alphanumeric characters.',
        ));
        continue;
      }

      // 2. Check for duplicate register numbers within the same sheet
      final upperReg = regNo.toUpperCase();
      if (seenRegNumbers.contains(upperReg)) {
        errors.add(MarksValidationErrorItem(
          rowNumber: rowNum,
          registerNumber: regNo,
          studentName: name,
          field: 'registerNumber',
          errorMessage: 'Duplicate entry: Register Number "$regNo" appears multiple times in upload.',
        ));
        continue;
      }
      seenRegNumbers.add(upperReg);

      // 3. Validate Marks Range
      dynamic rawScore = row['initial'] ?? row['obtained'] ?? row['marks'] ?? row['score'] ?? row['obtainedMarks'];
      double obtained = 0.0;
      if (rawScore is num) {
        obtained = rawScore.toDouble();
      } else if (rawScore != null) {
        final parsed = double.tryParse(rawScore.toString().split('/')[0].trim());
        if (parsed != null) {
          obtained = parsed;
        } else {
          errors.add(MarksValidationErrorItem(
            rowNumber: rowNum,
            registerNumber: regNo,
            studentName: name,
            field: 'obtainedMarks',
            errorMessage: 'Invalid marks format "$rawScore". Must be a numeric value.',
          ));
          continue;
        }
      }

      if (obtained < 0.0) {
        errors.add(MarksValidationErrorItem(
          rowNumber: rowNum,
          registerNumber: regNo,
          studentName: name,
          field: 'obtainedMarks',
          errorMessage: 'Marks cannot be negative (obtained $obtained).',
        ));
        continue;
      }

      if (obtained > maxMarks) {
        errors.add(MarksValidationErrorItem(
          rowNumber: rowNum,
          registerNumber: regNo,
          studentName: name,
          field: 'obtainedMarks',
          errorMessage: 'Obtained marks ($obtained) exceeds maximum allowed marks ($maxMarks).',
        ));
        continue;
      }

      // Record is valid
      final recordCopy = Map<String, dynamic>.from(row);
      recordCopy['validatedRegNo'] = upperReg;
      recordCopy['validatedObtained'] = obtained;
      recordCopy['validatedMax'] = maxMarks;
      validRecords.add(recordCopy);
    }

    return MarksValidationResult(
      isValid: errors.isEmpty,
      totalCount: rawRecords.length,
      successCount: validRecords.length,
      errorCount: errors.length,
      validRecords: validRecords,
      errors: errors,
    );
  }

  /// Full Document Import Pipeline
  Future<MarksDocumentModel> importMarksDocument({
    File? file,
    Uint8List? fileBytes,
    required String fileName,
    required String fileType,
    required String departmentId,
    String departmentName = 'Computer Science & Engineering',
    required String courseCode,
    required String subjectName,
    required String assessmentType, // 'internal_1', 'internal_2', 'model', 'retest', 'assignment', 'final_semester'
    String academicYear = '2025–26',
    required int semester,
    required UserModel currentUser,
    required List<Map<String, dynamic>> records,
    double maximumMarks = 50.0,
    double weightage = 15.0,
  }) async {
    // 1. Strict Permission Check
    verifyUploadPermission(
      userRole: currentUser.role,
      assessmentType: assessmentType,
      userDepartmentId: currentUser.departmentId ?? departmentId,
      targetDepartmentId: departmentId,
    );

    final cleanAssessment = assessmentType.toLowerCase().trim();
    final docId = 'doc_${departmentId}_${courseCode}_${cleanAssessment}_${DateTime.now().millisecondsSinceEpoch}'.toLowerCase();
    final storagePath = 'academic_documents/marks/$departmentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // 2. Upload file to Firebase Storage if provided
    String uploadedUrl = '';
    if (file != null && file.existsSync()) {
      final url = await _storageService.uploadFile(storagePath: storagePath, file: file);
      uploadedUrl = url ?? '';
    } else if (fileBytes != null && fileBytes.isNotEmpty) {
      final mime = fileType == 'pdf' ? 'application/pdf' : 'application/octet-stream';
      final url = await _storageService.uploadData(storagePath: storagePath, data: fileBytes, mimeType: mime);
      uploadedUrl = url ?? '';
    }

    // 3. Validate Records
    final validation = await validateRecords(
      rawRecords: records,
      maxMarks: maximumMarks,
      departmentId: departmentId,
    );

    final firestore = _firestore;
    final now = DateTime.now();

    final docModel = MarksDocumentModel(
      documentId: docId,
      institutionId: currentUser.metadata?['institutionId']?.toString() ?? 'default_institution',
      departmentId: departmentId,
      departmentName: departmentName,
      subjectId: courseCode,
      courseCode: courseCode,
      subjectName: subjectName,
      assessmentType: cleanAssessment,
      academicYear: academicYear,
      semester: semester,
      uploadedBy: currentUser.uid,
      uploadedByRole: currentUser.role == UserRole.hod ? 'hod' : 'staff',
      uploadedByName: currentUser.fullName,
      fileName: fileName,
      fileType: fileType,
      fileSize: file?.existsSync() == true ? file!.lengthSync() : (fileBytes?.length ?? 0),
      storagePath: uploadedUrl.isNotEmpty ? uploadedUrl : storagePath,
      processingStatus: validation.errors.isEmpty ? 'completed' : (validation.validRecords.isNotEmpty ? 'partial_success' : 'failed'),
      validationStatus: validation.errors.isEmpty ? 'valid' : 'has_errors',
      recordCount: records.length,
      successCount: validation.successCount,
      errorCount: validation.errorCount,
      validationErrors: validation.errors.map((e) => e.toMap()).toList(),
      createdAt: now,
      updatedAt: now,
    );

    if (firestore != null) {
      // 4. Save metadata to marks_documents/{docId}
      await firestore.collection('marks_documents').doc(docId).set(docModel.toMap(), SetOptions(merge: true));

      // 5. Save valid normalized records into canonical marks/{markId}
      final batch = firestore.batch();
      for (final v in validation.validRecords) {
        final regNo = v['validatedRegNo'] as String;
        final obt = v['validatedObtained'] as double;
        final maxM = v['validatedMax'] as double;
        final conv = (maxM > 0) ? (obt / maxM) * weightage : 0.0;

        final markDocId = 'mark_${departmentId}_${regNo}_${courseCode}_${cleanAssessment}_sem$semester'.toLowerCase();
        final markRef = firestore.collection('marks').doc(markDocId);

        final isRetest = cleanAssessment.contains('retest') || v['isRetest'] == true;
        final grade = _computeGrade(obt, maxM);

        final markData = {
          'id': markDocId,
          'markId': markDocId,
          'student_uid': regNo,
          'studentUid': regNo,
          'register_number': regNo,
          'registerNumber': regNo,
          'student_name': v['name'] ?? 'Student',
          'studentName': v['name'] ?? 'Student',
          'subject_name': subjectName,
          'subjectName': subjectName,
          'course_code': courseCode,
          'courseCode': courseCode,
          'department_id': departmentId,
          'departmentId': departmentId,
          'assessment_type': cleanAssessment,
          'assessmentType': cleanAssessment,
          'exam_type': cleanAssessment,
          'examType': cleanAssessment,
          'obtained_marks': obt.toInt(),
          'obtainedMarks': obt.toInt(),
          'total_marks': maxM.toInt(),
          'totalMarks': maxM.toInt(),
          'maximumMarks': maxM,
          'weightage': weightage,
          'convertedScore': double.parse(conv.toStringAsFixed(1)),
          'isRetest': isRetest,
          'initialScore': v['initial']?.toString(),
          'retestScore': v['retest']?.toString(),
          'retestStatus': v['status']?.toString(),
          'grade': grade,
          'status': 'published',
          'documentId': docId,
          'enteredBy': currentUser.uid,
          'enteredByRole': currentUser.role.name,
          'academicYear': academicYear,
          'semester': semester,
          'updated_at': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        batch.set(markRef, markData, SetOptions(merge: true));
      }

      await batch.commit();

      // 6. Update derived academic_performance for quick dashboard views
      final firestoreService = FirebaseFirestoreService();
      for (final v in validation.validRecords) {
        final regNo = v['validatedRegNo'] as String;
        final obt = v['validatedObtained'] as double;
        final maxM = v['validatedMax'] as double;

        try {
          final subData = {
            'code': courseCode,
            'name': subjectName,
            'faculty': currentUser.fullName,
            if (cleanAssessment.contains('ia1') || cleanAssessment == 'internal_1') ...{
              'ia1': '${obt.toInt()} / ${maxM.toInt()}',
              'ia1Conv': '${((obt / maxM) * 15.0).toStringAsFixed(1)} / 15',
            },
            if (cleanAssessment.contains('ia2') || cleanAssessment == 'internal_2') ...{
              'ia2': '${obt.toInt()} / ${maxM.toInt()}',
              'ia2Conv': '${((obt / maxM) * 15.0).toStringAsFixed(1)} / 15',
            },
            if (cleanAssessment.contains('model')) ...{
              'modelExam': '${obt.toInt()} / ${maxM.toInt()}',
              'modelConv': '${((obt / maxM) * 20.0).toStringAsFixed(1)} / 20',
            },
            if (cleanAssessment.contains('final')) ...{
              'finalSemester': '${obt.toInt()} / ${maxM.toInt()}',
              'grade': _computeGrade(obt, maxM),
            },
            'status': 'Live Verified in Firebase',
          };

          await firestoreService.uploadStudentAcademicPerformance(
            regNo: regNo,
            studentName: v['name']?.toString(),
            department: departmentName,
            semesterIndex: semester > 0 ? semester - 1 : 5,
            subjects: [subData],
          );
        } catch (_) {}
      }
    }

    return docModel;
  }

  static String _computeGrade(double obtained, double max) {
    if (max <= 0) return 'O';
    final pct = obtained / max;
    if (pct >= 0.90) return 'O (Outstanding)';
    if (pct >= 0.80) return 'A+ (Excellent)';
    if (pct >= 0.70) return 'A (Very Good)';
    if (pct >= 0.60) return 'B+ (Good)';
    if (pct >= 0.50) return 'B (Above Average)';
    return 'RA (Re-Appear)';
  }
}
