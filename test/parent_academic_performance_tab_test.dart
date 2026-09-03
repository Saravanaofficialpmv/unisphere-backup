import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:unisphere/screens/parent/parent_dashboard.dart';

void main() {
  group('ParentAcademicPerformanceTab Layout & Overflow Tests', () {
    final mockWard = ParentStudentWard(
      id: 'ward_1',
      name: 'Arun Kumar',
      regNo: '23CSE1042',
      department: 'Computer Science & Engineering',
      yearSection: 'CSE • III Year',
      currentYear: 'III Year',
      currentSemester: 'Semester 4',
      photoUrl: '',
      avatarInitials: 'AK',
      attendancePercent: 0.92,
      presentCount: 92,
      absentCount: 8,
      leaveOdCount: 0,
      cgpa: '8.78',
      academicTrend: 'Upward',
      academicStatus: 'First Class with Distinction',
      statusColor: const Color(0xFF10B981),
      totalFees: 50000,
      paidFees: 50000,
      pendingFees: 0,
      feeDueDate: DateTime(2026, 6, 1),
      feeStatus: 'Cleared',
      todayStatus: 'Present',
      subjectGrades: [],
    );

    testWidgets('Renders cleanly on narrow 360px mobile width without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ParentAcademicPerformanceTab(
              selectedWard: mockWard,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Academic Performance & Progress'), findsOneWidget);
      expect(find.text('8.78'), findsOneWidget);
      expect(find.text('First Class with Distinction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on very narrow 320px mobile width without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ParentAcademicPerformanceTab(
              selectedWard: mockWard,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('8.78'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
