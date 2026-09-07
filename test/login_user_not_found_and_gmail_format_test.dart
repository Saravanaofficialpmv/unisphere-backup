import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/screens/auth/auth_screen.dart';
import 'package:unisphere/services/auth_service.dart';

class MockFailingAuthService implements AuthService {
  @override
  UserModel? get currentUser => null;

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(null);

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (email == 'notfound@gmail.com') {
      throw 'User not found. No account is registered with this email address. Please check your email or Sign Up.';
    }
    if (email == 'wrongpass@gmail.com') {
      throw 'Incorrect password. Please verify your password or use "Forgot password".';
    }
  }

  @override
  Future<void> registerWithEmail(String email, String password, String name, UserRole role, {String? phoneNumber, Map<String, dynamic>? metadata}) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> updateUserProfile(UserModel updatedUser) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> ensureAuthReady() async {}

  @override
  Stream<fb.User?>? get firebaseUserStream => null;
}

void main() {
  group('Login Page - Gmail Format & User Not Found Tests', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(500, 1200);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('1. Login screen displays clean Email Address label and hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(MockFailingAuthService()),
          ],
          child: const MaterialApp(
            home: AuthScreen(isInitialSignUp: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check clean Email Address label and ensure badge is removed
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Gmail format (@gmail.com)'), findsNothing);

      // Check hint text in email field
      expect(find.text('yourname@gmail.com'), findsOneWidget);
    });

    testWidgets('2. Entering invalid/non-Gmail format shows validation error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(MockFailingAuthService()),
          ],
          child: const MaterialApp(
            home: AuthScreen(isInitialSignUp: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find email and password fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsAtLeastNWidgets(2));

      // Clear email and type non-gmail / missing @
      await tester.enterText(textFields.first, 'studentwithoutdomain');
      await tester.pumpAndSettle();

      // Tap Log In to trigger validation
      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Gmail format required: must include @gmail.com'), findsOneWidget);

      // Test with non-gmail domain like @yahoo.com
      await tester.enterText(textFields.first, 'testuser@yahoo.com');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid Gmail address (@gmail.com)'), findsOneWidget);
    });

    testWidgets('3. Quick append @gmail.com helper works when typing a username', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(MockFailingAuthService()),
          ],
          child: const MaterialApp(
            home: AuthScreen(isInitialSignUp: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'saravanapmv');
      await tester.pumpAndSettle();

      // Tap to append @gmail.com
      expect(find.text('Tap to append @gmail.com'), findsOneWidget);
      await tester.tap(find.text('Tap to append @gmail.com'));
      await tester.pumpAndSettle();

      // The field should now contain the complete Gmail address
      expect(find.text('saravanapmv@gmail.com'), findsOneWidget);
    });

    testWidgets('4. Small User not found text displays under email field when user is not registered', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(MockFailingAuthService()),
          ],
          child: const MaterialApp(
            home: AuthScreen(isInitialSignUp: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'notfound@gmail.com');
      await tester.enterText(textFields.at(1), 'ValidPassword123!');
      await tester.pumpAndSettle();

      // Tap Log In button
      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Verify small "User not found" text is displayed under the email field
      expect(find.text('User not found'), findsWidgets);

      // Verify big banner text is NOT displayed
      expect(find.text("Don't have an account registered with this email?"), findsNothing);

      // Verify typing in the email field clears the User not found error
      await tester.enterText(textFields.first, 'newemail@gmail.com');
      await tester.pumpAndSettle();
      expect(find.text('User not found'), findsNothing);
    });
  });
}
