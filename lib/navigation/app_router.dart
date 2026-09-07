import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/screens/auth/auth_screen.dart';
import 'package:unisphere/screens/auth/forgot_password_screen.dart';
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
import 'package:unisphere/screens/common/not_found_screen.dart';
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

String? resolveRouteRedirect({required UserModel? user, required String matchedLocation}) {
  final isAuth = user != null;

  final isSplash = matchedLocation == '/splash';
  final isLogin = matchedLocation == '/login';
  final isSignup = matchedLocation == '/signup';
  final isForgotPassword = matchedLocation == '/forgot-password';
  final isRequestSubmitted = matchedLocation == '/request-submitted';
  final isOnboarding = matchedLocation == '/onboarding';
  final isPreview = matchedLocation == '/loader-preview';

  if (isPreview || isSplash) return null;

  if (!isAuth) {
    if (isLogin || isOnboarding || isSignup || isForgotPassword || isRequestSubmitted) return null;
    return '/login';
  }

  final targetDashboard = switch (user.role) {
    UserRole.admin => '/admin',
    UserRole.hod => '/hod',
    UserRole.student => '/student',
    UserRole.staff || UserRole.advisor => '/staff',
    UserRole.parent => '/parent',
    _ => '/login',
  };

  if (matchedLocation == '/') {
    return targetDashboard;
  }

  if (isLogin || isSignup || isOnboarding || isForgotPassword) {
    return targetDashboard;
  }

  // Strict cross-role protection: prevent unauthorized users from accessing routes for other roles
  if (matchedLocation.startsWith('/admin') && user.role != UserRole.admin) {
    return targetDashboard;
  }
  if (matchedLocation.startsWith('/hod') && user.role != UserRole.hod) {
    return targetDashboard;
  }
  if (matchedLocation.startsWith('/student') && user.role != UserRole.student) {
    return targetDashboard;
  }
  if (matchedLocation.startsWith('/staff') && user.role != UserRole.staff && user.role != UserRole.advisor) {
    return targetDashboard;
  }
  if (matchedLocation.startsWith('/parent') && user.role != UserRole.parent) {
    return targetDashboard;
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerNotifierProvider);
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      await authService.ensureAuthReady();
      final user = authService.currentUser;
      debugPrint('Router: isAuth=${user != null}, path=${state.matchedLocation}');
      return resolveRouteRedirect(user: user, matchedLocation: state.matchedLocation);
    },
    errorPageBuilder: (context, state) => AppRouteTransitions.slideFade(
      context: context,
      state: state,
      child: NotFoundScreen(location: state.uri.toString()),
    ),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final user = authService.currentUser;
          if (user == null) return '/login';
          return switch (user.role) {
            UserRole.admin => '/admin',
            UserRole.hod => '/hod',
            UserRole.student => '/student',
            UserRole.staff || UserRole.advisor => '/staff',
            UserRole.parent => '/parent',
            _ => '/login',
          };
        },
      ),
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
        path: '/forgot-password',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return AppRouteTransitions.slideFade(
            context: context,
            state: state,
            child: ForgotPasswordScreen(initialEmail: email),
          );
        },
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
              initialRelationship: queryParams['relationship'],
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

      // ─── ADMIN ROUTES ───
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const AdminShell(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const AdminShell(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const AdminShell(initialIndex: 2),
        ),
      ),
      GoRoute(
        path: '/admin/departments',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const AdminShell(initialIndex: 3),
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const AdminShell(initialIndex: 15),
        ),
      ),

      // ─── HOD ROUTES ───
      GoRoute(
        path: '/hod',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const HodShell(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/hod/dashboard',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const HodShell(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/hod/staff',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const HodShell(initialIndex: 3),
        ),
      ),
      GoRoute(
        path: '/hod/students',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const HodShell(initialIndex: 4),
        ),
      ),
      GoRoute(
        path: '/hod/analytics',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const HodShell(initialIndex: 10),
        ),
      ),
      GoRoute(
        path: '/hod/settings',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const HodShell(initialIndex: 11),
        ),
      ),

      // ─── STUDENT ROUTES ───
      GoRoute(
        path: '/student',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/student/profile',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(initialIndex: 18),
        ),
      ),
      GoRoute(
        path: '/student/attendance',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(initialIndex: 3),
        ),
      ),
      GoRoute(
        path: '/student/assignments',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(initialIndex: 2),
        ),
      ),
      GoRoute(
        path: '/student/tasks',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(initialIndex: 2),
        ),
      ),
      GoRoute(
        path: '/student/marks',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(initialIndex: 4),
        ),
      ),
      GoRoute(
        path: '/student/exams',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(initialIndex: 5),
        ),
      ),
      GoRoute(
        path: '/student/fees',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StudentDashboard(initialIndex: 15),
        ),
      ),

      // ─── STAFF ROUTES ───
      GoRoute(
        path: '/staff',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StaffDashboard(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/staff/profile',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StaffDashboard(initialIndex: 20),
        ),
      ),
      GoRoute(
        path: '/staff/attendance',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StaffDashboard(initialIndex: 7),
        ),
      ),
      GoRoute(
        path: '/staff/assignments',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StaffDashboard(initialIndex: 4),
        ),
      ),
      GoRoute(
        path: '/staff/marks',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StaffDashboard(initialIndex: 8),
        ),
      ),

      // ─── PARENT ROUTES ───
      GoRoute(
        path: '/parent',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const ParentDashboard(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/parent/dashboard',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const ParentDashboard(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/parent/attendance',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const ParentDashboard(initialIndex: 1),
        ),
      ),
      GoRoute(
        path: '/parent/marks',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const ParentDashboard(initialIndex: 2),
        ),
      ),
      GoRoute(
        path: '/parent/fees',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const ParentDashboard(initialIndex: 0),
        ),
      ),

      // ─── STANDALONE & DEEP LINK ROUTES ───
      GoRoute(
        path: '/staff-details',
        pageBuilder: (context, state) => AppRouteTransitions.slideFade(
          context: context,
          state: state,
          child: const StaffDetailsScreen(),
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
