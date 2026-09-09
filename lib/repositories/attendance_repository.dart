import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/attendance_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

class AttendanceRepository {
  final FirebaseFirestore? _firestore;

  AttendanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Listen to real-time attendance records for a specific student
  Stream<List<AttendanceRecord>> watchStudentAttendance(String studentUid) {
    final firestore = _firestore;
    if (studentUid.isEmpty || firestore == null) {
      return Stream.value([]);
    }
    return firestore
        .collection('attendance')
        .where('student_uid', isEqualTo: studentUid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return AttendanceRecord.fromMap(data);
            }).toList())
        .handleError((e) {
      debugPrint('Firestore attendance stream error: $e');
      return <AttendanceRecord>[];
    });
  }

  /// Fetch attendance records synchronously
  Future<List<AttendanceRecord>> getStudentAttendance(String studentUid) async {
    final firestore = _firestore;
    final cleanUid = studentUid.trim();
    if (cleanUid.isEmpty || firestore == null) return [];
    try {
      final snapshot = await firestore
          .collection('attendance')
          .where(Filter.or(
            Filter('student_uid', isEqualTo: cleanUid),
            Filter('studentUid', isEqualTo: cleanUid),
          ))
          .get();

      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AttendanceRecord.fromMap(data);
      }).toList();

      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (e) {
      debugPrint('Firestore getStudentAttendance error: $e');
      return [];
    }
  }

  /// Mark or log new attendance record
  Future<void> markAttendance(AttendanceRecord record) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore
          .collection('attendance')
          .doc(record.id)
          .set(record.toMap(), SetOptions(merge: true));

      // Asynchronously recompute and save student metrics
      updateStudentAttendanceMetrics(record.studentUid).ignore();
    } catch (e) {
      debugPrint('Firestore markAttendance error: $e');
    }
  }

  /// Batch mark attendance records for an entire session
  Future<void> markBatchAttendance(List<AttendanceRecord> records) async {
    final firestore = _firestore;
    if (firestore == null || records.isEmpty) return;

    try {
      final batch = firestore.batch();
      final affectedStudentIds = <String>{};

      for (final r in records) {
        final docRef = firestore.collection('attendance').doc(r.id);
        batch.set(docRef, r.toMap(), SetOptions(merge: true));
        if (r.studentUid.isNotEmpty) {
          affectedStudentIds.add(r.studentUid);
        }
      }

      await batch.commit();

      // Recalculate metrics for each student updated in this session
      for (final sId in affectedStudentIds) {
        updateStudentAttendanceMetrics(sId).ignore();
      }
    } catch (e) {
      debugPrint('Firestore markBatchAttendance error: $e');
    }
  }

  /// Recalculates student attendance percentage and saves to students & users collections
  Future<void> updateStudentAttendanceMetrics(String studentUid) async {
    final firestore = _firestore;
    final cleanUid = studentUid.trim();
    if (firestore == null || cleanUid.isEmpty) return;

    try {
      final records = await getStudentAttendance(cleanUid);
      if (records.isEmpty) return;

      final pct = calculateAttendancePercentage(records);
      final presentCount = records.where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.onDuty).length;
      final absentCount = records.where((r) => r.status == AttendanceStatus.absent).length;

      final updateMap = {
        'attendancePercent': '$pct%',
        'attendance': '$pct%',
        'presentCount': presentCount,
        'absentCount': absentCount,
        'totalClasses': records.length,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Update students collection by doc id
      await firestore.collection('students').doc(cleanUid).set(updateMap, SetOptions(merge: true));

      // 2. Query students collection by registerNumber / userId if doc ID wasn't matching
      final qReg = await firestore.collection('students').where('registerNumber', isEqualTo: cleanUid).get();
      for (final doc in qReg.docs) {
        await doc.reference.set(updateMap, SetOptions(merge: true));
      }

      // 3. Update student_profiles if present
      await firestore.collection('student_profiles').doc(cleanUid).set(updateMap, SetOptions(merge: true));

      // 4. Update user doc metadata
      await firestore.collection('users').doc(cleanUid).set({
        'metadata': {
          'attendance': '$pct%',
          'attendancePercent': '$pct%',
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('updateStudentAttendanceMetrics error: $e');
    }
  }

  /// Calculate real-time overall attendance percentage from raw logs
  double calculateAttendancePercentage(List<AttendanceRecord> records) {
    if (records.isEmpty) return 0.0;
    int totalClasses = records.length;
    int attendedClasses = records.where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.onDuty).length;
    return double.parse(((attendedClasses / totalClasses) * 100).toStringAsFixed(1));
  }
}
