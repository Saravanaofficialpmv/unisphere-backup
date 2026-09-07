import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/screens/auth/auth_screen.dart';
import 'package:unisphere/services/auth_service.dart';

class _MockWebAuthService implements AuthService {
  bool signInWithGoogleCalled = false;
  UserModel? _mockCurrentUser;
  final StreamController<UserModel?> _controller = StreamController<UserModel?>.broadcast();

  @override
  UserModel? get currentUser => _mockCurrentUser;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Stream<fb.User?>? get firebaseUserStream => null;

  @override
  Future<void> ensureAuthReady() async {}

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    _mockCurrentUser = UserModel(
      uid: 'GGL-TEST-123',
      email: 'testuser@gmail.com',
      fullName: 'Test Google User',
      role: UserRole.student,
      profileImageUrl: 'https://lh3.googleusercontent.com/a/test',
    );
    _controller.add(_mockCurrentUser);
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String name,
    UserRole role, {
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> updateUserProfile(UserModel updatedUser) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    _mockCurrentUser = null;
    _controller.add(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Web Authentication Tests', () {
    testWidgets('1. Google Auth button renders on login screen and triggers signInWithGoogle()', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockAuth = _MockWebAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AuthScreen(isInitialSignUp: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Google button presence
      final googleBtn = find.widgetWithText(OutlinedButton, 'Google');
      expect(googleBtn, findsWidgets);

      // Tap the Google Sign-In button
      await tester.tap(googleBtn.first);
      await tester.pump();

      expect(mockAuth.signInWithGoogleCalled, isTrue);
    });

    testWidgets('2. Google Auth button also renders on signup screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockAuth = _MockWebAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AuthScreen(isInitialSignUp: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Google button presence on signup view
      final googleBtn = find.widgetWithText(OutlinedButton, 'Google');
      expect(googleBtn, findsWidgets);
    });

    test('3. Google user profile model preserves photoUrl and default student role', () {
      final googleUser = UserModel(
        uid: 'GGL-98765',
        email: 'alex.student@gmail.com',
        fullName: 'Alex Student',
        role: UserRole.student,
        profileImageUrl: 'https://lh3.googleusercontent.com/photo.jpg',
        metadata: {'photoUrl': 'https://lh3.googleusercontent.com/photo.jpg'},
      );

      expect(googleUser.role, UserRole.student);
      expect(googleUser.profileImageUrl, 'https://lh3.googleusercontent.com/photo.jpg');
      expect(googleUser.metadata?['photoUrl'], 'https://lh3.googleusercontent.com/photo.jpg');
    });
  });
}
