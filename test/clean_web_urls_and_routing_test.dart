import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/navigation/app_router.dart';
import 'package:unisphere/screens/common/not_found_screen.dart';

void main() {
  group('Clean Web URLs & Role Guards Tests', () {
    final student = UserModel(
      uid: 'u_student_1',
      email: 'student@unisphere.edu',
      fullName: 'Student User',
      role: UserRole.student,
    );

    final staff = UserModel(
      uid: 'u_staff_1',
      email: 'staff@unisphere.edu',
      fullName: 'Faculty User',
      role: UserRole.staff,
    );

    final hod = UserModel(
      uid: 'u_hod_1',
      email: 'hod@unisphere.edu',
      fullName: 'Dr. HOD',
      role: UserRole.hod,
    );

    final parent = UserModel(
      uid: 'u_parent_1',
      email: 'parent@gmail.com',
      fullName: 'Parent User',
      role: UserRole.parent,
    );

    final admin = UserModel(
      uid: 'u_admin_1',
      email: 'admin@unisphere.edu',
      fullName: 'System Admin',
      role: UserRole.admin,
    );

    test('1. Unauthenticated users are redirected to /login for all protected clean routes', () {
      expect(resolveRouteRedirect(user: null, matchedLocation: '/student'), equals('/login'));
      expect(resolveRouteRedirect(user: null, matchedLocation: '/staff'), equals('/login'));
      expect(resolveRouteRedirect(user: null, matchedLocation: '/hod'), equals('/login'));
      expect(resolveRouteRedirect(user: null, matchedLocation: '/parent'), equals('/login'));
      expect(resolveRouteRedirect(user: null, matchedLocation: '/admin'), equals('/login'));
      expect(resolveRouteRedirect(user: null, matchedLocation: '/student/attendance'), equals('/login'));
      expect(resolveRouteRedirect(user: null, matchedLocation: '/admin/users'), equals('/login'));

      // Public auth routes are allowed
      expect(resolveRouteRedirect(user: null, matchedLocation: '/login'), isNull);
      expect(resolveRouteRedirect(user: null, matchedLocation: '/onboarding'), isNull);
      expect(resolveRouteRedirect(user: null, matchedLocation: '/signup'), isNull);
      expect(resolveRouteRedirect(user: null, matchedLocation: '/forgot-password'), isNull);
    });

    test('2. Student role guard strictly rejects /admin, /staff, /hod, /parent and subroutes', () {
      // Allowed student routes
      expect(resolveRouteRedirect(user: student, matchedLocation: '/student'), isNull);
      expect(resolveRouteRedirect(user: student, matchedLocation: '/student/profile'), isNull);
      expect(resolveRouteRedirect(user: student, matchedLocation: '/student/attendance'), isNull);
      expect(resolveRouteRedirect(user: student, matchedLocation: '/student/marks'), isNull);

      // Denied foreign routes -> redirected back to /student
      expect(resolveRouteRedirect(user: student, matchedLocation: '/admin'), equals('/student'));
      expect(resolveRouteRedirect(user: student, matchedLocation: '/admin/users'), equals('/student'));
      expect(resolveRouteRedirect(user: student, matchedLocation: '/admin/settings'), equals('/student'));
      expect(resolveRouteRedirect(user: student, matchedLocation: '/staff'), equals('/student'));
      expect(resolveRouteRedirect(user: student, matchedLocation: '/staff/attendance'), equals('/student'));
      expect(resolveRouteRedirect(user: student, matchedLocation: '/hod'), equals('/student'));
      expect(resolveRouteRedirect(user: student, matchedLocation: '/hod/analytics'), equals('/student'));
      expect(resolveRouteRedirect(user: student, matchedLocation: '/parent'), equals('/student'));

      // Redirect away from login when already authenticated
      expect(resolveRouteRedirect(user: student, matchedLocation: '/login'), equals('/student'));
      expect(resolveRouteRedirect(user: student, matchedLocation: '/'), equals('/student'));
    });

    test('3. Staff role guard strictly protects faculty panel and rejects unauthorized routes', () {
      // Allowed staff routes
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/staff'), isNull);
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/staff/attendance'), isNull);
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/staff/assignments'), isNull);

      // Denied routes -> redirected to /staff
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/admin'), equals('/staff'));
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/admin/departments'), equals('/staff'));
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/student'), equals('/staff'));
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/student/marks'), equals('/staff'));
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/hod'), equals('/staff'));
      expect(resolveRouteRedirect(user: staff, matchedLocation: '/parent'), equals('/staff'));
    });

    test('4. HOD role guard strictly protects HOD panel and rejects foreign roles', () {
      // Allowed HOD routes
      expect(resolveRouteRedirect(user: hod, matchedLocation: '/hod'), isNull);
      expect(resolveRouteRedirect(user: hod, matchedLocation: '/hod/students'), isNull);
      expect(resolveRouteRedirect(user: hod, matchedLocation: '/hod/analytics'), isNull);

      // Denied routes -> redirected to /hod
      expect(resolveRouteRedirect(user: hod, matchedLocation: '/admin'), equals('/hod'));
      expect(resolveRouteRedirect(user: hod, matchedLocation: '/student'), equals('/hod'));
      expect(resolveRouteRedirect(user: hod, matchedLocation: '/staff'), equals('/hod'));
      expect(resolveRouteRedirect(user: hod, matchedLocation: '/parent'), equals('/hod'));
    });

    test('5. Admin role guard allows admin routes and redirects to /admin from other routes', () {
      // Allowed Admin routes
      expect(resolveRouteRedirect(user: admin, matchedLocation: '/admin'), isNull);
      expect(resolveRouteRedirect(user: admin, matchedLocation: '/admin/users'), isNull);
      expect(resolveRouteRedirect(user: admin, matchedLocation: '/admin/settings'), isNull);

      // Denied routes -> redirected to /admin
      expect(resolveRouteRedirect(user: admin, matchedLocation: '/student'), equals('/admin'));
      expect(resolveRouteRedirect(user: admin, matchedLocation: '/staff'), equals('/admin'));
      expect(resolveRouteRedirect(user: admin, matchedLocation: '/hod'), equals('/admin'));
      expect(resolveRouteRedirect(user: admin, matchedLocation: '/parent'), equals('/admin'));
    });

    test('6. Parent role guard allows parent routes and rejects unauthorized routes', () {
      // Allowed Parent routes
      expect(resolveRouteRedirect(user: parent, matchedLocation: '/parent'), isNull);
      expect(resolveRouteRedirect(user: parent, matchedLocation: '/parent/dashboard'), isNull);
      expect(resolveRouteRedirect(user: parent, matchedLocation: '/parent/attendance'), isNull);
      expect(resolveRouteRedirect(user: parent, matchedLocation: '/parent/marks'), isNull);

      // Denied routes -> redirected to /parent
      expect(resolveRouteRedirect(user: parent, matchedLocation: '/student'), equals('/parent'));
      expect(resolveRouteRedirect(user: parent, matchedLocation: '/staff'), equals('/parent'));
      expect(resolveRouteRedirect(user: parent, matchedLocation: '/hod'), equals('/parent'));
      expect(resolveRouteRedirect(user: parent, matchedLocation: '/admin'), equals('/parent'));
    });

    testWidgets('6. NotFoundScreen renders premium 404 experience with UniSphere branding', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotFoundScreen(location: '/random-page-test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('404'), findsOneWidget);
      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.textContaining('/random-page-test'), findsOneWidget);
      expect(find.byIcon(Icons.explore_off_rounded), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
