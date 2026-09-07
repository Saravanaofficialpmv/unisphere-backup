import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/screens/hod/hod_shell.dart';
import 'package:unisphere/screens/hod/modules/hod_staff_management.dart';
import 'package:unisphere/screens/hod/modules/hod_student_management.dart';
import 'package:unisphere/screens/hod/modules/hod_reports_analytics.dart';
import 'package:unisphere/screens/hod/modules/hod_settings.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  testWidgets('Test HodShell on iPhone 390x844 dimensions', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
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

    // On mobile, tap floating nav bar item 'Staff'
    final staffNav = find.byTooltip('Staff');
    expect(staffNav, findsOneWidget);
    await tester.tap(staffNav);
    await tester.pumpAndSettle();

    expect(find.byType(HodStaffManagement), findsOneWidget);
    expect(find.text('Faculty & Staff Directory'), findsOneWidget);

    // Tap 'Students'
    final studentsNav = find.byTooltip('Students');
    expect(studentsNav, findsOneWidget);
    await tester.tap(studentsNav);
    await tester.pumpAndSettle();

    expect(find.byType(HodStudentManagement), findsOneWidget);

    // Tap 'Reports'
    final reportsNav = find.byTooltip('Reports');
    expect(reportsNav, findsOneWidget);
    await tester.tap(reportsNav);
    await tester.pumpAndSettle();

    expect(find.byType(HodReportsAnalytics), findsOneWidget);

    // Verify 'Sign Out' in bottom floating nav bar
    final signOutNav = find.byTooltip('Sign Out');
    expect(signOutNav, findsOneWidget);

    // Tap 'Department Settings' in AppBar header
    final settingsNav = find.byTooltip('Department Settings');
    expect(settingsNav, findsOneWidget);
    await tester.tap(settingsNav);
    await tester.pumpAndSettle();

    expect(find.byType(HodSettings), findsOneWidget);

    // Tap 'Home'
    final homeNav = find.byTooltip('Home');
    expect(homeNav, findsOneWidget);
    await tester.tap(homeNav);
    await tester.pumpAndSettle();

    expect(find.text('DEPARTMENT HEALTH OVERVIEW'), findsOneWidget);
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
