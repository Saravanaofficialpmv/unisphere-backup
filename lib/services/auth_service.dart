import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/firebase_auth_service.dart';

class GoogleSignInCancelledException implements Exception {
  final String message;
  const GoogleSignInCancelledException([this.message = 'Sign-in cancelled.']);
  @override
  String toString() => message;
}

class UnisphereAccountNotRegisteredException implements Exception {
  final String? email;
  final String message;
  const UnisphereAccountNotRegisteredException({
    this.email,
    this.message = 'Your Google account is authenticated, but you do not currently have access to a Unisphere institution. Please contact your institution administrator.',
  });
  @override
  String toString() => message;
}

class UnisphereAccountDeactivatedException implements Exception {
  final String message;
  const UnisphereAccountDeactivatedException([
    this.message = 'Your Unisphere account has been deactivated. Please contact your institution administrator.',
  ]);
  @override
  String toString() => message;
}

abstract class AuthService {
  Stream<UserModel?> get authStateChanges;
  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(
    String email,
    String password,
    String name,
    UserRole role, {
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  });
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> updateUserProfile(UserModel updatedUser);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  UserModel? get currentUser;
  Future<void> reloadUser();
  Stream<fb.User?>? get firebaseUserStream;
  Future<void> ensureAuthReady();
}

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});


class SupabaseAuthService implements AuthService {
  final SupabaseClient _supabase;
  UserModel? _currentUser;
  final _stateController = StreamController<UserModel?>.broadcast();

  SupabaseAuthService(this._supabase) {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user == null) {
        _currentUser = null;
        _stateController.add(null);
      } else {
        final userData = await getUserData(user.id);
        _currentUser = userData;
        _stateController.add(userData);
      }
    });
    _init();
  }

  @override
  Future<void> ensureAuthReady() async {}

  @override
  Stream<UserModel?> get authStateChanges async* {
    // Immediately emit the current user so the screen doesn't stay blank
    yield _currentUser;
    yield* _stateController.stream;
  }

  Future<void> _init() async {
    _currentUser = await _getCurrentUser();
    _stateController.add(_currentUser);
  }

  Future<UserModel?> _getCurrentUser() async {
    final suUser = _supabase.auth.currentUser;
    if (suUser == null) return null;
    return await getUserData(suUser.id);
  }

  @override
  UserModel? get currentUser => _currentUser; 

  @override
  Future<void> signInWithEmail(String email, String password) async {
    // REAL SIGN IN
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid') || msg.contains('not found') || msg.contains('user_not_found')) {
        throw 'User not found. No account is registered with this email address. Please check your email or Sign Up.';
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
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.name,
        if (phoneNumber != null) 'phone': phoneNumber,
        ...?metadata,
      },
    );
    if (res.user != null) {
      _currentUser = await getUserData(res.user!.id);
      _stateController.add(_currentUser);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      throw 'Google Sign-In failed: $e';
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.apple);
    } catch (e) {
      throw 'Apple Sign-In failed: $e';
    }
  }

  @override
  Future<void> updateUserProfile(UserModel updatedUser) async {
    _currentUser = updatedUser;
    _stateController.add(updatedUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> reloadUser() async {}

  @override
  Stream<fb.User?>? get firebaseUserStream => null;

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _stateController.add(null);
  }

  Future<UserModel?> getUserData(String id) async {
    if (id.isEmpty) return null;
    try {
      final response = await _supabase.from('users').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return UserModel.fromMap(response, id);
    } catch (e) {
      return null;
    }
  }
}
