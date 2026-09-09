import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_departments.dart';
import 'package:unisphere/models/department_model.dart';

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  return DepartmentRepository();
});

final departmentsWithActiveHodProvider = StreamProvider<List<DepartmentModel>>((ref) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.watchDepartmentsWithActiveHod();
});

final activeHodDepartmentsFutureProvider = FutureProvider<List<DepartmentModel>>((ref) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getDepartmentsWithActiveHod();
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
        departmentId: 'DEP-GEN',
        name: 'Department',
        code: 'DEPT',
        hodId: '',
        hodName: 'Head of Department',
        totalStudents: 0,
        totalFaculty: 0,
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

    if (cleanId.isEmpty) {
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

      DepartmentModel? resolvedDept;

      // 2. Query departments collection where hodId == cleanId or hod_id == cleanId
      final query = await firestore
          .collection('departments')
          .where('hodId', isEqualTo: cleanId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        resolvedDept = DepartmentModel.fromMap(query.docs.first.data(), query.docs.first.id);
      } else {
        final altQuery = await firestore
            .collection('departments')
            .where('hod_id', isEqualTo: cleanId)
            .limit(1)
            .get();

        if (altQuery.docs.isNotEmpty) {
          resolvedDept = DepartmentModel.fromMap(altQuery.docs.first.data(), altQuery.docs.first.id);
        }
      }

      // 3. If candidateDeptId is available, check departments collection by ID
      if (resolvedDept == null && candidateDeptId != null && candidateDeptId.isNotEmpty) {
        final deptDoc = await firestore.collection('departments').doc(candidateDeptId).get();
        if (deptDoc.exists && deptDoc.data() != null) {
          resolvedDept = DepartmentModel.fromMap(deptDoc.data()!, deptDoc.id);
        }
      }

      // 4. Query departments collection by department name or derived code
      if (resolvedDept == null && candidateDeptName != null && candidateDeptName.isNotEmpty) {
        final nameQuery = await firestore
            .collection('departments')
            .where('name', isEqualTo: candidateDeptName)
            .limit(1)
            .get();
        if (nameQuery.docs.isNotEmpty) {
          resolvedDept = DepartmentModel.fromMap(nameQuery.docs.first.data(), nameQuery.docs.first.id);
        } else {
          final derivedCode = deriveDepartmentCode(candidateDeptName);
          final codeQuery = await firestore
              .collection('departments')
              .where('code', isEqualTo: derivedCode)
              .limit(1)
              .get();
          if (codeQuery.docs.isNotEmpty) {
            resolvedDept = DepartmentModel.fromMap(codeQuery.docs.first.data(), codeQuery.docs.first.id);
          }
        }
      }

      final targetDeptId = resolvedDept?.departmentId ?? candidateDeptId ?? deriveDepartmentId(candidateDeptName);
      final targetDeptName = resolvedDept?.name ?? candidateDeptName ?? 'Department';
      final targetDeptCode = resolvedDept?.code ?? deriveDepartmentCode(targetDeptName);

      // Dynamically compute genuine count of registered students and staff
      final actualCounts = await fetchActualDepartmentCounts(
        departmentId: targetDeptId,
        departmentName: targetDeptName,
        departmentCode: targetDeptCode,
      );

      if (resolvedDept != null) {
        // Self-heal: If Firestore doc has mock numbers (e.g. 360/22) or stale counts, persist real counts
        if (resolvedDept.totalStudents != actualCounts.totalStudents ||
            resolvedDept.totalFaculty != actualCounts.totalFaculty) {
          try {
            await firestore.collection('departments').doc(resolvedDept.departmentId).set({
              'totalStudents': actualCounts.totalStudents,
              'total_students': actualCounts.totalStudents,
              'totalFaculty': actualCounts.totalFaculty,
              'total_faculty': actualCounts.totalFaculty,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
        }

        return DepartmentModel(
          departmentId: resolvedDept.departmentId,
          name: resolvedDept.name,
          code: resolvedDept.code,
          hodId: resolvedDept.hodId ?? cleanId,
          hodName: resolvedDept.hodName ?? candidateHodName,
          totalStudents: actualCounts.totalStudents,
          totalFaculty: actualCounts.totalFaculty,
          createdAt: resolvedDept.createdAt,
          updatedAt: DateTime.now(),
        );
      }

      // 5. Construct DepartmentModel from the user's department information with real counts (0 if none)
      if (candidateDeptName != null && candidateDeptName.isNotEmpty) {
        final dynamicDept = DepartmentModel(
          departmentId: targetDeptId,
          name: candidateDeptName,
          code: targetDeptCode,
          hodId: cleanId,
          hodName: candidateHodName ?? 'Head of Department',
          totalStudents: actualCounts.totalStudents,
          totalFaculty: actualCounts.totalFaculty,
        );

        // Save into departments collection asynchronously for persistence
        try {
          await firestore.collection('departments').doc(targetDeptId).set(
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
        totalStudents: 0,
        totalFaculty: 0,
      );
    }

    return defaultDepartment;
  }

  /// Compute genuine count of registered students and staff belonging strictly to this department
  Future<({int totalStudents, int totalFaculty})> fetchActualDepartmentCounts({
    required String departmentId,
    required String departmentName,
    required String departmentCode,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return (totalStudents: 0, totalFaculty: 0);

    try {
      final Set<String> studentIdentifiers = {};
      final Set<String> staffIdentifiers = {};

      // 1. Scan students collection
      try {
        final studentSnap = await firestore.collection('students').get();
        for (final doc in studentSnap.docs) {
          final data = doc.data();
          if (_matchesDepartmentRecord(data, departmentId, departmentName, departmentCode)) {
            final id = (data['register_number'] ?? data['registerNumber'] ?? data['user_id'] ?? data['userId'] ?? doc.id).toString().trim();
            if (id.isNotEmpty) studentIdentifiers.add(id);
          }
        }
      } catch (e) {
        debugPrint('fetchActualDepartmentCounts students error: $e');
      }

      // 2. Scan staff collection
      try {
        final staffSnap = await firestore.collection('staff').get();
        for (final doc in staffSnap.docs) {
          final data = doc.data();
          if (_matchesDepartmentRecord(data, departmentId, departmentName, departmentCode)) {
            final id = (data['employee_id'] ?? data['employeeId'] ?? data['staff_id'] ?? data['staffId'] ?? data['user_id'] ?? data['userId'] ?? doc.id).toString().trim();
            if (id.isNotEmpty) staffIdentifiers.add(id);
          }
        }
      } catch (e) {
        debugPrint('fetchActualDepartmentCounts staff error: $e');
      }

      // 3. Scan users collection as well to catch any newly registered users
      try {
        final userSnap = await firestore.collection('users').get();
        for (final doc in userSnap.docs) {
          final data = doc.data();
          final role = (data['role'] ?? data['userRole'] ?? '').toString().toLowerCase();
          if (_matchesDepartmentRecord(data, departmentId, departmentName, departmentCode)) {
            if (role == 'student') {
              studentIdentifiers.add(doc.id);
            } else if (role == 'staff' || role == 'faculty' || role == 'advisor') {
              staffIdentifiers.add(doc.id);
            }
          }
        }
      } catch (e) {
        debugPrint('fetchActualDepartmentCounts users error: $e');
      }

      return (
        totalStudents: studentIdentifiers.length,
        totalFaculty: staffIdentifiers.length,
      );
    } catch (e) {
      debugPrint('fetchActualDepartmentCounts error: $e');
      return (totalStudents: 0, totalFaculty: 0);
    }
  }

  /// Sync and persist genuine department member counts directly to Firestore
  Future<void> syncDepartmentCounts(String departmentId) async {
    final firestore = _firestore;
    final cleanDept = departmentId.trim();
    if (cleanDept.isEmpty || firestore == null) return;

    try {
      final deptDoc = await firestore.collection('departments').doc(cleanDept).get();
      if (!deptDoc.exists || deptDoc.data() == null) return;

      final data = deptDoc.data()!;
      final deptName = (data['name'] ?? data['department_name'] ?? data['departmentName'] ?? '').toString();
      final deptCode = (data['code'] ?? data['department_code'] ?? data['departmentCode'] ?? '').toString();

      final actualCounts = await fetchActualDepartmentCounts(
        departmentId: cleanDept,
        departmentName: deptName,
        departmentCode: deptCode,
      );

      await firestore.collection('departments').doc(cleanDept).set({
        'totalStudents': actualCounts.totalStudents,
        'total_students': actualCounts.totalStudents,
        'totalFaculty': actualCounts.totalFaculty,
        'total_faculty': actualCounts.totalFaculty,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('DepartmentRepository syncDepartmentCounts error: $e');
    }
  }

  static bool _matchesDepartmentRecord(
    Map<String, dynamic> data,
    String targetDeptId,
    String targetDeptName,
    String targetDeptCode,
  ) {
    final meta = data['metadata'] is Map ? data['metadata'] as Map<String, dynamic> : null;
    final deptId = (data['departmentId'] ?? data['department_id'] ?? meta?['departmentId'] ?? meta?['department_id'] ?? '').toString().trim().toLowerCase();
    final deptName = (data['departmentName'] ?? data['department_name'] ?? data['department'] ?? meta?['department'] ?? meta?['departmentName'] ?? '').toString().trim().toLowerCase();
    final deptCode = (data['departmentCode'] ?? data['department_code'] ?? data['code'] ?? '').toString().trim().toLowerCase();

    final cleanTargetId = targetDeptId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanTargetName = targetDeptName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanTargetCode = targetDeptCode.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final cleanId = deptId.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanName = deptName.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanCode = deptCode.replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (cleanTargetCode.isNotEmpty && (cleanCode == cleanTargetCode || cleanId.contains(cleanTargetCode) || cleanName.contains(cleanTargetCode))) {
      return true;
    }
    if (cleanTargetId.isNotEmpty && (cleanId == cleanTargetId || cleanId.contains(cleanTargetId) || cleanTargetId.contains(cleanId))) {
      return true;
    }
    if (cleanTargetName.isNotEmpty && (cleanName == cleanTargetName || cleanName.contains(cleanTargetName) || cleanTargetName.contains(cleanName))) {
      return true;
    }

    if (cleanTargetName.contains('artificial') || cleanTargetCode == 'aids') {
      if (cleanName.contains('artificial') || cleanName.contains('aids') || cleanCode == 'aids' || cleanId.contains('aids')) {
        return true;
      }
    }
    if (cleanTargetName.contains('computerscience') || cleanTargetCode == 'cse') {
      if (cleanName.contains('computerscience') || cleanName.contains('cse') || cleanCode == 'cse' || cleanId.contains('cse')) {
        return true;
      }
    }

    return false;
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

  /// Canonicalize department name against AppDepartments.list if closely matched
  static String canonicalizeDepartmentName(String deptName) {
    final clean = deptName.trim().toLowerCase();
    for (final standard in AppDepartments.list) {
      if (standard.toLowerCase() == clean) return standard;
    }
    final code = deriveDepartmentCode(deptName);
    for (final standard in AppDepartments.list) {
      if (deriveDepartmentCode(standard) == code) return standard;
    }
    return deptName.trim();
  }

  /// Normalize department key for deduplication
  static String normalizeDepartmentKey(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Retrieve all departments that have an active Head of Department (HOD) created
  Future<List<DepartmentModel>> getDepartmentsWithActiveHod() async {
    final firestore = _firestore;
    if (firestore == null) return [];

    final Map<String, DepartmentModel> activeMap = {};

    try {
      // 1. Fetch departments from 'departments' collection with non-empty hodId/hod_id
      final deptSnap = await firestore.collection('departments').get();
      for (final doc in deptSnap.docs) {
        final data = doc.data();
        final rawHodId = (data['hodId'] ?? data['hod_id'])?.toString().trim();
        final rawHodName = (data['hodName'] ?? data['hod_name'])?.toString().trim();
        final rawName = (data['name'] ?? data['departmentName'] ?? data['department_name'])?.toString().trim();

        if (rawHodId != null && rawHodId.isNotEmpty && rawName != null && rawName.isNotEmpty) {
          final canonicalName = canonicalizeDepartmentName(rawName);
          final key = normalizeDepartmentKey(canonicalName);
          final code = (data['code'] ?? data['departmentCode'] ?? deriveDepartmentCode(canonicalName)).toString().trim();
          activeMap[key] = DepartmentModel(
            departmentId: doc.id,
            name: canonicalName,
            code: code,
            hodId: rawHodId,
            hodName: (rawHodName != null && rawHodName.isNotEmpty) ? rawHodName : 'Head of Department',
            totalStudents: int.tryParse(data['totalStudents']?.toString() ?? data['total_students']?.toString() ?? '') ?? 0,
            totalFaculty: int.tryParse(data['totalFaculty']?.toString() ?? data['total_faculty']?.toString() ?? '') ?? 0,
          );
        }
      }

      // 2. Fetch HOD users from 'users' collection to catch any HOD created in users
      final userSnap = await firestore.collection('users').get();
      for (final doc in userSnap.docs) {
        final data = doc.data();
        final role = (data['role'] ?? data['userRole'] ?? data['metadata']?['role'] ?? '').toString().trim().toLowerCase();
        if (role == 'hod' || role == 'userrole.hod' || role == 'department (hod)') {
          final rawDept = (data['department'] ?? data['departmentName'] ?? data['metadata']?['department'] ?? data['metadata']?['departmentName'])?.toString().trim();
          if (rawDept != null && rawDept.isNotEmpty) {
            final canonicalName = canonicalizeDepartmentName(rawDept);
            final key = normalizeDepartmentKey(canonicalName);
            if (!activeMap.containsKey(key)) {
              final hodName = (data['fullName'] ?? data['name'] ?? data['metadata']?['fullName'] ?? 'Head of Department').toString().trim();
              final code = deriveDepartmentCode(canonicalName);
              final deptId = deriveDepartmentId(canonicalName);
              activeMap[key] = DepartmentModel(
                departmentId: deptId,
                name: canonicalName,
                code: code,
                hodId: doc.id,
                hodName: hodName.isNotEmpty ? hodName : 'Head of Department',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DepartmentRepository getDepartmentsWithActiveHod error: $e');
    }

    final result = activeMap.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Real-time stream of departments with an active HOD
  Stream<List<DepartmentModel>> watchDepartmentsWithActiveHod() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);

    return firestore.collection('departments').snapshots().asyncMap((_) async {
      return await getDepartmentsWithActiveHod();
    }).handleError((e) {
      debugPrint('DepartmentRepository watchDepartmentsWithActiveHod error: $e');
      return <DepartmentModel>[];
    });
  }

  /// Check if a department currently has an active HOD
  Future<bool> hasActiveHod(String deptName) async {
    final clean = deptName.trim();
    if (clean.isEmpty) return false;
    final activeDepts = await getDepartmentsWithActiveHod();
    final cleanKey = normalizeDepartmentKey(clean);
    final cleanCode = deriveDepartmentCode(clean);

    return activeDepts.any((d) =>
      normalizeDepartmentKey(d.name) == cleanKey ||
      normalizeDepartmentKey(d.code) == cleanKey ||
      d.code.toUpperCase() == cleanCode.toUpperCase()
    );
  }
}
