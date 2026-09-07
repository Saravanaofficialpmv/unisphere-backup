class MarkModel {
  final String id;
  final String studentUid;
  final String? studentId;
  final String? registerNumber;
  final String? studentName;
  final String subjectName;
  final String? courseCode;
  final String? departmentId;
  final int obtainedMarks;
  final int totalMarks;
  final double? maximumMarks;
  final double? weightage;
  final double? convertedScore;
  final String examType;
  final String? assessmentType;
  final bool isRetest;
  final String? initialScore;
  final String? retestScore;
  final String? retestStatus;
  final String? grade;
  final String? status;
  final String? documentId;
  final String? enteredBy;
  final String? enteredByRole;
  final String? academicYear;
  final int? semester;
  final DateTime updatedAt;

  MarkModel({
    required this.id,
    required this.studentUid,
    this.studentId,
    this.registerNumber,
    this.studentName,
    required this.subjectName,
    this.courseCode,
    this.departmentId,
    required this.obtainedMarks,
    required this.totalMarks,
    this.maximumMarks,
    this.weightage,
    this.convertedScore,
    required this.examType,
    this.assessmentType,
    this.isRetest = false,
    this.initialScore,
    this.retestScore,
    this.retestStatus,
    this.grade,
    this.status,
    this.documentId,
    this.enteredBy,
    this.enteredByRole,
    this.academicYear,
    this.semester,
    required this.updatedAt,
  });

  String get regNo => registerNumber ?? studentUid;

  factory MarkModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawObt = map['obtained_marks'] ?? map['obtainedMarks'] ?? map['marks'] ?? 0;
    final rawTotal = map['total_marks'] ?? map['totalMarks'] ?? map['max'] ?? 100;

    int parseNumToInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      if (v != null) {
        final parsed = double.tryParse(v.toString().split('/')[0].trim());
        if (parsed != null) return parsed.toInt();
      }
      return fallback;
    }

    double parseNumToDouble(dynamic v, double fallback) {
      if (v is num) return v.toDouble();
      if (v != null) {
        final parsed = double.tryParse(v.toString().split('/')[0].trim());
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    final obtInt = parseNumToInt(rawObt, 0);
    final totInt = parseNumToInt(rawTotal, 100);

    return MarkModel(
      id: docId ?? map['id']?.toString() ?? map['markId']?.toString() ?? '',
      studentUid: map['student_uid'] ?? map['studentUid'] ?? map['register_number'] ?? map['registerNumber'] ?? '',
      studentId: map['studentId'] ?? map['student_id'] ?? map['studentUid'],
      registerNumber: map['register_number'] ?? map['registerNumber'] ?? map['regNo'] ?? map['student_uid'],
      studentName: map['student_name'] ?? map['studentName'] ?? map['fullName'],
      subjectName: map['subject_name'] ?? map['subjectName'] ?? map['courseName'] ?? '',
      courseCode: map['courseCode'] ?? map['course_code'] ?? map['subject_code'],
      departmentId: map['departmentId'] ?? map['department_id'],
      obtainedMarks: obtInt,
      totalMarks: totInt,
      maximumMarks: parseNumToDouble(map['maximumMarks'] ?? map['max'], totInt.toDouble()),
      weightage: (map['weightage'] as num?)?.toDouble(),
      convertedScore: (map['convertedScore'] ?? map['converted_mark'] as num?)?.toDouble(),
      examType: map['exam_type'] ?? map['examType'] ?? map['assessmentType'] ?? 'General',
      assessmentType: map['assessmentType'] ?? map['assessment_type'] ?? map['exam_type'],
      isRetest: map['isRetest'] == true || map['is_retest'] == true || map['hasIa1Retest'] == true || map['hasIa2Retest'] == true,
      initialScore: map['initialScore'] ?? map['initial_score'] ?? map['initial'],
      retestScore: map['retestScore'] ?? map['retest_score'] ?? map['retest_mark'] ?? map['retest'],
      retestStatus: map['retestStatus'] ?? map['retest_status'] ?? map['status'],
      grade: map['grade'],
      status: map['status'] ?? 'published',
      documentId: map['documentId'] ?? map['document_id'],
      enteredBy: map['enteredBy'] ?? map['entered_by'] ?? map['uploadedBy'],
      enteredByRole: map['enteredByRole'] ?? map['entered_by_role'],
      academicYear: map['academicYear'] ?? map['academic_year'],
      semester: (map['semester'] as num?)?.toInt(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_uid': studentUid,
      'studentUid': studentUid,
      if (studentId != null) 'studentId': studentId,
      if (registerNumber != null) 'register_number': registerNumber,
      if (registerNumber != null) 'registerNumber': registerNumber,
      if (registerNumber != null) 'regNo': registerNumber,
      if (studentName != null) 'student_name': studentName,
      'subject_name': subjectName,
      'subjectName': subjectName,
      if (courseCode != null) 'course_code': courseCode,
      if (courseCode != null) 'courseCode': courseCode,
      if (departmentId != null) 'department_id': departmentId,
      if (departmentId != null) 'departmentId': departmentId,
      'obtained_marks': obtainedMarks,
      'obtainedMarks': obtainedMarks,
      'total_marks': totalMarks,
      'totalMarks': totalMarks,
      if (maximumMarks != null) 'maximumMarks': maximumMarks,
      if (weightage != null) 'weightage': weightage,
      if (convertedScore != null) 'convertedScore': convertedScore,
      'exam_type': examType,
      'examType': examType,
      if (assessmentType != null) 'assessmentType': assessmentType,
      'isRetest': isRetest,
      if (initialScore != null) 'initialScore': initialScore,
      if (retestScore != null) 'retestScore': retestScore,
      if (retestStatus != null) 'retestStatus': retestStatus,
      if (grade != null) 'grade': grade,
      if (status != null) 'status': status,
      if (documentId != null) 'documentId': documentId,
      if (enteredBy != null) 'enteredBy': enteredBy,
      if (enteredByRole != null) 'enteredByRole': enteredByRole,
      if (academicYear != null) 'academicYear': academicYear,
      if (semester != null) 'semester': semester,
      'updated_at': updatedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
