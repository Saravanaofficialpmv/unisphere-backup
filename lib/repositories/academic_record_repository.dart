import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/models/academic_record_model.dart';

/// Repository responsible for reading and writing strongly-typed AcademicRecords in Cloud Firestore.
/// Follows the multi-institution scalable structure:
/// institutions/{institutionId}/students/{studentId}/academic_records/{recordId}
class AcademicRecordRepository {
  final FirebaseFirestore? _customFirestore;

  AcademicRecordRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _getAcademicRecordsRef({
    required String institutionId,
    required String studentId,
  }) {
    final cleanInst = institutionId.trim().isEmpty ? 'default_institution' : institutionId.trim();
    final cleanStu = studentId.trim();
    return _firestore
        .collection('institutions')
        .doc(cleanInst)
        .collection('students')
        .doc(cleanStu)
        .collection('academic_records');
  }

  /// Watch real-time stream of academic records for a student across all semesters
  Stream<List<AcademicRecord>> watchStudentAcademicRecords({
    required String studentId,
    String institutionId = 'default_institution',
  }) {
    final cleanStu = studentId.trim();
    if (cleanStu.isEmpty) return Stream.value([]);

    final primaryRef = _getAcademicRecordsRef(
      institutionId: institutionId,
      studentId: cleanStu,
    );

    return primaryRef.snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => AcademicRecord.fromFirestore(doc)).toList()
          ..sort((a, b) {
            final semComp = a.semester.compareTo(b.semester);
            if (semComp != 0) return semComp;
            return a.courseCode.compareTo(b.courseCode);
          });
      }

      // Fallback lookup: Check legacy 'academic_performance/{studentId}' or collection 'marks'
      try {
        final legacyDoc = await _firestore.collection('academic_performance').doc(cleanStu.toUpperCase()).get();
        if (legacyDoc.exists && legacyDoc.data() != null) {
          final data = legacyDoc.data()!;
          final List<AcademicRecord> records = [];
          if (data['semesters'] is Map) {
            final semMap = data['semesters'] as Map;
            semMap.forEach((semKey, semVal) {
              if (semVal is Map && semVal['subjects'] is List) {
                final int semIdx = (semVal['semesterIndex'] as num?)?.toInt() ?? 5;
                final subjectsList = semVal['subjects'] as List;
                for (final s in subjectsList) {
                  if (s is Map) {
                    final raw = Map<String, dynamic>.from(s);
                    raw['studentId'] = cleanStu;
                    raw['institutionId'] = institutionId;
                    raw['semester'] = semIdx + 1;
                    records.add(AcademicRecord.fromMap(raw));
                  }
                }
              }
            });
          }
          if (records.isNotEmpty) {
            return records;
          }
        }
      } catch (e) {
        debugPrint('Fallback academic_performance lookup error: $e');
      }

      return <AcademicRecord>[];
    });
  }

  /// One-time fetch of academic records for a student
  Future<List<AcademicRecord>> getStudentAcademicRecords({
    required String studentId,
    String institutionId = 'default_institution',
  }) async {
    final cleanStu = studentId.trim();
    if (cleanStu.isEmpty) return [];

    final primaryRef = _getAcademicRecordsRef(
      institutionId: institutionId,
      studentId: cleanStu,
    );

    try {
      final snap = await primaryRef.get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((doc) => AcademicRecord.fromFirestore(doc)).toList();
      }

      // Legacy fallback
      final legacyDoc = await _firestore.collection('academic_performance').doc(cleanStu.toUpperCase()).get();
      if (legacyDoc.exists && legacyDoc.data() != null) {
        final data = legacyDoc.data()!;
        final List<AcademicRecord> records = [];
        if (data['semesters'] is Map) {
          final semMap = data['semesters'] as Map;
          semMap.forEach((semKey, semVal) {
            if (semVal is Map && semVal['subjects'] is List) {
              final int semIdx = (semVal['semesterIndex'] as num?)?.toInt() ?? 5;
              final subjectsList = semVal['subjects'] as List;
              for (final s in subjectsList) {
                if (s is Map) {
                  final raw = Map<String, dynamic>.from(s);
                  raw['studentId'] = cleanStu;
                  raw['institutionId'] = institutionId;
                  raw['semester'] = semIdx + 1;
                  records.add(AcademicRecord.fromMap(raw));
                }
              }
            }
          });
        }
        return records;
      }
    } catch (e) {
      debugPrint('Error getting student academic records: $e');
    }
    return [];
  }

  /// Save or update a single academic record in Firestore
  Future<bool> saveAcademicRecord(AcademicRecord record) async {
    try {
      final ref = _getAcademicRecordsRef(
        institutionId: record.institutionId,
        studentId: record.studentId,
      );

      final docId = record.id.trim().isNotEmpty
          ? record.id.trim()
          : '${record.courseCode.toUpperCase()}_sem${record.semester}'.toLowerCase();

      await ref.doc(docId).set(record.toFirestore(), SetOptions(merge: true));

      // Also sync to global academic_records collection & marks collection for backward compatibility
      await _syncToGlobalCollections(record, docId);

      return true;
    } catch (e) {
      debugPrint('Error saving academic record: $e');
      return false;
    }
  }

  /// Batch save multiple academic records efficiently in a single Firestore transaction
  Future<bool> batchSaveAcademicRecords(List<AcademicRecord> records) async {
    if (records.isEmpty) return true;

    try {
      final batch = _firestore.batch();

      for (final record in records) {
        final ref = _getAcademicRecordsRef(
          institutionId: record.institutionId,
          studentId: record.studentId,
        );

        final docId = record.id.trim().isNotEmpty
            ? record.id.trim()
            : '${record.courseCode.toUpperCase()}_sem${record.semester}'.toLowerCase();

        batch.set(ref.doc(docId), record.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();

      // Background sync to legacy structures
      for (final r in records) {
        final docId = r.id.trim().isNotEmpty ? r.id.trim() : '${r.courseCode.toUpperCase()}_sem${r.semester}'.toLowerCase();
        _syncToGlobalCollections(r, docId).ignore();
      }

      return true;
    } catch (e) {
      debugPrint('Error batch saving academic records: $e');
      return false;
    }
  }

  /// Delete an academic record
  Future<bool> deleteAcademicRecord({
    required String institutionId,
    required String studentId,
    required String recordId,
  }) async {
    try {
      final ref = _getAcademicRecordsRef(
        institutionId: institutionId,
        studentId: studentId,
      );
      await ref.doc(recordId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting academic record: $e');
      return false;
    }
  }

  Future<void> _syncToGlobalCollections(AcademicRecord record, String docId) async {
    try {
      // 1. Sync to top-level marks collection
      final cleanReg = record.studentId.trim().toUpperCase();
      final markDocId = 'mark_${cleanReg}_${record.courseCode}_sem${record.semester}'.toLowerCase();

      await _firestore.collection('marks').doc(markDocId).set({
        'student_uid': cleanReg,
        'register_number': cleanReg,
        'subject_code': record.courseCode,
        'subject_name': record.courseName,
        'faculty': record.facultyName,
        'semester': record.semester,
        'ia1': record.ia1?.displayRaw ?? '44 / 50',
        'ia1Conv': record.ia1?.displayConverted ?? '13.2 / 15',
        'hasIa1Retest': record.ia1?.isRetest ?? false,
        'ia1Retest': record.ia1?.retestScore,
        'ia1RetestStatus': record.ia1?.retestStatus,
        'ia2': record.ia2?.displayRaw ?? '46 / 50',
        'ia2Conv': record.ia2?.displayConverted ?? '13.8 / 15',
        'hasIa2Retest': record.ia2?.isRetest ?? false,
        'ia2Retest': record.ia2?.retestScore,
        'ia2RetestStatus': record.ia2?.retestStatus,
        'modelExam': record.modelExam?.displayRaw ?? '92 / 100',
        'modelConv': record.modelExam?.displayConverted ?? '18.4 / 20',
        'attAssign': record.attendance?.displayConverted ?? '9.8 / 10',
        'totalInternal': record.internalMarks.display,
        'obtained_marks': record.internalMarks.obtained.toInt(),
        'total_marks': record.internalMarks.max.toInt(),
        'percent': record.internalMarks.percent,
        'grade': record.grade,
        'remarks': record.remarks,
        'status': record.status,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
