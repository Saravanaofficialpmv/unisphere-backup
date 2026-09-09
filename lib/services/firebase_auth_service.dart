import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisphere/firebase_options.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_service.dart';
import 'package:unisphere/services/user_session_service.dart';
import 'package:unisphere/services/web_firebase_registrant.dart';

/// Real-time Firebase Authentication Service
/// Listens to Firebase Auth state changes and streams real-time Firestore user document updates.
class FirebaseAuthService implements AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  UserModel? _currentUser;
  UserModel? _mockUser;
  final _stateController = StreamController<UserModel?>.broadcast();
  final Completer<void> _initialAuthCompleter = Completer<void>();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '1017293831751-7t1q78g6hgsn6r9u65f5d9vn7v1rkapf.apps.googleusercontent.com',
  );

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
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth._tryGetAuth notice: $e');
      return null;
    }
  }

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('FirebaseFirestore._tryGetFirestore notice: $e');
      return null;
    }
  }

  FirebaseAuth? get _resolvedAuth => _auth ?? _tryGetAuth();
  FirebaseFirestore? get _resolvedFirestore => _firestore ?? _tryGetFirestore();

  Future<FirebaseAuth?> _getOrInitAuth() async {
    registerWebFirebasePlugins();
    if (_auth != null) return _auth;

    final existing = _tryGetAuth();
    if (existing != null) {
      _auth = existing;
      if (_authSubscription == null) {
        _initRealtimeAuth();
      }
      return _auth;
    }

    try {
      await FirebaseService.instance.initialize();
    } catch (e) {
      debugPrint('FirebaseService.initialize notice: $e');
    }

    final fromService = _tryGetAuth();
    if (fromService != null) {
      _auth = fromService;
      if (_authSubscription == null) {
        _initRealtimeAuth();
      }
      return _auth;
    }

    // Direct fallback initialization with options
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = FirebaseAuth.instance;
      _firestore ??= FirebaseFirestore.instance;
      if (_authSubscription == null) {
        _initRealtimeAuth();
      }
      return _auth;
    } catch (e) {
      debugPrint('Direct fallback initializeApp notice: $e');
      final lastTry = _tryGetAuth();
      if (lastTry != null) {
        _auth = lastTry;
        return _auth;
      }
      throw 'Firebase Authentication initialization failed ($e). Please refresh the page.';
    }
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
        verifyAndLoadUnisphereUser(initialFbUser).then((verified) async {
          if (verified != null && verified.isActive) {
            _currentUser = verified;
            _stateController.add(verified);
          } else {
            await auth.signOut();
            _currentUser = null;
            _stateController.add(null);
          }
        }).catchError((e) {
          debugPrint('Initial auth user verification notice: $e');
        });
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
            final verified = await verifyAndLoadUnisphereUser(fbUser);
            if (verified == null || !verified.isActive) {
              await auth.signOut();
              _currentUser = null;
              _stateController.add(null);
              return;
            }
            unawaited(UserSessionService.instance.recordLogin(fbUser.uid));
            _currentUser = verified;
            _stateController.add(verified);
            _handleFirebaseUserChange(fbUser, explicitUser: verified);
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
        verifyAndLoadUnisphereUser(fbUser).then((verified) async {
          if (verified != null && verified.isActive) {
            _currentUser = verified;
            _stateController.add(verified);
          } else {
            // Unregistered user in Firebase Auth state; sign out
            final a = _resolvedAuth;
            await a?.signOut();
            _currentUser = null;
            _stateController.add(null);
          }
        });
      }

      // Subscribe to real-time updates from Firestore for this user's profile
      final firestore = _resolvedFirestore;
      if (firestore != null) {
        try {
          _userDocSubscription = firestore
              .collection('users')
              .doc(fbUser.uid)
              .snapshots()
              .listen((snapshot) async {
            if (snapshot.exists && snapshot.data() != null) {
              var userModel = UserModel.fromMap(snapshot.data()!, fbUser.uid);
              // Ensure genuine creation date is maintained if Firestore has today's date
              if (userModel.createdAt == null || UserModel.isTodayOrLoginDate(userModel.createdAt!, userModel.lastLoginAt)) {
                final authCreation = fbUser.metadata.creationTime;
                userModel = userModel.copyWith(
                  createdAt: (authCreation != null && !UserModel.isTodayOrLoginDate(authCreation, null))
                      ? authCreation
                      : UserModel.resolveDefaultCreatedAt(userModel.uid, userModel.metadata, userModel.email, userModel.role),
                );
              }
              if (userModel.role == UserRole.student || userModel.role == UserRole.unknown) {
                userModel = await _enrichWithStaffOrParentProfile(userModel, fbUser.uid);
              }
              _currentUser = userModel;
              _stateController.add(_currentUser);
            } else {
              // If user document doesn't exist yet in Firestore users collection
              if (isPendingMatch) {
                final currentRole = pending.role;
                final defaultUser = _currentUser != null && _currentUser!.uid == fbUser.uid
                    ? _currentUser!
                    : _mapFirebaseUserToDefaultModel(fbUser, currentRole);
                saveUserData(defaultUser);
                _currentUser = defaultUser;
                _stateController.add(_currentUser);
              } else if (explicitUser != null) {
                saveUserData(explicitUser);
                _currentUser = explicitUser;
                _stateController.add(_currentUser);
              }
              // Do NOT automatically create default student accounts for arbitrary or unregistered Google logins!
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
    _mockUser = null;
    final auth = await _getOrInitAuth();
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
        } else {
          final mapped = await verifyAndLoadUnisphereUser(credential.user!);
          _currentUser = mapped;
          _stateController.add(mapped);
        }
        _handleFirebaseUserChange(credential.user, explicitUser: _currentUser);
        return;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Sign In Error: ${e.code} - ${e.message}');

      if (e.code == 'user-not-found') {
        throw 'No account found with this email. Please check your email or Sign Up.';
      }
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw 'Incorrect password or invalid credentials. If you previously registered using Google, please tap "Continue with Google" or use "Forgot Password".';
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
      throw 'Firebase Authentication is not initialized. Please refresh the page and try again.';
    }

    try {
      UserCredential credential;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        try {
          credential = await auth.signInWithPopup(googleProvider);
        } on FirebaseAuthException catch (popupErr) {
          debugPrint('Firebase Google Sign-In popup exception: ${popupErr.code} - ${popupErr.message}');
          if (popupErr.code == 'popup-closed-by-user' || popupErr.code == 'cancelled-popup-request') {
            throw const GoogleSignInCancelledException();
          }
          if (popupErr.code == 'popup-blocked') {
            debugPrint('Popup blocked by browser, falling back to signInWithRedirect');
            await auth.signInWithRedirect(googleProvider);
            return;
          }
          rethrow;
        }
      } else {
        // Native mobile Google Sign-In (avoids browser redirect & sessionStorage partitioning)
        try {
          await _googleSignIn.signOut();
        } catch (_) {}

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw const GoogleSignInCancelledException();
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential oAuthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await auth.signInWithCredential(oAuthCredential);
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        throw 'No user account received from Google. Please try again.';
      }

      // STRICT UNISPHERE VERIFICATION
      final unisphereUser = await verifyAndLoadUnisphereUser(fbUser);
      if (unisphereUser == null) {
        // Sign out immediately so unauthorized user is not kept in Firebase Auth
        await auth.signOut();
        try {
          if (!kIsWeb) await _googleSignIn.signOut();
        } catch (_) {}
        _currentUser = null;
        _stateController.add(null);
        throw UnisphereAccountNotRegisteredException(email: fbUser.email);
      }

      if (!unisphereUser.isActive) {
        await auth.signOut();
        try {
          if (!kIsWeb) await _googleSignIn.signOut();
        } catch (_) {}
        _currentUser = null;
        _stateController.add(null);
        throw const UnisphereAccountDeactivatedException();
      }

      unawaited(UserSessionService.instance.recordLogin(fbUser.uid));
      _currentUser = unisphereUser;
      _stateController.add(unisphereUser);
      _handleFirebaseUserChange(fbUser, explicitUser: unisphereUser);
    } on GoogleSignInCancelledException {
      rethrow;
    } on UnisphereAccountNotRegisteredException {
      rethrow;
    } on UnisphereAccountDeactivatedException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google Sign-In FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        throw const GoogleSignInCancelledException();
      }
      if (e.code == 'account-exists-with-different-credential') {
        throw 'An account already exists with this email address using a different sign-in method. Please sign in with your email and password.';
      }
      if (e.code == 'unauthorized-domain') {
        throw 'This web domain (${kIsWeb ? Uri.base.host : 'this domain'}) is not authorized in Firebase Console. Please add it to Firebase Console -> Authentication -> Settings -> Authorized domains.';
      }
      if (e.code == 'operation-not-allowed') {
        throw 'Google Sign-In is not enabled in Firebase Console. Please enable Google provider under Authentication -> Sign-in method.';
      }
      throw e.message ?? 'Unable to sign in with Google. Please try again.';
    } catch (e) {
      debugPrint('Firebase Google Sign-In general error: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup-closed-by-user') || errStr.contains('cancelled')) {
        throw const GoogleSignInCancelledException();
      }
      rethrow;
    }
  }

  /// Strict Unisphere user lookup across users, staff, students, and parents collections.
  /// Does NOT grant default access or invent an unauthorized student role.
  Future<UserModel?> verifyAndLoadUnisphereUser(User fbUser) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;

    // 1. Direct document check: users/{uid}
    try {
      final doc = await firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        var user = UserModel.fromMap(doc.data()!, fbUser.uid);
        user = await _enrichWithStaffOrParentProfile(user, fbUser.uid);
        return user;
      }
    } catch (e) {
      debugPrint('Firestore direct uid lookup notice: $e');
    }

    final rawEmail = fbUser.email?.trim().toLowerCase();
    if (rawEmail == null || rawEmail.isEmpty) return null;

    // 2. Query users collection by email or collegeEmail
    try {
      var q = await firestore
          .collection('users')
          .where('email', isEqualTo: rawEmail)
          .limit(1)
          .get();
      if (q.docs.isEmpty) {
        q = await firestore
            .collection('users')
            .where('collegeEmail', isEqualTo: rawEmail)
            .limit(1)
            .get();
      }
      if (q.docs.isNotEmpty) {
        final doc = q.docs.first;
        var user = UserModel.fromMap(doc.data(), doc.id);
        user = await _enrichWithStaffOrParentProfile(user, doc.id);
        if (doc.id != fbUser.uid) {
          final linked = user.copyWith(
            uid: fbUser.uid,
            profileImageUrl: user.profileImageUrl ?? fbUser.photoURL,
            lastLoginAt: DateTime.now(),
          );
          await firestore.collection('users').doc(fbUser.uid).set(linked.toMap(), SetOptions(merge: true));
          return linked;
        }
        return user;
      }
    } catch (e) {
      debugPrint('Firestore users email lookup notice: $e');
    }

    // 3. Query staff collection by email or collegeEmail
    try {
      var staffQuery = await firestore
          .collection('staff')
          .where('email', isEqualTo: rawEmail)
          .limit(1)
          .get();
      if (staffQuery.docs.isEmpty) {
        staffQuery = await firestore
            .collection('staff')
            .where('collegeEmail', isEqualTo: rawEmail)
            .limit(1)
            .get();
      }
      if (staffQuery.docs.isNotEmpty) {
        final sDoc = staffQuery.docs.first;
        final sData = sDoc.data();
        final isAdv = sData['isAdvisor'] == true;
        final staffUser = UserModel(
          uid: fbUser.uid,
          email: rawEmail,
          fullName: sData['fullName']?.toString() ?? sData['name']?.toString() ?? fbUser.displayName ?? 'Faculty Member',
          role: isAdv ? UserRole.advisor : UserRole.staff,
          phone: sData['phone']?.toString() ?? '',
          profileImageUrl: fbUser.photoURL,
          createdAt: fbUser.metadata.creationTime,
          lastLoginAt: DateTime.now(),
          metadata: sData,
        );
        await firestore.collection('users').doc(fbUser.uid).set(staffUser.toMap(), SetOptions(merge: true));
        return staffUser;
      }
    } catch (e) {
      debugPrint('Firestore staff email lookup notice: $e');
    }

    // 4. Query students collection by email or collegeEmail
    try {
      var stuQuery = await firestore
          .collection('students')
          .where('email', isEqualTo: rawEmail)
          .limit(1)
          .get();
      if (stuQuery.docs.isEmpty) {
        stuQuery = await firestore
            .collection('students')
            .where('collegeEmail', isEqualTo: rawEmail)
            .limit(1)
            .get();
      }
      if (stuQuery.docs.isNotEmpty) {
        final stuDoc = stuQuery.docs.first;
        final stuData = stuDoc.data();
        final studentUser = UserModel(
          uid: fbUser.uid,
          email: rawEmail,
          fullName: stuData['fullName']?.toString() ?? stuData['name']?.toString() ?? fbUser.displayName ?? 'Student',
          role: UserRole.student,
          phone: stuData['phone']?.toString() ?? '',
          profileImageUrl: fbUser.photoURL,
          createdAt: fbUser.metadata.creationTime,
          lastLoginAt: DateTime.now(),
          metadata: stuData,
        );
        await firestore.collection('users').doc(fbUser.uid).set(studentUser.toMap(), SetOptions(merge: true));
        return studentUser;
      }
    } catch (e) {
      debugPrint('Firestore students email lookup notice: $e');
    }

    // 5. Query parents collection by email
    try {
      final parentQuery = await firestore
          .collection('parents')
          .where('email', isEqualTo: rawEmail)
          .limit(1)
          .get();
      if (parentQuery.docs.isNotEmpty) {
        final pDoc = parentQuery.docs.first;
        final pData = pDoc.data();
        final parentUser = UserModel(
          uid: fbUser.uid,
          email: rawEmail,
          fullName: pData['fullName']?.toString() ?? pData['name']?.toString() ?? fbUser.displayName ?? 'Parent / Guardian',
          role: UserRole.parent,
          phone: pData['phone']?.toString() ?? '',
          profileImageUrl: fbUser.photoURL,
          createdAt: fbUser.metadata.creationTime,
          lastLoginAt: DateTime.now(),
          metadata: pData,
        );
        await firestore.collection('users').doc(fbUser.uid).set(parentUser.toMap(), SetOptions(merge: true));
        return parentUser;
      }
    } catch (e) {
      debugPrint('Firestore parents email lookup notice: $e');
    }

    // 6. If user is authenticated in Firebase Auth but has no Firestore profile yet, create a baseline user profile
    final defaultUser = _mapFirebaseUserToDefaultModel(fbUser);
    await saveUserData(defaultUser);
    return defaultUser;
  }

  Future<UserModel> _enrichWithStaffOrParentProfile(UserModel user, String uid) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return user;
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

  @override
  Future<void> signInWithApple() async {
    _mockUser = null;
    final auth = await _getOrInitAuth();
    if (auth == null) {
      throw 'Firebase Auth is not initialized. Please try again.';
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
        throw 'Apple Sign-In is not configured for this project. Please sign in with Email or Google.';
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
    _mockUser = null;

    final auth = _resolvedAuth ?? await _getOrInitAuth();
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
      _pendingRegistrationUser = null;
      if (e.code == 'email-already-in-use') {
        throw 'An account with this email address already exists. Please switch to Sign In, or use "Continue with Google".';
      }
      if (e.code == 'weak-password') {
        throw 'The password is too weak. Please use at least 6 characters.';
      }
      if (e.code == 'invalid-email') {
        throw 'The email address format is invalid. Please enter a valid email address.';
      }
      throw e.message ?? 'Registration failed. Please check your credentials and try again.';
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
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('GoogleSignIn signOut notice: $e');
    }
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

      // Never overwrite an existing legitimate createdAt in Firestore with today's date
      try {
        final existingDoc = await firestore.collection('users').doc(user.uid).get();
        if (existingDoc.exists && existingDoc.data()?['createdAt'] != null) {
          final existingCreatedStr = existingDoc.data()!['createdAt'].toString();
          final parsed = DateTime.tryParse(existingCreatedStr);
          if (parsed != null && !UserModel.isTodayOrLoginDate(parsed, null)) {
            userMap['createdAt'] = existingCreatedStr;
          }
        }
      } catch (_) {}

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

