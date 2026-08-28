import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/theme/app_animations.dart';
import 'package:unisphere/services/auth_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final FocusNode _emailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isEmailSent = false;
  bool _isInputFocused = false;
  String _submittedEmail = '';

  // Resend cooldown timer
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _emailFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isInputFocused = _emailFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isEmailSent = true;
          _submittedEmail = email;
          _isLoading = false;
        });
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception:', '').trim(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0 || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(_submittedEmail);
      if (mounted) {
        HapticFeedback.lightImpact();
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reset link resent successfully!',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEmailApp() async {
    final Uri mailUri = Uri(scheme: 'mailto');
    try {
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri, mode: LaunchMode.externalApplication);
      } else {
        final webmailUri = Uri.parse('https://mail.google.com');
        if (await canLaunchUrl(webmailUri)) {
          await launchUrl(webmailUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please open your email client to check your messages.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _handleBack() {
    if (_isEmailSent) {
      setState(() {
        _isEmailSent = false;
        _cooldownTimer?.cancel();
        _cooldownSeconds = 0;
      });
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _isEmailSent ? _buildCheckEmailView() : _buildEnterEmailView(),
        ),
      ),
    );
  }

  /// Top navigation bar with circular back button
  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: AppPressable(
        onTap: _handleBack,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  /// View 1: Enter Email Screen (Aligned with Unisphere Theme)
  Widget _buildEnterEmailView() {
    return KeyedSubtree(
      key: const ValueKey('enter_email_view'),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 28),

                  // Title
                  const Text(
                    'Forgot Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Enter your email address to receive a reset link and regain access to your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Rounded Pill Email Input
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    onFieldSubmitted: (_) => _handleContinue(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      hintText: 'Email address',
                      hintStyle: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 18, right: 12),
                        child: Icon(
                          Icons.email_outlined,
                          color: _isInputFocused ? AppColors.primary : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 24),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your email address';
                      }
                      final trimmed = val.trim();
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(trimmed)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Brand Primary Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: AppPressable(
                      onTap: _isLoading ? null : _handleContinue,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.32),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.asset(
                                        'assets/tibsy-dp.gif',
                                        width: 22,
                                        height: 22,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Sending Link...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Back to Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Remember your password? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// View 2: Check Email Screen (Aligned with Unisphere Theme)
  Widget _buildCheckEmailView() {
    return KeyedSubtree(
      key: const ValueKey('check_email_view'),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTopBar(),
                const SizedBox(height: 28),

                // Animated Brand Email Badge
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mark_email_read_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Check Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle with highlighted email
                const Text(
                  'We have sent a password reset link to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                // Highlighted recipient pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _submittedEmail,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Please click the link in the email to reset your password. If you do not see it in your inbox, please check your spam folder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Open Email App Button (Brand Primary)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: AppPressable(
                    onTap: _openEmailApp,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mail_outline_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Open Email App',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Back to Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.go('/login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      backgroundColor: AppColors.cardBackground,
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Resend Email option with countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the email? ",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (_cooldownSeconds > 0)
                      Text(
                        'Resend in ${_cooldownSeconds}s',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _handleResend,
                        child: const Text(
                          'Resend link',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
