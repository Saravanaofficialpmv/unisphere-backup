import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/firebase_options.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/services/web_firebase_registrant.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();

  FirebaseService._internal();

  bool _initialized = false;
  bool get isInitialized {
    try {
      if (Firebase.apps.isNotEmpty) return true;
    } catch (_) {}
    return _initialized;
  }
  Future<bool>? _initFuture;

  FirebaseAuth? get auth {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get storage {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseStorage.instance;
    } catch (_) {}
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initialize Firebase app safely across platforms
  Future<bool> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        return true;
      }
    } catch (_) {}

    if (_initialized) return true;
    _initFuture ??= _performInitialize();
    final result = await _initFuture!;
    if (!result) {
      _initFuture = null; // allow retry on failure
    }
    return result;
  }

  Future<bool> _performInitialize() async {
    try {
      registerWebFirebasePlugins();
      try {
        if (Firebase.apps.isNotEmpty) {
          _initialized = true;
          return true;
        }
      } catch (_) {}

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        final errStr = '${e.code} ${e.message}'.toLowerCase();
        if (errStr.contains('duplicate') || errStr.contains('already exists')) {
          debugPrint('Firebase already initialized: ${e.message}');
        } else {
          rethrow;
        }
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('duplicate') || errStr.contains('already exists')) {
          debugPrint('Firebase already initialized.');
        } else {
          debugPrint('Platform specific options notice: $e, attempting fallback init');
          try {
            await Firebase.initializeApp();
          } catch (inner) {
            final innerStr = inner.toString().toLowerCase();
            if (!innerStr.contains('duplicate') && !innerStr.contains('already exists')) {
              rethrow;
            }
          }
        }
      }

      _initialized = true;
      debugPrint('Firebase initialized successfully.');
      // Asynchronously seed initial data in microtask without blocking initialization flow
      unawaited(FirebaseFirestoreService().seedInitialDataIfEmpty());
      return true;
    } catch (e) {
      debugPrint('Firebase initialization warning: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('duplicate') || errStr.contains('already exists')) {
        _initialized = true;
        return true;
      }
      try {
        if (Firebase.apps.isNotEmpty) {
          _initialized = true;
          return true;
        }
      } catch (_) {}
      _initialized = false;
      _initFuture = null; // allow retry
      return false;
    }
  }

  // Firestore Collection References
  CollectionReference? get usersCollection => firestore?.collection('users');
  CollectionReference? get announcementsCollection => firestore?.collection('announcements');
  CollectionReference? get assignmentsCollection => firestore?.collection('assignments');
  CollectionReference? get submissionsCollection => firestore?.collection('submissions');
  CollectionReference? get marksCollection => firestore?.collection('marks');
  CollectionReference? get attendanceCollection => firestore?.collection('attendance');
  CollectionReference? get hackathonsCollection => firestore?.collection('hackathons');
  CollectionReference? get examsCollection => firestore?.collection('exams');
  CollectionReference? get leavesCollection => firestore?.collection('leaves');
}
