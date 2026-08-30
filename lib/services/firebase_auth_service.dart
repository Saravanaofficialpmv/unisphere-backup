import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/user_session_service.dart';

/// Real-time Firebase Authentication Service
/// Listens to Firebase Auth state changes and streams real-time Firestore user document updates.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  UserModel? _currentUser;
  UserModel? _mockUser;
  final _stateController = StreamController<UserModel?>.broadcast();

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

  void _initRealtimeAuth() {
    final auth = _resolvedAuth;
    if (auth == null) return;
    try {
      // Listen to real-time Firebase Auth user changes (login, logout, token refresh)
      _authSubscription = auth.userChanges().listen((User? fbUser) {
        _handleFirebaseUserChange(fbUser);
      }, onError: (e) {
        debugPrint('Firebase Auth Realtime Error: $e');
      });
    } catch (e) {
      debugPrint('Firebase Auth initialization notice: $e');
    }
  }

  UserModel? _pendingRegistrationUser;

  void _handleFirebaseUserChange(User? fbUser, {UserRole? intendedRole, UserModel? explicitUser}) {
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
      if (emailLower.contains('parent')) {
        inferredRole = UserRole.parent;
      } else if (emailLower.contains('hod')) {
        inferredRole = UserRole.hod;
      } else if (emailLower.contains('staff') || emailLower.contains('faculty')) {
        inferredRole = UserRole.staff;
      }
    }
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? (user.email != null ? user.email!.split('@').first : 'User'),
      role: inferredRole,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: user.metadata.lastSignInTime,
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
      _mockUser = UserModel(uid: 'DEMO-STF', email: email, fullName: 'Demo Staff', role: UserRole.staff);
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

    final auth = _resolvedAuth;
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
        _handleFirebaseUserChange(credential.user);
        return;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Sign In Error: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          final newCred = await auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          if (newCred.user != null) {
            final name = email.contains('@') ? email.split('@').first : email;
            final newUser = UserModel(
              uid: newCred.user!.uid,
              email: email.trim(),
              fullName: name,
              role: UserRole.student,
            );
            await saveUserData(newUser);
            unawaited(UserSessionService.instance.recordFreshSignup(newCred.user!.uid));
            _handleFirebaseUserChange(newCred.user);
            return;
          }
        } catch (regErr) {
          debugPrint('Firebase auto-registration notice: $regErr');
        }
      }
      throw e.message ?? e.code;
    } catch (e) {
      debugPrint('Firebase Auth sign in error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    _mockUser = null;
    final auth = _resolvedAuth;
    if (auth == null) {
      throw 'Firebase Authentication is not available. Please verify your connection.';
    }
    try {
      final googleProvider = GoogleAuthProvider();
      final credential = await auth.signInWithProvider(googleProvider);
      if (credential.user != null) {
        unawaited(UserSessionService.instance.recordLogin(credential.user!.uid));
        _handleFirebaseUserChange(credential.user);
        return;
      }
    } catch (e) {
      debugPrint('Firebase Google Sign-In notice: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithApple() async {
    _mockUser = null;
    final auth = _resolvedAuth;
    if (auth == null) {
      throw 'Firebase Authentication is not available. Please verify your connection.';
    }
    try {
      final appleProvider = OAuthProvider('apple.com');
      final credential = await auth.signInWithProvider(appleProvider);
      if (credential.user != null) {
        unawaited(UserSessionService.instance.recordLogin(credential.user!.uid));
        _handleFirebaseUserChange(credential.user);
        return;
      }
    } catch (e) {
      debugPrint('Firebase Apple Sign-In notice: $e');
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
        return UserModel.fromMap(doc.data()!, uid);
      }
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

      await firestore.collection('users').doc(user.uid).set(userMap, SetOptions(merge: true));

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
          'studentId': regNo,
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
        await firestore.collection('students').doc(regNo).set(studentDoc, SetOptions(merge: true));
        await firestore.collection('students').doc(regNo.toUpperCase()).set(studentDoc, SetOptions(merge: true));
        await firestore.collection('students').doc(user.uid).set(studentDoc, SetOptions(merge: true));
        await firestore.collection('users').doc(regNo).set(userMap, SetOptions(merge: true));
        await firestore.collection('users').doc(regNo.toUpperCase()).set(userMap, SetOptions(merge: true));

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
        await firestore.collection('student_profiles').doc(regNo).set(profileDoc, SetOptions(merge: true));
        await firestore.collection('student_profiles').doc(regNo.toUpperCase()).set(profileDoc, SetOptions(merge: true));
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

