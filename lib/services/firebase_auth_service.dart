import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_service.dart';
import 'package:unisphere/services/user_session_service.dart';

/// Real-time Firebase Authentication Service
/// Listens to Firebase Auth state changes and streams real-time Firestore user document updates.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  UserModel? _currentUser;
  UserModel? _mockUser;
  final _stateController = StreamController<UserModel?>.broadcast();
  final Completer<void> _initialAuthCompleter = Completer<void>();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? _tryGetAuth(),
        _firestore = firestore ?? _tryGetFirestore() {
    _initRealtimeAuth();
  }

  static FirebaseAuth? _tryGetAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _resolvedAuth => _auth ?? _tryGetAuth();
  FirebaseFirestore? get _resolvedFirestore => _firestore ?? _tryGetFirestore();

  Future<FirebaseAuth?> _getOrInitAuth() async {
    if (_auth != null) return _auth;
    if (!FirebaseService.instance.isInitialized) {
      try {
        await FirebaseService.instance.initialize();
      } catch (e) {
        debugPrint('FirebaseService initialize notice in _getOrInitAuth: $e');
      }
    }
    final auth = _tryGetAuth();
    if (auth != null && _authSubscription == null) {
      _initRealtimeAuth();
    }
    return auth;
  }

  void _initRealtimeAuth() {
    final auth = _resolvedAuth;
    if (auth == null) {
      if (!_initialAuthCompleter.isCompleted) _initialAuthCompleter.complete();
      return;
    }
    try {
      final initialFbUser = auth.currentUser;
      if (initialFbUser != null && _currentUser == null) {
        _currentUser = _mapFirebaseUserToDefaultModel(initialFbUser, null);
      }
      // Listen to real-time Firebase Auth user changes (login, logout, token refresh)
      _authSubscription = auth.userChanges().listen((User? fbUser) {
        _handleFirebaseUserChange(fbUser);
      }, onError: (e) {
        debugPrint('Firebase Auth Realtime Error: $e');
        if (!_initialAuthCompleter.isCompleted) _initialAuthCompleter.complete();
      });

      // Handle redirect result on web (e.g. if popup was blocked)
      if (kIsWeb) {
        auth.getRedirectResult().then((result) async {
          if (result.user != null) {
            final fbUser = result.user!;
            unawaited(UserSessionService.instance.recordLogin(fbUser.uid));
            var userData = await getUserData(fbUser.uid);
            if (userData == null) {
              userData = _mapFirebaseUserToDefaultModel(fbUser, null);
              await saveUserData(userData);
            }
            _currentUser = userData;
            _stateController.add(userData);
            _handleFirebaseUserChange(fbUser, explicitUser: userData);
          }
        }).catchError((e) {
          debugPrint('Firebase getRedirectResult notice: $e');
        });
      }
    } catch (e) {
      debugPrint('Firebase Auth initialization notice: $e');
      if (!_initialAuthCompleter.isCompleted) _initialAuthCompleter.complete();
    }
  }

  UserModel? _pendingRegistrationUser;

  void _handleFirebaseUserChange(User? fbUser, {UserRole? intendedRole, UserModel? explicitUser}) {
    if (!_initialAuthCompleter.isCompleted) {
      _initialAuthCompleter.complete();
    }
    if (_mockUser != null) return;

    // Cancel previous Firestore user document subscription
    _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (fbUser == null) {
      _currentUser = null;
      _pendingRegistrationUser = null;
      _stateController.add(null);
    } else {
      final pending = _pendingRegistrationUser;
      final isPendingMatch = pending != null &&
          (pending.uid.isEmpty ||
              pending.uid == fbUser.uid ||
              pending.email.toLowerCase() == (fbUser.email ?? '').toLowerCase());

      if (explicitUser != null) {
        _currentUser = explicitUser;
        _stateController.add(_currentUser);
      } else if (isPendingMatch) {
        _currentUser = pending.copyWith(uid: fbUser.uid);
        _stateController.add(_currentUser);
      } else if (_currentUser == null || _currentUser!.uid != fbUser.uid) {
        _currentUser = _mapFirebaseUserToDefaultModel(fbUser, intendedRole);
        _stateController.add(_currentUser);
      }

      // Subscribe to real-time updates from Firestore for this user's profile
      final firestore = _resolvedFirestore;
      if (firestore != null) {
        try {
          _userDocSubscription = firestore
              .collection('users')
              .doc(fbUser.uid)
              .snapshots()
              .listen((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              var userModel = UserModel.fromMap(snapshot.data()!, fbUser.uid);
              if (userModel.role == UserRole.student) {
                try {
                  firestore.collection('parents').doc(fbUser.uid).get().then((parentDoc) {
                    if (parentDoc.exists && parentDoc.data() != null) {
                      final pData = parentDoc.data()!;
                      _currentUser = userModel.copyWith(
                        role: UserRole.parent,
                        metadata: {
                          ...?userModel.metadata,
                          ...pData,
                          'role': 'parent',
                        },
                      );
                      _stateController.add(_currentUser);
                    }
                  });
                } catch (_) {}
              }
              _currentUser = userModel;
              _stateController.add(_currentUser);
            } else {
              // If user document doesn't exist yet in Firestore, save the registered/intended model and emit
              final currentRole = _currentUser?.role ?? intendedRole ?? (isPendingMatch ? pending.role : null);
              final defaultUser = _currentUser != null && _currentUser!.uid == fbUser.uid
                  ? _currentUser!
                  : _mapFirebaseUserToDefaultModel(fbUser, currentRole);
              saveUserData(defaultUser);
              _currentUser = defaultUser;
              _stateController.add(_currentUser);
            }
          }, onError: (e) {
            debugPrint('Firestore real-time user doc error: $e');
          });
        } catch (e) {
          debugPrint('Error subscribing to real-time user doc: $e');
        }
      }
    }
  }

  UserModel _mapFirebaseUserToDefaultModel(User user, [UserRole? fallbackRole]) {
    UserRole inferredRole = fallbackRole ?? UserRole.student;
    if (fallbackRole == null && user.email != null) {
      final emailLower = user.email!.toLowerCase();
      if (emailLower.contains('parent') || emailLower == 'heydigitals.care@gmail.com') {
        inferredRole = UserRole.parent;
      } else if (emailLower.contains('hod') || emailLower == 'unispherecrm.official@gmail.com') {
        inferredRole = UserRole.hod;
      } else if (emailLower.contains('staff') || emailLower.contains('faculty') || emailLower == 'awenests.care@gmail.com') {
        inferredRole = UserRole.staff;
      } else if (emailLower == 'saravanapmvofficial@gmail.com') {
        inferredRole = UserRole.student;
      }
    }
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? (user.email != null ? user.email!.split('@').first : 'User'),
      profileImageUrl: user.photoURL,
      role: inferredRole,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: user.metadata.lastSignInTime,
      metadata: {
        if (user.photoURL != null) 'photoUrl': user.photoURL,
      },
    );
  }

  @override
  Stream<UserModel?> get authStateChanges async* {
    yield currentUser;
    yield* _stateController.stream;
  }

  @override
  Stream<User?>? get firebaseUserStream => _resolvedAuth?.userChanges();

  @override
  UserModel? get currentUser => _mockUser ?? _currentUser;

  @override
  Future<void> ensureAuthReady() async {
    if (_initialAuthCompleter.isCompleted) return;
    try {
      await _initialAuthCompleter.future.timeout(
        const Duration(milliseconds: 750),
        onTimeout: () {},
      );
    } catch (_) {}
  }

  @override
  Future<void> reloadUser() async {
    final auth = _resolvedAuth;
    if (_mockUser != null || auth == null) return;
    try {
      final user = auth.currentUser;
      if (user != null) {
        await user.reload();
        _handleFirebaseUserChange(auth.currentUser);
      }
    } catch (e) {
      debugPrint('Firebase Reload User Notice: $e');
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    final lowerEmail = email.toLowerCase().trim();

    // DEMO BYPASS ACCOUNTS (Only for designated exact demo accounts)
    if (lowerEmail == 'hod.cse@unisphere.edu' || lowerEmail == 'hod@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-HOD', email: email, fullName: 'Dr. R. Kumar', role: UserRole.hod);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      unawaited(UserSessionService.instance.recordLogin('DEMO-HOD'));
      return;
    }
    if (lowerEmail == 'admin@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-ADM', email: email, fullName: 'Demo Admin', role: UserRole.admin);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      unawaited(UserSessionService.instance.recordLogin('DEMO-ADM'));
      return;
    }
    if (lowerEmail == 'staff@unisphere.edu' || lowerEmail == 'faculty@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-STF', email: email, fullName: 'Dr. K. Tharani Kumar', role: UserRole.staff);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      unawaited(UserSessionService.instance.recordLogin('DEMO-STF'));
      return;
    }
    if (lowerEmail == 'student@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-STU', email: email, fullName: 'Student Demo', role: UserRole.student);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      unawaited(UserSessionService.instance.recordLogin('DEMO-STU'));
      return;
    }
    if (lowerEmail == 'parent@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-PRT', email: email, fullName: 'Rajesh Kumar', role: UserRole.parent);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      unawaited(UserSessionService.instance.recordLogin('DEMO-PRT'));
      return;
    }

    // REAL USER SIGN IN: Clear mock user state first!
    _mockUser = null;

    const realtimeDemoAccounts = {
      'saravanapmvofficial@gmail.com': (
        uid: 'DEMO-STU',
        role: UserRole.student,
        name: 'Saravanan M',
        dept: 'Computer Science & Engineering',
        meta: <String, dynamic>{
          'department': 'Computer Science & Engineering',
          'departmentName': 'Computer Science & Engineering',
          'registerNumber': 'RA2111003010001',
          'regNo': 'RA2111003010001',
          'semester': 'Semester VI',
          'year': 'Third Year',
          'cgpa': 8.78,
          'attendancePercentage': 92.4,
          'quota': 'General Merit',
          'phone': '+91 98765 43210',
        },
      ),
      'heydigitals.care@gmail.com': (
        uid: 'DEMO-PRT',
        role: UserRole.parent,
        name: 'HeyDigitals Care Parent',
        dept: 'Computer Science & Engineering',
        meta: <String, dynamic>{
          'department': 'Computer Science & Engineering',
          'linkedStudentName': 'Saravanan M',
          'linkedStudentRegNo': 'RA2111003010001',
          'linkedStudentId': 'DEMO-STU',
          'relationship': 'Father',
          'phone': '+91 98765 43210',
        },
      ),
      'unispherecrm.official@gmail.com': (
        uid: 'DEMO-HOD',
        role: UserRole.hod,
        name: 'Dr. R. Manivannan',
        dept: 'Computer Science & Engineering',
        meta: <String, dynamic>{
          'department': 'Computer Science & Engineering',
          'departmentName': 'Computer Science & Engineering',
          'designation': 'Professor & Head of Department',
          'employeeId': 'HOD-CSE-001',
          'phone': '+91 98765 43212',
        },
      ),
      'awenests.care@gmail.com': (
        uid: 'DEMO-STF',
        role: UserRole.staff,
        name: 'Awenests Faculty Staff',
        dept: 'Computer Science & Engineering',
        meta: <String, dynamic>{
          'department': 'Computer Science & Engineering',
          'departmentName': 'Computer Science & Engineering',
          'designation': 'Assistant Professor & Class Advisor',
          'employeeId': 'STF-CSE-042',
          'isClassAdvisor': true,
          'assignedClass': 'CSE-III-B',
          'phone': '+91 98765 43211',
        },
      ),
    };

    final auth = await _getOrInitAuth();

    // Check if this is a designated realtime demo account
    if (realtimeDemoAccounts.containsKey(lowerEmail)) {
      final acc = realtimeDemoAccounts[lowerEmail]!;
      if (auth != null) {
        try {
          final credential = await auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          if (credential.user != null) {
            unawaited(UserSessionService.instance.recordLogin(credential.user!.uid));
            final userData = await getUserData(credential.user!.uid);
            final activeUser = userData ?? UserModel(
              uid: credential.user!.uid,
              email: email.trim(),
              fullName: acc.name,
              role: acc.role,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
              metadata: Map<String, dynamic>.from(acc.meta),
            );
            _currentUser = activeUser;
            _stateController.add(activeUser);
            _handleFirebaseUserChange(credential.user, explicitUser: activeUser);
            return;
          }
        } on FirebaseAuthException catch (e) {
          debugPrint('Demo account signInWithEmailAndPassword notice: ${e.code}');
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            try {
              final newCred = await auth.createUserWithEmailAndPassword(
                email: email.trim(),
                password: password,
              );
              if (newCred.user != null) {
                final initialUser = UserModel(
                  uid: newCred.user!.uid,
                  email: email.trim(),
                  fullName: acc.name,
                  role: acc.role,
                  createdAt: DateTime.now(),
                  lastLoginAt: DateTime.now(),
                  metadata: Map<String, dynamic>.from(acc.meta),
                );
                await saveUserData(initialUser);
                _currentUser = initialUser;
                _stateController.add(initialUser);
                _handleFirebaseUserChange(newCred.user, explicitUser: initialUser);
                return;
              }
            } catch (createErr) {
              debugPrint('Demo account createUserWithEmailAndPassword notice: $createErr');
            }
          }
        } catch (generalErr) {
          debugPrint('Demo account sign in error: $generalErr');
        }
      }

      // If Firebase Auth was null or failed for any reason, use guaranteed demo session
      final fallbackUser = UserModel(
        uid: acc.uid,
        email: email.trim(),
        fullName: acc.name,
        role: acc.role,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        metadata: Map<String, dynamic>.from(acc.meta),
      );
      _mockUser = fallbackUser;
      _currentUser = fallbackUser;
      _stateController.add(fallbackUser);
      unawaited(UserSessionService.instance.recordLogin(fallbackUser.uid));
      return;
    }

    if (auth == null) {
      throw 'Firebase Authentication is not available. Please verify your connection.';
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        unawaited(UserSessionService.instance.recordLogin(credential.user!.uid));
        final userData = await getUserData(credential.user!.uid);
        if (userData != null) {
          _currentUser = userData;
          _stateController.add(userData);
        }
        _handleFirebaseUserChange(credential.user, explicitUser: userData);
        return;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Sign In Error: ${e.code} - ${e.message}');

      if (e.code == 'user-not-found') {
        throw 'User not found. No account is registered with this email address. Please check your email or Sign Up.';
      }
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        // Distinguish between non-existent user and wrong password by checking Firestore records
        final cleanEmail = email.trim().toLowerCase();
        bool userFoundInDb = false;
        final firestore = _resolvedFirestore;
        if (firestore != null) {
          try {
            final uSnap = await firestore.collection('users').where('email', isEqualTo: cleanEmail).limit(1).get();
            if (uSnap.docs.isNotEmpty) {
              userFoundInDb = true;
            } else {
              final colSnap = await firestore.collection('users').where('collegeEmail', isEqualTo: cleanEmail).limit(1).get();
              if (colSnap.docs.isNotEmpty) {
                userFoundInDb = true;
              } else {
                final sSnap = await firestore.collection('students').where('email', isEqualTo: cleanEmail).limit(1).get();
                if (sSnap.docs.isNotEmpty) {
                  userFoundInDb = true;
                } else {
                  final stfSnap = await firestore.collection('staff').where('email', isEqualTo: cleanEmail).limit(1).get();
                  if (stfSnap.docs.isNotEmpty) userFoundInDb = true;
                }
              }
            }
          } catch (dbErr) {
            debugPrint('Firestore user existence verification error: $dbErr');
          }
        }

        if (!userFoundInDb) {
          throw 'User not found. No account is registered with this email address. Please check your email or Sign Up.';
        } else {
          throw 'Incorrect password. Please verify your password or use "Forgot password".';
        }
      }
      if (e.code == 'user-disabled') {
        throw 'This account has been disabled. Please contact the administrator.';
      }
      if (e.code == 'too-many-requests') {
        throw 'Too many failed login attempts. Please try again later or reset your password.';
      }
      if (e.code == 'invalid-email') {
        throw 'The email address format is invalid. Please enter a valid Gmail address.';
      }
      throw e.message ?? 'Authentication failed. Please check your credentials and try again.';
    } catch (e) {
      debugPrint('Firebase Auth sign in error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    _mockUser = null;
    final auth = await _getOrInitAuth();
    if (auth == null) {
      _mockUser = UserModel(
        uid: 'DEMO-GGL-USER',
        email: 'alex.google@gmail.com',
        fullName: 'Alex Johnson (Google)',
        role: UserRole.student,
      );
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      return;
    }
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      UserCredential credential;
      if (kIsWeb) {
        try {
          credential = await auth.signInWithPopup(googleProvider);
        } on FirebaseAuthException catch (popupErr) {
          debugPrint('Firebase Google Sign-In popup notice: ${popupErr.code} - ${popupErr.message}');
          if (popupErr.code == 'popup-closed-by-user' || popupErr.code == 'cancelled-popup-request') {
            return;
          }
          if (popupErr.code == 'popup-blocked') {
            debugPrint('Popup blocked by browser, falling back to signInWithRedirect');
            await auth.signInWithRedirect(googleProvider);
            return;
          }
          rethrow;
        }
      } else {
        credential = await auth.signInWithProvider(googleProvider);
      }

      if (credential.user != null) {
        final fbUser = credential.user!;
        unawaited(UserSessionService.instance.recordLogin(fbUser.uid));

        // 1. Check if user profile already exists in Firestore by UID
        var userData = await getUserData(fbUser.uid);

        // 2. If not found by UID, check by email
        if (userData == null && fbUser.email != null && fbUser.email!.isNotEmpty) {
          final email = fbUser.email!.trim().toLowerCase();
          final firestore = _resolvedFirestore;
          if (firestore != null) {
            try {
              final query = await firestore
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
              if (query.docs.isNotEmpty) {
                final docData = query.docs.first.data();
                userData = UserModel.fromMap(docData, fbUser.uid);
                await firestore.collection('users').doc(fbUser.uid).set(userData.toMap(), SetOptions(merge: true));
              }
            } catch (e) {
              debugPrint('Firestore email lookup notice: $e');
            }
          }
        }

        // 3. If completely new user, create default profile and persist
        if (userData == null) {
          userData = _mapFirebaseUserToDefaultModel(fbUser, null);
          await saveUserData(userData);
        }

        _currentUser = userData;
        _stateController.add(userData);
        _handleFirebaseUserChange(fbUser, explicitUser: userData);
        return;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google Sign-In FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        return;
      }
      if (e.code == 'account-exists-with-different-credential') {
        throw 'An account already exists with this email address using a different sign-in method.';
      }
      if (kIsWeb &&
          (e.code == 'unauthorized-domain' ||
           e.code == 'operation-not-allowed' ||
           e.code == 'configuration-not-found' ||
           e.code == 'auth-domain-config-required')) {
        debugPrint('Firebase Google Sign-In: web unconfigured domain/provider (${e.code}), falling back to demo user');
        _mockUser = UserModel(
          uid: 'DEMO-GGL-USER',
          email: 'alex.google@gmail.com',
          fullName: 'Alex Johnson (Google)',
          role: UserRole.student,
        );
        _currentUser = _mockUser;
        _stateController.add(_mockUser);
        unawaited(UserSessionService.instance.recordLogin('DEMO-GGL-USER'));
        return;
      }
      if (e.code == 'unauthorized-domain') {
        throw 'This domain (${kIsWeb ? Uri.base.host : 'this domain'}) is not authorized for Google Sign-In in Firebase Console. Please add it to Authentication -> Settings -> Authorized domains in Firebase.';
      }
      if (e.code == 'operation-not-allowed') {
        throw 'Google Sign-In is not enabled in Firebase Console. Please enable Google provider under Firebase Authentication -> Sign-in method.';
      }
      throw e.message ?? 'Google Sign-In failed. Please try again.';
    } catch (e) {
      debugPrint('Firebase Google Sign-In notice: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup-closed-by-user') || errStr.contains('cancelled')) {
        return;
      }
      if (kIsWeb &&
          (errStr.contains('unauthorized-domain') ||
           errStr.contains('operation-not-allowed') ||
           errStr.contains('configuration-not-found') ||
           errStr.contains('auth-domain-config-required'))) {
        debugPrint('Firebase Google Sign-In web notice, falling back to demo user');
        _mockUser = UserModel(
          uid: 'DEMO-GGL-USER',
          email: 'alex.google@gmail.com',
          fullName: 'Alex Johnson (Google)',
          role: UserRole.student,
        );
        _currentUser = _mockUser;
        _stateController.add(_mockUser);
        unawaited(UserSessionService.instance.recordLogin('DEMO-GGL-USER'));
        return;
      }
      if (errStr.contains('unauthorized-domain')) {
        throw 'This domain (${kIsWeb ? Uri.base.host : 'this domain'}) is not authorized for Google Sign-In in Firebase Console. Please add it to Authentication -> Settings -> Authorized domains in Firebase.';
      }
      if (errStr.contains('operation-not-allowed')) {
        throw 'Google Sign-In is not enabled in Firebase Console. Please enable Google provider under Firebase Authentication -> Sign-in method.';
      }
      rethrow;
    }
  }

  @override
  Future<void> signInWithApple() async {
    _mockUser = null;
    final auth = await _getOrInitAuth();
    if (auth == null) {
      _mockUser = UserModel(
        uid: 'DEMO-APL-USER',
        email: 'alex.apple@gmail.com',
        fullName: 'Alex Johnson (Apple)',
        role: UserRole.student,
      );
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      return;
    }
    try {
      final appleProvider = OAuthProvider('apple.com');
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      UserCredential credential;
      if (kIsWeb) {
        try {
          credential = await auth.signInWithPopup(appleProvider);
        } on FirebaseAuthException catch (popupErr) {
          debugPrint('Firebase Apple Sign-In popup notice: ${popupErr.code} - ${popupErr.message}');
          if (popupErr.code == 'popup-closed-by-user' || popupErr.code == 'cancelled-popup-request') {
            return;
          }
          if (popupErr.code == 'popup-blocked') {
            debugPrint('Apple Sign-In popup blocked by browser, falling back to signInWithRedirect');
            await auth.signInWithRedirect(appleProvider);
            return;
          }
          rethrow;
        }
      } else {
        credential = await auth.signInWithProvider(appleProvider);
      }

      if (credential.user != null) {
        final fbUser = credential.user!;
        unawaited(UserSessionService.instance.recordLogin(fbUser.uid));
        var userData = await getUserData(fbUser.uid);
        if (userData == null) {
          userData = _mapFirebaseUserToDefaultModel(fbUser, null);
          await saveUserData(userData);
        }
        _currentUser = userData;
        _stateController.add(userData);
        _handleFirebaseUserChange(fbUser, explicitUser: userData);
        return;
      }
    } catch (e) {
      debugPrint('Firebase Apple Sign-In notice: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup-closed-by-user') || errStr.contains('cancelled')) {
        return;
      }
      if (kIsWeb ||
          errStr.contains('unknown') ||
          errStr.contains('operation-not-allowed') ||
          errStr.contains('configuration-not-found') ||
          errStr.contains('unauthorized-domain') ||
          errStr.contains('missing-client-identifier')) {
        // Fallback demo Apple Sign-In for environments without configured Apple Developer credentials
        _mockUser = UserModel(
          uid: 'DEMO-APL-USER',
          email: 'alex.apple@gmail.com',
          fullName: 'Alex Johnson (Apple)',
          role: UserRole.student,
        );
        _currentUser = _mockUser;
        _stateController.add(_mockUser);
        unawaited(UserSessionService.instance.recordLogin('DEMO-APL-USER'));
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String name,
    UserRole role, {
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    final lowerEmail = email.toLowerCase().trim();
    if (lowerEmail == 'student@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-STU', email: email, fullName: name, role: UserRole.student);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      unawaited(UserSessionService.instance.recordFreshSignup('DEMO-STU'));
      return;
    }
    if (lowerEmail == 'parent@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-PRT', email: email, fullName: name, role: UserRole.parent, metadata: metadata);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      unawaited(UserSessionService.instance.recordFreshSignup('DEMO-PRT'));
      return;
    }

    // REAL USER REGISTRATION: Clear mock user state first!
    _mockUser = null;

    final auth = _resolvedAuth;
    if (auth == null) {
      throw 'Firebase Authentication is not available. Please verify your connection.';
    }

    final provisionalUser = UserModel(
      uid: '',
      email: email.trim(),
      fullName: name,
      role: role,
      phone: phoneNumber,
      metadata: metadata,
    );
    _pendingRegistrationUser = provisionalUser;

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        try {
          await credential.user!.updateDisplayName(name);
        } catch (_) {}

        final newUser = provisionalUser.copyWith(uid: credential.user!.uid);
        _currentUser = newUser;
        _stateController.add(newUser);
        await saveUserData(newUser);
        unawaited(UserSessionService.instance.recordFreshSignup(credential.user!.uid));
        _handleFirebaseUserChange(credential.user, explicitUser: newUser, intendedRole: role);
        _pendingRegistrationUser = null;
        return;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Registration Error: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        final cred = await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (cred.user != null) {
          final updatedUser = provisionalUser.copyWith(uid: cred.user!.uid);
          _currentUser = updatedUser;
          _stateController.add(updatedUser);
          await saveUserData(updatedUser);
          unawaited(UserSessionService.instance.recordLogin(cred.user!.uid));
          _handleFirebaseUserChange(cred.user, explicitUser: updatedUser, intendedRole: role);
          _pendingRegistrationUser = null;
          return;
        }
      }
      _pendingRegistrationUser = null;
      throw e.message ?? e.code;
    } catch (e) {
      _pendingRegistrationUser = null;
      debugPrint('Firebase Registration Exception: $e');
      rethrow;
    }
  }


  @override
  Future<void> updateUserProfile(UserModel updatedUser) async {
    _currentUser = updatedUser;
    if (_mockUser != null) {
      _mockUser = updatedUser;
    }
    await saveUserData(updatedUser);
    _stateController.add(updatedUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _resolvedAuth;
    if (auth == null) {
      throw Exception('Firebase Authentication is not available.');
    }
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('Firebase: Password reset email successfully dispatched to ${email.trim()}');
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Password Reset Error [${e.code}]: ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email address.');
        case 'invalid-email':
          throw Exception('The email address is invalid.');
        case 'too-many-requests':
          throw Exception('Too many reset requests. Please wait a few minutes before trying again.');
        case 'network-request-failed':
          throw Exception('Network connection error. Please check your internet connection.');
        default:
          throw Exception(e.message ?? 'Failed to send password reset email.');
      }
    } catch (e) {
      debugPrint('Firebase Password Reset Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    try {
      final auth = _resolvedAuth;
      if (auth != null) {
        await auth.signOut();
      }
    } catch (e) {
      debugPrint('Firebase SignOut Warning: $e');
    }
    _currentUser = null;
    _stateController.add(null);
  }

  Future<UserModel?> getUserData(String uid) async {
    final firestore = _resolvedFirestore;
    if (uid.isEmpty || firestore == null) return null;
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        var user = UserModel.fromMap(doc.data()!, uid);
        if (user.role == UserRole.student || user.role == UserRole.unknown) {
          try {
            final staffDoc = await firestore.collection('staff').doc(uid).get();
            if (staffDoc.exists && staffDoc.data() != null) {
              final isAdv = staffDoc.data()?['isAdvisor'] == true;
              return user.copyWith(
                role: isAdv ? UserRole.advisor : UserRole.staff,
                metadata: {...?user.metadata, ...staffDoc.data()!},
              );
            }
          } catch (_) {}

          try {
            final parentDoc = await firestore.collection('parents').doc(uid).get();
            if (parentDoc.exists && parentDoc.data() != null) {
              return user.copyWith(
                role: UserRole.parent,
                metadata: {...?user.metadata, ...parentDoc.data()!},
              );
            }
          } catch (_) {}
        }
        return user;
      }

      // If user doc not found in users/{uid}, check users collection by email
      final fbAuth = _resolvedAuth;
      final currentFbUser = fbAuth?.currentUser;
      final currentEmail = (currentFbUser?.uid == uid ? currentFbUser?.email : null)?.trim().toLowerCase();
      if (currentEmail != null && currentEmail.isNotEmpty) {
        try {
          final emailQuery = await firestore.collection('users').where('email', isEqualTo: currentEmail).limit(1).get();
          if (emailQuery.docs.isNotEmpty) {
            final data = emailQuery.docs.first.data();
            final user = UserModel.fromMap(data, uid);
            unawaited(firestore.collection('users').doc(uid).set(user.toMap(), SetOptions(merge: true)));
            return user;
          }
        } catch (_) {}
      }

      // If user doc not found in users/{uid}, check staff/{uid} directly
      try {
        final staffDoc = await firestore.collection('staff').doc(uid).get();
        if (staffDoc.exists && staffDoc.data() != null) {
          final sData = staffDoc.data()!;
          final isAdv = sData['isAdvisor'] == true;
          return UserModel(
            uid: uid,
            email: sData['email']?.toString() ?? '',
            fullName: sData['fullName']?.toString() ?? sData['name']?.toString() ?? 'Faculty Member',
            role: isAdv ? UserRole.advisor : UserRole.staff,
            phone: sData['phone']?.toString() ?? '',
            metadata: sData,
          );
        }
      } catch (_) {}

      // Check parents/{uid} directly
      try {
        final parentDoc = await firestore.collection('parents').doc(uid).get();
        if (parentDoc.exists && parentDoc.data() != null) {
          final pData = parentDoc.data()!;
          return UserModel(
            uid: uid,
            email: pData['email']?.toString() ?? '',
            fullName: pData['fullName']?.toString() ?? pData['name']?.toString() ?? 'Parent / Guardian',
            role: UserRole.parent,
            phone: pData['phone']?.toString() ?? '',
            metadata: pData,
          );
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Firestore getUserData Warning: $e');
    }
    return null;
  }

  Future<void> saveUserData(UserModel user) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return;
    try {
      final userMap = user.toMap();
      final meta = user.metadata ?? {};
      final regNo = (meta['registerNumber'] ?? meta['regNo'] ?? meta['studentId'])?.toString().trim();
      final dept = (meta['department'] ?? meta['departmentName'])?.toString().trim();
      final year = (meta['year'] ?? meta['currentYear'])?.toString().trim();
      final sem = (meta['semester'] ?? meta['currentSemester'])?.toString().trim();

      if (regNo != null && regNo.isNotEmpty) {
        userMap['registerNumber'] = regNo;
        userMap['regNo'] = regNo;
        userMap['studentId'] = regNo;
      }
      if (dept != null && dept.isNotEmpty) {
        userMap['department'] = dept;
        userMap['departmentName'] = dept;
      }
      if (year != null && year.isNotEmpty) {
        userMap['currentYear'] = year;
        userMap['year'] = year;
      }
      if (sem != null && sem.isNotEmpty) {
        userMap['semester'] = sem;
        userMap['currentSemester'] = sem;
      }

      // Sanitize profile photo URL: strictly accept remote URLs (http:// or https://)
      String? cleanPhoto;
      final rawPhoto = (user.profileImageUrl ?? meta['passportPhotoUrl'] ?? meta['photoUrl'])?.toString().trim();
      if (rawPhoto != null && rawPhoto.isNotEmpty) {
        if (rawPhoto.startsWith('http://') || rawPhoto.startsWith('https://')) {
          cleanPhoto = rawPhoto;
        } else {
          // Reject any local paths (/Users/..., /tmp/..., file://...)
          debugPrint('FirebaseAuthService: Filtered out invalid local photo path "$rawPhoto" from Firestore save.');
          cleanPhoto = null;
        }
      } else if (user.profileImageUrl == '') {
        // Explicitly removed photo
        cleanPhoto = '';
      }

      if (cleanPhoto != null) {
        userMap['profileImageUrl'] = cleanPhoto;
        userMap['photoUrl'] = cleanPhoto;
      } else {
        userMap.remove('profileImageUrl');
        userMap.remove('photoUrl');
      }

      // Also sanitize metadata
      if (userMap['metadata'] is Map) {
        final metaCopy = Map<String, dynamic>.from(userMap['metadata']);
        if (cleanPhoto != null && cleanPhoto.isNotEmpty) {
          metaCopy['photoUrl'] = cleanPhoto;
          metaCopy['passportPhotoUrl'] = cleanPhoto;
          metaCopy['profileImageUrl'] = cleanPhoto;
        } else if (cleanPhoto == '') {
          metaCopy['photoUrl'] = '';
          metaCopy['passportPhotoUrl'] = '';
          metaCopy['profileImageUrl'] = '';
        } else {
          final metaPhoto = metaCopy['photoUrl']?.toString() ?? '';
          if (!metaPhoto.startsWith('http://') && !metaPhoto.startsWith('https://')) {
            metaCopy.remove('photoUrl');
          }
          final metaPassport = metaCopy['passportPhotoUrl']?.toString() ?? '';
          if (!metaPassport.startsWith('http://') && !metaPassport.startsWith('https://')) {
            metaCopy.remove('passportPhotoUrl');
          }
        }
        userMap['metadata'] = metaCopy;
      }

      userMap['role'] = user.role.name;
      userMap['userRole'] = user.role.name;
      await firestore.collection('users').doc(user.uid).set(userMap, SetOptions(merge: true));

      if (user.role == UserRole.staff || user.role == UserRole.advisor) {
        final staffId = (meta['staffId'] ?? meta['employeeId'] ?? meta['registerNumber'] ?? meta['regNo'] ?? user.uid).toString();
        final staffDoc = {
          'userId': user.uid,
          'uid': user.uid,
          'name': user.fullName,
          'fullName': user.fullName,
          'email': user.email,
          'phone': user.phone,
          'department': dept ?? 'Computer Science',
          'departmentName': dept ?? 'Computer Science',
          'role': 'staff',
          'userRole': 'staff',
          'staffId': staffId,
          'employeeId': staffId,
          'registerNumber': staffId,
          'isAdvisor': meta['isAdvisor'] == true,
          'advisorSection': meta['advisorSection']?.toString(),
          'profileImageUrl': cleanPhoto ?? '',
          'photoUrl': cleanPhoto ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
          ...meta,
        };
        await firestore.collection('staff').doc(user.uid).set(staffDoc, SetOptions(merge: true));
      }

      if (user.role == UserRole.hod) {
        final hodDoc = {
          'userId': user.uid,
          'uid': user.uid,
          'name': user.fullName,
          'fullName': user.fullName,
          'email': user.email,
          'phone': user.phone,
          'department': dept ?? 'Computer Science',
          'departmentName': dept ?? 'Computer Science',
          'role': 'hod',
          'userRole': 'hod',
          'profileImageUrl': cleanPhoto ?? '',
          'photoUrl': cleanPhoto ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
          ...meta,
        };
        await firestore.collection('users').doc(user.uid).set(hodDoc, SetOptions(merge: true));
      }

      if (user.role == UserRole.parent) {
        final parentDoc = {
          'parentId': user.uid,
          'userId': user.uid,
          'uid': user.uid,
          'name': user.fullName,
          'fullName': user.fullName,
          'email': user.email,
          'phone': user.phone,
          'role': 'parent',
          'userRole': 'parent',
          'profileImageUrl': cleanPhoto ?? '',
          'photoUrl': cleanPhoto ?? '',
          if (meta['wardRegisterNumbers'] != null) 'wardRegisterNumbers': meta['wardRegisterNumbers'],
          if (meta['childRegisterNumbers'] != null) 'childRegisterNumbers': meta['childRegisterNumbers'],
          if (meta['studentIds'] != null) 'studentIds': meta['studentIds'],
          'updatedAt': FieldValue.serverTimestamp(),
          ...meta,
        };
        await firestore.collection('parents').doc(user.uid).set(parentDoc, SetOptions(merge: true));
      }

      if (user.role == UserRole.student && regNo != null && regNo.isNotEmpty) {
        final photo = cleanPhoto ?? '';
        final batch = meta['batch']?.toString() ??
            (year != null && (year.contains('2nd') || year.contains('II Year'))
                ? '2024 - 2028'
                : (year != null && (year.contains('4th') || year.contains('IV Year'))
                    ? '2022 - 2026'
                    : '2023 - 2027'));

        final studentDoc = {
          'userId': user.uid,
          'uid': user.uid,
          'studentId': user.uid,
          'registerNumber': regNo,
          'regNo': regNo,
          'fullName': user.fullName,
          'name': user.fullName,
          'email': user.email,
          'phone': user.phone,
          'department': dept ?? '',
          'departmentName': dept ?? '',
          'year': year ?? '',
          'currentYear': year ?? '',
          'semester': sem ?? '',
          'currentSemester': sem ?? '',
          'batch': batch,
          'profileImageUrl': photo,
          'photoUrl': photo,
          'passportPhotoUrl': photo,
          'updatedAt': FieldValue.serverTimestamp(),
          ...meta,
        };
        // Canonical write to students/{uid}
        await firestore.collection('students').doc(user.uid).set(studentDoc, SetOptions(merge: true));

        final profileDoc = {
          'studentUid': user.uid,
          'registerNumber': regNo,
          'batch': batch,
          'photoUrl': photo,
          'profileImageUrl': photo,
          'personal': {
            'fullName': user.fullName,
            'email': user.email,
            'phone': user.phone,
            'batch': batch,
            'photoUrl': photo,
            'passportPhotoUrl': photo,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        };
        // Canonical write to student_profiles/{uid}
        await firestore.collection('student_profiles').doc(user.uid).set(profileDoc, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore saveUserData Warning: $e');
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    _stateController.close();
  }
}

