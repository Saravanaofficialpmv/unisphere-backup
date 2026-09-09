import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/department_model.dart';
import 'package:unisphere/repositories/department_repository.dart';
import 'package:unisphere/screens/onboarding/onboarding_screen.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Student Signup HOD Department Filtering Tests', () {
    test('1. Department name canonicalization and normalization', () {
      expect(
        DepartmentRepository.canonicalizeDepartmentName('Artificial Intelligence and Data Science'),
        'Artificial Intelligence and Data Science',
      );
      expect(
        DepartmentRepository.canonicalizeDepartmentName('AIDS'),
        'Artificial Intelligence and Data Science',
      );
      expect(
        DepartmentRepository.canonicalizeDepartmentName('ai & ds'),
        'Artificial Intelligence and Data Science',
      );
      expect(
        DepartmentRepository.canonicalizeDepartmentName('CSE'),
        'Computer Science and Engineering',
      );
      expect(
        DepartmentRepository.normalizeDepartmentKey('Artificial Intelligence & Data Science'),
        'artificialintelligencedatascience',
      );
    });

    test('2. DepartmentModel with active HOD vs unassigned department', () {
      final activeDept = DepartmentModel(
        departmentId: 'DEP-AIDS',
        name: 'Artificial Intelligence and Data Science',
        code: 'AIDS',
        hodId: 'hod-12345',
        hodName: 'Dr. Manivannan',
        totalStudents: 120,
        totalFaculty: 15,
      );

      final unassignedDept = DepartmentModel(
        departmentId: 'DEP-MECH',
        name: 'Mechanical Engineering',
        code: 'MECH',
        hodId: null,
        hodName: null,
        totalStudents: 0,
        totalFaculty: 0,
      );

      expect(activeDept.hodId, isNotNull);
      expect(activeDept.hodId!.isNotEmpty, isTrue);
      expect(activeDept.hodName, 'Dr. Manivannan');

      expect(unassignedDept.hodId, isNull);
    });

    testWidgets('3. Onboarding role selection allows choosing Student or HOD', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.text('Get Started 🚀'));
      await tester.pumpAndSettle();

      // Verify Role selection cards exist
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Department (HOD)'), findsOneWidget);

      // Select Student
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      // Advance to Name step
      await tester.tap(find.text('Continue ➔'));
      await tester.pumpAndSettle();

      expect(find.text('What\'s Your\nFull Name?'), findsOneWidget);
    });
  });
}
