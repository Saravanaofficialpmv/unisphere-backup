import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffAssignmentType {
  subjectFaculty,
  classAdvisor,
  departmentResponsibility,
  examResponsibility,
  committee,
}

extension StaffAssignmentTypeExtension on StaffAssignmentType {
  String get value {
    switch (this) {
      case StaffAssignmentType.subjectFaculty:
        return 'subject_faculty';
      case StaffAssignmentType.classAdvisor:
        return 'class_advisor';
      case StaffAssignmentType.departmentResponsibility:
        return 'department_responsibility';
      case StaffAssignmentType.examResponsibility:
        return 'exam_responsibility';
      case StaffAssignmentType.committee:
        return 'committee';
    }
  }

  String get displayName {
    switch (this) {
      case StaffAssignmentType.subjectFaculty:
        return 'Subject Faculty';
      case StaffAssignmentType.classAdvisor:
        return 'Class Advisor';
      case StaffAssignmentType.departmentResponsibility:
        return 'Department Responsibility';
      case StaffAssignmentType.examResponsibility:
        return 'Exam Responsibility';
      case StaffAssignmentType.committee:
        return 'Committee Member';
    }
  }

  static StaffAssignmentType fromString(String? val) {
    if (val == null) return StaffAssignmentType.subjectFaculty;
    final normalized = val.toLowerCase().trim();
    switch (normalized) {
      case 'class_advisor':
      case 'classadvisor':
      case 'advisor':
        return StaffAssignmentType.classAdvisor;
      case 'department_responsibility':
      case 'dept_responsibility':
        return StaffAssignmentType.departmentResponsibility;
      case 'exam_responsibility':
      case 'exam':
        return StaffAssignmentType.examResponsibility;
      case 'committee':
        return StaffAssignmentType.committee;
      case 'subject_faculty':
      default:
        return StaffAssignmentType.subjectFaculty;
    }
  }
}

class StaffAssignmentModel {
  final String id;
  final String staffId;
  final String staffName;
  final String departmentId;
  final StaffAssignmentType assignmentType;
  final String? subjectId;
  final String? subjectName;
  final String? subjectCode;
  final String? classId;
  final String? className;
  final String? section;
  final String academicYear;
  final String assignedBy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // 'active', 'completed', 'revoked'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StaffAssignmentModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.departmentId,
    required this.assignmentType,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
    this.classId,
    this.className,
    this.section,
    required this.academicYear,
    required this.assignedBy,
    this.startDate,
    this.endDate,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isClassAdvisor => assignmentType == StaffAssignmentType.classAdvisor && isActive;

  factory StaffAssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is Timestamp) return val.toDate();
      return DateTime.tryParse(val.toString());
    }

    return StaffAssignmentModel(
      id: id,
      staffId: map['staffId'] ?? map['staff_id'] ?? '',
      staffName: map['staffName'] ?? map['staff_name'] ?? 'Staff Member',
      departmentId: map['departmentId'] ?? map['department_id'] ?? 'DEPT-CSE',
      assignmentType: StaffAssignmentTypeExtension.fromString(
        map['assignmentType'] ?? map['assignment_type'],
      ),
      subjectId: map['subjectId'] ?? map['subject_id'],
      subjectName: map['subjectName'] ?? map['subject_name'],
      subjectCode: map['subjectCode'] ?? map['subject_code'],
      classId: map['classId'] ?? map['class_id'],
      className: map['className'] ?? map['class_name'],
      section: map['section'],
      academicYear: map['academicYear'] ?? map['academic_year'] ?? '2025–26',
      assignedBy: map['assignedBy'] ?? map['assigned_by'] ?? 'HOD',
      startDate: parseDate(map['startDate'] ?? map['start_date']),
      endDate: parseDate(map['endDate'] ?? map['end_date']),
      status: map['status'] ?? 'active',
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      updatedAt: parseDate(map['updatedAt'] ?? map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'staff_id': staffId,
      'staffName': staffName,
      'staff_name': staffName,
      'departmentId': departmentId,
      'department_id': departmentId,
      'assignmentType': assignmentType.value,
      'assignment_type': assignmentType.value,
      'subjectId': subjectId,
      'subject_id': subjectId,
      'subjectName': subjectName,
      'subject_name': subjectName,
      'subjectCode': subjectCode,
      'subject_code': subjectCode,
      'classId': classId,
      'class_id': classId,
      'className': className,
      'class_name': className,
      'section': section,
      'academicYear': academicYear,
      'academic_year': academicYear,
      'assignedBy': assignedBy,
      'assigned_by': assignedBy,
      'startDate': startDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
