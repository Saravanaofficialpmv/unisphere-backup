import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NptelStatus {
  pending('Pending Verification', Color(0xFFF59E0B), Icons.pending_actions_rounded),
  verified('Verified', Color(0xFF10B981), Icons.verified_rounded),
  rejected('Rejected', Color(0xFFEF4444), Icons.cancel_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const NptelStatus(this.label, this.color, this.icon);
}

class NptelCertificateModel {
  final String id;
  final String studentName;
  final String rollNo;
  final String department;
  final String courseName;
  final String courseCode;
  final String semester;
  final String academicYear;
  final String score;
  final String grade;
  final String certificateId;
  final String issueDate;
  final String fileName;
  final String fileSize;
  final DateTime uploadDate;
  String status; // 'Pending Verification', 'Verified', 'Rejected'
  String? rejectionReason;
  String? reviewedBy;
  DateTime? reviewedAt;
  final String? studentUid;
  final String? departmentId;
  final String? fileUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NptelCertificateModel({
    required this.id,
    required this.studentName,
    required this.rollNo,
    required this.department,
    required this.courseName,
    required this.courseCode,
    required this.semester,
    required this.academicYear,
    required this.score,
    required this.grade,
    required this.certificateId,
    required this.issueDate,
    required this.fileName,
    required this.fileSize,
    required this.uploadDate,
    required this.status,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    this.studentUid,
    this.departmentId,
    this.fileUrl,
    this.createdAt,
    this.updatedAt,
  });

  Color get statusColor {
    switch (status) {
      case 'Verified':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      case 'Pending Verification':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'Verified':
        return Icons.verified_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      case 'Pending Verification':
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'rollNo': rollNo,
      'department': department,
      'courseName': courseName,
      'courseCode': courseCode,
      'semester': semester,
      'academicYear': academicYear,
      'score': score,
      'grade': grade,
      'certificateId': certificateId,
      'issueDate': issueDate,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'status': status,
      'rejectionReason': rejectionReason,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'studentUid': studentUid,
      'departmentId': departmentId,
      'fileUrl': fileUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory NptelCertificateModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? (fallback ?? DateTime.now());
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return fallback ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return NptelCertificateModel(
      id: docId ?? (map['id'] as String? ?? ''),
      studentName: map['studentName'] as String? ?? '',
      rollNo: map['rollNo'] as String? ?? '',
      department: map['department'] as String? ?? '',
      courseName: map['courseName'] as String? ?? '',
      courseCode: map['courseCode'] as String? ?? '',
      semester: map['semester'] as String? ?? '',
      academicYear: map['academicYear'] as String? ?? '',
      score: map['score'] as String? ?? '',
      grade: map['grade'] as String? ?? '',
      certificateId: map['certificateId'] as String? ?? '',
      issueDate: map['issueDate'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      fileSize: map['fileSize'] as String? ?? '',
      uploadDate: parseDate(map['uploadDate']),
      status: map['status'] as String? ?? 'Pending Verification',
      rejectionReason: map['rejectionReason'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: parseNullableDate(map['reviewedAt']),
      studentUid: map['studentUid'] as String?,
      departmentId: map['departmentId'] as String?,
      fileUrl: map['fileUrl'] as String?,
      createdAt: parseNullableDate(map['createdAt']),
      updatedAt: parseNullableDate(map['updatedAt']),
    );
  }

  factory NptelCertificateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NptelCertificateModel.fromMap(data, doc.id);
  }

  NptelCertificateModel copyWith({
    String? id,
    String? studentName,
    String? rollNo,
    String? department,
    String? courseName,
    String? courseCode,
    String? semester,
    String? academicYear,
    String? score,
    String? grade,
    String? certificateId,
    String? issueDate,
    String? fileName,
    String? fileSize,
    DateTime? uploadDate,
    String? status,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? studentUid,
    String? departmentId,
    String? fileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NptelCertificateModel(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      rollNo: rollNo ?? this.rollNo,
      department: department ?? this.department,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      score: score ?? this.score,
      grade: grade ?? this.grade,
      certificateId: certificateId ?? this.certificateId,
      issueDate: issueDate ?? this.issueDate,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      uploadDate: uploadDate ?? this.uploadDate,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      studentUid: studentUid ?? this.studentUid,
      departmentId: departmentId ?? this.departmentId,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
