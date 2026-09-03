class StaffModel {
  final String userId;
  final String employeeId;
  final String fullName;
  final String departmentId;
  final String departmentName;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StaffModel({
    required this.userId,
    required this.employeeId,
    required this.fullName,
    required this.departmentId,
    required this.departmentName,
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
    this.createdAt,
    this.updatedAt,
  });

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
      departmentId: map['departmentId'] ?? map['department_id'] ?? 'DEPT-CSE',
      departmentName: map['departmentName'] ?? map['department_name'] ?? 'Computer Science',
      designation: map['designation'] ?? 'Assistant Professor',
      specialization: map['specialization'] ?? 'Computer Science',
      photoPath: map['photoPath'] ?? map['photo_path'],
      assignedClasses: List<String>.from(map['assignedClasses'] ?? map['assigned_classes'] ?? []),
      assignedSubjects: List<String>.from(map['assignedSubjects'] ?? map['assigned_subjects'] ?? []),
      qualification: map['qualification'],
      experienceYears: (map['experienceYears'] ?? map['experience_years'] ?? 0) as int,
      officeLocation: map['officeLocation'] ?? map['office_location'],
      isHod: map['isHod'] ?? map['is_hod'] ?? false,
      isAdvisor: map['isAdvisor'] ?? map['is_advisor'] ?? false,
      advisorSection: map['advisorSection'] ?? map['advisor_section'],
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
      'departmentId': departmentId,
      'department_id': departmentId,
      'departmentName': departmentName,
      'department_name': departmentName,
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
      'advisorSection': advisorSection,
      'advisor_section': advisorSection,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

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
    String? departmentId,
    String? departmentName,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffModel(
      userId: userId ?? this.userId,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
