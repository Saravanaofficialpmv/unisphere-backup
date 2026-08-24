import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/parent_model.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:unisphere/services/parent_service.dart';

void main() {
  group('Parent Service Multi-Child Tests', () {
    late ParentService parentService;

    setUp(() {
      parentService = ParentService();
    });

    test('Default student wards are populated properly', () {
      final defaultWards = parentService.getDefaultStudentWards();
      expect(defaultWards.length, greaterThanOrEqualTo(2));
      expect(defaultWards.first.name, 'Arun Kumar');
      expect(defaultWards.first.regNo, '23CSE1042');
      expect(defaultWards[1].name, 'Kavya Kumar');
      expect(defaultWards[1].regNo, '24ECE2018');
    });

    test('Live lookup resolves known demo students', () async {
      final student1 = await parentService.lookupStudentByRegNo('917721104012');
      expect(student1, isNotNull);
      expect(student1!['fullName'], 'Aravind Swamy');

      final student2 = await parentService.lookupStudentByRegNo('917722104022');
      expect(student2, isNotNull);
      expect(student2!['fullName'], 'Karthik Raja');

      final student3 = await parentService.lookupStudentByRegNo('23CSE1042');
      expect(student3, isNotNull);
      expect(student3!['fullName'], 'Arun Kumar');
    });

    test('ParentModel maps multiple children studentIds and wardRegisterNumbers', () {
      final parent = ParentModel(
        parentId: 'PRT-1001',
        userId: 'USER-PRT-1001',
        fullName: 'Ramesh Swamy',
        phone: '+91 94444 12345',
        email: 'ramesh.parent@gmail.com',
        studentIds: ['917721104012', '917722104022'],
        wardRegisterNumbers: ['917721104012', '917722104022'],
      );

      final map = parent.toMap();
      expect(map['parentId'], 'PRT-1001');
      expect(map['wardRegisterNumbers'], ['917721104012', '917722104022']);
      expect(map['studentIds'], ['917721104012', '917722104022']);

      final restored = ParentModel.fromMap(map, 'PRT-1001');
      expect(restored.wardRegisterNumbers.length, 2);
      expect(restored.wardRegisterNumbers, contains('917721104012'));
      expect(restored.wardRegisterNumbers, contains('917722104022'));
    });

    test('ParentService linkParentWithChildren runs cleanly without exception', () async {
      await parentService.linkParentWithChildren(
        parentId: 'TEST-PRT-01',
        userId: 'TEST-USER-01',
        parentName: 'Sundar Pichai',
        phone: '+91 99887 76655',
        email: 'sundar.parent@gmail.com',
        childRegisterNumbers: ['917721104012', '917722104022'],
      );
      expect(true, isTrue);
    });

    test('ParentStudentWard attendance status logic works correctly', () {
      final highAttWard = ParentStudentWard(
        id: 'w1',
        name: 'Alex',
        regNo: '917721104012',
        department: 'CSE',
        yearSection: 'CSE • IV Year',
        currentYear: 'IV Year',
        currentSemester: 'Semester VII',
        avatarInitials: 'AJ',
        attendancePercent: 0.92,
        presentCount: 92,
        absentCount: 8,
        leaveOdCount: 0,
        cgpa: '9.1',
        academicTrend: '+0.1',
        academicStatus: 'Dean List',
        statusColor: const Color(0xFF10B981),
        totalFees: 50000,
        paidFees: 50000,
        pendingFees: 0,
        feeDueDate: DateTime(2026, 9, 15),
        feeStatus: 'Cleared',
        subjectGrades: [],
      );

      expect(highAttWard.attendanceHealthStatus, 'Healthy');
    });
  });
}
