import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/user_session_service.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

/// App Startup & Initialization Screen (Section 1)
/// Initializes essential services, validates user session & role, and routes smoothly.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusLabel = 'Loading UNISPHERE...';
  String? _statusSubtitle = 'Initializing campus portal services...';
  final List<Timer> _activeTimers = [];

  @override
  void initState() {
    super.initState();
    _startStartupSequence();
  }

  void _startStartupSequence() {
    // Stage 1: Brief branded appearance
    _schedule(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _statusLabel = 'Verifying Session...';
        _statusSubtitle = 'Checking authentication & account permissions';
      });

      // Stage 2: Verify user auth & role data
      _schedule(const Duration(milliseconds: 600), () async {
        if (!mounted) return;
        final authService = ref.read(authServiceProvider);
        final user = authService.currentUser;

        if (user != null) {
          final isReturning = await ref.read(userSessionServiceProvider).isReturningUser(user.uid);
          final firstName = user.fullName.trim().split(' ').first;
          final prefix = isReturning ? 'Welcome back' : 'Welcome';
          if (mounted) {
            setState(() {
              _statusLabel = '$prefix${firstName.isNotEmpty ? ', $firstName' : ''}';
              _statusSubtitle = 'Loading your ${_getRoleTitle(user.role)} portal...';
            });
          }
        }

        // Stage 3: Smooth routing to correct dashboard
        _schedule(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          if (user == null) {
            context.go('/onboarding');
          } else {
            switch (user.role) {
              case UserRole.admin:
                context.go('/admin');
                break;
              case UserRole.hod:
                context.go('/hod');
                break;
              case UserRole.student:
                context.go('/student');
                break;
              case UserRole.staff:
              case UserRole.advisor:
                context.go('/staff');
                break;
              case UserRole.parent:
                context.go('/parent');
                break;
              default:
                context.go('/login');
            }
          }
        });
      });
    });
  }

  void _schedule(Duration delay, VoidCallback action) {
    final timer = Timer(delay, action);
    _activeTimers.add(timer);
  }

  @override
  void dispose() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    super.dispose();
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.hod:
        return 'Department Head';
      case UserRole.student:
        return 'Student';
      case UserRole.staff:
        return 'Faculty';
      case UserRole.advisor:
        return 'Class Advisor';
      case UserRole.parent:
        return 'Parent';
      default:
        return 'Campus';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Loader(
                size: 96,
                label: _statusLabel,
                subtitle: _statusSubtitle,
                spacing: 16,
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'UNISPHERE CAMPUS PORTAL',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
