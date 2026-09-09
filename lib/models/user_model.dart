enum UserRole { admin, student, staff, parent, hod, advisor, unknown }

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final bool profileCompleted;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.uid,
    required this.email,
    String? fullName,
    String? name,
    required this.role,
    String? phone,
    String? phoneNumber,
    this.isActive = true,
    this.profileCompleted = true,
    this.profileImageUrl,
    DateTime? createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.metadata,
  })  : fullName = (fullName != null && fullName.isNotEmpty)
            ? fullName
            : ((name != null && name.isNotEmpty)
                ? name
                : (email.contains('@') ? email.split('@').first : 'User')),
        phone = (phone != null && phone.isNotEmpty)
            ? phone
            : (phoneNumber ?? ''),
        createdAt = (createdAt != null && !isTodayOrLoginDate(createdAt, lastLoginAt))
            ? createdAt
            : resolveDefaultCreatedAt(uid, metadata, email, role);

  String get name => fullName;
  String? get phoneNumber => phone;

  String? get department =>
      metadata?['department']?.toString() ?? metadata?['departmentName']?.toString();

  String? get departmentName =>
      metadata?['departmentName']?.toString() ?? metadata?['department']?.toString();

  String? get departmentId =>
      metadata?['departmentId']?.toString() ?? metadata?['department_id']?.toString();

  bool get isAdvisor => metadata?['isAdvisor'] == true || role == UserRole.advisor;

  String? get registerNumber =>
      metadata?['registerNumber']?.toString() ??
      metadata?['regNo']?.toString() ??
      metadata?['registrationNumber']?.toString() ??
      metadata?['studentId']?.toString();

  static bool isTodayOrLoginDate(DateTime date, DateTime? lastLogin) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isLogin = lastLogin != null &&
        date.year == lastLogin.year &&
        date.month == lastLogin.month &&
        date.day == lastLogin.day;
    return isToday || isLogin;
  }

  static DateTime resolveDefaultCreatedAt(String uid, Map<String, dynamic>? metadata, [String? email, UserRole? role]) {
    if (metadata != null) {
      final raw = metadata['accountCreatedAt'] ??
          metadata['registrationDate'] ??
          metadata['admissionDate'] ??
          metadata['joiningDate'] ??
          metadata['createdAt'] ??
          metadata['created_at'];
      if (raw is DateTime) {
        if (!isTodayOrLoginDate(raw, null)) return raw;
      } else if (raw != null) {
        try {
          final dynamic dyn = raw;
          if (dyn.toDate is Function) {
            final dt = dyn.toDate() as DateTime;
            if (!isTodayOrLoginDate(dt, null)) return dt;
          }
        } catch (_) {}
        final parsed = DateTime.tryParse(raw.toString());
        if (parsed != null && !isTodayOrLoginDate(parsed, null)) return parsed;
      }
    }

    return DateTime.now();
  }

  String get formattedCreatedAt {
    DateTime? date = createdAt;
    if (date == null || isTodayOrLoginDate(date, lastLoginAt)) {
      date = resolveDefaultCreatedAt(uid, metadata, email, role);
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      try {
        final dynamic dyn = val;
        if (dyn.toDate is Function) return dyn.toDate() as DateTime;
      } catch (_) {}
      return DateTime.tryParse(val.toString());
    }

    final nameVal = map['fullName'] ?? map['name'] ?? map['full_name'] ?? '';
    final phoneVal = map['phone'] ?? map['phone_number'] ?? map['phoneNumber'] ?? '';

    final metaMap = map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : <String, dynamic>{};
    if (map['batch'] != null && map['batch'].toString().isNotEmpty) {
      metaMap['batch'] = map['batch'].toString();
    }
    if (map['department'] != null && map['department'].toString().isNotEmpty && metaMap['department'] == null) {
      metaMap['department'] = map['department'].toString();
    }
    if (map['departmentName'] != null && map['departmentName'].toString().isNotEmpty && metaMap['departmentName'] == null) {
      metaMap['departmentName'] = map['departmentName'].toString();
    }
    if (map['departmentId'] != null && map['departmentId'].toString().isNotEmpty && metaMap['departmentId'] == null) {
      metaMap['departmentId'] = map['departmentId'].toString();
    }
    if (map['department_id'] != null && map['department_id'].toString().isNotEmpty && metaMap['department_id'] == null) {
      metaMap['department_id'] = map['department_id'].toString();
    }

    final rawRole = map['role'] ?? map['userRole'] ?? map['user_role'] ?? metaMap['role'] ?? metaMap['userRole'];
    UserRole parsedRole = _parseRole(rawRole?.toString());

    final rawEmail = (map['email'] ?? metaMap['email'] ?? metaMap['collegeEmail'] ?? '').toString().trim().toLowerCase();
    DateTime? creationDate = parseDate(map['createdAt'] ?? map['created_at'] ?? metaMap['createdAt'] ?? metaMap['created_at'] ?? metaMap['accountCreatedAt']);
    final loginDate = parseDate(map['lastLoginAt'] ?? map['last_login_at']);
    if (creationDate == null || isTodayOrLoginDate(creationDate, loginDate)) {
      creationDate = resolveDefaultCreatedAt(id, metaMap, rawEmail, parsedRole);
    }

    if (parsedRole == UserRole.student || parsedRole == UserRole.unknown) {
      final hasWards = map['wardRegisterNumbers'] != null ||
          map['childRegisterNumbers'] != null ||
          map['wards'] != null ||
          metaMap['wardRegisterNumbers'] != null ||
          metaMap['childRegisterNumbers'] != null ||
          metaMap['studentIds'] != null;
      if (hasWards) {
        parsedRole = UserRole.parent;
      } else if (map['isAdvisor'] == true || metaMap['isAdvisor'] == true) {
        parsedRole = UserRole.advisor;
      } else if (map['staffId'] != null ||
          map['employeeId'] != null ||
          metaMap['staffId'] != null ||
          metaMap['employeeId'] != null) {
        parsedRole = UserRole.staff;
      }
    }

    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      fullName: nameVal.toString(),
      role: parsedRole,
      phone: phoneVal.toString(),
      isActive: map['isActive'] ?? map['is_active'] ?? true,
      profileCompleted: map['profileCompleted'] ?? map['profile_completed'] ?? true,
      profileImageUrl: map['profileImageUrl'] ?? map['profile_image_url'],
      createdAt: creationDate,
      updatedAt: parseDate(map['updatedAt'] ?? map['updated_at']),
      lastLoginAt: parseDate(map['lastLoginAt'] ?? map['last_login_at']),
      metadata: metaMap.isNotEmpty ? metaMap : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'name': fullName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'profileCompleted': profileCompleted,
      'profile_image_url': profileImageUrl,
      'profileImageUrl': profileImageUrl,
      if (metadata?['batch'] != null) 'batch': metadata!['batch'],
      if (department != null) 'department': department,
      if (departmentName != null) 'departmentName': departmentName,
      if (departmentId != null) 'departmentId': departmentId,
      'createdAt': (createdAt != null && !isTodayOrLoginDate(createdAt!, lastLoginAt))
          ? createdAt!.toIso8601String()
          : resolveDefaultCreatedAt(uid, metadata, email, role).toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get roleName {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.hod:
        return 'HOD / Department Admin';
      case UserRole.advisor:
        return 'Class Advisor';
      case UserRole.staff:
        return 'Staff / Faculty';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent / Guardian';
      default:
        return 'User';
    }
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? name,
    String? email,
    String? phone,
    String? phoneNumber,
    UserRole? role,
    bool? isActive,
    bool? profileCompleted,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? name ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? phoneNumber ?? this.phone,
      isActive: isActive ?? this.isActive,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }


  List<UserRole> get availableRoles {
    final list = <UserRole>[role];
    if (metadata != null) {
      final rawRoles = metadata!['availableRoles'] ?? metadata!['roles'];
      if (rawRoles is List) {
        for (final r in rawRoles) {
          final parsed = parseRole(r.toString());
          if (parsed != UserRole.unknown && !list.contains(parsed)) {
            list.add(parsed);
          }
        }
      }
      if (metadata!['isAdvisor'] == true && !list.contains(UserRole.advisor)) {
        list.add(UserRole.advisor);
      }
    }
    return list;
  }

  List<String> get availableInstitutions {
    final list = <String>[];
    if (metadata != null) {
      final rawInsts = metadata!['availableInstitutions'] ?? metadata!['institutions'];
      if (rawInsts is List) {
        for (final inst in rawInsts) {
          if (inst != null && inst.toString().trim().isNotEmpty) {
            final str = inst.toString().trim();
            if (!list.contains(str)) list.add(str);
          }
        }
      }
      final primary = metadata!['institutionName'] ?? metadata!['collegeName'] ?? metadata!['institution'];
      if (primary != null && primary.toString().trim().isNotEmpty) {
        final str = primary.toString().trim();
        if (!list.contains(str)) list.add(str);
      }
    }
    if (list.isEmpty) {
      list.add('VSB Engineering College');
    }
    return list;
  }

  static UserRole parseRole(String? role) => _parseRole(role);

  static UserRole _parseRole(String? role) {
    if (role == null) return UserRole.student;
    final r = role.toLowerCase().trim();
    if (r == 'admin' ||
        r == 'administrator' ||
        r == 'superadmin' ||
        r == 'userrole.admin') {
      return UserRole.admin;
    }
    if (r == 'hod' ||
        r == 'head of department' ||
        r == 'department (hod)' ||
        r == 'department(hod)' ||
        r == 'department hod' ||
        r == 'dept head' ||
        r == 'department head' ||
        r == 'userrole.hod') {
      return UserRole.hod;
    }
    if (r == 'staff' ||
        r == 'faculty' ||
        r == 'teacher' ||
        r == 'professor' ||
        r == 'staff / faculty' ||
        r == 'faculty / staff' ||
        r == 'userrole.staff') {
      return UserRole.staff;
    }
    if (r == 'advisor' || r == 'class advisor' || r == 'userrole.advisor') {
      return UserRole.advisor;
    }
    if (r == 'parent' ||
        r == 'guardian' ||
        r == 'parent / guardian' ||
        r == 'parent/guardian' ||
        r == 'userrole.parent') {
      return UserRole.parent;
    }
    if (r == 'student' || r == 'userrole.student' || r == 'pupil' || r == 'learner') {
      return UserRole.student;
    }
    return UserRole.unknown;
  }
}

