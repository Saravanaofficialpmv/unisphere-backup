class DepartmentModel {
  final String departmentId;
  final String name;
  final String code;
  final String? hodId;
  final String? hodName;
  final int totalStudents;
  final int totalFaculty;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DepartmentModel({
    required this.departmentId,
    required this.name,
    required this.code,
    this.hodId,
    this.hodName,
    this.totalStudents = 0,
    this.totalFaculty = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get departmentName => name;
  String get departmentCode => code;

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final deptName = map['name'] ?? map['department_name'] ?? map['departmentName'] ?? '';
    final deptCode = map['code'] ?? map['department_code'] ?? map['departmentCode'] ?? '';

    return DepartmentModel(
      departmentId: id,
      name: deptName.toString(),
      code: deptCode.toString(),
      hodId: map['hodId'] ?? map['hod_id'],
      hodName: map['hodName'] ?? map['hod_name'],
      totalStudents: int.tryParse(map['totalStudents']?.toString() ?? map['total_students']?.toString() ?? '') ?? 0,
      totalFaculty: int.tryParse(map['totalFaculty']?.toString() ?? map['total_faculty']?.toString() ?? '') ?? 0,
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      updatedAt: parseDate(map['updatedAt'] ?? map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'department_id': departmentId,
      'name': name,
      'department_name': name,
      'departmentName': name,
      'code': code,
      'department_code': code,
      'departmentCode': code,
      'hodId': hodId,
      'hod_id': hodId,
      'hodName': hodName,
      'hod_name': hodName,
      'totalStudents': totalStudents,
      'total_students': totalStudents,
      'totalFaculty': totalFaculty,
      'total_faculty': totalFaculty,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

