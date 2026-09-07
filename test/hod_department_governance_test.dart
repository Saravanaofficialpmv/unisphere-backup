import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/screens/hod/hod_home_dashboard.dart';
import 'package:unisphere/screens/hod/modules/hod_student_management.dart';
import 'package:unisphere/screens/hod/modules/hod_staff_management.dart';
import 'package:unisphere/screens/hod/hod_shell.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('HOD Department Governance & Data Scoping Tests', () {
    test('1. DepartmentModel serialization and deserialization integrity', () {
      final dept = DepartmentModel(
        departmentId: 'DEP-AI-DS',
        name: 'Artificial Intelligence & Data Science',
        code: 'AI&DS',
        hodId: 'hod_123',
        hodName: 'Dr. S. K. Narayanan',
        totalStudents: 320,
        totalFaculty: 18,
      );

      final map = dept.toMap();
      expect(map['name'], 'Artificial Intelligence & Data Science');
      expect(map['code'], 'AI&DS');
      expect(map['hodId'], 'hod_123');
      expect(map['totalStudents'], 320);
      expect(map['totalFaculty'], 18);

      final reconstructed = DepartmentModel.fromMap(map, 'DEP-AI-DS');
      expect(reconstructed.departmentId, 'DEP-AI-DS');
      expect(reconstructed.name, dept.name);
      expect(reconstructed.code, dept.code);
      expect(reconstructed.hodName, dept.hodName);
      expect(reconstructed.totalStudents, 320);
      expect(reconstructed.totalFaculty, 18);
    });

    test('2. HOD Attendance Analytics calculations accurately categorize student bands', () async {
      final students = <StudentModel>[
        StudentModel(
          studentId: 's1',
          userId: 'u1',
          fullName: 'Student High Attendance',
          rollNumber: '21CS001',
          registerNumber: 'REG2026001',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '94.5',
          cgpa: '9.1',
        ),
        StudentModel(
          studentId: 's2',
          userId: 'u2',
          fullName: 'Student Good Attendance',
          rollNumber: '21CS002',
          registerNumber: 'REG2026002',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '84.0',
          cgpa: '8.2',
        ),
        StudentModel(
          studentId: 's3',
          userId: 'u3',
          fullName: 'Student Borderline Attendance',
          rollNumber: '21CS003',
          registerNumber: 'REG2026003',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '77.5',
          cgpa: '7.3',
        ),
        StudentModel(
          studentId: 's4',
          userId: 'u4',
          fullName: 'Student Low Attendance',
          rollNumber: '21CS004',
          registerNumber: 'REG2026004',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '68.0',
          cgpa: '6.5',
          academicStatus: 'At Risk',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          hodStudentsStreamProvider.overrideWith((ref) => Stream<List<StudentModel>>.value(students)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hodStudentsStreamProvider.future);
      final attAnalytics = container.read(hodAttendanceAnalyticsProvider);
      expect(attAnalytics.total, 4);
      expect(attAnalytics.exemplary, 1);
      expect(attAnalytics.good, 1);
      expect(attAnalytics.borderline, 1);
      expect(attAnalytics.alert, 1);
      expect(attAnalytics.exemplaryPct, 0.25);
    });

    test('3. HOD Academic Analytics calculations and distinction tracking', () async {
      final students = <StudentModel>[
        StudentModel(
          studentId: 's1',
          userId: 'u1',
          fullName: 'Distinction Student',
          rollNumber: '21CS001',
          registerNumber: 'REG2026001',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          cgpa: '9.3',
        ),
        StudentModel(
          studentId: 's2',
          userId: 'u2',
          fullName: 'First Class Student',
          rollNumber: '21CS002',
          registerNumber: 'REG2026002',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          cgpa: '8.5',
        ),
        StudentModel(
          studentId: 's3',
          userId: 'u3',
          fullName: 'Second Class Student',
          rollNumber: '21CS003',
          registerNumber: 'REG2026003',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          cgpa: '7.4',
        ),
        StudentModel(
          studentId: 's4',
          userId: 'u4',
          fullName: 'Arrear Student',
          rollNumber: '21CS004',
          registerNumber: 'REG2026004',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          cgpa: '6.2',
          academicStatus: 'At Risk',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          hodStudentsStreamProvider.overrideWith((ref) => Stream<List<StudentModel>>.value(students)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hodStudentsStreamProvider.future);
      final acadAnalytics = container.read(hodAcademicAnalyticsProvider);
      expect(acadAnalytics.total, 4);
      expect(acadAnalytics.distinction, 1);
      expect(acadAnalytics.firstClass, 1);
      expect(acadAnalytics.secondClass, 1);
      expect(acadAnalytics.reAppear, 1);
      expect(acadAnalytics.distinctionPct, 0.25);
    });

    test('4. Student Risk List correctly identifies low attendance and low CGPA students', () async {
      final students = <StudentModel>[
        StudentModel(
          studentId: 'safe_1',
          userId: 'u1',
          fullName: 'Priya Sharma',
          rollNumber: '21CS101',
          registerNumber: 'REG2026101',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '92.0',
          cgpa: '8.9',
        ),
        StudentModel(
          studentId: 'risk_att',
          userId: 'u2',
          fullName: 'Karthik Raja',
          rollNumber: '21CS102',
          registerNumber: 'REG2026102',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '71.5',
          cgpa: '8.1',
        ),
        StudentModel(
          studentId: 'risk_cgpa',
          userId: 'u3',
          fullName: 'Ananya Verma',
          rollNumber: '21CS103',
          registerNumber: 'REG2026103',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '88.0',
          cgpa: '6.4',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          hodStudentsStreamProvider.overrideWith((ref) => Stream<List<StudentModel>>.value(students)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hodStudentsStreamProvider.future);
      final riskStudents = container.read(hodStudentRiskListProvider);
      expect(riskStudents.length, 2);
      expect(riskStudents.any((s) => s.registerNumber == 'REG2026102'), isTrue);
      expect(riskStudents.any((s) => s.registerNumber == 'REG2026103'), isTrue);
      expect(riskStudents.any((s) => s.registerNumber == 'REG2026101'), isFalse);
    });

    testWidgets('5. HOD Home Dashboard renders KPI metrics, live department header, and risk alerts', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dept = DepartmentModel(
        departmentId: 'DEP-CSE',
        name: 'Computer Science & Engineering',
        code: 'CSE',
        hodName: 'Dr. Ramesh Sundaram',
      );

      final students = <StudentModel>[
        StudentModel(
          studentId: 's1',
          userId: 'u1',
          fullName: 'Rahul V',
          rollNumber: '21CS045',
          registerNumber: '312321104045',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '68.5',
          cgpa: '6.8',
          academicStatus: 'At Risk',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentHodDepartmentProvider.overrideWith((ref) => Future.value(dept)),
            hodStudentsStreamProvider.overrideWith((ref) => Stream<List<StudentModel>>.value(students)),
            hodStaffStreamProvider.overrideWith((ref) => Stream<List<StaffModel>>.value([])),
            hodAssignmentsStreamProvider.overrideWith((ref) => Stream<List<StaffAssignmentModel>>.value([])),
            hodLeaveRequestsStreamProvider.overrideWith((ref) => Stream<List<Map<String, dynamic>>>.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HodHomeDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Department Overview & Header
      expect(find.text('Dr. Ramesh Sundaram'), findsOneWidget);
      expect(find.textContaining('Computer Science & Engineering'), findsWidgets);

      // KPI Metric Cards
      expect(find.text('Enrolled Students'), findsOneWidget);
      expect(find.text('Faculty Members'), findsOneWidget);
      expect(find.text('Active Classes'), findsOneWidget);

      // Student Risk Alert Card with Register Number
      expect(find.text('STUDENTS REQUIRING ATTENTION'), findsOneWidget);
      expect(find.text('312321104045'), findsOneWidget);
      expect(find.text('Rahul V'), findsOneWidget);
    });

    testWidgets('6. HOD Student Management screen renders Register Number and directory header', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final students = <StudentModel>[
        StudentModel(
          studentId: 'stu_1',
          userId: 'u1',
          fullName: 'Deepak Kumar',
          rollNumber: '21CS012',
          registerNumber: '312321104012',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'B1',
          batch: '2022-2026',
          semester: '6',
          section: 'A',
          admissionYear: 2022,
          attendancePercent: '91.0',
          cgpa: '8.8',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentHodDepartmentProvider.overrideWith((ref) => Future.value(
                  DepartmentModel(departmentId: 'DEP-CSE', name: 'Computer Science & Engineering', code: 'CSE'),
                )),
            hodStudentsStreamProvider.overrideWith((ref) => Stream<List<StudentModel>>.value(students)),
            hodVerificationsStreamProvider.overrideWith((ref) => Stream<List<Map<String, dynamic>>>.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HodStudentManagement(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Directory'), findsOneWidget);
      expect(find.text('Deepak Kumar'), findsOneWidget);
      expect(find.text('Reg No: 312321104012'), findsOneWidget);
    });

    testWidgets('7. HOD Staff Management screen renders faculty roster and advisor badge', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staff = <StaffModel>[
        StaffModel(
          userId: 'fac_1',
          employeeId: 'EMP-01',
          fullName: 'Dr. Anita Roy',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          designation: 'Associate Professor',
          specialization: 'Artificial Intelligence',
          assignedClasses: ['CSE-A'],
          assignedSubjects: ['Deep Learning'],
          isAdvisor: true,
          advisorSection: 'CSE-A (Year 3)',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hodStaffStreamProvider.overrideWith((ref) => Stream<List<StaffModel>>.value(staff)),
            hodAssignmentsStreamProvider.overrideWith((ref) => Stream<List<StaffAssignmentModel>>.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HodStaffManagement(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('FACULTY & RESPONSIBILITY DIRECTORY'), findsOneWidget);
      expect(find.text('Dr. Anita Roy'), findsOneWidget);
      expect(find.textContaining('Class Advisor'), findsWidgets);
      expect(find.textContaining('CSE-A (Year 3)'), findsWidgets);
    });

    testWidgets('8. HOD Shell tab navigation updates content view and AppBar title seamlessly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dept = DepartmentModel(
        departmentId: 'DEP-CSE',
        name: 'Computer Science & Engineering',
        code: 'CSE',
        hodId: 'hod_1',
        hodName: 'Dr. R. Kumar',
        totalStudents: 450,
        totalFaculty: 24,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentHodDepartmentProvider.overrideWith((ref) => Future.value(dept)),
            hodStudentsStreamProvider.overrideWith((ref) => Stream<List<StudentModel>>.value([])),
            hodStaffStreamProvider.overrideWith((ref) => Stream<List<StaffModel>>.value([])),
            hodVerificationsStreamProvider.overrideWith((ref) => Stream<List<Map<String, dynamic>>>.value([])),
            hodLeaveRequestsStreamProvider.overrideWith((ref) => Stream<List<Map<String, dynamic>>>.value([])),
            hodAssignmentsStreamProvider.overrideWith((ref) => Stream<List<StaffAssignmentModel>>.value([])),
          ],
          child: const MaterialApp(
            home: HodShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Home Dashboard
      expect(find.text('CSE Department Portal'), findsOneWidget);
      expect(find.byType(HodHomeDashboard), findsOneWidget);
      expect(find.byType(HodStaffManagement), findsNothing);
      expect(find.byType(HodStudentManagement), findsNothing);

      // Tap on 'Staff Management' in sidebar
      await tester.tap(find.text('Staff Management'));
      await tester.pumpAndSettle();

      // Content has transitioned to HodStaffManagement
      expect(find.byType(HodStaffManagement), findsOneWidget);
      expect(find.byType(HodHomeDashboard), findsNothing);
      expect(find.text('Staff Management'), findsWidgets);

      // Tap on 'Student Management' in sidebar
      await tester.tap(find.text('Student Management'));
      await tester.pumpAndSettle();

      // Content has transitioned to HodStudentManagement
      expect(find.byType(HodStudentManagement), findsOneWidget);
      expect(find.byType(HodStaffManagement), findsNothing);
      expect(find.text('Student Management'), findsWidgets);

      // Tap back button in AppBar to return to previous tab (Staff Management)
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(HodStaffManagement), findsOneWidget);
      expect(find.byType(HodStudentManagement), findsNothing);

      // Tap back button again to return to Home Dashboard
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(HodHomeDashboard), findsOneWidget);
      expect(find.byType(HodStaffManagement), findsNothing);
    });
  });
}

const _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
