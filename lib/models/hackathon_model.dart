import 'dart:convert';

class HackathonModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String organizer;
  final String mode; // 'Online', 'Offline', 'Hybrid'
  final String bannerImage;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationStartDate;
  final DateTime registrationDeadline;
  final bool registrationOpen;
  final String prizePool;
  final int registeredTeams;
  final int maxTeams;
  final int maxTeamMembers;
  final int teamSize;
  final String status; // 'upcoming', 'ongoing', 'ended'
  final String userRegistrationStatus; // 'registered', 'not_registered', 'pending'
  final String? registrationId;
  final String? registrationLink;
  final String? createdBy;
  final String location;
  final List<String> tags;
  final bool isFeatured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String externalRegistrationUrl;
  final List<String> eligibleYears;
  final List<String> eligibleSections;
  final String createdByRole; // 'hod' or 'advisor'
  final String createdByName;
  final int minTeamSize;

  HackathonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.organizer,
    required this.mode,
    required this.bannerImage,
    required this.startDate,
    required this.endDate,
    DateTime? registrationStartDate,
    required this.registrationDeadline,
    required this.registrationOpen,
    required this.prizePool,
    required this.registeredTeams,
    required this.maxTeams,
    this.maxTeamMembers = 6,
    required this.teamSize,
    this.minTeamSize = 1,
    required this.status,
    required this.userRegistrationStatus,
    this.registrationId,
    this.registrationLink,
    this.createdBy,
    required this.location,
    required this.tags,
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
    this.externalRegistrationUrl = 'https://unstop.com/hackathons',
    this.eligibleYears = const ['1st Year', '2nd Year', '3rd Year', '4th Year'],
    this.eligibleSections = const ['Sec A', 'Sec B', 'Sec C', 'Sec D'],
    this.createdByRole = 'hod',
    this.createdByName = '',
  }) : registrationStartDate = registrationStartDate ?? startDate;

  bool get isRegistered => userRegistrationStatus.toLowerCase() == 'registered';
  bool get isDeadlinePassed => DateTime.now().isAfter(registrationDeadline);
  bool get isDeadlineApproaching => !isDeadlinePassed && registrationDeadline.difference(DateTime.now()).inHours <= 48;
  int get hoursUntilDeadline => registrationDeadline.difference(DateTime.now()).inHours;

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isPublished => status.toLowerCase() == 'published' || status.toLowerCase() == 'upcoming' || status.toLowerCase() == 'ongoing';
  bool get isRegistrationClosed => status.toLowerCase() == 'registration closed' || status.toLowerCase() == 'ended' || !registrationOpen;

  factory HackathonModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val == null) return fallback ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? fallback ?? DateTime.now();
    }

    final start = parseDate(map['startDate'] ?? map['start_date'] ?? map['eventStartDate'] ?? map['event_start_date']);
    final end = parseDate(map['endDate'] ?? map['end_date'] ?? map['eventEndDate'] ?? map['event_end_date']);

    return HackathonModel(
      id: docId ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      organizer: map['organizer']?.toString() ?? 'Organizer',
      mode: map['mode']?.toString() ?? 'Online',
      bannerImage: map['bannerImage']?.toString() ?? map['banner_image']?.toString() ?? '',
      startDate: start,
      endDate: end,
      registrationStartDate: parseDate(map['registrationStartDate'] ?? map['registration_start_date'], start),
      registrationDeadline: parseDate(map['registrationDeadline'] ?? map['registration_deadline']),
      registrationOpen: map['registrationOpen'] ?? map['registration_open'] ?? true,
      prizePool: map['prizePool']?.toString() ?? map['prize_pool']?.toString() ?? '₹0',
      registeredTeams: (map['registeredTeams'] ?? map['registered_teams'] ?? 0) as int,
      maxTeams: (map['maxTeams'] ?? map['max_teams'] ?? 100) as int,
      maxTeamMembers: (map['maxTeamMembers'] ?? map['max_team_members'] ?? 6) as int,
      teamSize: (map['teamSize'] ?? map['team_size'] ?? 6) as int,
      minTeamSize: (map['minTeamSize'] ?? map['min_team_size'] ?? 1) as int,
      status: map['status']?.toString() ?? 'upcoming',
      userRegistrationStatus: map['userRegistrationStatus']?.toString() ?? map['user_registration_status']?.toString() ?? 'not_registered',
      registrationId: map['registrationId']?.toString() ?? map['registration_id']?.toString(),
      registrationLink: map['registrationLink']?.toString() ?? map['registration_link']?.toString(),
      createdBy: map['createdBy']?.toString() ?? map['created_by']?.toString(),
      location: map['location']?.toString() ?? 'Online',
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFeatured: map['isFeatured'] ?? map['is_featured'] ?? false,
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      updatedAt: parseDate(map['updatedAt'] ?? map['updated_at']),
      externalRegistrationUrl: map['externalRegistrationUrl']?.toString() ?? map['external_registration_url']?.toString() ?? 'https://unstop.com/hackathons',
      eligibleYears: (map['eligibleYears'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['1st Year', '2nd Year', '3rd Year', '4th Year'],
      eligibleSections: (map['eligibleSections'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Sec A', 'Sec B', 'Sec C', 'Sec D'],
      createdByRole: map['createdByRole']?.toString() ?? map['created_by_role']?.toString() ?? 'hod',
      createdByName: map['createdByName']?.toString() ?? map['created_by_name']?.toString() ?? '',
    );
  }

  factory HackathonModel.fromJson(String source) => HackathonModel.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'organizer': organizer,
      'mode': mode,
      'bannerImage': bannerImage,
      'banner_image': bannerImage,
      'startDate': startDate.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'eventStartDate': startDate.toIso8601String(),
      'event_start_date': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'eventEndDate': endDate.toIso8601String(),
      'event_end_date': endDate.toIso8601String(),
      'registrationStartDate': registrationStartDate.toIso8601String(),
      'registration_start_date': registrationStartDate.toIso8601String(),
      'registrationDeadline': registrationDeadline.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      'registrationOpen': registrationOpen,
      'registration_open': registrationOpen,
      'prizePool': prizePool,
      'prize_pool': prizePool,
      'registeredTeams': registeredTeams,
      'registered_teams': registeredTeams,
      'maxTeams': maxTeams,
      'max_teams': maxTeams,
      'maxTeamMembers': maxTeamMembers,
      'max_team_members': maxTeamMembers,
      'teamSize': teamSize,
      'team_size': teamSize,
      'minTeamSize': minTeamSize,
      'status': status,
      'userRegistrationStatus': userRegistrationStatus,
      'user_registration_status': userRegistrationStatus,
      'registrationId': registrationId,
      'registration_id': registrationId,
      'registrationLink': registrationLink,
      'registration_link': registrationLink,
      'createdBy': createdBy,
      'created_by': createdBy,
      'location': location,
      'tags': tags,
      'isFeatured': isFeatured,
      'is_featured': isFeatured,
      'createdAt': createdAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'externalRegistrationUrl': externalRegistrationUrl,
      'eligibleYears': eligibleYears,
      'eligibleSections': eligibleSections,
      'createdByRole': createdByRole,
      'createdByName': createdByName,
    };
  }

  String toJson() => json.encode(toMap());

  HackathonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? organizer,
    String? mode,
    String? bannerImage,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationStartDate,
    DateTime? registrationDeadline,
    bool? registrationOpen,
    String? prizePool,
    int? registeredTeams,
    int? maxTeams,
    int? maxTeamMembers,
    int? teamSize,
    int? minTeamSize,
    String? status,
    String? userRegistrationStatus,
    String? registrationId,
    String? registrationLink,
    String? createdBy,
    String? location,
    List<String>? tags,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? externalRegistrationUrl,
    List<String>? eligibleYears,
    List<String>? eligibleSections,
    String? createdByRole,
    String? createdByName,
  }) {
    return HackathonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      organizer: organizer ?? this.organizer,
      mode: mode ?? this.mode,
      bannerImage: bannerImage ?? this.bannerImage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationStartDate: registrationStartDate ?? this.registrationStartDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      registrationOpen: registrationOpen ?? this.registrationOpen,
      prizePool: prizePool ?? this.prizePool,
      registeredTeams: registeredTeams ?? this.registeredTeams,
      maxTeams: maxTeams ?? this.maxTeams,
      maxTeamMembers: maxTeamMembers ?? this.maxTeamMembers,
      teamSize: teamSize ?? this.teamSize,
      minTeamSize: minTeamSize ?? this.minTeamSize,
      status: status ?? this.status,
      userRegistrationStatus: userRegistrationStatus ?? this.userRegistrationStatus,
      registrationId: registrationId ?? this.registrationId,
      registrationLink: registrationLink ?? this.registrationLink,
      createdBy: createdBy ?? this.createdBy,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      externalRegistrationUrl: externalRegistrationUrl ?? this.externalRegistrationUrl,
      eligibleYears: eligibleYears ?? this.eligibleYears,
      eligibleSections: eligibleSections ?? this.eligibleSections,
      createdByRole: createdByRole ?? this.createdByRole,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
