import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/student_model.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

final departmentStudentsStreamProvider = StreamProvider.family<List<StudentModel>, String>((ref, deptId) {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.watchStudentsByDepartment(deptId);
});

class StudentRepository {
  final FirebaseFirestore? _firestore;

  StudentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static bool get isOfflineEnvironment => _tryGetFirestore() == null;

  static final List<StudentModel> offlineBaselineStudents = const [];

  /// Fetch single student record by UID or Registration Number
  Future<StudentModel?> getStudentByUserId(String uid) async {
    final firestore = _firestore;
    if (uid.isEmpty || firestore == null) return null;
    try {
      // 1. Try lookup by doc ID (regNo or UID)
      final docSnap = await firestore.collection('students').doc(uid).get();
      if (docSnap.exists && docSnap.data() != null) {
        return StudentModel.fromMap(docSnap.data()!, docSnap.id);
      }

      // 2. Query by user_id
      final snapshot = await firestore
          .collection('students')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return StudentModel.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      debugPrint('Firestore getStudentByUserId error: $e');
    }
    return null;
  }

  /// Fetch single student record directly by unique Register Number
  Future<StudentModel?> getStudentByRegisterNumber(String regNo) async {
    final firestore = _firestore;
    final cleanReg = regNo.trim();
    if (cleanReg.isEmpty || firestore == null) return null;
    try {
      final docSnap = await firestore.collection('students').doc(cleanReg).get();
      if (docSnap.exists && docSnap.data() != null) {
        return StudentModel.fromMap(docSnap.data()!, docSnap.id);
      }

      final snapshot = await firestore
          .collection('students')
          .where('register_number', isEqualTo: cleanReg)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return StudentModel.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      debugPrint('Firestore getStudentByRegisterNumber error: $e');
    }
    return null;
  }

  /// Listen to real-time student updates by UID
  Stream<StudentModel?> watchStudentByUserId(String uid) {
    final firestore = _firestore;
    if (uid.isEmpty || firestore == null) {
      return Stream.value(null);
    }
    return firestore
        .collection('students')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return StudentModel.fromMap(doc.data(), doc.id);
      }
      return null;
    }).handleError((e) {
      debugPrint('Student snapshot stream notice: $e');
      return null;
    });
  }

  /// Listen to real-time student updates by Register Number
  Stream<StudentModel?> watchStudentByRegisterNumber(String regNo) {
    final firestore = _firestore;
    final cleanReg = regNo.trim();
    if (cleanReg.isEmpty || firestore == null) {
      return Stream.value(null);
    }
    return firestore
        .collection('students')
        .doc(cleanReg)
        .snapshots()
        .map((docSnap) {
      if (docSnap.exists && docSnap.data() != null) {
        return StudentModel.fromMap(docSnap.data()!, docSnap.id);
      }
      return null;
    }).handleError((e) {
      debugPrint('Student regNo stream notice: $e');
      return null;
    });
  }

  /// Watch real-time stream of students belonging strictly to a department
  Stream<List<StudentModel>> watchStudentsByDepartment(String departmentId) {
    final firestore = _firestore;
    final cleanDept = departmentId.trim();
    if (firestore == null || cleanDept.isEmpty) {
      return Stream.value(const []);
    }

    return firestore.collection('students').snapshots().map((snap) {
      final Map<String, StudentModel> deduplicated = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final model = StudentModel.fromMap(data, doc.id);
        if (_matchesDepartment(model, cleanDept)) {
          final key = model.registerNumber.isNotEmpty ? model.registerNumber : model.studentId;
          deduplicated[key] = model;
        }
      }
      return deduplicated.values.toList()
        ..sort((a, b) => a.registerNumber.compareTo(b.registerNumber));
    }).handleError((e) {
      debugPrint('StudentRepository watchStudentsByDepartment error: $e');
      return <StudentModel>[];
    });
  }

  /// Get students belonging strictly to a department
  Future<List<StudentModel>> getStudentsByDepartment(String departmentId) async {
    final firestore = _firestore;
    final cleanDept = departmentId.trim();
    if (firestore == null || cleanDept.isEmpty) return const [];

    try {
      final snap = await firestore.collection('students').get();
      final Map<String, StudentModel> deduplicated = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final model = StudentModel.fromMap(data, doc.id);
        if (_matchesDepartment(model, cleanDept)) {
          final key = model.registerNumber.isNotEmpty ? model.registerNumber : model.studentId;
          deduplicated[key] = model;
        }
      }
      return deduplicated.values.toList()
        ..sort((a, b) => a.registerNumber.compareTo(b.registerNumber));
    } catch (e) {
      debugPrint('StudentRepository getStudentsByDepartment error: $e');
      return [];
    }
  }

  static bool _matchesDepartment(StudentModel student, String targetDept) {
    final cleanTarget = targetDept.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final studentDeptId = student.departmentId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final studentDeptName = student.departmentName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (cleanTarget.isEmpty) return true;
    if (studentDeptId == cleanTarget || studentDeptName == cleanTarget) return true;
    if (studentDeptId.contains(cleanTarget) || cleanTarget.contains(studentDeptId)) return true;
    if (cleanTarget.contains('cse') || cleanTarget.contains('computerscience')) {
      if (studentDeptId.contains('cse') || studentDeptName.contains('computerscience')) return true;
    }
    return false;
  }

  /// Save or update student record stored under unique Register Number doc ID
  Future<void> saveStudent(StudentModel student) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final regNo = student.registerNumber.trim();
      if (regNo.isNotEmpty) {
        await firestore
            .collection('students')
            .doc(regNo)
            .set(student.toMap(), SetOptions(merge: true));
      }
      if (student.studentId.isNotEmpty) {
        await firestore
            .collection('students')
            .doc(student.studentId)
            .set(student.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore saveStudent error: $e');
    }
  }
}
