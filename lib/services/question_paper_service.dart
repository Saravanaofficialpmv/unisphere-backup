import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/models/question_paper_model.dart';

class QuestionPaperService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory cache / custom uploaded list for instant responsiveness
  static final List<QuestionPaperModel> _inMemoryCustomPapers = [];

  /// Fetch question papers and question banks with filtering
  Future<List<QuestionPaperModel>> getQuestionPapers({
    String? department,
    String? semester,
    String? subjectCode,
    QuestionPaperType? paperType,
    String? regulation,
    String? examSession,
    String? searchQuery,
    bool? onlyWithAnswerKey,
  }) async {
    List<QuestionPaperModel> allPapers = [];

    try {
      final snapshot = await _firestore
          .collection('question_papers')
          .orderBy('uploadedAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        allPapers = snapshot.docs
            .map((doc) => QuestionPaperModel.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (e) {
      debugPrint('QuestionPaperService: Firestore fetch error (falling back to built-in): $e');
    }

    // Merge with in-memory custom uploads
    final combined = <String, QuestionPaperModel>{};
    for (var p in _inMemoryCustomPapers) {
      combined[p.id] = p;
    }
    for (var p in allPapers) {
      combined[p.id] = p;
    }

    var result = combined.values.toList();

    // Sort by uploadedAt descending
    result.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    // Apply Department Filter
    if (department != null &&
        department.isNotEmpty &&
        department.toLowerCase() != 'all' &&
        department.toLowerCase() != 'all departments') {
      final normDept = _normalize(department);
      result = result.where((p) {
        final pDept = _normalize(p.department);
        return pDept.contains(normDept) ||
            normDept.contains(pDept) ||
            pDept.contains('all') ||
            pDept.isEmpty;
      }).toList();
    }

    // Apply Semester Filter
    if (semester != null &&
        semester.isNotEmpty &&
        semester.toLowerCase() != 'all' &&
        semester.toLowerCase() != 'all semesters') {
      final normSem = _normalizeSemester(semester);
      result = result.where((p) => _normalizeSemester(p.semester) == normSem).toList();
    }

    // Apply Subject Code Filter
    if (subjectCode != null && subjectCode.isNotEmpty) {
      final normCode = subjectCode.trim().toLowerCase();
      result = result.where((p) => p.subjectCode.toLowerCase() == normCode).toList();
    }

    // Apply Paper Type Filter
    if (paperType != null) {
      result = result.where((p) => p.paperType == paperType).toList();
    }

    // Apply Regulation Filter
    if (regulation != null &&
        regulation.isNotEmpty &&
        regulation.toLowerCase() != 'all' &&
        regulation.toLowerCase() != 'all regulations') {
      final normReg = _normalize(regulation);
      result = result.where((p) => _normalize(p.regulation).contains(normReg)).toList();
    }

    // Apply Exam Session Filter
    if (examSession != null &&
        examSession.isNotEmpty &&
        examSession.toLowerCase() != 'all') {
      final normSession = _normalize(examSession);
      result = result.where((p) => _normalize(p.examSession).contains(normSession)).toList();
    }

    // Apply Only With Answer Key Filter
    if (onlyWithAnswerKey == true) {
      result = result.where((p) => p.hasAnswerKey).toList();
    }

    // Apply Search Query Filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.subjectCode.toLowerCase().contains(query) ||
            p.subjectName.toLowerCase().contains(query) ||
            p.department.toLowerCase().contains(query) ||
            p.examSession.toLowerCase().contains(query) ||
            p.uploadedByStaffName.toLowerCase().contains(query) ||
            p.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return result;
  }

  /// Get papers uploaded by a specific staff member
  Future<List<QuestionPaperModel>> getStaffUploadedPapers(String staffId) async {
    final all = await getQuestionPapers();
    return all.where((p) => p.uploadedByStaffId == staffId || staffId.isEmpty).toList();
  }

  /// Upload / Save a new Question Paper or Question Bank
  Future<QuestionPaperModel> uploadQuestionPaper(QuestionPaperModel paper) async {
    try {
      final docRef = _firestore.collection('question_papers').doc(paper.id.isEmpty ? null : paper.id);
      final finalId = docRef.id;
      final updatedPaper = paper.copyWith(id: finalId);

      await docRef.set(updatedPaper.toMap(), SetOptions(merge: true));

      // Cache locally
      _inMemoryCustomPapers.removeWhere((p) => p.id == finalId);
      _inMemoryCustomPapers.insert(0, updatedPaper);

      return updatedPaper;
    } catch (e) {
      debugPrint('QuestionPaperService: Firestore write error: $e. Storing in local cache.');
      final localId = paper.id.isEmpty ? 'qp_local_${DateTime.now().millisecondsSinceEpoch}' : paper.id;
      final localPaper = paper.copyWith(id: localId);
      _inMemoryCustomPapers.removeWhere((p) => p.id == localId);
      _inMemoryCustomPapers.insert(0, localPaper);
      return localPaper;
    }
  }

  /// Delete a question paper
  Future<void> deleteQuestionPaper(String id) async {
    try {
      await _firestore.collection('question_papers').doc(id).delete();
    } catch (e) {
      debugPrint('QuestionPaperService delete Firestore error: $e');
    }
    _inMemoryCustomPapers.removeWhere((p) => p.id == id);
  }

  /// Increment download count
  Future<void> incrementDownloadCount(String id) async {
    try {
      await _firestore.collection('question_papers').doc(id).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('QuestionPaperService download increment error: $e');
    }

    final index = _inMemoryCustomPapers.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = _inMemoryCustomPapers[index];
      _inMemoryCustomPapers[index] = current.copyWith(downloadCount: current.downloadCount + 1);
    }
  }

  // --- Helpers ---
  String _normalize(String val) {
    return val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _normalizeSemester(String sem) {
    final match = RegExp(r'\d+').firstMatch(sem);
    if (match != null) {
      return 'semester_${match.group(0)}';
    }
    return sem.toLowerCase().replaceAll(' ', '_');
  }

}
