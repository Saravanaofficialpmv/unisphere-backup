import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/screens/auth/widgets/web_login_view.dart';
import 'package:unisphere/screens/auth/widgets/workspace_selection_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/repositories/department_repository.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/parent_service.dart';
import 'package:unisphere/services/user_session_service.dart';
import 'package:unisphere/core/constants/app_colors.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool isInitialSignUp;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialRole;
  final String? initialId;
  final String? initialDepartment;
  final String? initialPhone;
  final String? initialRelationship;
  final List<String>? initialChildRegNumbers;
  
  const AuthScreen({
    super.key, 
    this.isInitialSignUp = false,
    this.initialFirstName,
    this.initialLastName,
    this.initialRole,
    this.initialId,
    this.initialDepartment,
    this.initialPhone,
    this.initialRelationship,
    this.initialChildRegNumbers,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  
  // Basic Controllers
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  
  // Signup Specific Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _regNoController;
  late final TextEditingController _deptController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _phoneController;
  late String _parentRelationship;
  final List<TextEditingController> _childRegControllers = [];
  
  // Student registration lookup states for Parent linking
  final ParentService _parentService = ParentService();
  final Map<int, Map<String, dynamic>?> _authChildMatches = {};
  final Map<int, bool> _isCheckingChild = {};
  final Map<int, String?> _childLookupErrors = {};

  // Student registration availability states for Student signup
  bool _isCheckingStudentRegNo = false;
  bool _studentRegNoAlreadyExists = false;
  bool _studentRegNoAvailable = false;

  Future<void> _checkAuthChildMatch(int index, String regNo) async {
    final clean = regNo.trim().toUpperCase();
    if (clean.length < 3) {
      if (_authChildMatches.containsKey(index) || _childLookupErrors.containsKey(index)) {
        setState(() {
          _authChildMatches.remove(index);
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
        _authChildMatches.remove(index);
        _isCheckingChild.remove(index);
        _childLookupErrors[index] = duplicateOf == 0
            ? 'Already added as primary student'
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
          _authChildMatches.remove(index);
          _childLookupErrors[index] = duplicateCheck == 0
              ? 'Already added as primary student'
              : 'Already added as Child ${duplicateCheck + 1}';
        } else if (match != null) {
          _authChildMatches[index] = match;
          _childLookupErrors.remove(index);
        } else {
          _authChildMatches.remove(index);
          if (clean.length == 12 || clean.length >= 8) {
            _childLookupErrors[index] = 'Student not found';
          } else {
            _childLookupErrors.remove(index);
          }
        }
      });
    }
  }

  void _revalidateAllAuthChildMatches() {
    for (int i = 0; i < _childRegControllers.length; i++) {
      _checkAuthChildMatch(i, _childRegControllers[i].text);
    }
  }

  Future<void> _checkStudentRegNoAvailability(String regNo) async {
    final clean = regNo.trim();
    if (clean.length < 12) {
      if (_isCheckingStudentRegNo || _studentRegNoAlreadyExists || _studentRegNoAvailable) {
        setState(() {
          _isCheckingStudentRegNo = false;
          _studentRegNoAlreadyExists = false;
          _studentRegNoAvailable = false;
        });
      }
      return;
    }

    setState(() {
      _isCheckingStudentRegNo = true;
      _studentRegNoAlreadyExists = false;
      _studentRegNoAvailable = false;
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
        debugPrint('Student reg no existence check notice: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingStudentRegNo = false;
        if (alreadyExists) {
          _studentRegNoAlreadyExists = true;
          _studentRegNoAvailable = false;
        } else {
          _studentRegNoAlreadyExists = false;
          _studentRegNoAvailable = true;
        }
      });
    }
  }

  late UserRole _selectedRole;
  late bool _isSignUp;
  late final PageController _pageController;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  String? _loginErrorMessage;
  bool _isUserNotFoundError = false;
  int _flipTrigger = 0;
  String? _unregisteredMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isInitialSignUp;
    _pageController = PageController(initialPage: _isSignUp ? 1 : 0);
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController(
      text: widget.initialFirstName != null ? '${widget.initialFirstName} ${widget.initialLastName ?? ''}'.trim() : '',
    );
    _regNoController = TextEditingController(text: widget.initialId);
    _deptController = TextEditingController(text: widget.initialDepartment ?? '');
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _parentRelationship = widget.initialRelationship ?? 'Father';

    // Initialize Role based on onboarding query param
    final parsedInitRole = UserModel.parseRole(widget.initialRole);
    if (parsedInitRole != UserRole.unknown) {
      _selectedRole = parsedInitRole;
    } else {
      final roleLower = widget.initialRole?.toLowerCase();
      if (roleLower == 'parent') {
        _selectedRole = UserRole.parent;
      } else if (roleLower == 'faculty' || roleLower == 'staff') {
        _selectedRole = UserRole.staff;
      } else if (roleLower == 'department (hod)' || roleLower == 'hod') {
        _selectedRole = UserRole.hod;
      } else {
        _selectedRole = UserRole.student;
      }
    }

    // Initialize child registration controllers
    if (widget.initialChildRegNumbers != null && widget.initialChildRegNumbers!.isNotEmpty) {
      for (int i = 0; i < widget.initialChildRegNumbers!.length; i++) {
        final reg = widget.initialChildRegNumbers![i];
        _childRegControllers.add(TextEditingController(text: reg));
        _checkAuthChildMatch(i, reg);
      }
    } else if (widget.initialId != null && widget.initialId!.isNotEmpty && _selectedRole == UserRole.parent) {
      _childRegControllers.add(TextEditingController(text: widget.initialId));
      _checkAuthChildMatch(0, widget.initialId!);
    } else {
      _childRegControllers.add(TextEditingController());
    }

    if (widget.initialId != null && widget.initialId!.isNotEmpty && _selectedRole == UserRole.student) {
      _checkStudentRegNoAvailability(widget.initialId!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _regNoController.dispose();
    _deptController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    for (final c in _childRegControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleAuthMode(bool isSignUp) {
    if (_isSignUp == isSignUp) return;
    setState(() {
      _isSignUp = isSignUp;
      _loginErrorMessage = null;
      _isUserNotFoundError = false;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        isSignUp ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToUserDashboard(UserModel user) {
    if (!mounted) return;
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
        context.go('/student');
        break;
    }
  }

  Future<void> _handleSubmit() async {
    final activeFormKey = _isSignUp ? _signupFormKey : _loginFormKey;
    if (activeFormKey.currentState != null && !activeFormKey.currentState!.validate()) return;

    if (_isSignUp) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Password and Confirm Password do not match', AppColors.error);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _loginErrorMessage = null;
      _isUserNotFoundError = false;
    });
    
    try {
      if (_isSignUp) {
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final phone = _phoneController.text.trim();

        if (_selectedRole == UserRole.parent) {
          final seenRegs = <String>{};
          for (int i = 0; i < _childRegControllers.length; i++) {
            final reg = _childRegControllers[i].text.trim().toUpperCase();
            if (reg.isEmpty) {
              _showSnackBar(
                i == 0
                    ? 'Please enter student register number'
                    : 'Please fill sibling ${i + 1} register number or delete the field',
                AppColors.error,
              );
              return;
            }
            if (reg.length != 12) {
              _showSnackBar(
                i == 0
                    ? 'Student register number must be exactly 12 digits'
                    : 'Sibling ${i + 1} register number must be exactly 12 digits',
                AppColors.error,
              );
              return;
            }

            if (seenRegs.contains(reg)) {
              _showSnackBar(
                'Cannot use the same register number ($reg) twice as a sibling',
                AppColors.error,
              );
              return;
            }
            seenRegs.add(reg);

            final match = _authChildMatches[i] ?? await _parentService.lookupStudentByRegNo(reg);
            if (match == null) {
              _showSnackBar(
                'Student with register number "$reg" is not registered in institutional database',
                AppColors.error,
              );
              return;
            }
          }

          final childRegs = _childRegControllers
              .map((c) => c.text.trim().toUpperCase())
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList();

          await ref.read(authServiceProvider).registerWithEmail(
            email,
            password,
            name.isNotEmpty ? name : 'Parent / Guardian',
            UserRole.parent,
            phoneNumber: phone.isNotEmpty ? phone : null,
            metadata: {
              'fullName': name,
              'phone': phone,
              'relationship': _parentRelationship,
              'wardRegisterNumbers': childRegs,
              'studentIds': childRegs,
              'role': 'parent',
              'profileCompletionStatus': 'complete',
            },
          );

          final currentUser = ref.read(authServiceProvider).currentUser;
          if (currentUser != null) {
            await ref.read(parentServiceProvider).linkParentWithChildren(
              parentId: currentUser.uid,
              userId: currentUser.uid,
              parentName: name.isNotEmpty ? name : 'Parent / Guardian',
              phone: phone,
              email: email,
              childRegisterNumbers: childRegs,
            );
          }
        } else if (_selectedRole == UserRole.staff) {
          final staffReg = _regNoController.text.trim();
          if (staffReg.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(staffReg)) {
            _showSnackBar('Staff register number must be exactly 4 digits', AppColors.error);
            return;
          }
          final deptVal = _deptController.text.trim();
          await ref.read(authServiceProvider).registerWithEmail(
            email,
            password,
            name.isNotEmpty ? name : 'Faculty Member',
            UserRole.staff,
            phoneNumber: phone.isNotEmpty ? phone : null,
            metadata: {
              'fullName': name,
              'name': name,
              'staffId': staffReg,
              'employeeId': staffReg,
              'registerNumber': staffReg,
              'regNo': staffReg,
              'department': deptVal,
              'departmentName': deptVal,
              'email': email,
              'phone': phone,
              'role': 'staff',
              'userRole': 'staff',
              'isAdvisor': false,
              'profileCompletionStatus': 'complete',
            },
          );

          final currentUser = ref.read(authServiceProvider).currentUser;
          if (currentUser != null) {
            final staffMap = {
              'userId': currentUser.uid,
              'uid': currentUser.uid,
              'staffId': staffReg,
              'employeeId': staffReg,
              'registerNumber': staffReg,
              'name': name,
              'fullName': name,
              'email': email,
              'phone': phone,
              'department': deptVal,
              'departmentName': deptVal,
              'role': 'staff',
              'userRole': 'staff',
              'isAdvisor': false,
              'updatedAt': FieldValue.serverTimestamp(),
            };
            try {
              final firestore = FirebaseFirestore.instance;
              await firestore.collection('staff').doc(currentUser.uid).set(staffMap, SetOptions(merge: true));
              await firestore.collection('users').doc(currentUser.uid).set(staffMap, SetOptions(merge: true));
            } catch (_) {}
          }
        } else if (_selectedRole == UserRole.hod) {
          final deptVal = _deptController.text.trim();
          await ref.read(authServiceProvider).registerWithEmail(
            email,
            password,
            name.isNotEmpty ? name : 'Head of Department',
            UserRole.hod,
            phoneNumber: phone.isNotEmpty ? phone : null,
            metadata: {
              'fullName': name,
              'name': name,
              'department': deptVal,
              'departmentName': deptVal,
              'email': email,
              'phone': phone,
              'role': 'hod',
              'userRole': 'hod',
              'profileCompletionStatus': 'complete',
            },
          );
          final currentUser = ref.read(authServiceProvider).currentUser;
          if (currentUser != null) {
            final hodMap = {
              'userId': currentUser.uid,
              'uid': currentUser.uid,
              'name': name,
              'fullName': name,
              'email': email,
              'phone': phone,
              'department': deptVal,
              'departmentName': deptVal,
              'role': 'hod',
              'userRole': 'hod',
              'updatedAt': FieldValue.serverTimestamp(),
            };
            try {
              final firestore = FirebaseFirestore.instance;
              await firestore.collection('users').doc(currentUser.uid).set(hodMap, SetOptions(merge: true));

              final targetDeptId = DepartmentRepository.deriveDepartmentId(deptVal);
              final targetDeptCode = DepartmentRepository.deriveDepartmentCode(deptVal);
              await firestore.collection('departments').doc(targetDeptId).set({
                'departmentId': targetDeptId,
                'department_id': targetDeptId,
                'name': deptVal,
                'departmentName': deptVal,
                'department_name': deptVal,
                'code': targetDeptCode,
                'departmentCode': targetDeptCode,
                'department_code': targetDeptCode,
                'hodId': currentUser.uid,
                'hod_id': currentUser.uid,
                'hodName': name.isNotEmpty ? name : 'Head of Department',
                'hod_name': name.isNotEmpty ? name : 'Head of Department',
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            } catch (_) {}
          }
        } else {
          final regNo = _regNoController.text.trim();
          final deptVal = _deptController.text.trim();
          if (_selectedRole == UserRole.student) {
            if (regNo.length != 12 || !RegExp(r'^[0-9]{12}$').hasMatch(regNo)) {
              _showSnackBar('Register number must be exactly 12 digits', AppColors.error);
              return;
            }
            if (_studentRegNoAlreadyExists) {
              _showSnackBar(
                'An account with register number "$regNo" already exists. Please log in.',
                AppColors.error,
              );
              return;
            }
            if (deptVal.isEmpty) {
              _showSnackBar('Please select your academic department', AppColors.error);
              return;
            }
            final hasHod = await ref.read(departmentRepositoryProvider).hasActiveHod(deptVal);
            if (!hasHod) {
              _showSnackBar(
                'The selected department "$deptVal" does not have an active Head of Department (HOD) yet. Please select an active department.',
                AppColors.error,
              );
              return;
            }
          }
          await ref.read(authServiceProvider).registerWithEmail(
            email,
            password,
            name.isNotEmpty ? name : 'New Student',
            _selectedRole,
            phoneNumber: phone.isNotEmpty ? phone : null,
            metadata: {
              'fullName': name,
              'name': name,
              'registerNumber': regNo,
              'regNo': regNo,
              'department': deptVal,
              'departmentName': deptVal,
              'collegeEmail': email,
              'role': 'student',
              'userRole': 'student',
              'profileCompletionStatus': 'incomplete',
              'profileCompletionPercentage': 10,
            },
          );

          final studentMap = {
            'studentId': regNo,
            'registerNumber': regNo,
            'regNo': regNo,
            'fullName': name,
            'name': name,
            'displayName': name,
            'department': deptVal,
            'departmentName': deptVal,
            'department_name': deptVal,
            'email': email,
            'phone': phone,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          ref.read(parentServiceProvider).cacheStudentProfile(regNo, studentMap);
        }
      } else {
        await ref.read(authServiceProvider).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      final currentUser = ref.read(authServiceProvider).currentUser;
      if (currentUser != null && mounted) {
        if (_isSignUp) {
          await ref.read(userSessionServiceProvider).recordFreshSignup(currentUser.uid);
        } else {
          await ref.read(userSessionServiceProvider).recordLogin(currentUser.uid);
        }
        _navigateToUserDashboard(currentUser);
      }
    } catch (e) {
      String rawError = e.toString().replaceFirst('Exception: ', '').trim();
      // Remove raw Firebase error prefixes like [firebase_auth/invalid-credential]
      rawError = rawError.replaceAll(RegExp(r'\[firebase_auth/[^\]]+\]\s*'), '').trim();
      final lowerErr = rawError.toLowerCase();
      final isUserNotFound = lowerErr.contains('user not found') ||
          lowerErr.contains('user-not-found') ||
          lowerErr.contains('no account is registered') ||
          lowerErr.contains('no user record');

      final isAlreadyExists = lowerErr.contains('already exists') ||
          lowerErr.contains('email-already-in-use') ||
          lowerErr.contains('already in use');

      setState(() {
        if (!_isSignUp) {
          if (isUserNotFound) {
            _isUserNotFoundError = true;
            _loginErrorMessage = 'User not found. No account is registered with this email address. Please check your email or Sign Up.';
            if (kIsWeb) {
              final typed = _emailController.text.trim();
              _unregisteredMessage = typed.isNotEmpty
                  ? 'No Unisphere account was found for $typed.'
                  : 'No account is registered with this email address.';
              _flipTrigger++;
            }
          } else {
            _isUserNotFoundError = false;
            _loginErrorMessage = rawError.startsWith('Authentication Notice:')
                ? rawError.replaceFirst('Authentication Notice:', '').trim()
                : rawError;
          }
        }
      });

      if (mounted) {
        if (isAlreadyExists) {
          _showSnackBar(
            'An account with this email already exists. Switching to Sign In...',
            AppColors.primary,
          );
          _toggleAuthMode(false);
        } else if (!kIsWeb || !isUserNotFound) {
          _showSnackBar(
            isUserNotFound ? 'User not found. Please check your email or Sign Up.' : rawError,
            AppColors.error,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToForgotPassword() {
    final currentEmail = _emailController.text.trim();
    final uri = Uri(
      path: '/forgot-password',
      queryParameters: currentEmail.isNotEmpty ? {'email': currentEmail} : null,
    );
    context.push(uri.toString());
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading || _isAppleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null && mounted) {
        await ref.read(userSessionServiceProvider).recordLogin(user.uid);
        if (!mounted) return;

        // Check if user has multiple roles or institutions to select
        if (user.availableRoles.length > 1 || user.availableInstitutions.length > 1) {
          final selection = await WorkspaceSelectionDialog.show(context, user: user);
          if (selection == null) {
            // User cancelled workspace selection -> sign out
            await ref.read(authServiceProvider).signOut();
            return;
          }
          final chosenUser = user.copyWith(role: selection.role);
          _navigateToUserDashboard(chosenUser);
        } else {
          _navigateToUserDashboard(user);
        }
      }
    } on GoogleSignInCancelledException {
      if (mounted) {
        _showSnackBar('Sign-in cancelled.', const Color(0xFF64748B));
      }
    } on UnisphereAccountNotRegisteredException catch (e) {
      if (mounted) {
        if (kIsWeb) {
          setState(() {
            _unregisteredMessage = e.email != null && e.email!.isNotEmpty
                ? 'Your Google account (${e.email}) is not registered in Unisphere.'
                : 'Your Google account is not registered in Unisphere.';
            _flipTrigger++;
          });
        } else {
          _showAccountNotRegisteredDialog(e.email);
        }
      }
    } on UnisphereAccountDeactivatedException catch (e) {
      if (mounted) {
        _showAccountDeactivatedDialog(e.message);
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      final lower = cleanMsg.toLowerCase();
      if (lower.contains('popup-closed-by-user') || lower.contains('cancelled')) {
        if (mounted) _showSnackBar('Sign-in cancelled.', const Color(0xFF64748B));
      } else if (lower.contains('unregistered') || lower.contains('not registered')) {
        if (kIsWeb) {
          setState(() {
            _unregisteredMessage = 'Account does not exist. Please download the mobile app to sign up or register.';
            _flipTrigger++;
          });
        } else {
          if (mounted) _showAccountNotRegisteredDialog(null);
        }
      } else if (mounted) {
        _showSnackBar(
          cleanMsg.isNotEmpty ? cleanMsg : 'Unable to sign in with Google. Please try again.',
          AppColors.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showAccountNotRegisteredDialog(String? email) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: const Icon(
                Icons.person_off_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Account not registered',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              email != null && email.isNotEmpty
                  ? 'Your Google account ($email) is authenticated, but you do not currently have access to a Unisphere institution.'
                  : 'Your Google account is authenticated, but you do not currently have access to a Unisphere institution.',
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please contact your institution administrator.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Understood', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDeactivatedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Account Deactivated',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebLoginView(
        formKey: _loginFormKey,
        emailController: _emailController,
        passwordController: _passwordController,
        isLoading: _isLoading,
        isGoogleLoading: _isGoogleLoading,
        obscurePassword: _obscurePassword,
        isUserNotFoundError: _isUserNotFoundError,
        loginErrorMessage: _loginErrorMessage,
        flipTrigger: _flipTrigger,
        unregisteredMessage: _unregisteredMessage,
        onFlippedToFront: () {
          if (mounted) {
            setState(() {
              _unregisteredMessage = null;
            });
          }
        },
        selectedRole: _selectedRole,
        onRoleChanged: (newRole) {
          setState(() {
            _selectedRole = newRole;
          });
        },
        onTogglePasswordVisibility: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        onLoginPressed: () {
          _isSignUp = false;
          _handleSubmit();
        },
        onGoogleLoginPressed: _handleGoogleSignIn,
        onForgotPasswordPressed: _navigateToForgotPassword,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Aesthetic
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Header Title (Clean FadeTransition - ZERO text overlap)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey<bool>(_isSignUp),
                    child: Column(
                      children: [
                        Text(
                          _isSignUp ? 'Get Started Now' : 'Welcome Back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp ? 'Create an account to explore UNISPHERE' : 'Login to access your account',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Tab Switcher (Sliding Pill Indicator)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildTabSwitcher(),
                ),
                const SizedBox(height: 24),
                // Form Content (PageView - Isolated pages with ZERO text overlap)
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (pageIndex) {
                      final isSignUpPage = pageIndex == 1;
                      if (_isSignUp != isSignUpPage) {
                        setState(() => _isSignUp = isSignUpPage);
                      }
                    },
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Form(
                          key: _loginFormKey,
                          child: _buildLoginForm(),
                        ),
                      ),
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Form(
                          key: _signupFormKey,
                          child: _buildSignupForm(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _gmailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
    caseSensitive: false,
  );

  String? _validateEmail(String? val, {bool isCollege = false}) {
    final clean = val?.trim() ?? '';
    if (clean.isEmpty) {
      return isCollege ? 'Please enter college email address' : 'Please enter your email address';
    }
    if (isCollege) {
      if (!_emailRegExp.hasMatch(clean)) {
        return 'Enter a valid college email address';
      }
      return null;
    }

    // Gmail format validation for login and parent
    if (!clean.contains('@')) {
      return 'Gmail format required: must include @gmail.com';
    }

    final lowerClean = clean.toLowerCase();
    final isDemoDomain = lowerClean.endsWith('@unisphere.edu') || lowerClean.endsWith('@vsbec.ac.in');

    if (!isDemoDomain && !_gmailRegExp.hasMatch(clean)) {
      if (!_emailRegExp.hasMatch(clean)) {
        return 'Please enter a valid Gmail address (e.g. name@gmail.com)';
      }
      return 'Please enter a valid Gmail address (@gmail.com)';
    }

    return null;
  }

  String? _validatePhone(String? val) {
    if (!_isSignUp) return null;
    final clean = val?.trim() ?? '';
    if (clean.isEmpty) {
      return 'Please enter 10-digit mobile number';
    }
    final digits = clean.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  String? _validateName(String? val, {String entity = 'full'}) {
    if (!_isSignUp) return null;
    final clean = val?.trim() ?? '';
    if (clean.isEmpty) return 'Please enter $entity name';
    if (RegExp(r'[0-9]').hasMatch(clean) || !RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(clean)) {
      return 'Name must contain letters only';
    }
    return null;
  }

  String? _validateRegNo(String? val, {String label = 'register number'}) {
    if (!_isSignUp) return null;
    final clean = val?.trim() ?? '';
    if (clean.isEmpty) return 'Please enter $label';
    if (clean.length != 12 || !RegExp(r'^[0-9]{12}$').hasMatch(clean)) {
      return 'Must be exactly 12 digits';
    }
    return null;
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Email Address', style: _labelStyle),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _emailController,
          hint: 'yourname@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          customBorderColor: _isUserNotFoundError ? const Color(0xFFEF4444) : null,
          validator: (val) => _validateEmail(val),
          onChanged: (val) {
            setState(() {
              _loginErrorMessage = null;
              _isUserNotFoundError = false;
            });
          },
        ),
        if (_isUserNotFoundError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                SizedBox(width: 4),
                Text(
                  'User not found',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        if (!_isSignUp && _emailController.text.isNotEmpty && !_emailController.text.contains('@'))
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Text(
                  'Format: ',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                InkWell(
                  onTap: () {
                    final text = _emailController.text.trim();
                    _emailController.text = '$text@gmail.com';
                    _emailController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _emailController.text.length),
                    );
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Text(
                      'Tap to append @gmail.com',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text('Password', style: _labelStyle),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _passwordController,
          hint: '*******',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: (val) => val == null || val.length < 6 ? 'Password too short' : null,
          onChanged: (val) {
            if (_loginErrorMessage != null) {
              setState(() {
                _loginErrorMessage = null;
                _isUserNotFoundError = false;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _rememberMe = val ?? false),
                ),
                const Text('Remember me', style: TextStyle(fontSize: 13)),
              ],
            ),
            TextButton(
              onPressed: _navigateToForgotPassword,
              child: const Text('Forgot password?', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSubmitButton('Log In'),
        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              GestureDetector(
                onTap: () => _toggleAuthMode(true),
                child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildSocialLogins(),
      ],
    );
  }

  Widget _buildRoleHeader() {
    final String roleTitle;
    final IconData roleIcon;
    switch (_selectedRole) {
      case UserRole.student:
        roleTitle = 'Student Registration';
        roleIcon = Icons.school_rounded;
        break;
      case UserRole.staff:
      case UserRole.advisor:
        roleTitle = 'Faculty / Staff Registration';
        roleIcon = Icons.badge_rounded;
        break;
      case UserRole.hod:
        roleTitle = 'Department (HOD) Registration';
        roleIcon = Icons.corporate_fare_rounded;
        break;
      case UserRole.parent:
        roleTitle = 'Parent / Guardian Registration';
        roleIcon = Icons.family_restroom_rounded;
        break;
      default:
        roleTitle = 'Campus Registration';
        roleIcon = Icons.person_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(roleIcon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Workspace profile selected during onboarding',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                SizedBox(width: 4),
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Column(
      key: const ValueKey('signup_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleHeader(),
        if (_selectedRole == UserRole.parent) ...[
          const Text('Parent / Guardian Full Name', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter parent / guardian full name',
            icon: Icons.person_outline,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]')),
            ],
            validator: (val) => _validateName(val, entity: 'parent full'),
          ),
          const SizedBox(height: 16),
          const Text('Parent Contact Phone Number', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: 'Enter 10-digit mobile number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: _validatePhone,
          ),
          const SizedBox(height: 16),
          Text(
            'Relationship to Student',
            style: _labelStyle,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAuthRelationshipChip('Father', Icons.face_6_rounded),
              const SizedBox(width: 8),
              _buildAuthRelationshipChip('Mother', Icons.face_3_rounded),
              const SizedBox(width: 8),
              _buildAuthRelationshipChip('Guardian', Icons.shield_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Linked Children Register Numbers (${_childRegControllers.length})',
                style: _labelStyle,
              ),
              if (_childRegControllers.length > 1)
                Text(
                  '${_childRegControllers.length} siblings',
                  style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_childRegControllers.length, (index) {
            final isPrimary = index == 0;
            final match = _authChildMatches[index];
            final isChecking = _isCheckingChild[index] == true;
            final text = _childRegControllers[index].text.trim().toUpperCase();
            final isDuplicate = _childRegControllers.asMap().entries.any(
              (e) => e.key != index && e.value.text.trim().toUpperCase() == text && text.isNotEmpty,
            );
            final lookupError = _childLookupErrors[index];
            final hasError = (text.length == 12 || text.length >= 8) && (match == null || isDuplicate) && !isChecking;
            final errorText = isDuplicate
                ? 'Already added'
                : (lookupError ?? (hasError ? 'Student not found' : null));

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : (match != null && !isDuplicate ? const Color(0xFF10B981) : AppColors.border),
                  width: (match != null || hasError) ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _childRegControllers[index],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (val) {
                            _revalidateAllAuthChildMatches();
                          },
                          validator: (val) {
                            final baseErr = _validateRegNo(
                              val,
                              label: isPrimary ? 'student register number' : 'sibling register number',
                            );
                            if (baseErr != null) return baseErr;
                            if (isDuplicate) return 'Already added';
                            return null;
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: isPrimary ? 'Enter 12-digit register number' : 'Enter 12-digit sibling register number',
                            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                            prefixIcon: Icon(
                              isPrimary ? Icons.school_rounded : Icons.person_add_alt_1_rounded,
                              color: AppColors.primary,
                              size: 18,
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
                                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                                    : (hasError
                                        ? const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18)
                                        : null)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      if (!isPrimary)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                          onPressed: () {
                            setState(() {
                              _childRegControllers[index].dispose();
                              _childRegControllers.removeAt(index);
                              _authChildMatches.remove(index);
                              _isCheckingChild.remove(index);
                              _childLookupErrors.remove(index);
                            });
                            _revalidateAllAuthChildMatches();
                          },
                        ),
                    ],
                  ),
                  if (match != null && !isDuplicate) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '✓ Verified: ${match['fullName'] ?? match['name']} • ${match['departmentName'] ?? match['department'] ?? 'CSE'}${match['semester'] != null ? ' (${match['semester']})' : ''}',
                              style: const TextStyle(
                                fontSize: 11.5,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 15),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              errorText,
                              style: const TextStyle(
                                fontSize: 11.5,
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _childRegControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
              label: const Text(
                '+ Add Another Child (Sibling)',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Parent Email Address', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'parent@gmail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => _validateEmail(val),
          ),
        ] else if (_selectedRole == UserRole.staff) ...[
          const Text('Faculty / Staff Full Name', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter faculty / staff full name',
            icon: Icons.person_outline,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]')),
            ],
            validator: (val) => _validateName(val, entity: 'faculty full'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Staff Register Number', style: _labelStyle),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _regNoController,
                      hint: 'Enter 4-digit register number',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (val) {
                        if (!_isSignUp) return null;
                        if (val == null || val.trim().isEmpty) return 'Staff register number required';
                        if (val.trim().length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(val.trim())) {
                          return 'Must be 4 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Department', style: _labelStyle),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _deptController,
                      hint: 'e.g. CSE, IT, MECH',
                      icon: Icons.school_outlined,
                      validator: (val) => _isSignUp && (val == null || val.trim().isEmpty) ? 'Enter Department' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Staff Email Address', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'staff@unisphere.edu or gmail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => _validateEmail(val),
          ),
          const SizedBox(height: 16),
          const Text('Contact Phone Number', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: 'Enter 10-digit mobile number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: _validatePhone,
          ),
        ] else if (_selectedRole == UserRole.hod) ...[
          const Text('HOD Full Name', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter HOD full name',
            icon: Icons.person_outline,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]')),
            ],
            validator: (val) => _validateName(val, entity: 'HOD full'),
          ),
          const SizedBox(height: 16),
          const Text('Department', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _deptController,
            hint: 'e.g. Computer Science & Engineering',
            icon: Icons.domain_rounded,
            validator: (val) => _isSignUp && (val == null || val.trim().isEmpty) ? 'Enter Department' : null,
          ),
          const SizedBox(height: 16),
          const Text('HOD Email Address', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'hod@unisphere.edu or gmail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => _validateEmail(val),
          ),
          const SizedBox(height: 16),
          const Text('Contact Phone Number', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: 'Enter 10-digit mobile number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: _validatePhone,
          ),
        ] else ...[
          const Text('Student Full Name', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter full name',
            icon: Icons.person_outline,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]')),
            ],
            validator: (val) => _validateName(val, entity: 'student full'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Register Number', style: _labelStyle),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _regNoController,
                      hint: 'Enter 12-digit register number',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      customBorderColor: _studentRegNoAlreadyExists
                          ? AppColors.error
                          : (_studentRegNoAvailable ? const Color(0xFF10B981) : null),
                      customSuffixIcon: _isCheckingStudentRegNo
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
                          : (_studentRegNoAlreadyExists
                              ? const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20)
                              : (_studentRegNoAvailable
                                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                                  : null)),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      onChanged: (val) => _checkStudentRegNoAvailability(val),
                      validator: (val) {
                        final baseErr = _validateRegNo(val);
                        if (baseErr != null) return baseErr;
                        if (_studentRegNoAlreadyExists) {
                          return 'Already exists';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Department', style: _labelStyle),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _deptController,
                      hint: 'Select active department',
                      icon: Icons.school_outlined,
                      readOnly: true,
                      onTap: _openActiveDepartmentPicker,
                      customSuffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                      validator: (val) => _isSignUp && (val == null || val.trim().isEmpty) ? 'Select Department' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('College Email Address', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'student@vsbec.ac.in',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => _validateEmail(val, isCollege: true),
          ),
        ],
        const SizedBox(height: 16),
        const Text('Password', style: _labelStyle),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordController,
          hint: '••••••••',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (_) => setState(() {}),
          validator: (val) {
            if (!_isSignUp) return null;
            if (val == null || val.isEmpty) return 'Password required';
            if (val.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text('Confirm Password', style: _labelStyle),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _confirmPasswordController,
          hint: '••••••••',
          icon: Icons.lock_clock_outlined,
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          onChanged: (_) => setState(() {}),
          validator: (val) {
            if (!_isSignUp) return null;
            if (val == null || val.isEmpty) return 'Confirm password';
            if (val != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        if (_isSignUp &&
            (_passwordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty)) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final pass = _passwordController.text;
              final confirm = _confirmPasswordController.text;
              if (pass.isEmpty || confirm.isEmpty) {
                return Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pass.length < 6
                            ? 'Password must be at least 6 characters'
                            : 'Enter confirm password to match',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                );
              }
              final isMatch = pass == confirm;
              return Row(
                children: [
                  Icon(
                    isMatch ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 14,
                    color: isMatch ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isMatch ? 'Both passwords match' : 'Passwords do not match',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMatch ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        _buildSubmitButton('Create Account & Continue →'),
        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              GestureDetector(
                onTap: () => _toggleAuthMode(false),
                child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSocialLogins(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSubmitButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? () {} : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: _isLoading ? 0 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/tibsy-dp.gif',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isSignUp ? 'Creating Account...' : 'Signing In...',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            )
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }



  Widget _buildSocialLogins() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Or continue with', style: TextStyle(color: Colors.grey, fontSize: 12))),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildGoogleButton(_handleGoogleSignIn),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton(
                'Apple',
                Icons.apple_rounded,
                Colors.black,
                () async {
                  if (_isLoading || _isGoogleLoading || _isAppleLoading) return;
                  setState(() => _isAppleLoading = true);
                  try {
                    await ref.read(authServiceProvider).signInWithApple();
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user != null && mounted) {
                      _navigateToUserDashboard(user);
                    }
                  } catch (e) {
                    final cleanMsg = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
                    if (mounted) _showSnackBar(cleanMsg.isNotEmpty ? cleanMsg : 'Apple Sign-In could not be completed.', AppColors.error);
                  } finally {
                    if (mounted) setState(() => _isAppleLoading = false);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoogleButton(VoidCallback onTap) {
    final bool isBusy = _isLoading || _isGoogleLoading || _isAppleLoading;
    return OutlinedButton(
      onPressed: isBusy ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isGoogleLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/google_logo.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                const Text('Google', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color, VoidCallback onTap) {
    final bool isBusy = _isLoading || _isGoogleLoading || _isAppleLoading;
    return OutlinedButton(
      onPressed: isBusy ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isAppleLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 8) / 2;
          return Stack(
            children: [
              // Sliding White Pill Indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                alignment: _isSignUp ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab Text Touch Targets
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleAuthMode(false),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: !_isSignUp ? FontWeight.bold : FontWeight.w600,
                            color: !_isSignUp ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleAuthMode(true),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: _isSignUp ? FontWeight.bold : FontWeight.w600,
                            color: _isSignUp ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _openActiveDepartmentPicker() async {
    HapticFeedback.lightImpact();
    final activeDepts = await ref.read(departmentRepositoryProvider).getDepartmentsWithActiveHod();
    if (!mounted) return;

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
            final filtered = activeDepts.where((d) {
              return d.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  d.code.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  (d.hodName != null && d.hodName!.toLowerCase().contains(searchQuery.toLowerCase()));
            }).toList();

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Active Department',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${filtered.length} active',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search active department or HOD...',
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
                      onChanged: (val) => setModalState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEF3C7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.domain_disabled_rounded, size: 32, color: Color(0xFFD97706)),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      searchQuery.isEmpty ? 'No Active Departments' : 'No Departments Found',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'A Head of Department (HOD) must register first to activate a department for student sign-up.'
                                          : 'No active department matched "$searchQuery".',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final dept = filtered[index];
                                final isSelected = _deptController.text.trim() == dept.name;

                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _deptController.text = dept.name;
                                    });
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.school_outlined, size: 20, color: isSelected ? Colors.white : AppColors.primary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dept.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      dept.code,
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: isSelected ? Colors.white : const Color(0xFF059669),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'HOD: ${dept.hodName ?? "Registered"}',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isPassword = false,
    bool obscureText = false,
    Widget? customSuffixIcon,
    Color? customBorderColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final effectiveBorderSide = customBorderColor != null
        ? BorderSide(color: customBorderColor, width: 1.5)
        : const BorderSide(color: AppColors.border);

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      cursorColor: AppColors.primary,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary, size: 20) : null,
        suffixIcon: customSuffixIcon ??
            (isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: effectiveBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: effectiveBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: customBorderColor != null
              ? BorderSide(color: customBorderColor, width: 2.0)
              : const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        errorMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  Widget _buildAuthRelationshipChip(String label, IconData icon) {
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
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
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
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary);
}
