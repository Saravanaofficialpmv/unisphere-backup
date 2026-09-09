class StaffCourse {
  final String code;
  final String name;
  final String yearSemester;
  final String section;
  final int studentCount;
  final String room;

  const StaffCourse({
    required this.code,
    required this.name,
    required this.yearSemester,
    required this.section,
    required this.studentCount,
    required this.room,
  });
}

class StaffLeaveRecord {
  final String id;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final int days;
  final String status; // Approved, Pending, Rejected
  final String reason;

  const StaffLeaveRecord({
    required this.id,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.status,
    required this.reason,
  });
}

class StaffDocument {
  final String id;
  final String title;
  final String fileType;
  final String fileSize;
  final String uploadDate;
  final String status;

  const StaffDocument({
    required this.id,
    required this.title,
    required this.fileType,
    required this.fileSize,
    required this.uploadDate,
    required this.status,
  });
}

class StaffDetailsModel {
  final String id;
  final String name;
  final String designation;
  final String department;
  final String qualification;
  final String specialization;
  final String joiningDate;
  final String experience;
  final String employmentType;
  final String status;
  final String phone;
  final String email;
  final String dob;
  final String gender;
  final String address;
  final String photoUrl;
  final String bloodGroup;
  final String emergencyContact;
  final String staffCategory;
  final int coursesCount;
  final int studentsAssigned;
  final int classesThisWeek;
  final int attendancePercentage;
  final List<StaffCourse> courses;
  final List<StaffLeaveRecord> leaveHistory;
  final List<StaffDocument> documents;

  const StaffDetailsModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.qualification,
    required this.specialization,
    required this.joiningDate,
    required this.experience,
    required this.employmentType,
    required this.status,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    required this.address,
    required this.photoUrl,
    this.bloodGroup = "-",
    this.emergencyContact = "-",
    this.staffCategory = "Teaching Faculty",
    required this.coursesCount,
    required this.studentsAssigned,
    required this.classesThisWeek,
    required this.attendancePercentage,
    required this.courses,
    required this.leaveHistory,
    required this.documents,
  });

  StaffDetailsModel copyWith({
    String? id,
    String? name,
    String? designation,
    String? department,
    String? qualification,
    String? specialization,
    String? joiningDate,
    String? experience,
    String? employmentType,
    String? status,
    String? phone,
    String? email,
    String? dob,
    String? gender,
    String? address,
    String? photoUrl,
    String? bloodGroup,
    String? emergencyContact,
    String? staffCategory,
    int? coursesCount,
    int? studentsAssigned,
    int? classesThisWeek,
    int? attendancePercentage,
    List<StaffCourse>? courses,
    List<StaffLeaveRecord>? leaveHistory,
    List<StaffDocument>? documents,
  }) {
    return StaffDetailsModel(
      id: id ?? this.id,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      qualification: qualification ?? this.qualification,
      specialization: specialization ?? this.specialization,
      joiningDate: joiningDate ?? this.joiningDate,
      experience: experience ?? this.experience,
      employmentType: employmentType ?? this.employmentType,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      staffCategory: staffCategory ?? this.staffCategory,
      coursesCount: coursesCount ?? this.coursesCount,
      studentsAssigned: studentsAssigned ?? this.studentsAssigned,
      classesThisWeek: classesThisWeek ?? this.classesThisWeek,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      courses: courses ?? this.courses,
      leaveHistory: leaveHistory ?? this.leaveHistory,
      documents: documents ?? this.documents,
    );
  }

  static StaffDetailsModel get defaultTharaniKumar => const StaffDetailsModel(
        id: "",
        name: "Staff Member",
        designation: "Faculty",
        department: "",
        qualification: "",
        specialization: "",
        joiningDate: "-",
        experience: "-",
        employmentType: "Permanent",
        status: "Active",
        phone: "-",
        email: "",
        dob: "-",
        gender: "-",
        address: "-",
        photoUrl: "",
        bloodGroup: "-",
        emergencyContact: "-",
        staffCategory: "Teaching Faculty",
        coursesCount: 0,
        studentsAssigned: 0,
        classesThisWeek: 0,
        attendancePercentage: 0,
        courses: [],
        leaveHistory: [],
        documents: [],
      );
}
