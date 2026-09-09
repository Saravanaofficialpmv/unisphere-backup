import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/repositories/attendance_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository();
});

class StaffRepository {
  final FirebaseFirestore? _firestore;

  StaffRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. STAFF PROFILE & LIVE STREAM
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<StaffModel?> watchStaffProfile(String uid) {
    final firestore = _firestore;
    if (uid.isEmpty || firestore == null) {
      return Stream.value(null);
    }

    return firestore
        .collection('staff')
        .doc(uid)
        .snapshots()
        .map((docSnap) {
          if (docSnap.exists && docSnap.data() != null) {
            return StaffModel.fromMap(docSnap.data()!, docSnap.id);
          }
          return null;
        })
        .handleError((e) {
          debugPrint('StaffRepository watchStaffProfile error: $e');
          return null;
        });
  }

  Future<StaffModel?> getStaffProfile(String uid) async {
    final firestore = _firestore;
    if (uid.isEmpty || firestore == null) return null;
    try {
      final doc = await firestore.collection('staff').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StaffModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('StaffRepository getStaffProfile error: $e');
    }
    return null;
  }

  Future<void> saveStaffProfile(StaffModel staff) async {
    final firestore = _firestore;
    if (firestore == null || staff.userId.isEmpty) return;
    try {
      final data = staff.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await firestore
          .collection('staff')
          .doc(staff.userId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('StaffRepository saveStaffProfile error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. STAFF ASSIGNMENTS (Extensible Responsibilities)
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<StaffAssignmentModel>> watchStaffAssignments(String staffId) {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return Stream.value(const []);
    }

    return firestore
        .collection('staffAssignments')
        .where('staffId', isEqualTo: staffId)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) {
            return const <StaffAssignmentModel>[];
          }
          return snap.docs
              .map((d) => StaffAssignmentModel.fromMap(d.data(), d.id))
              .toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchStaffAssignments error: $e');
          return const <StaffAssignmentModel>[];
        });
  }

  Future<List<StaffAssignmentModel>> getStaffAssignments(String staffId) async {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return const [];
    }
    try {
      final snap = await firestore
          .collection('staffAssignments')
          .where('staffId', isEqualTo: staffId)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((d) => StaffAssignmentModel.fromMap(d.data(), d.id))
            .toList();
      }
    } catch (e) {
      debugPrint('StaffRepository getStaffAssignments error: $e');
    }
    return const [];
  }

  Future<void> assignResponsibility(StaffAssignmentModel assignment) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final docRef = firestore.collection('staffAssignments').doc(assignment.id.isEmpty ? null : assignment.id);
      final data = assignment.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (assignment.createdAt == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await docRef.set(data, SetOptions(merge: true));

      // Also update the staff profile with quick access flags if class_advisor
      if (assignment.isClassAdvisor) {
        await firestore.collection('staff').doc(assignment.staffId).set({
          'isAdvisor': true,
          'is_advisor': true,
          'isClassAdvisor': true,
          'advisorSection': assignment.section ?? assignment.className ?? 'III CSE - A',
          'advisorClassId': assignment.classId ?? 'CLASS-III-CSE-A',
          'advisorAcademicYear': assignment.academicYear,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('StaffRepository assignResponsibility error: $e');
      rethrow;
    }
  }

  Future<void> revokeAssignment(String assignmentId, {String? staffId}) async {
    final firestore = _firestore;
    if (firestore == null || assignmentId.isEmpty) return;
    try {
      await firestore.collection('staffAssignments').doc(assignmentId).update({
        'status': 'revoked',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (staffId != null && staffId.isNotEmpty) {
        // Check if there are any other active advisor assignments
        final activeOther = await firestore
            .collection('staffAssignments')
            .where('staffId', isEqualTo: staffId)
            .where('status', isEqualTo: 'active')
            .where('assignmentType', isEqualTo: 'class_advisor')
            .get();

        if (activeOther.docs.isEmpty) {
          await firestore.collection('staff').doc(staffId).set({
            'isAdvisor': false,
            'is_advisor': false,
            'isClassAdvisor': false,
            'advisorSection': null,
            'advisorClassId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('StaffRepository revokeAssignment error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. TODAY'S CLASSES & SCHEDULE
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchTodaySchedule(String staffId) {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return Stream.value(const []);
    }

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    return firestore
        .collection('staffSchedules')
        .where('staffId', isEqualTo: staffId)
        .where('date', isEqualTo: todayStr)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchTodaySchedule error: $e');
          return const <Map<String, dynamic>>[];
        });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. MY SUBJECTS
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchStaffSubjects(String staffId) {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return Stream.value(const []);
    }

    return firestore
        .collection('staffSubjects')
        .where('staffId', isEqualTo: staffId)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchStaffSubjects error: $e');
          return const <Map<String, dynamic>>[];
        });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. PENDING WORK & RECENT ACTIVITIES
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchPendingWork(String staffId) {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return Stream.value(const []);
    }

    return firestore
        .collection('staffPendingTasks')
        .where('staffId', isEqualTo: staffId)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) => const <Map<String, dynamic>>[]);
  }

  Stream<List<Map<String, dynamic>>> watchRecentActivities(String staffId) {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return Stream.value(const []);
    }

    return firestore
        .collection('staffActivities')
        .where('staffId', isEqualTo: staffId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) => const <Map<String, dynamic>>[]);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. ADVISOR CLASS STUDENTS & METRICS
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<StudentModel>> watchClassStudents({String? section, String? departmentId}) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(const []);
    }

    final querySection = section?.trim() ?? '';
    Query query = firestore.collection('students');
    if (querySection.isNotEmpty) {
      query = query.where('section', isEqualTo: querySection);
    }

    return query
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => StudentModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchClassStudents error: $e');
          return const <StudentModel>[];
        });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. ADVISOR LEAVE / OD REQUESTS
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchAdvisorLeaveODRequests(String section) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value(<Map<String, dynamic>>[]);

    final cleanSection = section.trim();
    Query<Map<String, dynamic>> query = firestore.collection('leave_requests');
    if (cleanSection.isNotEmpty) {
      query = query.where('section', isEqualTo: cleanSection);
    }

    return query
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchAdvisorLeaveODRequests error: $e');
          return <Map<String, dynamic>>[];
        });
  }

  /// Submit a student leave or OD request into Firestore leave_requests
  Future<void> submitStudentLeaveRequest(LeaveRequestModel request) async {
    final firestore = _firestore;
    if (firestore == null || request.id.isEmpty) return;
    try {
      await firestore.collection('leave_requests').doc(request.id).set(request.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('StaffRepository submitStudentLeaveRequest error: $e');
      rethrow;
    }
  }

  Future<void> updateLeaveODStatus({
    required String requestId,
    required String status,
    String? reviewerName,
    String? remarks,
  }) async {
    final firestore = _firestore;
    if (firestore == null || requestId.isEmpty) return;
    try {
      final docRef = firestore.collection('leave_requests').doc(requestId);
      final docSnap = await docRef.get();
      final existingData = docSnap.data() ?? {};

      final data = <String, dynamic>{
        'status': status,
        'reviewedBy': reviewerName ?? 'HOD',
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (remarks != null && remarks.isNotEmpty) {
        data['remarks'] = remarks;
      }
      await docRef.set(data, SetOptions(merge: true));

      // If status is 'Approved' and this is an On-Duty (OD) request,
      // automatically log an attendance record with AttendanceStatus.onDuty
      final type = (existingData['type'] ?? existingData['leaveCategory'] ?? '').toString().toLowerCase();
      if (status.toLowerCase().contains('approv') && (type.contains('duty') || type.contains('od'))) {
        final stuId = (existingData['studentId'] ?? existingData['student_id'] ?? existingData['studentUid'] ?? existingData['registerNumber'] ?? '').toString().trim();
        final stuName = (existingData['studentName'] ?? existingData['student_name'] ?? existingData['name'] ?? 'Student').toString().trim();

        if (stuId.isNotEmpty) {
          final now = DateTime.now();
          final odRecord = AttendanceRecord(
            id: 'od_${now.millisecondsSinceEpoch}_$stuId',
            studentUid: stuId,
            studentName: stuName,
            subjectCode: 'OD-APPR',
            subjectName: 'On Duty Activity',
            date: now,
            timeSlot: 'Full Day',
            status: AttendanceStatus.onDuty,
            facultyName: reviewerName ?? 'Academic Advisor / HOD',
          );
          await AttendanceRepository(firestore: firestore).markAttendance(odRecord);
        }
      }
    } catch (e) {
      debugPrint('StaffRepository updateLeaveODStatus error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. ADVISOR TASKS
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<StaffTaskModel>> watchAdvisorTasks(String staffId) {
    final firestore = _firestore;
    if (firestore == null || staffId.isEmpty) {
      return Stream.value(const []);
    }

    return firestore
        .collection('staffTasks')
        .where('staffId', isEqualTo: staffId)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => StaffTaskModel.fromMap(d.data(), d.id))
              .toList();
        })
        .handleError((e) => const <StaffTaskModel>[]);
  }

  Future<void> toggleAdvisorTaskStatus(String taskId, bool isCompleted) async {
    final firestore = _firestore;
    if (firestore == null || taskId.isEmpty) return;
    try {
      await firestore.collection('staffTasks').doc(taskId).set({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('StaffRepository toggleAdvisorTaskStatus error: $e');
    }
  }

  /// Stream real-time leave and OD requests for a department
  /// Stream real-time leave and OD requests for a department
  Stream<List<Map<String, dynamic>>> watchDepartmentLeaveRequests(String departmentId) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value(<Map<String, dynamic>>[]);

    final cleanDept = departmentId.trim();
    Query<Map<String, dynamic>> query = firestore.collection('leave_requests');
    if (cleanDept.isNotEmpty) {
      query = query.where('departmentId', isEqualTo: cleanDept);
    }

    return query.snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
    }).handleError((e) {
      debugPrint('StaffRepository watchDepartmentLeaveRequests error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  /// Watch all staff members strictly scoped to a department and institution
  Stream<List<StaffModel>> watchStaffByDepartment(String departmentId, {String? institutionId}) {
    final firestore = _firestore;
    final cleanDept = departmentId.trim();
    final cleanInst = institutionId?.trim();
    if (firestore == null) {
      return Stream.value(const []);
    }

    return firestore.collection('staff').snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return const <StaffModel>[];
      }
      final list = snap.docs
          .map((d) => StaffModel.fromMap(d.data(), d.id))
          .where((s) {
            final matchesDept = _matchesStaffDepartment(s, cleanDept);
            final matchesInst = cleanInst == null || cleanInst.isEmpty || s.institutionId == null || s.institutionId!.isEmpty || s.institutionId == cleanInst;
            return matchesDept && matchesInst;
          })
          .toList();
      return list;
    }).handleError((e) {
      debugPrint('StaffRepository watchStaffByDepartment error: $e');
      return const <StaffModel>[];
    });
  }

  /// Watch all staff assignments for a department
  Stream<List<StaffAssignmentModel>> watchAssignmentsByDepartment(String departmentId, {String? institutionId}) {
    final firestore = _firestore;
    final cleanDept = departmentId.trim();
    final cleanInst = institutionId?.trim();
    if (firestore == null) return Stream.value(const []);

    return firestore.collection('staffAssignments').snapshots().map((snap) {
      if (snap.docs.isEmpty) return const <StaffAssignmentModel>[];
      final list = snap.docs
          .map((d) => StaffAssignmentModel.fromMap(d.data(), d.id))
          .where((a) {
            final matchesDept = cleanDept.isEmpty || a.departmentId.toLowerCase().contains(cleanDept.toLowerCase());
            final matchesInst = cleanInst == null || cleanInst.isEmpty || a.institutionId == null || a.institutionId!.isEmpty || a.institutionId == cleanInst;
            return matchesDept && matchesInst;
          })
          .toList();
      return list;
    }).handleError((e) {
      debugPrint('StaffRepository watchAssignmentsByDepartment error: $e');
      return const <StaffAssignmentModel>[];
    });
  }

  static bool _matchesStaffDepartment(StaffModel staff, String targetDept) {
    final cleanTarget = targetDept.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final staffDeptId = staff.departmentId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final staffDeptName = staff.departmentName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (cleanTarget.isEmpty) return true;
    if (staffDeptId == cleanTarget || staffDeptName == cleanTarget) return true;
    if (staffDeptId.contains(cleanTarget) || cleanTarget.contains(staffDeptId)) return true;
    if (cleanTarget.contains('cse') || cleanTarget.contains('computerscience')) {
      if (staffDeptId.contains('cse') || staffDeptName.contains('computerscience')) return true;
    }
    return false;
  }
}
