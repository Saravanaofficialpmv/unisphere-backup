import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:unisphere/services/parent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parent Student Linking & Real-Time Sync Tests', () {
    late ParentService parentService;

    setUp(() {
      parentService = ParentService(firestore: null);
    });

    test('1. lookupStudentByRegNo resolves registered student real data', () async {
      final studentData = await parentService.lookupStudentByRegNo('917721104012');
      expect(studentData, isNotNull);
      expect(studentData!['fullName'], equals('Aravind Swamy'));
      expect(studentData['department'], contains('Computer Science'));
      expect(studentData['semester'], equals('VI Semester'));
    });

    test('2. Dynamic caching and updating student profile immediately updates lookup', () async {
      const regNo = '922523243199';
      final dynamicProfile = {
        'fullName': 'Siddharth Varma',
        'name': 'Siddharth Varma',
        'registerNumber': regNo,
        'regNo': regNo,
        'departmentName': 'Artificial Intelligence & Data Science',
        'department': 'Artificial Intelligence & Data Science',
        'semester': 'IV Semester',
        'currentYear': 'II Year',
        'cgpa': '9.45',
        'attendancePercent': '96.2%',
        'presentCount': 160,
        'absentCount': 4,
        'leaveOdCount': 2,
        'todayStatus': 'Present',
        'photoUrl': 'https://example.com/siddharth.png',
        'fatherPhotoUrl': 'https://example.com/father.png',
        'motherPhotoUrl': 'https://example.com/mother.png',
        'totalFees': 60000.0,
        'paidFees': 60000.0,
        'pendingFees': 0.0,
        'subjectGrades': [
          {'code': 'AI401', 'name': 'Machine Learning Foundations', 'grade': 'O', 'percent': 0.95},
          {'code': 'AI402', 'name': 'Deep Neural Networks', 'grade': 'O', 'percent': 0.94},
        ],
      };

      parentService.cacheStudentProfile(regNo, dynamicProfile);

      final lookupResult = await parentService.lookupStudentByRegNo(regNo);
      expect(lookupResult, isNotNull);
      expect(lookupResult!['fullName'], equals('Siddharth Varma'));
      expect(lookupResult['cgpa'], equals('9.45'));
      expect(lookupResult['department'], equals('Artificial Intelligence & Data Science'));
      expect(lookupResult['photoUrl'], equals('https://example.com/siddharth.png'));
      expect(lookupResult['fatherPhotoUrl'], equals('https://example.com/father.png'));
      expect(lookupResult['motherPhotoUrl'], equals('https://example.com/mother.png'));
    });

    test('3. Linking a student to a parent account makes real student ward available in wards list', () async {
      const parentId = 'test_parent_user_001';
      const childRegNo = '922523243199';

      final linkSuccess = await parentService.linkAdditionalChild(
        parentUidOrEmail: parentId,
        childRegisterNumber: childRegNo,
        parentName: 'Ramesh Varma',
        phone: '+91 9876543210',
      );

      expect(linkSuccess, isTrue);

      final wards = await parentService.getStudentWardsForParent(parentId);
      expect(wards, isNotEmpty);
      expect(wards.any((w) => w.regNo.toUpperCase() == childRegNo.toUpperCase()), isTrue);

      final ward = wards.firstWhere((w) => w.regNo.toUpperCase() == childRegNo.toUpperCase());
      expect(ward.name, equals('Siddharth Varma'));
      expect(ward.cgpa, equals('9.45'));
      expect(ward.department, equals('Artificial Intelligence & Data Science'));
      expect(ward.attendancePercent, closeTo(0.962, 0.01));
      expect(ward.fatherPhotoUrl, equals('https://example.com/father.png'));
      expect(ward.motherPhotoUrl, equals('https://example.com/mother.png'));
      expect(ward.subjectGrades.length, equals(2));
      expect(ward.subjectGrades.first.subjectCode, equals('AI401'));
      expect(ward.subjectGrades.first.grade, equals('O'));
    });

    test('4. Real-time updates to student data reflect in getStudentWardsForParent without stale fallback', () async {
      const parentId = 'test_parent_user_001';
      const childRegNo = '922523243199';

      // Update student data (e.g. grades updated, attendance updated, CGPA changed to 9.60)
      final updatedProfile = {
        'fullName': 'Siddharth Varma',
        'name': 'Siddharth Varma',
        'registerNumber': childRegNo,
        'regNo': childRegNo,
        'departmentName': 'Artificial Intelligence & Data Science',
        'department': 'Artificial Intelligence & Data Science',
        'semester': 'IV Semester',
        'currentYear': 'II Year',
        'cgpa': '9.60',
        'academicTrend': '+0.15 from Sem III',
        'academicStatus': 'Dean\'s Scholar',
        'attendancePercent': '97.5%',
        'presentCount': 165,
        'absentCount': 3,
        'leaveOdCount': 2,
        'todayStatus': 'Present',
        'photoUrl': 'https://example.com/siddharth_new.png',
        'fatherPhotoUrl': 'https://example.com/father.png',
        'motherPhotoUrl': 'https://example.com/mother.png',
        'totalFees': 60000.0,
        'paidFees': 60000.0,
        'pendingFees': 0.0,
      };

      parentService.cacheStudentProfile(childRegNo, updatedProfile);

      final wards = await parentService.getStudentWardsForParent(parentId);
      final ward = wards.firstWhere((w) => w.regNo.toUpperCase() == childRegNo.toUpperCase());

      expect(ward.cgpa, equals('9.60'));
      expect(ward.academicTrend, equals('+0.15 from Sem III'));
      expect(ward.academicStatus, equals('Dean\'s Scholar'));
      expect(ward.attendancePercent, closeTo(0.975, 0.01));
      expect(ward.photoUrl, equals('https://example.com/siddharth_new.png'));
    });

    test('5. Parent photo resolver picks up student ward parent photo automatically', () {
      final ward = ParentStudentWard(
        id: 'ward_001',
        name: 'Siddharth Varma',
        regNo: '922523243199',
        department: 'AI & DS',
        yearSection: 'AI & DS • II Year • IV Semester',
        currentYear: 'II Year',
        currentSemester: 'IV Semester',
        avatarInitials: 'SV',
        attendancePercent: 0.96,
        presentCount: 160,
        absentCount: 4,
        leaveOdCount: 2,
        cgpa: '9.6',
        academicTrend: '+0.15',
        academicStatus: 'Dean\'s Scholar',
        statusColor: const Color(0xFF10B981),
        totalFees: 60000,
        paidFees: 60000,
        pendingFees: 0,
        feeDueDate: DateTime.now(),
        feeStatus: 'Cleared',
        fatherPhotoUrl: 'https://example.com/father_photo.jpg',
        motherPhotoUrl: 'https://example.com/mother_photo.jpg',
        subjectGrades: [],
      );

      final fatherPhoto = parentService.resolveParentPhotoFromWards(
        relationship: 'Father',
        wards: [ward],
      );
      expect(fatherPhoto, equals('https://example.com/father_photo.jpg'));

      final motherPhoto = parentService.resolveParentPhotoFromWards(
        relationship: 'Mother',
        wards: [ward],
      );
      expect(motherPhoto, equals('https://example.com/mother_photo.jpg'));
    });

    test('6. watchParentWards stream emits wards list with linked children', () async {
      const parentId = 'test_parent_user_001';
      final stream = parentService.watchParentWards(parentId);
      final firstEmit = await stream.first;

      expect(firstEmit, isNotEmpty);
      expect(firstEmit.any((w) => w.regNo.toUpperCase() == '922523243199'), isTrue);
    });

    test('7. Active ward preference is saved and retrieved accurately', () async {
      const parentKey = 'test_parent_user_001';
      const preferredReg = '922523243199';

      await parentService.saveActiveWardPreference(
        parentUidOrEmail: parentKey,
        wardRegNo: preferredReg,
      );

      final retrievedPref = await parentService.getActiveWardPreference(parentKey);
      expect(retrievedPref, equals(preferredReg));
    });
  });
}
