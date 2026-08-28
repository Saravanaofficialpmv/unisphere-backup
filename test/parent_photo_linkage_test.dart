import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:unisphere/services/parent_service.dart';

void main() {
  group('Parent Photo Linkage & Relationship Resolution Tests', () {
    late ParentService parentService;
    late ParentStudentWard mockWard;

    setUp(() {
      parentService = ParentService();
      mockWard = ParentStudentWard(
        id: 'ward_1',
        name: 'Alex Johnson',
        regNo: 'RA2111003010001',
        department: 'Computer Science',
        yearSection: 'CSE • III Year',
        currentYear: 'III Year',
        currentSemester: 'VI Semester',
        photoUrl: 'https://images.unsplash.com/photo-student.jpg',
        fatherPhotoUrl: 'https://images.unsplash.com/photo-father.jpg',
        motherPhotoUrl: 'https://images.unsplash.com/photo-mother.jpg',
        guardianPhotoUrl: 'https://images.unsplash.com/photo-guardian.jpg',
        avatarInitials: 'AJ',
        attendancePercent: 0.90,
        presentCount: 90,
        absentCount: 10,
        leaveOdCount: 0,
        cgpa: '8.9',
        academicTrend: 'Upward',
        academicStatus: 'Distinction',
        statusColor: const Color(0xFF10B981),
        totalFees: 50000,
        paidFees: 50000,
        pendingFees: 0,
        feeDueDate: DateTime(2026, 6, 1),
        feeStatus: 'Cleared',
        todayStatus: 'Present',
        subjectGrades: [],
      );
    });

    test('ParentStudentWard holds father, mother, and guardian photo URLs', () {
      expect(mockWard.fatherPhotoUrl, 'https://images.unsplash.com/photo-father.jpg');
      expect(mockWard.motherPhotoUrl, 'https://images.unsplash.com/photo-mother.jpg');
      expect(mockWard.guardianPhotoUrl, 'https://images.unsplash.com/photo-guardian.jpg');
    });

    test('resolveParentPhotoFromWards resolves Father photo for Father relationship', () {
      final photo = parentService.resolveParentPhotoFromWards(
        relationship: 'Father',
        wards: [mockWard],
      );
      expect(photo, 'https://images.unsplash.com/photo-father.jpg');
    });

    test('resolveParentPhotoFromWards resolves Mother photo for Mother relationship', () {
      final photo = parentService.resolveParentPhotoFromWards(
        relationship: 'Mother',
        wards: [mockWard],
      );
      expect(photo, 'https://images.unsplash.com/photo-mother.jpg');
    });

    test('resolveParentPhotoFromWards resolves Guardian photo for Guardian relationship', () {
      final photo = parentService.resolveParentPhotoFromWards(
        relationship: 'Guardian',
        wards: [mockWard],
      );
      expect(photo, 'https://images.unsplash.com/photo-guardian.jpg');
    });

    test('Explicit custom parent photo takes priority over ward photo', () {
      const customPhoto = 'https://custom-storage.com/my-photo.jpg';
      final photo = parentService.resolveParentPhotoFromWards(
        relationship: 'Father',
        wards: [mockWard],
        currentParentPhoto: customPhoto,
      );
      expect(photo, customPhoto);
    });

    test('Fallback to available parent photo if requested relation photo is null', () {
      final wardWithOnlyMother = ParentStudentWard(
        id: 'ward_2',
        name: 'Alex Johnson',
        regNo: 'RA2111003010001',
        department: 'Computer Science',
        yearSection: 'CSE • III Year',
        currentYear: 'III Year',
        currentSemester: 'VI Semester',
        photoUrl: 'https://images.unsplash.com/photo-student.jpg',
        fatherPhotoUrl: null,
        motherPhotoUrl: 'https://images.unsplash.com/photo-mother-only.jpg',
        guardianPhotoUrl: null,
        avatarInitials: 'AJ',
        attendancePercent: 0.90,
        presentCount: 90,
        absentCount: 10,
        leaveOdCount: 0,
        cgpa: '8.9',
        academicTrend: 'Upward',
        academicStatus: 'Distinction',
        statusColor: const Color(0xFF10B981),
        totalFees: 50000,
        paidFees: 50000,
        pendingFees: 0,
        feeDueDate: DateTime(2026, 6, 1),
        feeStatus: 'Cleared',
        todayStatus: 'Present',
        subjectGrades: [],
      );

      final photo = parentService.resolveParentPhotoFromWards(
        relationship: 'Father',
        wards: [wardWithOnlyMother],
      );
      expect(photo, 'https://images.unsplash.com/photo-mother-only.jpg');
    });
  });
}
