import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UserSessionService manages user authentication session state,
/// distinguishing between fresh signups ("Hello, Welcome! 👋")
/// and returning logins ("Hello, Welcome Back! 👋").
class UserSessionService {
  static final UserSessionService _instance = UserSessionService._internal();
  static UserSessionService get instance => _instance;
  UserSessionService._internal();

  // In-memory cache for fast, synchronous lookups
  final Map<String, bool> _returningUserCache = {};

  /// Records that a user has just completed a brand new account registration (Fresh Signup).
  /// Sets isFreshSignup = true and hasLoggedInBefore = false for this user.
  Future<void> recordFreshSignup(String uid) async {
    if (uid.isEmpty) return;
    _returningUserCache[uid] = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_fresh_signup_$uid', true);
      await prefs.setBool('user_has_logged_in_$uid', false);
      await prefs.setInt('user_login_count_$uid', 1);
    } catch (e) {
      debugPrint('UserSessionService recordFreshSignup error: $e');
    }
  }

  /// Records that a user has logged in (Returning login or subsequent logins).
  Future<void> recordLogin(String uid) async {
    if (uid.isEmpty) return;
    _returningUserCache[uid] = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('user_login_count_$uid') ?? 0;
      await prefs.setInt('user_login_count_$uid', currentCount + 1);
      await prefs.setBool('user_fresh_signup_$uid', false);
      await prefs.setBool('user_has_logged_in_$uid', true);
    } catch (e) {
      debugPrint('UserSessionService recordLogin error: $e');
    }
  }

  /// Checks whether this user is a returning user (true) or fresh signup (false).
  /// - Returns false (Fresh Signup -> "Hello, Welcome! 👋") if user just registered.
  /// - Returns true (Returning User -> "Hello, Welcome Back! 👋") for returning users or subsequent sessions.
  Future<bool> isReturningUser(String uid) async {
    if (uid.isEmpty) return true;
    if (_returningUserCache.containsKey(uid)) {
      return _returningUserCache[uid]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final isFresh = prefs.getBool('user_fresh_signup_$uid') ?? false;
      if (isFresh) {
        _returningUserCache[uid] = false;
        return false;
      }

      final hasLoggedIn = prefs.getBool('user_has_logged_in_$uid');
      final loginCount = prefs.getInt('user_login_count_$uid') ?? 0;

      // If hasLoggedIn was explicitly set to false and loginCount <= 1, it's fresh
      if (hasLoggedIn == false && loginCount <= 1) {
        _returningUserCache[uid] = false;
        return false;
      }

      // Otherwise, user is a returning user
      _returningUserCache[uid] = true;
      return true;
    } catch (e) {
      debugPrint('UserSessionService isReturningUser error: $e');
      return true;
    }
  }

  /// Marks the fresh signup session as seen, so subsequent app launches or logins
  /// will greet the user with "Welcome Back!".
  Future<void> markUserSessionSeen(String uid) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_fresh_signup_$uid', false);
      await prefs.setBool('user_has_logged_in_$uid', true);
      _returningUserCache[uid] = true;
    } catch (e) {
      debugPrint('UserSessionService markUserSessionSeen error: $e');
    }
  }

  /// Synchronous retrieval from in-memory cache
  bool isReturningUserSync(String uid) {
    if (uid.isEmpty) return true;
    return _returningUserCache[uid] ?? true;
  }

  /// Reset session cache for testing / logout
  void clearMemoryCache() {
    _returningUserCache.clear();
  }
}

final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService.instance;
});
