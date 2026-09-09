import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unisphere/models/assignment_model.dart';
import 'package:unisphere/models/submission_model.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';

class AssignmentService extends ChangeNotifier {
  static final AssignmentService _instance = AssignmentService._internal();
  factory AssignmentService() => _instance;

  StreamSubscription<List<AssignmentModel>>? _subscription;
  StreamSubscription<List<SubmissionModel>>? _submissionsSubscription;

  AssignmentService._internal() {
    _connectFirestoreStream();
  }

  final List<AssignmentModel> _assignments = [];
  final List<SubmissionModel> _submissions = [];

  List<AssignmentModel> get assignments => List.unmodifiable(_assignments);
  List<SubmissionModel> get submissions => List.unmodifiable(_submissions);

  void _connectFirestoreStream() {
    try {
      final firestoreService = FirebaseFirestoreService();
      _subscription = firestoreService.getAssignments().listen(
        (list) {
          _assignments.clear();
          _assignments.addAll(list);
          notifyListeners();
        },
        onError: (e) {
          debugPrint('AssignmentService stream error: $e');
        },
      );

      _submissionsSubscription = firestoreService.getAllSubmissions().listen(
        (list) {
          _submissions.clear();
          _submissions.addAll(list);
          notifyListeners();
        },
        onError: (e) {
          debugPrint('AssignmentService submissions stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('AssignmentService connect error: $e');
    }
  }

  List<SubmissionModel> getSubmissionsForAssignment(String assignmentId) {
    return _submissions.where((s) => s.assignmentId == assignmentId).toList();
  }

  SubmissionModel? getSubmissionForStudent(String assignmentId, String studentUid) {
    try {
      return _submissions.firstWhere(
        (s) => s.assignmentId == assignmentId && s.studentUid == studentUid,
      );
    } catch (_) {
      return null;
    }
  }

  void submitAssignment(SubmissionModel submission) {
    _submissions.add(submission);
    notifyListeners();
    FirebaseFirestoreService().submitAssignment(submission);
  }

  void createAssignment(AssignmentModel assignment) {
    _assignments.insert(0, assignment);
    notifyListeners();
    FirebaseFirestoreService().createAssignment(assignment);
  }

  void addAssignment(AssignmentModel assignment) {
    createAssignment(assignment);
  }

  void saveSubmission({
    required String assignmentId,
    required String studentUid,
    required String studentName,
    required String registerNumber,
    required String fileName,
    required String fileType,
    required int fileSizeBytes,
    String? fileUrl,
    String? submissionNotes,
    required bool isFinalSubmit,
  }) {
    final index = _submissions.indexWhere(
      (s) => s.assignmentId == assignmentId && s.studentUid == studentUid,
    );

    final status = isFinalSubmit ? 'Submitted' : 'Draft';
    if (index != -1) {
      final updated = _submissions[index].copyWith(
        fileName: fileName,
        fileUrl: fileUrl ?? _submissions[index].fileUrl,
        fileType: fileType,
        fileSizeBytes: fileSizeBytes,
        submittedAt: DateTime.now(),
        status: status,
        submissionNotes: submissionNotes ?? _submissions[index].submissionNotes,
      );
      _submissions[index] = updated;
      notifyListeners();
      FirebaseFirestoreService().submitAssignment(updated);
    } else {
      final newSub = SubmissionModel(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        assignmentId: assignmentId,
        studentUid: studentUid,
        studentName: studentName,
        registerNumber: registerNumber,
        fileName: fileName,
        fileUrl: fileUrl,
        fileType: fileType,
        fileSizeBytes: fileSizeBytes,
        submittedAt: DateTime.now(),
        status: status,
        isGraded: false,
        submissionNotes: submissionNotes,
      );
      _submissions.add(newSub);
      notifyListeners();
      FirebaseFirestoreService().submitAssignment(newSub);
    }
  }

  void gradeSubmission({
    required String submissionId,
    required int marks,
    required String feedback,
    required String gradedBy,
  }) {
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index != -1) {
      final updated = _submissions[index].copyWith(
        obtainedMarks: marks,
        feedback: feedback,
        gradedBy: gradedBy,
        gradedAt: DateTime.now(),
        isGraded: true,
        status: 'Graded',
      );
      _submissions[index] = updated;
      notifyListeners();
      FirebaseFirestoreService().submitAssignment(updated);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _submissionsSubscription?.cancel();
    super.dispose();
  }
}
