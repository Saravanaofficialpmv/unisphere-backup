class StaffTaskModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String assignedBy;
  final String assignedDate;
  final String dueDate;
  final String year;
  final String department;
  final String section;
  final int studentsAssigned;
  final int submissions;
  final int pending;
  final int maxMarks;
  final String priority;
  final String status; // 'Active', 'Pending', 'Completed', 'Overdue'
  final String taskType;
  final String? instructions;
  final String? attachmentUrl;

  const StaffTaskModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.assignedBy,
    required this.assignedDate,
    required this.dueDate,
    required this.year,
    required this.department,
    required this.section,
    required this.studentsAssigned,
    required this.submissions,
    required this.pending,
    required this.maxMarks,
    required this.priority,
    required this.status,
    this.taskType = "Mini Project",
    this.instructions,
    this.attachmentUrl,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  double get submissionRate => studentsAssigned > 0 ? (submissions / studentsAssigned) * 100 : 0.0;

  StaffTaskModel copyWith({
    String? title,
    String? subject,
    String? description,
    String? dueDate,
    int? studentsAssigned,
    int? submissions,
    int? pending,
    int? maxMarks,
    String? priority,
    String? status,
  }) {
    return StaffTaskModel(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      assignedBy: assignedBy,
      assignedDate: assignedDate,
      dueDate: dueDate ?? this.dueDate,
      year: year,
      department: department,
      section: section,
      studentsAssigned: studentsAssigned ?? this.studentsAssigned,
      submissions: submissions ?? this.submissions,
      pending: pending ?? this.pending,
      maxMarks: maxMarks ?? this.maxMarks,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      taskType: taskType,
      instructions: instructions,
      attachmentUrl: attachmentUrl,
    );
  }

  factory StaffTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return StaffTaskModel(
      id: id,
      title: map['title'] ?? 'Task',
      subject: map['subject'] ?? 'General',
      description: map['description'] ?? '',
      assignedBy: map['assignedBy'] ?? map['assigned_by'] ?? 'Staff',
      assignedDate: map['assignedDate'] ?? map['assigned_date'] ?? 'Today',
      dueDate: map['dueDate'] ?? map['due_date'] ?? 'Due Soon',
      year: map['year'] ?? 'III Year',
      department: map['department'] ?? 'CSE',
      section: map['section'] ?? 'A',
      studentsAssigned: (map['studentsAssigned'] ?? map['students_assigned'] ?? 0) as int,
      submissions: (map['submissions'] ?? 0) as int,
      pending: (map['pending'] ?? 0) as int,
      maxMarks: (map['maxMarks'] ?? map['max_marks'] ?? 20) as int,
      priority: map['priority'] ?? 'Medium',
      status: map['status'] ?? (map['isCompleted'] == true ? 'Completed' : 'Active'),
      taskType: map['taskType'] ?? map['task_type'] ?? 'Task',
      instructions: map['instructions'],
      attachmentUrl: map['attachmentUrl'] ?? map['attachment_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'description': description,
      'assignedBy': assignedBy,
      'assigned_by': assignedBy,
      'assignedDate': assignedDate,
      'assigned_date': assignedDate,
      'dueDate': dueDate,
      'due_date': dueDate,
      'year': year,
      'department': department,
      'section': section,
      'studentsAssigned': studentsAssigned,
      'students_assigned': studentsAssigned,
      'submissions': submissions,
      'pending': pending,
      'maxMarks': maxMarks,
      'max_marks': maxMarks,
      'priority': priority,
      'status': status,
      'isCompleted': isCompleted,
      'taskType': taskType,
      'task_type': taskType,
      'instructions': instructions,
      'attachmentUrl': attachmentUrl,
    };
  }

  static List<StaffTaskModel> get defaultTasks => const [];
}

class StudentTaskSubmission {
  final String taskId;
  final String studentId;
  final String studentName;
  final String registerNo;
  final String photoUrl;
  final String status; // 'Submitted', 'Pending', 'Late', 'Graded'
  final String? submittedAt;
  final int? marks;
  final int maxMarks;
  final String? feedback;
  final String? fileUrl;

  const StudentTaskSubmission({
    required this.taskId,
    required this.studentId,
    required this.studentName,
    required this.registerNo,
    required this.photoUrl,
    required this.status,
    this.submittedAt,
    this.marks,
    this.maxMarks = 20,
    this.feedback,
    this.fileUrl,
  });

  StudentTaskSubmission copyWith({
    String? status,
    String? submittedAt,
    int? marks,
    String? feedback,
  }) {
    return StudentTaskSubmission(
      taskId: taskId,
      studentId: studentId,
      studentName: studentName,
      registerNo: registerNo,
      photoUrl: photoUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      marks: marks ?? this.marks,
      maxMarks: maxMarks,
      feedback: feedback ?? this.feedback,
      fileUrl: fileUrl,
    );
  }

  static List<StudentTaskSubmission> get defaultSubmissions => const [];
}
