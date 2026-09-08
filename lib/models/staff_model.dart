class StaffModel {
  final String userId;
  final String employeeId;
  final String fullName;
  final String? email;
  final String departmentId;
  final String departmentName;
  final String? institutionId;
  final String designation;
  final String specialization;
  final String? photoPath;
  final List<String> assignedClasses;
  final List<String> assignedSubjects;
  final String? qualification;
  final int experienceYears;
  final String? officeLocation;
  final bool isHod;
  final bool isAdvisor;
  final String? advisorSection;
  final String? advisorClassId;
  final String? advisorAcademicYear;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StaffModel({
    required this.userId,
    required this.employeeId,
    required this.fullName,
    this.email,
    required this.departmentId,
    required this.departmentName,
    this.institutionId,
    required this.designation,
    required this.specialization,
    this.photoPath,
    required this.assignedClasses,
    required this.assignedSubjects,
    this.qualification,
    this.experienceYears = 0,
    this.officeLocation,
    this.isHod = false,
    this.isAdvisor = false,
    this.advisorSection,
    this.advisorClassId,
    this.advisorAcademicYear,
    this.createdAt,
    this.updatedAt,
  });

  bool get isClassAdvisor => isAdvisor && (advisorSection != null || advisorClassId != null);
  String get name => fullName;
  bool get hasAdvisorPrivileges => isAdvisor || isHod;

  String get roleTitle => isAdvisor
      ? (advisorSection != null && advisorSection!.isNotEmpty
          ? 'Class Advisor ($advisorSection)'
          : 'Class Advisor')
      : 'Teaching Faculty';

  StaffModel copyWith({
    String? userId,
    String? employeeId,
    String? fullName,
    String? email,
    String? departmentId,
    String? departmentName,
    String? institutionId,
    String? designation,
    String? specialization,
    String? photoPath,
    List<String>? assignedClasses,
    List<String>? assignedSubjects,
    String? qualification,
    int? experienceYears,
    String? officeLocation,
    bool? isHod,
    bool? isAdvisor,
    String? advisorSection,
    String? advisorClassId,
    String? advisorAcademicYear,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffModel(
      userId: userId ?? this.userId,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      institutionId: institutionId ?? this.institutionId,
      designation: designation ?? this.designation,
      specialization: specialization ?? this.specialization,
      photoPath: photoPath ?? this.photoPath,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      assignedSubjects: assignedSubjects ?? this.assignedSubjects,
      qualification: qualification ?? this.qualification,
      experienceYears: experienceYears ?? this.experienceYears,
      officeLocation: officeLocation ?? this.officeLocation,
      isHod: isHod ?? this.isHod,
      isAdvisor: isAdvisor ?? this.isAdvisor,
      advisorSection: advisorSection ?? this.advisorSection,
      advisorClassId: advisorClassId ?? this.advisorClassId,
      advisorAcademicYear: advisorAcademicYear ?? this.advisorAcademicYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StaffModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return StaffModel(
      userId: id,
      employeeId: map['employeeId'] ?? map['employee_id'] ?? id,
      fullName: map['fullName'] ?? map['name'] ?? map['full_name'] ?? 'Staff Member',
      email: map['email']?.toString(),
      departmentId: map['departmentId'] ?? map['department_id'] ?? 'DEPT-CSE',
      departmentName: map['departmentName'] ?? map['department_name'] ?? 'Computer Science',
      institutionId: map['institutionId'] ?? map['institution_id'],
      designation: map['designation'] ?? 'Assistant Professor',
      specialization: map['specialization'] ?? 'Computer Science',
      photoPath: map['photoPath'] ?? map['photo_path'],
      assignedClasses: List<String>.from(map['assignedClasses'] ?? map['assigned_classes'] ?? []),
      assignedSubjects: List<String>.from(map['assignedSubjects'] ?? map['assigned_subjects'] ?? []),
      qualification: map['qualification'],
      experienceYears: int.tryParse(map['experienceYears']?.toString() ?? map['experience_years']?.toString() ?? '0') ?? 0,
      officeLocation: map['officeLocation'] ?? map['office_location'],
      isHod: map['isHod'] ?? map['is_hod'] ?? false,
      isAdvisor: map['isAdvisor'] ?? map['is_advisor'] ?? map['isClassAdvisor'] ?? false,
      advisorSection: map['advisorSection'] ?? map['advisor_section'] ?? map['advisorClass'],
      advisorClassId: map['advisorClassId'] ?? map['advisor_class_id'],
      advisorAcademicYear: map['advisorAcademicYear'] ?? map['advisor_academic_year'] ?? '2025–26',
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      updatedAt: parseDate(map['updatedAt'] ?? map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'user_id': userId,
      'employeeId': employeeId,
      'employee_id': employeeId,
      'fullName': fullName,
      'name': fullName,
      if (email != null) 'email': email,
      'departmentId': departmentId,
      'department_id': departmentId,
      'departmentName': departmentName,
      'department_name': departmentName,
      if (institutionId != null) 'institutionId': institutionId,
      if (institutionId != null) 'institution_id': institutionId,
      'designation': designation,
      'specialization': specialization,
      'photoPath': photoPath,
      'photo_path': photoPath,
      'assignedClasses': assignedClasses,
      'assigned_classes': assignedClasses,
      'assignedSubjects': assignedSubjects,
      'assigned_subjects': assignedSubjects,
      'qualification': qualification,
      'experienceYears': experienceYears,
      'officeLocation': officeLocation,
      'isHod': isHod,
      'is_hod': isHod,
      'isAdvisor': isAdvisor,
      'is_advisor': isAdvisor,
      'isClassAdvisor': isClassAdvisor,
      'advisorSection': advisorSection,
      'advisor_section': advisorSection,
      'advisorClassId': advisorClassId,
      'advisor_class_id': advisorClassId,
      'advisorAcademicYear': advisorAcademicYear,
      'advisor_academic_year': advisorAcademicYear,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
