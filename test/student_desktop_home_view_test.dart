import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/screens/student/student_dashboard.dart';
import 'package:unisphere/screens/student/student_desktop_home_view.dart';
import 'package:unisphere/widgets/student/student_profile_completion_banner.dart';
import 'package:unisphere/widgets/student/student_profile_completion_sheet.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeFirestoreService extends Fake implements FirebaseFirestoreService {
  @override
  Stream<Map<String, dynamic>?> getFullStudentProfileStream(String studentId) {
    return Stream.value(null);
  }

  @override
  Future<Map<String, dynamic>?> getStudentProfileDraft(String studentId) async {
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getFullStudentProfile(String studentId) async {
    return null;
  }

  @override
  Stream<List<Map<String, dynamic>>> getAllTimetablesStream() {
    return Stream.value([]);
  }

  @override
  Stream<List<Map<String, dynamic>>> getAllAssignmentsStream() {
    return Stream.value([]);
  }
}

class FakeAuthService extends Fake implements AuthService {
  final UserModel _user;
  FakeAuthService(this._user);

  @override
  UserModel? get currentUser => _user;

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(_user);
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

    final fakeAuth = FakeAuthService(testStudent);
    final fakeFirestore = FakeFirestoreService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(testStudent)),
          authServiceProvider.overrideWithValue(fakeAuth),
          firebaseFirestoreServiceProvider.overrideWithValue(fakeFirestore),
          allTimetablesStreamProvider.overrideWith((ref) => Stream.value([])),
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
    expect(find.byType(StudentProfileCompletionBanner), findsOneWidget);
    expect(find.textContaining('Complete Your Profile'), findsOneWidget);
    expect(find.text('Complete Profile'), findsOneWidget);
    expect(find.text('Cumulative GPA'), findsOneWidget);
    expect(find.text('Overall Attendance'), findsOneWidget);
    expect(find.text('Tasks & Deadlines'), findsOneWidget);
    expect(find.text('Degree Earned Credits'), findsOneWidget);
    expect(find.text('Student Academic Command Center'), findsOneWidget);

    // Tap Complete Profile button to open sheet
    await tester.tap(find.text('Complete Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(StudentProfileCompletionSheet), findsOneWidget);
  });
}
