import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/models/announcement_model.dart';
import 'package:unisphere/models/assignment_model.dart';
import 'package:unisphere/models/attendance_model.dart';
import 'package:unisphere/models/certification_model.dart';
import 'package:unisphere/models/department_model.dart';
import 'package:unisphere/models/exam_model.dart';
import 'package:unisphere/models/faculty_model.dart';
import 'package:unisphere/models/hackathon_banner_model.dart';
import 'package:unisphere/models/hackathon_model.dart';
import 'package:unisphere/models/hackathon_registration_model.dart';
import 'package:unisphere/models/mark_model.dart';
import 'package:unisphere/models/notification_model.dart';
import 'package:unisphere/models/notification_rule_model.dart';
import 'package:unisphere/models/gallery_photo_model.dart';
import 'package:unisphere/models/photo_album_model.dart';
import 'package:unisphere/models/project_model.dart';
import 'package:unisphere/models/student_model.dart';
import 'package:unisphere/models/submission_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/models/academic_schedule_model.dart';
import 'package:unisphere/models/syllabus_model.dart';


/// DatabaseSeeder populates Cloud Firestore with complete, real sample data across all 17 app collections for development, demo testing & production setup.
class DatabaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> seedAllData() async {
    try {
      debugPrint('🌱 Starting Complete UniSphere Firebase Database Seeding...');

      // 1. Seed Users (All 5 Roles: Student, HOD, Staff, Admin, Parent + Faculty Users)
      final users = [
        UserModel(
          uid: 'DEMO-STU',
          email: 'saravanapmvofficial@gmail.com',
          fullName: 'Alex Johnson',
          role: UserRole.student,
          metadata: {
            'registerNumber': 'RA2111003010001',
            'department': 'Computer Science & Engineering',
            'year': '3rd Year',
            'semester': 'Semester VI',
            'section': 'Sec B',
            'verificationStatus': 'verified',
            'hasMembership': true,
            'membershipOrg': 'ISTE',
            'membershipId': 'ISTE-2024-9842',
            'fatherPhotoUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
            'motherPhotoUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
          },
        ),
        UserModel(
          uid: 'DEMO-HOD',
          email: 'hod.cse@unisphere.edu',
          fullName: 'Dr. R. Kumar',
          role: UserRole.hod,
          metadata: {
            'department': 'Computer Science & Engineering',
            'designation': 'Head of Department & Professor',
          },
        ),
        UserModel(
          uid: 'DEMO-STF',
          email: 'staff@unisphere.edu',
          fullName: 'Prof. Sarah Jenkins',
          role: UserRole.staff,
          metadata: {
            'department': 'Computer Science & Engineering',
            'designation': 'Assistant Professor',
          },
        ),
        UserModel(
          uid: 'DEMO-ADM',
          email: 'admin@unisphere.edu',
          fullName: 'Campus Administrator',
          role: UserRole.admin,
          metadata: {'role': 'Super Admin'},
        ),
        UserModel(
          uid: 'DEMO-PRT',
          email: 'parent@unisphere.edu',
          fullName: 'Rajesh Johnson',
          role: UserRole.parent,
          metadata: {
            'wardUid': 'DEMO-STU',
            'wardName': 'Alex Johnson',
            'wardRegisterNumbers': ['RA2111003010001', '917721104012'],
            'relationship': 'Father',
          },
        ),
        UserModel(
          uid: 'FAC-101',
          email: 'robert.vance@unisphere.edu',
          fullName: 'Dr. Robert Vance',
          role: UserRole.staff,
          metadata: {
            'department': 'Computer Science & Engineering',
            'designation': 'Associate Professor',
          },
        ),
        UserModel(
          uid: 'FAC-102',
          email: 'grace.hopper@unisphere.edu',
          fullName: 'Dr. Grace Hopper',
          role: UserRole.staff,
          metadata: {
            'department': 'Computer Science & Engineering',
            'designation': 'Professor & AI Lead',
          },
        ),
      ];


      for (var u in users) {
        await _firestore.collection('users').doc(u.uid).set(u.toMap(), SetOptions(merge: true));
        final regNo = u.metadata?['registerNumber']?.toString();
        if (regNo != null && regNo.isNotEmpty) {
          await _firestore.collection('users').doc(regNo).set(u.toMap(), SetOptions(merge: true));
        }
      }

      // 2. Seed Student Profiles (Stored under unique Register Number & Student UID)
      final students = [
        StudentModel(
          studentId: 'DEMO-STU',
          userId: 'DEMO-STU',
          registerNumber: 'RA2111003010001',
          fullName: 'Alex Johnson',
          rollNumber: '917722104022',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2022-26',
          batch: '2022–2026',
          semester: 'Semester VI',
          section: 'Sec B',
          admissionYear: 2022,
          cgpa: '8.92',
          attendancePercent: '88.5',
          hasMembership: true,
          membershipOrg: 'ISTE',
          membershipId: 'ISTE-2024-9842',
        ),
        StudentModel(
          studentId: 'STU-102',
          userId: 'STU-USER-102',
          registerNumber: 'RA2111003010002',
          fullName: 'Sarah Connor',
          rollNumber: '917722104023',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2022-26',
          batch: '2022–2026',
          semester: 'Semester VI',
          section: 'Sec B',
          admissionYear: 2022,
          cgpa: '9.15',
          attendancePercent: '92.0',
          hasMembership: true,
          membershipOrg: 'CSI',
          membershipId: 'CSI-2024-5519',
        ),
        StudentModel(
          studentId: '917721104012',
          userId: '917721104012',
          registerNumber: '917721104012',
          fullName: 'Aravind Swamy',
          rollNumber: '917721104012',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2022-26',
          batch: '2022–2026',
          semester: 'Semester VI',
          section: 'Sec A',
          admissionYear: 2022,
          cgpa: '9.12',
          attendancePercent: '96.5',
          hasMembership: true,
          membershipOrg: 'ISTE',
          membershipId: 'ISTE-2024-1102',
        ),
        StudentModel(
          studentId: '917721104045',
          userId: '917721104045',
          registerNumber: '917721104045',
          fullName: 'Priya Dharshini',
          rollNumber: '917721104045',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2022-26',
          batch: '2022–2026',
          semester: 'Semester VI',
          section: 'Sec A',
          admissionYear: 2022,
          cgpa: '8.85',
          attendancePercent: '92.0',
          hasMembership: true,
          membershipOrg: 'ACM',
          membershipId: 'ACM-2024-9041',
        ),
        StudentModel(
          studentId: '917722104022',
          userId: '917722104022',
          registerNumber: '917722104022',
          fullName: 'Karthik Raja',
          rollNumber: '917722104022',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2023-27',
          batch: '2023–2027',
          semester: 'Semester IV',
          section: 'Sec B',
          admissionYear: 2023,
          cgpa: '7.45',
          attendancePercent: '71.5',
          hasMembership: false,
        ),
        StudentModel(
          studentId: '917723104089',
          userId: '917723104089',
          registerNumber: '917723104089',
          fullName: 'Sneha Murali',
          rollNumber: '917723104089',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2024-28',
          batch: '2024–2028',
          semester: 'Semester II',
          section: 'Sec C',
          admissionYear: 2024,
          cgpa: '9.50',
          attendancePercent: '98.0',
          hasMembership: true,
          membershipOrg: 'IEEE',
          membershipId: 'IEEE-2025-4109',
        ),
        StudentModel(
          studentId: '922523243098',
          userId: '922523243098',
          registerNumber: '922523243098',
          fullName: 'Sam',
          rollNumber: '922523243098',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2023-27',
          batch: '2023–2027',
          semester: 'Semester VI',
          section: 'Sec B',
          admissionYear: 2023,
          cgpa: '8.60',
          attendancePercent: '89.0',
          hasMembership: true,
          membershipOrg: 'ACM',
          membershipId: 'ACM-2025-9921',
        ),
        StudentModel(
          studentId: '922523243100',
          userId: '922523243100',
          registerNumber: '922523243100',
          fullName: 'saravana',
          rollNumber: '922523243100',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2023-27',
          batch: '2023–2027',
          semester: 'Semester VI',
          section: 'Sec A',
          admissionYear: 2023,
          cgpa: '8.90',
          attendancePercent: '92.0',
          hasMembership: true,
          membershipOrg: 'CSI',
          membershipId: 'CSI-2025-4412',
        ),
        StudentModel(
          studentId: '922523243078',
          userId: '922523243078',
          registerNumber: '922523243078',
          fullName: 'saravana',
          rollNumber: '922523243078',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          batchId: 'BATCH-2023-27',
          batch: '2023–2027',
          semester: 'Semester VI',
          section: 'Sec A',
          admissionYear: 2023,
          cgpa: '8.80',
          attendancePercent: '91.0',
          hasMembership: true,
          membershipOrg: 'IEEE',
          membershipId: 'IEEE-2025-2281',
        ),
      ];

      for (var st in students) {
        // Save under student ID and under unique Register Number doc ID
        await _firestore.collection('students').doc(st.studentId).set(st.toMap(), SetOptions(merge: true));
        await _firestore.collection('students').doc(st.registerNumber).set(st.toMap(), SetOptions(merge: true));

        // Also seed complete 360° profile under unique Register Number doc ID in student_profiles
        final profileDoc = {
          'studentUid': st.userId,
          'registerNumber': st.registerNumber,
          'completionStatus': 'completed',
          'completionPercentage': 100,
          'personal': {
            'fullName': 'Alex Johnson',
            'registerNumber': st.registerNumber,
            'department': st.departmentName,
            'collegeEmail': 'saravanapmvofficial@gmail.com',
            'gender': 'Male',
            'bloodGroup': 'O+',
            'dob': '15/05/2005',
            'religion': 'Hindu',
            'community': 'BC',
            'motherTongue': 'Tamil',
          },
          'contact': {
            'primaryMobile': '+91 98765 43210',
            'personalEmail': 'student.test@gmail.com',
            'permanentAddress': {
              'addressLine1': '123, Anna Nagar 2nd Street',
              'city': 'Karur',
              'state': 'Tamil Nadu',
              'pincode': '639002',
              'country': 'India',
            },
            'currentAddress': {
              'addressLine1': '123, Anna Nagar 2nd Street',
              'city': 'Karur',
              'state': 'Tamil Nadu',
              'pincode': '639002',
              'country': 'India',
            },
          },
          'education': {
            'tenth': {
              'institutionName': 'Government Higher Sec School',
              'institutionAddress': 'Main Road, Karur, Tamil Nadu',
              'boardOrUniversity': 'State Board',
              'medium': 'Tamil',
              'marksObtained': 465,
              'totalMarks': 500,
              'percentage': 93.0,
              'passingYear': '2021',
            },
            'twelfthOrDiploma': {
              'institutionName': 'VSB Higher Sec School',
              'institutionAddress': 'Covai Road, Karur, Tamil Nadu',
              'boardOrUniversity': 'State Board',
              'medium': 'English',
              'marksObtained': 552,
              'totalMarks': 600,
              'percentage': 92.0,
              'passingYear': '2023',
            },
            'hasDiploma': true,
            'diploma': {
              'institutionName': 'VSB Polytechnic College',
              'institutionAddress': 'Covai Road, Karur, Tamil Nadu',
              'boardOrUniversity': 'DOTE / Polytechnic Board',
              'medium': 'English',
              'registerNumber': 'Diploma in Computer Engineering',
              'marksObtained': 88.5,
              'totalMarks': 100,
              'percentage': 88.5,
              'passingYear': '2025',
            },
          },
          'living': {
            'livingType': 'pgHostel',
            'details': {
              'pgName': 'Sri Sai Men\'s PG',
              'pgAddress': 'Covai Road, Near VSB Campus, Karur',
              'rentedAddress': '12/A, Gandhigramam 3rd Street, Karur',
              'roommates': 'Classmates (Karthik & Ramesh)',
            },
          },
          'documents': [
            {'id': 'doc_photo', 'name': 'Student Passport Photo', 'isRequired': true, 'fileName': 'passport_photo.jpg (0.8 MB)', 'fileUrl': 'https://unisphere.edu/docs/photo.jpg', 'status': 'uploaded'},
            {'id': 'doc_10th', 'name': '10th Standard Marksheet', 'isRequired': true, 'fileName': '10th_marksheet.pdf (1.4 MB)', 'fileUrl': 'https://unisphere.edu/docs/10th.pdf', 'status': 'uploaded'},
            {'id': 'doc_12th', 'name': '12th / Diploma Marksheet', 'isRequired': true, 'fileName': '12th_marksheet.pdf (1.6 MB)', 'fileUrl': 'https://unisphere.edu/docs/12th.pdf', 'status': 'uploaded'},
            {'id': 'doc_tc', 'name': 'Transfer Certificate (TC)', 'isRequired': true, 'fileName': 'transfer_certificate.pdf (0.9 MB)', 'fileUrl': 'https://unisphere.edu/docs/tc.pdf', 'status': 'uploaded'},
            {'id': 'doc_community', 'name': 'Community Certificate', 'isRequired': false, 'fileName': '', 'fileUrl': '', 'status': 'pending'},
          ],
          'hasMembership': st.hasMembership,
          'membershipOrg': st.membershipOrg,
          'membershipId': st.membershipId,
          'membership': {
            'hasMembership': st.hasMembership,
            'membershipOrg': st.membershipOrg,
            'membershipId': st.membershipId,
          },
        };
        await _firestore.collection('student_profiles').doc(st.registerNumber).set(profileDoc, SetOptions(merge: true));
        await _firestore.collection('student_profiles').doc(st.userId).set(profileDoc, SetOptions(merge: true));
      }

      // 3. Seed Faculty Members
      final facultyList = [
        FacultyModel(
          facultyId: 'FAC-101',
          userId: 'FAC-101',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          designation: 'Associate Professor',
          assignedSubjects: ['CS301 - Computer Networks', 'CS306 - Cloud Computing'],
        ),
        FacultyModel(
          facultyId: 'FAC-102',
          userId: 'FAC-102',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          designation: 'Professor',
          assignedSubjects: ['CS304 - AI & Machine Learning'],
        ),
        FacultyModel(
          facultyId: 'FAC-103',
          userId: 'DEMO-STF',
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          designation: 'Assistant Professor',
          assignedSubjects: ['CS302 - Database Systems', 'CS305 - Web Technology'],
        ),
      ];

      for (var f in facultyList) {
        await _firestore.collection('faculty').doc(f.facultyId).set(f.toMap(), SetOptions(merge: true));
      }

      // 4. Seed Departments
      final departments = [
        DepartmentModel(
          departmentId: 'DEP-CSE',
          name: 'Computer Science & Engineering',
          code: 'CSE',
          hodId: 'DEMO-HOD',
          hodName: 'Dr. R. Kumar',
          totalStudents: 480,
          totalFaculty: 32,
        ),
        DepartmentModel(
          departmentId: 'DEP-ECE',
          name: 'Electronics & Communication Engineering',
          code: 'ECE',
          hodId: 'HOD-ECE-01',
          hodName: 'Dr. V. Swaminathan',
          totalStudents: 390,
          totalFaculty: 26,
        ),
        DepartmentModel(
          departmentId: 'DEP-IT',
          name: 'Information Technology',
          code: 'IT',
          hodId: 'HOD-IT-01',
          hodName: 'Dr. Anita Desai',
          totalStudents: 340,
          totalFaculty: 22,
        ),
        DepartmentModel(
          departmentId: 'DEP-MECH',
          name: 'Mechanical Engineering',
          code: 'MECH',
          hodId: 'HOD-MECH-01',
          hodName: 'Dr. K. Ramanathan',
          totalStudents: 300,
          totalFaculty: 20,
        ),

      ];

      for (var dep in departments) {
        await _firestore.collection('departments').doc(dep.departmentId).set(dep.toMap(), SetOptions(merge: true));
      }

      // 5. Seed Attendance Records
      final attendanceRecords = [
        AttendanceRecord(
          id: 'att-1',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          subjectCode: 'CS301',
          subjectName: 'Computer Networks',
          date: DateTime.now().subtract(const Duration(hours: 4)),
          timeSlot: '09:00 - 10:00 AM',
          status: AttendanceStatus.present,
          facultyName: 'Dr. Robert Vance',
        ),
        AttendanceRecord(
          id: 'att-2',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          subjectCode: 'CS302',
          subjectName: 'Database Systems',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          timeSlot: '10:15 - 11:15 AM',
          status: AttendanceStatus.present,
          facultyName: 'Prof. Sarah Jenkins',
        ),
        AttendanceRecord(
          id: 'att-3',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          subjectCode: 'CS303',
          subjectName: 'Software Engineering',
          date: DateTime.now().subtract(const Duration(days: 1)),
          timeSlot: '01:30 - 02:30 PM',
          status: AttendanceStatus.present,
          facultyName: 'Prof. Michael Scott',
        ),
        AttendanceRecord(
          id: 'att-4',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          subjectCode: 'CS304',
          subjectName: 'AI & Machine Learning',
          date: DateTime.now().subtract(const Duration(days: 2)),
          timeSlot: '02:45 - 03:45 PM',
          status: AttendanceStatus.onDuty,
          facultyName: 'Dr. Grace Hopper',
        ),
        AttendanceRecord(
          id: 'att-5',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          subjectCode: 'CS305',
          subjectName: 'Web Technology',
          date: DateTime.now().subtract(const Duration(days: 3)),
          timeSlot: '11:30 - 12:30 PM',
          status: AttendanceStatus.present,
          facultyName: 'Prof. Sarah Jenkins',
        ),
      ];
      for (var att in attendanceRecords) {
        await _firestore.collection('attendance').doc(att.id).set(att.toMap(), SetOptions(merge: true));
      }

      // 6. Seed Certifications (NPTEL & Industry)
      final certs = [
        CertificationModel(
          id: 'cert-1',
          studentId: 'DEMO-STU',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          title: 'NPTEL Cloud Computing & Distributed Systems',
          provider: 'IIT Kharagpur / NPTEL',
          type: CertificationType.nptel,
          certificateId: 'NPTEL26CS45S1299834',
          issueDate: DateTime(2026, 4, 15),
          verificationStatus: 'verified',
          approvalStatus: 'approved',
          createdAt: DateTime.now(),
        ),
        CertificationModel(
          id: 'cert-2',
          studentId: 'DEMO-STU',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          title: 'AWS Certified Solutions Architect – Associate',
          provider: 'Amazon Web Services',
          type: CertificationType.industry,
          certificateId: 'AWS-ASA-99823412',
          issueDate: DateTime(2026, 5, 20),
          verificationStatus: 'verified',
          approvalStatus: 'approved',
          createdAt: DateTime.now(),
        ),
        CertificationModel(
          id: 'cert-3',
          studentId: 'DEMO-STU',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          title: 'Google Cloud Professional Data Engineer',
          provider: 'Google Cloud',
          type: CertificationType.industry,
          certificateId: 'GCP-PDE-8823194',
          issueDate: DateTime(2026, 7, 10),
          verificationStatus: 'verified',
          approvalStatus: 'approved',
          createdAt: DateTime.now(),
        ),
        CertificationModel(
          id: 'cert-aravind-1',
          studentId: '917721104012',
          studentUid: '917721104012',
          studentName: 'Aravind Swamy',
          title: 'NPTEL Programming, Data Structures and Algorithms Using Python',
          provider: 'IIT Madras / NPTEL (Elite + Silver)',
          type: CertificationType.nptel,
          certificateId: 'NPTEL26CS22S904128',
          issueDate: DateTime(2026, 3, 10),
          verificationStatus: 'verified',
          approvalStatus: 'approved',
          createdAt: DateTime.now(),
        ),
        CertificationModel(
          id: 'cert-aravind-2',
          studentId: '917721104012',
          studentUid: '917721104012',
          studentName: 'Aravind Swamy',
          title: 'Certified Kubernetes Administrator (CKA)',
          provider: 'Linux Foundation / CNCF',
          type: CertificationType.industry,
          certificateId: 'CKA-2600-88124',
          issueDate: DateTime(2026, 5, 14),
          verificationStatus: 'verified',
          approvalStatus: 'approved',
          createdAt: DateTime.now(),
        ),
        CertificationModel(
          id: 'cert-priya-1',
          studentId: '917721104045',
          studentUid: '917721104045',
          studentName: 'Priya Dharshini',
          title: 'TensorFlow Developer Certificate',
          provider: 'Google',
          type: CertificationType.industry,
          certificateId: 'TF-DEV-901248',
          issueDate: DateTime(2026, 4, 18),
          verificationStatus: 'verified',
          approvalStatus: 'approved',
          createdAt: DateTime.now(),
        ),
        CertificationModel(
          id: 'cert-karthik-1',
          studentId: '917722104022',
          studentUid: '917722104022',
          studentName: 'Karthik Raja',
          title: 'Oracle Certified Professional: Java SE 17 Developer',
          provider: 'Oracle Corporation',
          type: CertificationType.industry,
          certificateId: 'OCP-JAVA-77219',
          issueDate: DateTime(2026, 2, 28),
          verificationStatus: 'verified',
          approvalStatus: 'approved',
          createdAt: DateTime.now(),
        ),
        CertificationModel(
          id: 'cert-sneha-1',
          studentId: '917723104089',
          studentUid: '917723104089',
          studentName: 'Sneha Murali',
          title: 'NPTEL Introduction to Internet of Things',
          provider: 'IIT Kharagpur / NPTEL (Elite)',
          type: CertificationType.nptel,
          certificateId: 'NPTEL26CS08S551920',
          issueDate: DateTime(2026, 4, 12),
          verificationStatus: 'verified',
          approvalStatus: 'approved',
          createdAt: DateTime.now(),
        ),
      ];
      for (var c in certs) {
        await _firestore.collection('certifications').doc(c.id).set(c.toMap(), SetOptions(merge: true));
      }

      // 7. Seed Hackathons
      final hackathons = [
        HackathonModel(
          id: 'hack-1',
          title: 'Smart Campus AI Hackathon 2026',
          description: 'Build innovative mobile & cloud solutions for smart university governance.',
          category: 'AI & Mobile',
          organizer: 'UniSphere Developer Student Club',
          mode: 'Hybrid',
          bannerImage: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4',
          startDate: DateTime.now().add(const Duration(days: 10)),
          endDate: DateTime.now().add(const Duration(days: 12)),
          registrationOpen: true,
          registrationDeadline: DateTime.now().add(const Duration(days: 7)),
          prizePool: '₹1,00,000',
          registeredTeams: 28,
          maxTeams: 50,
          teamSize: 4,
          status: 'upcoming',
          userRegistrationStatus: 'registered',
          location: 'Tech Park Auditorium & Discord',
          tags: ['Flutter', 'Firebase', 'AI', 'Cloud'],
        ),
        HackathonModel(
          id: 'hack-2',
          title: 'National Web3 & Cloud Summit 2026',
          description: 'Develop decentralized academic credentials and zero-knowledge verification pipelines.',
          category: 'Web3 & Cloud',
          organizer: 'IEEE Computer Society',
          mode: 'Online',
          bannerImage: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5',
          startDate: DateTime.now().add(const Duration(days: 20)),
          endDate: DateTime.now().add(const Duration(days: 22)),
          registrationOpen: true,
          registrationDeadline: DateTime.now().add(const Duration(days: 15)),
          prizePool: '₹2,50,000',
          registeredTeams: 45,
          maxTeams: 100,
          teamSize: 4,
          status: 'upcoming',
          userRegistrationStatus: 'none',
          location: 'Online / Zoom & GitHub',
          tags: ['Solidity', 'Blockchain', 'Cloud', 'React'],
        ),
      ];
      for (var h in hackathons) {
        await _firestore.collection('hackathons').doc(h.id).set(h.toMap(), SetOptions(merge: true));
      }

      // 8. Seed Hackathon Banners
      final banners = [
        HackathonBannerModel(
          id: 1,
          title: 'Smart India Hackathon 2026',
          posterImage: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1200&q=80',
          registrationLink: 'https://sih.gov.in',
          uploadDate: DateTime.now().subtract(const Duration(days: 5)),
          expiryDate: DateTime.now().add(const Duration(days: 25)),
          isActive: true,
        ),
        HackathonBannerModel(
          id: 2,
          title: 'UniSphere AI Challenge 2026',
          posterImage: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=1200&q=80',
          registrationLink: 'https://unisphere.edu/hackathon',
          uploadDate: DateTime.now().subtract(const Duration(days: 2)),
          expiryDate: DateTime.now().add(const Duration(days: 15)),
          isActive: true,
        ),
      ];

      for (var b in banners) {
        await _firestore.collection('hackathon_banners').doc(b.id.toString()).set(b.toMap(), SetOptions(merge: true));
      }

      // 9. Seed Hackathon Registrations
      final reg = HackathonRegistrationModel(
        id: 'reg-1',
        hackathonId: 'hack-1',
        hackathonTitle: 'Smart Campus AI Hackathon 2026',
        studentId: 'STU-101',
        studentName: 'Alex Johnson',
        department: 'Computer Science & Engineering',
        year: '3rd Year',
        email: 'saravanapmvofficial@gmail.com',
        phone: '+91 98765 43210',
        teamName: 'Team CyberKnights',
        teamMembers: ['Alex Johnson (Leader)', 'Priya Sharma', 'Rahul Verma', 'Ananya Roy'],
        registrationDate: DateTime.now().subtract(const Duration(days: 3)),
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 12)),
        participationStatus: 'Registration Confirmed',
        mode: 'Hybrid',
        location: 'Tech Park Auditorium & Discord',
        organizer: 'UniSphere Developer Student Club',
        description: 'Build innovative mobile & cloud solutions for smart university governance.',
        bannerImage: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4',
      );

      await _firestore.collection('hackathon_registrations').doc(reg.id).set(reg.toMap(), SetOptions(merge: true));
      await _firestore.collection('hackathonRegistrations').doc(reg.id).set(reg.toMap(), SetOptions(merge: true));
      await _firestore
          .collection('hackathons')
          .doc('hack-1')
          .collection('teams')
          .doc('team-1')
          .set({
            'teamId': 'team-1',
            'hackathonId': 'hack-1',
            'teamName': 'Team CyberKnights',
            'leaderId': 'DEMO-STU',
            'memberIds': ['DEMO-STU', 'STU-102'],
            'memberCount': 2,
            'registrationStatus': 'registered',
            'registrationCompleted': true,
            'hodReviewStatus': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));


      // 10. Seed Marks
      final marks = [
        MarkModel(
          id: 'mk-1',
          studentUid: 'DEMO-STU',
          subjectName: 'Computer Networks',
          obtainedMarks: 92,
          totalMarks: 100,
          examType: 'Internal Assessment I',
          updatedAt: DateTime.now(),
        ),
        MarkModel(
          id: 'mk-2',
          studentUid: 'DEMO-STU',
          subjectName: 'Database Systems',
          obtainedMarks: 88,
          totalMarks: 100,
          examType: 'Internal Assessment I',
          updatedAt: DateTime.now(),
        ),
        MarkModel(
          id: 'mk-3',
          studentUid: 'DEMO-STU',
          subjectName: 'Software Engineering',
          obtainedMarks: 95,
          totalMarks: 100,
          examType: 'Internal Assessment I',
          updatedAt: DateTime.now(),
        ),
        MarkModel(
          id: 'mk-4',
          studentUid: 'DEMO-STU',
          subjectName: 'AI & Machine Learning',
          obtainedMarks: 90,
          totalMarks: 100,
          examType: 'Internal Assessment I',
          updatedAt: DateTime.now(),
        ),
        MarkModel(
          id: 'mk-5',
          studentUid: 'DEMO-STU',
          subjectName: 'Web Technology',
          obtainedMarks: 94,
          totalMarks: 100,
          examType: 'Internal Assessment I',
          updatedAt: DateTime.now(),
        ),
      ];

      for (var m in marks) {
        await _firestore.collection('marks').doc(m.id).set(m.toMap(), SetOptions(merge: true));
      }

      // 11. Seed Exams
      final exams = [
        ExamModel(
          id: 'exam-1',
          subjectName: 'Computer Networks',
          courseCode: 'CS301',
          examType: 'Internal Assessment II',
          date: DateTime.now().add(const Duration(days: 5)),
          startTime: '09:30 AM',
          endTime: '11:00 AM',
          durationMinutes: 90,
          venue: 'Main Academic Block',
          roomNumber: 'Hall 301',
          blockBuilding: 'Main Academic Building - Floor 3',
          facultyInvigilator: 'Dr. Robert Vance',
          instructions: 'Bring your official College ID card and Hall Ticket. Scientific calculators permitted.',
          requirements: const [
            ExamRequirementItem(label: 'College ID Card', status: ExamRequirementStatus.required),
            ExamRequirementItem(label: 'Hall Ticket', status: ExamRequirementStatus.required),
            ExamRequirementItem(label: 'Scientific Calculator', status: ExamRequirementStatus.allowed),
          ],
        ),
        ExamModel(
          id: 'exam-2',
          subjectName: 'Database Systems',
          courseCode: 'CS302',
          examType: 'Internal Assessment II',
          date: DateTime.now().add(const Duration(days: 7)),
          startTime: '01:30 PM',
          endTime: '03:00 PM',
          durationMinutes: 90,
          venue: 'Main Academic Block',
          roomNumber: 'Hall 302',
          blockBuilding: 'Main Academic Building - Floor 3',
          facultyInvigilator: 'Prof. Sarah Jenkins',
          instructions: 'Arrive 15 minutes before the exam start time.',
          requirements: const [
            ExamRequirementItem(label: 'College ID Card', status: ExamRequirementStatus.required),
            ExamRequirementItem(label: 'Hall Ticket', status: ExamRequirementStatus.required),
          ],
        ),
        ExamModel(
          id: 'exam-3',
          subjectName: 'AI & Machine Learning',
          courseCode: 'CS304',
          examType: 'End Semester Practical Exam',
          date: DateTime.now().add(const Duration(days: 14)),
          startTime: '09:00 AM',
          endTime: '12:00 PM',
          durationMinutes: 180,
          venue: 'Tech Park Block A',
          roomNumber: 'Lab 204',
          blockBuilding: 'Tech Park Innovation Block',
          facultyInvigilator: 'Dr. Grace Hopper',
          instructions: 'Submit signed lab record before starting the practical code implementation.',
          requirements: const [
            ExamRequirementItem(label: 'Signed Lab Record', status: ExamRequirementStatus.required),
            ExamRequirementItem(label: 'College ID Card', status: ExamRequirementStatus.required),
          ],
        ),
      ];

      for (var ex in exams) {
        await _firestore.collection('exams').doc(ex.id).set(ex.toMap(), SetOptions(merge: true));
      }

      // 12. Seed Announcements
      final announcements = [
        AnnouncementModel(
          id: 'ann-1',
          title: '🎉 End-Semester Examination Schedule & Regulations Released',
          content: 'The official end-semester examination timetable for Semester VI (2025-26) has been published. All students must download their verified Hall Tickets from the student portal before the commencement date.',
          authorName: 'Controller of Examinations',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          category: 'Examination',
          priority: 'Urgent',
          isNew: true,
        ),
        AnnouncementModel(
          id: 'ann-2',
          title: '🚀 Campus Placement Drive: Google & Microsoft',
          content: 'Career Development Centre (CDC) announces upcoming campus placement recruitment drives for 3rd and 4th year CSE/IT students. Register your updated resume by Friday.',
          authorName: 'Placement Cell Lead',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          category: 'Placement',
          priority: 'Important',
          isNew: false,
        ),
        AnnouncementModel(
          id: 'ann-3',
          title: '🏆 Smart Campus AI Hackathon 2026 Registrations Open',
          content: 'UniSphere DSC is organizing a 36-hour hybrid hackathon with cash prizes worth ₹1,00,000. Form teams of 2 to 4 members and submit your project proposal.',
          authorName: 'DSC Student President',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          category: 'Event',
          priority: 'Normal',
          isNew: false,
        ),
      ];

      for (var ann in announcements) {
        await _firestore.collection('announcements').doc(ann.id).set(ann.toMap(), SetOptions(merge: true));
      }

      // 13. Seed Assignments
      final assignments = [
        AssignmentModel(
          id: 'asg-1',
          title: 'Socket Programming & TCP Stream Pipeline',
          description: 'Implement a multi-threaded TCP Client-Server socket application handling asynchronous message streaming, packet serialization, and connection keep-alive.',
          authorName: 'Dr. Robert Vance',
          subjectName: 'Computer Networks',
          courseCode: 'CS301',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          dueDate: DateTime.now().add(const Duration(days: 4)),
          maxMarks: 100,
          targetedClasses: ['CSE - 3rd Year - Sec B'],
          taskType: 'Lab Record',
          priority: 'High',
          status: 'Pending',
          submissionInstructions: 'Upload a clean PDF containing code listings, execution screenshots, and Wireshark trace analysis.',
        ),
        AssignmentModel(
          id: 'asg-2',
          title: 'SQL Query Optimization & B-Tree Indexing Benchmark',
          description: 'Design complex multi-table SQL queries, execute query explain plans, and optimize indexing strategies on a 100,000 row dataset.',
          authorName: 'Prof. Sarah Jenkins',
          subjectName: 'Database Systems',
          courseCode: 'CS302',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          dueDate: DateTime.now().add(const Duration(days: 6)),
          maxMarks: 100,
          targetedClasses: ['CSE - 3rd Year - Sec B'],
          taskType: 'Assignment',
          priority: 'Normal',
          status: 'Pending',
          submissionInstructions: 'Submit a PDF report with SQL queries, execution time comparisons, and index trees.',
        ),
        AssignmentModel(
          id: 'asg-3',
          title: 'Machine Learning Model Pipeline & Hyperparameter Tuning',
          description: 'Build and train a Convolutional Neural Network (CNN) for image classification. Evaluate accuracy, precision, and recall metrics.',
          authorName: 'Dr. Grace Hopper',
          subjectName: 'AI & Machine Learning',
          courseCode: 'CS304',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          dueDate: DateTime.now().add(const Duration(days: 9)),
          maxMarks: 50,
          targetedClasses: ['CSE - 3rd Year - Sec B'],
          taskType: 'Project Review',
          priority: 'High',
          status: 'Upcoming',
        ),
      ];

      for (var asg in assignments) {
        await _firestore.collection('assignments').doc(asg.id).set(asg.toMap(), SetOptions(merge: true));
      }

      // 14. Seed Submissions
      final submissions = [
        SubmissionModel(
          id: 'sub-1',
          assignmentId: 'asg-1',
          studentUid: 'DEMO-STU',
          studentName: 'Alex Johnson',
          registerNumber: 'RA2111003010001',
          fileName: 'tcp_socket_programming_alex.pdf',
          fileUrl: 'https://storage.unisphere.edu/submissions/tcp_socket_programming_alex.pdf',
          fileType: 'PDF',
          fileSizeBytes: 2450100,
          submittedAt: DateTime.now().subtract(const Duration(hours: 12)),
          status: 'Graded',
          isGraded: true,
          obtainedMarks: 95,
          feedback: 'Excellent implementation of multi-threaded socket server and packet inspection.',
          gradedBy: 'Dr. Robert Vance',
          gradedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      for (var sub in submissions) {
        await _firestore.collection('submissions').doc(sub.id).set(sub.toMap(), SetOptions(merge: true));
      }

      // 15. Seed Notifications & Notification Automation Rules
      final notifications = [
        NotificationModel(
          id: 'notif-1',
          title: '🚨 CRITICAL: Low Attendance Alert',
          message: 'Your overall attendance has fallen to 74.5%, which is below the required 75% minimum threshold.',
          type: 'automated',
          category: 'Attendance',
          priority: 'critical',
          senderId: 'system_rule_attendance',
          senderName: 'System Automation Engine',
          recipientType: 'user',
          recipientUserIds: ['DEMO-STU'],
          targetRoles: ['student'],
          relatedModule: 'attendance',
          createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
          isRead: false,
        ),
        NotificationModel(
          id: 'notif-2',
          title: '📅 End-Semester Examination Schedule Released',
          message: 'The final timetable for Semester VI examinations is now available on your portal.',
          type: 'manual',
          category: 'Academic',
          priority: 'high',
          senderId: 'DEMO-HOD',
          senderName: 'Dr. R. Kumar',
          senderRole: 'HOD',
          recipientType: 'department',
          targetDepartment: 'Computer Science',
          recipientUserIds: ['DEMO-STU', 'DEMO-STF'],
          targetRoles: ['student', 'staff'],
          relatedModule: 'exam',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
        NotificationModel(
          id: 'notif-3',
          title: '📝 Grade Updated: Computer Networks Socket Programming',
          message: 'Dr. Robert Vance graded your assignment with 95/100.',
          type: 'automated',
          category: 'Academic',
          priority: 'medium',
          senderId: 'system_rule_assignments',
          senderName: 'System Automation Engine',
          recipientType: 'user',
          recipientUserIds: ['DEMO-STU'],
          targetRoles: ['student'],
          relatedModule: 'assignment',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
        NotificationModel(
          id: 'notif-prt-1',
          title: '⚠️ Parent Notice: Student Low Attendance Alert',
          message: 'Your ward Alex Johnson has fallen below the 75% minimum attendance requirement (74.5%). Please ensure regular class attendance.',
          type: 'automated',
          category: 'Attendance',
          priority: 'critical',
          senderId: 'system_rule_attendance',
          senderName: 'System Automation Engine',
          recipientType: 'user',
          recipientUserIds: ['DEMO-PRT', 'PRT-917721104012'],
          targetRoles: ['parent'],
          relatedModule: 'attendance',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          isRead: false,
        ),
        NotificationModel(
          id: 'notif-prt-2',
          title: '💳 Fee Payment Reminder: Semester VI Tuition Fee',
          message: 'Semester VI Tuition Fee (₹45,000) for Alex Johnson is due on 25th August. Please process payment online.',
          type: 'automated',
          category: 'Finance',
          priority: 'high',
          senderId: 'system_rule_fees',
          senderName: 'Finance Department',
          recipientType: 'user',
          recipientUserIds: ['DEMO-PRT', 'PRT-917721104012'],
          targetRoles: ['parent'],
          relatedModule: 'fee',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: false,
        ),
        NotificationModel(
          id: 'notif-prt-3',
          title: '📅 End-Semester Examination & PTM Schedule',
          message: 'End-semester theory examinations begin on September 15th. Parent-Teacher Meeting is scheduled for September 5th.',
          type: 'manual',
          category: 'Academic',
          priority: 'medium',
          senderId: 'DEMO-HOD',
          senderName: 'Academic Affairs Office',
          senderRole: 'HOD',
          recipientType: 'role',
          recipientUserIds: ['DEMO-PRT', 'PRT-917721104012'],
          targetRoles: ['parent', 'student'],
          relatedModule: 'exam',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
      ];

      for (var n in notifications) {
        await _firestore.collection('notifications').doc(n.id).set(n.toMap(), SetOptions(merge: true));
      }

      final defaultRules = [
        NotificationRuleModel(
          ruleId: 'rule_attendance_warning',
          ruleName: 'Attendance Warning Threshold',
          category: 'Attendance',
          warningThreshold: 80.0,
          criticalThreshold: 75.0,
          consecutiveAbsenceLimit: 2,
          priority: 'high',
          targetRoles: ['student', 'parent'],
        ),
        NotificationRuleModel(
          ruleId: 'rule_attendance_critical',
          ruleName: 'Attendance Critical Alert',
          category: 'Attendance',
          warningThreshold: 80.0,
          criticalThreshold: 75.0,
          consecutiveAbsenceLimit: 2,
          priority: 'critical',
          targetRoles: ['student', 'parent', 'hod'],
        ),
        NotificationRuleModel(
          ruleId: 'rule_assignment_deadlines',
          ruleName: 'Assignment Deadline Reminders',
          category: 'Academic',
          reminderDays: [3, 1, 0],
          priority: 'high',
          targetRoles: ['student'],
        ),
        NotificationRuleModel(
          ruleId: 'rule_fee_deadlines',
          ruleName: 'Fee Payment Reminders',
          category: 'Finance',
          reminderDays: [7, 3, 1, 0],
          priority: 'high',
          targetRoles: ['student', 'parent', 'admin'],
        ),
      ];

      for (var r in defaultRules) {
        await _firestore.collection('notification_rules').doc(r.ruleId).set(r.toMap(), SetOptions(merge: true));
      }

      // 16. Seed Student Projects
      final projects = [
        ProjectModel(
          id: 'proj-1',
          studentUid: 'DEMO-STU',
          title: 'UniSphere - Smart Campus ERP Platform',
          description: 'A unified mobile & web campus management system built with Flutter, Firebase Firestore, and real-time push analytics.',
          technologies: ['Flutter', 'Firebase', 'Dart', 'Riverpod'],
          githubUrl: 'https://github.com/saravana/unisphere-main-v2',
          guideName: 'Dr. R. Kumar',
          status: 'Completed',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
        ProjectModel(
          id: 'proj-2',
          studentUid: 'DEMO-STU',
          title: 'AI Automated Attendance & Facial Recognition System',
          description: 'Deep learning vision model integrated with mobile camera streams for contactless biometric attendance verification.',
          technologies: ['Python', 'OpenCV', 'TensorFlow', 'Flutter'],
          githubUrl: 'https://github.com/saravana/ai-attendance-biometric',
          guideName: 'Dr. Grace Hopper',
          status: 'Ongoing',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        ProjectModel(
          id: 'proj-aravind-1',
          studentUid: '917721104012',
          title: 'Distributed File Sharing & Cloud Storage Node',
          description: 'Peer-to-peer decentralized storage platform built with Go, gRPC, and distributed hash tables for high throughput campus data sharing.',
          technologies: ['Go', 'gRPC', 'Docker', 'PostgreSQL'],
          githubUrl: 'https://github.com/aravind-dev/distributed-store',
          guideName: 'Dr. Robert Vance',
          status: 'Completed',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
        ProjectModel(
          id: 'proj-priya-1',
          studentUid: '917721104045',
          title: 'Medical Imaging Diagnostics with Vision Transformers',
          description: 'Deep learning classifier for chest X-ray disease detection utilizing PyTorch and Vision Transformers (ViT) with explainable Grad-CAM heatmaps.',
          technologies: ['Python', 'PyTorch', 'Transformers', 'FastAPI'],
          githubUrl: 'https://github.com/priyadharshini/vit-medical-imaging',
          guideName: 'Dr. Grace Hopper',
          status: 'Completed',
          createdAt: DateTime.now().subtract(const Duration(days: 50)),
        ),
        ProjectModel(
          id: 'proj-karthik-1',
          studentUid: '917722104022',
          title: 'Campus Food Delivery & Canteen Ordering App',
          description: 'Cross-platform mobile application for pre-ordering campus meals, real-time order tracking, and UPI digital payments.',
          technologies: ['Flutter', 'Firebase', 'Dart', 'Stripe'],
          githubUrl: 'https://github.com/karthik-coder/campus-eats',
          guideName: 'Prof. Sarah Jenkins',
          status: 'Completed',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        ProjectModel(
          id: 'proj-sneha-1',
          studentUid: '917723104089',
          title: 'Smart IoT Greenhouse & Climate Control Pipeline',
          description: 'Microcontroller sensor node monitoring soil moisture, temperature, and automated water irrigation with cloud dashboards.',
          technologies: ['C++', 'Arduino', 'MQTT', 'Node-RED'],
          githubUrl: 'https://github.com/sneha-dev/smart-greenhouse-iot',
          guideName: 'Dr. Anita Roy',
          status: 'Completed',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

      for (var pr in projects) {
        await _firestore.collection('projects').doc(pr.id).set(pr.toMap(), SetOptions(merge: true));
      }

      // 17. Seed Leave Applications
      final leaves = [
        {
          'id': 'leave-1',
          'student_uid': 'DEMO-STU',
          'student_name': 'Alex Johnson',
          'reason': 'On-Duty Leave for Smart Campus Hackathon Participation',
          'start_date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
          'end_date': DateTime.now().add(const Duration(days: 12)).toIso8601String(),
          'status': 'Approved',
          'applied_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'approved_by': 'Dr. R. Kumar (HOD)',
        },
      ];

      for (var l in leaves) {
        await _firestore.collection('leave_applications').doc(l['id'].toString()).set(l, SetOptions(merge: true));
      }

      // 18. Seed Published Syllabi Documents
      final syllabi = [
        SyllabusSubjectModel(
          id: 'SYLL-CS101-2026',
          subjectCode: 'CS101',
          subjectName: 'Programming in C',
          department: 'Computer Science & Engineering',
          applicableBatch: '2026–2030',
          year: 'I Year',
          semester: 'Semester 1',
          academicYear: '2026–2027',
          effectiveStartYear: 2026,
          credits: 4,
          subjectType: 'Theory',
          description: 'Fundamental programming constructs, data types, control flow, functions, arrays, pointers, structures, file operations, and algorithmic logic in C language.',
          units: [
            SyllabusUnitModel(unitNumber: 'Unit I', title: 'C Language Fundamentals & Data Types', topics: ['Algorithm & Flowcharts', 'Structure of C Program', 'Variables & Data Types', 'Operators & Expressions']),
            SyllabusUnitModel(unitNumber: 'Unit II', title: 'Control Flow & Decision Statements', topics: ['if-else Statements', 'switch-case Statements', 'while & do-while Loops', 'for Loops']),
            SyllabusUnitModel(unitNumber: 'Unit III', title: 'Arrays, Strings & User-defined Functions', topics: ['Single & Multi-dimensional Arrays', 'String Manipulation', 'Function Prototypes', 'Recursion']),
            SyllabusUnitModel(unitNumber: 'Unit IV', title: 'Pointers & Dynamic Memory Management', topics: ['Pointer Arithmetic', 'Pointers to Arrays & Functions', 'Dynamic Memory Allocation']),
            SyllabusUnitModel(unitNumber: 'Unit V', title: 'Structures, Unions & File Handling', topics: ['Defining Structures & Unions', 'File Pointers & Modes', 'Sequential Access']),
          ],
          textbooks: ['Programming in ANSI C (8th Edition) by E. Balagurusamy, McGraw Hill'],
          referenceBooks: ['The C Programming Language (2nd Edition) by Kernighan and Ritchie'],
          documentUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          documentFileName: 'CS101_Programming_in_C_2026-27.pdf',
          documentSize: '2.4 MB',
          lastUpdated: DateTime(2026, 8, 1),
          status: 'published',
        ),
        SyllabusSubjectModel(
          id: 'SYLL-MA101-2026',
          subjectCode: 'MA101',
          subjectName: 'Mathematics I: Calculus & Linear Algebra',
          department: 'Computer Science & Engineering',
          applicableBatch: '2026–2030',
          year: 'I Year',
          semester: 'Semester 1',
          academicYear: '2026–2027',
          effectiveStartYear: 2026,
          credits: 4,
          subjectType: 'Theory',
          description: 'Matrix algebra, eigenvalues, multivariable calculus, partial derivatives, double and triple integrals, and vector calculus.',
          units: [
            SyllabusUnitModel(unitNumber: 'Unit I', title: 'Matrices & Linear Systems', topics: ['Rank of a Matrix', 'System of Linear Equations', 'Eigenvalues & Eigenvectors']),
          ],
          textbooks: ['Higher Engineering Mathematics (44th Edition) by B.S. Grewal'],
          referenceBooks: ['Advanced Engineering Mathematics by Erwin Kreyszig'],
          documentUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          documentFileName: 'MA101_Mathematics_I_2026-27.pdf',
          documentSize: '3.1 MB',
          lastUpdated: DateTime(2026, 8, 2),
          status: 'published',
        ),
        SyllabusSubjectModel(
          id: 'SYLL-PH101-2026',
          subjectCode: 'PH101',
          subjectName: 'Physics for Computing',
          department: 'Computer Science & Engineering',
          applicableBatch: '2026–2030',
          year: 'I Year',
          semester: 'Semester 1',
          academicYear: '2026–2027',
          effectiveStartYear: 2026,
          credits: 3,
          subjectType: 'Theory',
          description: 'Quantum mechanics, lasers, fiber optics, semiconductor physics, and magnetic materials.',
          units: [
            SyllabusUnitModel(unitNumber: 'Unit I', title: 'Wave Optics & Lasers', topics: ['Interference & Diffraction', 'Laser Principles', 'Semiconductor Lasers']),
          ],
          textbooks: ['A Textbook of Engineering Physics by M.N. Avadhanulu'],
          referenceBooks: ['Concepts of Modern Physics by Arthur Beiser'],
          documentUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          documentFileName: 'PH101_Physics_2026-27.pdf',
          documentSize: '1.9 MB',
          lastUpdated: DateTime(2026, 8, 1),
          status: 'published',
        ),
      ];

      for (var s in syllabi) {
        await _firestore.collection('syllabi').doc(s.id).set(s.toMap(), SetOptions(merge: true));
      }

      // 18. Seed Photo Albums and Gallery Photos
      final albums = [
        PhotoAlbumModel(
          albumId: 'album-tech-symposium-2026',
          title: 'National Tech Symposium & Innovation Expo 2026',
          description: 'Highlights from the annual tech symposium featuring project displays, guest keynote lectures, robotics arena, and hackathon awards ceremony.',
          eventDate: DateTime.now().subtract(const Duration(days: 5)),
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          coverPhotoUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200&q=80',
          status: AlbumStatus.published,
          createdBy: 'DEMO-HOD',
          createdByName: 'Dr. R. Kumar (HOD CSE)',
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          publishedAt: DateTime.now().subtract(const Duration(days: 5)),
          photoCount: 5,
        ),
        PhotoAlbumModel(
          albumId: 'album-ai-hackathon-2026',
          title: 'Smart Campus AI Hackathon Grand Finale',
          description: 'Memorable moments from the 36-hour non-stop hackathon with live coding sessions, mentor interactions, and winning project demonstrations.',
          eventDate: DateTime.now().subtract(const Duration(days: 12)),
          departmentId: 'DEP-CSE',
          departmentName: 'Computer Science & Engineering',
          coverPhotoUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=1200&q=80',
          status: AlbumStatus.published,
          createdBy: 'DEMO-HOD',
          createdByName: 'Dr. R. Kumar (HOD CSE)',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          updatedAt: DateTime.now().subtract(const Duration(days: 12)),
          publishedAt: DateTime.now().subtract(const Duration(days: 12)),
          photoCount: 4,
        ),
        PhotoAlbumModel(
          albumId: 'album-cultural-fest-2026',
          title: 'Annual Campus Cultural Fest – Waves 2026',
          description: 'Vibrant musical performances, dance competitions, fashion shows, and celebrity guest appearances during our flagship cultural event.',
          eventDate: DateTime.now().subtract(const Duration(days: 20)),
          departmentId: 'DEP-ECE',
          departmentName: 'Electronics & Communication',
          coverPhotoUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=1200&q=80',
          status: AlbumStatus.published,
          createdBy: 'HOD-ECE-01',
          createdByName: 'Dr. V. Swaminathan',
          createdAt: DateTime.now().subtract(const Duration(days: 22)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
          publishedAt: DateTime.now().subtract(const Duration(days: 20)),
          photoCount: 4,
        ),
        PhotoAlbumModel(
          albumId: 'album-sports-meet-2026',
          title: 'Inter-Departmental Athletics & Sports Championship',
          description: 'Thrilling track & field events, football finals, basketball championships, and trophy presentations honoring champion athletes.',
          eventDate: DateTime.now().subtract(const Duration(days: 28)),
          departmentId: 'DEP-MECH',
          departmentName: 'Mechanical Engineering',
          coverPhotoUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=1200&q=80',
          status: AlbumStatus.published,
          createdBy: 'HOD-MECH-01',
          createdByName: 'Dr. K. Ramanathan',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 28)),
          publishedAt: DateTime.now().subtract(const Duration(days: 28)),
          photoCount: 4,
        ),
      ];

      final Map<String, List<GalleryPhotoModel>> albumPhotosMap = {
        'album-tech-symposium-2026': [
          GalleryPhotoModel(
            photoId: 'photo-ts-1',
            albumId: 'album-tech-symposium-2026',
            photoUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200&q=80',
            caption: 'Keynote Address by Industry Leaders in Main Auditorium',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
            displayOrder: 0,
          ),
          GalleryPhotoModel(
            photoId: 'photo-ts-2',
            albumId: 'album-tech-symposium-2026',
            photoUrl: 'https://images.unsplash.com/photo-1523580494863-6f3031224c94?w=1200&q=80',
            caption: 'Student Project Exhibition & Prototype Demonstrations',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
            displayOrder: 1,
          ),
          GalleryPhotoModel(
            photoId: 'photo-ts-3',
            albumId: 'album-tech-symposium-2026',
            photoUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=1200&q=80',
            caption: 'Robotics Arena Arena Competition in Progress',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
            displayOrder: 2,
          ),
          GalleryPhotoModel(
            photoId: 'photo-ts-4',
            albumId: 'album-tech-symposium-2026',
            photoUrl: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=1200&q=80',
            caption: 'Interactive Workshop on Cloud & Distributed Architecture',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
            displayOrder: 3,
          ),
          GalleryPhotoModel(
            photoId: 'photo-ts-5',
            albumId: 'album-tech-symposium-2026',
            photoUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200&q=80',
            caption: 'Award Distribution Ceremony for Top Innovation Projects',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
            displayOrder: 4,
          ),
        ],
        'album-ai-hackathon-2026': [
          GalleryPhotoModel(
            photoId: 'photo-hack-1',
            albumId: 'album-ai-hackathon-2026',
            photoUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=1200&q=80',
            caption: 'Teams collaborating during overnight coding sprint',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 12)),
            displayOrder: 0,
          ),
          GalleryPhotoModel(
            photoId: 'photo-hack-2',
            albumId: 'album-ai-hackathon-2026',
            photoUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200&q=80',
            caption: 'Mentorship round with Senior Cloud Solution Architects',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 12)),
            displayOrder: 1,
          ),
          GalleryPhotoModel(
            photoId: 'photo-hack-3',
            albumId: 'album-ai-hackathon-2026',
            photoUrl: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=1200&q=80',
            caption: 'Final Jury Pitch Presentation in Main Conference Hall',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 12)),
            displayOrder: 2,
          ),
          GalleryPhotoModel(
            photoId: 'photo-hack-4',
            albumId: 'album-ai-hackathon-2026',
            photoUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1200&q=80',
            caption: '1st Place Winner Team CyberKnights receiving ₹1,00,000 Cheque',
            uploadedBy: 'DEMO-HOD',
            uploadedAt: DateTime.now().subtract(const Duration(days: 12)),
            displayOrder: 3,
          ),
        ],
        'album-cultural-fest-2026': [
          GalleryPhotoModel(
            photoId: 'photo-cult-1',
            albumId: 'album-cultural-fest-2026',
            photoUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=1200&q=80',
            caption: 'Grand Stage Lighting & Inaugural Musical Concert',
            uploadedBy: 'HOD-ECE-01',
            uploadedAt: DateTime.now().subtract(const Duration(days: 20)),
            displayOrder: 0,
          ),
          GalleryPhotoModel(
            photoId: 'photo-cult-2',
            albumId: 'album-cultural-fest-2026',
            photoUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200&q=80',
            caption: 'Classical & Contemporary Group Dance Competition',
            uploadedBy: 'HOD-ECE-01',
            uploadedAt: DateTime.now().subtract(const Duration(days: 20)),
            displayOrder: 1,
          ),
          GalleryPhotoModel(
            photoId: 'photo-cult-3',
            albumId: 'album-cultural-fest-2026',
            photoUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=1200&q=80',
            caption: 'Celebrity DJ Night with Campus Crowd Celebration',
            uploadedBy: 'HOD-ECE-01',
            uploadedAt: DateTime.now().subtract(const Duration(days: 20)),
            displayOrder: 2,
          ),
          GalleryPhotoModel(
            photoId: 'photo-cult-4',
            albumId: 'album-cultural-fest-2026',
            photoUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1200&q=80',
            caption: 'Fashion Show Runway Display',
            uploadedBy: 'HOD-ECE-01',
            uploadedAt: DateTime.now().subtract(const Duration(days: 20)),
            displayOrder: 3,
          ),
        ],
        'album-sports-meet-2026': [
          GalleryPhotoModel(
            photoId: 'photo-sp-1',
            albumId: 'album-sports-meet-2026',
            photoUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=1200&q=80',
            caption: '100m Athletics Final Sprint at University Stadium',
            uploadedBy: 'HOD-MECH-01',
            uploadedAt: DateTime.now().subtract(const Duration(days: 28)),
            displayOrder: 0,
          ),
          GalleryPhotoModel(
            photoId: 'photo-sp-2',
            albumId: 'album-sports-meet-2026',
            photoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=1200&q=80',
            caption: 'Inter-Departmental Football Championship Trophy Final',
            uploadedBy: 'HOD-MECH-01',
            uploadedAt: DateTime.now().subtract(const Duration(days: 28)),
            displayOrder: 1,
          ),
          GalleryPhotoModel(
            photoId: 'photo-sp-3',
            albumId: 'album-sports-meet-2026',
            photoUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200&q=80',
            caption: 'Basketball Finals High Voltage Match',
            uploadedBy: 'HOD-MECH-01',
            uploadedAt: DateTime.now().subtract(const Duration(days: 28)),
            displayOrder: 2,
          ),
          GalleryPhotoModel(
            photoId: 'photo-sp-4',
            albumId: 'album-sports-meet-2026',
            photoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266010b?w=1200&q=80',
            caption: 'Overall Championship Shield Awarded to CSE Department',
            uploadedBy: 'HOD-MECH-01',
            uploadedAt: DateTime.now().subtract(const Duration(days: 28)),
            displayOrder: 3,
          ),
        ],
      };

      for (var album in albums) {
        await _firestore.collection('photo_albums').doc(album.albumId).set(album.toMap(), SetOptions(merge: true));
        final photos = albumPhotosMap[album.albumId] ?? [];
        for (var p in photos) {
          await _firestore
              .collection('photo_albums')
              .doc(album.albumId)
              .collection('photos')
              .doc(p.photoId)
              .set(p.toMap(), SetOptions(merge: true));
        }
      }

      // 19. Seed Official Academic Schedules
      final initialSchedule = AcademicScheduleModel(
        id: 'SCHED-2026-I-YEAR-V1',
        title: 'Academic Schedule for I Year',
        description: 'Official College Academic Calendar & Schedule of Working Days, Continuous Assessments, Holidays and End-Semester Examinations.',
        academicYear: '2026-27',
        departmentId: 'all',
        departmentName: 'All Departments',
        targetStudentYear: 'I Year',
        semester: 'Odd Semester (Semester 1)',
        fileName: 'Academic schedule for I Year_07.08.2026.xls',
        fileType: 'xls',
        fileUrl: '',
        storagePath: 'academic_schedules/2026-27/all/I_Year/SCHED-2026-I-YEAR-V1/v1/Academic schedule for I Year_07.08.2026.xls',
        fileSize: 184320,
        version: 1,
        status: ScheduleStatus.active,
        isLatest: true,
        publishedAt: DateTime(2026, 8, 7),
        uploadedAt: DateTime(2026, 8, 7),
        uploadedBy: 'HOD-CSE-01',
        uploadedByName: 'Dr. Suresh Kumar',
        updatedAt: DateTime(2026, 8, 7),
        scheduleEvents: [
          ScheduleEventItem(
            dateString: '07 Aug 2026',
            date: DateTime(2026, 8, 7),
            title: 'Commencement of Classes for I Year (Odd Sem)',
            category: 'Academic',
            description: 'Official reopening and orientation for freshers',
          ),
          ScheduleEventItem(
            dateString: '15 Aug 2026',
            date: DateTime(2026, 8, 15),
            title: 'Independence Day',
            category: 'Holiday',
            isHoliday: true,
          ),
          ScheduleEventItem(
            dateString: '01 Sep 2026 - 05 Sep 2026',
            date: DateTime(2026, 9, 1),
            title: 'Continuous Assessment Test 1 (CAT-1)',
            category: 'Assessment',
            description: 'First internal assessment examinations across all departments',
          ),
          ScheduleEventItem(
            dateString: '17 Sep 2026',
            date: DateTime(2026, 9, 17),
            title: 'Milad-un-Nabi',
            category: 'Holiday',
            isHoliday: true,
          ),
          ScheduleEventItem(
            dateString: '02 Oct 2026',
            date: DateTime(2026, 10, 2),
            title: 'Gandhi Jayanti',
            category: 'Holiday',
            isHoliday: true,
          ),
          ScheduleEventItem(
            dateString: '12 Oct 2026 - 16 Oct 2026',
            date: DateTime(2026, 10, 12),
            title: 'Continuous Assessment Test 2 (CAT-2)',
            category: 'Assessment',
            description: 'Second internal assessment examinations',
          ),
          ScheduleEventItem(
            dateString: '20 Oct 2026',
            date: DateTime(2026, 10, 20),
            title: 'Student Online Feedback Cycle 1',
            category: 'Academic',
          ),
          ScheduleEventItem(
            dateString: '31 Oct 2026',
            date: DateTime(2026, 10, 31),
            title: 'Deepavali',
            category: 'Holiday',
            isHoliday: true,
          ),
          ScheduleEventItem(
            dateString: '16 Nov 2026 - 20 Nov 2026',
            date: DateTime(2026, 11, 16),
            title: 'Model Practical & Theory Examinations',
            category: 'Examination',
            description: 'Final preparatory exams before University Finals',
          ),
          ScheduleEventItem(
            dateString: '28 Nov 2026',
            date: DateTime(2026, 11, 28),
            title: 'Last Working Day for I Year (Odd Sem)',
            category: 'Academic',
          ),
          ScheduleEventItem(
            dateString: '07 Dec 2026',
            date: DateTime(2026, 12, 7),
            title: 'Commencement of University End-Sem Theory Exams',
            category: 'Examination',
          ),
        ],
      );

      await _firestore
          .collection('academicSchedules')
          .doc(initialSchedule.id)
          .set(initialSchedule.toMap(), SetOptions(merge: true));

      debugPrint('✅ UniSphere Complete Database Seeding Succeeded across 19 Collections!');
      return true;

    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        debugPrint('⚠️ DatabaseSeeder Notice: Firestore permission-denied. Ensure Firestore Security Rules allow read/write in Firebase Console.');
      } else {
        debugPrint('❌ DatabaseSeeder Error: $e');
      }
      return false;
    }
  }
}
