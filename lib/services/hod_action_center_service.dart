import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/student_model.dart';
import '../models/staff_model.dart';

/// Priority level for department action center items.
enum HodPriorityLevel {
  critical,
  high,
  medium,
  low,
  info;

  String get label {
    switch (this) {
      case HodPriorityLevel.critical:
        return 'CRITICAL';
      case HodPriorityLevel.high:
        return 'HIGH';
      case HodPriorityLevel.medium:
        return 'MEDIUM';
      case HodPriorityLevel.low:
        return 'LOW';
      case HodPriorityLevel.info:
        return 'INFO';
    }
  }

  Color get color {
    switch (this) {
      case HodPriorityLevel.critical:
        return AppColors.error;
      case HodPriorityLevel.high:
        return AppColors.warning;
      case HodPriorityLevel.medium:
        return AppColors.hodRole;
      case HodPriorityLevel.low:
        return AppColors.info;
      case HodPriorityLevel.info:
        return AppColors.textSecondary;
    }
  }

  Color get backgroundColor {
    return color.withValues(alpha: 0.12);
  }
}

/// Action item surfaced to the HOD in the Intelligent Action Center.
class HodActionItem {
  final String id;
  final String category; // 'attendance', 'leave', 'verification', 'marks', 'academic'
  final String title;
  final String contextDescription;
  final String? deadline;
  final HodPriorityLevel priority;
  final String actionLabel;
  final int targetRouteIndex;
  final IconData icon;
  final Map<String, dynamic>? metadata;

  const HodActionItem({
    required this.id,
    required this.category,
    required this.title,
    required this.contextDescription,
    this.deadline,
    required this.priority,
    required this.actionLabel,
    required this.targetRouteIndex,
    required this.icon,
    this.metadata,
  });
}

/// Detailed risk assessment profile for a student.
class StudentRiskProfile {
  final StudentModel student;
  final HodPriorityLevel riskLevel;
  final List<String> reasons;
  final double attendance;
  final double cgpa;
  final bool isAttendanceRisk;
  final bool isAcademicRisk;

  const StudentRiskProfile({
    required this.student,
    required this.riskLevel,
    required this.reasons,
    required this.attendance,
    required this.cgpa,
    required this.isAttendanceRisk,
    required this.isAcademicRisk,
  });
}

/// Workload intelligence summary for a faculty member.
enum FacultyWorkloadStatus {
  overloaded,
  balanced,
  underutilized;

  String get label {
    switch (this) {
      case FacultyWorkloadStatus.overloaded:
        return 'Overloaded';
      case FacultyWorkloadStatus.balanced:
        return 'Balanced';
      case FacultyWorkloadStatus.underutilized:
        return 'Underutilized';
    }
  }

  Color get color {
    switch (this) {
      case FacultyWorkloadStatus.overloaded:
        return AppColors.error;
      case FacultyWorkloadStatus.balanced:
        return AppColors.success;
      case FacultyWorkloadStatus.underutilized:
        return AppColors.info;
    }
  }
}

class FacultyWorkloadSummary {
  final StaffModel staff;
  final int assignedSubjectsCount;
  final int weeklyPeriodsCount;
  final FacultyWorkloadStatus workloadStatus;
  final double loadPercentage;

  const FacultyWorkloadSummary({
    required this.staff,
    required this.assignedSubjectsCount,
    required this.weeklyPeriodsCount,
    required this.workloadStatus,
    required this.loadPercentage,
  });
}

/// Academic or administrative deadline item with countdown intelligence.
class DepartmentDeadlineItem {
  final String id;
  final String title;
  final String category;
  final DateTime dueDate;
  final String relativeTime;
  final int daysRemaining;
  final int targetRouteIndex;
  final bool isUrgent;

  const DepartmentDeadlineItem({
    required this.id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.relativeTime,
    required this.daysRemaining,
    required this.targetRouteIndex,
    required this.isUrgent,
  });
}

/// Department executive health scorecard.
class ExecutiveDepartmentHealth {
  final double attendanceRate;
  final double academicAverageCgpa;
  final double facultyCoverageRate;
  final int pendingActionsCount;
  final int totalStudents;
  final int totalFaculty;
  final int activeClasses;
  final String attendanceTrend;
  final String academicTrend;
  final String coverageTrend;

  const ExecutiveDepartmentHealth({
    required this.attendanceRate,
    required this.academicAverageCgpa,
    required this.facultyCoverageRate,
    required this.pendingActionsCount,
    required this.totalStudents,
    required this.totalFaculty,
    required this.activeClasses,
    this.attendanceTrend = 'No attendance recorded',
    this.academicTrend = 'No grades recorded',
    this.coverageTrend = 'No faculty enrolled',
  });
}
