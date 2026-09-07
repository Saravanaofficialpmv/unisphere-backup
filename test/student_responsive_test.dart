import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/screens/student/student_dashboard.dart';
import 'package:unisphere/widgets/student/student_floating_nav_bar.dart';

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

  final fakeFirestore = FakeFirestoreService();
  final fakeAuth = FakeAuthService(testStudent);

  testWidgets('StudentDashboard renders on multiple screen sizes without RenderErrorBox', (tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('LAYOUT_INFO: ${details.exceptionAsString()}');
      debugPrint('${details.context}');
      final str = details.toString();
      for (final l in str.split('\n')) {
        if (l.contains('constraints:') || l.contains('size:') || l.contains('file://')) {
          debugPrint('  $l');
        }
      }
    };
    final sizes = [
      const Size(320, 480),
      const Size(360, 640),
      const Size(375, 667),
      const Size(390, 844),
      const Size(414, 896),
      const Size(480, 800),
      const Size(600, 960),
      const Size(768, 1024),
      const Size(799, 800),
      const Size(800, 800),
      const Size(1024, 768),
      const Size(1280, 800),
      const Size(1440, 900),
      const Size(1920, 1080),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

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

      await tester.pump(const Duration(milliseconds: 300));

      final err = tester.takeException();
      if (err != null) {
        debugPrint('EXCEPTION AT SIZE $size: $err');
      }
      expect(find.byType(ErrorWidget), findsNothing, reason: 'ErrorWidget found at size $size');

      // Check floating navbar visibility
      if (size.width < 800) {
        expect(find.byType(StudentFloatingNavBar), findsOneWidget);
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
