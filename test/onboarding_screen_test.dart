import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/screens/onboarding/onboarding_screen.dart';
import 'package:unisphere/screens/onboarding/widgets/campus_hero_art.dart';

void main() {
  group('Onboarding Screen Layout Tests', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(393, 852);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('Onboarding renders hero art, floating badge, headline, and dark capsule button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Check CampusHeroArt visual is rendered
      expect(find.byType(CampusHeroArt), findsOneWidget);

      // 2. Check Bold Title & Subtitle
      expect(find.text('Your Entire Campus,\nIn Your Pocket'), findsOneWidget);

      // 3. Check "Already have an account? Login"
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('Already have an account?'),
        ),
        findsOneWidget,
      );

      // 4. Check Blue Capsule CTA Button
      expect(find.text('Get Started 🚀'), findsOneWidget);
    });

    testWidgets('Tapping Get Started navigates directly to role selection step', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Get Started 🚀 -> Enters Role Selection step directly
      await tester.tap(find.text('Get Started 🚀'));
      await tester.pumpAndSettle();

      expect(find.text('Tell Us Who\nYou Are'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Faculty'), findsOneWidget);
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Department (HOD)'), findsOneWidget);
    });

    testWidgets('Role selection updates state and advances to Name step', (WidgetTester tester) async {
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

      // Select Student role
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      // Tap Continue ➔ -> Advances to name step
      await tester.tap(find.text('Continue ➔'));
      await tester.pumpAndSettle();

      expect(find.text('What\'s Your\nFull Name?'), findsOneWidget);
    });
  });
}
