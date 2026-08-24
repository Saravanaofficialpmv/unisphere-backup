import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/screens/auth/auth_screen.dart';
import 'package:unisphere/screens/auth/request_submitted_screen.dart';
import 'package:unisphere/screens/student/student_dashboard.dart';
import 'package:unisphere/screens/parent/parent_dashboard.dart';
import 'package:unisphere/screens/onboarding/onboarding_screen.dart';

import 'package:unisphere/screens/admin/admin_shell.dart';
import 'package:unisphere/screens/hod/hod_shell.dart';
import 'package:unisphere/screens/student/cgpa_details_screen.dart';
import 'package:unisphere/screens/features/leetcode_detail_screen.dart';
import 'package:unisphere/screens/features/github_detail_screen.dart';
import 'package:unisphere/screens/student/modules/student_resume_screen.dart';

import 'package:unisphere/screens/splash/splash_screen.dart';
import 'package:unisphere/screens/common/loader_preview_screen.dart';
import 'package:unisphere/screens/staff/staff_details_screen.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';
import 'package:unisphere/core/theme/app_animations.dart';

import 'dart:async';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final routerNotifierProvider = Provider<GoRouterRefreshStream>((ref) {
  return GoRouterRefreshStream(ref.watch(authServiceProvider).authStateChanges);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerNotifierProvider);
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final user = authService.currentUser;
      final isAuth = user != null;

      debugPrint('Router: isAuth=$isAuth, path=${state.matchedLocation}');

      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      final isSignup = state.matchedLocation == '/signup';
      final isRequestSubmitted = state.matchedLocation == '/request-submitted';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isPreview = state.matchedLocation == '/loader-preview';

      if (isPreview || isSplash) return null;

      if (!isAuth) {
        if (isLogin || isOnboarding || isSignup || isRequestSubmitted) return null;
        return '/onboarding';
      }

      if (isAuth && (isLogin || isSignup || isOnboarding)) {
        switch (user.role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.hod:
            return '/hod';
          case UserRole.student:
            return '/student';
          case UserRole.staff:
            return '/staff';
          case UserRole.parent:
            return '/parent';
          default:
            return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/loader-preview',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const LoaderPreviewScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) {
          final queryParams = state.uri.queryParameters;
          List<String>? childRegNumbers;
          if (queryParams['childRegNumbers'] != null && queryParams['childRegNumbers']!.isNotEmpty) {
            childRegNumbers = queryParams['childRegNumbers']!
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          } else if (queryParams['id'] != null && queryParams['id']!.isNotEmpty) {
            childRegNumbers = [queryParams['id']!.trim()];
          }

          return AppRouteTransitions.slideFade(
            context: context,
            state: state,
            child: AuthScreen(
              isInitialSignUp: true,
              initialFirstName: queryParams['firstName'],
              initialLastName: queryParams['lastName'],
              initialRole: queryParams['role'],
              initialId: queryParams['id'],
              initialDepartment: queryParams['department'],
              initialPhone: queryParams['phone'],
              initialChildRegNumbers: childRegNumbers,
            ),
          );
        },
      ),
      GoRoute(
        path: '/request-submitted',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const RequestSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const AdminShell(),
        ),
      ),
      GoRoute(
        path: '/hod',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const HodShell(),
        ),
      ),
      GoRoute(
        path: '/student',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(),
        ),
      ),
      GoRoute(
        path: '/staff',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StaffDashboard(),
        ),
      ),
      GoRoute(
        path: '/staff-details',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StaffDetailsScreen(),
        ),
      ),
      GoRoute(
        path: '/parent',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const ParentDashboard(),
        ),
      ),
      GoRoute(
        path: '/cgpa-details',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const CgpaDetailsScreen(),
        ),
      ),
      GoRoute(
        path: '/leetcode-details',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const LeetCodeDetailScreen(),
        ),
      ),
      GoRoute(
        path: '/github-details',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const GitHubDetailScreen(),
        ),
      ),
      GoRoute(
        path: '/resume',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentResumeScreen(),
        ),
      ),
    ],
  );
});
