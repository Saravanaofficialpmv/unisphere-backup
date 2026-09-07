import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/services/marks_import_service.dart';

void main() {
  group('Marks Document & Normalized Marks Architecture Tests', () {
    test('1. MarksDocumentModel serializes and deserializes accurately with audit metadata', () {
      final now = DateTime.now();
      final doc = MarksDocumentModel(
        documentId: 'doc-cse-2025-001',
        institutionId: 'inst-srm-01',
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        subjectId: 'SUB-CS301',
        courseCode: 'CS301',
        subjectName: 'Distributed Systems',
        assessmentType: MarksDocumentModel.typeInternal1,
        academicYear: '2025–26',
        semester: 6,
        uploadedBy: 'USER-STAFF-01',
        uploadedByRole: 'staff',
        uploadedByName: 'Dr. Arun Kumar',
        fileName: 'CS301_IA1_Marks.xlsx',
        fileType: 'xlsx',
        fileSize: 45200,
        storagePath: 'academic_documents/marks/DEP-CSE/CS301_IA1_Marks.xlsx',
        processingStatus: 'completed',
        validationStatus: 'valid',
        recordCount: 65,
        successCount: 65,
        errorCount: 0,
        createdAt: now,
      );

      final map = doc.toMap();
      expect(map['documentId'], 'doc-cse-2025-001');
      expect(map['departmentId'], 'DEP-CSE');
      expect(map['assessmentType'], MarksDocumentModel.typeInternal1);
      expect(map['recordCount'], 65);
      expect(map['successCount'], 65);
      expect(map['errorCount'], 0);
      expect(doc.isFinalSemester, isFalse);
      expect(doc.hasErrors, isFalse);
      expect(doc.validRecordsCount, 65);

      final reconstructed = MarksDocumentModel.fromMap(map, 'doc-cse-2025-001');
      expect(reconstructed.documentId, 'doc-cse-2025-001');
      expect(reconstructed.courseCode, 'CS301');
      expect(reconstructed.uploadedByName, 'Dr. Arun Kumar');
      expect(reconstructed.recordCount, 65);
    });

    test('2. MarkModel maintains normalized schema while supporting legacy getters', () {
      final now = DateTime.now();
      final mark = MarkModel(
        id: 'mark-001',
        studentUid: 'STUD-917721104089',
        registerNumber: '917721104089',
        studentName: 'Sneha Murali',
        courseCode: 'CS301',
        subjectName: 'Distributed Systems',
        examType: 'internal_1',
        assessmentType: 'internal_1',
        obtainedMarks: 48,
        totalMarks: 50,
        maximumMarks: 50.0,
        grade: 'O',
        status: 'Pass',
        documentId: 'doc-cse-2025-001',
        updatedAt: now,
      );

      // Verify normalized fields and legacy aliases
      expect(mark.id, 'mark-001');
      expect(mark.studentUid, 'STUD-917721104089');
      expect(mark.registerNumber, '917721104089');
      expect(mark.regNo, '917721104089'); // legacy alias
      expect(mark.courseCode, 'CS301');
      expect(mark.obtainedMarks, 48);
      expect(mark.totalMarks, 50);
      expect(mark.maximumMarks, 50.0);
      expect(mark.grade, 'O');
      expect(mark.documentId, 'doc-cse-2025-001');

      final map = mark.toMap();
      expect(map['studentUid'], 'STUD-917721104089');
      expect(map['registerNumber'], '917721104089');
      expect(map['regNo'], '917721104089');
      expect(map['documentId'], 'doc-cse-2025-001');

      final reconstructed = MarkModel.fromMap(map, 'mark-001');
      expect(reconstructed.studentUid, 'STUD-917721104089');
      expect(reconstructed.obtainedMarks, 48);
    });

    test('3. Staff is strictly blocked from uploading Final Semester marks', () {
      // Staff trying to upload Final Semester
      expect(
        () => MarksImportService.verifyUploadPermission(
          userRole: UserRole.staff,
          assessmentType: MarksDocumentModel.typeFinalSemester,
          userDepartmentId: 'DEP-CSE',
          targetDepartmentId: 'DEP-CSE',
        ),
        throwsA(isA<MarksPermissionException>().having(
          (e) => e.message,
          'message',
          contains('Head of Department (HOD)'),
        )),
      );

      // Staff uploading Internal 1 -> Allowed without exception
      expect(
        () => MarksImportService.verifyUploadPermission(
          userRole: UserRole.staff,
          assessmentType: MarksDocumentModel.typeInternal1,
          userDepartmentId: 'DEP-CSE',
          targetDepartmentId: 'DEP-CSE',
        ),
        returnsNormally,
      );

      // Staff uploading Model Exam -> Allowed without exception
      expect(
        () => MarksImportService.verifyUploadPermission(
          userRole: UserRole.staff,
          assessmentType: MarksDocumentModel.typeModel,
          userDepartmentId: 'DEP-CSE',
          targetDepartmentId: 'DEP-CSE',
        ),
        returnsNormally,
      );
    });

    test('4. HOD and Admin are authorized to upload Final Semester marks', () {
      expect(
        () => MarksImportService.verifyUploadPermission(
          userRole: UserRole.hod,
          assessmentType: MarksDocumentModel.typeFinalSemester,
          userDepartmentId: 'DEP-CSE',
          targetDepartmentId: 'DEP-CSE',
        ),
        returnsNormally,
      );

      expect(
        () => MarksImportService.verifyUploadPermission(
          userRole: UserRole.admin,
          assessmentType: MarksDocumentModel.typeFinalSemester,
          userDepartmentId: 'DEP-ADMIN',
          targetDepartmentId: 'DEP-CSE',
        ),
        returnsNormally,
      );
    });

    test('5. Record validation catches invalid register numbers and out-of-bound marks', () async {
      final service = MarksImportService();

      final dirtyRecords = [
        // Valid record
        {'regNo': '917721104001', 'name': 'Aditya R', 'initial': '44/50'},
        // Invalid register number format (only 2 digits)
        {'regNo': '12', 'name': 'Invalid Reg', 'initial': '35/50'},
        // Obtained marks exceed maximum marks (55/50)
        {'regNo': '917721104002', 'name': 'Overflow Marks', 'initial': '55/50'},
        // Negative marks (-5/50)
        {'regNo': '917721104003', 'name': 'Negative Marks', 'initial': '-5/50'},
      ];

      final validation = await service.validateRecords(
        rawRecords: dirtyRecords,
        maxMarks: 50.0,
        departmentId: 'DEP-CSE',
      );

      expect(validation.validRecords.length, 1);
      expect(validation.errors.length, 3);
      expect(validation.hasErrors, isTrue);

      final errorDescriptions = validation.errors.map((e) => e.errorMessage).toList();
      expect(errorDescriptions.any((msg) => msg.contains('Register number format')), isTrue);
      expect(errorDescriptions.any((msg) => msg.contains('exceeds maximum')), isTrue);
      expect(errorDescriptions.any((msg) => msg.contains('cannot be negative')), isTrue);
    });
  });
}
