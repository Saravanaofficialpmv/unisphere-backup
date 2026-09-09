import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/models/syllabus_model.dart';

class SyllabusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper to extract integer start year from academic year string (e.g. "2026–2027" -> 2026)
  static int parseStartYear(String acYear) {
    final match = RegExp(r'\d{4}').firstMatch(acYear);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 2026;
    }
    return 2026;
  }

  static bool _hasClearedAllSyllabi = true;

  /// Fetch published syllabus records for students.
  /// Strictly filters out future syllabus records (effectiveStartYear > studentCurrentStartYear)
  /// and draft records (status != 'published').
  Future<List<SyllabusSubjectModel>> getStudentSyllabus({
    required String department,
    required String studentAcademicYear, // e.g. "2026–2027"
    String? year,
    String? semester,
    bool includePreviousYears = true,
  }) async {
    final studentStartYear = parseStartYear(studentAcademicYear);
    final normalizedDept = _normalizeDepartment(department);

    try {
      // Query Firestore for published syllabus records
      final snapshot = await _firestore
          .collection('syllabi')
          .where('status', isEqualTo: 'published')
          .get();

      if (_hasClearedAllSyllabi && snapshot.docs.isEmpty) {
        return [];
      }

      if (snapshot.docs.isNotEmpty) {
        final allPublished = snapshot.docs.map((doc) {
          return SyllabusSubjectModel.fromMap(doc.data(), doc.id);
        }).toList();

        final filtered = allPublished.where((s) {
          // Rule 1: Must be published
          if (!s.isPublished) return false;

          // Rule 2: SECURITY & VISIBILITY: NEVER return future syllabus
          if (s.effectiveStartYear > studentStartYear) return false;

          // Rule 3: Department check
          final matchesDept = s.department.isEmpty ||
              s.department.toLowerCase() == 'all' ||
              _normalizeDepartment(s.department) == normalizedDept;
          if (!matchesDept) return false;

          // Rule 4: Previous vs Current filtering option
          if (!includePreviousYears && s.effectiveStartYear < studentStartYear) {
            return false;
          }

          // Rule 5: Optional year/sem match
          if (year != null && year.isNotEmpty && _normalizeYear(s.year) != _normalizeYear(year)) {
            return false;
          }
          if (semester != null && semester.isNotEmpty && _normalizeSemester(s.semester) != _normalizeSemester(semester)) {
            return false;
          }

          return true;
        }).toList();

        if (filtered.isNotEmpty) {
          return filtered;
        }
      }
    } catch (e) {
      debugPrint('SyllabusService error loading from Firestore: $e');
    }

    return [];
  }

  /// Fetch HOD/Admin syllabus records (includes Current, Previous, Future, Draft, and Published).
  Future<List<SyllabusSubjectModel>> getHODAllSyllabi({
    required String department,
  }) async {
    final normalizedDept = _normalizeDepartment(department);
    try {
      final snapshot = await _firestore.collection('syllabi').get();
      if (snapshot.docs.isNotEmpty) {
        final allDocs = snapshot.docs
            .map((doc) => SyllabusSubjectModel.fromMap(doc.data(), doc.id))
            .where((s) => s.department.isEmpty || s.department.toLowerCase() == 'all' || _normalizeDepartment(s.department) == normalizedDept)
            .toList();
        if (allDocs.isNotEmpty) return allDocs;
      }
    } catch (e) {
      debugPrint('SyllabusService error loading HOD records: $e');
    }
    return [];
  }

  /// Add a new subject record to Firestore syllabi collection
  Future<bool> createSubject(SyllabusSubjectModel subject) async {
    try {
      _hasClearedAllSyllabi = false;
      final docRef = _firestore.collection('syllabi').doc(subject.id.isNotEmpty ? subject.id : null);
      final finalSubject = SyllabusSubjectModel(
        id: docRef.id,
        subjectCode: subject.subjectCode,
        subjectName: subject.subjectName,
        department: subject.department,
        applicableBatch: subject.applicableBatch,
        year: subject.year,
        semester: subject.semester,
        academicYear: subject.academicYear,
        effectiveStartYear: subject.effectiveStartYear,
        credits: subject.credits,
        subjectType: subject.subjectType,
        description: subject.description,
        units: subject.units,
        textbooks: subject.textbooks,
        referenceBooks: subject.referenceBooks,
        documentUrl: subject.documentUrl,
        documentFileName: subject.documentFileName,
        documentSize: subject.documentSize,
        effectiveFrom: subject.effectiveFrom,
        lastUpdated: DateTime.now(),
        status: subject.status,
        uploadedBy: subject.uploadedBy,
        uploadedAt: DateTime.now(),
      );

      await docRef.set(finalSubject.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('SyllabusService createSubject error: $e');
      return false;
    }
  }

  /// Update existing subject record in Firestore syllabi collection
  Future<bool> updateSubject(SyllabusSubjectModel subject) async {
    try {
      if (subject.id.isEmpty) return false;
      final updatedSubject = SyllabusSubjectModel(
        id: subject.id,
        subjectCode: subject.subjectCode,
        subjectName: subject.subjectName,
        department: subject.department,
        applicableBatch: subject.applicableBatch,
        year: subject.year,
        semester: subject.semester,
        academicYear: subject.academicYear,
        effectiveStartYear: subject.effectiveStartYear,
        credits: subject.credits,
        subjectType: subject.subjectType,
        description: subject.description,
        units: subject.units,
        textbooks: subject.textbooks,
        referenceBooks: subject.referenceBooks,
        documentUrl: subject.documentUrl,
        documentFileName: subject.documentFileName,
        documentSize: subject.documentSize,
        effectiveFrom: subject.effectiveFrom,
        lastUpdated: DateTime.now(),
        status: subject.status,
        uploadedBy: subject.uploadedBy,
        uploadedAt: subject.uploadedAt,
      );

      await _firestore.collection('syllabi').doc(subject.id).set(updatedSubject.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('SyllabusService updateSubject error: $e');
      return false;
    }
  }

  /// Delete subject record from Firestore syllabi collection
  Future<bool> deleteSubject(String subjectId) async {
    try {
      if (subjectId.isEmpty) return false;
      await _firestore.collection('syllabi').doc(subjectId).delete();
      return true;
    } catch (e) {
      debugPrint('SyllabusService deleteSubject error: $e');
      return false;
    }
  }

  /// Delete ALL syllabus records from Firestore syllabi collection (optionally for a specific department or all)
  Future<bool> deleteAllSyllabi({String? department}) async {
    try {
      _hasClearedAllSyllabi = true;
      final snapshot = await _firestore.collection('syllabi').get();
      final batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        if (department != null && department.isNotEmpty && department.toLowerCase() != 'all') {
          final docDept = (doc.data()['department'] ?? doc.data()['dept'] ?? '').toString();
          if (docDept.isEmpty || docDept.toLowerCase() == 'all' || _normalizeDepartment(docDept) == _normalizeDepartment(department)) {
            batch.delete(doc.reference);
            count++;
          }
        } else {
          batch.delete(doc.reference);
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint('SyllabusService deleteAllSyllabi error: $e');
      return false;
    }
  }

  /// Toggle or update publish status ('published' vs 'draft')
  Future<bool> updateSubjectStatus(String subjectId, String newStatus) async {
    try {
      if (subjectId.isEmpty) return false;
      await _firestore.collection('syllabi').doc(subjectId).update({
        'status': newStatus,
        'lastUpdated': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('SyllabusService updateSubjectStatus error: $e');
      return false;
    }
  }

  /// Check if a subject code already exists within the same academic year and semester for a department
  Future<bool> isDuplicateSubjectCode({
    required String subjectCode,
    required String academicYear,
    required String semester,
    required String department,
    String? currentId,
  }) async {
    try {
      final snapshot = await _firestore.collection('syllabi').get();
      final normCode = subjectCode.trim().toLowerCase();
      final normAcYear = academicYear.trim().toLowerCase();
      final normSem = _normalizeSemester(semester);
      final normDept = _normalizeDepartment(department);

      for (var doc in snapshot.docs) {
        if (currentId != null && doc.id == currentId) continue;
        final data = doc.data();
        final cCode = (data['subjectCode'] ?? data['subject_code'] ?? '').toString().trim().toLowerCase();
        final cAcYear = (data['academicYear'] ?? data['academic_year'] ?? '').toString().trim().toLowerCase();
        final cSem = _normalizeSemester((data['semester'] ?? '').toString());
        final cDept = _normalizeDepartment((data['department'] ?? '').toString());

        if (cCode == normCode && cAcYear == normAcYear && cSem == normSem && cDept == normDept) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('SyllabusService isDuplicateSubjectCode error: $e');
    }
    return false;
  }

  String _normalizeDepartment(String dept) {
    final lower = dept.toLowerCase().trim();
    if (lower.contains('cse') || lower.contains('computer science')) {
      return 'computer science & engineering';
    } else if (lower.contains('ece') || lower.contains('electronics')) {
      return 'electronics & communication engineering';
    } else if (lower.contains('eee') || lower.contains('electrical')) {
      return 'electrical & electronics engineering';
    } else if (lower.contains('mech') || lower.contains('mechanical')) {
      return 'mechanical engineering';
    } else if (lower.contains('it') || lower.contains('information tech')) {
      return 'information technology';
    }
    return lower;
  }

  String _normalizeYear(String yearStr) {
    final s = yearStr.trim().toLowerCase();
    if (s.contains('1st') || s.contains('i year') || s.contains('year 1') || s == '1' || s == 'i') {
      return 'I Year';
    } else if (s.contains('2nd') || s.contains('ii year') || s.contains('year 2') || s == '2' || s == 'ii') {
      return 'II Year';
    } else if (s.contains('3rd') || s.contains('iii year') || s.contains('year 3') || s == '3' || s == 'iii') {
      return 'III Year';
    } else if (s.contains('4th') || s.contains('iv year') || s.contains('year 4') || s == '4' || s == 'iv') {
      return 'IV Year';
    }
    return 'I Year';
  }

  String _normalizeSemester(String semStr) {
    final s = semStr.trim().toLowerCase();
    final numMatch = RegExp(r'\d+').firstMatch(s);
    if (numMatch != null) {
      return 'Semester ${numMatch.group(0)}';
    }
    return 'Semester 1';
  }

}
