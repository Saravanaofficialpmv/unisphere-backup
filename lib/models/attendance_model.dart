library;

/// Core Attendance Models for Unisphere Application

/// Status of an individual session record
enum AttendanceStatus { present, absent, onDuty, late }

extension AttendanceStatusExtension on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.onDuty:
        return 'On Duty';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}

/// Daily Attendance Log for a working day (All subjects share the daily status)
class DailyAttendanceLog {
  final String id;
  final String dateStr;
  final DateTime date;
  final AttendanceStatus status;
  final String dayName;
  final List<String> subjectsCovered;
  final String classInCharge;
  final String? remarks;

  DailyAttendanceLog({
    required this.id,
    required this.dateStr,
    required this.date,
    required this.status,
    required this.dayName,
    required this.subjectsCovered,
    required this.classInCharge,
    this.remarks,
  });

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isOnDuty => status == AttendanceStatus.onDuty;
}

/// Record for a specific class session
class AttendanceRecord {
  final String id;
  final String studentUid;
  final String studentName;
  final String subjectCode;
  final String subjectName;
  final DateTime date;
  final String timeSlot;
  final AttendanceStatus status;
  final String facultyName;

  AttendanceRecord({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.subjectCode,
    required this.subjectName,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.facultyName,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    AttendanceStatus parsedStatus = AttendanceStatus.present;
    final statusStr = (map['status'] ?? 'present').toString().toLowerCase();
    if (statusStr == 'absent') {
      parsedStatus = AttendanceStatus.absent;
    } else if (statusStr == 'onduty' || statusStr == 'on duty') {
      parsedStatus = AttendanceStatus.onDuty;
    } else if (statusStr == 'late') {
      parsedStatus = AttendanceStatus.late;
    }

    DateTime recordDate = DateTime.now();
    final rawDate = map['date'] ?? map['timestamp'] ?? map['createdAt'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        recordDate = rawDate;
      } else if (rawDate is String) {
        recordDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else {
        try {
          recordDate = (rawDate as dynamic).toDate();
        } catch (_) {
          recordDate = DateTime.now();
        }
      }
    }

    return AttendanceRecord(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      studentUid: map['student_uid'] ?? map['studentUid'] ?? map['studentId'] ?? map['registerNumber'] ?? '',
      studentName: map['student_name'] ?? map['studentName'] ?? 'Student',
      subjectCode: map['subject_code'] ?? map['subjectCode'] ?? 'CS301',
      subjectName: map['subject_name'] ?? map['subjectName'] ?? 'Subject',
      date: recordDate,
      timeSlot: map['time_slot'] ?? map['timeSlot'] ?? '09:00 - 10:00 AM',
      status: parsedStatus,
      facultyName: map['faculty_name'] ?? map['facultyName'] ?? 'Faculty',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_uid': studentUid,
      'studentUid': studentUid,
      'student_name': studentName,
      'studentName': studentName,
      'subject_code': subjectCode,
      'subjectCode': subjectCode,
      'subject_name': subjectName,
      'subjectName': subjectName,
      'date': date.toIso8601String(),
      'time_slot': timeSlot,
      'timeSlot': timeSlot,
      'status': status.label,
      'faculty_name': facultyName,
      'facultyName': facultyName,
    };
  }
}

/// Subject-level attendance metrics for a student
class SubjectAttendance {
  final String code;
  final String name;
  final String facultyName;
  final int credits;
  final int attendedSessions;
  final int totalSessions;
  final int colorValue;

  SubjectAttendance({
    required this.code,
    required this.name,
    required this.facultyName,
    this.credits = 4,
    required this.attendedSessions,
    required this.totalSessions,
    this.colorValue = 0xFF2563EB,
  });

  double get percentage {
    if (totalSessions <= 0) return 0.0;
    return (attendedSessions / totalSessions) * 100.0;
  }

  bool get isLow => percentage < 80.0;

  String get safeMarginText {
    if (percentage >= 90.0) return 'Safe: Can skip 4 classes';
    if (percentage >= 85.0) return 'Safe: Can skip 3 classes';
    if (percentage >= 80.0) return 'Safe: Can skip 2 classes';
    return 'Warning: Attend next 2 classes!';
  }

  SubjectAttendance copyWith({
    int? attendedSessions,
    int? totalSessions,
  }) {
    return SubjectAttendance(
      code: code,
      name: name,
      facultyName: facultyName,
      credits: credits,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      colorValue: colorValue,
    );
  }
}

/// Configuration for a semester set by Head of Department (HOD)
class HodSemesterConfig {
  final int semesterNumber;
  final String semesterName;
  final int totalWorkingDays;
  final double minimumRequiredPercentage;

  const HodSemesterConfig({
    required this.semesterNumber,
    required this.semesterName,
    required this.totalWorkingDays,
    this.minimumRequiredPercentage = 75.0,
  });

  HodSemesterConfig copyWith({
    int? totalWorkingDays,
    double? minimumRequiredPercentage,
  }) {
    return HodSemesterConfig(
      semesterNumber: semesterNumber,
      semesterName: semesterName,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      minimumRequiredPercentage: minimumRequiredPercentage ?? this.minimumRequiredPercentage,
    );
  }
}

/// Student's semester attendance data
class SemesterAttendance {
  final int semesterNumber;
  final String semesterName;
  final int attendedWorkingDays;
  final int totalWorkingDays;
  final bool isCurrentSemester;
  final List<SubjectAttendance> subjects;

  const SemesterAttendance({
    required this.semesterNumber,
    required this.semesterName,
    required this.attendedWorkingDays,
    required this.totalWorkingDays,
    this.isCurrentSemester = false,
    this.subjects = const [],
  });

  double get attendancePercentage {
    if (totalWorkingDays <= 0) return 0.0;
    final pct = (attendedWorkingDays / totalWorkingDays) * 100.0;
    return pct > 100.0 ? 100.0 : pct;
  }

  String get statusLabel {
    final pct = attendancePercentage;
    if (pct >= 85.0) return 'Good';
    if (pct >= 75.0) return 'Safe Margin';
    return 'Critical';
  }

  String get safeMarginText {
    final pct = attendancePercentage;
    if (pct >= 85.0) return 'Safe Margin: Can skip up to 4 days';
    if (pct >= 75.0) return 'Warning: Attend next 3 classes!';
    return 'Shortage Alert: Below 75% requirement';
  }

  SemesterAttendance copyWith({
    int? attendedWorkingDays,
    int? totalWorkingDays,
    bool? isCurrentSemester,
    List<SubjectAttendance>? subjects,
  }) {
    return SemesterAttendance(
      semesterNumber: semesterNumber,
      semesterName: semesterName,
      attendedWorkingDays: attendedWorkingDays ?? this.attendedWorkingDays,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      isCurrentSemester: isCurrentSemester ?? this.isCurrentSemester,
      subjects: subjects ?? this.subjects,
    );
  }
}

/// Leave & On-Duty request model
class LeaveRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String registerNumber;
  final String departmentId;
  final String section;
  final String role;
  final String type;
  final String duration;
  final String reason;
  final String status;
  final String appliedDate;
  final bool hasAttachment;
  final String? requestLetterUrl;
  final String? registrationScreenshotUrl;
  final DateTime? createdAt;
  final String? remarks;

  LeaveRequestModel({
    required this.id,
    this.studentId = '',
    required this.studentName,
    this.registerNumber = '',
    this.departmentId = '',
    this.section = '',
    this.role = 'Student',
    required this.type,
    required this.duration,
    required this.reason,
    required this.status,
    required this.appliedDate,
    this.hasAttachment = false,
    this.requestLetterUrl,
    this.registrationScreenshotUrl,
    this.createdAt,
    this.remarks,
  });

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawDate = map['createdAt'] ?? map['appliedDateTimestamp'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        parsedCreatedAt = rawDate;
      } else if (rawDate is String) {
        parsedCreatedAt = DateTime.tryParse(rawDate);
      } else {
        try {
          parsedCreatedAt = (rawDate as dynamic).toDate();
        } catch (_) {}
      }
    }

    return LeaveRequestModel(
      id: docId ?? map['id']?.toString() ?? '',
      studentId: map['studentId'] ?? map['student_id'] ?? map['studentUid'] ?? '',
      studentName: map['studentName'] ?? map['student_name'] ?? map['name'] ?? 'Student',
      registerNumber: map['registerNumber'] ?? map['register_number'] ?? '',
      departmentId: map['departmentId'] ?? map['department_id'] ?? '',
      section: map['section'] ?? '',
      role: map['role'] ?? 'Student',
      type: map['type'] ?? map['leaveCategory'] ?? 'Medical Leave',
      duration: map['duration'] ?? map['dates'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'Pending Approval',
      appliedDate: map['appliedDate'] ?? map['applied_date'] ?? 'Today',
      hasAttachment: map['hasAttachment'] ?? map['has_attachment'] ?? (map['requestLetterUrl'] != null || map['document'] != null),
      requestLetterUrl: map['requestLetterUrl'] ?? map['document'],
      registrationScreenshotUrl: map['registrationScreenshotUrl'] ?? map['screenshotUrl'],
      createdAt: parsedCreatedAt,
      remarks: map['remarks'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'student_id': studentId,
      'studentName': studentName,
      'student_name': studentName,
      'name': studentName,
      'registerNumber': registerNumber,
      'register_number': registerNumber,
      'departmentId': departmentId,
      'department_id': departmentId,
      'section': section,
      'role': role,
      'type': type,
      'leaveCategory': type,
      'duration': duration,
      'dates': duration,
      'reason': reason,
      'status': status,
      'appliedDate': appliedDate,
      'applied_date': appliedDate,
      'hasAttachment': hasAttachment,
      'has_attachment': hasAttachment,
      if (requestLetterUrl != null) 'requestLetterUrl': requestLetterUrl,
      if (requestLetterUrl != null) 'document': requestLetterUrl,
      if (registrationScreenshotUrl != null) 'registrationScreenshotUrl': registrationScreenshotUrl,
      if (remarks != null) 'remarks': remarks,
      'createdAt': createdAt != null ? createdAt!.toIso8601String() : DateTime.now().toIso8601String(),
    };
  }

  LeaveRequestModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? registerNumber,
    String? departmentId,
    String? section,
    String? role,
    String? type,
    String? duration,
    String? reason,
    String? status,
    String? appliedDate,
    bool? hasAttachment,
    String? requestLetterUrl,
    String? registrationScreenshotUrl,
    DateTime? createdAt,
    String? remarks,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      registerNumber: registerNumber ?? this.registerNumber,
      departmentId: departmentId ?? this.departmentId,
      section: section ?? this.section,
      role: role ?? this.role,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      hasAttachment: hasAttachment ?? this.hasAttachment,
      requestLetterUrl: requestLetterUrl ?? this.requestLetterUrl,
      registrationScreenshotUrl: registrationScreenshotUrl ?? this.registrationScreenshotUrl,
      createdAt: createdAt ?? this.createdAt,
      remarks: remarks ?? this.remarks,
    );
  }
}
