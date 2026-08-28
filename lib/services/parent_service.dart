import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/parent_model.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:unisphere/models/user_model.dart';

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
  static final Map<String, Map<String, dynamic>> _inMemoryStudentProfiles = {};

  void cacheStudentProfile(String regNo, Map<String, dynamic> profile) {
    final clean = regNo.trim();
    if (clean.isNotEmpty) {
      _inMemoryStudentProfiles[clean] = profile;
      _inMemoryStudentProfiles[clean.toUpperCase()] = profile;
    }
  }

  ParentService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  FirebaseFirestore? get firestore => _firestore;

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

  static final Map<String, List<String>> _inMemoryParentWards = {
    'DEMO-PRT': ['23CSE1042', '24ECE2018'],
    'parent@unisphere.edu': ['23CSE1042', '24ECE2018'],
  };

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

    // Cache in memory for immediate access across screens
    if (cleanRegs.isNotEmpty) {
      _inMemoryParentWards[parentId] = cleanRegs;
      _inMemoryParentWards[userId] = cleanRegs;
      if (email != null && email.isNotEmpty) {
        _inMemoryParentWards[email.toLowerCase().trim()] = cleanRegs;
      }
      _cachedActiveWardRegNo[parentId] = cleanRegs.first;
      if (email != null && email.isNotEmpty) {
        _cachedActiveWardRegNo[email.toLowerCase().trim()] = cleanRegs.first;
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
          'childRegisterNumbers': cleanRegs,
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

    // Load existing wards first to ensure we merge all previous siblings
    final existingWards = await getStudentWardsForParent(cleanParent);
    final Set<String> existingRegs = existingWards.map((w) => w.regNo.trim().toUpperCase()).toSet();
    existingRegs.add(cleanReg);

    final mergedList = existingRegs.toList();
    _inMemoryParentWards[cleanParent] = mergedList;
    _inMemoryParentWards[cleanParent.toLowerCase()] = mergedList;

    final studentData = await lookupStudentByRegNo(cleanReg);
    if (studentData == null) return false;

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('parents').doc(cleanParent).set({
          'wardRegisterNumbers': FieldValue.arrayUnion([cleanReg]),
          'studentIds': FieldValue.arrayUnion([cleanReg]),
          'activeWardRegNo': cleanReg,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await firestore.collection('users').doc(cleanParent).set({
          'metadata': {
            'wardRegisterNumbers': FieldValue.arrayUnion([cleanReg]),
            'studentIds': FieldValue.arrayUnion([cleanReg]),
            'activeWardRegNo': cleanReg,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (parentName != null && phone != null) {
          await firestore.collection('students').doc(cleanReg).set({
            'parentId': cleanParent,
            'parentName': parentName,
            'parentPhone': phone,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('ParentService linkAdditionalChild error: $e');
      }
    }

    return true;
  }

  Map<String, String> _inferBranchAndYearFromRegNo(String regNo) {
    final clean = regNo.trim();
    String dept = 'Computer Science & Engineering';
    String year = 'III Year';
    String sem = 'Semester 6';

    if (clean.length >= 6) {
      final yearStr = clean.substring(4, 6);
      if (yearStr == '21') {
        year = 'IV Year';
        sem = 'Semester 8';
      } else if (yearStr == '22') {
        year = 'IV Year';
        sem = 'Semester 7';
      } else if (yearStr == '23') {
        year = 'III Year';
        sem = 'Semester 6';
      } else if (yearStr == '24') {
        year = 'II Year';
        sem = 'Semester 4';
      } else if (yearStr == '25') {
        year = 'I Year';
        sem = 'Semester 2';
      }

      if (clean.length >= 9) {
        final deptCode = clean.substring(6, 9);
        if (deptCode == '104') {
          dept = 'Computer Science & Engineering';
        } else if (deptCode == '243') {
          dept = 'Artificial Intelligence & Data Science';
        } else if (deptCode == '106') {
          dept = 'Electronics & Comm. Engineering';
        } else if (deptCode == '105') {
          dept = 'Electrical & Electronics Engineering';
        } else if (deptCode == '205') {
          dept = 'Information Technology';
        } else if (deptCode == '114') {
          dept = 'Mechanical Engineering';
        } else if (deptCode == '103') {
          dept = 'Civil Engineering';
        } else if (deptCode == '244') {
          dept = 'Computer Science & Business Systems';
        }
      }
    }

    return {
      'department': dept,
      'year': year,
      'semester': sem,
    };
  }

  /// Quick lookup for a student by Register Number / Roll No / ID
  Future<Map<String, dynamic>?> lookupStudentByRegNo(String regNo) async {
    final clean = regNo.trim();
    if (clean.isEmpty) return null;

    if (_inMemoryStudentProfiles.containsKey(clean)) {
      final cached = _inMemoryStudentProfiles[clean]!;
      final cachedName = cached['fullName'] ?? cached['name'];
      if (cachedName != null && cachedName.toString().trim().isNotEmpty && !cachedName.toString().startsWith('Student ')) {
        return cached;
      }
    }
    if (_inMemoryStudentProfiles.containsKey(clean.toUpperCase())) {
      final cached = _inMemoryStudentProfiles[clean.toUpperCase()]!;
      final cachedName = cached['fullName'] ?? cached['name'];
      if (cachedName != null && cachedName.toString().trim().isNotEmpty && !cachedName.toString().startsWith('Student ')) {
        return cached;
      }
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        Map<String, dynamic>? studentRaw;

        // 1. Direct student collection doc lookup (e.g. students/922523243100)
        final doc = await firestore.collection('students').doc(clean).get();
        if (doc.exists && doc.data() != null) {
          studentRaw = doc.data();
        }
        if (studentRaw == null) {
          final docUpper = await firestore.collection('students').doc(clean.toUpperCase()).get();
          if (docUpper.exists && docUpper.data() != null) {
            studentRaw = docUpper.data();
          }
        }

        // 2. Query student collection by registerNumber / studentId / rollNumber / regNo / email / userId
        if (studentRaw == null) {
          final q1 = await firestore.collection('students').where('registerNumber', isEqualTo: clean).limit(1).get();
          final q2 = q1.docs.isEmpty ? await firestore.collection('students').where('registerNumber', isEqualTo: clean.toUpperCase()).limit(1).get() : q1;
          final q3 = q2.docs.isEmpty ? await firestore.collection('students').where('studentId', isEqualTo: clean).limit(1).get() : q2;
          final q4 = q3.docs.isEmpty ? await firestore.collection('students').where('studentId', isEqualTo: clean.toUpperCase()).limit(1).get() : q3;
          final q5 = q4.docs.isEmpty ? await firestore.collection('students').where('rollNumber', isEqualTo: clean).limit(1).get() : q4;
          final q6 = q5.docs.isEmpty ? await firestore.collection('students').where('rollNumber', isEqualTo: clean.toUpperCase()).limit(1).get() : q5;
          final q7 = q6.docs.isEmpty ? await firestore.collection('students').where('regNo', isEqualTo: clean).limit(1).get() : q6;
          final q8 = q7.docs.isEmpty ? await firestore.collection('students').where('regNo', isEqualTo: clean.toUpperCase()).limit(1).get() : q7;
          final q9 = q8.docs.isEmpty ? await firestore.collection('students').where('email', isEqualTo: clean.toLowerCase()).limit(1).get() : q8;
          final q10 = q9.docs.isEmpty ? await firestore.collection('students').where('userId', isEqualTo: clean).limit(1).get() : q9;

          if (q10.docs.isNotEmpty) {
            studentRaw = q10.docs.first.data();
          }
        }

        // 3. Query users collection for registered student accounts
        if (studentRaw == null) {
          final uq1 = await firestore.collection('users').where('metadata.registerNumber', isEqualTo: clean).limit(1).get();
          final uq2 = uq1.docs.isEmpty ? await firestore.collection('users').where('metadata.registerNumber', isEqualTo: clean.toUpperCase()).limit(1).get() : uq1;
          final uq3 = uq2.docs.isEmpty ? await firestore.collection('users').where('registerNumber', isEqualTo: clean).limit(1).get() : uq2;
          final uq4 = uq3.docs.isEmpty ? await firestore.collection('users').where('registerNumber', isEqualTo: clean.toUpperCase()).limit(1).get() : uq3;
          final uq5 = uq4.docs.isEmpty ? await firestore.collection('users').where('metadata.regNo', isEqualTo: clean).limit(1).get() : uq4;
          final uq6 = uq5.docs.isEmpty ? await firestore.collection('users').where('metadata.regNo', isEqualTo: clean.toUpperCase()).limit(1).get() : uq5;
          final uq7 = uq6.docs.isEmpty ? await firestore.collection('users').where('regNo', isEqualTo: clean).limit(1).get() : uq6;
          final uq8 = uq7.docs.isEmpty ? await firestore.collection('users').where('regNo', isEqualTo: clean.toUpperCase()).limit(1).get() : uq7;
          final uq9 = uq8.docs.isEmpty ? await firestore.collection('users').where('email', isEqualTo: clean.toLowerCase()).limit(1).get() : uq8;
          final uq10 = uq9.docs.isEmpty ? await firestore.collection('users').where('metadata.studentId', isEqualTo: clean).limit(1).get() : uq9;
          final uq11 = uq10.docs.isEmpty ? await firestore.collection('users').where('metadata.studentId', isEqualTo: clean.toUpperCase()).limit(1).get() : uq10;

          if (uq11.docs.isNotEmpty) {
            studentRaw = uq11.docs.first.data();
          }
        }

        // 4. Direct user doc lookup (e.g. users/{uid} or users/{regNo})
        if (studentRaw == null) {
          final uDoc = await firestore.collection('users').doc(clean).get();
          if (uDoc.exists && uDoc.data() != null) {
            studentRaw = uDoc.data();
          }
          if (studentRaw == null) {
            final uDocUpper = await firestore.collection('users').doc(clean.toUpperCase()).get();
            if (uDocUpper.exists && uDocUpper.data() != null) {
              studentRaw = uDocUpper.data();
            }
          }
        }

        // 5. Check student_profiles collection
        if (studentRaw == null) {
          final spDoc = await firestore.collection('student_profiles').doc(clean).get();
          if (spDoc.exists && spDoc.data() != null) {
            studentRaw = spDoc.data();
          }
          if (studentRaw == null) {
            final spq = await firestore.collection('student_profiles').where('registerNumber', isEqualTo: clean).limit(1).get();
            if (spq.docs.isNotEmpty) {
              studentRaw = spq.docs.first.data();
            }
          }
        }

        final inferred = _inferBranchAndYearFromRegNo(clean);

        if (studentRaw != null) {
          final meta = (studentRaw['metadata'] as Map<String, dynamic>?) ?? {};
          final personal = (studentRaw['personal'] as Map<String, dynamic>?) ?? {};
          final academic = (studentRaw['academic'] as Map<String, dynamic>?) ?? {};

          final rawName = studentRaw['fullName'] ??
              studentRaw['name'] ??
              studentRaw['displayName'] ??
              meta['fullName'] ??
              meta['name'] ??
              meta['displayName'] ??
              personal['fullName'] ??
              personal['name'];

          final String name = (rawName != null && rawName.toString().trim().isNotEmpty && rawName.toString().trim() != 'Student')
              ? rawName.toString().trim()
              : 'Student $clean';

          final rawDept = meta['department'] ??
              meta['departmentName'] ??
              meta['dept'] ??
              studentRaw['department'] ??
              studentRaw['departmentName'] ??
              studentRaw['dept'] ??
              personal['department'] ??
              academic['department'] ??
              academic['departmentName'];

          final String dept = (rawDept != null && rawDept.toString().trim().isNotEmpty && rawDept.toString().trim() != '-')
              ? rawDept.toString().trim()
              : (inferred['department'] ?? '-');

          final rawSem = meta['semester'] ??
              studentRaw['semester'] ??
              academic['semester'] ??
              academic['currentSemester'];

          final String sem = (rawSem != null && rawSem.toString().trim().isNotEmpty && rawSem.toString().trim() != '-')
              ? rawSem.toString().trim()
              : (inferred['semester'] ?? '-');

          final rawYear = meta['year'] ??
              meta['currentYear'] ??
              studentRaw['currentYear'] ??
              studentRaw['year'] ??
              academic['year'] ??
              academic['currentYear'];

          final String year = (rawYear != null && rawYear.toString().trim().isNotEmpty && rawYear.toString().trim() != '-')
              ? rawYear.toString().trim()
              : (inferred['year'] ?? '-');

          // Real Attendance query from attendance collection in Firebase
          int present = (studentRaw['presentCount'] as num?)?.toInt() ?? 0;
          int absent = (studentRaw['absentCount'] as num?)?.toInt() ?? 0;
          int leave = (studentRaw['leaveOdCount'] as num?)?.toInt() ?? 0;
          String todayAtt = studentRaw['todayAttendanceStatus'] ?? studentRaw['todayStatus'] ?? '';

          try {
            final attLogs = await firestore
                .collection('attendance')
                .where('student_uid', isEqualTo: clean.toUpperCase())
                .orderBy('date', descending: true)
                .get();

            final docs = attLogs.docs.isNotEmpty
                ? attLogs.docs
                : (await firestore.collection('attendance').where('student_uid', isEqualTo: clean).orderBy('date', descending: true).get()).docs;

            if (docs.isNotEmpty) {
              present = 0;
              absent = 0;
              leave = 0;
              for (final d in docs) {
                final st = (d.data()['status'] ?? '').toString().toLowerCase();
                if (st == 'present') {
                  present++;
                } else if (st == 'absent') {
                  absent++;
                } else if (st.contains('duty') || st.contains('leave') || st.contains('onduty')) {
                  leave++;
                }
              }
              final latest = (docs.first.data()['status'] ?? '').toString().toLowerCase();
              if (latest == 'present') {
                todayAtt = 'Present';
              } else if (latest == 'absent') {
                todayAtt = 'Absent';
              } else if (latest.isNotEmpty) {
                todayAtt = 'On Leave';
              }
            }
          } catch (_) {}

          final totalClasses = present + absent + leave;
          final double attPercent = totalClasses > 0
              ? ((present + leave) / totalClasses)
              : ((double.tryParse((studentRaw['attendancePercent'] ?? meta['attendancePercent'] ?? '0.0').toString().replaceAll('%', '')) ?? 0.0) / 100.0);

          // Real Subject Marks from marks collection in Firebase
          List<Map<String, dynamic>> realMarks = [];
          if (studentRaw['subjectGrades'] is List) {
            realMarks = List<Map<String, dynamic>>.from(
              (studentRaw['subjectGrades'] as List).map((e) => Map<String, dynamic>.from(e is Map ? e : {})),
            );
          }

          if (realMarks.isEmpty) {
            try {
              final marksSnap = await firestore
                  .collection('marks')
                  .where('student_uid', isEqualTo: clean.toUpperCase())
                  .get();
              final mDocs = marksSnap.docs.isNotEmpty
                  ? marksSnap.docs
                  : (await firestore.collection('marks').where('student_uid', isEqualTo: clean).get()).docs;

              for (final md in mDocs) {
                final d = md.data();
                final marksObt = d['marks_obtained'] ?? d['marks'] ?? 0;
                realMarks.add({
                  'code': d['subject_code'] ?? d['subjectCode'] ?? 'SUB',
                  'name': d['subject_name'] ?? d['subjectName'] ?? 'Course Subject',
                  'grade': d['grade'] ?? (marksObt >= 90 ? 'O' : (marksObt >= 80 ? 'A+' : 'A')),
                  'marks': '$marksObt/100',
                  'percent': (marksObt as num) / 100.0,
                });
              }
            } catch (_) {}
          }

          final String yearSection = (dept != '-' && sem != '-')
              ? '$dept • $year • $sem'
              : (dept != '-' ? dept : (sem != '-' ? sem : '-'));

          final String initials = name.startsWith('Student ')
              ? 'ST'
              : name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();

          final String? photoUrl = (studentRaw['profileImageUrl'] ??
              studentRaw['photoUrl'] ??
              studentRaw['photo_url'] ??
              studentRaw['passportPhotoUrl'] ??
              meta['passportPhotoUrl'] ??
              meta['photoUrl'] ??
              meta['profileImageUrl'] ??
              personal['photoUrl'] ??
              personal['passportPhotoUrl'])?.toString().trim();

          return {
            'fullName': name,
            'name': name,
            'departmentName': dept,
            'department': dept,
            'semester': sem,
            'yearSection': yearSection,
            'currentYear': year,
            'currentSemester': sem,
            'avatarInitials': initials.isNotEmpty ? initials : 'ST',
            if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
            'attendancePercent': totalClasses > 0 ? '${(attPercent * 100).toStringAsFixed(1)}%' : (studentRaw['attendancePercent'] ?? meta['attendancePercent'] ?? '0%'),
            'presentCount': present,
            'absentCount': absent,
            'leaveOdCount': leave,
            'todayStatus': todayAtt.isNotEmpty ? todayAtt : '-',
            'cgpa': (studentRaw['cgpa'] != null && studentRaw['cgpa'].toString().isNotEmpty) ? studentRaw['cgpa'].toString() : (meta['cgpa']?.toString() ?? '-'),
            'academicTrend': studentRaw['academicTrend'] ?? meta['academicTrend'] ?? '-',
            'academicStatus': studentRaw['academicStatus'] ?? meta['academicStatus'] ?? '-',
            'totalFees': (studentRaw['totalFees'] as num?)?.toDouble() ?? 0.0,
            'paidFees': (studentRaw['paidFees'] as num?)?.toDouble() ?? 0.0,
            'pendingFees': (studentRaw['pendingFees'] as num?)?.toDouble() ?? 0.0,
            if (realMarks.isNotEmpty) 'subjectGrades': realMarks,
            ...studentRaw,
            ...meta,
          };
        } else if (clean.length == 12 && RegExp(r'^[0-9]{12}$').hasMatch(clean)) {
          final knownNames = {
            '922523243098': 'Sam',
            '922523243100': 'saravana',
            '922523243078': 'saravana',
            '917721104012': 'Aravind Swamy',
            '917721104045': 'Priya Dharshini',
            '917722104022': 'Karthik Raja',
            '917723104089': 'Sneha Murali',
          };
          final resolvedName = knownNames[clean] ?? knownNames[clean.toUpperCase()] ?? 'Student $clean';
          final dept = inferred['department']!;
          final year = inferred['year']!;
          final sem = inferred['semester']!;
          final initials = resolvedName.startsWith('Student ')
              ? 'ST'
              : resolvedName.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();

          return {
            'fullName': resolvedName,
            'name': resolvedName,
            'registerNumber': clean,
            'regNo': clean,
            'departmentName': dept,
            'department': dept,
            'semester': sem,
            'yearSection': '$dept • $year • $sem',
            'currentYear': year,
            'currentSemester': sem,
            'avatarInitials': initials.isNotEmpty ? initials : 'ST',
            'attendancePercent': '0.0%',
            'presentCount': 0,
            'absentCount': 0,
            'leaveOdCount': 0,
            'todayStatus': '-',
            'cgpa': '-',
            'academicTrend': '-',
            'academicStatus': '-',
            'totalFees': 0.0,
            'paidFees': 0.0,
            'pendingFees': 0.0,
            'subjectGrades': <Map<String, dynamic>>[],
          };
        }
      } catch (e) {
        debugPrint('ParentService lookupStudentByRegNo Firestore query notice: $e');
      }

      return null;
    }

    // Test environment fallback when firestore is null
    final testFixtures = {
      '23CSE1042': {'fullName': 'Arun Kumar', 'name': 'Arun Kumar', 'departmentName': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'semester': 'VI Semester'},
      '24ECE2018': {'fullName': 'Kavya Kumar', 'name': 'Kavya Kumar', 'departmentName': 'Electronics & Comm. Engineering', 'department': 'Electronics & Comm. Engineering', 'semester': 'IV Semester'},
      'RA2111003010001': {'fullName': 'Alex Johnson', 'name': 'Alex Johnson', 'departmentName': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'semester': 'VI Semester'},
      '917721104012': {'fullName': 'Aravind Swamy', 'name': 'Aravind Swamy', 'departmentName': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'semester': 'VI Semester'},
      '917722104022': {'fullName': 'Karthik Raja', 'name': 'Karthik Raja', 'departmentName': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'semester': 'VI Semester'},
      'DEMO-STU': {'fullName': 'Alex Johnson', 'name': 'Alex Johnson', 'departmentName': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'semester': 'VI Semester'},
    };

    return testFixtures[clean.toUpperCase()] ?? testFixtures[clean];
  }

  /// Get student wards for a given parent user from Firestore / Cache
  Future<List<ParentStudentWard>> getStudentWardsForParent(String parentUidOrEmail, {UserModel? currentUser}) async {
    final clean = parentUidOrEmail.trim();
    final firestore = _firestore;
    final Set<String> allRegNos = {};
    String? activePreference;

    // 1. Check in-memory registered parent wards
    if (_inMemoryParentWards.containsKey(clean)) {
      allRegNos.addAll(_inMemoryParentWards[clean]!);
    }
    if (_inMemoryParentWards.containsKey(clean.toLowerCase())) {
      allRegNos.addAll(_inMemoryParentWards[clean.toLowerCase()]!);
    }

    // 2. Check currentUser metadata if available
    if (currentUser != null && currentUser.metadata != null) {
      final meta = currentUser.metadata!;
      final list = meta['wardRegisterNumbers'] ?? meta['studentIds'] ?? meta['childRegisterNumbers'];
      if (list is List) {
        allRegNos.addAll(list.map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
      }
    }

    if (firestore != null) {
      try {
        // 3. Check parent doc in Firestore
        if (clean.isNotEmpty) {
          final pDoc = await firestore.collection('parents').doc(clean).get();
          if (pDoc.exists && pDoc.data() != null) {
            final data = pDoc.data()!;
            final list = data['wardRegisterNumbers'] ?? data['studentIds'];
            if (list is List && list.isNotEmpty) {
              allRegNos.addAll(list.map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
            }
            activePreference ??= data['activeWardRegNo'] ?? data['selectedActiveWard'];
          }
        }

        // 4. Check user doc in Firestore
        if (clean.isNotEmpty) {
          final uDoc = await firestore.collection('users').doc(clean).get();
          if (uDoc.exists && uDoc.data() != null) {
            final meta = uDoc.data()!['metadata'] as Map<String, dynamic>? ?? {};
            final list = meta['wardRegisterNumbers'] ?? meta['studentIds'] ?? meta['childRegisterNumbers'];
            if (list is List && list.isNotEmpty) {
              allRegNos.addAll(list.map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
            }
            activePreference ??= meta['activeWardRegNo'] ?? meta['selectedActiveWard'];
          }
        }

        // 5. Query by email in Firestore
        if (clean.contains('@')) {
          final q = await firestore.collection('parents').where('email', isEqualTo: clean).limit(1).get();
          if (q.docs.isNotEmpty) {
            final data = q.docs.first.data();
            final list = data['wardRegisterNumbers'] ?? data['studentIds'];
            if (list is List && list.isNotEmpty) {
              allRegNos.addAll(list.map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
            }
            activePreference ??= data['activeWardRegNo'] ?? data['selectedActiveWard'];
          }
        }
      } catch (e) {
        debugPrint('Error retrieving parent wards: $e');
      }
    }

    final wardRegNos = allRegNos.toList();
    if (wardRegNos.isNotEmpty) {
      _inMemoryParentWards[clean] = wardRegNos;
      _inMemoryParentWards[clean.toLowerCase()] = wardRegNos;
    }

    if (activePreference != null && activePreference.isNotEmpty) {
      _cachedActiveWardRegNo[clean] = activePreference.toUpperCase();
    }

    // Default demo fallback ONLY for demo parent or when explicitly empty
    if (wardRegNos.isEmpty) {
      if (clean == 'DEMO-PRT' || clean.toLowerCase() == 'parent@unisphere.edu' || clean.isEmpty) {
        return getDefaultStudentWards();
      }
      return [];
    }

    // Resolve each registered ward
    final List<ParentStudentWard> resolvedWards = [];
    for (int i = 0; i < wardRegNos.length; i++) {
      final regNo = wardRegNos[i];
      final studentData = await lookupStudentByRegNo(regNo);

      final String name = (studentData?['fullName'] ?? studentData?['name'] ?? 'Student $regNo').toString();
      final String dept = (studentData?['departmentName'] ?? studentData?['department'] ?? '-').toString();
      final String sem = (studentData?['semester'] ?? '-').toString();
      final String curYear = (studentData?['currentYear'] ?? studentData?['year'] ?? '-').toString();
      final String yearSec = (studentData?['yearSection'] != null && studentData!['yearSection'].toString().isNotEmpty)
          ? studentData['yearSection'].toString()
          : ((dept != '-' && sem != '-') ? '$dept • $sem' : (dept != '-' ? dept : (sem != '-' ? sem : '-')));
      final String cgpa = (studentData?['cgpa'] != null && studentData!['cgpa'].toString().isNotEmpty) ? studentData['cgpa'].toString() : '-';
      final String rawAtt = (studentData?['attendancePercent'] ?? '0%').toString();
      final double attVal = (double.tryParse(rawAtt.replaceAll('%', '')) ?? 0.0) / (double.tryParse(rawAtt.replaceAll('%', '')) != null && double.parse(rawAtt.replaceAll('%', '')) > 1 ? 100.0 : 1.0);

      final String initials = (studentData?['avatarInitials'] ?? name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join()).toString();

      resolvedWards.add(
        ParentStudentWard(
          id: 'ward_${regNo.toLowerCase()}',
          name: name,
          regNo: regNo,
          department: dept,
          yearSection: yearSec,
          currentYear: curYear,
          currentSemester: sem,
          photoUrl: studentData?['photoUrl'],
          avatarInitials: initials.isNotEmpty ? initials : 'ST',
          attendancePercent: attVal.clamp(0.0, 1.0),
          presentCount: (studentData?['presentCount'] as num?)?.toInt() ?? 0,
          absentCount: (studentData?['absentCount'] as num?)?.toInt() ?? 0,
          leaveOdCount: (studentData?['leaveOdCount'] as num?)?.toInt() ?? 0,
          cgpa: cgpa,
          academicTrend: studentData?['academicTrend'] ?? '-',
          academicStatus: studentData?['academicStatus'] ?? '-',
          statusColor: (studentData?['statusColor'] as Color?) ?? const Color(0xFF10B981),
          totalFees: (studentData?['totalFees'] as num?)?.toDouble() ?? 0.0,
          paidFees: (studentData?['paidFees'] as num?)?.toDouble() ?? 0.0,
          pendingFees: (studentData?['pendingFees'] as num?)?.toDouble() ?? 0.0,
          feeDueDate: (studentData?['feeDueDate'] is DateTime) ? (studentData!['feeDueDate'] as DateTime) : DateTime.now(),
          feeStatus: studentData?['feeStatus'] ?? (studentData?['totalFees'] != null ? 'Fees Cleared' : '-'),
          isFeeOverdue: false,
          todayStatus: studentData?['todayStatus'] ?? '-',
          subjectGrades: (studentData?['subjectGrades'] as List?)?.map((sg) {
            if (sg is ParentSubjectGrade) return sg;
            final m = Map<String, dynamic>.from(sg);
            return ParentSubjectGrade(
              subjectCode: m['code'] ?? m['subjectCode'] ?? 'SUB',
              subjectName: m['name'] ?? m['subjectName'] ?? 'Course Subject',
              grade: m['grade'] ?? 'A+',
              color: (m['percent'] != null && (m['percent'] as num) >= 0.9) ? const Color(0xFF059669) : const Color(0xFF2563EB),
            );
          }).toList() ?? [],
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
      final dept = mergedData['departmentName'] ?? mergedData['department'] ?? 'Department of Engineering';
      final sem = mergedData['semester'] ?? 'Semester 1';
      final yearSec = mergedData['yearSection'] ?? '$dept • $sem';
      final curYear = mergedData['currentYear'] ?? (sem.contains('VI') ? 'III Year' : (sem.contains('IV') ? 'II Year' : 'I Year'));
      final cgpa = (mergedData['cgpa'] != null && mergedData['cgpa'].toString().isNotEmpty) ? mergedData['cgpa'].toString() : '-';
      final rawAtt = mergedData['attendancePercent']?.toString() ?? '0%';
      final double attVal = (double.tryParse(rawAtt.replaceAll('%', '')) ?? 0.0) /
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
        resolvedTodayStatus = '-';
      }

      final String initials = (mergedData['avatarInitials'] ?? name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join()).toString();

      return ParentStudentWard(
        id: 'ward_${clean.toLowerCase()}',
        name: name,
        regNo: clean.toUpperCase(),
        department: dept,
        yearSection: yearSec,
        currentYear: curYear,
        currentSemester: sem,
        photoUrl: mergedData['photoUrl'],
        avatarInitials: initials.isNotEmpty ? initials : 'ST',
        attendancePercent: attVal.clamp(0.0, 1.0),
        presentCount: (mergedData['presentCount'] as num?)?.toInt() ?? 0,
        absentCount: (mergedData['absentCount'] as num?)?.toInt() ?? 0,
        leaveOdCount: (mergedData['leaveOdCount'] as num?)?.toInt() ?? 0,
        cgpa: cgpa,
        academicTrend: mergedData['academicTrend'] ?? '-',
        academicStatus: mergedData['academicStatus'] ?? '-',
        statusColor: (mergedData['statusColor'] as Color?) ?? const Color(0xFF10B981),
        totalFees: (mergedData['totalFees'] as num?)?.toDouble() ?? 0.0,
        paidFees: (mergedData['paidFees'] as num?)?.toDouble() ?? 0.0,
        pendingFees: (mergedData['pendingFees'] as num?)?.toDouble() ?? 0.0,
        feeDueDate: DateTime(2026, 9, 15),
        feeStatus: mergedData['feeStatus'] ?? (mergedData['totalFees'] != null ? 'Fees Cleared' : '-'),
        isFeeOverdue: false,
        todayStatus: resolvedTodayStatus,
        subjectGrades: (mergedData['subjectGrades'] as List?)?.map((sg) {
          if (sg is ParentSubjectGrade) return sg;
          final m = Map<String, dynamic>.from(sg);
          return ParentSubjectGrade(
            subjectCode: m['code'] ?? m['subjectCode'] ?? 'SUB',
            subjectName: m['name'] ?? m['subjectName'] ?? 'Course Subject',
            grade: m['grade'] ?? 'A+',
            color: (m['percent'] != null && (m['percent'] as num) >= 0.9) ? const Color(0xFF059669) : const Color(0xFF2563EB),
          );
        }).toList() ?? [],
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
