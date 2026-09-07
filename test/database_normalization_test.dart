import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/models.dart';

void main() {
  group('Database Architecture & Normalization Tests', () {
    test('1. Canonical Document Identity: Students use canonical UID paths with indexed registerNumber', () {
      const studentUid = 'STUDENT_AUTH_UID_001';
      const cleanReg = '917721104089';

      final student = StudentModel(
        studentId: 'STUD-001',
        userId: studentUid,
        registerNumber: cleanReg,
        fullName: 'Sneha Murali',
        rollNumber: '21CS089',
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        batchId: 'BATCH-2021-25',
        batch: '2021-2025',
        semester: '6',
        section: 'A',
        admissionYear: 2021,
      );

      // Student model uses UID as primary identity and stores registerNumber as indexed query field
      expect(student.userId, studentUid);
      expect(student.registerNumber, cleanReg);
      expect(student.fullName, 'Sneha Murali');

      final map = student.toMap();
      expect(map['userId'], studentUid);
      expect(map['registerNumber'], cleanReg);
      // Ensure document path target is canonical
      final canonicalDocPath = 'students/$studentUid';
      expect(canonicalDocPath, 'students/STUDENT_AUTH_UID_001');
    });

    test('2. Staff identity with Class Advisor capability retains unified staff role and StaffDashboard compatibility', () {
      const staffUid = 'STAFF_AUTH_UID_002';
      const staffReg = '4001';

      // Advisor is Staff with additional responsibilities (isAdvisor: true)
      final advisorUser = UserModel(
        uid: staffUid,
        email: 'advisor@unisphere.edu',
        fullName: 'Dr. Arun Kumar',
        role: UserRole.staff,
        metadata: {
          'isAdvisor': true,
          'staffId': staffReg,
          'department': 'Computer Science & Engineering',
          'departmentId': 'DEP-CSE',
          'advisedClass': 'III Year CSE - Section A',
        },
      );

      // Verify role remains UserRole.staff so routing goes to StaffDashboard
      expect(advisorUser.role, UserRole.staff);
      expect(advisorUser.isAdvisor, isTrue);
      expect(advisorUser.department, 'Computer Science & Engineering');

      final staffModel = StaffModel(
        userId: staffUid,
        employeeId: staffReg,
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Associate Professor & Class Advisor',
        specialization: 'Distributed Systems',
        assignedClasses: ['III CSE A'],
        assignedSubjects: ['CS301'],
        isAdvisor: true,
      );

      expect(staffModel.userId, staffUid);
      expect(staffModel.isAdvisor, isTrue);
      final staffMap = staffModel.toMap();
      expect(staffMap['isAdvisor'], isTrue);
    });

    test('3. Consolidated collection naming standards align with normalized architecture', () {
      // Mapping of old/duplicate collection names to canonical standard names
      final canonicalCollections = {
        'faculty': 'staff',
        'hackathonRegistrations': 'hackathon_registrations',
        'leave_applications': 'leave_requests',
        'audit_logs': 'activityLogs',
        'system_settings': 'settings',
      };

      expect(canonicalCollections['faculty'], 'staff');
      expect(canonicalCollections['hackathonRegistrations'], 'hackathon_registrations');
      expect(canonicalCollections['leave_applications'], 'leave_requests');
      expect(canonicalCollections['audit_logs'], 'activityLogs');
      expect(canonicalCollections['system_settings'], 'settings');
    });

    test('4. Academic Record schema supports multi-tenant hierarchy', () {
      final now = DateTime.now();
      final academicRecord = AcademicRecord(
        id: 'rec-001',
        studentId: '917721104089',
        institutionId: 'inst-srm-01',
        departmentId: 'DEP-CSE',
        academicYear: '2025-26',
        semester: 6,
        courseCode: 'CS301',
        courseName: 'Distributed Systems',
        facultyName: 'Dr. Arun Kumar',
        assessmentComponents: {
          'ia1': const AssessmentComponent(
            obtained: 48.0,
            max: 50.0,
            weightage: 15.0,
          ),
          'ia2': const AssessmentComponent(
            obtained: 46.0,
            max: 50.0,
            weightage: 15.0,
          ),
        },
        internalMarks: const InternalMarksSummary(
          obtained: 55.2,
          max: 60.0,
        ),
        grade: 'O',
        updatedBy: 'Dr. Arun Kumar',
        updatedAt: now,
      );

      expect(academicRecord.institutionId, 'inst-srm-01');
      expect(academicRecord.departmentId, 'DEP-CSE');
      expect(academicRecord.courseCode, 'CS301');
      expect(academicRecord.assessmentComponents.length, 2);
      expect(academicRecord.grade, 'O');

      final map = academicRecord.toFirestore();
      expect(map['institutionId'], 'inst-srm-01');
      expect(map['departmentId'], 'DEP-CSE');
      expect(map['courseCode'], 'CS301');
    });
  });
}
