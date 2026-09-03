import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_home_dashboard.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_dashboard.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Staff Portal & Role-Based Advisor Experience Tests', () {
    testWidgets('1. Normal Staff Dashboard renders teaching schedule, quick actions, subjects, and pending work', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StaffHomeDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Greeting and Title
      expect(find.text('Dr. Arun Kumar'), findsOneWidget);
      expect(find.text("TODAY'S SCHEDULE"), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text('MY SUBJECTS'), findsOneWidget);
      expect(find.text('PENDING WORK'), findsOneWidget);
      expect(find.text('RECENT ACTIVITY'), findsOneWidget);

      // Top metrics
      expect(find.text("Today's Classes"), findsOneWidget);
      expect(find.text('Pending Tasks'), findsOneWidget);
      expect(find.text('Attendance'), findsAtLeast(1));

      // Quick Actions items
      expect(find.text('Upload Marks'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Question Papers'), findsOneWidget);
    });

    testWidgets('2. Class Advisor Dashboard renders overview metrics, attendance gauge, academic performance, and attention categories', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdvisorDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header Banner
      expect(find.text('Class Advisor'), findsOneWidget);
      expect(find.textContaining('Academic Year'), findsOneWidget);

      // Overview section
      expect(find.text('CLASS OVERVIEW'), findsOneWidget);
      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('Overall Attendance'), findsOneWidget);
      expect(find.text('Average CGPA'), findsOneWidget);
      expect(find.text('Students At Risk'), findsOneWidget);

      // Attendance & Academics
      expect(find.text('Students Requiring Attention'), findsOneWidget);
      expect(find.text('ACADEMIC PERFORMANCE'), findsOneWidget);
      expect(find.text('STUDENTS REQUIRING ATTENTION'), findsOneWidget);
      expect(find.text('ADVISOR TASKS'), findsOneWidget);

      // Actions & cards
      expect(find.text('View All Students'), findsOneWidget);
      expect(find.text('Top Performers'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
    });

    testWidgets('3. StaffDashboard shell hosts active role and allows switching view mode', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StaffDashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top App Bar shows VSB College and portal subtitle
      expect(find.text('VSB COLLEGE'), findsOneWidget);
      expect(find.text('Class Advisor Portal'), findsOneWidget);

      // Tap 'Teaching View' button to toggle to teaching mode
      final teachingBtn = find.text('Teaching View');
      if (teachingBtn.evaluate().isNotEmpty) {
        await tester.tap(teachingBtn);
        await tester.pumpAndSettle();

        expect(find.text("TODAY'S SCHEDULE"), findsOneWidget);
        expect(find.text('Advisor Mode'), findsOneWidget);
      }
    });

    testWidgets('4. Role-Based Access: Normal Staff sees only staff features, advisor-only features hidden', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final normalStaff = StaffModel(
        userId: 'STF-NORMAL',
        employeeId: 'STF-009',
        fullName: 'Prof. Rajesh Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'CSE Department',
        designation: 'Associate Professor',
        specialization: 'Computer Science',
        assignedClasses: ['III CSE - A'],
        assignedSubjects: ['Data Structures'],
        isAdvisor: false,
        advisorSection: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(normalStaff)),
          ],
          child: const MaterialApp(
            home: StaffDashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Subtitle reflects Faculty mode
      expect(find.text('Faculty Management System'), findsOneWidget);
      expect(find.text('Staff Dashboard'), findsOneWidget);

      // Faculty navigation items are present
      expect(find.text('Timetable & Schedule'), findsOneWidget);
      expect(find.text('Take Attendance'), findsAtLeast(1));
      expect(find.text('Upload Marks'), findsAtLeast(1));
      expect(find.text('Give Assignment'), findsOneWidget);

      // Advisor-only navigation items are strictly hidden
      expect(find.text('Advisor Dashboard'), findsNothing);
      expect(find.text('Class Student Directory'), findsNothing);
      expect(find.text('Parent Communication'), findsNothing);
      expect(find.text('Student Approvals'), findsNothing);
      expect(find.text('Profile Edit Requests'), findsNothing);
      expect(find.text('Resume Bank'), findsNothing);
      expect(find.text('NPTEL Verification'), findsNothing);
      expect(find.text('Hackathon Approvals'), findsNothing);
    });

    testWidgets('5. Role-Based Access: Class Advisor sees staff features + advisor features', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final advisorStaff = StaffModel(
        userId: 'STF-ADVISOR',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'CSE Department',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: ['III CSE - A'],
        assignedSubjects: ['Machine Learning'],
        isAdvisor: true,
        advisorSection: 'III CSE - A',
        advisorAcademicYear: '2025–26',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(true),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(advisorStaff)),
          ],
          child: const MaterialApp(
            home: StaffDashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Subtitle reflects Class Advisor portal
      expect(find.text('Class Advisor Portal'), findsOneWidget);

      // Advisor navigation items are visible
      expect(find.text('Advisor Dashboard'), findsOneWidget);
      expect(find.text('Class Student Directory'), findsOneWidget);
      expect(find.text('Parent Communication'), findsOneWidget);
      expect(find.text('Student Approvals'), findsOneWidget);
      expect(find.text('Profile Edit Requests'), findsOneWidget);
      expect(find.text('Resume Bank'), findsOneWidget);

      // Teaching items are also accessible
      expect(find.text('Timetable & Schedule'), findsOneWidget);
      expect(find.text('Take Attendance'), findsOneWidget);
      expect(find.text('Upload Marks'), findsOneWidget);
      expect(find.text('Give Assignment'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> putUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> headUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> get(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> post(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> put(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> head(String host, int port, String path) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final List<int> _kTransparentImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

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
