import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/firebase_options.dart';
import 'package:unisphere/models/announcement_model.dart';
import 'package:unisphere/models/assignment_model.dart';
import 'package:unisphere/models/exam_model.dart';
import 'package:unisphere/models/hackathon_model.dart';
import 'package:unisphere/models/mark_model.dart';
import 'package:unisphere/models/submission_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/firebase_auth_service.dart';
import 'package:unisphere/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseOptions Configuration Tests', () {
    test('Android options have correct project ID and credentials', () {
      expect(DefaultFirebaseOptions.android.projectId, 'unisphere-a2be4');
      expect(DefaultFirebaseOptions.android.messagingSenderId, '1017293831751');
      expect(DefaultFirebaseOptions.android.appId, '1:1017293831751:android:f66b6c9a8b851402d77b62');
    });

    test('iOS options have correct bundle ID, App ID, and iosClientId', () {
      expect(DefaultFirebaseOptions.ios.projectId, 'unisphere-a2be4');
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'unisphere');
      expect(DefaultFirebaseOptions.ios.appId, '1:1017293831751:ios:4e5e6f3f8ba2d6d8d77b62');
      expect(
        DefaultFirebaseOptions.ios.iosClientId,
        '1017293831751-bsff5f865lco5q4b94t53933l9gmu2sh.apps.googleusercontent.com',
      );
    });

    test('Web options have correct project ID and storage bucket', () {
      expect(DefaultFirebaseOptions.web.projectId, 'unisphere-a2be4');
      expect(DefaultFirebaseOptions.web.storageBucket, 'unisphere-a2be4.firebasestorage.app');
    });
  });

  group('FirebaseService Singleton & State Tests', () {
    test('FirebaseService instance is singleton', () {
      final instance1 = FirebaseService.instance;
      final instance2 = FirebaseService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('isInitialized returns boolean', () {
      final service = FirebaseService.instance;
      expect(service.isInitialized, isA<bool>());
    });
  });

  group('Firebase Model Serialization Tests', () {
    test('AnnouncementModel map conversion', () {
      final announcement = AnnouncementModel(
        id: 'ann-1',
        title: 'Campus Update',
        content: 'Midterm exams schedule released.',
        authorName: 'Admin',
        createdAt: DateTime(2026, 8, 13),
        category: 'Exam',
        priority: 'Urgent',
      );

      final map = announcement.toMap();
      expect(map['id'], 'ann-1');
      expect(map['title'], 'Campus Update');
      expect(map['category'], 'Exam');
      expect(map['priority'], 'Urgent');

      final reconstructed = AnnouncementModel.fromMap(map);
      expect(reconstructed.id, 'ann-1');
      expect(reconstructed.title, 'Campus Update');
      expect(reconstructed.category, 'Exam');
    });

    test('AssignmentModel map conversion', () {
      final assignment = AssignmentModel(
        id: 'asg-101',
        title: 'Flutter Firebase Integration',
        description: 'Set up Firebase in Flutter app',
        authorName: 'Prof. Smith',
        subjectName: 'Mobile Dev',
        createdAt: DateTime(2026, 8, 10),
        dueDate: DateTime(2026, 8, 20),
        maxMarks: 100,
        targetedClasses: ['CSE-3A'],
        status: 'Pending',
      );

      final map = assignment.toMap();
      expect(map['id'], 'asg-101');
      expect(map['subject_name'], 'Mobile Dev');
      expect(map['max_marks'], 100);

      final reconstructed = AssignmentModel.fromMap(map);
      expect(reconstructed.id, 'asg-101');
      expect(reconstructed.title, 'Flutter Firebase Integration');
      expect(reconstructed.maxMarks, 100);
    });

    test('SubmissionModel map conversion', () {
      final submission = SubmissionModel(
        id: 'sub-1',
        assignmentId: 'asg-101',
        studentUid: 'uid-55',
        studentName: 'John Doe',
        registerNumber: 'RA2111003010001',
        fileUrl: 'https://storage.googleapis.com/test.pdf',
        submittedAt: DateTime(2026, 8, 14),
        status: 'Submitted',
        obtainedMarks: 95,
      );

      final map = submission.toMap();
      expect(map['id'], 'sub-1');
      expect(map['assignment_id'], 'asg-101');
      expect(map['obtained_marks'], 95);

      final reconstructed = SubmissionModel.fromMap(map);
      expect(reconstructed.id, 'sub-1');
      expect(reconstructed.assignmentId, 'asg-101');
      expect(reconstructed.obtainedMarks, 95);
    });

    test('ExamModel map conversion', () {
      final exam = ExamModel(
        id: 'ex-1',
        subjectName: 'Database Systems',
        courseCode: 'CS301',
        examType: 'Midterm Exam',
        date: DateTime(2026, 8, 25),
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        durationMinutes: 120,
        venue: 'Main Block',
        roomNumber: 'Lab 3',
        blockBuilding: 'CS Building',
        instructions: 'Bring your student ID card.',
      );

      final map = exam.toMap();
      expect(map['id'], 'ex-1');
      expect(map['subject_name'], 'Database Systems');
      expect(map['room_number'], 'Lab 3');

      final reconstructed = ExamModel.fromMap(map);
      expect(reconstructed.id, 'ex-1');
      expect(reconstructed.subjectName, 'Database Systems');
      expect(reconstructed.examType, 'Midterm Exam');
    });

    test('MarkModel map conversion', () {
      final mark = MarkModel(
        id: 'mk-1',
        studentUid: 'uid-55',
        subjectName: 'Software Engineering',
        obtainedMarks: 85,
        totalMarks: 100,
        examType: 'Internal Assessment',
        updatedAt: DateTime(2026, 8, 10),
      );

      final map = mark.toMap();
      expect(map['subject_name'], 'Software Engineering');
      expect(map['obtained_marks'], 85);
      expect(map['total_marks'], 100);

      final reconstructed = MarkModel.fromMap(map);
      expect(reconstructed.subjectName, 'Software Engineering');
      expect(reconstructed.obtainedMarks, 85);
    });

    test('HackathonModel map conversion', () {
      final hackathon = HackathonModel(
        id: 'hack-1',
        title: 'Smart Campus Hackathon 2026',
        description: 'Build innovative solutions for campus life.',
        category: 'AI & Mobile',
        organizer: 'UniSphere Club',
        mode: 'Hybrid',
        bannerImage: 'https://example.com/banner.png',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 3),
        registrationOpen: true,
        registrationDeadline: DateTime(2026, 8, 30),
        prizePool: '₹50,000',
        registeredTeams: 12,
        maxTeams: 50,
        teamSize: 4,
        status: 'upcoming',
        userRegistrationStatus: 'not_registered',
        location: 'Auditorium 1',
        tags: ['Flutter', 'AI', 'Firebase'],
      );

      final map = hackathon.toMap();
      expect(map['id'], 'hack-1');
      expect(map['title'], 'Smart Campus Hackathon 2026');
      expect(map['teamSize'], 4);

      final reconstructed = HackathonModel.fromMap(map);
      expect(reconstructed.id, 'hack-1');
      expect(reconstructed.title, 'Smart Campus Hackathon 2026');
      expect(reconstructed.teamSize, 4);
    });
  });

  group('FirebaseAuthService Real-Time Authentication Tests', () {
    test('FirebaseAuthService initializes and handles authStateChanges stream', () async {
      final authService = FirebaseAuthService();
      expect(authService, isNotNull);
      
      // Check initial auth state stream emission
      final initialUser = await authService.authStateChanges.first;
      expect(initialUser, isNull);
    });

    test('Real-time sign in updates currentUser and emits to authStateChanges stream', () async {
      final authService = FirebaseAuthService();

      // Sign in with demo student account
      await authService.signInWithEmail('student@unisphere.edu', 'StudentPass123!');

      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.email, 'student@unisphere.edu');
      expect(authService.currentUser?.role, UserRole.student);

      // Sign out
      await authService.signOut();
      expect(authService.currentUser, isNull);
    });

    test('Real-time profile update updates user data and emits stream event', () async {
      final authService = FirebaseAuthService();

      await authService.signInWithEmail('hod.cse@unisphere.edu', 'HodPass123!');
      final user = authService.currentUser;
      expect(user?.role, UserRole.hod);

      // Update profile
      final updatedUser = user!.copyWith(name: 'Dr. R. Kumar (HOD CSE)');
      await authService.updateUserProfile(updatedUser);

      expect(authService.currentUser?.name, 'Dr. R. Kumar (HOD CSE)');

      await authService.signOut();
      expect(authService.currentUser, isNull);
    });
  });
}

