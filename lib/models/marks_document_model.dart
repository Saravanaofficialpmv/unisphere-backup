class MarksDocumentModel {
  final String documentId;
  final String institutionId;
  final String departmentId;
  final String departmentName;
  final String subjectId;
  final String courseCode;
  final String subjectName;
  final String? examId;
  final String assessmentType; // 'internal_1', 'internal_2', 'model', 'retest', 'assignment', 'final_semester'
  final String academicYear;
  final int semester;
  final String uploadedBy; // User UID
  final String uploadedByRole; // 'staff' or 'hod'
  final String uploadedByName;
  final String fileName;
  final String fileType; // 'xlsx', 'csv', 'pdf'
  final int fileSize; // bytes
  final String storagePath;
  final String processingStatus; // 'uploaded', 'processing', 'completed', 'failed'
  final String validationStatus; // 'valid', 'has_errors', 'rejected'
  final int recordCount;
  final int successCount;
  final int errorCount;
  final List<Map<String, dynamic>> validationErrors;
  final String approvalStatus; // 'Pending Verification', 'Approved', 'Rejected'
  final bool isPublished;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? publishedAt;
  final String? publishedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MarksDocumentModel({
    required this.documentId,
    this.institutionId = 'default_institution',
    required this.departmentId,
    this.departmentName = 'Computer Science & Engineering',
    required this.subjectId,
    required this.courseCode,
    required this.subjectName,
    this.examId,
    required this.assessmentType,
    this.academicYear = '2025–26',
    required this.semester,
    required this.uploadedBy,
    required this.uploadedByRole,
    required this.uploadedByName,
    required this.fileName,
    required this.fileType,
    this.fileSize = 0,
    required this.storagePath,
    this.processingStatus = 'uploaded',
    this.validationStatus = 'valid',
    this.approvalStatus = 'Pending Verification',
    this.isPublished = false,
    this.approvedBy,
    this.approvedAt,
    this.publishedAt,
    this.publishedBy,
    this.recordCount = 0,
    this.successCount = 0,
    this.errorCount = 0,
    this.validationErrors = const [],
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const String typeFinalSemester = 'final_semester';
  static const String typeInternal1 = 'internal_1';
  static const String typeInternal2 = 'internal_2';
  static const String typeModel = 'model';
  static const String typeRetest = 'retest';
  static const String typeAssignment = 'assignment';

  bool get isFinalSemester => assessmentType.toLowerCase() == 'final_semester';
  bool get hasErrors => errorCount > 0 || validationErrors.isNotEmpty;
  int get validRecordsCount => successCount;
  bool get isApproved => approvalStatus.toLowerCase() == 'approved';
  bool get isPendingApproval => approvalStatus.toLowerCase().contains('pending');

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'document_id': documentId,
      'institutionId': institutionId,
      'institution_id': institutionId,
      'departmentId': departmentId,
      'department_id': departmentId,
      'departmentName': departmentName,
      'department_name': departmentName,
      'subjectId': subjectId,
      'subject_id': subjectId,
      'courseCode': courseCode,
      'course_code': courseCode,
      'subjectName': subjectName,
      'subject_name': subjectName,
      if (examId != null) 'examId': examId,
      if (examId != null) 'exam_id': examId,
      'assessmentType': assessmentType,
      'assessment_type': assessmentType,
      'academicYear': academicYear,
      'academic_year': academicYear,
      'semester': semester,
      'uploadedBy': uploadedBy,
      'uploaded_by': uploadedBy,
      'uploadedByRole': uploadedByRole,
      'uploaded_by_role': uploadedByRole,
      'uploadedByName': uploadedByName,
      'uploaded_name': uploadedByName,
      'fileName': fileName,
      'file_name': fileName,
      'fileType': fileType,
      'file_type': fileType,
      'fileSize': fileSize,
      'file_size': fileSize,
      'storagePath': storagePath,
      'storage_path': storagePath,
      'processingStatus': processingStatus,
      'processing_status': processingStatus,
      'validationStatus': validationStatus,
      'validation_status': validationStatus,
      'approvalStatus': approvalStatus,
      'approval_status': approvalStatus,
      'isPublished': isPublished,
      'is_published': isPublished,
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
      if (publishedBy != null) 'publishedBy': publishedBy,
      if (publishedBy != null) 'published_by': publishedBy,
      'recordCount': recordCount,
      'record_count': recordCount,
      'successCount': successCount,
      'success_count': successCount,
      'errorCount': errorCount,
      'error_count': errorCount,
      'validationErrors': validationErrors,
      'validation_errors': validationErrors,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String() ?? createdAt.toIso8601String(),
    };
  }

  factory MarksDocumentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      try {
        final dynamic dyn = val;
        if (dyn.toDate is Function) return dyn.toDate() as DateTime;
      } catch (_) {}
      return DateTime.tryParse(val.toString());
    }

    final rawErrors = map['validationErrors'] ?? map['validation_errors'] ?? [];
    List<Map<String, dynamic>> errorsList = [];
    if (rawErrors is List) {
      for (final e in rawErrors) {
        if (e is Map) {
          errorsList.add(Map<String, dynamic>.from(e));
        }
      }
    }

    final rawPublished = map['isPublished'] ?? map['is_published'];
    final bool parsedPublished = rawPublished is bool
        ? rawPublished
        : (rawPublished?.toString().toLowerCase() == 'true');

    return MarksDocumentModel(
      documentId: id,
      institutionId: map['institutionId'] ?? map['institution_id'] ?? 'default_institution',
      departmentId: map['departmentId'] ?? map['department_id'] ?? 'DEP-CSE',
      departmentName: map['departmentName'] ?? map['department_name'] ?? 'Computer Science & Engineering',
      subjectId: map['subjectId'] ?? map['subject_id'] ?? map['courseCode'] ?? '',
      courseCode: map['courseCode'] ?? map['course_code'] ?? map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? map['subject_name'] ?? 'Course Subject',
      examId: map['examId'] ?? map['exam_id'],
      assessmentType: map['assessmentType'] ?? map['assessment_type'] ?? 'internal_1',
      academicYear: map['academicYear'] ?? map['academic_year'] ?? '2025–26',
      semester: (map['semester'] as num?)?.toInt() ?? 6,
      uploadedBy: map['uploadedBy'] ?? map['uploaded_by'] ?? '',
      uploadedByRole: map['uploadedByRole'] ?? map['uploaded_by_role'] ?? 'staff',
      uploadedByName: map['uploadedByName'] ?? map['uploaded_name'] ?? 'Faculty Member',
      fileName: map['fileName'] ?? map['file_name'] ?? 'marks_document.xlsx',
      fileType: map['fileType'] ?? map['file_type'] ?? 'xlsx',
      fileSize: (map['fileSize'] ?? map['file_size'] as num?)?.toInt() ?? 0,
      storagePath: map['storagePath'] ?? map['storage_path'] ?? '',
      processingStatus: map['processingStatus'] ?? map['processing_status'] ?? 'uploaded',
      validationStatus: map['validationStatus'] ?? map['validation_status'] ?? 'valid',
      approvalStatus: map['approvalStatus'] ?? map['approval_status'] ?? 'Pending Verification',
      isPublished: parsedPublished,
      approvedBy: map['approvedBy'] ?? map['approved_by'],
      approvedAt: parseDate(map['approvedAt'] ?? map['approved_at']),
      publishedAt: parseDate(map['publishedAt'] ?? map['published_at']),
      publishedBy: map['publishedBy'] ?? map['published_by'],
      recordCount: (map['recordCount'] ?? map['record_count'] as num?)?.toInt() ?? 0,
      successCount: (map['successCount'] ?? map['success_count'] as num?)?.toInt() ?? 0,
      errorCount: (map['errorCount'] ?? map['error_count'] as num?)?.toInt() ?? 0,
      validationErrors: errorsList,
      createdAt: parseDate(map['createdAt'] ?? map['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt'] ?? map['updated_at']),
    );
  }

  MarksDocumentModel copyWith({
    String? processingStatus,
    String? validationStatus,
    String? approvalStatus,
    bool? isPublished,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? publishedAt,
    String? publishedBy,
    int? recordCount,
    int? successCount,
    int? errorCount,
    List<Map<String, dynamic>>? validationErrors,
    DateTime? updatedAt,
  }) {
    return MarksDocumentModel(
      documentId: documentId,
      institutionId: institutionId,
      departmentId: departmentId,
      departmentName: departmentName,
      subjectId: subjectId,
      courseCode: courseCode,
      subjectName: subjectName,
      examId: examId,
      assessmentType: assessmentType,
      academicYear: academicYear,
      semester: semester,
      uploadedBy: uploadedBy,
      uploadedByRole: uploadedByRole,
      uploadedByName: uploadedByName,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      storagePath: storagePath,
      processingStatus: processingStatus ?? this.processingStatus,
      validationStatus: validationStatus ?? this.validationStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isPublished: isPublished ?? this.isPublished,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedBy: publishedBy ?? this.publishedBy,
      recordCount: recordCount ?? this.recordCount,
      successCount: successCount ?? this.successCount,
      errorCount: errorCount ?? this.errorCount,
      validationErrors: validationErrors ?? this.validationErrors,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
