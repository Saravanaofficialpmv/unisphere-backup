import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/responsive/responsive_breakpoints.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/apple_glass_card.dart';

/// Clean, responsive 404 Route-Not-Found experience for UniSphere ERP Web & Mobile.
class NotFoundScreen extends ConsumerWidget {
  final String? location;

  const NotFoundScreen({super.key, this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = AppResponsive.isDesktop(context);
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;

    void handleGoHome() {
      if (user == null) {
        context.go('/login');
        return;
      }
      final target = switch (user.role) {
        UserRole.admin => '/admin',
        UserRole.hod => '/hod',
        UserRole.student => '/student',
        UserRole.staff || UserRole.advisor => '/staff',
        UserRole.parent => '/parent',
        _ => '/login',
      };
      context.go(target);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 540 : 420,
              ),
              child: AppleGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                borderRadius: 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Institutional Badge / Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.explore_off_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Big 404 Headline
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        '404',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    const Text(
                      'Page Not Found',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle description
                    Text(
                      location != null && location!.isNotEmpty && location != '/'
                          ? 'We couldn\'t find any active module or page at "$location".'
                          : 'The page you are looking for doesn\'t exist, has moved, or is temporarily unavailable.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Return Home / Dashboard Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: handleGoHome,
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: Text(
                          user != null ? 'Return to Dashboard' : 'Return to Login',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    if (user != null) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary,
                        ),
                        child: const Text(
                          'Switch Account / Sign Out',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
