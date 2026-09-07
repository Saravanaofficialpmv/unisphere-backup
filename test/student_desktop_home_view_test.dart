import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/screens/student/student_dashboard.dart';
import 'package:unisphere/screens/student/student_desktop_home_view.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  testWidgets('StudentDashboard renders desktop view on 1280x800', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testStudent = UserModel(
      uid: 'DEMO-STU',
      email: 'saravanapmvofficial@gmail.com',
      fullName: 'Saravanan M',
      name: 'Saravanan M',
      role: UserRole.student,
      metadata: {
        'department': 'Artificial intelligence and Data Science',
        'departmentName': 'Artificial intelligence and Data Science',
        'registerNumber': 'RA2111003010001',
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(testStudent)),
        ],
        child: const MaterialApp(
          home: StudentDashboard(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(StudentDashboard), findsOneWidget);
    expect(find.byType(StudentDesktopHomeView), findsOneWidget);
    expect(find.text('Cumulative GPA'), findsOneWidget);
    expect(find.text('Overall Attendance'), findsOneWidget);
    expect(find.text('Tasks & Deadlines'), findsOneWidget);
    expect(find.text('Degree Earned Credits'), findsOneWidget);
    expect(find.text('Student Academic Command Center'), findsOneWidget);
  });
}
