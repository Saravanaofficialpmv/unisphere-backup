import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/academic_record_model.dart';
import 'package:unisphere/repositories/academic_record_repository.dart';
import 'package:unisphere/services/academic_record_service.dart';

void main() {
  group('AcademicCalculationEngine Unit Tests', () {
    test('Standard scale converts correctly (IA-1=44/50 -> 13.2/15, IA-2=46/50 -> 13.8/15, Model=92/100 -> 18.4/20, Att=9.8/10 -> 9.8/10, Total=55.2/60)', () {
      const ia1 = AssessmentComponent(
        obtained: 44,
        max: 50,
        weightage: 15,
      );
      expect(ia1.convertedScore, closeTo(13.2, 0.01));
      expect(ia1.displayRaw, '44 / 50');
      expect(ia1.displayConverted, '13.2 / 15M');

      const ia2 = AssessmentComponent(
        obtained: 46,
        max: 50,
        weightage: 15,
      );
      expect(ia2.convertedScore, closeTo(13.8, 0.01));
      expect(ia2.displayRaw, '46 / 50');
      expect(ia2.displayConverted, '13.8 / 15M');

      const model = AssessmentComponent(
        obtained: 92,
        max: 100,
        weightage: 20,
      );
      expect(model.convertedScore, closeTo(18.4, 0.01));
      expect(model.displayRaw, '92 / 100');
      expect(model.displayConverted, '18.4 / 20M');

      const att = AssessmentComponent(
        obtained: 9.8,
        max: 10,
        weightage: 10,
      );
      expect(att.convertedScore, closeTo(9.8, 0.01));

      final components = <String, AssessmentComponent>{
        'ia1': ia1,
        'ia2': ia2,
        'model': model,
        'attendance': att,
      };

      final total = AcademicCalculationEngine.calculateTotalInternalMarks(components);
      expect(total, closeTo(55.2, 0.01));

      final grade = AcademicCalculationEngine.calculateGrade(total);
      expect(grade, 'O (Outstanding)');
    });

    test('Boundary and Grade mapping logic', () {
      expect(AcademicCalculationEngine.calculateGrade(58.0), 'O (Outstanding)'); // >= 90% (54.0)
      expect(AcademicCalculationEngine.calculateGrade(50.0), 'A+ (Excellent)'); // >= 80% (48.0)
      expect(AcademicCalculationEngine.calculateGrade(43.0), 'A (Very Good)'); // >= 70% (42.0)
      expect(AcademicCalculationEngine.calculateGrade(37.0), 'B+ (Good)'); // >= 60% (36.0)
      expect(AcademicCalculationEngine.calculateGrade(31.0), 'B (Above Average)'); // >= 50% (30.0)
      expect(AcademicCalculationEngine.calculateGrade(25.0), 'RA (Re-Appear)'); // < 50%
    });

    test('Retest calculation with improvement tracking', () {
      const compWithRetest = AssessmentComponent(
        obtained: 44,
        max: 50,
        weightage: 15,
        initialAttempt: '20 / 50',
        isRetest: true,
        retestScore: '44 / 50',
        retestStatus: 'Retest Cleared (+24 Marks Improved)',
      );

      expect(compWithRetest.isRetest, isTrue);
      expect(compWithRetest.initialAttempt, '20 / 50');
      expect(compWithRetest.retestScore, '44 / 50');
      expect(compWithRetest.retestStatus, 'Retest Cleared (+24 Marks Improved)');
      expect(compWithRetest.convertedScore, closeTo(13.2, 0.01));
    });
  });

  group('AcademicRecord Model Serialization Tests', () {
    test('Round-trip serialization toMap / fromMap produces identical values', () {
      final record = AcademicRecord(
        id: 'cs3401_sem4',
        studentId: '922523243079',
        institutionId: 'inst_anna_univ',
        academicYear: '2025-2026',
        semester: 4,
        courseCode: 'CS3401',
        courseName: 'Design & Analysis of Algorithms',
        facultyId: 'fac_ramanathan',
        facultyName: 'Dr. S. Ramanathan',
        departmentId: 'CSE',
        assessmentComponents: const {
          'ia1': AssessmentComponent(
            obtained: 44,
            max: 50,
            weightage: 15,
            initialAttempt: '20 / 50',
            isRetest: true,
            retestScore: '44 / 50',
            retestStatus: 'Retest Cleared (+24 Marks)',
          ),
          'ia2': AssessmentComponent(
            obtained: 46,
            max: 50,
            weightage: 15,
          ),
          'model': AssessmentComponent(
            obtained: 92,
            max: 100,
            weightage: 20,
          ),
          'attendance': AssessmentComponent(
            obtained: 9.8,
            max: 10,
            weightage: 10,
          ),
        },
        internalMarks: const InternalMarksSummary(obtained: 55.2, max: 60.0),
        retest: const RetestResult(
          cleared: true,
          improvement: 24,
          initialAttempt: '20 / 50',
          retestScore: '44 / 50',
          status: 'Retest Cleared (+24 Marks Improved)',
        ),
        grade: 'O (Outstanding)',
        remarks: 'Exceptional comeback in graph algorithms.',
        status: 'Live Verified in Firebase',
        updatedAt: DateTime(2026, 9, 3, 10, 0),
        updatedBy: 'Dr. S. Ramanathan',
      );

      final firestoreMap = record.toFirestore();
      expect(firestoreMap['studentId'], '922523243079');
      expect(firestoreMap['institutionId'], 'inst_anna_univ');
      expect(firestoreMap['semester'], 4);
      expect(firestoreMap['courseCode'], 'CS3401');
      expect(firestoreMap['courseName'], 'Design & Analysis of Algorithms');
      expect(firestoreMap['grade'], 'O (Outstanding)');
      expect(firestoreMap['internalMarks']['obtained'], 55.2);
      expect(firestoreMap['internalMarks']['max'], 60.0);

      final restored = AcademicRecord.fromMap(firestoreMap, id: 'cs3401_sem4');
      expect(restored.studentId, record.studentId);
      expect(restored.courseCode, 'CS3401');
      expect(restored.semester, 4);
      expect(restored.internalMarks.obtained, 55.2);
      expect(restored.internalMarks.display, '55.2 / 60');
      expect(restored.hasRetest, isTrue);
      expect(restored.ia1?.convertedScore, closeTo(13.2, 0.01));
      expect(restored.retest?.improvement, 24);
    });
  });

  group('AcademicRecordService Validation Tests', () {
    test('Rejects invalid negative marks or mark exceeding max', () async {
      final service = AcademicRecordService();

      final badComponentMap = <String, AssessmentComponent>{
        'ia1': const AssessmentComponent(
          obtained: 55, // Invalid: exceeds max of 50
          max: 50,
          weightage: 15,
        ),
      };

      final result = await service.publishSubjectAcademicRecord(
        studentId: '922523243079',
        institutionId: 'inst_01',
        academicYear: '2025-2026',
        semester: 4,
        courseCode: 'CS3401',
        courseName: 'Design & Analysis of Algorithms',
        facultyName: 'Dr. S. Ramanathan',
        departmentId: 'CSE',
        components: badComponentMap,
        updatedBy: 'Dr. S. Ramanathan',
      );

      expect(result, isFalse);
    });

    test('Rejects empty student ID or course code', () async {
      final service = AcademicRecordService();

      final result = await service.publishSubjectAcademicRecord(
        studentId: '',
        institutionId: 'inst_01',
        academicYear: '2025-2026',
        semester: 4,
        courseCode: '',
        courseName: 'Algorithms',
        facultyName: 'Dr. S. Ramanathan',
        departmentId: 'CSE',
        components: {},
        updatedBy: 'Staff',
      );

      expect(result, isFalse);
    });

    test('Validates and successfully delegates to repository when marks are valid', () async {
      final mockRepo = _MockAcademicRecordRepository();
      final service = AcademicRecordService(repository: mockRepo);

      final validComponents = <String, AssessmentComponent>{
        'ia1': const AssessmentComponent(obtained: 44, max: 50, weightage: 15),
        'ia2': const AssessmentComponent(obtained: 46, max: 50, weightage: 15),
        'model': const AssessmentComponent(obtained: 92, max: 100, weightage: 20),
        'attendance': const AssessmentComponent(obtained: 9.8, max: 10, weightage: 10),
      };

      final result = await service.publishSubjectAcademicRecord(
        studentId: '922523243079',
        institutionId: 'inst_anna_univ',
        academicYear: '2025-2026',
        semester: 4,
        courseCode: 'CS3401',
        courseName: 'Design & Analysis of Algorithms',
        facultyName: 'Dr. S. Ramanathan',
        departmentId: 'CSE',
        components: validComponents,
        updatedBy: 'Dr. S. Ramanathan',
      );

      expect(result, isTrue);
      expect(mockRepo.savedRecords.length, 1);
      final saved = mockRepo.savedRecords.first;
      expect(saved.studentId, '922523243079');
      expect(saved.courseCode, 'CS3401');
      expect(saved.internalMarks.obtained, closeTo(55.2, 0.01));
      expect(saved.grade, 'O (Outstanding)');
    });

    test('Batch upload validates records and delegates to batch repository', () async {
      final mockRepo = _MockAcademicRecordRepository();
      final service = AcademicRecordService(repository: mockRepo);

      final records = [
        AcademicRecord(
          id: 'cs3401_sem4',
          studentId: '922523243079',
          institutionId: 'inst_anna_univ',
          academicYear: '2025-2026',
          semester: 4,
          courseCode: 'CS3401',
          courseName: 'Design & Analysis of Algorithms',
          facultyName: 'Dr. S. Ramanathan',
          departmentId: 'CSE',
          assessmentComponents: const {},
          internalMarks: const InternalMarksSummary(obtained: 55.2, max: 60.0),
          grade: 'O (Outstanding)',
          status: 'Live Verified in Firebase',
          updatedAt: DateTime.now(),
          updatedBy: 'Staff',
        ),
      ];

      final success = await service.uploadBatchAcademicRecords(records);
      expect(success, isTrue);
      expect(mockRepo.batchSavedRecords.length, 1);
    });
  });
}

class _MockAcademicRecordRepository extends AcademicRecordRepository {
  final List<AcademicRecord> savedRecords = [];
  final List<AcademicRecord> batchSavedRecords = [];

  @override
  Future<bool> saveAcademicRecord(AcademicRecord record) async {
    savedRecords.add(record);
    return true;
  }

  @override
  Future<bool> batchSaveAcademicRecords(List<AcademicRecord> records) async {
    batchSavedRecords.addAll(records);
    return true;
  }
}
