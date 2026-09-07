import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/firebase_options.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();

  FirebaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;
  Future<bool>? _initFuture;

  FirebaseAuth? get auth {
    if (!_initialized) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get firestore {
    if (!_initialized) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get storage {
    if (!_initialized) return null;
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initialize Firebase app safely across platforms without querying Firebase.apps on Web before initialization
  Future<bool> initialize() {
    if (_initialized) return Future.value(true);
    _initFuture ??= _performInitialize();
    return _initFuture!;
  }

  Future<bool> _performInitialize() async {
    try {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        if (e.code == 'duplicate-app') {
          debugPrint('Firebase already initialized: ${e.message}');
        } else {
          rethrow;
        }
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('duplicate') || errStr.contains('already exists')) {
          debugPrint('Firebase already initialized.');
        } else {
          debugPrint('Platform specific options failed, trying default initializeApp: $e');
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
