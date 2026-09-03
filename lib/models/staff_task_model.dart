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

  static List<StaffTaskModel> get defaultTasks => [
    const StaffTaskModel(
      id: "TASK-1024",
      title: "Machine Learning Mini Project",
      subject: "Machine Learning",
      description: "Build and evaluate a classification model using Python scikit-learn on the provided dataset.",
      assignedBy: "VSB10234",
      assignedDate: "20 Aug 2026",
      dueDate: "28 Aug 2026",
      year: "III Year",
      department: "CSE",
      section: "A",
      studentsAssigned: 42,
      submissions: 28,
      pending: 14,
      maxMarks: 20,
      priority: "High",
      status: "Active",
      taskType: "Mini Project",
      instructions: "Upload a zipped GitHub repo link along with a PDF report containing confusion matrix graphs.",
    ),
    const StaffTaskModel(
      id: "TASK-1025",
      title: "Python Programming Assignment",
      subject: "Python Programming",
      description: "Implement OOPs concepts, decorator functions, and exception handling algorithms in Python.",
      assignedBy: "VSB10234",
      assignedDate: "18 Aug 2026",
      dueDate: "25 Aug 2026",
      year: "III Year",
      department: "CSE",
      section: "B",
      studentsAssigned: 38,
      submissions: 25,
      pending: 13,
      maxMarks: 20,
      priority: "Medium",
      status: "Active",
      taskType: "Assignment",
      instructions: "Submit executable .py script files along with code outputs screenshot.",
    ),
    const StaffTaskModel(
      id: "TASK-1026",
      title: "Data Analytics Case Study",
      subject: "Data Analytics",
      description: "Perform exploratory data analysis (EDA) and visualization on retail customer churn data.",
      assignedBy: "VSB10234",
      assignedDate: "17 Aug 2026",
      dueDate: "30 Aug 2026",
      year: "III Year",
      department: "CSE",
      section: "A",
      studentsAssigned: 35,
      submissions: 10,
      pending: 25,
      maxMarks: 20,
      priority: "High",
      status: "Pending",
      taskType: "Case Study",
      instructions: "Submit Jupyter Notebook (.ipynb) with clean data visualizations and markdown commentary.",
    ),
  ];
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

  static List<StudentTaskSubmission> get defaultSubmissions => [
    const StudentTaskSubmission(
      taskId: "TASK-1024",
      studentId: "STD-2001",
      studentName: "Saran Kumar",
      registerNo: "20CS3012",
      photoUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200",
      status: "Submitted",
      submittedAt: "24 Aug 2026, 10:30 AM",
      marks: 18,
      maxMarks: 20,
      feedback: "Great implementation of Random Forest classifier with clean graphs.",
      fileUrl: "saran_ml_project.pdf",
    ),
    const StudentTaskSubmission(
      taskId: "TASK-1025",
      studentId: "STD-2002",
      studentName: "Nandhini R",
      registerNo: "20CS3025",
      photoUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200",
      status: "Submitted",
      submittedAt: "23 Aug 2026, 09:15 AM",
      marks: 16,
      maxMarks: 20,
      feedback: "Good work on decorators, but missing unit tests.",
      fileUrl: "nandhini_python_assignment.py",
    ),
    const StudentTaskSubmission(
      taskId: "TASK-1026",
      studentId: "STD-2003",
      studentName: "Vignesh S",
      registerNo: "20CS3058",
      photoUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200",
      status: "Pending",
      submittedAt: "-",
      marks: null,
      maxMarks: 20,
      feedback: null,
      fileUrl: null,
    ),
  ];
}
