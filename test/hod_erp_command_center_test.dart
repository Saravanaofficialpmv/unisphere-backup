import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/screens/hod/hod_home_dashboard.dart';
import 'package:unisphere/screens/hod/hod_shell.dart';
import 'package:unisphere/screens/hod/modules/hod_action_center.dart';
import 'package:unisphere/screens/hod/modules/hod_command_header.dart';
import 'package:unisphere/screens/hod/modules/hod_executive_health.dart';
import 'package:unisphere/screens/hod/modules/hod_student_health_center.dart';
import 'package:unisphere/screens/hod/modules/hod_faculty_health_center.dart';
import 'package:unisphere/screens/hod/modules/hod_academic_performance_center.dart';
import 'package:unisphere/screens/hod/modules/hod_today_operations.dart';
import 'package:unisphere/screens/hod/modules/hod_deadline_intelligence.dart';
import 'package:unisphere/screens/hod/modules/hod_activity_timeline.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';
import 'package:unisphere/services/hod_action_center_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('HOD Next-Gen ERP Command Center Tests', () {
    final testDept = DepartmentModel(
      departmentId: 'DEP-CSE',
      name: 'Computer Science & Engineering',
      code: 'CSE',
      hodId: 'hod_1',
      hodName: 'Dr. Ramesh Sundaram',
      totalStudents: 450,
      totalFaculty: 24,
    );

    final testStudents = <StudentModel>[
      StudentModel(
        studentId: 'stu_1',
        userId: 'u_1',
        fullName: 'Rahul V',
        rollNumber: '21CS001',
        registerNumber: '312321104045',
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        batchId: 'B1',
        batch: '2022-2026',
        semester: '6',
        section: 'A',
        admissionYear: 2022,
        attendancePercent: '64.5',
        cgpa: '5.8',
      ),
      StudentModel(
        studentId: 'stu_2',
        userId: 'u_2',
        fullName: 'Priya Sharma',
        rollNumber: '21CS002',
        registerNumber: '312321104046',
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        batchId: 'B1',
        batch: '2022-2026',
        semester: '6',
        section: 'A',
        admissionYear: 2022,
        attendancePercent: '92.0',
        cgpa: '9.2',
      ),
    ];

    final testStaff = <StaffModel>[
      StaffModel(
        userId: 'u_stf1',
        employeeId: 'EMP001',
        fullName: 'Dr. Ananya Sharma',
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Associate Professor',
        specialization: 'Artificial Intelligence',
        isAdvisor: true,
        advisorSection: 'A',
        assignedClasses: const ['CSE-3A'],
        assignedSubjects: const ['CS801', 'CS802'],
      ),
      StaffModel(
        userId: 'u_stf2',
        employeeId: 'EMP002',
        fullName: 'Prof. Rajesh K',
        departmentId: 'DEP-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Assistant Professor',
        specialization: 'Cloud Computing',
        isAdvisor: false,
        assignedClasses: const ['CSE-2B'],
        assignedSubjects: const ['CS401'],
      ),
    ];

    test('1. Action Center domain models and priority mapping logic', () {
      expect(HodPriorityLevel.critical.label, 'CRITICAL');
      expect(HodPriorityLevel.high.label, 'HIGH');
      expect(HodPriorityLevel.medium.label, 'MEDIUM');
      expect(HodPriorityLevel.low.label, 'LOW');
      expect(HodPriorityLevel.info.label, 'INFO');

      final profile = StudentRiskProfile(
        student: testStudents.first,
        riskLevel: HodPriorityLevel.critical,
        reasons: ['Low Attendance (< 75%)', 'Low CGPA (< 6.0)'],
        attendance: 64.5,
        cgpa: 5.8,
        isAttendanceRisk: true,
        isAcademicRisk: true,
      );

      expect(profile.isAttendanceRisk, isTrue);
      expect(profile.isAcademicRisk, isTrue);
      expect(profile.reasons.length, 2);
    });

    testWidgets('2. Full HOD Home Dashboard renders all 5 ERP operational layers', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentHodDepartmentProvider.overrideWith((ref) => Future.value(testDept)),
            hodStudentsStreamProvider.overrideWith((ref) => Stream<List<StudentModel>>.value(testStudents)),
            hodStaffStreamProvider.overrideWith((ref) => Stream<List<StaffModel>>.value(testStaff)),
            hodVerificationsStreamProvider.overrideWith((ref) => Stream<List<Map<String, dynamic>>>.value([])),
            hodLeaveRequestsStreamProvider.overrideWith((ref) => Stream<List<Map<String, dynamic>>>.value([])),
            hodAssignmentsStreamProvider.overrideWith((ref) => Stream<List<StaffAssignmentModel>>.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HodHomeDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Layer 1: Command Header & Executive Health
      expect(find.byType(HodCommandHeader), findsOneWidget);
      expect(find.byType(HodExecutiveHealth), findsOneWidget);
      expect(find.text('Dr. Ramesh Sundaram'), findsOneWidget);
      expect(find.text('DEPARTMENT HEALTH OVERVIEW'), findsOneWidget);
      expect(find.text('Enrolled Students'), findsOneWidget);
      expect(find.text('Faculty Members'), findsOneWidget);
      expect(find.text('Active Classes'), findsOneWidget);

      // Layer 2: Action Center
      expect(find.byType(HodActionCenter), findsOneWidget);
      expect(find.text('Action Center'), findsOneWidget);

      // Layer 3: Student Health & Faculty Health & Academic Centers
      expect(find.byType(HodStudentHealthCenter), findsOneWidget);
      expect(find.text('STUDENTS REQUIRING ATTENTION'), findsOneWidget);
      expect(find.text('312321104045'), findsOneWidget);
      expect(find.text('Rahul V'), findsOneWidget);

      expect(find.byType(HodFacultyHealthCenter), findsOneWidget);
      expect(find.text('Faculty Health & Workload'), findsOneWidget);
      expect(find.text('Department Faculty'), findsOneWidget);

      expect(find.byType(HodAcademicPerformanceCenter), findsOneWidget);
      expect(find.text('Academic Performance & Alerts'), findsOneWidget);

      // Layer 4: Operations Today & Deadlines
      expect(find.byType(HodTodayOperations), findsOneWidget);
      expect(find.text("Today's Operations"), findsOneWidget);

      expect(find.byType(HodDeadlineIntelligence), findsOneWidget);
      expect(find.text('Upcoming Deadlines'), findsOneWidget);

      // Layer 5: Activity Log
      expect(find.byType(HodActivityTimeline), findsOneWidget);
      expect(find.text('Recent Department Activity'), findsOneWidget);
    });

    testWidgets('3. Quick Action Modal opens from HodShell floating button', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentHodDepartmentProvider.overrideWith((ref) => Future.value(testDept)),
            hodStudentsStreamProvider.overrideWith((ref) => Stream<List<StudentModel>>.value(testStudents)),
            hodStaffStreamProvider.overrideWith((ref) => Stream<List<StaffModel>>.value(testStaff)),
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

      // Find quick action button in AppBar
      final quickActionBtn = find.byTooltip('Department Operations Action Center');
      expect(quickActionBtn, findsOneWidget);

      await tester.tap(quickActionBtn);
      await tester.pumpAndSettle();

      // Verify bottom sheet modal opened
      final modal = find.byType(BottomSheet);
      expect(modal, findsOneWidget);
      expect(find.descendant(of: modal, matching: find.text('Quick Department Actions')), findsOneWidget);
      expect(find.descendant(of: modal, matching: find.text('Broadcast Dept Announcement')), findsOneWidget);
      expect(find.descendant(of: modal, matching: find.text('Approve Pending Leave / OD')), findsOneWidget);
      expect(find.descendant(of: modal, matching: find.text('Generate Department Report')), findsOneWidget);
      expect(find.descendant(of: modal, matching: find.text('Assign Class Advisor / Staff')), findsOneWidget);
      expect(find.descendant(of: modal, matching: find.text('Review Exam Schedules')), findsOneWidget);
      expect(find.descendant(of: modal, matching: find.text('Student Verifications')), findsOneWidget);
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
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => invocation.memberName == #getUrl ? Future.value(_MockHttpClientRequest()) : null;
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
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.fromIterable([_kTransparentImage]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
