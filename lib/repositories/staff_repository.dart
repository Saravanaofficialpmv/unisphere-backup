import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';

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
    if (uid.isEmpty) {
      return Stream.value(null);
    }
    if (firestore == null) {
      if (uid == 'DEMO-STF') {
        return Stream.value(_resolveDefaultStaff(uid));
      }
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
          if (uid == 'DEMO-STF') {
            return _resolveDefaultStaff(uid);
          }
          return null;
        })
        .handleError((e) {
          debugPrint('StaffRepository watchStaffProfile error: $e');
          if (uid == 'DEMO-STF') {
            return _resolveDefaultStaff(uid);
          }
          return null;
        });
  }

  Future<StaffModel?> getStaffProfile(String uid) async {
    final firestore = _firestore;
    if (uid.isEmpty) return null;
    if (firestore == null) {
      return uid == 'DEMO-STF' ? _resolveDefaultStaff(uid) : null;
    }
    try {
      final doc = await firestore.collection('staff').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StaffModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('StaffRepository getStaffProfile error: $e');
    }
    return uid == 'DEMO-STF' ? _resolveDefaultStaff(uid) : null;
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
      return Stream.value(_resolveDefaultAssignments(staffId));
    }

    return firestore
        .collection('staffAssignments')
        .where('staffId', isEqualTo: staffId)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) {
            return _resolveDefaultAssignments(staffId);
          }
          return snap.docs
              .map((d) => StaffAssignmentModel.fromMap(d.data(), d.id))
              .toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchStaffAssignments error: $e');
          return _resolveDefaultAssignments(staffId);
        });
  }

  Future<List<StaffAssignmentModel>> getStaffAssignments(String staffId) async {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return _resolveDefaultAssignments(staffId);
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
    return _resolveDefaultAssignments(staffId);
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
      return Stream.value(_defaultTodaySchedule);
    }

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    return firestore
        .collection('staffSchedules')
        .where('staffId', isEqualTo: staffId)
        .where('date', isEqualTo: todayStr)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) {
            return _defaultTodaySchedule;
          }
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchTodaySchedule error: $e');
          return _defaultTodaySchedule;
        });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. MY SUBJECTS
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchStaffSubjects(String staffId) {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return Stream.value(_defaultSubjects);
    }

    return firestore
        .collection('staffSubjects')
        .where('staffId', isEqualTo: staffId)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) {
            return _defaultSubjects;
          }
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchStaffSubjects error: $e');
          return _defaultSubjects;
        });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. PENDING WORK & RECENT ACTIVITIES
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchPendingWork(String staffId) {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return Stream.value(_defaultPendingWork);
    }

    return firestore
        .collection('staffPendingTasks')
        .where('staffId', isEqualTo: staffId)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return _defaultPendingWork;
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) => _defaultPendingWork);
  }

  Stream<List<Map<String, dynamic>>> watchRecentActivities(String staffId) {
    final firestore = _firestore;
    if (staffId.isEmpty || firestore == null) {
      return Stream.value(_defaultRecentActivities);
    }

    return firestore
        .collection('staffActivities')
        .where('staffId', isEqualTo: staffId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return _defaultRecentActivities;
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) => _defaultRecentActivities);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. ADVISOR CLASS STUDENTS & METRICS
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<StudentModel>> watchClassStudents({String? section, String? departmentId}) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(_defaultClassStudents);
    }

    final querySection = (section == null || section.isEmpty || section.toLowerCase().contains('iii cse - a'))
        ? 'III CSE - A'
        : section;

    return firestore
        .collection('students')
        .where('section', isEqualTo: querySection)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) {
            return _defaultClassStudents;
          }
          return snap.docs
              .map((d) => StudentModel.fromMap(d.data(), d.id))
              .toList();
        })
        .handleError((e) {
          debugPrint('StaffRepository watchClassStudents error: $e');
          return _defaultClassStudents;
        });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. ADVISOR LEAVE / OD REQUESTS
  // ─────────────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchAdvisorLeaveODRequests(String section) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value(_defaultLeaveODRequests);

    return firestore
        .collection('leave_requests')
        .where('section', isEqualTo: section.isEmpty ? 'III CSE - A' : section)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return _defaultLeaveODRequests;
          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
        })
        .handleError((e) => _defaultLeaveODRequests);
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
      final data = <String, dynamic>{
        'status': status,
        'reviewedBy': reviewerName ?? 'HOD',
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (remarks != null && remarks.isNotEmpty) {
        data['remarks'] = remarks;
      }
      await firestore.collection('leave_requests').doc(requestId).set(data, SetOptions(merge: true));
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
      return Stream.value(StaffTaskModel.defaultTasks);
    }

    return firestore
        .collection('staffTasks')
        .where('staffId', isEqualTo: staffId)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return StaffTaskModel.defaultTasks;
          return snap.docs
              .map((d) => StaffTaskModel.fromMap(d.data(), d.id))
              .toList();
        })
        .handleError((e) => StaffTaskModel.defaultTasks);
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. DEFAULT / SEEDED DATA HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  static List<StaffModel> _resolveDefaultStaffList(String departmentId, {String? institutionId}) {
    final cleanDept = departmentId.isNotEmpty ? departmentId : 'DEPT-CSE';
    final cleanInst = institutionId ?? 'INST-UNI-01';

    return [
      StaffModel(
        userId: 'UNI-STF-CSE-001',
        employeeId: 'UNI-STF-CSE-001',
        fullName: 'Arun Kumar',
        email: 'arun@college.edu',
        departmentId: cleanDept,
        departmentName: 'Computer Science & Engineering',
        institutionId: cleanInst,
        designation: 'Assistant Professor',
        specialization: 'Machine Learning & AI',
        assignedClasses: ['III CSE - A', 'IV CSE - A'],
        assignedSubjects: ['Machine Learning', 'Data Structures', 'Artificial Intelligence'],
        isAdvisor: true,
        advisorSection: 'III CSE - A',
        advisorClassId: 'CLASS-III-CSE-A',
        advisorAcademicYear: '2025–26',
        experienceYears: 8,
        officeLocation: 'Academic Block 3, Cabin 401',
        photoPath: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      ),
      StaffModel(
        userId: 'UNI-STF-CSE-002',
        employeeId: 'UNI-STF-CSE-002',
        fullName: 'Priya Devi',
        email: 'priya@college.edu',
        departmentId: cleanDept,
        departmentName: 'Computer Science & Engineering',
        institutionId: cleanInst,
        designation: 'Associate Professor',
        specialization: 'Cloud Computing & Distributed Systems',
        assignedClasses: ['II CSE - B', 'III CSE - B'],
        assignedSubjects: ['Cloud Computing', 'Operating Systems', 'Database Management'],
        isAdvisor: false,
        experienceYears: 10,
        officeLocation: 'Academic Block 3, Cabin 405',
        photoPath: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      ),
      StaffModel(
        userId: 'UNI-STF-CSE-003',
        employeeId: 'UNI-STF-CSE-003',
        fullName: 'Dr. K. Tharani Kumar',
        email: 'tharani.kumar@college.edu',
        departmentId: cleanDept,
        departmentName: 'Computer Science & Engineering',
        institutionId: cleanInst,
        designation: 'Assistant Professor',
        specialization: 'Artificial Intelligence & Machine Learning',
        assignedClasses: ['III CSE - A', 'II CSE - B', 'IV CSE - A'],
        assignedSubjects: ['Machine Learning', 'Data Structures', 'Artificial Intelligence'],
        isAdvisor: true,
        advisorSection: 'III CSE - A',
        advisorClassId: 'CLASS-III-CSE-A',
        advisorAcademicYear: '2025–26',
        experienceYears: 8,
        officeLocation: 'Academic Block 3, Cabin 402',
        photoPath: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      ),
      StaffModel(
        userId: 'UNI-STF-CSE-004',
        employeeId: 'UNI-STF-CSE-004',
        fullName: 'Prof. Rajesh Kumar',
        email: 'rajesh.k@college.edu',
        departmentId: cleanDept,
        departmentName: 'Computer Science & Engineering',
        institutionId: cleanInst,
        designation: 'Associate Professor',
        specialization: 'Data Structures & Algorithms',
        assignedClasses: ['II CSE - A', 'IV CSE - B'],
        assignedSubjects: ['Data Structures', 'Design and Analysis of Algorithms'],
        isAdvisor: false,
        experienceYears: 9,
        officeLocation: 'Academic Block 3, Cabin 408',
        photoPath: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      ),
      StaffModel(
        userId: 'UNI-STF-CSE-005',
        employeeId: 'UNI-STF-CSE-005',
        fullName: 'Dr. Anita Roy',
        email: 'anita.roy@college.edu',
        departmentId: cleanDept,
        departmentName: 'Computer Science & Engineering',
        institutionId: cleanInst,
        designation: 'Assistant Professor',
        specialization: 'AI & Data Science',
        assignedClasses: ['II CSE - B'],
        assignedSubjects: ['AI Fundamentals', 'Python for Data Science'],
        isAdvisor: true,
        advisorSection: 'II CSE - B',
        advisorClassId: 'CLASS-II-CSE-B',
        advisorAcademicYear: '2025–26',
        experienceYears: 6,
        officeLocation: 'Academic Block 3, Cabin 412',
        photoPath: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      ),
    ];
  }

  static StaffModel _resolveDefaultStaff(String uid) {
    final list = _resolveDefaultStaffList('DEPT-CSE');
    return list.firstWhere((s) => s.userId == uid || s.employeeId == uid, orElse: () => list.first);
  }

  static List<StaffAssignmentModel> _resolveDefaultAssignments(String staffId) {
    final now = DateTime.now();
    return [
      StaffAssignmentModel(
        id: 'ASGN-ADVISOR-01',
        staffId: staffId.isNotEmpty ? staffId : 'UNI-STF-CSE-001',
        staffName: 'Arun Kumar',
        departmentId: 'DEPT-CSE',
        institutionId: 'INST-UNI-01',
        assignmentType: StaffAssignmentType.classAdvisor,
        classId: 'CLASS-III-CSE-A',
        className: 'III CSE - A',
        section: 'III CSE - A',
        academicYear: '2025–26',
        assignedBy: 'Dr. S. Meenakshi (HOD)',
        startDate: DateTime(now.year, 6, 1),
        endDate: DateTime(now.year + 1, 5, 31),
        status: 'active',
      ),
      StaffAssignmentModel(
        id: 'ASGN-SUB-01',
        staffId: staffId.isNotEmpty ? staffId : 'UNI-STF-CSE-001',
        staffName: 'Arun Kumar',
        departmentId: 'DEPT-CSE',
        institutionId: 'INST-UNI-01',
        assignmentType: StaffAssignmentType.subjectFaculty,
        subjectId: 'SUB-CS8691',
        subjectName: 'Machine Learning',
        subjectCode: 'CS8691',
        classId: 'CLASS-III-CSE-A',
        className: 'III CSE - A',
        section: 'Sec A',
        academicYear: '2025–26',
        assignedBy: 'Dr. S. Meenakshi (HOD)',
        startDate: DateTime(now.year, 6, 1),
        status: 'active',
      ),
      StaffAssignmentModel(
        id: 'ASGN-SUB-02',
        staffId: staffId.isNotEmpty ? staffId : 'UNI-STF-CSE-001',
        staffName: 'Arun Kumar',
        departmentId: 'DEPT-CSE',
        institutionId: 'INST-UNI-01',
        assignmentType: StaffAssignmentType.subjectFaculty,
        subjectId: 'SUB-CS8392',
        subjectName: 'Data Structures',
        subjectCode: 'CS8392',
        classId: 'CLASS-II-CSE-B',
        className: 'II CSE - B',
        section: 'Sec B',
        academicYear: '2025–26',
        assignedBy: 'Dr. S. Meenakshi (HOD)',
        startDate: DateTime(now.year, 6, 1),
        status: 'active',
      ),
      StaffAssignmentModel(
        id: 'ASGN-DEPT-01',
        staffId: staffId.isNotEmpty ? staffId : 'UNI-STF-CSE-002',
        staffName: 'Priya Devi',
        departmentId: 'DEPT-CSE',
        institutionId: 'INST-UNI-01',
        assignmentType: StaffAssignmentType.departmentResponsibility,
        responsibilityTitle: 'Exam Coordinator',
        academicYear: '2025–26',
        assignedBy: 'Dr. S. Meenakshi (HOD)',
        startDate: DateTime(now.year, 6, 1),
        status: 'active',
      ),
    ];
  }

  static final List<Map<String, dynamic>> _defaultTodaySchedule = [
    {
      'id': 'SCH-01',
      'startTime': '09:00 AM',
      'endTime': '10:00 AM',
      'subjectName': 'Machine Learning',
      'subjectCode': 'CS8691',
      'className': 'III CSE - A',
      'room': 'CS Lab 2',
      'isAttendanceTaken': true,
      'attendancePercent': 95,
    },
    {
      'id': 'SCH-02',
      'startTime': '11:00 AM',
      'endTime': '12:00 PM',
      'subjectName': 'Data Structures',
      'subjectCode': 'CS8392',
      'className': 'II CSE - B',
      'room': 'LH-204',
      'isAttendanceTaken': false,
      'attendancePercent': 0,
    },
    {
      'id': 'SCH-03',
      'startTime': '02:00 PM',
      'endTime': '03:00 PM',
      'subjectName': 'Artificial Intelligence',
      'subjectCode': 'CS8791',
      'className': 'IV CSE - A',
      'room': 'LH-101',
      'isAttendanceTaken': false,
      'attendancePercent': 0,
    },
  ];

  static final List<Map<String, dynamic>> _defaultSubjects = [
    {
      'id': 'SUB-CS8691',
      'name': 'Machine Learning',
      'code': 'CS8691',
      'class': 'III CSE - A',
      'studentsCount': 62,
      'attendance': 91,
    },
    {
      'id': 'SUB-CS8392',
      'name': 'Data Structures',
      'code': 'CS8392',
      'class': 'II CSE - B',
      'studentsCount': 58,
      'attendance': 87,
    },
    {
      'id': 'SUB-CS8791',
      'name': 'Artificial Intelligence',
      'code': 'CS8791',
      'class': 'IV CSE - A',
      'studentsCount': 65,
      'attendance': 89,
    },
  ];

  static final List<Map<String, dynamic>> _defaultPendingWork = [
    {
      'id': 'PW-01',
      'title': 'Marks pending',
      'subtitle': 'Machine Learning • Internal 2',
      'dueDate': 'Due Sep 10',
      'priority': 'high',
      'action': 'upload_marks',
    },
    {
      'id': 'PW-02',
      'title': 'Attendance incomplete',
      'subtitle': 'Data Structures • Today',
      'dueDate': 'Due Today',
      'priority': 'urgent',
      'action': 'take_attendance',
    },
    {
      'id': 'PW-03',
      'title': 'Assignment review',
      'subtitle': 'AI Assignment 03 • 18 submissions',
      'dueDate': 'Due Sep 09',
      'priority': 'medium',
      'action': 'review_submissions',
    },
    {
      'id': 'PW-04',
      'title': 'Question paper submission',
      'subtitle': 'CS8691 • End Semester',
      'dueDate': 'Due Sep 15',
      'priority': 'low',
      'action': 'upload_qp',
    },
  ];

  static final List<Map<String, dynamic>> _defaultRecentActivities = [
    {
      'id': 'ACT-01',
      'title': 'Marks uploaded for III CSE - A',
      'timestamp': '2 hours ago',
      'type': 'marks',
      'icon': 'check_circle',
    },
    {
      'id': 'ACT-02',
      'title': 'Attendance submitted',
      'subtitle': 'Machine Learning • Period 1',
      'timestamp': '4 hours ago',
      'type': 'attendance',
      'icon': 'how_to_reg',
    },
    {
      'id': 'ACT-03',
      'title': 'Assignment published',
      'subtitle': 'AI Assignment 03',
      'timestamp': '1 day ago',
      'type': 'assignment',
      'icon': 'assignment',
    },
    {
      'id': 'ACT-04',
      'title': '12 new submissions received',
      'subtitle': 'ML Lab Exercise 4',
      'timestamp': '1 day ago',
      'type': 'submission',
      'icon': 'rate_review',
    },
  ];

  static final List<StudentModel> _defaultClassStudents = [
    StudentModel(
      studentId: '23CSE001',
      userId: 'USR-23CSE001',
      registerNumber: '23CSE001',
      fullName: 'Arun Kumar',
      rollNumber: '23CSE001',
      departmentId: 'DEPT-CSE',
      departmentName: 'Computer Science & Engineering',
      batchId: 'BATCH-2023-27',
      batch: '2023–2027',
      semester: 'Semester V',
      section: 'III CSE - A',
      admissionYear: 2023,
      cgpa: '6.4',
      attendancePercent: '68',
      academicStatus: 'At Risk',
      gender: 'Male',
      comingMode: 'Day Scholar',
    ),
    StudentModel(
      studentId: '23CSE017',
      userId: 'USR-23CSE017',
      registerNumber: '23CSE017',
      fullName: 'Karthik Raj',
      rollNumber: '23CSE017',
      departmentId: 'DEPT-CSE',
      departmentName: 'Computer Science & Engineering',
      batchId: 'BATCH-2023-27',
      batch: '2023–2027',
      semester: 'Semester V',
      section: 'III CSE - A',
      admissionYear: 2023,
      cgpa: '6.2',
      attendancePercent: '71',
      academicStatus: 'At Risk',
      gender: 'Male',
      comingMode: 'Hostel',
    ),
    StudentModel(
      studentId: '23CSE045',
      userId: 'USR-23CSE045',
      registerNumber: '23CSE045',
      fullName: 'Priya Sharma',
      rollNumber: '23CSE045',
      departmentId: 'DEPT-CSE',
      departmentName: 'Computer Science & Engineering',
      batchId: 'BATCH-2023-27',
      batch: '2023–2027',
      semester: 'Semester V',
      section: 'III CSE - A',
      admissionYear: 2023,
      cgpa: '8.8',
      attendancePercent: '76',
      academicStatus: 'Active',
      gender: 'Female',
      comingMode: 'Day Scholar',
    ),
  ];

  static final List<Map<String, dynamic>> _defaultLeaveODRequests = [
    {
      'id': 'LOD-01',
      'studentName': 'Arun Kumar',
      'studentId': '23CSE001',
      'type': 'Medical Leave',
      'duration': 'Sep 04 – Sep 05',
      'reason': 'Viral fever and doctor advice',
      'status': 'Pending',
    },
    {
      'id': 'LOD-02',
      'studentName': 'Priya Sharma',
      'studentId': '23CSE045',
      'type': 'On Duty',
      'duration': 'Sep 06',
      'reason': 'Smart India Hackathon Regional Round',
      'status': 'Pending',
    },
  ];

  /// Stream real-time leave and OD requests for a department
  Stream<List<Map<String, dynamic>>> watchDepartmentLeaveRequests(String departmentId) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value(_defaultLeaveODRequests);

    return firestore.collection('leave_requests').snapshots().map((snap) {
      if (snap.docs.isEmpty) return _defaultLeaveODRequests;
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
    }).handleError((e) {
      debugPrint('StaffRepository watchDepartmentLeaveRequests error: $e');
      return _defaultLeaveODRequests;
    });
  }

  /// Watch all staff members strictly scoped to a department and institution
  Stream<List<StaffModel>> watchStaffByDepartment(String departmentId, {String? institutionId}) {
    final firestore = _firestore;
    final cleanDept = departmentId.trim();
    final cleanInst = institutionId?.trim();
    if (firestore == null) {
      return Stream.value(_resolveDefaultStaffList(cleanDept, institutionId: cleanInst));
    }

    return firestore.collection('staff').snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return _resolveDefaultStaffList(cleanDept, institutionId: cleanInst);
      }
      final list = snap.docs
          .map((d) => StaffModel.fromMap(d.data(), d.id))
          .where((s) {
            final matchesDept = _matchesStaffDepartment(s, cleanDept);
            final matchesInst = cleanInst == null || cleanInst.isEmpty || s.institutionId == null || s.institutionId!.isEmpty || s.institutionId == cleanInst;
            return matchesDept && matchesInst;
          })
          .toList();
      return list.isNotEmpty ? list : _resolveDefaultStaffList(cleanDept, institutionId: cleanInst);
    }).handleError((e) {
      debugPrint('StaffRepository watchStaffByDepartment error: $e');
      return _resolveDefaultStaffList(cleanDept, institutionId: cleanInst);
    });
  }

  /// Watch all staff assignments for a department
  Stream<List<StaffAssignmentModel>> watchAssignmentsByDepartment(String departmentId, {String? institutionId}) {
    final firestore = _firestore;
    final cleanDept = departmentId.trim();
    final cleanInst = institutionId?.trim();
    if (firestore == null) return Stream.value(_resolveDefaultAssignments(''));

    return firestore.collection('staffAssignments').snapshots().map((snap) {
      if (snap.docs.isEmpty) return _resolveDefaultAssignments('');
      final list = snap.docs
          .map((d) => StaffAssignmentModel.fromMap(d.data(), d.id))
          .where((a) {
            final matchesDept = cleanDept.isEmpty || a.departmentId.toLowerCase().contains(cleanDept.toLowerCase());
            final matchesInst = cleanInst == null || cleanInst.isEmpty || a.institutionId == null || a.institutionId!.isEmpty || a.institutionId == cleanInst;
            return matchesDept && matchesInst;
          })
          .toList();
      return list.isNotEmpty ? list : _resolveDefaultAssignments('');
    }).handleError((e) {
      debugPrint('StaffRepository watchAssignmentsByDepartment error: $e');
      return _resolveDefaultAssignments('');
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
