import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/parent_model.dart';
import 'package:unisphere/models/parent_portal_types.dart';

final parentServiceProvider = Provider<ParentService>((ref) {
  return ParentService();
});

/// Riverpod StateProvider for the currently active student ward selected by the parent
final activeParentWardProvider = StateProvider<ParentStudentWard?>((ref) => null);

/// Riverpod StateProvider for all mapped student wards of current parent
final parentWardsListProvider = StateProvider<List<ParentStudentWard>>((ref) => []);

/// Riverpod StreamProvider for real-time live database updates for the active student ward
final activeWardLiveStreamProvider = StreamProvider.family<ParentStudentWard?, String>((ref, regNo) {
  final service = ref.watch(parentServiceProvider);
  return service.watchStudentWard(regNo);
});

class ParentService {
  final FirebaseFirestore? _firestore;
  static final Map<String, String> _cachedActiveWardRegNo = {};

  ParentService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Get parent profile by parentId or student UID reference
  Future<ParentModel?> getParentById(String parentId) async {
    final firestore = _firestore;
    if (parentId.isEmpty || firestore == null) return null;
    try {
      final doc = await firestore.collection('parents').doc(parentId).get();
      if (doc.exists && doc.data() != null) {
        return ParentModel.fromMap(doc.data()!, doc.id);
      }

      // Fallback lookup by studentId array
      final snap = await firestore.collection('parents').where('studentIds', arrayContains: parentId).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return ParentModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
      }
    } catch (e) {
      debugPrint('ParentService getParentById error: $e');
    }
    return null;
  }

  /// Save or update parent profile under parents/{parentId}
  Future<void> saveParent(ParentModel parent) async {
    final firestore = _firestore;
    if (firestore == null || parent.parentId.isEmpty) return;
    try {
      final data = parent.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await firestore.collection('parents').doc(parent.parentId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ParentService saveParent error: $e');
    }
  }

  /// Saves the active student ward preference in the database (Firestore) and local cache
  Future<void> saveActiveWardPreference({
    required String parentUidOrEmail,
    required String wardRegNo,
  }) async {
    final cleanParent = parentUidOrEmail.trim();
    final cleanReg = wardRegNo.trim().toUpperCase();
    if (cleanParent.isEmpty || cleanReg.isEmpty) return;

    _cachedActiveWardRegNo[cleanParent] = cleanReg;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('parents').doc(cleanParent).set({
          'activeWardRegNo': cleanReg,
          'selectedActiveWard': cleanReg,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await firestore.collection('users').doc(cleanParent).set({
          'metadata': {
            'activeWardRegNo': cleanReg,
            'selectedActiveWard': cleanReg,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('ParentService saveActiveWardPreference error: $e');
      }
    }
  }

  /// Gets the stored active student ward preference from cache or Firestore
  Future<String?> getActiveWardPreference(String parentUidOrEmail) async {
    final clean = parentUidOrEmail.trim();
    if (clean.isEmpty) return null;

    if (_cachedActiveWardRegNo.containsKey(clean)) {
      return _cachedActiveWardRegNo[clean];
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final doc = await firestore.collection('parents').doc(clean).get();
        if (doc.exists && doc.data() != null) {
          final reg = doc.data()!['activeWardRegNo'] ?? doc.data()!['selectedActiveWard'];
          if (reg != null && reg.toString().isNotEmpty) {
            _cachedActiveWardRegNo[clean] = reg.toString().toUpperCase();
            return _cachedActiveWardRegNo[clean];
          }
        }
      } catch (e) {
        debugPrint('ParentService getActiveWardPreference error: $e');
      }
    }

    return null;
  }

  /// Links a parent with multiple student wards (children) in Firestore
  Future<void> linkParentWithChildren({
    required String parentId,
    required String userId,
    required String parentName,
    required String phone,
    String? email,
    required List<String> childRegisterNumbers,
  }) async {
    final firestore = _firestore;
    final cleanRegs = childRegisterNumbers
        .map((r) => r.trim().toUpperCase())
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();

    // Set first child as default active ward if available
    if (cleanRegs.isNotEmpty) {
      _cachedActiveWardRegNo[parentId] = cleanRegs.first;
      if (email != null && email.isNotEmpty) {
        _cachedActiveWardRegNo[email] = cleanRegs.first;
      }
    }

    // 1. Build ParentModel & Save in parents collection
    final parent = ParentModel(
      parentId: parentId,
      userId: userId,
      fullName: parentName,
      phone: phone,
      email: email,
      studentIds: cleanRegs,
      wardRegisterNumbers: cleanRegs,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveParent(parent);

    if (firestore == null) return;

    try {
      // 2. Also update parent document under users collection
      await firestore.collection('users').doc(userId).set({
        'role': 'parent',
        'fullName': parentName,
        'phone': phone,
        'email': email,
        'metadata': {
          'fullName': parentName,
          'phone': phone,
          'wardRegisterNumbers': cleanRegs,
          'studentIds': cleanRegs,
          'activeWardRegNo': cleanRegs.isNotEmpty ? cleanRegs.first : null,
          'profileCompletionStatus': 'complete',
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Link each student record with parent details
      for (final regNo in cleanRegs) {
        try {
          final studentData = {
            'parentId': parentId,
            'parentUserId': userId,
            'parentName': parentName,
            'parentPhone': phone,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await firestore.collection('students').doc(regNo).set(studentData, SetOptions(merge: true));

          final q = await firestore.collection('students').where('registerNumber', isEqualTo: regNo).limit(1).get();
          if (q.docs.isNotEmpty) {
            await q.docs.first.reference.set(studentData, SetOptions(merge: true));
          }
        } catch (stErr) {
          debugPrint('Error linking student $regNo with parent: $stErr');
        }
      }
    } catch (e) {
      debugPrint('ParentService linkParentWithChildren error: $e');
    }
  }

  /// Links an additional student ward to an existing parent in Firestore
  Future<bool> linkAdditionalChild({
    required String parentUidOrEmail,
    required String childRegisterNumber,
    String? parentName,
    String? phone,
  }) async {
    final cleanParent = parentUidOrEmail.trim();
    final cleanReg = childRegisterNumber.trim().toUpperCase();
    if (cleanParent.isEmpty || cleanReg.isEmpty) return false;

    final studentData = await lookupStudentByRegNo(cleanReg);
    if (studentData == null) return false;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('parents').doc(cleanParent).set({
          'studentIds': FieldValue.arrayUnion([cleanReg]),
          'wardRegisterNumbers': FieldValue.arrayUnion([cleanReg]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await firestore.collection('users').doc(cleanParent).set({
          'metadata': {
            'studentIds': FieldValue.arrayUnion([cleanReg]),
            'wardRegisterNumbers': FieldValue.arrayUnion([cleanReg]),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await firestore.collection('students').doc(cleanReg).set({
          'parentId': cleanParent,
          if (parentName != null) 'parentName': parentName,
          if (phone != null) 'parentPhone': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('ParentService linkAdditionalChild error: $e');
      }
    }

    return true;
  }

  /// Quick lookup for a student by Register Number / Roll No / ID
  Future<Map<String, dynamic>?> lookupStudentByRegNo(String regNo) async {
    final clean = regNo.trim();
    if (clean.isEmpty) return null;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final doc = await firestore.collection('students').doc(clean).get();
        if (doc.exists && doc.data() != null) {
          return doc.data();
        }
        final docUpper = await firestore.collection('students').doc(clean.toUpperCase()).get();
        if (docUpper.exists && docUpper.data() != null) {
          return docUpper.data();
        }

        final q = await firestore.collection('students').where('registerNumber', isEqualTo: clean).limit(1).get();
        if (q.docs.isNotEmpty) {
          return q.docs.first.data();
        }
        final qUpper = await firestore.collection('students').where('registerNumber', isEqualTo: clean.toUpperCase()).limit(1).get();
        if (qUpper.docs.isNotEmpty) {
          return qUpper.docs.first.data();
        }
      } catch (e) {
        debugPrint('ParentService lookupStudentByRegNo Firestore query notice: $e');
      }
    }

    // Local known demo student fallback with full rich academic & attendance records
    final demoMap = {
      '23CSE1042': {
        'fullName': 'Arun Kumar',
        'name': 'Arun Kumar',
        'departmentName': 'Computer Science & Engineering',
        'department': 'Computer Science & Engineering',
        'semester': 'VI Semester',
        'yearSection': 'CSE • III Year • VI Semester',
        'currentYear': 'III Year',
        'currentSemester': 'VI Semester',
        'avatarInitials': 'AK',
        'photoUrl': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
        'attendancePercent': '87.0',
        'presentCount': 142,
        'absentCount': 15,
        'leaveOdCount': 6,
        'cgpa': '8.2',
        'academicTrend': '+0.3 from Sem V',
        'academicStatus': 'Good Standing',
        'statusColor': const Color(0xFF10B981),
        'totalFees': 50000.0,
        'paidFees': 37500.0,
        'pendingFees': 12500.0,
        'subjectGrades': [
          {'code': 'CS601', 'name': 'Core Algorithms & Data Structures', 'attended': 32, 'total': 35, 'percent': 0.914, 'status': 'SAFE', 'buffer': '+6 classes buffer', 'marks': '94/100', 'grade': 'O (Outstanding)', 'progress': '0.94'},
          {'code': 'CS602', 'name': 'Database Management (DBMS)', 'attended': 28, 'total': 32, 'percent': 0.875, 'status': 'SAFE', 'buffer': '+4 classes buffer', 'marks': '88/100', 'grade': 'A+ (Excellent)', 'progress': '0.88'},
          {'code': 'CS603', 'name': 'Operating Systems & Architecture', 'attended': 28, 'total': 33, 'percent': 0.848, 'status': 'SAFE', 'buffer': '+3 classes buffer', 'marks': '85/100', 'grade': 'A (Very Good)', 'progress': '0.85'},
          {'code': 'CS604', 'name': 'Computer Networks & Security', 'attended': 27, 'total': 30, 'percent': 0.900, 'status': 'SAFE', 'buffer': '+4 classes buffer', 'marks': '90/100', 'grade': 'O (Outstanding)', 'progress': '0.90'},
        ],
      },
      '24ECE2018': {
        'fullName': 'Kavya Kumar',
        'name': 'Kavya Kumar',
        'departmentName': 'Electronics & Comm. Engineering',
        'department': 'Electronics & Comm. Engineering',
        'semester': 'IV Semester',
        'yearSection': 'ECE • II Year • IV Semester',
        'currentYear': 'II Year',
        'currentSemester': 'IV Semester',
        'avatarInitials': 'KK',
        'photoUrl': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
        'attendancePercent': '94.0',
        'presentCount': 156,
        'absentCount': 8,
        'leaveOdCount': 2,
        'cgpa': '9.1',
        'academicTrend': '+0.2 from Sem III',
        'academicStatus': 'Dean\'s Scholar',
        'statusColor': const Color(0xFF7C3AED),
        'totalFees': 48000.0,
        'paidFees': 48000.0,
        'pendingFees': 0.0,
        'subjectGrades': [
          {'code': 'EC401', 'name': 'Signals & Systems Analysis', 'attended': 34, 'total': 35, 'percent': 0.971, 'status': 'EXCELLENT', 'buffer': '+7 classes buffer', 'marks': '96/100', 'grade': 'O (Outstanding)', 'progress': '0.96'},
          {'code': 'EC402', 'name': 'Analog Circuits & Semiconductor Devices', 'attended': 30, 'total': 32, 'percent': 0.938, 'status': 'EXCELLENT', 'buffer': '+6 classes buffer', 'marks': '91/100', 'grade': 'O (Outstanding)', 'progress': '0.91'},
          {'code': 'EC403', 'name': 'Electromagnetic Fields & Waves', 'attended': 29, 'total': 31, 'percent': 0.935, 'status': 'EXCELLENT', 'buffer': '+5 classes buffer', 'marks': '89/100', 'grade': 'A+ (Excellent)', 'progress': '0.89'},
          {'code': 'MA401', 'name': 'Probability & Random Processes', 'attended': 28, 'total': 30, 'percent': 0.933, 'status': 'EXCELLENT', 'buffer': '+5 classes buffer', 'marks': '93/100', 'grade': 'O (Outstanding)', 'progress': '0.93'},
        ],
      },
      'RA2111003010001': {'fullName': 'Alex Johnson', 'name': 'Alex Johnson', 'departmentName': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'semester': 'VI Semester'},
      '917721104012': {'fullName': 'Aravind Swamy', 'name': 'Aravind Swamy', 'departmentName': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'semester': 'VI Semester'},
      '917721104045': {'fullName': 'Priya Dharshini', 'name': 'Priya Dharshini', 'departmentName': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'semester': 'VI Semester'},
    };

    if (demoMap.containsKey(clean.toUpperCase())) {
      return demoMap[clean.toUpperCase()];
    }
    if (demoMap.containsKey(clean)) {
      return demoMap[clean];
    }

    return null;
  }

  /// Get student wards for a given parent user from Firestore
  Future<List<ParentStudentWard>> getStudentWardsForParent(String parentUidOrEmail) async {
    final clean = parentUidOrEmail.trim();
    if (clean.isEmpty) return getDefaultStudentWards();

    final firestore = _firestore;
    List<String> wardRegNos = [];
    String? activePreference;

    if (firestore != null) {
      try {
        // 1. Check parent doc
        final pDoc = await firestore.collection('parents').doc(clean).get();
        if (pDoc.exists && pDoc.data() != null) {
          final data = pDoc.data()!;
          wardRegNos = List<String>.from(data['wardRegisterNumbers'] ?? data['studentIds'] ?? []);
          activePreference = data['activeWardRegNo'] ?? data['selectedActiveWard'];
        }

        // 2. Fallback check user doc
        if (wardRegNos.isEmpty) {
          final uDoc = await firestore.collection('users').doc(clean).get();
          if (uDoc.exists && uDoc.data() != null) {
            final meta = uDoc.data()!['metadata'] as Map<String, dynamic>? ?? {};
            wardRegNos = List<String>.from(meta['wardRegisterNumbers'] ?? meta['studentIds'] ?? []);
            activePreference ??= meta['activeWardRegNo'] ?? meta['selectedActiveWard'];
          }
        }

        // 3. Fallback query by email if clean is email
        if (wardRegNos.isEmpty && clean.contains('@')) {
          final q = await firestore.collection('parents').where('email', isEqualTo: clean).limit(1).get();
          if (q.docs.isNotEmpty) {
            final data = q.docs.first.data();
            wardRegNos = List<String>.from(data['wardRegisterNumbers'] ?? data['studentIds'] ?? []);
            activePreference ??= data['activeWardRegNo'] ?? data['selectedActiveWard'];
          }
        }
      } catch (e) {
        debugPrint('Error retrieving parent wards: $e');
      }
    }

    if (activePreference != null && activePreference.isNotEmpty) {
      _cachedActiveWardRegNo[clean] = activePreference.toUpperCase();
    }

    if (wardRegNos.isEmpty) {
      return getDefaultStudentWards();
    }

    // Resolve each registered ward
    final List<ParentStudentWard> resolvedWards = [];
    for (int i = 0; i < wardRegNos.length; i++) {
      final regNo = wardRegNos[i];
      final studentData = await lookupStudentByRegNo(regNo);

      final name = studentData?['fullName'] ?? studentData?['name'] ?? 'Student $regNo';
      final dept = studentData?['departmentName'] ?? studentData?['department'] ?? 'Computer Science & Engineering';
      final sem = studentData?['semester'] ?? (i == 0 ? 'VI Semester' : 'IV Semester');
      final yearSec = studentData?['yearSection'] ?? (dept.contains('Computer') ? 'CSE • III Year • $sem' : 'ECE • II Year • $sem');
      final curYear = studentData?['currentYear'] ?? (sem.contains('VI') ? 'III Year' : (sem.contains('IV') ? 'II Year' : 'I Year'));
      final cgpa = studentData?['cgpa']?.toString() ?? (i == 0 ? '8.2' : '9.1');
      final rawAtt = studentData?['attendancePercent']?.toString() ?? (i == 0 ? '87.0' : '94.0');
      final double attVal = (double.tryParse(rawAtt.replaceAll('%', '')) ?? 88.0) / (double.tryParse(rawAtt.replaceAll('%', '')) != null && double.parse(rawAtt.replaceAll('%', '')) > 1 ? 100.0 : 1.0);

      final initials = studentData?['avatarInitials'] ?? name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();

      resolvedWards.add(
        ParentStudentWard(
          id: 'ward_${regNo.toLowerCase()}',
          name: name,
          regNo: regNo,
          department: dept,
          yearSection: yearSec,
          currentYear: curYear,
          currentSemester: sem,
          photoUrl: studentData?['photoUrl'] ?? (i == 0 ? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200' : 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200'),
          avatarInitials: initials.isNotEmpty ? initials : 'AK',
          attendancePercent: attVal.clamp(0.0, 1.0),
          presentCount: studentData?['presentCount'] ?? (i == 0 ? 142 : 156),
          absentCount: studentData?['absentCount'] ?? (i == 0 ? 15 : 8),
          leaveOdCount: studentData?['leaveOdCount'] ?? (i == 0 ? 6 : 2),
          cgpa: cgpa,
          academicTrend: studentData?['academicTrend'] ?? (i == 0 ? '+0.3 from Sem V' : '+0.2 from Sem III'),
          academicStatus: studentData?['academicStatus'] ?? (i == 0 ? 'Good Standing' : 'Dean\'s Scholar'),
          statusColor: (studentData?['statusColor'] as Color?) ?? (i == 0 ? const Color(0xFF10B981) : const Color(0xFF7C3AED)),
          totalFees: (studentData?['totalFees'] as num?)?.toDouble() ?? 50000.0,
          paidFees: (studentData?['paidFees'] as num?)?.toDouble() ?? (i == 0 ? 37500.0 : 48000.0),
          pendingFees: (studentData?['pendingFees'] as num?)?.toDouble() ?? (i == 0 ? 12500.0 : 0.0),
          feeDueDate: DateTime(2026, 9, 15),
          feeStatus: i == 0 ? 'Payment Pending' : 'All Fees Cleared',
          isFeeOverdue: false,
          subjectGrades: (studentData?['subjectGrades'] as List?)?.map((sg) {
            if (sg is ParentSubjectGrade) return sg;
            final m = Map<String, dynamic>.from(sg);
            return ParentSubjectGrade(
              subjectCode: m['code'] ?? m['subjectCode'] ?? 'CS601',
              subjectName: m['name'] ?? m['subjectName'] ?? 'Course Subject',
              grade: m['grade'] ?? 'A+',
              color: (m['percent'] != null && (m['percent'] as num) >= 0.9) ? const Color(0xFF059669) : const Color(0xFF2563EB),
            );
          }).toList() ?? (i == 0
              ? [
                  ParentSubjectGrade(subjectCode: 'CS601', subjectName: 'Core Algorithms & Data Structures', grade: 'O', color: const Color(0xFF059669)),
                  ParentSubjectGrade(subjectCode: 'CS602', subjectName: 'Database Management Systems', grade: 'A+', color: const Color(0xFF2563EB)),
                  ParentSubjectGrade(subjectCode: 'CS603', subjectName: 'Operating Systems & Architecture', grade: 'A', color: const Color(0xFFD97706)),
                  ParentSubjectGrade(subjectCode: 'CS604', subjectName: 'Computer Networks & Security', grade: 'O', color: const Color(0xFF7C3AED)),
                ]
              : [
                  ParentSubjectGrade(subjectCode: 'EC401', subjectName: 'Signals & Systems Analysis', grade: 'O', color: const Color(0xFF059669)),
                  ParentSubjectGrade(subjectCode: 'EC402', subjectName: 'Analog Circuits & Devices', grade: 'O', color: const Color(0xFF2563EB)),
                  ParentSubjectGrade(subjectCode: 'EC403', subjectName: 'Electromagnetic Fields & Waves', grade: 'A+', color: const Color(0xFF7C3AED)),
                  ParentSubjectGrade(subjectCode: 'MA401', subjectName: 'Probability & Random Processes', grade: 'O', color: const Color(0xFF059669)),
                ]),
        ),
      );
    }

    return resolvedWards.isNotEmpty ? resolvedWards : getDefaultStudentWards();
  }

  /// Returns default mapped student wards for parent dashboard (Arun Kumar & Kavya Kumar)
  List<ParentStudentWard> getDefaultStudentWards() {
    return [
      ParentStudentWard(
        id: 'ward_23cse1042',
        name: 'Arun Kumar',
        regNo: '23CSE1042',
        department: 'Computer Science & Engineering',
        yearSection: 'CSE • III Year • VI Semester',
        currentYear: 'III Year',
        currentSemester: 'VI Semester',
        photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
        avatarInitials: 'AK',
        attendancePercent: 0.87,
        presentCount: 142,
        absentCount: 15,
        leaveOdCount: 6,
        cgpa: '8.2',
        academicTrend: '+0.3 from Sem V',
        academicStatus: 'Good Standing',
        statusColor: const Color(0xFF10B981),
        totalFees: 50000,
        paidFees: 37500,
        pendingFees: 12500,
        feeDueDate: DateTime(2026, 9, 15),
        feeStatus: 'Payment Pending',
        isFeeOverdue: false,
        subjectGrades: [
          ParentSubjectGrade(subjectCode: 'CS601', subjectName: 'Core Algorithms & Data Structures', grade: 'O', color: const Color(0xFF059669)),
          ParentSubjectGrade(subjectCode: 'CS602', subjectName: 'Database Management Systems (DBMS)', grade: 'A+', color: const Color(0xFF2563EB)),
          ParentSubjectGrade(subjectCode: 'CS603', subjectName: 'Operating Systems & Architecture', grade: 'A', color: const Color(0xFFD97706)),
          ParentSubjectGrade(subjectCode: 'CS604', subjectName: 'Computer Networks & Security', grade: 'O', color: const Color(0xFF7C3AED)),
        ],
      ),
      ParentStudentWard(
        id: 'ward_24ece2018',
        name: 'Kavya Kumar',
        regNo: '24ECE2018',
        department: 'Electronics & Comm. Engineering',
        yearSection: 'ECE • II Year • IV Semester',
        currentYear: 'II Year',
        currentSemester: 'IV Semester',
        photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
        avatarInitials: 'KK',
        attendancePercent: 0.94,
        presentCount: 156,
        absentCount: 8,
        leaveOdCount: 2,
        cgpa: '9.1',
        academicTrend: '+0.2 from Sem III',
        academicStatus: 'Dean\'s Scholar',
        statusColor: const Color(0xFF7C3AED),
        totalFees: 48000,
        paidFees: 48000,
        pendingFees: 0,
        feeDueDate: DateTime(2026, 11, 30),
        feeStatus: 'All Fees Cleared',
        todayStatus: 'Present',
        subjectGrades: [
          ParentSubjectGrade(subjectCode: 'EC401', subjectName: 'Signals & Systems Analysis', grade: 'O', color: const Color(0xFF059669)),
          ParentSubjectGrade(subjectCode: 'EC402', subjectName: 'Analog Circuits & Devices', grade: 'O', color: const Color(0xFF2563EB)),
          ParentSubjectGrade(subjectCode: 'EC403', subjectName: 'Electromagnetic Fields & Waves', grade: 'A+', color: const Color(0xFF7C3AED)),
          ParentSubjectGrade(subjectCode: 'MA401', subjectName: 'Probability & Random Processes', grade: 'O', color: const Color(0xFF059669)),
        ],
      ),
    ];
  }

  /// Stream real-time data for a specific student ward directly from Firestore
  Stream<ParentStudentWard?> watchStudentWard(String regNo) {
    final clean = regNo.trim();
    if (clean.isEmpty) return Stream.value(null);

    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(null);
    }

    final docRef = firestore.collection('students').doc(clean.toUpperCase());
    return docRef.snapshots().asyncMap((docSnap) async {
      Map<String, dynamic>? studentData;
      if (docSnap.exists && docSnap.data() != null) {
        studentData = docSnap.data();
      } else {
        final querySnap = await firestore.collection('students').where('registerNumber', isEqualTo: clean.toUpperCase()).limit(1).get();
        if (querySnap.docs.isNotEmpty) {
          studentData = querySnap.docs.first.data();
        }
      }

      // Merge with demo lookup fallback if fields are missing
      final fallbackData = await lookupStudentByRegNo(clean);
      final mergedData = <String, dynamic>{
        if (fallbackData != null) ...fallbackData,
        if (studentData != null) ...studentData,
      };

      if (mergedData.isEmpty) return null;

      final name = mergedData['fullName'] ?? mergedData['name'] ?? 'Student $clean';
      final dept = mergedData['departmentName'] ?? mergedData['department'] ?? 'Computer Science & Engineering';
      final sem = mergedData['semester'] ?? 'VI Semester';
      final yearSec = mergedData['yearSection'] ?? (dept.contains('Computer') ? 'CSE • III Year • $sem' : 'ECE • II Year • $sem');
      final curYear = mergedData['currentYear'] ?? (sem.contains('VI') ? 'III Year' : (sem.contains('IV') ? 'II Year' : 'I Year'));
      final cgpa = mergedData['cgpa']?.toString() ?? '8.5';
      final rawAtt = mergedData['attendancePercent']?.toString() ?? '87.0';
      final double attVal = (double.tryParse(rawAtt.replaceAll('%', '')) ?? 87.0) /
          (double.tryParse(rawAtt.replaceAll('%', '')) != null && double.parse(rawAtt.replaceAll('%', '')) > 1 ? 100.0 : 1.0);

      // Check today's real attendance status from database
      String resolvedTodayStatus = mergedData['todayAttendanceStatus'] ?? mergedData['todayStatus'] ?? '';
      if (resolvedTodayStatus.isEmpty) {
        try {
          final attLogs = await firestore
              .collection('attendance')
              .where('student_uid', isEqualTo: clean.toUpperCase())
              .orderBy('date', descending: true)
              .limit(1)
              .get();
          if (attLogs.docs.isNotEmpty) {
            final st = attLogs.docs.first.data()['status']?.toString().toLowerCase() ?? 'present';
            if (st == 'absent') {
              resolvedTodayStatus = 'Absent';
            } else if (st == 'onduty' || st == 'leave' || st == 'on duty') {
              resolvedTodayStatus = 'On Leave';
            } else {
              resolvedTodayStatus = 'Present';
            }
          }
        } catch (_) {}
      }

      if (resolvedTodayStatus.isEmpty) {
        resolvedTodayStatus = attVal >= 0.70 ? 'Present' : 'Absent';
      }

      final initials = mergedData['avatarInitials'] ?? name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();

      return ParentStudentWard(
        id: 'ward_${clean.toLowerCase()}',
        name: name,
        regNo: clean.toUpperCase(),
        department: dept,
        yearSection: yearSec,
        currentYear: curYear,
        currentSemester: sem,
        photoUrl: mergedData['photoUrl'] ?? (clean.toUpperCase().contains('CSE') ? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200' : 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200'),
        avatarInitials: initials.isNotEmpty ? initials : 'AK',
        attendancePercent: attVal.clamp(0.0, 1.0),
        presentCount: (mergedData['presentCount'] as num?)?.toInt() ?? 142,
        absentCount: (mergedData['absentCount'] as num?)?.toInt() ?? 15,
        leaveOdCount: (mergedData['leaveOdCount'] as num?)?.toInt() ?? 6,
        cgpa: cgpa,
        academicTrend: mergedData['academicTrend'] ?? '+0.3 from Sem V',
        academicStatus: mergedData['academicStatus'] ?? 'Good Standing',
        statusColor: (mergedData['statusColor'] as Color?) ?? const Color(0xFF10B981),
        totalFees: (mergedData['totalFees'] as num?)?.toDouble() ?? 50000.0,
        paidFees: (mergedData['paidFees'] as num?)?.toDouble() ?? 37500.0,
        pendingFees: (mergedData['pendingFees'] as num?)?.toDouble() ?? 12500.0,
        feeDueDate: DateTime(2026, 9, 15),
        feeStatus: 'Payment Pending',
        isFeeOverdue: false,
        todayStatus: resolvedTodayStatus,
        subjectGrades: (mergedData['subjectGrades'] as List?)?.map((sg) {
          if (sg is ParentSubjectGrade) return sg;
          final m = Map<String, dynamic>.from(sg);
          return ParentSubjectGrade(
            subjectCode: m['code'] ?? m['subjectCode'] ?? 'CS601',
            subjectName: m['name'] ?? m['subjectName'] ?? 'Course Subject',
            grade: m['grade'] ?? 'A+',
            color: (m['percent'] != null && (m['percent'] as num) >= 0.9) ? const Color(0xFF059669) : const Color(0xFF2563EB),
          );
        }).toList() ?? [
          ParentSubjectGrade(subjectCode: 'CS601', subjectName: 'Core Algorithms & Data Structures', grade: 'O', color: const Color(0xFF059669)),
          ParentSubjectGrade(subjectCode: 'CS602', subjectName: 'Database Management Systems', grade: 'A+', color: const Color(0xFF2563EB)),
        ],
      );
    }).handleError((e) {
      debugPrint('Error streaming student ward $clean: $e');
      return null;
    });
  }

  /// Updates a student's daily attendance status, CGPA, and attendance percentage in the database
  Future<void> updateStudentAttendanceStatus({
    required String regNo,
    required String status, // 'Present', 'Absent', 'On Leave'
    String? cgpa,
    String? attendancePercent,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final updateData = <String, dynamic>{
        'todayAttendanceStatus': status,
        'todayStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (cgpa != null) updateData['cgpa'] = cgpa;
      if (attendancePercent != null) updateData['attendancePercent'] = attendancePercent;

      final cleanUpper = regNo.trim().toUpperCase();
      await firestore.collection('students').doc(cleanUpper).set(updateData, SetOptions(merge: true));
      await firestore.collection('students').doc(regNo.trim()).set(updateData, SetOptions(merge: true));

      // Also record in attendance collection
      await firestore.collection('attendance').doc('${cleanUpper}_${DateTime.now().toIso8601String().substring(0, 10)}').set({
        'student_uid': cleanUpper,
        'date': DateTime.now().toIso8601String(),
        'status': status.toLowerCase() == 'on leave' ? 'onDuty' : status.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating student status: $e');
    }
  }
}
