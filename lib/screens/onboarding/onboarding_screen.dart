import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/constants/app_departments.dart';
import 'package:unisphere/screens/onboarding/widgets/campus_hero_art.dart';
import 'package:unisphere/services/parent_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Main Step Controller:
  // Step 0: Single Main Onboarding Landing Page
  // Step 1: Role Selection
  // Step 2: Name Input
  // Step 3: Academic / Multi-child Details
  // Step 4: Final Welcome
  final PageController _mainPageController = PageController();
  int _currentMainStep = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  // Multi-child registration controllers for parents
  final List<TextEditingController> _childRegControllers = [TextEditingController()];
  final Map<int, Map<String, dynamic>?> _childMatches = {};
  final Map<int, bool> _isCheckingChild = {};
  final Map<int, String?> _childLookupErrors = {};
  final ParentService _parentService = ParentService();

  // Selection states
  String? _selectedRole;
  String? _selectedDept;
  String _parentRelationship = 'Father';

  // Inline Validation Error States (Highlights boxes in red instead of popup snackbars)
  bool _hasRoleError = false;
  bool _hasNameError = false;
  String _nameErrorMessage = 'Please enter your name';
  bool _hasIdError = false;
  String _idErrorMessage = 'Please enter your ID';
  bool _hasDeptError = false;
  final Set<int> _childErrors = {};

  // Student register number existence checking states
  bool _isCheckingStudentId = false;
  bool _studentIdAlreadyExists = false;
  bool _studentIdAvailable = false;

  final List<String> _roles = ['Student', 'Faculty', 'Department (HOD)', 'Parent'];
  final List<String> _departments = AppDepartments.list;

  void _addChildField() {
    HapticFeedback.lightImpact();
    setState(() {
      _childRegControllers.add(TextEditingController());
    });
  }

  void _removeChildField(int index) {
    if (_childRegControllers.length <= 1) return;
    HapticFeedback.lightImpact();
    setState(() {
      _childRegControllers[index].dispose();
      _childRegControllers.removeAt(index);
      _childMatches.remove(index);
      _isCheckingChild.remove(index);
      _childLookupErrors.remove(index);
      _childErrors.remove(index);
    });
  }

  Future<void> _checkStudentMatch(int index, String regNo) async {
    final clean = regNo.trim().toUpperCase();
    if (_childErrors.contains(index) && clean.length == 12) {
      setState(() => _childErrors.remove(index));
    }

    if (clean.length < 3) {
      if (_childMatches.containsKey(index) || _childLookupErrors.containsKey(index)) {
        setState(() {
          _childMatches.remove(index);
          _isCheckingChild.remove(index);
          _childLookupErrors.remove(index);
        });
      }
      return;
    }

    // Sibling duplicate check
    int? duplicateOf;
    for (int i = 0; i < _childRegControllers.length; i++) {
      if (i != index && _childRegControllers[i].text.trim().toUpperCase() == clean) {
        duplicateOf = i;
        break;
      }
    }

    if (duplicateOf != null) {
      setState(() {
        _childMatches.remove(index);
        _isCheckingChild.remove(index);
        _childLookupErrors[index] = duplicateOf == 0
            ? 'Already added as primary child'
            : 'Already added as Child ${duplicateOf! + 1}';
      });
      return;
    }

    setState(() {
      _isCheckingChild[index] = true;
      _childLookupErrors.remove(index);
    });

    final match = await _parentService.lookupStudentByRegNo(clean);
    if (mounted) {
      if (index >= _childRegControllers.length || _childRegControllers[index].text.trim().toUpperCase() != clean) {
        return;
      }
      int? duplicateCheck;
      for (int i = 0; i < _childRegControllers.length; i++) {
        if (i != index && _childRegControllers[i].text.trim().toUpperCase() == clean) {
          duplicateCheck = i;
          break;
        }
      }

      setState(() {
        _isCheckingChild[index] = false;
        if (duplicateCheck != null) {
          _childMatches.remove(index);
          _childLookupErrors[index] = duplicateCheck == 0
              ? 'Already added as primary child'
              : 'Already added as Child ${duplicateCheck + 1}';
        } else if (match != null) {
          _childMatches[index] = match;
          _childLookupErrors.remove(index);
        } else {
          _childMatches.remove(index);
          if (clean.length == 12 || clean.length >= 8) {
            _childLookupErrors[index] = 'Student not found';
          } else {
            _childLookupErrors.remove(index);
          }
        }
      });
    }
  }

  void _revalidateAllChildMatches() {
    for (int i = 0; i < _childRegControllers.length; i++) {
      _checkStudentMatch(i, _childRegControllers[i].text);
    }
  }

  Future<void> _checkStudentIdExistence(String id) async {
    final clean = id.trim();
    if (_selectedRole != 'Student' || clean.isEmpty) {
      setState(() {
        _isCheckingStudentId = false;
        _studentIdAlreadyExists = false;
        _studentIdAvailable = false;
      });
      return;
    }

    if (clean.length < 12) {
      if (_isCheckingStudentId || _studentIdAlreadyExists || _studentIdAvailable) {
        setState(() {
          _isCheckingStudentId = false;
          _studentIdAlreadyExists = false;
          _studentIdAvailable = false;
          _hasIdError = false;
        });
      }
      return;
    }

    setState(() {
      _isCheckingStudentId = true;
      _studentIdAlreadyExists = false;
      _studentIdAvailable = false;
      _hasIdError = false;
    });

    final firestore = _parentService.firestore;
    bool alreadyExists = false;

    if (firestore != null) {
      try {
        final uq = await firestore
            .collection('users')
            .where('metadata.registerNumber', isEqualTo: clean)
            .limit(1)
            .get();
        if (uq.docs.isNotEmpty) {
          alreadyExists = true;
        }

        if (!alreadyExists) {
          final uDoc = await firestore.collection('users').doc(clean).get();
          if (uDoc.exists) alreadyExists = true;
        }
      } catch (e) {
        debugPrint('Onboarding reg no existence check notice: $e');
      }
    }

    if (!alreadyExists) {
      const existingDemoRegs = [
        'RA2111003010001',
        '917721104012',
        '917722104022',
        '917721104045',
        '922523243100',
      ];
      if (existingDemoRegs.contains(clean) || existingDemoRegs.contains(clean.toUpperCase())) {
        alreadyExists = true;
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingStudentId = false;
        if (alreadyExists) {
          _studentIdAlreadyExists = true;
          _studentIdAvailable = false;
          _hasIdError = true;
          _idErrorMessage = 'Already registered';
        } else {
          _studentIdAlreadyExists = false;
          _studentIdAvailable = true;
          _hasIdError = false;
        }
      });
    }
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    _mainPageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onStepNext() {
    HapticFeedback.lightImpact();
    if (_currentMainStep == 0) {
      _goToStep(1);
      return;
    }

    if (_currentMainStep < 4) {
      // Step 1: Role Validation
      if (_currentMainStep == 1) {
        if (_selectedRole == null) {
          HapticFeedback.mediumImpact();
          setState(() => _hasRoleError = true);
          return;
        }
      }

      // Step 2: Name Validation (Must be letters only)
      if (_currentMainStep == 2) {
        final nameText = _nameController.text.trim();
        if (nameText.isEmpty) {
          HapticFeedback.mediumImpact();
          setState(() {
            _hasNameError = true;
            _nameErrorMessage = 'Please enter your name';
          });
          return;
        }
        if (RegExp(r'[0-9]').hasMatch(nameText) || !RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(nameText)) {
          HapticFeedback.mediumImpact();
          setState(() {
            _hasNameError = true;
            _nameErrorMessage = 'Name must contain letters only';
          });
          return;
        }
      }

      // Step 3: Details Validation (Register numbers must be 12 digits)
      if (_currentMainStep == 3) {
        if (_selectedRole == 'Parent') {
          _childErrors.clear();
          final seenRegs = <String>{};
          bool hasDuplicate = false;
          bool hasUnregistered = false;
          for (int i = 0; i < _childRegControllers.length; i++) {
            final reg = _childRegControllers[i].text.trim().toUpperCase();
            if (reg.isEmpty || reg.length != 12) {
              _childErrors.add(i);
            } else if (seenRegs.contains(reg)) {
              _childErrors.add(i);
              hasDuplicate = true;
            } else {
              seenRegs.add(reg);
            }

            final match = _childMatches[i];
            if (match == null && reg.length == 12) {
              _childErrors.add(i);
              hasUnregistered = true;
            }
          }
          if (_childErrors.isNotEmpty) {
            HapticFeedback.mediumImpact();
            setState(() {});
            if (hasDuplicate) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot use the same register number twice as a sibling.'),
                  backgroundColor: Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (hasUnregistered) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid registered student register numbers.'),
                  backgroundColor: Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        } else {
          bool hasError = false;
          final idText = _idController.text.trim();
          if (idText.isEmpty) {
            _hasIdError = true;
            _idErrorMessage = 'Please enter your ID';
            hasError = true;
          } else if (_selectedRole == 'Student' && (idText.length != 12 || !RegExp(r'^[0-9]{12}$').hasMatch(idText))) {
            _hasIdError = true;
            _idErrorMessage = 'Register number must be 12 digits';
            hasError = true;
          } else if (_selectedRole == 'Student' && _studentIdAlreadyExists) {
            _hasIdError = true;
            _idErrorMessage = 'Already registered';
            hasError = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('An account already exists with this register number. Please sign in directly.'),
                backgroundColor: Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (_selectedDept == null) {
            _hasDeptError = true;
            hasError = true;
          }
          if (hasError) {
            HapticFeedback.mediumImpact();
            setState(() {});
            return;
          }
        }
      }

      _goToStep(_currentMainStep + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    if (_currentMainStep > 0) {
      _goToStep(_currentMainStep - 1);
    }
  }

  void _completeOnboarding() {
    final name = _nameController.text.trim();
    final role = _selectedRole ?? 'Student';

    final nameParts = name.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final queryParams = <String, String>{
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'department': _selectedDept ?? '',
    };

    if (role == 'Parent') {
      final validRegs = _childRegControllers
          .map((c) => c.text.trim().toUpperCase())
          .where((t) => t.isNotEmpty)
          .toList();
      queryParams['id'] = validRegs.isNotEmpty ? validRegs.first : '';
      queryParams['childRegNumbers'] = validRegs.join(',');
      queryParams['phone'] = _parentPhoneController.text.trim();
      queryParams['relationship'] = _parentRelationship;
    } else {
      queryParams['id'] = _idController.text.trim();
    }

    context.go(
      Uri(
        path: '/signup',
        queryParameters: queryParams,
      ).toString(),
    );
  }

  @override
  void dispose() {
    _mainPageController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _parentPhoneController.dispose();
    for (final controller in _childRegControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroHeight = (size.height * 0.46).clamp(300.0, 440.0);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 80;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── MAIN PAGE CONTENT ──────────────────────────────────────────
            Positioned.fill(
              child: PageView(
                controller: _mainPageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentMainStep = index),
                children: [
                  _buildMainIntroPage(heroHeight),
                  _buildRoleSelectionStep(heroHeight),
                  _buildNameInputStep(heroHeight),
                  _buildDetailsStep(heroHeight),
                  _buildFinalWelcomeStep(heroHeight),
                ],
              ),
            ),

            // ── FLOATING TOP APP BAR & NAVIGATION ──────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildTopOverlayHeader(),
              ),
            ),

            // ── FLOATING BOTTOM CONTROLS BAR ───────────────────────────────
            if (!isKeyboardOpen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: _buildBottomControlsBar(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── FLOATING TOP HEADER (BACK BUTTON ON SUBSEQUENT STEPS) ─────────────────
  Widget _buildTopOverlayHeader() {
    final showBackButton = _currentMainStep > 0;
    if (!showBackButton) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: _onBack,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }

  // ── SINGLE MAIN INTRO LANDING PAGE (EXACT TARGET LAYOUT) ────────────────
  Widget _buildMainIntroPage(double heroHeight) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Immersive Hero Visual
          CampusHeroArt(height: heroHeight),

          // 2. Content Card
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bold Headline
                const Text(
                  'Your Entire Campus,\nIn Your Pocket',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.8,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),

                // Subtitle
                const Text(
                  'Effortlessly manage attendance, grades, notices, and smart campus workflows in one unified platform.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 75),

                // Already have an account? Login
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120), // clearance for bottom floating bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FLOATING FEATURE PILL BADGE ──────────────────────────────────────────
  Widget _buildFeatureBadge({
    String? icon,
    String? imageAsset,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageAsset != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                imageAsset,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 16, color: AppColors.primary),
              ),
            )
          else if (icon != null)
            Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEAMLESS FULL-BLEED SOFT BLUE GRADIENT WRAPPER (STEPS 1-4) ────────────
  Widget _buildStepBackgroundWithSoftGradient({required Widget child}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Rich Sky Blue Linear Base Canopy
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFBFDBFE), // Vibrant Soft Sky Blue (Blue-200)
                Color(0xFFDBEAFE), // Soft Blue Tint (Blue-100)
                Color(0xFFEFF6FF), // Whispering Ice Blue (Blue-50)
                Color(0xFFF8FAFC), // Ultra Light Mist
                Colors.white,      // Pure White Seamless
              ],
              stops: [0.0, 0.18, 0.36, 0.54, 0.72],
            ),
          ),
        ),

        // 2. Soft Ambient Luminous Radial Glow (in top corners)
        Positioned(
          top: -60,
          left: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF60A5FA).withValues(alpha: 0.30),
                  const Color(0xFF93C5FD).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -40,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.25),
                  const Color(0xFF93C5FD).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Step Scrollable Content
        child,
      ],
    );
  }

  // ── STEP 1: ROLE SELECTION ───────────────────────────────────────────────
  Widget _buildRoleSelectionStep(double heroHeight) {
    final topClearance = MediaQuery.of(context).padding.top + 58.0;

    return _buildStepBackgroundWithSoftGradient(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topClearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureBadge(icon: '🎓', label: 'Personalize Your Hub'),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Tell Us Who\nYou Are',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.8,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (_hasRoleError)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Select your role',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'We will tailor your campus workspace and permissions for your role.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                // 2x2 Roles Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.08,
                  ),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role;
                    return _buildRoleCard(role, isSelected);
                  },
                ),
                const SizedBox(height: 130), // Ample clearance for floating bottom bar
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildRoleCard(String role, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedRole = role;
          _hasRoleError = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : (_hasRoleError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : (_hasRoleError ? 1.8 : 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0F172A).withValues(alpha: 0.22)
                  : (_hasRoleError ? const Color(0xFFEF4444).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03)),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top-right checkmark when selected
            if (isSelected)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),

            // Centered Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getRoleIcon(role),
                      size: 26,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    role,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 2: NAME INPUT ───────────────────────────────────────────────────
  Widget _buildNameInputStep(double heroHeight) {
    final isParent = _selectedRole == 'Parent';
    final topClearance = MediaQuery.of(context).padding.top + 58.0;

    return _buildStepBackgroundWithSoftGradient(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topClearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureBadge(icon: '👤', label: 'Profile Setup'),
                  const SizedBox(height: 14),
                  Text(
                    isParent ? 'Parent / Guardian\nFull Name' : 'What\'s Your\nFull Name?',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.14,
                      letterSpacing: -0.8,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isParent
                        ? 'This is how student advisors, faculty, and administration identify you.'
                        : 'This is how you will appear across attendance rosters, assignments, and campus notices.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Name Input Field (Highlighted with red border if empty / invalid)
                  _buildStyledInputField(
                    controller: _nameController,
                    hint: isParent ? 'Enter parent / guardian full name' : 'Enter your full name',
                    icon: isParent ? Icons.family_restroom_rounded : Icons.person_outline_rounded,
                    label: 'Full Legal Name',
                    hasError: _hasNameError,
                    errorMessage: _nameErrorMessage,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]')),
                    ],
                    onChanged: (val) {
                      if (_hasNameError && val.trim().isNotEmpty) {
                        setState(() => _hasNameError = false);
                      }
                    },
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 3: DETAILS (ACADEMIC / MULTI-CHILD) ─────────────────────────────
  Widget _buildDetailsStep(double heroHeight) {
    final isParent = _selectedRole == 'Parent';
    final topClearance = MediaQuery.of(context).padding.top + 58.0;

    return _buildStepBackgroundWithSoftGradient(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topClearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: isParent
                  ? _buildParentWardLinkingSection()
                  : _buildStandardDetailsSection(),
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  void _openDepartmentPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _departments
                .where((d) => d.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72,
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Department',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${_departments.length} programs',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search Field
                    TextField(
                      autofocus: false,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search department name...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // List
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final dept = filtered[index];
                          final isSelected = _selectedDept == dept;

                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedDept = dept;
                                _hasDeptError = false;
                              });
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 20,
                                    color: isSelected ? Colors.white : AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      dept,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStandardDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureBadge(icon: '🏛️', label: 'Academic Linking'),
        const SizedBox(height: 12),
        const Text(
          'Campus ID &\nDepartment',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.14,
            letterSpacing: -0.8,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Provide your institution credentials to link your academic records.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14.5, height: 1.4),
        ),
        const SizedBox(height: 26),

        // Campus ID Field (Highlighted with red border if empty / invalid / already exists)
        _buildStyledInputField(
          controller: _idController,
          hint: _selectedRole == 'Student' ? 'Enter 12-digit register number' : 'Enter your campus ID / employee ID',
          icon: Icons.badge_outlined,
          label: _selectedRole == 'Student' ? 'Campus Register Number' : 'Campus Register / Employee ID',
          keyboardType: _selectedRole == 'Student' ? TextInputType.number : null,
          inputFormatters: _selectedRole == 'Student'
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ]
              : null,
          hasError: _hasIdError || _studentIdAlreadyExists,
          isSuccess: _selectedRole == 'Student' && _studentIdAvailable,
          errorMessage: _idErrorMessage,
          suffixIcon: _selectedRole == 'Student'
              ? (_isCheckingStudentId
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : (_studentIdAlreadyExists
                      ? const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20)
                      : (_studentIdAvailable
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                          : null)))
              : null,
          bottomWidget: _selectedRole == 'Student' && _studentIdAlreadyExists
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 15),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Already exists',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => context.go('/auth?mode=login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Sign In ➔',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          onChanged: (val) {
            if (_hasIdError && val.trim().isNotEmpty) {
              setState(() => _hasIdError = false);
            }
            if (_selectedRole == 'Student') {
              _checkStudentIdExistence(val);
            }
          },
        ),
        const SizedBox(height: 24),

        // Department Picker Field (Highlighted with red border if empty)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Academic Department',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: _hasDeptError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
              ),
            ),
            if (_hasDeptError)
              const Text(
                'Please select department',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() => _hasDeptError = false);
            _openDepartmentPicker();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _hasDeptError ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasDeptError
                    ? const Color(0xFFEF4444)
                    : (_selectedDept != null ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                width: (_hasDeptError || _selectedDept != null) ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: _hasDeptError ? const Color(0xFFEF4444) : const Color(0xFF475569),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDept ?? 'Select your department',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _selectedDept != null ? FontWeight.w700 : FontWeight.w500,
                      color: _hasDeptError
                          ? const Color(0xFFEF4444)
                          : (_selectedDept != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _selectedDept != null ? const Color(0xFF0F172A).withValues(alpha: 0.08) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedDept != null ? Icons.check_circle_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _hasDeptError
                        ? const Color(0xFFEF4444)
                        : (_selectedDept != null ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParentWardLinkingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureBadge(icon: '👨‍👩‍👧', label: 'Multi-Child Family Portal'),
        const SizedBox(height: 12),
        const Text(
          'Link Your\nChildren',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.14,
            letterSpacing: -0.8,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter register numbers to monitor attendance, grades, and fees for your child or siblings in one portal.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 18),

        // Relationship Selector
        const Text(
          'Your Relationship to Student *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRelationshipChip('Father', Icons.face_6_rounded),
            const SizedBox(width: 8),
            _buildRelationshipChip('Mother', Icons.face_3_rounded),
            const SizedBox(width: 8),
            _buildRelationshipChip('Guardian', Icons.shield_outlined),
          ],
        ),
        const SizedBox(height: 18),

        // Contact phone
        _buildStyledInputField(
          controller: _parentPhoneController,
          hint: 'Enter 10-digit mobile number',
          icon: Icons.phone_outlined,
          label: 'Parent Contact Phone',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 20),

        ...List.generate(_childRegControllers.length, (index) {
          final isPrimary = index == 0;
          final match = _childMatches[index];
          final isChecking = _isCheckingChild[index] == true;
          final text = _childRegControllers[index].text.trim().toUpperCase();
          final isDuplicate = _childRegControllers.asMap().entries.any(
            (e) => e.key != index && e.value.text.trim().toUpperCase() == text && text.isNotEmpty,
          );
          final lookupError = _childLookupErrors[index];
          final hasError = (text.length == 12 || text.length >= 8) && (match == null || isDuplicate) && !isChecking;
          final hasChildError = _childErrors.contains(index) || hasError;
          final errorText = isDuplicate
              ? 'Already added'
              : (lookupError ?? (hasError ? 'Student not found' : null));

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPrimary ? 'Student Register Number' : 'Student Register Number (Child ${index + 1})',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: hasChildError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                      ),
                    ),
                    if (!isPrimary)
                      GestureDetector(
                        onTap: () {
                          _removeChildField(index);
                          _revalidateAllChildMatches();
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _childRegControllers[index],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  onChanged: (val) {
                    _revalidateAllChildMatches();
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter 12-digit register number',
                    hintStyle: TextStyle(
                      color: hasChildError ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: hasChildError ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: hasChildError ? const Color(0xFFEF4444) : const Color(0xFF475569),
                      size: 20,
                    ),
                    suffixIcon: isChecking
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : (match != null && !isDuplicate
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                            : (hasError
                                ? const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20)
                                : null)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: hasChildError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                        width: (hasChildError || (match != null && !isDuplicate)) ? 1.8 : 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: hasChildError
                            ? const Color(0xFFEF4444)
                            : (match != null && !isDuplicate ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                        width: (hasChildError || (match != null && !isDuplicate)) ? 1.5 : 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: hasChildError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
                if (match != null && !isDuplicate) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verified: ${match['fullName']} • ${match['departmentName'] ?? match['semester'] ?? 'Student'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (hasError && errorText != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        // Add Sibling Button
        InkWell(
          onTap: _addChildField,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F172A), size: 18),
                SizedBox(width: 8),
                Text(
                  '+ Add Another Child (Sibling)',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelationshipChip(String label, IconData icon) {
    final isSelected = _parentRelationship == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _parentRelationship = label);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 4: FINAL WELCOME ────────────────────────────────────────────────
  Widget _buildFinalWelcomeStep(double heroHeight) {
    final rawName = _nameController.text.trim().split(' ').first;
    final displayName = rawName.isNotEmpty
        ? (rawName.length == 1
            ? rawName.toUpperCase()
            : '${rawName[0].toUpperCase()}${rawName.substring(1)}')
        : 'Scholar';
    final isParent = _selectedRole == 'Parent';
    final topClearance = MediaQuery.of(context).padding.top + 58.0;

    return _buildStepBackgroundWithSoftGradient(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topClearance),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureBadge(icon: '🎉', label: 'All Systems Ready'),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Aboard,\n$displayName! 🚀',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.8,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isParent
                        ? 'Your parent portal and linked student wards have been configured. Tap below to launch Unisphere.'
                        : 'Your personalized academic dashboard is set up. Tap below to start your smart campus journey.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool hasError = false,
    bool isSuccess = false,
    String? errorMessage,
    Widget? suffixIcon,
    Widget? bottomWidget,
    ValueChanged<String>? onChanged,
  }) {
    final effectiveBorderColor = hasError
        ? const Color(0xFFEF4444)
        : (isSuccess ? const Color(0xFF10B981) : const Color(0xFFE2E8F0));
    final effectiveBorderWidth = (hasError || isSuccess) ? 1.8 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: hasError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
              ),
            ),
            if (hasError && errorMessage != null)
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: hasError ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
              fontSize: 14,
            ),
            filled: true,
            fillColor: hasError ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
            prefixIcon: Icon(
              icon,
              color: hasError
                  ? const Color(0xFFEF4444)
                  : (isSuccess ? const Color(0xFF10B981) : const Color(0xFF475569)),
              size: 20,
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: effectiveBorderColor,
                width: effectiveBorderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: effectiveBorderColor,
                width: effectiveBorderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : (isSuccess ? const Color(0xFF10B981) : const Color(0xFF0F172A)),
                width: 1.8,
              ),
            ),
          ),
        ),
        if (bottomWidget != null) bottomWidget,
      ],
    );
  }

  // ── FLOATING BOTTOM CONTROLS BAR (INDICATORS + DARK CAPSULE BUTTON) ──────
  Widget _buildBottomControlsBar() {
    // Determine active index for dots
    final totalDots = _currentMainStep == 0 ? 3 : 5;
    final activeIndex = _currentMainStep;

    // CTA Label
    String buttonText;
    if (_currentMainStep == 0) {
      buttonText = 'Get Started 🚀';
    } else if (_currentMainStep == 4) {
      buttonText = 'Launch App 🚀';
    } else {
      buttonText = 'Continue ➔';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 16,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Page Indicators (Left) ──────────────────────────────
          Row(
            children: List.generate(
              totalDots,
              (index) {
                final isActive = index == activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 6),
                  height: 7,
                  width: isActive ? 28 : 7,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),

          // ── Blue Pill CTA Button (Right) ─────────────────────────
          GestureDetector(
            onTap: _onStepNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Student':
        return Icons.school_outlined;
      case 'Faculty':
        return Icons.psychology_outlined;
      case 'Parent':
        return Icons.family_restroom_outlined;
      default:
        return Icons.apartment_outlined;
    }
  }
}
