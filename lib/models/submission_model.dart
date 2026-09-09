class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentUid;
  final String studentName;
  final String registerNumber;
  final String? fileName;
  final String? fileUrl;
  final String? fileType; // PDF, DOCX, ZIP, PNG, JPG
  final int? fileSizeBytes;
  final DateTime submittedAt;
  final String status; // 'Draft', 'Submitted', 'Late', 'Graded'
  final bool isGraded;
  final int? obtainedMarks;
  final String? feedback;
  final String? gradedBy;
  final DateTime? gradedAt;
  final String? submissionNotes;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentUid,
    required this.studentName,
    required this.registerNumber,
    this.fileName,
    this.fileUrl,
    this.fileType,
    this.fileSizeBytes,
    required this.submittedAt,
    this.status = 'Submitted',
    this.isGraded = false,
    this.obtainedMarks,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    this.submissionNotes,
  });

  factory SubmissionModel.fromMap(Map<String, dynamic> map) {
    return SubmissionModel(
      id: map['id']?.toString() ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
      assignmentId: map['assignment_id']?.toString() ?? map['assignmentId']?.toString() ?? '',
      studentUid: map['student_uid']?.toString() ?? map['studentUid']?.toString() ?? '',
      studentName: map['student_name']?.toString() ?? map['studentName']?.toString() ?? '',
      registerNumber: map['register_number']?.toString() ?? map['registerNumber']?.toString() ?? '',
      fileName: map['file_name']?.toString() ?? map['fileName']?.toString(),
      fileUrl: map['file_url']?.toString() ?? map['fileUrl']?.toString(),
      fileType: map['file_type']?.toString() ?? map['fileType']?.toString() ?? 'PDF',
      fileSizeBytes: map['file_size_bytes'] is int
          ? map['file_size_bytes'] as int
          : (map['fileSizeBytes'] is int ? map['fileSizeBytes'] as int : null),
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'].toString()) ?? DateTime.now()
          : (map['submittedAt'] != null ? DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now() : DateTime.now()),
      status: map['status']?.toString() ?? (map['is_graded'] == true || map['isGraded'] == true ? 'Graded' : 'Submitted'),
      isGraded: map['is_graded'] == true || map['isGraded'] == true,
      obtainedMarks: map['obtained_marks'] is int
          ? map['obtained_marks'] as int
          : (map['obtainedMarks'] is int ? map['obtainedMarks'] as int : null),
      feedback: map['feedback']?.toString(),
      gradedBy: map['graded_by']?.toString() ?? map['gradedBy']?.toString(),
      gradedAt: map['graded_at'] != null
          ? DateTime.tryParse(map['graded_at'].toString())
          : (map['gradedAt'] != null ? DateTime.tryParse(map['gradedAt'].toString()) : null),
      submissionNotes: map['submission_notes']?.toString() ?? map['submissionNotes']?.toString() ?? map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'student_uid': studentUid,
      'student_name': studentName,
      'register_number': registerNumber,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'submitted_at': submittedAt.toIso8601String(),
      'status': status,
      'is_graded': isGraded,
      'obtained_marks': obtainedMarks,
      'feedback': feedback,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
      'submission_notes': submissionNotes,
    };
  }

  SubmissionModel copyWith({
    String? status,
    bool? isGraded,
    int? obtainedMarks,
    String? feedback,
    String? gradedBy,
    DateTime? gradedAt,
    String? fileName,
    String? fileUrl,
    String? fileType,
    int? fileSizeBytes,
    DateTime? submittedAt,
    String? submissionNotes,
  }) {
    return SubmissionModel(
      id: id,
      assignmentId: assignmentId,
      studentUid: studentUid,
      studentName: studentName,
      registerNumber: registerNumber,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      isGraded: isGraded ?? this.isGraded,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      feedback: feedback ?? this.feedback,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      submissionNotes: submissionNotes ?? this.submissionNotes,
    );
  }
}
