import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/auth_service.dart';

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

  void _handleFirebaseUserChange(User? fbUser) {
    if (_mockUser != null) return;

    // Cancel previous Firestore user document subscription
    _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (fbUser == null) {
      _currentUser = null;
      _stateController.add(null);
    } else {
      // Set initial user model from Firebase User metadata immediately
      if (_currentUser == null || _currentUser!.uid != fbUser.uid) {
        _currentUser = _mapFirebaseUserToDefaultModel(fbUser);
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
              _currentUser = UserModel.fromMap(snapshot.data()!, fbUser.uid);
              _stateController.add(_currentUser);
            } else {
              // If user document doesn't exist yet, save default and emit
              final defaultUser = _mapFirebaseUserToDefaultModel(fbUser);
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

  UserModel _mapFirebaseUserToDefaultModel(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? (user.email != null ? user.email!.split('@').first : 'User'),
      role: UserRole.student,
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
      return;
    }
    if (lowerEmail == 'admin@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-ADM', email: email, fullName: 'Demo Admin', role: UserRole.admin);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      return;
    }
    if (lowerEmail == 'staff@unisphere.edu' || lowerEmail == 'faculty@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-STF', email: email, fullName: 'Demo Staff', role: UserRole.staff);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      return;
    }
    if (lowerEmail == 'student@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-STU', email: email, fullName: 'Student Demo', role: UserRole.student);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
      return;
    }
    if (lowerEmail == 'parent@unisphere.edu') {
      _mockUser = UserModel(uid: 'DEMO-PRT', email: email, fullName: 'Rajesh Kumar', role: UserRole.parent);
      _currentUser = _mockUser;
      _stateController.add(_mockUser);
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
      return;
    }

    // REAL USER REGISTRATION: Clear mock user state first!
    _mockUser = null;

    final auth = _resolvedAuth;
    if (auth == null) {
      throw 'Firebase Authentication is not available. Please verify your connection.';
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        try {
          await credential.user!.updateDisplayName(name);
        } catch (_) {}

        final newUser = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          fullName: name,
          role: role,
          phone: phoneNumber,
          metadata: metadata,
        );
        await saveUserData(newUser);
        _handleFirebaseUserChange(credential.user);
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
          _handleFirebaseUserChange(cred.user);
          return;
        }
      }
      throw e.message ?? e.code;
    } catch (e) {
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
      await firestore.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
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

