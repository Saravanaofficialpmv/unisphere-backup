import 'dart:convert';
import 'package:unisphere/models/hackathon_model.dart';
import 'package:unisphere/models/hackathon_activity_model.dart';

class HackathonRegistrationModel {
  final String id; // registrationId
  final String hackathonId;
  final String teamId;
  final String leaderId;
  final String hackathonTitle;
  final String studentId; // Team Leader ID
  final String teamLeaderId; // Alias for Team Leader ID
  final String studentName;
  final String department;
  final String year;
  final String section;
  final String email;
  final String phone;
  final String teamName;
  final List<String> teamMembers;
  final DateTime registrationDate;
  final DateTime startDate;
  final DateTime endDate;
  final String participationStatus; // Status flow representation
  final bool registrationCompleted;
  final String externalRegistrationStatus;
  final String hodReviewStatus;
  final String mode; // 'Online', 'Offline', 'Hybrid'
  final String location;
  final String organizer;
  final String description;
  final String bannerImage;
  final List<String> rules;
  final DateTime? submissionDeadline;
  final String? projectSubmissionUrl;
  final String? projectSubmissionTitle;
  final String? projectSubmissionNotes;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final String externalRegistrationId;
  final String registrationScreenshotUrl;
  final String verificationStatus; // 'Pending Verification', 'Verified', 'Correction Required'
  final String assignedAdvisorId;
  final String assignedAdvisorName;
  final String? advisorCorrectionNotes;
  final List<HackathonActivityModel> activities;

  HackathonRegistrationModel({
    required this.id,
    required this.hackathonId,
    String? teamId,
    String? leaderId,
    required this.hackathonTitle,
    required this.studentId,
    String? teamLeaderId,
    required this.studentName,
    required this.department,
    required this.year,
    this.section = 'Sec B',
    required this.email,
    required this.phone,
    required this.teamName,
    required this.teamMembers,
    required this.registrationDate,
    required this.startDate,
    required this.endDate,
    required this.participationStatus,
    this.registrationCompleted = true,
    this.externalRegistrationStatus = 'completed',
    this.hodReviewStatus = 'pending',
    required this.mode,
    required this.location,
    required this.organizer,
    this.description = '',
    this.bannerImage = '',
    this.rules = const [],
    this.submissionDeadline,
    this.projectSubmissionUrl,
    this.projectSubmissionTitle,
    this.projectSubmissionNotes,
    this.submittedAt,
    this.updatedAt,
    this.externalRegistrationId = '',
    this.registrationScreenshotUrl = '',
    this.verificationStatus = 'Pending Verification',
    this.assignedAdvisorId = '',
    this.assignedAdvisorName = '',
    this.advisorCorrectionNotes,
    this.activities = const [],
  })  : teamId = teamId ?? 'TEAM-$id',
        leaderId = leaderId ?? studentId,
        teamLeaderId = teamLeaderId ?? studentId;

  /// Dynamic lifecycle status based on current date vs start/end dates
  String get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      return 'pending';
    } else if (now.isAfter(endDate)) {
      return 'completed';
    } else {
      return 'ongoing';
    }
  }

  bool get isOngoing => status == 'ongoing';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';

  /// Status Flow Helper Getters
  bool get isVerified => verificationStatus.toLowerCase().contains('verified');
  bool get isCorrectionRequired => verificationStatus.toLowerCase().contains('correction');
  bool get isPendingVerification => verificationStatus.toLowerCase().contains('pending');
  bool get isResubmitted => participationStatus.toLowerCase().contains('resubmitted');

  bool get hasExternalRegId => externalRegistrationId.trim().isNotEmpty;
  bool get hasScreenshotProof => registrationScreenshotUrl.trim().isNotEmpty;
  bool get hasRequiredMembers => teamMembers.isNotEmpty && teamMembers.length <= 6;
  bool get isSubmittedToAdvisor => verificationStatus != 'Not Submitted';
  bool get isCompleteAndVerified => isVerified && hasExternalRegId && hasScreenshotProof;

  HackathonModel toHackathonModel() {
    return HackathonModel(
      id: hackathonId,
      title: hackathonTitle,
      description: description.isNotEmpty
          ? description
          : '36-hour innovation hackathon focusing on AI agents, cloud pipelines, and software engineering.',
      category: 'Hackathon',
      organizer: organizer,
      mode: mode,
      bannerImage: bannerImage.isNotEmpty
          ? bannerImage
          : 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&q=80',
      startDate: startDate,
      endDate: endDate,
      registrationOpen: !isCompleted,
      registrationDeadline: startDate.subtract(const Duration(days: 1)),
      prizePool: '₹2,50,000',
      registeredTeams: 120,
      maxTeams: 200,
      maxTeamMembers: 6,
      teamSize: teamMembers.isNotEmpty ? teamMembers.length : 6,
      status: status,
      userRegistrationStatus: 'registered',
      registrationId: id,
      location: location,
      tags: ['Innovation', 'Development'],
    );
  }

  HackathonRegistrationModel copyWith({
    String? id,
    String? hackathonId,
    String? teamId,
    String? leaderId,
    String? hackathonTitle,
    String? studentId,
    String? studentName,
    String? department,
    String? year,
    String? section,
    String? email,
    String? phone,
    String? teamName,
    List<String>? teamMembers,
    DateTime? registrationDate,
    DateTime? startDate,
    DateTime? endDate,
    String? participationStatus,
    bool? registrationCompleted,
    String? externalRegistrationStatus,
    String? hodReviewStatus,
    String? mode,
    String? location,
    String? organizer,
    String? description,
    String? bannerImage,
    List<String>? rules,
    DateTime? submissionDeadline,
    String? projectSubmissionUrl,
    String? projectSubmissionTitle,
    String? projectSubmissionNotes,
    DateTime? submittedAt,
    DateTime? updatedAt,
    String? externalRegistrationId,
    String? registrationScreenshotUrl,
    String? verificationStatus,
    String? assignedAdvisorId,
    String? assignedAdvisorName,
    String? advisorCorrectionNotes,
    List<HackathonActivityModel>? activities,
  }) {
    return HackathonRegistrationModel(
      id: id ?? this.id,
      hackathonId: hackathonId ?? this.hackathonId,
      teamId: teamId ?? this.teamId,
      leaderId: leaderId ?? this.leaderId,
      hackathonTitle: hackathonTitle ?? this.hackathonTitle,
      studentId: studentId ?? this.studentId,
      teamLeaderId: teamLeaderId,
      studentName: studentName ?? this.studentName,
      department: department ?? this.department,
      year: year ?? this.year,
      section: section ?? this.section,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      teamName: teamName ?? this.teamName,
      teamMembers: teamMembers ?? this.teamMembers,
      registrationDate: registrationDate ?? this.registrationDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participationStatus: participationStatus ?? this.participationStatus,
      registrationCompleted: registrationCompleted ?? this.registrationCompleted,
      externalRegistrationStatus: externalRegistrationStatus ?? this.externalRegistrationStatus,
      hodReviewStatus: hodReviewStatus ?? this.hodReviewStatus,
      mode: mode ?? this.mode,
      location: location ?? this.location,
      organizer: organizer ?? this.organizer,
      description: description ?? this.description,
      bannerImage: bannerImage ?? this.bannerImage,
      rules: rules ?? this.rules,
      submissionDeadline: submissionDeadline ?? this.submissionDeadline,
      projectSubmissionUrl: projectSubmissionUrl ?? this.projectSubmissionUrl,
      projectSubmissionTitle: projectSubmissionTitle ?? this.projectSubmissionTitle,
      projectSubmissionNotes: projectSubmissionNotes ?? this.projectSubmissionNotes,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      externalRegistrationId: externalRegistrationId ?? this.externalRegistrationId,
      registrationScreenshotUrl: registrationScreenshotUrl ?? this.registrationScreenshotUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      assignedAdvisorId: assignedAdvisorId ?? this.assignedAdvisorId,
      assignedAdvisorName: assignedAdvisorName ?? this.assignedAdvisorName,
      advisorCorrectionNotes: advisorCorrectionNotes ?? this.advisorCorrectionNotes,
      activities: activities ?? this.activities,
    );
  }

  factory HackathonRegistrationModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? fallback;
    }

    final now = DateTime.now();
    final regId = docId ?? map['registrationId']?.toString() ?? map['id']?.toString() ?? 'REG-${now.millisecondsSinceEpoch}';

    final rawActivities = map['activities'] as List<dynamic>?;
    List<HackathonActivityModel> parsedActivities = [];
    if (rawActivities != null) {
      for (var item in rawActivities) {
        if (item is Map<String, dynamic>) {
          parsedActivities.add(HackathonActivityModel.fromMap(item));
        }
      }
    }

    return HackathonRegistrationModel(
      id: regId,
      hackathonId: map['hackathonId']?.toString() ?? map['hackathon_id']?.toString() ?? '',
      teamId: map['teamId']?.toString() ?? map['team_id']?.toString() ?? 'TEAM-$regId',
      leaderId: map['leaderId']?.toString() ?? map['leader_id']?.toString() ?? map['studentId']?.toString() ?? map['student_id']?.toString() ?? '',
      hackathonTitle: map['hackathonTitle']?.toString() ?? map['hackathon_title']?.toString() ?? map['hackathonName']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? map['student_id']?.toString() ?? map['teamLeaderId']?.toString() ?? '',
      teamLeaderId: map['teamLeaderId']?.toString() ?? map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? map['student_name']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      year: map['year']?.toString() ?? '',
      section: map['section']?.toString() ?? map['sec']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      teamName: map['teamName']?.toString() ?? map['team_name']?.toString() ?? 'Team',
      teamMembers: (map['teamMembers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (map['members'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      registrationDate: parseDate(map['registrationDate'] ?? map['registration_date'] ?? map['submittedAt'] ?? map['submitted_at'], now),
      startDate: parseDate(map['startDate'] ?? map['start_date'], now.subtract(const Duration(days: 1))),
      endDate: parseDate(map['endDate'] ?? map['end_date'], now.add(const Duration(days: 2))),
      participationStatus: map['participationStatus']?.toString() ?? map['status']?.toString() ?? 'Confirmed',
      registrationCompleted: map['registrationCompleted'] ?? map['registration_completed'] ?? true,
      externalRegistrationStatus: map['externalRegistrationStatus'] ?? map['external_registration_status'] ?? 'completed',
      hodReviewStatus: map['hodReviewStatus'] ?? map['hod_review_status'] ?? 'pending',
      mode: map['mode']?.toString() ?? 'Online',
      location: map['location']?.toString() ?? map['venue']?.toString() ?? 'Online',
      organizer: map['organizer']?.toString() ?? 'UniSphere Innovation Cell',
      description: map['description']?.toString() ?? '',
      bannerImage: map['bannerImage']?.toString() ?? map['banner_image']?.toString() ?? '',
      rules: (map['rules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      submissionDeadline: map['submissionDeadline'] != null ? parseDate(map['submissionDeadline'], now) : null,
      projectSubmissionUrl: map['projectSubmissionUrl']?.toString(),
      projectSubmissionTitle: map['projectSubmissionTitle']?.toString(),
      projectSubmissionNotes: map['projectSubmissionNotes']?.toString(),
      submittedAt: map['submittedAt'] != null ? parseDate(map['submittedAt'], now) : null,
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt'], now) : null,
      externalRegistrationId: map['externalRegistrationId']?.toString() ?? map['external_registration_id']?.toString() ?? '',
      registrationScreenshotUrl: map['registrationScreenshotUrl']?.toString() ?? map['registration_screenshot_url']?.toString() ?? '',
      verificationStatus: map['verificationStatus']?.toString() ?? map['verification_status']?.toString() ?? 'Pending Verification',
      assignedAdvisorId: map['assignedAdvisorId']?.toString() ?? map['assigned_advisor_id']?.toString() ?? '',
      assignedAdvisorName: map['assignedAdvisorName']?.toString() ?? map['assigned_advisor_name']?.toString() ?? '',
      advisorCorrectionNotes: map['advisorCorrectionNotes']?.toString() ?? map['advisor_correction_notes']?.toString(),
      activities: parsedActivities,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'registrationId': id,
      'id': id,
      'hackathonId': hackathonId,
      'hackathon_id': hackathonId,
      'teamId': teamId,
      'team_id': teamId,
      'leaderId': leaderId,
      'leader_id': leaderId,
      'hackathonTitle': hackathonTitle,
      'studentId': studentId,
      'student_id': studentId,
      'teamLeaderId': teamLeaderId,
      'studentName': studentName,
      'department': department,
      'year': year,
      'section': section,
      'email': email,
      'phone': phone,
      'teamName': teamName,
      'team_name': teamName,
      'teamMembers': teamMembers,
      'registrationDate': registrationDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'participationStatus': participationStatus,
      'registrationCompleted': registrationCompleted,
      'registration_completed': registrationCompleted,
      'externalRegistrationStatus': externalRegistrationStatus,
      'external_registration_status': externalRegistrationStatus,
      'hodReviewStatus': hodReviewStatus,
      'hod_review_status': hodReviewStatus,
      'mode': mode,
      'location': location,
      'organizer': organizer,
      'description': description,
      'bannerImage': bannerImage,
      'rules': rules,
      'submissionDeadline': submissionDeadline?.toIso8601String(),
      'projectSubmissionUrl': projectSubmissionUrl,
      'projectSubmissionTitle': projectSubmissionTitle,
      'projectSubmissionNotes': projectSubmissionNotes,
      'submittedAt': (submittedAt ?? registrationDate).toIso8601String(),
      'submitted_at': (submittedAt ?? registrationDate).toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'externalRegistrationId': externalRegistrationId,
      'registrationScreenshotUrl': registrationScreenshotUrl,
      'verificationStatus': verificationStatus,
      'assignedAdvisorId': assignedAdvisorId,
      'assignedAdvisorName': assignedAdvisorName,
      'advisorCorrectionNotes': advisorCorrectionNotes,
      'activities': activities.map((a) => a.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());

  factory HackathonRegistrationModel.fromJson(String source) => HackathonRegistrationModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
