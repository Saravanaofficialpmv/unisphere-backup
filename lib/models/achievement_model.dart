import 'package:flutter/material.dart';

class AchievementCriteria {
  final String title;
  final bool isMet;
  final String detail;

  AchievementCriteria({
    required this.title,
    required this.isMet,
    required this.detail,
  });
}

class AchievementMetric {
  final String label;
  final String value;
  final IconData icon;

  AchievementMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class AchievementEvidenceLog {
  final String title;
  final String value;
  final String subtext;

  AchievementEvidenceLog({
    required this.title,
    required this.value,
    required this.subtext,
  });
}

class AchievementModel {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final String dateUnlocked;
  final String issuer;
  final List<AchievementCriteria> criteria;
  final List<AchievementMetric> metrics;
  final List<AchievementEvidenceLog> evidenceLogs;
  final String certificateId;

  AchievementModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.dateUnlocked,
    required this.issuer,
    required this.criteria,
    required this.metrics,
    required this.evidenceLogs,
    required this.certificateId,
  });
}

class AchievementRegistry {
  static final List<AchievementModel> achievements = [
    AchievementModel(
      id: 'deans_list',
      title: 'Dean\'s List Scholar',
      desc: 'CGPA >= 8.50 for 3 consecutive semesters',
      icon: Icons.stars_rounded,
      color: const Color(0xFFD97706),
      isUnlocked: true,
      dateUnlocked: '10 Jan 2026',
      issuer: 'Office of the Academic Dean, VSBEC',
      certificateId: 'VSBEC-DL-2026-857',
      criteria: [
        AchievementCriteria(title: 'Maintain CGPA >= 8.50', isMet: true, detail: 'Current CGPA: 8.57'),
        AchievementCriteria(title: 'Minimum 3 Consecutive Semesters', isMet: true, detail: 'Completed 3 Sems (Sem 1, 2, 3)'),
        AchievementCriteria(title: 'No Active Arrears (RA/SA/W)', isMet: true, detail: 'All registered subjects passed'),
      ],
      metrics: [
        AchievementMetric(label: 'Overall CGPA', value: '8.57', icon: Icons.emoji_events_rounded),
        AchievementMetric(label: 'Eligible Sems', value: '3 Sems', icon: Icons.calendar_month_rounded),
        AchievementMetric(label: 'Honor Status', value: 'Distinction', icon: Icons.verified_user_rounded),
      ],
      evidenceLogs: [
        AchievementEvidenceLog(title: 'Semester 1 Performance', value: 'SGPA: 8.50', subtext: '22 Eligible Credits Passed'),
        AchievementEvidenceLog(title: 'Semester 2 Performance', value: 'SGPA: 8.60', subtext: '23 Eligible Credits Passed'),
        AchievementEvidenceLog(title: 'Semester 3 Performance', value: 'SGPA: 8.75', subtext: '22 Eligible Credits Passed'),
      ],
    ),
    AchievementModel(
      id: 'code_master',
      title: 'Code Master',
      desc: 'Completed 50+ Data Structure & Algo lab tasks',
      icon: Icons.terminal_rounded,
      color: const Color(0xFF2563EB),
      isUnlocked: true,
      dateUnlocked: '15 Dec 2025',
      issuer: 'Department of Computer Science & Engineering',
      certificateId: 'VSBEC-CSE-CM-402',
      criteria: [
        AchievementCriteria(title: 'Complete 50+ Lab Coding Tasks', isMet: true, detail: '58 DSA Tasks Solved (116%)'),
        AchievementCriteria(title: 'Pass All Automated Unit Tests', isMet: true, detail: '100% Test Case Pass Rate'),
        AchievementCriteria(title: 'Maintain Clean Code Standard', isMet: true, detail: 'Reviewed by CSE Faculty Head'),
      ],
      metrics: [
        AchievementMetric(label: 'Tasks Solved', value: '58 Tasks', icon: Icons.code_rounded),
        AchievementMetric(label: 'Acceptance Rate', value: '98.4%', icon: Icons.query_builder_rounded),
        AchievementMetric(label: 'Lab Score', value: '100 / 100', icon: Icons.grade_rounded),
      ],
      evidenceLogs: [
        AchievementEvidenceLog(title: 'Arrays & Linked Lists', value: '18 Tasks', subtext: 'Pointers, Memory Allocation, SLL/DLL'),
        AchievementEvidenceLog(title: 'Trees & Graph Theory', value: '22 Tasks', subtext: 'BST, AVL, BFS/DFS, Dijkstra Algo'),
        AchievementEvidenceLog(title: 'Dynamic Programming & Sorting', value: '18 Tasks', subtext: 'Knapsack, QuickSort, MergeSort'),
      ],
    ),
    AchievementModel(
      id: 'perfect_attendance',
      title: 'Perfect Attendance',
      desc: '100% attendance in OS & DBMS for 2 months',
      icon: Icons.verified_rounded,
      color: const Color(0xFF10B981),
      isUnlocked: true,
      dateUnlocked: '28 Nov 2025',
      issuer: 'Department Academic Attendance Committee',
      certificateId: 'VSBEC-ATT-2025-100',
      criteria: [
        AchievementCriteria(title: '100% Attendance in Operating Systems', isMet: true, detail: '36/36 Sessions Attended'),
        AchievementCriteria(title: '100% Attendance in DBMS', isMet: true, detail: '34/34 Sessions Attended'),
        AchievementCriteria(title: 'Consecutive 60 Days No Absence', isMet: true, detail: 'Active Streak: 60 Days'),
      ],
      metrics: [
        AchievementMetric(label: 'OS Attendance', value: '100%', icon: Icons.schedule_rounded),
        AchievementMetric(label: 'DBMS Attendance', value: '100%', icon: Icons.storage_rounded),
        AchievementMetric(label: 'Active Streak', value: '60 Days', icon: Icons.local_fire_department_rounded),
      ],
      evidenceLogs: [
        AchievementEvidenceLog(title: 'CS403 Operating Systems', value: '36 / 36 Hrs', subtext: '100% Presence recorded via biometric'),
        AchievementEvidenceLog(title: 'CS402 Database Mgmt Systems', value: '34 / 34 Hrs', subtext: '100% Presence recorded via biometric'),
        AchievementEvidenceLog(title: 'Monthly Attendance Log', value: 'Oct & Nov 2025', subtext: 'Zero leaves, zero shortage alerts'),
      ],
    ),
    AchievementModel(
      id: 'hackathon_winner',
      title: 'Hackathon Winner',
      desc: 'First Prize in Annual Tech Fest 2025',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFF7C3AED),
      isUnlocked: true,
      dateUnlocked: '05 Feb 2026',
      issuer: 'UNISPHERE National Innovation Council',
      certificateId: 'VSBEC-HACK-1ST-2026',
      criteria: [
        AchievementCriteria(title: 'Win 1st Place in Track', isMet: true, detail: '1st Prize in AI & Smart Campus Track'),
        AchievementCriteria(title: 'Deploy Working Prototype', isMet: true, detail: 'Full-stack App Deployed on GCP'),
        AchievementCriteria(title: 'Grand Jury Pitch Presentation', isMet: true, detail: 'Scored 98/100 by Tech Leaders'),
      ],
      metrics: [
        AchievementMetric(label: 'Position', value: '1st Rank', icon: Icons.military_tech_rounded),
        AchievementMetric(label: 'Prize Award', value: '₹50,000', icon: Icons.payments_rounded),
        AchievementMetric(label: 'Teams Total', value: '45 Teams', icon: Icons.groups_rounded),
      ],
      evidenceLogs: [
        AchievementEvidenceLog(title: 'Project Title', value: 'Unisphere AI Engine', subtext: 'Smart Campus Analytics & Assistant'),
        AchievementEvidenceLog(title: 'Team Roster', value: 'Alex & Team Delta', subtext: 'Lead Full-Stack Developer & AI Specialist'),
        AchievementEvidenceLog(title: 'Jury Commendation', value: 'Highest Innovation Score', subtext: 'Selected for Incubator Mentorship'),
      ],
    ),
    AchievementModel(
      id: 'research_contributor',
      title: 'Research Contributor',
      desc: 'Co-authored IEEE conference paper draft',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF0284C7),
      isUnlocked: false,
      dateUnlocked: 'Pending Review',
      issuer: 'Department Research & Development Cell',
      certificateId: 'VSBEC-RES-PENDING-04',
      criteria: [
        AchievementCriteria(title: 'Draft IEEE Format Paper', isMet: true, detail: '12 Pages Submitted'),
        AchievementCriteria(title: 'Faculty Advisor Endorsement', isMet: true, detail: 'Approved by Dr. Sarah Vance'),
        AchievementCriteria(title: 'Final Camera-Ready Acceptance', isMet: false, detail: 'Peer Review in Progress'),
      ],
      metrics: [
        AchievementMetric(label: 'Paper Status', value: 'In Review', icon: Icons.pending_actions_rounded),
        AchievementMetric(label: 'Co-Authors', value: '3 Authors', icon: Icons.groups_rounded),
        AchievementMetric(label: 'Target Venue', value: 'IEEE 2026', icon: Icons.school_rounded),
      ],
      evidenceLogs: [
        AchievementEvidenceLog(title: 'Paper Title', value: 'AI Campus Orchestration', subtext: 'Machine Learning for Student Engagement'),
        AchievementEvidenceLog(title: 'Primary Author', value: 'Student Researcher', subtext: 'Lead Investigator & Experimenter'),
      ],
    ),
    AchievementModel(
      id: 'peer_mentor',
      title: 'Peer Mentor',
      desc: 'Tutored 15+ junior students in Python & OOP',
      icon: Icons.groups_rounded,
      color: const Color(0xFFEA580C),
      isUnlocked: false,
      dateUnlocked: 'Progress: 12/15',
      issuer: 'Student Peer Mentorship Association',
      certificateId: 'VSBEC-MENTOR-PROG',
      criteria: [
        AchievementCriteria(title: 'Mentor 15+ Junior Students', isMet: false, detail: '12 / 15 Students Completed (80%)'),
        AchievementCriteria(title: 'Log 30+ Tutoring Hours', isMet: true, detail: '34 Tutoring Hours Logged'),
        AchievementCriteria(title: 'Maintain Rating >= 4.5', isMet: true, detail: 'Average Rating: 4.9 / 5.0'),
      ],
      metrics: [
        AchievementMetric(label: 'Students Taught', value: '12 / 15', icon: Icons.person_rounded),
        AchievementMetric(label: 'Hours Logged', value: '34 Hrs', icon: Icons.timer_rounded),
        AchievementMetric(label: 'Rating Score', value: '4.9 / 5.0', icon: Icons.star_rounded),
      ],
      evidenceLogs: [
        AchievementEvidenceLog(title: 'Python & OOP Workshops', value: '6 Sessions', subtext: 'Covered Classes, Inheritance, Data Structures'),
        AchievementEvidenceLog(title: 'Student Feedback', value: '98% Satisfaction', subtext: 'Recorded via Student Mentor Feedback Form'),
      ],
    ),
  ];
}
