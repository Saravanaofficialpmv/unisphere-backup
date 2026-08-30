

// ── Personal Details ──
class StudentPersonalDetails {
  final String fullName;
  final String registerNumber;
  final String department;
  final String collegeEmail;
  final String batch; // Academic batch range (From - To), e.g. '2023 - 2027'
  final String? profilePhotoUrl;
  final String? dateOfBirth;
  final String? gender;
  final String bloodGroup;
  final String nationality;
  final String religion;
  final String community;
  final String caste;
  final String motherTongue;
  final bool isFirstGraduate;
  final bool isDifferentlyAbled;
  final String? disabilityDetails;

  StudentPersonalDetails({
    required this.fullName,
    required this.registerNumber,
    required this.department,
    required this.collegeEmail,
    this.batch = '2023 - 2027',
    this.profilePhotoUrl,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup = 'O+',
    this.nationality = 'Indian',
    this.religion = 'Hindu',
    this.community = 'OC',
    this.caste = '',
    this.motherTongue = 'Tamil',
    this.isFirstGraduate = false,
    this.isDifferentlyAbled = false,
    this.disabilityDetails,
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'registerNumber': registerNumber,
        'department': department,
        'collegeEmail': collegeEmail,
        'batch': batch,
        'profilePhotoUrl': profilePhotoUrl,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'nationality': nationality,
        'religion': religion,
        'community': community,
        'caste': caste,
        'motherTongue': motherTongue,
        'isFirstGraduate': isFirstGraduate,
        'isDifferentlyAbled': isDifferentlyAbled,
        'disabilityDetails': disabilityDetails,
      };

  factory StudentPersonalDetails.fromMap(Map<String, dynamic> map) =>
      StudentPersonalDetails(
        fullName: map['fullName'] ?? '',
        registerNumber: map['registerNumber'] ?? '',
        department: map['department'] ?? '',
        collegeEmail: map['collegeEmail'] ?? '',
        batch: map['batch'] ?? '2023 - 2027',
        profilePhotoUrl: map['profilePhotoUrl'],
        dateOfBirth: map['dateOfBirth'],
        gender: map['gender'],
        bloodGroup: map['bloodGroup'] ?? 'O+',
        nationality: map['nationality'] ?? 'Indian',
        religion: map['religion'] ?? 'Hindu',
        community: map['community'] ?? 'OC',
        caste: map['caste'] ?? '',
        motherTongue: map['motherTongue'] ?? 'Tamil',
        isFirstGraduate: map['isFirstGraduate'] ?? false,
        isDifferentlyAbled: map['isDifferentlyAbled'] ?? false,
        disabilityDetails: map['disabilityDetails'],
      );
}

// ── Address ──
class StudentAddress {
  final String addressLine1;
  final String? addressLine2;
  final String area;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String country;

  StudentAddress({
    required this.addressLine1,
    this.addressLine2,
    required this.area,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    this.country = 'India',
  });

  Map<String, dynamic> toMap() => {
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'area': area,
        'city': city,
        'district': district,
        'state': state,
        'pincode': pincode,
        'country': country,
      };

  factory StudentAddress.fromMap(Map<String, dynamic> map) => StudentAddress(
        addressLine1: map['addressLine1'] ?? '',
        addressLine2: map['addressLine2'],
        area: map['area'] ?? '',
        city: map['city'] ?? '',
        district: map['district'] ?? '',
        state: map['state'] ?? 'Tamil Nadu',
        pincode: map['pincode'] ?? '',
        country: map['country'] ?? 'India',
      );
}

// ── Contact & Address Details ──
class StudentContactDetails {
  final String primaryMobile;
  final String? alternateMobile;
  final String? personalEmail;
  final String emergencyContactName;
  final String emergencyContactRelationship;
  final String emergencyContactNumber;
  final StudentAddress permanentAddress;
  final bool sameAsPermanent;
  final StudentAddress currentAddress;

  StudentContactDetails({
    required this.primaryMobile,
    this.alternateMobile,
    this.personalEmail,
    required this.emergencyContactName,
    required this.emergencyContactRelationship,
    required this.emergencyContactNumber,
    required this.permanentAddress,
    this.sameAsPermanent = true,
    required this.currentAddress,
  });

  Map<String, dynamic> toMap() => {
        'primaryMobile': primaryMobile,
        'alternateMobile': alternateMobile,
        'personalEmail': personalEmail,
        'emergencyContactName': emergencyContactName,
        'emergencyContactRelationship': emergencyContactRelationship,
        'emergencyContactNumber': emergencyContactNumber,
        'permanentAddress': permanentAddress.toMap(),
        'sameAsPermanent': sameAsPermanent,
        'currentAddress': currentAddress.toMap(),
      };

  factory StudentContactDetails.fromMap(Map<String, dynamic> map) =>
      StudentContactDetails(
        primaryMobile: map['primaryMobile'] ?? '',
        alternateMobile: map['alternateMobile'],
        personalEmail: map['personalEmail'],
        emergencyContactName: map['emergencyContactName'] ?? '',
        emergencyContactRelationship: map['emergencyContactRelationship'] ?? '',
        emergencyContactNumber: map['emergencyContactNumber'] ?? '',
        permanentAddress: StudentAddress.fromMap(
            map['permanentAddress'] as Map<String, dynamic>? ?? {}),
        sameAsPermanent: map['sameAsPermanent'] ?? true,
        currentAddress: StudentAddress.fromMap(
            map['currentAddress'] as Map<String, dynamic>? ?? {}),
      );
}

// ── Parent Individual Record ──
class ParentRecord {
  final String? photoUrl;
  final String name;
  final String mobileNumber;
  final String? email; // OPTIONAL / NULLABLE
  final String qualification;
  final String occupation;
  final String annualIncome;

  ParentRecord({
    this.photoUrl,
    required this.name,
    required this.mobileNumber,
    this.email,
    this.qualification = 'School',
    this.occupation = 'Business / Self-Employed',
    this.annualIncome = '₹1,00,000 - ₹3,00,000',
  });

  Map<String, dynamic> toMap() => {
        'photoUrl': photoUrl,
        'name': name,
        'mobileNumber': mobileNumber,
        'email': email,
        'qualification': qualification,
        'occupation': occupation,
        'annualIncome': annualIncome,
      };

  factory ParentRecord.fromMap(Map<String, dynamic> map) => ParentRecord(
        photoUrl: map['photoUrl'],
        name: map['name'] ?? '',
        mobileNumber: map['mobileNumber'] ?? '',
        email: map['email'],
        qualification: map['qualification'] ?? '',
        occupation: map['occupation'] ?? '',
        annualIncome: map['annualIncome'] ?? '',
      );
}

// ── Guardian Record ──
class GuardianRecord {
  final String? photoUrl;
  final String name;
  final String relationship;
  final String mobileNumber;
  final String? email; // OPTIONAL
  final String qualification;
  final String occupation;
  final String address;

  GuardianRecord({
    this.photoUrl,
    required this.name,
    required this.relationship,
    required this.mobileNumber,
    this.email,
    this.qualification = '',
    this.occupation = '',
    this.address = '',
  });

  Map<String, dynamic> toMap() => {
        'photoUrl': photoUrl,
        'name': name,
        'relationship': relationship,
        'mobileNumber': mobileNumber,
        'email': email,
        'qualification': qualification,
        'occupation': occupation,
        'address': address,
      };

  factory GuardianRecord.fromMap(Map<String, dynamic> map) => GuardianRecord(
        photoUrl: map['photoUrl'],
        name: map['name'] ?? '',
        relationship: map['relationship'] ?? '',
        mobileNumber: map['mobileNumber'] ?? '',
        email: map['email'],
        qualification: map['qualification'] ?? '',
        occupation: map['occupation'] ?? '',
        address: map['address'] ?? '',
      );
}

// ── Parent & Guardian Details ──
class StudentParentDetails {
  final ParentRecord father;
  final ParentRecord mother;
  final GuardianRecord? guardian;
  final String parentAnnualIncome;

  StudentParentDetails({
    required this.father,
    required this.mother,
    this.guardian,
    this.parentAnnualIncome = '₹3,00,000 - ₹5,00,000',
  });

  Map<String, dynamic> toMap() => {
        'father': father.toMap(),
        'mother': mother.toMap(),
        'guardian': guardian?.toMap(),
        'parentAnnualIncome': parentAnnualIncome,
        'annualIncome': parentAnnualIncome,
      };

  factory StudentParentDetails.fromMap(Map<String, dynamic> map) =>
      StudentParentDetails(
        father: ParentRecord.fromMap(
            map['father'] as Map<String, dynamic>? ?? {}),
        mother: ParentRecord.fromMap(
            map['mother'] as Map<String, dynamic>? ?? {}),
        guardian: map['guardian'] != null
            ? GuardianRecord.fromMap(map['guardian'] as Map<String, dynamic>)
            : null,
        parentAnnualIncome: map['parentAnnualIncome'] ??
            map['annualIncome'] ??
            '₹3,00,000 - ₹5,00,000',
      );
}

// ── Education Record ──
class EducationRecord {
  final String institutionName;
  final String? institutionAddress;
  final String boardOrUniversity;
  final String medium;
  final String registerNumber;
  final String passingYear;
  final double totalMarks;
  final double marksObtained;
  final double percentage;

  EducationRecord({
    required this.institutionName,
    this.institutionAddress,
    required this.boardOrUniversity,
    required this.medium,
    required this.registerNumber,
    required this.passingYear,
    required this.totalMarks,
    required this.marksObtained,
    required this.percentage,
  });

  Map<String, dynamic> toMap() => {
        'institutionName': institutionName,
        'institutionAddress': institutionAddress,
        'boardOrUniversity': boardOrUniversity,
        'medium': medium,
        'registerNumber': registerNumber,
        'passingYear': passingYear,
        'totalMarks': totalMarks,
        'marksObtained': marksObtained,
        'percentage': percentage,
      };

  factory EducationRecord.fromMap(Map<String, dynamic> map) => EducationRecord(
        institutionName: map['institutionName'] ?? '',
        institutionAddress: map['institutionAddress'],
        boardOrUniversity: map['boardOrUniversity'] ?? '',
        medium: map['medium'] ?? 'English',
        registerNumber: map['registerNumber'] ?? '',
        passingYear: map['passingYear'] ?? '',
        totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 500.0,
        marksObtained: (map['marksObtained'] as num?)?.toDouble() ?? 0.0,
        percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}

class StudentPreviousEducation {
  final EducationRecord tenth;
  final EducationRecord twelfthOrDiploma;
  final EducationRecord? diploma;
  final bool hasDiploma;

  StudentPreviousEducation({
    required this.tenth,
    required this.twelfthOrDiploma,
    this.diploma,
    this.hasDiploma = false,
  });

  Map<String, dynamic> toMap() => {
        'tenth': tenth.toMap(),
        'twelfthOrDiploma': twelfthOrDiploma.toMap(),
        'diploma': diploma?.toMap(),
        'hasDiploma': hasDiploma,
      };

  factory StudentPreviousEducation.fromMap(Map<String, dynamic> map) =>
      StudentPreviousEducation(
        tenth: EducationRecord.fromMap(
            map['tenth'] as Map<String, dynamic>? ?? {}),
        twelfthOrDiploma: EducationRecord.fromMap(
            map['twelfthOrDiploma'] as Map<String, dynamic>? ?? {}),
        diploma: map['diploma'] != null
            ? EducationRecord.fromMap(map['diploma'] as Map<String, dynamic>)
            : null,
        hasDiploma: map['hasDiploma'] ?? (map['diploma'] != null),
      );
}

// ── Living & Accommodation Details ──
enum LivingType { collegeHostel, homeFamily, pgHostel, rentedHouse, relativeHome }

class StudentLivingDetails {
  final LivingType livingType;
  final Map<String, dynamic> details;

  bool get isDayScholar => livingType != LivingType.collegeHostel;

  StudentLivingDetails({
    required this.livingType,
    required this.details,
  });

  Map<String, dynamic> toMap() => {
        'livingType': livingType.name,
        'details': details,
      };

  factory StudentLivingDetails.fromMap(Map<String, dynamic> map) {
    LivingType type = LivingType.homeFamily;
    final typeStr = map['livingType']?.toString() ?? '';
    for (var lt in LivingType.values) {
      if (lt.name == typeStr) {
        type = lt;
        break;
      }
    }
    return StudentLivingDetails(
      livingType: type,
      details: map['details'] as Map<String, dynamic>? ?? {},
    );
  }
}

// ── Day Scholar Transport Details (STRICTLY ONLY: BUS, BIKE, WALK) ──
// ignore: constant_identifier_names
enum PrimaryTransportMode { BUS, BIKE, WALK }

class StudentTransportDetails {
  final PrimaryTransportMode mode;
  final Map<String, dynamic> modeDetails;
  final String oneWayDistanceKm;
  final String oneWayTravelTimeMinutes;
  final String usualArrivalTime;
  final String usualDepartureTime;

  StudentTransportDetails({
    required this.mode,
    required this.modeDetails,
    required this.oneWayDistanceKm,
    required this.oneWayTravelTimeMinutes,
    required this.usualArrivalTime,
    required this.usualDepartureTime,
  });

  Map<String, dynamic> toMap() => {
        'mode': mode.name,
        'modeDetails': modeDetails,
        'oneWayDistanceKm': oneWayDistanceKm,
        'oneWayTravelTimeMinutes': oneWayTravelTimeMinutes,
        'usualArrivalTime': usualArrivalTime,
        'usualDepartureTime': usualDepartureTime,
      };

  factory StudentTransportDetails.fromMap(Map<String, dynamic> map) {
    PrimaryTransportMode pMode = PrimaryTransportMode.BUS;
    final mStr = map['mode']?.toString().toUpperCase() ?? 'BUS';
    if (mStr == 'BIKE') pMode = PrimaryTransportMode.BIKE;
    if (mStr == 'WALK') pMode = PrimaryTransportMode.WALK;

    return StudentTransportDetails(
      mode: pMode,
      modeDetails: map['modeDetails'] as Map<String, dynamic>? ?? {},
      oneWayDistanceKm: map['oneWayDistanceKm']?.toString() ?? '10 km',
      oneWayTravelTimeMinutes: map['oneWayTravelTimeMinutes']?.toString() ?? '25 mins',
      usualArrivalTime: map['usualArrivalTime']?.toString() ?? '08:30 AM',
      usualDepartureTime: map['usualDepartureTime']?.toString() ?? '05:00 PM',
    );
  }
}

// ── Student Document Record ──
class StudentDocument {
  final String id;
  final String name;
  final bool isRequired;
  final String fileUrl;
  final String fileName;
  final String status; // pending, verified, rejected
  final String? verificationNotes;

  StudentDocument({
    required this.id,
    required this.name,
    this.isRequired = true,
    required this.fileUrl,
    required this.fileName,
    this.status = 'pending',
    this.verificationNotes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isRequired': isRequired,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'status': status,
        'verificationNotes': verificationNotes,
      };

  factory StudentDocument.fromMap(Map<String, dynamic> map) => StudentDocument(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        isRequired: map['isRequired'] ?? true,
        fileUrl: map['fileUrl'] ?? '',
        fileName: map['fileName'] ?? '',
        status: map['status'] ?? 'pending',
        verificationNotes: map['verificationNotes'],
      );
}

// ── Full Complete Student 360° Profile Model ──
class FullStudentProfileModel {
  final String studentUid;
  final String completionStatus; // incomplete, submitted, verified
  final int completionPercentage;
  final StudentPersonalDetails personal;
  final StudentContactDetails contact;
  final StudentParentDetails parents;
  final StudentPreviousEducation education;
  final StudentLivingDetails living;
  final StudentTransportDetails? transport;
  final List<StudentDocument> documents;
  final String? submittedAt;
  final String? verifiedAt;

  FullStudentProfileModel({
    required this.studentUid,
    this.completionStatus = 'incomplete',
    this.completionPercentage = 10,
    required this.personal,
    required this.contact,
    required this.parents,
    required this.education,
    required this.living,
    this.transport,
    required this.documents,
    this.submittedAt,
    this.verifiedAt,
  });

  Map<String, dynamic> toMap() => {
        'studentUid': studentUid,
        'completionStatus': completionStatus,
        'completionPercentage': completionPercentage,
        'personal': personal.toMap(),
        'contact': contact.toMap(),
        'parents': parents.toMap(),
        'education': education.toMap(),
        'living': living.toMap(),
        'transport': transport?.toMap(),
        'documents': documents.map((d) => d.toMap()).toList(),
        'submittedAt': submittedAt,
        'verifiedAt': verifiedAt,
      };

  factory FullStudentProfileModel.fromMap(Map<String, dynamic> map, String uid) =>
      FullStudentProfileModel(
        studentUid: uid,
        completionStatus: map['completionStatus'] ?? 'incomplete',
        completionPercentage: (map['completionPercentage'] as num?)?.toInt() ?? 10,
        personal: StudentPersonalDetails.fromMap(
            map['personal'] as Map<String, dynamic>? ?? {}),
        contact: StudentContactDetails.fromMap(
            map['contact'] as Map<String, dynamic>? ?? {}),
        parents: StudentParentDetails.fromMap(
            map['parents'] as Map<String, dynamic>? ?? {}),
        education: StudentPreviousEducation.fromMap(
            map['education'] as Map<String, dynamic>? ?? {}),
        living: StudentLivingDetails.fromMap(
            map['living'] as Map<String, dynamic>? ?? {}),
        transport: map['transport'] != null
            ? StudentTransportDetails.fromMap(map['transport'] as Map<String, dynamic>)
            : null,
        documents: (map['documents'] as List? ?? [])
            .map((d) => StudentDocument.fromMap(d as Map<String, dynamic>))
            .toList(),
        submittedAt: map['submittedAt'],
        verifiedAt: map['verifiedAt'],
      );
}

// ── Profile Edit Request Items ──
class EditRequestItem {
  final String category;
  final String fieldName;
  final String label;
  final String currentValue;
  final String requestedValue;
  final String status; // pending, approved, rejected
  final String? rejectionReason;

  EditRequestItem({
    required this.category,
    required this.fieldName,
    required this.label,
    required this.currentValue,
    required this.requestedValue,
    this.status = 'pending',
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() => {
        'category': category,
        'fieldName': fieldName,
        'label': label,
        'currentValue': currentValue,
        'requestedValue': requestedValue,
        'status': status,
        'rejectionReason': rejectionReason,
      };

  factory EditRequestItem.fromMap(Map<String, dynamic> map) => EditRequestItem(
        category: map['category'] ?? '',
        fieldName: map['fieldName'] ?? '',
        label: map['label'] ?? '',
        currentValue: map['currentValue'] ?? '',
        requestedValue: map['requestedValue'] ?? '',
        status: map['status'] ?? 'pending',
        rejectionReason: map['rejectionReason'],
      );
}

// ── Profile Edit Request ──
class ProfileEditRequest {
  final String requestId;
  final String studentUid;
  final String studentName;
  final String registerNumber;
  final String department;
  final String batch;
  final String academicYear;
  final String section;
  final String reason;
  final String? documentUrl;
  final List<EditRequestItem> items;
  final String status; // pending_advisor, partially_approved, approved, rejected
  final String? assignedAdvisorId;
  final String? advisorComments;
  final String createdAt;
  final String? processedAt;

  ProfileEditRequest({
    required this.requestId,
    required this.studentUid,
    required this.studentName,
    required this.registerNumber,
    required this.department,
    required this.batch,
    required this.academicYear,
    required this.section,
    required this.reason,
    this.documentUrl,
    required this.items,
    this.status = 'pending_advisor',
    this.assignedAdvisorId,
    this.advisorComments,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'studentUid': studentUid,
        'studentName': studentName,
        'registerNumber': registerNumber,
        'department': department,
        'batch': batch,
        'academicYear': academicYear,
        'section': section,
        'reason': reason,
        'documentUrl': documentUrl,
        'items': items.map((i) => i.toMap()).toList(),
        'status': status,
        'assignedAdvisorId': assignedAdvisorId,
        'advisorComments': advisorComments,
        'createdAt': createdAt,
        'processedAt': processedAt,
      };

  factory ProfileEditRequest.fromMap(Map<String, dynamic> map, String id) =>
      ProfileEditRequest(
        requestId: id,
        studentUid: map['studentUid'] ?? '',
        studentName: map['studentName'] ?? '',
        registerNumber: map['registerNumber'] ?? '',
        department: map['department'] ?? '',
        batch: map['batch'] ?? '',
        academicYear: map['academicYear'] ?? '',
        section: map['section'] ?? '',
        reason: map['reason'] ?? '',
        documentUrl: map['documentUrl'],
        items: (map['items'] as List? ?? [])
            .map((i) => EditRequestItem.fromMap(i as Map<String, dynamic>))
            .toList(),
        status: map['status'] ?? 'pending_advisor',
        assignedAdvisorId: map['assignedAdvisorId'],
        advisorComments: map['advisorComments'],
        createdAt: map['createdAt'] ?? '',
        processedAt: map['processedAt'],
      );
}
