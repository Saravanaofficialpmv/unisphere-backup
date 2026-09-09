import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/academic_schedule_model.dart';
import 'package:unisphere/services/activity_log_service.dart';

final academicScheduleServiceProvider = Provider<AcademicScheduleService>((ref) {
  return AcademicScheduleService();
});

class AcademicScheduleService {
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;
  final ActivityLogService _activityLogService;

  AcademicScheduleService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ActivityLogService? activityLogService,
  })  : _firestore = firestore ?? _tryGetFirestore(),
        _storage = storage ?? _tryGetStorage(),
        _activityLogService = activityLogService ?? ActivityLogService();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseStorage? _tryGetStorage() {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference get _schedulesCol =>
      _firestore!.collection('academicSchedules');

  /// Default Official Schedule Seed Models for All Academic Years (I, II, III, IV Year)
  static List<AcademicScheduleModel> getDefaultInitialSchedules() {
    return const [];
  }

  /// Upload file and publish schedule version atomically
  Future<AcademicScheduleModel?> uploadAndPublishSchedule({
    required String title,
    String description = '',
    required String academicYear, // e.g. '2026-27'
    String departmentId = 'all',
    String departmentName = 'All Departments',
    required String targetStudentYear, // e.g. 'I Year'
    String semester = 'Odd Semester',
    File? file,
    Uint8List? fileBytes,
    required String originalFileName,
    int? customFileSize,
    required String userId,
    required String userName,
    required String userRole,
    List<ScheduleEventItem> scheduleEvents = const [],
    bool publishNow = true,
  }) async {
    final firestore = _firestore;
    final storage = _storage;

    // 1. Determine file type & size
    final extension = originalFileName.split('.').last.toLowerCase();
    int fileSize = customFileSize ?? 0;
    if (fileSize == 0) {
      if (file != null && file.existsSync()) {
        fileSize = await file.length();
      } else if (fileBytes != null) {
        fileSize = fileBytes.length;
      } else {
        fileSize = 184320; // 180KB default
      }
    }

    final scheduleId = 'SCHED-${DateTime.now().millisecondsSinceEpoch}';

    int nextVersion = 1;
    AcademicScheduleModel? prevActiveModel;

    // 2. Query previous active version
    if (firestore != null) {
      try {
        QuerySnapshot prevActiveSnap = await _schedulesCol
            .where('academicYear', isEqualTo: academicYear)
            .where('targetStudentYear', isEqualTo: targetStudentYear)
            .where('departmentId', isEqualTo: departmentId)
            .where('isLatest', isEqualTo: true)
            .get();

        if (prevActiveSnap.docs.isNotEmpty) {
          final doc = prevActiveSnap.docs.first;
          prevActiveModel = AcademicScheduleModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          nextVersion = prevActiveModel.version + 1;
        } else {
          final allVersionsSnap = await _schedulesCol
              .where('academicYear', isEqualTo: academicYear)
              .where('targetStudentYear', isEqualTo: targetStudentYear)
              .where('departmentId', isEqualTo: departmentId)
              .get();
          if (allVersionsSnap.docs.isNotEmpty) {
            int maxV = 0;
            for (var d in allVersionsSnap.docs) {
              final v = (d.data() as Map<String, dynamic>)['version'] as num? ?? 0;
              if (v > maxV) maxV = v.toInt();
            }
            nextVersion = maxV + 1;
          }
        }
      } catch (e) {
        debugPrint('Query previous version notice: $e');
      }
    }

    // 3. Upload file to Firebase Storage if available
    String fileUrl = '';
    String storagePath =
        'academic_schedules/$academicYear/$departmentId/${targetStudentYear.replaceAll(' ', '_')}/$scheduleId/v$nextVersion/$originalFileName';

    if (storage != null) {
      try {
        final storageRef = storage.ref().child(storagePath);
        final metadata = SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'uploadedBy': userId,
            'academicYear': academicYear,
            'targetYear': targetStudentYear,
            'version': nextVersion.toString(),
          },
        );

        if (file != null && file.existsSync()) {
          final uploadTask = await storageRef.putFile(file, metadata);
          fileUrl = await uploadTask.ref.getDownloadURL();
        } else if (fileBytes != null && fileBytes.isNotEmpty) {
          final uploadTask = await storageRef.putData(fileBytes, metadata);
          fileUrl = await uploadTask.ref.getDownloadURL();
        }
      } catch (e) {
        debugPrint('Storage upload notice (continuing with metadata save): $e');
      }
    }

    // 4. Create new schedule model
    final newSchedule = AcademicScheduleModel(
      id: scheduleId,
      title: title,
      description: description,
      academicYear: academicYear,
      departmentId: departmentId,
      departmentName: departmentName,
      targetStudentYear: targetStudentYear,
      semester: semester,
      fileName: originalFileName,
      fileType: extension,
      fileUrl: fileUrl,
      storagePath: storagePath,
      fileSize: fileSize,
      version: nextVersion,
      status: publishNow ? ScheduleStatus.active : ScheduleStatus.draft,
      isLatest: publishNow,
      publishedAt: publishNow ? DateTime.now() : null,
      uploadedAt: DateTime.now(),
      uploadedBy: userId,
      uploadedByName: userName,
      updatedAt: DateTime.now(),
      scheduleEvents: scheduleEvents,
    );

    // 5. Atomic Batch Write: Archive old version + Create new version in Firestore
    if (firestore != null) {
      try {
        final batch = firestore.batch();

        if (publishNow) {
          final prevSnap = await _schedulesCol
              .where('academicYear', isEqualTo: academicYear)
              .where('targetStudentYear', isEqualTo: targetStudentYear)
              .where('departmentId', isEqualTo: departmentId)
              .where('isLatest', isEqualTo: true)
              .get();

          for (var doc in prevSnap.docs) {
            batch.update(doc.reference, {
              'status': ScheduleStatus.archived.name,
              'isLatest': false,
              'archivedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        batch.set(_schedulesCol.doc(scheduleId), newSchedule.toMap());
        await batch.commit();

        // 6. Log Activity
        await _activityLogService.logActivity(
          userId: userId,
          action: publishNow ? 'SCHEDULE_PUBLISHED' : 'SCHEDULE_UPLOADED',
          module: 'AcademicSchedule',
          entityId: scheduleId,
          description:
              '$userName ($userRole) published "$title" (v$nextVersion) for $targetStudentYear ($academicYear).',
          metadata: {
            'scheduleId': scheduleId,
            'version': nextVersion,
            'targetYear': targetStudentYear,
            'academicYear': academicYear,
            'fileName': originalFileName,
            'previousArchivedId': prevActiveModel?.id,
          },
        );
      } catch (e) {
        debugPrint('Firestore save notice: $e');
      }
    }

    return newSchedule;
  }

  /// Watch the single latest active schedule for a student or staff scope
  Stream<AcademicScheduleModel?> watchLatestScheduleForScope({
    required String academicYear,
    required String studentYear,
    String? departmentId,
  }) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(null);
    }

    final normalizedYear = normalizeTargetYear(studentYear);

    return _schedulesCol
        .where('status', isEqualTo: ScheduleStatus.active.name)
        .where('isLatest', isEqualTo: true)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return null;
      }

      final allActive = snap.docs
          .map((d) => AcademicScheduleModel.fromMap(
              d.data() as Map<String, dynamic>, d.id))
          .toList();

      if (allActive.isEmpty) return null;

      // 1. Look for matching student year and specific department
      if (departmentId != null && departmentId.isNotEmpty && departmentId != 'all') {
        AcademicScheduleModel? deptMatch;
        try {
          deptMatch = allActive.firstWhere(
            (s) =>
                (normalizeTargetYear(s.targetStudentYear) == normalizedYear ||
                    s.targetStudentYear == 'All Years') &&
                s.departmentId == departmentId,
          );
        } catch (_) {
          try {
            deptMatch = allActive.firstWhere(
              (s) =>
                  (normalizeTargetYear(s.targetStudentYear) == normalizedYear ||
                      s.targetStudentYear == 'All Years') &&
                  s.departmentId == 'all',
            );
          } catch (_) {
            deptMatch = allActive.first;
          }
        }
        return deptMatch;
      }

      // 2. Match student year with college-wide schedule
      try {
        return allActive.firstWhere(
          (s) =>
              normalizeTargetYear(s.targetStudentYear) == normalizedYear ||
              s.targetStudentYear == 'All Years',
        );
      } catch (_) {
        return allActive.isNotEmpty ? allActive.first : null;
      }
    }).handleError((err) {
      debugPrint('watchLatestScheduleForScope stream error: $err');
      return null;
    });
  }

  /// Watch all department schedules for HOD (includes Active, Draft, Archived)
  Stream<List<AcademicScheduleModel>> watchDepartmentSchedules({
    String departmentId = 'all',
  }) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value(const []);

    return _schedulesCol.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return const <AcademicScheduleModel>[];
      }

      final list = snap.docs
          .map((d) => AcademicScheduleModel.fromMap(
              d.data() as Map<String, dynamic>, d.id))
          .where((s) => departmentId == 'all' || s.departmentId == 'all' || s.departmentId == departmentId)
          .toList();

      if (list.isEmpty) return const <AcademicScheduleModel>[];

      // Sort: Active/Latest first, then newest publishedAt / uploadedAt
      list.sort((a, b) {
        if (a.isLatest && !b.isLatest) return -1;
        if (!a.isLatest && b.isLatest) return 1;
        return b.uploadedAt.compareTo(a.uploadedAt);
      });

      return list;
    }).handleError((err) {
      debugPrint('watchDepartmentSchedules stream error: $err');
      return const <AcademicScheduleModel>[];
    });
  }

  /// Watch version history for a specific scope (target year + academic year)
  Stream<List<AcademicScheduleModel>> watchVersionHistory({
    required String targetStudentYear,
    required String academicYear,
    String departmentId = 'all',
  }) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value(const []);

    final normalizedYear = normalizeTargetYear(targetStudentYear);

    return _schedulesCol
        .where('academicYear', isEqualTo: academicYear)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AcademicScheduleModel.fromMap(
              d.data() as Map<String, dynamic>, d.id))
          .where((s) =>
              normalizeTargetYear(s.targetStudentYear) == normalizedYear &&
              (departmentId == 'all' || s.departmentId == departmentId || s.departmentId == 'all'))
          .toList();

      list.sort((a, b) => b.version.compareTo(a.version));
      return list;
    });
  }

  /// Archive a schedule manually
  Future<bool> archiveSchedule({
    required String scheduleId,
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      await _schedulesCol.doc(scheduleId).update({
        'status': ScheduleStatus.archived.name,
        'isLatest': false,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _activityLogService.logActivity(
        userId: userId,
        action: 'SCHEDULE_ARCHIVED',
        module: 'AcademicSchedule',
        entityId: scheduleId,
        description: '$userName ($userRole) archived schedule $scheduleId.',
      );

      return true;
    } catch (e) {
      debugPrint('AcademicScheduleService archiveSchedule error: $e');
      return false;
    }
  }

  /// Delete a draft or invalid schedule
  Future<bool> deleteSchedule({
    required String scheduleId,
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final docSnap = await _schedulesCol.doc(scheduleId).get();
      if (docSnap.exists) {
        final storagePath = (docSnap.data() as Map<String, dynamic>?)?['storagePath'] as String?;
        if (storagePath != null && storagePath.isNotEmpty && _storage != null) {
          try {
            await _storage.ref().child(storagePath).delete();
          } catch (_) {}
        }
      }

      await _schedulesCol.doc(scheduleId).delete();

      await _activityLogService.logActivity(
        userId: userId,
        action: 'SCHEDULE_DELETED',
        module: 'AcademicSchedule',
        entityId: scheduleId,
        description: '$userName ($userRole) deleted schedule $scheduleId.',
      );

      return true;
    } catch (e) {
      debugPrint('AcademicScheduleService deleteSchedule error: $e');
      return false;
    }
  }



  /// Normalize year strings for fuzzy matching across user profiles
  static String normalizeTargetYear(String? raw) {
    if (raw == null || raw.isEmpty) return 'I Year';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('1') || lower.contains('first') || lower.contains('i year') || lower == 'i') {
      return 'I Year';
    }
    if (lower.contains('2') || lower.contains('second') || lower.contains('ii year') || lower == 'ii') {
      return 'II Year';
    }
    if (lower.contains('3') || lower.contains('third') || lower.contains('iii year') || lower == 'iii') {
      return 'III Year';
    }
    if (lower.contains('4') || lower.contains('fourth') || lower.contains('iv year') || lower == 'iv' || lower.contains('final')) {
      return 'IV Year';
    }
    return raw;
  }

  static String _getContentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
