import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/department_model.dart';

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  return DepartmentRepository();
});

/// Repository responsible for department metadata, academic charter, and HOD configuration.
class DepartmentRepository {
  final FirebaseFirestore? _firestore;

  DepartmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ── Default Fallback Department ──
  static DepartmentModel get defaultDepartment => DepartmentModel(
        departmentId: 'DEP-CSE',
        name: 'Computer Science & Engineering',
        code: 'CSE',
        hodId: 'DEMO-HOD',
        hodName: 'Dr. R. Kumar',
        totalStudents: 480,
        totalFaculty: 32,
      );

  /// Derive standard short code for any department name
  static String deriveDepartmentCode(String? deptName) {
    if (deptName == null || deptName.trim().isEmpty) return 'HOD';
    final clean = deptName.trim().toLowerCase();
    if (clean.contains('artificial') ||
        clean.contains('data science') ||
        clean.contains('aids') ||
        clean.contains('ai & ds') ||
        clean.contains('ai and ds')) {
      return 'AIDS';
    }
    if (clean.contains('computer science') || clean.contains('cse')) {
      return 'CSE';
    }
    if (clean.contains('information technology') || clean == 'it') {
      return 'IT';
    }
    if (clean.contains('mechanical') || clean.contains('mech')) {
      return 'MECH';
    }
    if (clean.contains('electronics') && clean.contains('communication') || clean.contains('ece')) {
      return 'ECE';
    }
    if (clean.contains('electrical') && clean.contains('electronics') || clean.contains('eee')) {
      return 'EEE';
    }
    if (clean.contains('civil')) {
      return 'CIVIL';
    }
    if (clean.contains('biotech')) {
      return 'BIOTECH';
    }

    // Acronym extraction for custom departments
    final words = deptName.trim().split(RegExp(r'\s+'));
    if (words.length > 1) {
      final acronym = words
          .where((w) => w.isNotEmpty && !['and', '&', 'of', 'in', 'the'].contains(w.toLowerCase()))
          .map((w) => w[0].toUpperCase())
          .join();
      if (acronym.isNotEmpty) return acronym;
    }
    return deptName.length > 4 ? deptName.substring(0, 4).toUpperCase() : deptName.toUpperCase();
  }

  /// Derive standard department ID string for database scoping
  static String deriveDepartmentId(String? deptName) {
    final code = deriveDepartmentCode(deptName);
    return 'DEP-$code';
  }

  /// Fetch department by departmentId (e.g. 'DEP-CSE', 'CSE', 'DEP-AIDS')
  Future<DepartmentModel?> getDepartmentById(String departmentId) async {
    final firestore = _firestore;
    final cleanId = departmentId.trim();
    if (cleanId.isEmpty || firestore == null) return defaultDepartment;

    try {
      // 1. Direct document lookup
      final doc = await firestore.collection('departments').doc(cleanId).get();
      if (doc.exists && doc.data() != null) {
        return DepartmentModel.fromMap(doc.data()!, doc.id);
      }

      // 2. Query by code or normalized ID
      final query = await firestore
          .collection('departments')
          .where('code', isEqualTo: cleanId.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return DepartmentModel.fromMap(query.docs.first.data(), query.docs.first.id);
      }
    } catch (e) {
      debugPrint('DepartmentRepository getDepartmentById error: $e');
    }
    return defaultDepartment;
  }

  /// Watch real-time department details by ID
  Stream<DepartmentModel> watchDepartment(String departmentId) {
    final firestore = _firestore;
    final cleanId = departmentId.trim();
    if (cleanId.isEmpty || firestore == null) {
      return Stream.value(defaultDepartment);
    }

    return firestore
        .collection('departments')
        .doc(cleanId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return DepartmentModel.fromMap(doc.data()!, doc.id);
          }
          return defaultDepartment;
        })
        .handleError((e) {
          debugPrint('DepartmentRepository watchDepartment error: $e');
          return defaultDepartment;
        });
  }

  /// Resolve department mapped to an authenticated HOD by HOD User ID, with support for user metadata
  Future<DepartmentModel> getDepartmentByHodId(String hodId) async {
    return getDepartmentForHod(hodId: hodId);
  }

  /// Resolve department mapped to an authenticated HOD, prioritizing the user's registered department
  Future<DepartmentModel> getDepartmentForHod({
    required String hodId,
    String? userDeptName,
    String? userDeptId,
    String? hodName,
  }) async {
    final firestore = _firestore;
    final cleanId = hodId.trim();

    String? candidateDeptName = userDeptName?.trim();
    String? candidateDeptId = userDeptId?.trim();
    String? candidateHodName = hodName?.trim();

    if (candidateDeptName != null && candidateDeptName.isNotEmpty && candidateDeptName != 'Computer Science & Engineering') {
      candidateDeptId ??= deriveDepartmentId(candidateDeptName);
    }

    if (cleanId.isEmpty || cleanId == 'DEMO-HOD') {
      if (candidateDeptName != null && candidateDeptName.isNotEmpty) {
        return DepartmentModel(
          departmentId: candidateDeptId ?? deriveDepartmentId(candidateDeptName),
          name: candidateDeptName,
          code: deriveDepartmentCode(candidateDeptName),
          hodId: cleanId,
          hodName: candidateHodName ?? 'Head of Department',
        );
      }
      return defaultDepartment;
    }

    if (firestore == null) {
      if (candidateDeptName != null && candidateDeptName.isNotEmpty) {
        return DepartmentModel(
          departmentId: candidateDeptId ?? deriveDepartmentId(candidateDeptName),
          name: candidateDeptName,
          code: deriveDepartmentCode(candidateDeptName),
          hodId: cleanId,
          hodName: candidateHodName ?? 'Head of Department',
        );
      }
      return defaultDepartment;
    }

    try {
      // 1. Check users/{cleanId} Firestore document to get real department stored on the user record
      final userDoc = await firestore.collection('users').doc(cleanId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final dbDept = userData['department']?.toString() ??
            userData['departmentName']?.toString() ??
            userData['metadata']?['department']?.toString() ??
            userData['metadata']?['departmentName']?.toString();
        if (dbDept != null && dbDept.trim().isNotEmpty) {
          candidateDeptName = dbDept.trim();
          candidateDeptId ??= userData['departmentId']?.toString() ??
              userData['department_id']?.toString() ??
              userData['metadata']?['departmentId']?.toString() ??
              deriveDepartmentId(candidateDeptName);
        }
        candidateHodName ??= userData['fullName']?.toString() ??
            userData['name']?.toString() ??
            userData['metadata']?['fullName']?.toString() ??
            userData['metadata']?['name']?.toString();
      }

      // 2. Query departments collection where hodId == cleanId or hod_id == cleanId
      final query = await firestore
          .collection('departments')
          .where('hodId', isEqualTo: cleanId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return DepartmentModel.fromMap(query.docs.first.data(), query.docs.first.id);
      }

      final altQuery = await firestore
          .collection('departments')
          .where('hod_id', isEqualTo: cleanId)
          .limit(1)
          .get();

      if (altQuery.docs.isNotEmpty) {
        return DepartmentModel.fromMap(altQuery.docs.first.data(), altQuery.docs.first.id);
      }

      // 3. If candidateDeptId is available, check departments collection by ID
      if (candidateDeptId != null && candidateDeptId.isNotEmpty) {
        final deptDoc = await firestore.collection('departments').doc(candidateDeptId).get();
        if (deptDoc.exists && deptDoc.data() != null) {
          return DepartmentModel.fromMap(deptDoc.data()!, deptDoc.id);
        }
      }

      // 4. Query departments collection by department name or derived code
      if (candidateDeptName != null && candidateDeptName.isNotEmpty) {
        final nameQuery = await firestore
            .collection('departments')
            .where('name', isEqualTo: candidateDeptName)
            .limit(1)
            .get();
        if (nameQuery.docs.isNotEmpty) {
          return DepartmentModel.fromMap(nameQuery.docs.first.data(), nameQuery.docs.first.id);
        }

        final derivedCode = deriveDepartmentCode(candidateDeptName);
        final codeQuery = await firestore
            .collection('departments')
            .where('code', isEqualTo: derivedCode)
            .limit(1)
            .get();
        if (codeQuery.docs.isNotEmpty) {
          return DepartmentModel.fromMap(codeQuery.docs.first.data(), codeQuery.docs.first.id);
        }

        // 5. Construct DepartmentModel from the user's department information
        final derivedDeptId = candidateDeptId ?? deriveDepartmentId(candidateDeptName);
        final dynamicDept = DepartmentModel(
          departmentId: derivedDeptId,
          name: candidateDeptName,
          code: derivedCode,
          hodId: cleanId,
          hodName: candidateHodName ?? 'Head of Department',
          totalStudents: 360,
          totalFaculty: 22,
        );

        // Save into departments collection asynchronously for persistence
        try {
          firestore.collection('departments').doc(derivedDeptId).set(
            dynamicDept.toMap(),
            SetOptions(merge: true),
          );
        } catch (_) {}

        return dynamicDept;
      }
    } catch (e) {
      debugPrint('DepartmentRepository getDepartmentForHod error: $e');
    }

    if (candidateDeptName != null && candidateDeptName.isNotEmpty) {
      return DepartmentModel(
        departmentId: candidateDeptId ?? deriveDepartmentId(candidateDeptName),
        name: candidateDeptName,
        code: deriveDepartmentCode(candidateDeptName),
        hodId: cleanId,
        hodName: candidateHodName ?? 'Head of Department',
      );
    }

    return defaultDepartment;
  }

  /// Watch real-time department charter (Vision, Mission, PEOs, PSOs)
  Stream<Map<String, dynamic>> watchDepartmentCharter(String departmentId) {
    final firestore = _firestore;
    final cleanId = departmentId.trim().isEmpty ? 'DEP-CSE' : departmentId.trim();
    if (firestore == null) return Stream.value({});

    return firestore
        .collection('departments')
        .doc(cleanId)
        .collection('charter')
        .doc('academic_specification')
        .snapshots()
        .map((doc) => doc.data() ?? {})
        .handleError((e) {
          debugPrint('DepartmentRepository watchDepartmentCharter error: $e');
          return <String, dynamic>{};
        });
  }

  /// Save or update department academic charter
  Future<void> saveDepartmentCharter(String departmentId, Map<String, dynamic> charterData) async {
    final firestore = _firestore;
    final cleanId = departmentId.trim().isEmpty ? 'DEP-CSE' : departmentId.trim();
    if (firestore == null) return;

    try {
      final data = Map<String, dynamic>.from(charterData);
      data['updatedAt'] = FieldValue.serverTimestamp();
      await firestore
          .collection('departments')
          .doc(cleanId)
          .collection('charter')
          .doc('academic_specification')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('DepartmentRepository saveDepartmentCharter error: $e');
      rethrow;
    }
  }

  /// Save or update department configuration
  Future<void> saveDepartment(DepartmentModel department) async {
    final firestore = _firestore;
    if (firestore == null || department.departmentId.isEmpty) return;
    try {
      final data = department.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await firestore
          .collection('departments')
          .doc(department.departmentId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('DepartmentRepository saveDepartment error: $e');
      rethrow;
    }
  }
}
