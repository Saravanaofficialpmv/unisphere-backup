import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/announcement_model.dart';
import 'package:unisphere/models/assignment_model.dart';
import 'package:unisphere/models/attendance_model.dart';
import 'package:unisphere/models/exam_model.dart';
import 'package:unisphere/models/hackathon_model.dart';
import 'package:unisphere/models/mark_model.dart';
import 'package:unisphere/models/submission_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/database_seeder.dart';
import 'package:unisphere/services/supabase_service.dart';

final firebaseFirestoreServiceProvider = Provider<FirebaseFirestoreService>((ref) {
  return FirebaseFirestoreService();
});

final allStudentsStreamProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(firebaseFirestoreServiceProvider).getStudents();
});

final allTimetablesStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseFirestoreServiceProvider).getAllTimetablesStream();
});

final allAssignmentsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseFirestoreServiceProvider).getAllAssignmentsStream();
});

final allSubmissionsStreamProvider = StreamProvider.autoDispose<List<SubmissionModel>>((ref) {
  return ref.watch(firebaseFirestoreServiceProvider).getAllSubmissions();
});

final allMarksStreamProvider = StreamProvider.autoDispose<List<MarkModel>>((ref) {
  return ref.watch(firebaseFirestoreServiceProvider).getAllMarksStream();
});

class FirebaseFirestoreService implements SupabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MockSupabaseService _fallbackMock = MockSupabaseService();

  FirebaseFirestoreService();

  // ==========================================
  // ANNOUNCEMENTS
  // ==========================================
  @override
  Stream<List<AnnouncementModel>> getAnnouncements() {
    try {
      return _firestore
          .collection('announcements')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return AnnouncementModel.fromMap(data);
              }).toList())
          .handleError((error) {
        debugPrint('Firestore Announcements Error, serving fallback: $error');
        return _fallbackMock.getAnnouncements();
      });
    } catch (e) {
      debugPrint('Firestore getAnnouncements exception: $e');
      return _fallbackMock.getAnnouncements();
    }
  }

  Future<void> addAnnouncement(AnnouncementModel announcement) async {
    try {
      await _firestore.collection('announcements').doc(announcement.id).set(announcement.toMap());
    } catch (e) {
      debugPrint('Firestore addAnnouncement error: $e');
    }
  }

  Future<void> markAnnouncementRead(String announcementId, String userId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'read_by_users': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      debugPrint('Firestore markAnnouncementRead error: $e');
    }
  }

  // ==========================================
  // ASSIGNMENTS & SUBMISSIONS
  // ==========================================
  @override
  Stream<List<AssignmentModel>> getAssignments() {
    try {
      return _firestore
          .collection('assignments')
          .orderBy('due_date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return AssignmentModel.fromMap(data);
              }).toList())
          .handleError((error) {
        debugPrint('Firestore Assignments Error, serving fallback: $error');
        return _fallbackMock.getAssignments();
      });
    } catch (e) {
      return _fallbackMock.getAssignments();
    }
  }

  Future<void> createAssignment(AssignmentModel assignment) async {
    try {
      await _firestore.collection('assignments').doc(assignment.id).set(assignment.toMap());
    } catch (e) {
      debugPrint('Firestore createAssignment error: $e');
    }
  }

  @override
  Future<void> submitAssignment(SubmissionModel submission) async {
    try {
      await _firestore.collection('submissions').doc(submission.id).set(submission.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore submitAssignment exception: $e');
    }
  }

  @override
  Stream<List<SubmissionModel>> getSubmissions(String assignmentId) {
    try {
      return _firestore
          .collection('submissions')
          .where('assignment_id', isEqualTo: assignmentId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return SubmissionModel.fromMap(data);
              }).toList())
          .handleError((error) => _fallbackMock.getSubmissions(assignmentId));
    } catch (e) {
      return _fallbackMock.getSubmissions(assignmentId);
    }
  }

  Stream<List<SubmissionModel>> getAllSubmissions() {
    try {
      return _firestore
          .collection('submissions')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return SubmissionModel.fromMap(data);
              }).toList())
          .handleError((error) {
        debugPrint('Firestore getAllSubmissions error: $error');
        return <SubmissionModel>[];
      });
    } catch (e) {
      return Stream.value(<SubmissionModel>[]);
    }
  }

  Stream<List<SubmissionModel>> getStudentSubmissions(String studentUid) {
    try {
      return _firestore
          .collection('submissions')
          .where('student_uid', isEqualTo: studentUid)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return SubmissionModel.fromMap(data);
              }).toList())
          .handleError((error) {
        debugPrint('Firestore getStudentSubmissions error: $error');
        return <SubmissionModel>[];
      });
    } catch (e) {
      return Stream.value(<SubmissionModel>[]);
    }
  }

  // ==========================================
  // MARKS & GRADEBOOK
  // ==========================================
  @override
  Stream<List<MarkModel>> getMarks(String studentUid) {
    try {
      return _firestore
          .collection('marks')
          .where('student_uid', isEqualTo: studentUid)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return MarkModel.fromMap(data);
              }).toList())
          .handleError((error) => _fallbackMock.getMarks(studentUid));
    } catch (e) {
      return _fallbackMock.getMarks(studentUid);
    }
  }

  Stream<List<MarkModel>> getAllMarksStream() {
    try {
      return _firestore.collection('marks').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return MarkModel.fromMap(data);
        }).toList();
      }).handleError((error) {
        debugPrint('Firestore getAllMarksStream error: $error');
        return <MarkModel>[];
      });
    } catch (e) {
      debugPrint('Firestore getAllMarksStream exception: $e');
      return Stream.value(<MarkModel>[]);
    }
  }

  @override
  Future<void> addMarks(MarkModel mark) async {
    try {
      await _firestore.collection('marks').doc(mark.id).set(mark.toMap());
    } catch (e) {
      debugPrint('Firestore addMarks exception: $e');
    }
  }

  // ==========================================
  // ATTENDANCE & LEAVES
  // ==========================================
  @override
  Stream<List<AttendanceRecord>> getAttendance(String studentUid) {
    try {
      return _firestore
          .collection('attendance')
          .where('student_uid', isEqualTo: studentUid)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return AttendanceRecord.fromMap(data);
              }).toList())
          .handleError((error) => _fallbackMock.getAttendance(studentUid));
    } catch (e) {
      return _fallbackMock.getAttendance(studentUid);
    }
  }

  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    try {
      await _firestore.collection('attendance').doc(record.id).set(record.toMap());
    } catch (e) {
      debugPrint('Firestore addAttendanceRecord error: $e');
    }
  }

  // ==========================================
  // EXAMS
  // ==========================================
  Stream<List<ExamModel>> getExams() {
    try {
      return _firestore
          .collection('exams')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return ExamModel.fromMap(data);
              }).toList())
          .handleError((error) {
        debugPrint('Firestore Exams Stream error: $error');
        return <ExamModel>[];
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> addExam(ExamModel exam) async {
    try {
      await _firestore.collection('exams').doc(exam.id).set(exam.toMap());
    } catch (e) {
      debugPrint('Firestore addExam error: $e');
    }
  }

  // ==========================================
  // HACKATHONS
  // ==========================================
  Stream<List<HackathonModel>> getHackathons() {
    try {
      return _firestore
          .collection('hackathons')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return HackathonModel.fromMap(data);
              }).toList())
          .handleError((error) {
        debugPrint('Firestore Hackathons Stream error: $error');
        return <HackathonModel>[];
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> registerHackathonTeam(String hackathonId, Map<String, dynamic> registrationData) async {
    try {
      await _firestore
          .collection('hackathons')
          .doc(hackathonId)
          .collection('registrations')
          .add(registrationData);
      
      // Increment registered teams count
      await _firestore.collection('hackathons').doc(hackathonId).update({
        'registeredTeams': FieldValue.increment(1)
      });
    } catch (e) {
      debugPrint('Firestore registerHackathonTeam error: $e');
    }
  }
  // ==========================================
  // USERS & STUDENTS DIRECTORY
  // ==========================================
  Stream<List<UserModel>> getStudents() {
    try {
      return _firestore
          .collection('users')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .where((u) => u.role == UserRole.student)
              .toList());
    } catch (e) {
      debugPrint('Firestore getStudents error: $e');
      return Stream.value([]);
    }
  }

  Future<bool> isRegisterNumberTaken(String regNo, String currentUid) async {
    final cleanReg = regNo.trim().toLowerCase();
    if (cleanReg.isEmpty) return false;
    try {
      final snapshot = await _firestore.collection('users').get();
      for (var doc in snapshot.docs) {
        if (doc.id == currentUid) continue;
        final data = doc.data();
        final existingReg = data['metadata']?['registerNumber']?.toString().toLowerCase().trim() ?? '';
        if (existingReg == cleanReg && existingReg.isNotEmpty) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Firestore isRegisterNumberTaken error: $e');
    }
    return false;
  }

  Future<void> saveSemesterWorkingDays(int semNumber, int totalWorkingDays) async {
    try {
      await _firestore.collection('attendance_configs').doc('sem_$semNumber').set({
        'semNumber': semNumber,
        'totalWorkingDays': totalWorkingDays,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveSemesterWorkingDays error: $e');
    }
  }

  Stream<Map<int, int>> getSemesterWorkingDaysStream() {
    try {
      return _firestore.collection('attendance_configs').snapshots().map((snapshot) {
        final Map<int, int> configs = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final semNum = data['semNumber'] as int? ?? int.tryParse(doc.id.replaceAll('sem_', ''));
          final days = data['totalWorkingDays'] as int?;
          if (semNum != null && days != null) {
            configs[semNum] = days;
          }
        }
        return configs;
      });
    } catch (e) {
      debugPrint('Firestore getSemesterWorkingDaysStream error: $e');
      return Stream.value({});
    }
  }

  Future<void> saveYearSectionTimetable({
    required String year,
    required String section,
    required String fileName,
    required String fileType,
    String? fileUrl,
    List<Map<String, dynamic>>? periods,
  }) async {
    try {
      final docId = '${year.replaceAll(' ', '_')}_${section.replaceAll(' ', '_')}'.toLowerCase();
      await _firestore.collection('timetables').doc(docId).set({
        'year': year,
        'section': section,
        'fileName': fileName,
        'fileType': fileType,
        'fileUrl': fileUrl ?? '',
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': 'HOD Computer Science',
        'periods': periods ?? [],
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveYearSectionTimetable error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAllTimetablesStream() {
    try {
      return _firestore.collection('timetables').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Firestore getAllTimetablesStream error: $e');
      return Stream.value([]);
    }
  }

  Future<void> saveAssignmentMarks({
    required String title,
    required String subject,
    required String examType,
    required String fileName,
    required String fileType,
    required List<Map<String, String>> studentRecords,
  }) async {
    try {
      final docId = 'assign_${subject.replaceAll(' ', '_')}_${examType.replaceAll(' ', '_')}'.toLowerCase();
      final nowStr = DateTime.now().toIso8601String();

      await _firestore.collection('assignments').doc(docId).set({
        'title': title,
        'subject': subject,
        'examType': examType,
        'fileName': fileName,
        'fileType': fileType,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': 'Faculty Staff',
        'studentRecords': studentRecords,
      }, SetOptions(merge: true));

      // Also update individual 'marks' collection documents for student real-time streaming
      for (var record in studentRecords) {
        final regNo = record['regNo'] ?? '';
        if (regNo.isNotEmpty) {
          final markDocId = 'mark_${regNo}_$docId'.toLowerCase();
          final rawObtained = double.tryParse(record['initial']?.split('/')[0].trim() ?? '0') ?? 0;
          final rawTotal = double.tryParse(record['initial']?.split('/')[1].split(' ')[0].trim() ?? '50') ?? 50;

          await _firestore.collection('marks').doc(markDocId).set({
            'student_uid': regNo,
            'register_number': regNo,
            'subject_name': subject,
            'obtained_marks': rawObtained.toInt(),
            'total_marks': rawTotal.toInt(),
            'exam_type': examType,
            'retest_mark': record['retest'],
            'converted_mark': record['conv'],
            'status': record['status'],
            'updated_at': nowStr,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Firestore saveAssignmentMarks error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAllAssignmentsStream() {
    try {
      return _firestore.collection('assignments').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Firestore getAllAssignmentsStream error: $e');
      return Stream.value([]);
    }
  }

  // ==========================================
  // STUDENT 360° PROFILE MANAGEMENT & REG NO PERSISTENCE
  // ==========================================
  Future<void> saveStudentProfileDraft(String identifier, Map<String, dynamic> draftData) async {
    try {
      final regNo = (draftData['registerNumber'] ?? draftData['personal']?['registerNumber'])?.toString().trim() ?? '';
      final nowStr = DateTime.now().toIso8601String();
      final dataToSave = {
        ...draftData,
        'updatedAt': nowStr,
      };

      // Save under main identifier
      await _firestore.collection('student_profile_drafts').doc(identifier).set(dataToSave, SetOptions(merge: true));

      // Store under unique regNo if available
      if (regNo.isNotEmpty && regNo != identifier) {
        await _firestore.collection('student_profile_drafts').doc(regNo).set(dataToSave, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore saveStudentProfileDraft error: $e');
    }
  }

  Future<Map<String, dynamic>?> getStudentProfileDraft(String identifier) async {
    try {
      final doc = await _firestore.collection('student_profile_drafts').doc(identifier).get();
      if (doc.exists && doc.data() != null) return doc.data();

      // Fallback lookup by registerNumber
      final snap = await _firestore
          .collection('student_profile_drafts')
          .where('registerNumber', isEqualTo: identifier)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.data();
      return null;
    } catch (e) {
      debugPrint('Firestore getStudentProfileDraft error: $e');
      return null;
    }
  }

  Future<void> submitFullStudentProfile(Map<String, dynamic> profileMap) async {
    try {
      final uid = profileMap['studentUid']?.toString() ?? '';
      final regNo = (profileMap['personal']?['registerNumber'] ?? profileMap['registerNumber'])?.toString().trim() ?? '';
      final batch = (profileMap['personal']?['batch'] ?? profileMap['batch'])?.toString().trim() ?? '2023 - 2027';

      if (uid.isEmpty && regNo.isEmpty) return;

      final nowStr = DateTime.now().toIso8601String();
      profileMap['completionStatus'] = 'submitted';
      profileMap['completionPercentage'] = 100;
      profileMap['submittedAt'] = nowStr;
      profileMap['batch'] = batch;
      if (profileMap['personal'] is Map) {
        (profileMap['personal'] as Map)['batch'] = batch;
      }

      // 1. Store details under regNo in student_profiles collection (as primary unique ID)
      if (regNo.isNotEmpty) {
        await _firestore.collection('student_profiles').doc(regNo).set(profileMap, SetOptions(merge: true));
      }

      // 2. Also store details under uid for UID-based lookups
      if (uid.isNotEmpty) {
        await _firestore.collection('student_profiles').doc(uid).set(profileMap, SetOptions(merge: true));
      }

      // 3. Store details under regNo in students collection
      final fatherPhoto = profileMap['fatherPhotoUrl'] ?? profileMap['parents']?['father']?['photoUrl'];
      final motherPhoto = profileMap['motherPhotoUrl'] ?? profileMap['parents']?['mother']?['photoUrl'];

      if (regNo.isNotEmpty) {
        await _firestore.collection('students').doc(regNo).set({
          'register_number': regNo,
          'user_id': uid,
          'batch': batch,
          'details': profileMap,
          if (fatherPhoto != null && fatherPhoto.toString().isNotEmpty) 'fatherPhotoUrl': fatherPhoto,
          if (motherPhoto != null && motherPhoto.toString().isNotEmpty) 'motherPhotoUrl': motherPhoto,
          'updated_at': nowStr,
        }, SetOptions(merge: true));
      }

      // 4. Update user document profile completion status, batch & metadata
      if (uid.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set({
          'profileCompletionStatus': 'submitted',
          'batch': batch,
          if (fatherPhoto != null && fatherPhoto.toString().isNotEmpty) 'fatherPhotoUrl': fatherPhoto,
          if (motherPhoto != null && motherPhoto.toString().isNotEmpty) 'motherPhotoUrl': motherPhoto,
          'metadata': {
            'registerNumber': regNo.isNotEmpty ? regNo : null,
            'batch': batch,
            'profileCompletionPercentage': 100,
            if (fatherPhoto != null && fatherPhoto.toString().isNotEmpty) 'fatherPhotoUrl': fatherPhoto,
            if (motherPhoto != null && motherPhoto.toString().isNotEmpty) 'motherPhotoUrl': motherPhoto,
            'submittedAt': nowStr,
          }
        }, SetOptions(merge: true));
      }

      if (regNo.isNotEmpty) {
        await _firestore.collection('users').doc(regNo).set({
          'profileCompletionStatus': 'submitted',
          'batch': batch,
          if (fatherPhoto != null && fatherPhoto.toString().isNotEmpty) 'fatherPhotoUrl': fatherPhoto,
          if (motherPhoto != null && motherPhoto.toString().isNotEmpty) 'motherPhotoUrl': motherPhoto,
          'metadata': {
            'registerNumber': regNo,
            'batch': batch,
            'profileCompletionPercentage': 100,
            if (fatherPhoto != null && fatherPhoto.toString().isNotEmpty) 'fatherPhotoUrl': fatherPhoto,
            if (motherPhoto != null && motherPhoto.toString().isNotEmpty) 'motherPhotoUrl': motherPhoto,
            'submittedAt': nowStr,
          }
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore submitFullStudentProfile error: $e');
    }
  }

  Future<Map<String, dynamic>?> getFullStudentProfile(String identifier) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) return null;
    try {
      // 1. Direct lookup in student_profiles doc
      final spDoc = await _firestore.collection('student_profiles').doc(cleanId).get();
      if (spDoc.exists && spDoc.data() != null) {
        return spDoc.data();
      }

      // 2. Query student_profiles by registerNumber
      final spQuery = await _firestore.collection('student_profiles').where('registerNumber', isEqualTo: cleanId).limit(1).get();
      if (spQuery.docs.isNotEmpty) {
        return spQuery.docs.first.data();
      }

      // 3. Direct lookup in students doc
      final stDoc = await _firestore.collection('students').doc(cleanId).get();
      if (stDoc.exists && stDoc.data() != null) {
        final data = stDoc.data()!;
        if (data['details'] is Map<String, dynamic>) {
          return data['details'] as Map<String, dynamic>;
        }
        return data;
      }

      // 4. Direct lookup in users doc
      final uDoc = await _firestore.collection('users').doc(cleanId).get();
      if (uDoc.exists && uDoc.data() != null) {
        return uDoc.data();
      }
    } catch (e) {
      debugPrint('Firestore getFullStudentProfile error: $e');
    }
    return null;
  }

  Stream<Map<String, dynamic>?> getFullStudentProfileStream(String identifier) {
    try {
      return _firestore.collection('student_profiles').doc(identifier).snapshots().map((doc) {
        if (doc.exists && doc.data() != null) {
          return doc.data();
        }
        return null;
      });
    } catch (e) {
      debugPrint('Firestore getFullStudentProfileStream error: $e');
      return Stream.value(null);
    }
  }

  /// Save professional membership details (membershipId, org, hasMembership)
  /// for student directly under regNo and UID across database collections.
  Future<void> saveStudentMembershipDetails({
    required String studentUid,
    required String registerNumber,
    required bool hasMembership,
    required String membershipOrg,
    required String membershipId,
  }) async {
    try {
      final nowStr = DateTime.now().toIso8601String();
      final cleanReg = registerNumber.trim();
      final membershipData = {
        'hasMembership': hasMembership,
        'membershipOrg': membershipOrg,
        'membershipId': membershipId,
        'membershipUpdatedAt': nowStr,
      };

      // 1. Save in users collection (under uid and regNo metadata)
      if (studentUid.isNotEmpty) {
        await _firestore.collection('users').doc(studentUid).set({
          'metadata': membershipData,
        }, SetOptions(merge: true));
      }
      if (cleanReg.isNotEmpty) {
        await _firestore.collection('users').doc(cleanReg).set({
          'metadata': membershipData,
        }, SetOptions(merge: true));
      }

      // 2. Save in student_profiles collection (under regNo and studentUid)
      if (cleanReg.isNotEmpty) {
        await _firestore.collection('student_profiles').doc(cleanReg).set({
          'membership': membershipData,
          'membershipId': membershipId,
          'membershipOrg': membershipOrg,
          'hasMembership': hasMembership,
          'updatedAt': nowStr,
        }, SetOptions(merge: true));
      }
      if (studentUid.isNotEmpty) {
        await _firestore.collection('student_profiles').doc(studentUid).set({
          'membership': membershipData,
          'membershipId': membershipId,
          'membershipOrg': membershipOrg,
          'hasMembership': hasMembership,
          'updatedAt': nowStr,
        }, SetOptions(merge: true));
      }

      // 3. Save in students collection (under regNo and studentUid)
      if (cleanReg.isNotEmpty) {
        await _firestore.collection('students').doc(cleanReg).set({
          'membership_id': membershipId,
          'membership_org': membershipOrg,
          'has_membership': hasMembership,
          'updated_at': nowStr,
        }, SetOptions(merge: true));
      }
      if (studentUid.isNotEmpty) {
        await _firestore.collection('students').doc(studentUid).set({
          'membership_id': membershipId,
          'membership_org': membershipOrg,
          'has_membership': hasMembership,
          'updated_at': nowStr,
        }, SetOptions(merge: true));
      }

      debugPrint('✅ Membership details (ID: $membershipId) stored on database under regNo: "$cleanReg" / UID: "$studentUid"');
    } catch (e) {
      debugPrint('Firestore saveStudentMembershipDetails error: $e');
    }
  }

  /// Check whether the membership ID is stored on the database for a student
  /// by Registration Number (regNo) or UID.
  Future<Map<String, dynamic>> checkStudentMembershipInDatabase(String regNoOrUid) async {
    final cleanId = regNoOrUid.trim();
    if (cleanId.isEmpty) {
      return {'found': false, 'membershipId': 'N/A', 'message': 'Invalid regNo or UID'};
    }

    try {
      // 1. Check student_profiles collection under regNo doc ID
      final profileDoc = await _firestore.collection('student_profiles').doc(cleanId).get();
      if (profileDoc.exists && profileDoc.data() != null) {
        final data = profileDoc.data()!;
        final memId = data['membershipId'] ?? data['membership']?['membershipId'] ?? data['metadata']?['membershipId'];
        if (memId != null && memId.toString().isNotEmpty && memId.toString() != 'N/A') {
          return {
            'found': true,
            'source': 'student_profiles doc($cleanId)',
            'membershipId': memId.toString(),
            'membershipOrg': data['membershipOrg'] ?? data['membership']?['membershipOrg'] ?? 'ISTE',
            'hasMembership': data['hasMembership'] ?? data['membership']?['hasMembership'] ?? true,
          };
        }
      }

      // 2. Check users collection under doc(cleanId)
      final userDoc = await _firestore.collection('users').doc(cleanId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final meta = userDoc.data()!['metadata'] as Map<String, dynamic>? ?? {};
        final memId = meta['membershipId'];
        if (memId != null && memId.toString().isNotEmpty && memId.toString() != 'N/A') {
          return {
            'found': true,
            'source': 'users doc($cleanId)',
            'membershipId': memId.toString(),
            'membershipOrg': meta['membershipOrg'] ?? 'ISTE',
            'hasMembership': meta['hasMembership'] ?? true,
          };
        }
      }

      // 3. Check students collection under doc(cleanId)
      final studentDoc = await _firestore.collection('students').doc(cleanId).get();
      if (studentDoc.exists && studentDoc.data() != null) {
        final data = studentDoc.data()!;
        final memId = data['membership_id'] ?? data['membershipId'];
        if (memId != null && memId.toString().isNotEmpty && memId.toString() != 'N/A') {
          return {
            'found': true,
            'source': 'students doc($cleanId)',
            'membershipId': memId.toString(),
            'membershipOrg': data['membership_org'] ?? data['membershipOrg'] ?? 'ISTE',
            'hasMembership': data['has_membership'] ?? data['hasMembership'] ?? true,
          };
        }
      }
    } catch (e) {
      debugPrint('checkStudentMembershipInDatabase error: $e');
    }

    return {
      'found': false,
      'membershipId': 'N/A',
      'message': 'No membership record found in database for $cleanId',
    };
  }

  // ==========================================
  // PROFILE EDIT REQUESTS & CLASS ADVISOR ROUTING
  // ==========================================
  Future<void> createProfileEditRequest(Map<String, dynamic> requestMap) async {
    try {
      final reqId = requestMap['requestId']?.toString() ?? _firestore.collection('profile_edit_requests').doc().id;
      requestMap['requestId'] = reqId;
      requestMap['createdAt'] = DateTime.now().toIso8601String();
      requestMap['status'] = 'pending_advisor';

      await _firestore.collection('profile_edit_requests').doc(reqId).set(requestMap);
    } catch (e) {
      debugPrint('Firestore createProfileEditRequest error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getProfileEditRequestsStream() {
    try {
      return _firestore.collection('profile_edit_requests').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['requestId'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Firestore getProfileEditRequestsStream error: $e');
      return Stream.value([]);
    }
  }

  Future<void> processProfileEditRequest({
    required String requestId,
    required String studentUid,
    required List<Map<String, dynamic>> updatedItems,
    required String overallStatus, // approved, partially_approved, rejected
    required String advisorComments,
    required String advisorUid,
  }) async {
    try {
      final nowStr = DateTime.now().toIso8601String();

      // 1. Update request status & item approval states
      await _firestore.collection('profile_edit_requests').doc(requestId).set({
        'status': overallStatus,
        'items': updatedItems,
        'advisorComments': advisorComments,
        'assignedAdvisorId': advisorUid,
        'processedAt': nowStr,
      }, SetOptions(merge: true));

      // 2. Apply approved fields to student_profiles doc
      final approvedItems = updatedItems.where((i) => i['status'] == 'approved').toList();
      if (approvedItems.isNotEmpty) {
        final profileDocRef = _firestore.collection('student_profiles').doc(studentUid);
        final profileSnap = await profileDocRef.get();
        final profileData = profileSnap.data() ?? {};

        for (var item in approvedItems) {
          final cat = item['category']?.toString() ?? 'personal';
          final field = item['fieldName']?.toString() ?? '';
          final val = item['requestedValue']?.toString() ?? '';

          if (field.isNotEmpty) {
            if (profileData[cat] is Map) {
              (profileData[cat] as Map)[field] = val;
            } else {
              profileData[field] = val;
            }

            // Also record audit history entry
            await _firestore.collection('audit_logs').add({
              'studentUid': studentUid,
              'requestId': requestId,
              'fieldName': '$cat.$field',
              'previousValue': item['currentValue'],
              'newValue': val,
              'approvedBy': advisorUid,
              'approvedAt': nowStr,
              'changeReason': item['label'] ?? 'Class Advisor Approved Edit Request',
            });
          }
        }

        await profileDocRef.set(profileData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore processProfileEditRequest error: $e');
    }
  }

  // ==========================================
  // INITIAL DATABASE SEEDING
  // ==========================================
  Future<void> seedInitialDataIfEmpty() async {
    try {
      final annSnapshot = await _firestore
          .collection('announcements')
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      if (annSnapshot.docs.isEmpty) {
        debugPrint('Seeding initial Firestore database across all collections...');
        await DatabaseSeeder.seedAllData().timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      if (!e.toString().contains('TimeoutException')) {
        debugPrint('Firestore seedInitialDataIfEmpty notice: $e');
      }
    }
  }

  // ==========================================
  // HOD STUDENT PROFILE VERIFICATIONS
  // ==========================================
  Stream<List<Map<String, dynamic>>> getPendingHodVerificationsStream() {
    try {
      return _firestore.collection('student_profiles').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['studentUid'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Firestore getPendingHodVerificationsStream error: $e');
      return Stream.value([]);
    }
  }

  Future<void> approveStudentProfileByHod({
    required String studentUid,
    required String hodUid,
    required String hodName,
  }) async {
    try {
      final nowStr = DateTime.now().toIso8601String();

      // Update student_profiles collection under studentUid
      await _firestore.collection('student_profiles').doc(studentUid).set({
        'verificationStatus': 'approved',
        'completionStatus': 'completed',
        'verifiedAt': nowStr,
        'verifiedByHodUid': hodUid,
        'verifiedByHodName': hodName,
      }, SetOptions(merge: true));

      // Get registerNumber if studentUid is a firebase UID, or vice versa
      final profileSnap = await _firestore.collection('student_profiles').doc(studentUid).get();
      final regNo = profileSnap.data()?['registerNumber'] ?? profileSnap.data()?['personal']?['registerNumber'];
      final actualUid = profileSnap.data()?['studentUid'] ?? studentUid;

      if (regNo != null && regNo.toString().isNotEmpty) {
        await _firestore.collection('student_profiles').doc(regNo.toString()).set({
          'verificationStatus': 'approved',
          'completionStatus': 'completed',
          'verifiedAt': nowStr,
          'verifiedByHodUid': hodUid,
          'verifiedByHodName': hodName,
        }, SetOptions(merge: true));
      }

      // Update users collection
      await _firestore.collection('users').doc(actualUid.toString()).set({
        'verificationStatus': 'approved',
        'profileCompletionStatus': 'completed',
        'metadata': {
          'verifiedAt': nowStr,
          'verifiedByHodName': hodName,
        }
      }, SetOptions(merge: true));

      // Send approval notification to student
      final notifId = 'notif_appr_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('notifications').doc(notifId).set({
        'id': notifId,
        'title': 'Profile Approved 🎉',
        'body': 'Congratulations! Your 360° student profile has been verified and approved by HOD $hodName.',
        'senderId': hodUid,
        'senderName': hodName,
        'senderRole': 'hod',
        'targetRoles': ['student'],
        'recipientUserIds': [actualUid.toString()],
        'category': 'Academic',
        'priority': 'HIGH',
        'type': 'AUTOMATED',
        'createdAt': nowStr,
      });

      await _firestore.collection('notification_recipients').doc('${notifId}_${actualUid.toString()}').set({
        'id': '${notifId}_${actualUid.toString()}',
        'notificationId': notifId,
        'userId': actualUid.toString(),
        'userRole': 'student',
        'status': 'UNREAD',
        'createdAt': nowStr,
        'priority': 'HIGH',
        'category': 'Academic',
        'type': 'AUTOMATED',
      });

      await _firestore.collection('audit_logs').add({
        'actionType': 'hod_profile_verification_approval',
        'studentUid': actualUid.toString(),
        'hodUid': hodUid,
        'hodName': hodName,
        'timestamp': nowStr,
      });
    } catch (e) {
      debugPrint('Firestore approveStudentProfileByHod error: $e');
    }
  }

  Future<void> rejectStudentProfileByHod({
    required String studentUid,
    required String hodUid,
    required String hodName,
    required String reason,
  }) async {
    try {
      final nowStr = DateTime.now().toIso8601String();
      await _firestore.collection('student_profiles').doc(studentUid).set({
        'verificationStatus': 'rejected',
        'completionStatus': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': nowStr,
        'rejectedByHodUid': hodUid,
        'rejectedByHodName': hodName,
      }, SetOptions(merge: true));

      final profileSnap = await _firestore.collection('student_profiles').doc(studentUid).get();
      final regNo = profileSnap.data()?['registerNumber'] ?? profileSnap.data()?['personal']?['registerNumber'];
      final actualUid = profileSnap.data()?['studentUid'] ?? studentUid;

      if (regNo != null && regNo.toString().isNotEmpty) {
        await _firestore.collection('student_profiles').doc(regNo.toString()).set({
          'verificationStatus': 'rejected',
          'completionStatus': 'rejected',
          'rejectionReason': reason,
          'rejectedAt': nowStr,
          'rejectedByHodUid': hodUid,
          'rejectedByHodName': hodName,
        }, SetOptions(merge: true));
      }

      await _firestore.collection('users').doc(actualUid.toString()).set({
        'verificationStatus': 'rejected',
        'profileCompletionStatus': 'rejected',
        'rejectionReason': reason,
        'metadata': {
          'rejectedAt': nowStr,
          'rejectionReason': reason,
        }
      }, SetOptions(merge: true));

      // Send rejection notification to student
      final notifId = 'notif_rej_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('notifications').doc(notifId).set({
        'id': notifId,
        'title': 'Profile Verification Update ⚠️',
        'body': 'Your profile requires correction: $reason. Please update and resubmit.',
        'senderId': hodUid,
        'senderName': hodName,
        'senderRole': 'hod',
        'targetRoles': ['student'],
        'recipientUserIds': [actualUid.toString()],
        'category': 'Academic',
        'priority': 'HIGH',
        'type': 'AUTOMATED',
        'createdAt': nowStr,
      });

      await _firestore.collection('notification_recipients').doc('${notifId}_${actualUid.toString()}').set({
        'id': '${notifId}_${actualUid.toString()}',
        'notificationId': notifId,
        'userId': actualUid.toString(),
        'userRole': 'student',
        'status': 'UNREAD',
        'createdAt': nowStr,
        'priority': 'HIGH',
        'category': 'Academic',
        'type': 'AUTOMATED',
      });

      await _firestore.collection('audit_logs').add({
        'actionType': 'hod_profile_verification_rejection',
        'studentUid': actualUid.toString(),
        'hodUid': hodUid,
        'hodName': hodName,
        'reason': reason,
        'timestamp': nowStr,
      });
    } catch (e) {
      debugPrint('Firestore rejectStudentProfileByHod error: $e');
    }
  }

  // ==========================================
  // REAL-TIME ACADEMIC PERFORMANCE & MARKS UPLOADING
  // ==========================================

  /// Upload or update real-time academic performance & marks for a specific student and semester
  Future<bool> uploadStudentAcademicPerformance({
    required String regNo,
    String? studentName,
    String? department,
    String? currentYear,
    String? currentSemester,
    String? cgpa,
    String? standing,
    required int semesterIndex,
    required List<Map<String, dynamic>> subjects,
    String? sgpa,
    String? creditsCompleted,
    String? totalCredits,
  }) async {
    try {
      final cleanReg = regNo.trim().toUpperCase();
      if (cleanReg.isEmpty) return false;

      final nowStr = DateTime.now().toIso8601String();
      final docRef = _firestore.collection('academic_performance').doc(cleanReg);
      final existingDoc = await docRef.get();
      final existingData = existingDoc.data() ?? {};

      Map<String, dynamic> existingSemesters = {};
      if (existingData['semesters'] is Map) {
        existingSemesters = Map<String, dynamic>.from(existingData['semesters'] as Map);
      }

      final semKey = 'sem_$semesterIndex';
      existingSemesters[semKey] = {
        'semesterIndex': semesterIndex,
        'semesterName': 'Semester ${semesterIndex + 1}',
        'sgpa': sgpa ?? existingSemesters[semKey]?['sgpa'] ?? '9.02',
        'creditsCompleted': creditsCompleted ?? existingSemesters[semKey]?['creditsCompleted'] ?? '${24 * (semesterIndex + 1)} / 160',
        'totalCredits': totalCredits ?? '160',
        'subjects': subjects,
        'updatedAt': nowStr,
      };

      final dataToSave = {
        'regNo': cleanReg,
        'studentName': studentName ?? existingData['studentName'] ?? 'Arun Kumar',
        'department': department ?? existingData['department'] ?? 'Artificial Intelligence & Data Science',
        'currentYear': currentYear ?? existingData['currentYear'] ?? 'III Year',
        'currentSemester': currentSemester ?? existingData['currentSemester'] ?? 'Semester 6',
        'cgpa': cgpa ?? existingData['cgpa'] ?? '8.78',
        'standing': standing ?? existingData['standing'] ?? 'Top 5%',
        'semesters': existingSemesters,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSyncedAt': nowStr,
      };

      await docRef.set(dataToSave, SetOptions(merge: true));

      // Also mirror to lowercase doc if different
      if (cleanReg != regNo.trim().toLowerCase()) {
        await _firestore.collection('academic_performance').doc(regNo.trim().toLowerCase()).set(dataToSave, SetOptions(merge: true));
      }

      // Sync summary metrics to student_profiles collection
      await _firestore.collection('student_profiles').doc(cleanReg).set({
        'cgpa': cgpa ?? existingData['cgpa'] ?? '8.78',
        'academicStatus': standing ?? existingData['standing'] ?? 'First Class with Distinction',
        'departmentName': department ?? existingData['department'],
        'department': department ?? existingData['department'],
        'fullName': studentName ?? existingData['studentName'],
        'name': studentName ?? existingData['studentName'],
        'semester': currentSemester ?? existingData['currentSemester'],
        'currentYear': currentYear ?? existingData['currentYear'],
        'lastAcademicSync': nowStr,
      }, SetOptions(merge: true));

      // Update individual subject entries in 'marks' collection for individual querying
      for (final sub in subjects) {
        final subCode = (sub['code'] ?? 'SUB').toString();
        final subName = (sub['name'] ?? 'Course').toString();
        final markDocId = 'mark_${cleanReg}_${subCode}_sem$semesterIndex'.toLowerCase();

        final totInt = double.tryParse((sub['totalInternal'] ?? '').toString().split('/')[0].trim()) ?? 0;

        await _firestore.collection('marks').doc(markDocId).set({
          'student_uid': cleanReg,
          'register_number': cleanReg,
          'subject_code': subCode,
          'subject_name': subName,
          'faculty': sub['faculty'],
          'semester': semesterIndex + 1,
          'ia1': sub['ia1'],
          'ia1Conv': sub['ia1Conv'],
          'hasIa1Retest': sub['hasIa1Retest'] ?? false,
          'ia1Retest': sub['ia1Retest'],
          'ia1RetestStatus': sub['ia1RetestStatus'],
          'ia2': sub['ia2'],
          'ia2Conv': sub['ia2Conv'],
          'hasIa2Retest': sub['hasIa2Retest'] ?? false,
          'ia2Retest': sub['ia2Retest'],
          'ia2RetestStatus': sub['ia2RetestStatus'],
          'modelExam': sub['modelExam'],
          'modelConv': sub['modelConv'],
          'attAssign': sub['attAssign'],
          'totalInternal': sub['totalInternal'],
          'obtained_marks': totInt.toInt(),
          'total_marks': 60,
          'percent': sub['percent'] ?? (totInt / 60.0),
          'grade': sub['grade'] ?? 'O',
          'remarks': sub['remarks'],
          'status': sub['status'] ?? 'Live Verified in Firebase',
          'updated_at': nowStr,
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      debugPrint('Firestore uploadStudentAcademicPerformance error: $e');
      return false;
    }
  }

  /// Watch real-time stream of academic performance for a student
  Stream<Map<String, dynamic>?> watchStudentAcademicPerformanceStream(String regNo) {
    try {
      final cleanReg = regNo.trim().toUpperCase();
      if (cleanReg.isEmpty) return Stream.value(null);

      return _firestore.collection('academic_performance').doc(cleanReg).snapshots().map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        return data;
      });
    } catch (e) {
      debugPrint('Firestore watchStudentAcademicPerformanceStream error: $e');
      return Stream.value(null);
    }
  }

  /// Get one-time student academic performance document
  Future<Map<String, dynamic>?> getStudentAcademicPerformance(String regNo) async {
    try {
      final cleanReg = regNo.trim().toUpperCase();
      if (cleanReg.isEmpty) return null;

      final doc = await _firestore.collection('academic_performance').doc(cleanReg).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }

      // Fallback query by regNo or studentId
      final q = await _firestore.collection('academic_performance').where('regNo', isEqualTo: cleanReg).limit(1).get();
      if (q.docs.isNotEmpty) {
        final data = q.docs.first.data();
        data['id'] = q.docs.first.id;
        return data;
      }
    } catch (e) {
      debugPrint('Firestore getStudentAcademicPerformance error: $e');
    }
    return null;
  }

  /// Seed initial full academic performance dataset for student in Firestore
  Future<bool> seedStudentAcademicPerformanceToFirebase({
    String regNo = '922523243079',
    String studentName = 'Arun Kumar',
    String department = 'Artificial Intelligence & Data Science',
    String currentYear = 'III Year',
    String currentSemester = 'Semester 6',
    String cgpa = '8.78',
    String standing = 'Top 5%',
  }) async {
    try {
      final cleanReg = regNo.trim().toUpperCase();
      final nowStr = DateTime.now().toIso8601String();

      // Complete realistic semester 1 to 6 subjects
      final Map<String, dynamic> semesters = {
        'sem_0': {
          'semesterIndex': 0,
          'semesterName': 'Semester 1',
          'sgpa': '8.85',
          'creditsCompleted': '24 / 160',
          'totalCredits': '160',
          'subjects': [
            {
              'code': 'MA3151',
              'name': 'Matrices and Calculus',
              'faculty': 'Dr. K. Srinivasan (Maths)',
              'ia1': '46 / 50',
              'ia1Conv': '13.8 / 15',
              'ia1Initial': '46 / 50',
              'hasIa1Retest': false,
              'ia2': '44 / 50',
              'ia2Conv': '13.2 / 15',
              'ia2Initial': '44 / 50',
              'hasIa2Retest': false,
              'modelExam': '90 / 100',
              'modelConv': '18.0 / 20',
              'modelInitial': '90 / 100',
              'hasModelRetest': false,
              'attAssign': '9.5 / 10',
              'totalInternal': '54.5 / 60',
              'percent': 0.91,
              'grade': 'O (Outstanding)',
              'remarks': 'Excellent command over linear algebra and calculus applications.',
              'status': 'Finalized by Faculty',
            },
            {
              'code': 'PH3151',
              'name': 'Engineering Physics',
              'faculty': 'Dr. M. Lakshmi (Physics)',
              'ia1': '42 / 50',
              'ia1Conv': '12.6 / 15',
              'ia1Initial': '42 / 50',
              'hasIa1Retest': false,
              'ia2': '43 / 50',
              'ia2Conv': '12.9 / 15',
              'ia2Initial': '43 / 50',
              'hasIa2Retest': false,
              'modelExam': '84 / 100',
              'modelConv': '16.8 / 20',
              'modelInitial': '84 / 100',
              'hasModelRetest': false,
              'attAssign': '9.0 / 10',
              'totalInternal': '51.3 / 60',
              'percent': 0.855,
              'grade': 'A+ (Excellent)',
              'remarks': 'Good experimental skills and theory comprehension.',
              'status': 'Finalized by Faculty',
            },
            {
              'code': 'CY3151',
              'name': 'Engineering Chemistry',
              'faculty': 'Dr. P. Rajeshwari (Chemistry)',
              'ia1': '45 / 50',
              'ia1Conv': '13.5 / 15',
              'ia1Initial': '45 / 50',
              'hasIa1Retest': false,
              'ia2': '46 / 50',
              'ia2Conv': '13.8 / 15',
              'ia2Initial': '46 / 50',
              'hasIa2Retest': false,
              'modelExam': '88 / 100',
              'modelConv': '17.6 / 20',
              'modelInitial': '88 / 100',
              'hasModelRetest': false,
              'attAssign': '9.4 / 10',
              'totalInternal': '54.3 / 60',
              'percent': 0.905,
              'grade': 'O (Outstanding)',
              'remarks': 'Consistent high scores in electrochemistry and polymer modules.',
              'status': 'Finalized by Faculty',
            },
            {
              'code': 'GE3151',
              'name': 'Problem Solving and Python Programming',
              'faculty': 'Prof. K. Sundaram (CSE)',
              'ia1': '48 / 50',
              'ia1Conv': '14.4 / 15',
              'ia1Initial': '48 / 50',
              'hasIa1Retest': false,
              'ia2': '49 / 50',
              'ia2Conv': '14.7 / 15',
              'ia2Initial': '49 / 50',
              'hasIa2Retest': false,
              'modelExam': '96 / 100',
              'modelConv': '19.2 / 20',
              'modelInitial': '96 / 100',
              'hasModelRetest': false,
              'attAssign': '10.0 / 10',
              'totalInternal': '58.3 / 60',
              'percent': 0.972,
              'grade': 'O (Outstanding)',
              'remarks': 'Top performer in Python algorithmic coding and automation scripts.',
              'status': 'Finalized by Faculty',
            },
          ],
        },
        'sem_1': {
          'semesterIndex': 1,
          'semesterName': 'Semester 2',
          'sgpa': '8.65',
          'creditsCompleted': '48 / 160',
          'totalCredits': '160',
          'subjects': [
            {
              'code': 'MA3251',
              'name': 'Statistics and Numerical Methods',
              'faculty': 'Dr. K. Srinivasan (Maths)',
              'ia1': '43 / 50',
              'ia1Conv': '12.9 / 15',
              'ia1Initial': '43 / 50',
              'hasIa1Retest': false,
              'ia2': '44 / 50',
              'ia2Conv': '13.2 / 15',
              'ia2Initial': '44 / 50',
              'hasIa2Retest': false,
              'modelExam': '86 / 100',
              'modelConv': '17.2 / 20',
              'modelInitial': '86 / 100',
              'hasModelRetest': false,
              'attAssign': '9.2 / 10',
              'totalInternal': '52.5 / 60',
              'percent': 0.875,
              'grade': 'A+ (Excellent)',
              'remarks': 'Strong analytical problem solving in curve fitting and interpolation.',
              'status': 'Finalized by Faculty',
            },
            {
              'code': 'CS3251',
              'name': 'Programming in C',
              'faculty': 'Dr. S. Ramanathan (CSE)',
              'ia1': '47 / 50',
              'ia1Conv': '14.1 / 15',
              'ia1Initial': '47 / 50',
              'hasIa1Retest': false,
              'ia2': '48 / 50',
              'ia2Conv': '14.4 / 15',
              'ia2Initial': '48 / 50',
              'hasIa2Retest': false,
              'modelExam': '94 / 100',
              'modelConv': '18.8 / 20',
              'modelInitial': '94 / 100',
              'hasModelRetest': false,
              'attAssign': '9.8 / 10',
              'totalInternal': '57.1 / 60',
              'percent': 0.952,
              'grade': 'O (Outstanding)',
              'remarks': 'Excellent command over dynamic memory allocation and pointer arithmetic.',
              'status': 'Finalized by Faculty',
            },
            {
              'code': 'EC3251',
              'name': 'Basic Electrical and Electronics Engineering',
              'faculty': 'Prof. N. Mohan (ECE)',
              'ia1': '41 / 50',
              'ia1Conv': '12.3 / 15',
              'ia1Initial': '41 / 50',
              'hasIa1Retest': false,
              'ia2': '42 / 50',
              'ia2Conv': '12.6 / 15',
              'ia2Initial': '42 / 50',
              'hasIa2Retest': false,
              'modelExam': '82 / 100',
              'modelConv': '16.4 / 20',
              'modelInitial': '82 / 100',
              'hasModelRetest': false,
              'attAssign': '9.0 / 10',
              'totalInternal': '50.3 / 60',
              'percent': 0.838,
              'grade': 'A+ (Excellent)',
              'remarks': 'Active participant in circuit analysis and breadboard prototyping.',
              'status': 'Finalized by Faculty',
            },
          ],
        },
        'sem_2': {
          'semesterIndex': 2,
          'semesterName': 'Semester 3',
          'sgpa': '8.92',
          'creditsCompleted': '70 / 160',
          'totalCredits': '160',
          'subjects': [
            {
              'code': 'MA3354',
              'name': 'Discrete Mathematics',
              'faculty': 'Dr. K. Srinivasan (Maths)',
              'ia1': '45 / 50',
              'ia1Conv': '13.5 / 15',
              'ia1Initial': '45 / 50',
              'hasIa1Retest': false,
              'ia2': '47 / 50',
              'ia2Conv': '14.1 / 15',
              'ia2Initial': '47 / 50',
              'hasIa2Retest': false,
              'modelExam': '90 / 100',
              'modelConv': '18.0 / 20',
              'modelInitial': '90 / 100',
              'hasModelRetest': false,
              'attAssign': '9.5 / 10',
              'totalInternal': '55.1 / 60',
              'percent': 0.918,
              'grade': 'O (Outstanding)',
              'remarks': 'Mastery of combinatorics, predicate calculus, and recurrence relations.',
              'status': 'Finalized by Faculty',
            },
            {
              'code': 'CS3351',
              'name': 'Digital Principles & Computer Organization',
              'faculty': 'Dr. V. Rajesh (CSE)',
              'ia1': '44 / 50',
              'ia1Conv': '13.2 / 15',
              'ia1Initial': '44 / 50',
              'hasIa1Retest': false,
              'ia2': '45 / 50',
              'ia2Conv': '13.5 / 15',
              'ia2Initial': '45 / 50',
              'hasIa2Retest': false,
              'modelExam': '89 / 100',
              'modelConv': '17.8 / 20',
              'modelInitial': '89 / 100',
              'hasModelRetest': false,
              'attAssign': '9.4 / 10',
              'totalInternal': '53.9 / 60',
              'percent': 0.898,
              'grade': 'A+ (Excellent)',
              'remarks': 'Solid understanding of CPU pipelining and logic gate minimization.',
              'status': 'Finalized by Faculty',
            },
            {
              'code': 'CS3352',
              'name': 'Foundations of Data Science',
              'faculty': 'Dr. Anitha Subramanian (AI&DS)',
              'ia1': '46 / 50',
              'ia1Conv': '13.8 / 15',
              'ia1Initial': '46 / 50',
              'hasIa1Retest': false,
              'ia2': '48 / 50',
              'ia2Conv': '14.4 / 15',
              'ia2Initial': '48 / 50',
              'hasIa2Retest': false,
              'modelExam': '92 / 100',
              'modelConv': '18.4 / 20',
              'modelInitial': '92 / 100',
              'hasModelRetest': false,
              'attAssign': '9.7 / 10',
              'totalInternal': '56.3 / 60',
              'percent': 0.938,
              'grade': 'O (Outstanding)',
              'remarks': 'Impressive data exploration projects using Pandas, NumPy, and Seaborn.',
              'status': 'Finalized by Faculty',
            },
            {
              'code': 'CS3391',
              'name': 'Object Oriented Programming with Java',
              'faculty': 'Prof. K. Sundaram (CSE)',
              'ia1': '48 / 50',
              'ia1Conv': '14.4 / 15',
              'ia1Initial': '48 / 50',
              'hasIa1Retest': false,
              'ia2': '49 / 50',
              'ia2Conv': '14.7 / 15',
              'ia2Initial': '49 / 50',
              'hasIa2Retest': false,
              'modelExam': '95 / 100',
              'modelConv': '19.0 / 20',
              'modelInitial': '95 / 100',
              'hasModelRetest': false,
              'attAssign': '10.0 / 10',
              'totalInternal': '58.1 / 60',
              'percent': 0.968,
              'grade': 'O (Outstanding)',
              'remarks': 'Exceptional implementation of design patterns and multi-threaded applications.',
              'status': 'Finalized by Faculty',
            },
          ],
        },
        'sem_3': {
          'semesterIndex': 3,
          'semesterName': 'Semester 4',
          'sgpa': '9.02',
          'creditsCompleted': '92 / 160',
          'totalCredits': '160',
          'subjects': [
            {
              'code': 'CS3401',
              'name': 'Design & Analysis of Algorithms',
              'faculty': 'Dr. S. Ramanathan (CSE)',
              'ia1': '44 / 50',
              'ia1Conv': '13.2 / 15',
              'ia1Initial': '20 / 50',
              'ia1Retest': '44 / 50',
              'ia1RetestStatus': 'Retest Cleared (+24 Marks Improved)',
              'hasIa1Retest': true,
              'ia2': '46 / 50',
              'ia2Conv': '13.8 / 15',
              'ia2Initial': '46 / 50',
              'hasIa2Retest': false,
              'modelExam': '92 / 100',
              'modelConv': '18.4 / 20',
              'modelInitial': '92 / 100',
              'hasModelRetest': false,
              'attAssign': '9.8 / 10',
              'totalInternal': '55.2 / 60',
              'percent': 0.92,
              'grade': 'O (Outstanding)',
              'remarks': 'Demonstrated remarkable comeback in graph algorithms after initial test.',
              'status': 'Live Verified in Firebase',
            },
            {
              'code': 'CS3492',
              'name': 'Database Management Systems',
              'faculty': 'Prof. K. Sundaram (CSE)',
              'ia1': '42 / 50',
              'ia1Conv': '12.6 / 15',
              'ia1Initial': '42 / 50',
              'hasIa1Retest': false,
              'ia2': '45 / 50',
              'ia2Conv': '13.5 / 15',
              'ia2Initial': '45 / 50',
              'hasIa2Retest': false,
              'modelExam': '88 / 100',
              'modelConv': '17.6 / 20',
              'modelInitial': '88 / 100',
              'hasModelRetest': false,
              'attAssign': '9.2 / 10',
              'totalInternal': '52.9 / 60',
              'percent': 0.881,
              'grade': 'A+ (Excellent)',
              'remarks': 'Strong SQL query optimization skills and normal forms mastery.',
              'status': 'Live Verified in Firebase',
            },
            {
              'code': 'CS3451',
              'name': 'Operating Systems',
              'faculty': 'Dr. V. Rajesh (CSE)',
              'ia1': '41 / 50',
              'ia1Conv': '12.3 / 15',
              'ia1Initial': '41 / 50',
              'hasIa1Retest': false,
              'ia2': '43 / 50',
              'ia2Conv': '12.9 / 15',
              'ia2Initial': '43 / 50',
              'hasIa2Retest': false,
              'modelExam': '85 / 100',
              'modelConv': '17.0 / 20',
              'modelInitial': '85 / 100',
              'hasModelRetest': false,
              'attAssign': '9.0 / 10',
              'totalInternal': '51.2 / 60',
              'percent': 0.853,
              'grade': 'A+ (Excellent)',
              'remarks': 'Proficient with Linux thread synchronization and semaphore logic.',
              'status': 'Live Verified in Firebase',
            },
            {
              'code': 'CS3491',
              'name': 'Computer Networks',
              'faculty': 'Dr. Anitha Subramanian (CSE)',
              'ia1': '45 / 50',
              'ia1Conv': '13.5 / 15',
              'ia1Initial': '45 / 50',
              'hasIa1Retest': false,
              'ia2': '47 / 50',
              'ia2Conv': '14.1 / 15',
              'ia2Initial': '47 / 50',
              'hasIa2Retest': false,
              'modelExam': '90 / 100',
              'modelConv': '18.0 / 20',
              'modelInitial': '90 / 100',
              'hasModelRetest': false,
              'attAssign': '9.6 / 10',
              'totalInternal': '55.2 / 60',
              'percent': 0.92,
              'grade': 'O (Outstanding)',
              'remarks': 'Excellent packet capture analysis in Wireshark and socket programming.',
              'status': 'Live Verified in Firebase',
            },
            {
              'code': 'GE3451',
              'name': 'Environmental Sciences & Sustainability',
              'faculty': 'Dr. P. Rajeshwari (Science)',
              'ia1': '43 / 50',
              'ia1Conv': '12.9 / 15',
              'ia1Initial': '43 / 50',
              'hasIa1Retest': false,
              'ia2': '44 / 50',
              'ia2Conv': '13.2 / 15',
              'ia2Initial': '44 / 50',
              'hasIa2Retest': false,
              'modelExam': '86 / 100',
              'modelConv': '17.2 / 20',
              'modelInitial': '86 / 100',
              'hasModelRetest': false,
              'attAssign': '9.0 / 10',
              'totalInternal': '52.3 / 60',
              'percent': 0.871,
              'grade': 'A+ (Excellent)',
              'remarks': 'Punctual with sustainability case study submissions.',
              'status': 'Live Verified in Firebase',
            },
          ],
        },
        'sem_4': {
          'semesterIndex': 4,
          'semesterName': 'Semester 5',
          'sgpa': '8.95',
          'creditsCompleted': '116 / 160',
          'totalCredits': '160',
          'subjects': [
            {
              'code': 'AI3501',
              'name': 'Deep Learning & Neural Networks',
              'faculty': 'Dr. Anitha Subramanian (AI&DS)',
              'ia1': '46 / 50',
              'ia1Conv': '13.8 / 15',
              'ia1Initial': '46 / 50',
              'hasIa1Retest': false,
              'ia2': '47 / 50',
              'ia2Conv': '14.1 / 15',
              'ia2Initial': '47 / 50',
              'hasIa2Retest': false,
              'modelExam': '91 / 100',
              'modelConv': '18.2 / 20',
              'modelInitial': '91 / 100',
              'hasModelRetest': false,
              'attAssign': '9.6 / 10',
              'totalInternal': '55.7 / 60',
              'percent': 0.928,
              'grade': 'O (Outstanding)',
              'remarks': 'Excellent CNN backpropagation implementation in PyTorch.',
              'status': 'Live Verified in Firebase',
            },
            {
              'code': 'CS3591',
              'name': 'Computer Vision',
              'faculty': 'Dr. S. Ramanathan (CSE)',
              'ia1': '44 / 50',
              'ia1Conv': '13.2 / 15',
              'ia1Initial': '44 / 50',
              'hasIa1Retest': false,
              'ia2': '45 / 50',
              'ia2Conv': '13.5 / 15',
              'ia2Initial': '45 / 50',
              'hasIa2Retest': false,
              'modelExam': '88 / 100',
              'modelConv': '17.6 / 20',
              'modelInitial': '88 / 100',
              'hasModelRetest': false,
              'attAssign': '9.4 / 10',
              'totalInternal': '53.7 / 60',
              'percent': 0.895,
              'grade': 'A+ (Excellent)',
              'remarks': 'Strong real-time edge detection and OpenCV project work.',
              'status': 'Live Verified in Firebase',
            },
          ],
        },
        'sem_5': {
          'semesterIndex': 5,
          'semesterName': 'Semester 6',
          'sgpa': '9.10',
          'creditsCompleted': '140 / 160',
          'totalCredits': '160',
          'subjects': [
            {
              'code': 'CS3601',
              'name': 'Cloud Computing & Serverless',
              'faculty': 'Dr. V. Rajesh (CSE)',
              'ia1': '45 / 50',
              'ia1Conv': '13.5 / 15',
              'ia1Initial': '45 / 50',
              'hasIa1Retest': false,
              'ia2': '46 / 50',
              'ia2Conv': '13.8 / 15',
              'ia2Initial': '46 / 50',
              'hasIa2Retest': false,
              'modelExam': '90 / 100',
              'modelConv': '18.0 / 20',
              'modelInitial': '90 / 100',
              'hasModelRetest': false,
              'attAssign': '9.6 / 10',
              'totalInternal': '54.9 / 60',
              'percent': 0.915,
              'grade': 'O (Outstanding)',
              'remarks': 'Proficient with Docker container orchestration and cloud architecture.',
              'status': 'Live Verified in Firebase',
            },
            {
              'code': 'CS3602',
              'name': 'Software Engineering & DevOps',
              'faculty': 'Prof. K. Sundaram (CSE)',
              'ia1': '46 / 50',
              'ia1Conv': '13.8 / 15',
              'ia1Initial': '46 / 50',
              'hasIa1Retest': false,
              'ia2': '47 / 50',
              'ia2Conv': '14.1 / 15',
              'ia2Initial': '47 / 50',
              'hasIa2Retest': false,
              'modelExam': '92 / 100',
              'modelConv': '18.4 / 20',
              'modelInitial': '92 / 100',
              'hasModelRetest': false,
              'attAssign': '9.7 / 10',
              'totalInternal': '56.0 / 60',
              'percent': 0.933,
              'grade': 'O (Outstanding)',
              'remarks': 'Clean CI/CD automated pipeline scripting and agile sprint planning.',
              'status': 'Live Verified in Firebase',
            },
          ],
        },
      };

      final dataDoc = {
        'regNo': cleanReg,
        'studentName': studentName,
        'department': department,
        'currentYear': currentYear,
        'currentSemester': currentSemester,
        'cgpa': cgpa,
        'standing': standing,
        'semesters': semesters,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSyncedAt': nowStr,
      };

      await _firestore.collection('academic_performance').doc(cleanReg).set(dataDoc, SetOptions(merge: true));
      await _firestore.collection('academic_performance').doc(cleanReg.toLowerCase()).set(dataDoc, SetOptions(merge: true));

      // Also update student_profiles
      await _firestore.collection('student_profiles').doc(cleanReg).set({
        'registerNumber': cleanReg,
        'fullName': studentName,
        'name': studentName,
        'department': department,
        'departmentName': department,
        'currentYear': currentYear,
        'semester': currentSemester,
        'cgpa': cgpa,
        'academicStatus': standing,
        'lastAcademicSync': nowStr,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Firestore seedStudentAcademicPerformanceToFirebase error: $e');
      return false;
    }
  }
}

