import 'package:flutter/material.dart';

/// Detailed model representing a Student Ward under Parent supervision
class ParentStudentWard {
  final String id;
  final String name;
  final String regNo;
  final String department;
  final String yearSection;
  final String currentYear;
  final String currentSemester;
  final String batch;
  final String? photoUrl;
  final String? fatherPhotoUrl;
  final String? motherPhotoUrl;
  final String? guardianPhotoUrl;
  final String avatarInitials;
  final double attendancePercent;
  final int presentCount;
  final int absentCount;
  final int leaveOdCount;
  final String cgpa;
  final String academicTrend;
  final String academicStatus;
  final Color statusColor;
  final double totalFees;
  final double paidFees;
  final double pendingFees;
  final DateTime feeDueDate;
  final String feeStatus;
  final bool isFeeOverdue;
  final String todayStatus; // 'Present', 'Absent', 'On Leave'
  final List<ParentSubjectGrade> subjectGrades;

  ParentStudentWard({
    required this.id,
    required this.name,
    required this.regNo,
    required this.department,
    required this.yearSection,
    required this.currentYear,
    required this.currentSemester,
    this.batch = '2023 - 2027',
    this.photoUrl,
    this.fatherPhotoUrl,
    this.motherPhotoUrl,
    this.guardianPhotoUrl,
    required this.avatarInitials,
    required this.attendancePercent,
    required this.presentCount,
    required this.absentCount,
    required this.leaveOdCount,
    required this.cgpa,
    required this.academicTrend,
    required this.academicStatus,
    required this.statusColor,
    required this.totalFees,
    required this.paidFees,
    required this.pendingFees,
    required this.feeDueDate,
    required this.feeStatus,
    this.isFeeOverdue = false,
    this.todayStatus = 'Present',
    required this.subjectGrades,
  });

  ParentStudentWard copyWith({
    String? id,
    String? name,
    String? regNo,
    String? department,
    String? yearSection,
    String? currentYear,
    String? currentSemester,
    String? batch,
    String? photoUrl,
    String? fatherPhotoUrl,
    String? motherPhotoUrl,
    String? guardianPhotoUrl,
    String? avatarInitials,
    double? attendancePercent,
    int? presentCount,
    int? absentCount,
    int? leaveOdCount,
    String? cgpa,
    String? academicTrend,
    String? academicStatus,
    Color? statusColor,
    double? totalFees,
    double? paidFees,
    double? pendingFees,
    DateTime? feeDueDate,
    String? feeStatus,
    bool? isFeeOverdue,
    String? todayStatus,
    List<ParentSubjectGrade>? subjectGrades,
  }) {
    return ParentStudentWard(
      id: id ?? this.id,
      name: name ?? this.name,
      regNo: regNo ?? this.regNo,
      department: department ?? this.department,
      yearSection: yearSection ?? this.yearSection,
      currentYear: currentYear ?? this.currentYear,
      currentSemester: currentSemester ?? this.currentSemester,
      batch: batch ?? this.batch,
      photoUrl: photoUrl ?? this.photoUrl,
      fatherPhotoUrl: fatherPhotoUrl ?? this.fatherPhotoUrl,
      motherPhotoUrl: motherPhotoUrl ?? this.motherPhotoUrl,
      guardianPhotoUrl: guardianPhotoUrl ?? this.guardianPhotoUrl,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      attendancePercent: attendancePercent ?? this.attendancePercent,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      leaveOdCount: leaveOdCount ?? this.leaveOdCount,
      cgpa: cgpa ?? this.cgpa,
      academicTrend: academicTrend ?? this.academicTrend,
      academicStatus: academicStatus ?? this.academicStatus,
      statusColor: statusColor ?? this.statusColor,
      totalFees: totalFees ?? this.totalFees,
      paidFees: paidFees ?? this.paidFees,
      pendingFees: pendingFees ?? this.pendingFees,
      feeDueDate: feeDueDate ?? this.feeDueDate,
      feeStatus: feeStatus ?? this.feeStatus,
      isFeeOverdue: isFeeOverdue ?? this.isFeeOverdue,
      todayStatus: todayStatus ?? this.todayStatus,
      subjectGrades: subjectGrades ?? this.subjectGrades,
    );
  }

  /// Attendance health threshold status badge string & color
  String get attendanceHealthStatus {
    if (attendancePercent >= 0.85) return 'Healthy';
    if (attendancePercent >= 0.75) return 'Monitor';
    return 'Warning';
  }

  Color get attendanceHealthColor {
    if (attendancePercent >= 0.85) return const Color(0xFF10B981);
    if (attendancePercent >= 0.75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

/// Subject Grade entry for Academic Performance Summary
class ParentSubjectGrade {
  final String subjectCode;
  final String subjectName;
  final String grade;
  final Color color;

  ParentSubjectGrade({
    required this.subjectCode,
    required this.subjectName,
    required this.grade,
    required this.color,
  });
}

/// Model for Upcoming Exams in Parent Portal
class ParentExamModel {
  final String id;
  final String examName;
  final String subject;
  final DateTime examDate;
  final String timeSlot;
  final String venue;
  final String examType;

  ParentExamModel({
    required this.id,
    required this.examName,
    required this.subject,
    required this.examDate,
    required this.timeSlot,
    required this.venue,
    required this.examType,
  });
}

/// Model for Upcoming Events in Parent Portal
class ParentEventModel {
  final String id;
  final String title;
  final DateTime eventDate;
  final String timeSlot;
  final String venue;
  final String category;
  final String description;

  ParentEventModel({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.timeSlot,
    required this.venue,
    required this.category,
    required this.description,
  });
}

/// Model for Important Announcements in Parent Portal
class ParentAnnouncementModel {
  final String id;
  final String title;
  final String description;
  final DateTime datePublished;
  final String category;
  final bool isImportant;
  final bool isRead;

  ParentAnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.datePublished,
    required this.category,
    this.isImportant = false,
    this.isRead = false,
  });
}

/// Model for Recent Notifications in Parent Portal with navigation target
class ParentNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color iconColor;
  final String targetTab; // 'attendance', 'academics', 'fees', 'exams', 'events', 'announcements'
  final int targetTabIndex; // 1: Attendance, 2: Academics, 3: Announcements, 6: Fees, 8: Events
  final bool isUnread;

  ParentNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    required this.targetTab,
    required this.targetTabIndex,
    this.isUnread = true,
  });
}
