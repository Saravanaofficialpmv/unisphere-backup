import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/repositories/department_repository.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/screens/hod/hod_shell.dart';
import 'package:unisphere/screens/hod/modules/hod_settings.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('HOD Custom Department Resolution Tests (e.g. AI & DS)', () {
    test('1. DepartmentRepository deriveDepartmentCode and deriveDepartmentId for AI & DS', () {
      expect(DepartmentRepository.deriveDepartmentCode('Artificial Intelligence and Data Science'), 'AIDS');
      expect(DepartmentRepository.deriveDepartmentId('Artificial Intelligence and Data Science'), 'DEP-AIDS');

      expect(DepartmentRepository.deriveDepartmentCode('Artificial Intelligence & Data Science'), 'AIDS');
      expect(DepartmentRepository.deriveDepartmentId('Artificial Intelligence & Data Science'), 'DEP-AIDS');

      expect(DepartmentRepository.deriveDepartmentCode('Computer Science & Engineering'), 'CSE');
      expect(DepartmentRepository.deriveDepartmentId('Computer Science & Engineering'), 'DEP-CSE');
    });

    test('2. UserModel parses root-level department and departmentName correctly', () {
      final userDoc = {
        'createdAt': '2026-09-05T11:10:26.514386',
        'department': 'Artificial Intelligence and Data Science',
        'departmentName': 'Artificial Intelligence and Data Science',
        'email': 'Unispherecrm.official@gmail.com',
        'fullName': 'manivannan',
        'name': 'manivannan',
        'isActive': true,
        'role': 'hod',
        'userRole': 'hod',
        'userId': '1Pl7LbOCZXh5wd6PyRIwOHzDRTf2',
      };

      final user = UserModel.fromMap(userDoc, '1Pl7LbOCZXh5wd6PyRIwOHzDRTf2');
      expect(user.uid, '1Pl7LbOCZXh5wd6PyRIwOHzDRTf2');
      expect(user.fullName, 'manivannan');
      expect(user.role, UserRole.hod);
      expect(user.department, 'Artificial Intelligence and Data Science');
      expect(user.departmentName, 'Artificial Intelligence and Data Science');
    });

    test('3. DepartmentRepository resolves dynamic DepartmentModel without falling back to CSE', () async {
      final repo = DepartmentRepository();
      final dept = await repo.getDepartmentForHod(
        hodId: '1Pl7LbOCZXh5wd6PyRIwOHzDRTf2',
        userDeptName: 'Artificial Intelligence and Data Science',
        hodName: 'manivannan',
      );

      expect(dept.name, 'Artificial Intelligence and Data Science');
      expect(dept.code, 'AIDS');
      expect(dept.departmentId, 'DEP-AIDS');
      expect(dept.hodId, '1Pl7LbOCZXh5wd6PyRIwOHzDRTf2');
      expect(dept.hodName, 'manivannan');
    });

    testWidgets('4. HodHomeDashboard and HodShell render AI & DS on UI instead of CSE', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final loggedInUser = UserModel(
        uid: '1Pl7LbOCZXh5wd6PyRIwOHzDRTf2',
        email: 'Unispherecrm.official@gmail.com',
        fullName: 'manivannan',
        role: UserRole.hod,
        metadata: {
          'department': 'Artificial Intelligence and Data Science',
          'departmentName': 'Artificial Intelligence and Data Science',
        },
      );

      final aidsDept = DepartmentModel(
        departmentId: 'DEP-AIDS',
        name: 'Artificial Intelligence and Data Science',
        code: 'AIDS',
        hodId: '1Pl7LbOCZXh5wd6PyRIwOHzDRTf2',
        hodName: 'manivannan',
        totalStudents: 360,
        totalFaculty: 22,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => Stream.value(loggedInUser)),
            currentHodDepartmentProvider.overrideWith((ref) => Future.value(aidsDept)),
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

      // Verify that "Artificial Intelligence and Data Science" is displayed and NOT "Computer Science & Engineering"
      expect(find.text('Artificial Intelligence and Data Science'), findsWidgets);
      expect(find.textContaining('Computer Science & Engineering'), findsNothing);

      // Verify AppBar displays "AIDS Department Portal"
      expect(find.text('AIDS Department Portal'), findsOneWidget);

      // Verify greeting has HOD's name
      expect(find.textContaining('manivannan'), findsWidgets);

      // Navigate to Settings and verify department code & name in Department Details card
      final settingsNav = find.byWidgetPredicate(
        (w) => (w is IconButton && (w.tooltip == 'Department Settings' || w.tooltip == 'Settings')) ||
               (w is Icon && w.icon == Icons.settings_outlined),
      );
      await tester.tap(settingsNav.first);
      await tester.pumpAndSettle();

      expect(find.byType(HodSettings), findsOneWidget);
      expect(find.text('AIDS'), findsOneWidget);
      expect(find.text('Unispherecrm.official@gmail.com'), findsOneWidget);
      expect(find.textContaining('Computer Science & Engineering'), findsNothing);
    });
  });
}

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
  int get contentLength => 0;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.empty().listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
