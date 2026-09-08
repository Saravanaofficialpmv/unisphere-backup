import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/core/constants/app_colors.dart';

/// Web-specific Login View using Unisphere's official brand color theme (AppColors.primary)
/// and featuring the Unisphere Smart Campus hero image (webimage.png) on the front,
/// with a 3D card flip animation to the mobile app download screen on the back when Signup is requested.
class WebLoginView extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool obscurePassword;
  final bool isUserNotFoundError;
  final String? loginErrorMessage;
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onLoginPressed;
  final VoidCallback onForgotPasswordPressed;
  final Function(String email, String password, UserRole role) onDemoAutofill;

  const WebLoginView({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.isUserNotFoundError,
    this.loginErrorMessage,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onTogglePasswordVisibility,
    required this.onLoginPressed,
    required this.onForgotPasswordPressed,
    required this.onDemoAutofill,
  });

  @override
  State<WebLoginView> createState() => _WebLoginViewState();
}

class _WebLoginViewState extends State<WebLoginView> with SingleTickerProviderStateMixin {
  // Brand color theme from AppColors
  static const Color _brandPrimary = AppColors.primary; // 0xFF2563EB (Royal Indigo Blue)
  static const Color _webBackground = Color(0xFFF1F5F9); // Slate 100 Neutral Surface

  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipToBack() {
    _flipController.forward();
  }

  void _flipToFront() {
    _flipController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _webBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 880;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 1060 : 540,
                  minHeight: isWideScreen ? 600 : 0,
                ),
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * math.pi;
                    final isFront = angle < (math.pi / 2);

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _brandPrimary.withValues(alpha: 0.22),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _brandPrimary.withValues(alpha: 0.10),
                              blurRadius: 48,
                              spreadRadius: 2,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: isFront
                            ? (isWideScreen ? _buildWideSplitLayout() : _buildNarrowStackedLayout())
                            : Transform(
                                transform: Matrix4.identity()..rotateY(math.pi),
                                alignment: Alignment.center,
                                child: _buildFlippedBackLayout(isWideScreen: isWideScreen),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FRONT FACE: LOGIN INTERFACE (Web Split Layout)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWideSplitLayout() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Side: White Login Form Panel
          Expanded(
            flex: 11,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: _buildFormContent(),
            ),
          ),

          // Right Side: Unisphere Smart Campus Hero Image (webimage.png)
          Expanded(
            flex: 12,
            child: _buildRightImagePanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowStackedLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Image Banner
        SizedBox(
          height: 280,
          child: _buildRightImagePanel(isCompact: true),
        ),

        // Bottom Form
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: _buildFormContent(),
        ),
      ],
    );
  }

  Widget _buildRightImagePanel({bool isCompact = false}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero Image Asset
        Image.asset(
          'assets/webimage.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.school_rounded, color: Colors.white54, size: 64),
            ),
          ),
        ),

        // Subtle gradient vignette at bottom for seamless depth & contrast
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: isCompact ? 100 : 160,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
        ),

        // Bottom title badge overlay
        Positioned(
          left: 28,
          right: 28,
          bottom: isCompact ? 16 : 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF60A5FA), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Unified Campus Platform',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome to Unisphere',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Next-generation institutional operations, academics & analytics.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBrandHeader(),
          const SizedBox(height: 32),

          _buildRoleTabs(),
          const SizedBox(height: 26),

          _buildEmailField(),
          const SizedBox(height: 18),

          _buildPasswordField(),
          const SizedBox(height: 24),

          _buildLoginButton(),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: widget.onForgotPasswordPressed,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: const Text(
                'Forgot password ?',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _buildMobileExclusiveNotice(),
          const SizedBox(height: 18),

          _buildDemoAccessBar(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _brandPrimary.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'UNISPHERE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Campus Personalized',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                color: _brandPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildRoleTabItem('Students Login', UserRole.student),
          const SizedBox(width: 24),
          _buildRoleTabItem('Parents Login', UserRole.parent),
          const SizedBox(width: 24),
          _buildRoleTabItem('Staff Login', UserRole.staff),
          const SizedBox(width: 24),
          _buildRoleTabItem('Admin Login', UserRole.admin),
        ],
      ),
    );
  }

  Widget _buildRoleTabItem(String label, UserRole role) {
    final isSelected = widget.selectedRole == role;

    return InkWell(
      onTap: () => widget.onRoleChanged(role),
      borderRadius: BorderRadius.circular(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _brandPrimary : const Color(0xFF64748B),
                letterSpacing: 0.1,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.5,
            width: isSelected ? 80 : 0,
            decoration: BoxDecoration(
              color: isSelected ? _brandPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: _getEmailHintText(),
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFFBFBFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.isUserNotFoundError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _brandPrimary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
            ),
          ),
          validator: (val) {
            final clean = val?.trim() ?? '';
            if (clean.isEmpty) return 'Please enter your username or email';
            return null;
          },
        ),
        if (widget.isUserNotFoundError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                SizedBox(width: 4),
                Text(
                  'User not found with this email',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getEmailHintText() {
    switch (widget.selectedRole) {
      case UserRole.student:
        return 'Username/Email (or Student ID)';
      case UserRole.parent:
        return 'Parent Email Address';
      case UserRole.staff:
      case UserRole.advisor:
        return 'Faculty / Staff Email';
      case UserRole.admin:
        return 'Admin Email (admin@unisphere.edu)';
      case UserRole.hod:
        return 'HOD Email';
      case UserRole.unknown:
        return 'Username/Email';
    }
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: widget.passwordController,
      obscureText: widget.obscurePassword,
      style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E293B)),
      onFieldSubmitted: (_) => widget.onLoginPressed(),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFFBFBFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(
            widget.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF64748B),
            size: 20,
          ),
          onPressed: widget.onTogglePasswordVisibility,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _brandPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Please enter password';
        if (val.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _brandPrimary.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          elevation: 1,
          shadowColor: _brandPrimary.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: widget.isLoading
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Signing In...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildMobileExclusiveNotice() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              InkWell(
                onTap: _flipToBack,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Signup',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _brandPrimary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.flip_rounded, size: 14, color: _brandPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Signup to download our Android application',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccessBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: _brandPrimary),
              SizedBox(width: 4),
              Text(
                'Demo Quick Access (Tap to Autofill)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _demoChip('Student', 'saravanapmvofficial@gmail.com', 'Sivamani9698pmv\$', UserRole.student),
              _demoChip('Parent', 'heydigitals.care@gmail.com', 'Sivamani9698pmv\$', UserRole.parent),
              _demoChip('Staff', 'Awenests.care@gmail.com', 'Unisphere@123', UserRole.staff),
              _demoChip('HOD', 'unispherecrm.official@gmail.com', 'Unisphere@123', UserRole.hod),
              _demoChip('Admin', 'admin@unisphere.edu', 'AdminPass123!', UserRole.admin),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoChip(String roleName, String email, String pass, UserRole role) {
    return InkWell(
      onTap: () {
        widget.onDemoAutofill(email, pass, role);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          roleName,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BACK FACE: DOWNLOAD OUR APPLICATION FROM PLAY STORE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFlippedBackLayout({required bool isWideScreen}) {
    if (isWideScreen) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Visual Mobile App Showcase & QR Scanner
            Expanded(
              flex: 10,
              child: Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(40),
                child: _buildBackVisualShowcase(),
              ),
            ),

            // Right Column: Play Store Download Details & Back Button
            Expanded(
              flex: 13,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 44),
                child: _buildBackContentDetails(),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBackVisualShowcase(isCompact: true),
            const SizedBox(height: 24),
            _buildBackContentDetails(isCompact: true),
          ],
        ),
      );
    }
  }

  Widget _buildBackVisualShowcase({bool isCompact = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Icon with Ambient Glow
        Container(
          width: isCompact ? 76 : 92,
          height: isCompact ? 76 : 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _brandPrimary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'UNISPHERE MOBILE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Campus Ecosystem at your fingertips',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),

        // Simulated QR Code Frame
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: 96,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Scan to install on Android',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rating Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
              SizedBox(width: 4),
              Text(
                '4.9 ★ • 2,400+ Active Campus Users',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackContentDetails({bool isCompact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tag Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.android_rounded, color: Color(0xFF10B981), size: 15),
              SizedBox(width: 6),
              Text(
                'MOBILE ONBOARDING ONLY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Main Title
        Text(
          'Download Our Application from Google Play Store',
          style: TextStyle(
            fontSize: isCompact ? 22 : 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        const Text(
          'To ensure campus identity security and automated student verification, new student, parent, and faculty account registration is available exclusively on the Unisphere Mobile App.',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Official Google Play Store Button
        _buildPlayStoreButton(),
        const SizedBox(height: 20),

        // Feature Bullets
        _buildFeatureBullet(Icons.person_add_alt_1_rounded, 'Rapid 3-step registration with digital student ID lookup'),
        const SizedBox(height: 8),
        _buildFeatureBullet(Icons.notifications_active_rounded, 'Real-time attendance alerts, timetable changes & GPA updates'),
        const SizedBox(height: 8),
        _buildFeatureBullet(Icons.shield_rounded, 'Biometric login and verified parent-faculty messaging'),
        const SizedBox(height: 28),

        // Return / Flip Back Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _flipToFront,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'Already Registered? Flip Back to Login',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandPrimary,
              side: BorderSide(color: _brandPrimary.withValues(alpha: 0.4), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayStoreButton() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Unisphere on Google Play Store...'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play Store Icon Graphic
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF34D399),
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GET IT ON',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Google Play',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _brandPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
