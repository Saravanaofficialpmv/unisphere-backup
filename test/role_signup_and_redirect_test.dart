import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/navigation/app_router.dart';
import 'package:unisphere/screens/auth/auth_screen.dart';

void main() {
  group('Role Selection & Redirection Tests', () {
    testWidgets('1. Signup form with initialRole=Faculty renders 4-digit Staff Register Number fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AuthScreen(
                isInitialSignUp: true,
                initialRole: 'Faculty',
                initialId: '2041',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Staff Register Number label, 4-digit hint, and prefilled initialId
      expect(find.text('Faculty / Staff Full Name'), findsOneWidget);
      expect(find.text('Staff Register Number'), findsOneWidget);
      expect(find.text('Enter 4-digit register number'), findsOneWidget);
      expect(find.text('Staff Email Address'), findsOneWidget);
      expect(find.text('2041'), findsOneWidget);
      // Ensure the redundant role picker is not present
      expect(find.text('Select Your Role'), findsNothing);
    });

    testWidgets('2. Signup form with initialRole=Student renders Student Register Number fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AuthScreen(
                isInitialSignUp: true,
                initialRole: 'Student',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Student fields
      expect(find.text('Student Full Name'), findsOneWidget);
      expect(find.text('Register Number'), findsOneWidget);
      expect(find.text('Enter 12-digit register number'), findsOneWidget);
      expect(find.text('College Email Address'), findsOneWidget);
      expect(find.text('Select Your Role'), findsNothing);
    });

    test('3. Role redirection unit tests: each role is strictly mapped to its own panel', () {
      final staffUser = UserModel(
        uid: 'TEST-STF-01',
        email: 'prof.smith@gmail.com',
        fullName: 'Prof. Smith',
        role: UserRole.staff,
      );

      final studentUser = UserModel(
        uid: 'TEST-STU-01',
        email: 'student@gmail.com',
        fullName: 'Student User',
        role: UserRole.student,
      );

      final parentUser = UserModel(
        uid: 'TEST-PRT-01',
        email: 'parent@gmail.com',
        fullName: 'Parent User',
        role: UserRole.parent,
      );

      final hodUser = UserModel(
        uid: 'TEST-HOD-01',
        email: 'hod@gmail.com',
        fullName: 'Dr. Vance',
        role: UserRole.hod,
      );

      final adminUser = UserModel(
        uid: 'TEST-ADM-01',
        email: 'admin@gmail.com',
        fullName: 'Admin User',
        role: UserRole.admin,
      );

      // Staff user redirects to /staff from login, signup, and mismatched dashboards
      expect(resolveRouteRedirect(user: staffUser, matchedLocation: '/login'), equals('/staff'));
      expect(resolveRouteRedirect(user: staffUser, matchedLocation: '/signup'), equals('/staff'));
      expect(resolveRouteRedirect(user: staffUser, matchedLocation: '/student'), equals('/staff'));
      expect(resolveRouteRedirect(user: staffUser, matchedLocation: '/parent'), equals('/staff'));
      expect(resolveRouteRedirect(user: staffUser, matchedLocation: '/hod'), equals('/staff'));
      expect(resolveRouteRedirect(user: staffUser, matchedLocation: '/staff'), isNull);

      // Student user redirects to /student from mismatched dashboards
      expect(resolveRouteRedirect(user: studentUser, matchedLocation: '/staff'), equals('/student'));
      expect(resolveRouteRedirect(user: studentUser, matchedLocation: '/parent'), equals('/student'));
      expect(resolveRouteRedirect(user: studentUser, matchedLocation: '/hod'), equals('/student'));
      expect(resolveRouteRedirect(user: studentUser, matchedLocation: '/student'), isNull);

      // Parent user redirects to /parent
      expect(resolveRouteRedirect(user: parentUser, matchedLocation: '/student'), equals('/parent'));
      expect(resolveRouteRedirect(user: parentUser, matchedLocation: '/staff'), equals('/parent'));
      expect(resolveRouteRedirect(user: parentUser, matchedLocation: '/parent'), isNull);

      // HOD user redirects to /hod
      expect(resolveRouteRedirect(user: hodUser, matchedLocation: '/student'), equals('/hod'));
      expect(resolveRouteRedirect(user: hodUser, matchedLocation: '/staff'), equals('/hod'));
      expect(resolveRouteRedirect(user: hodUser, matchedLocation: '/hod'), isNull);

      // Admin user redirects to /admin
      expect(resolveRouteRedirect(user: adminUser, matchedLocation: '/student'), equals('/admin'));
      expect(resolveRouteRedirect(user: adminUser, matchedLocation: '/staff'), equals('/admin'));
      expect(resolveRouteRedirect(user: adminUser, matchedLocation: '/admin'), isNull);
    });
  });
}
