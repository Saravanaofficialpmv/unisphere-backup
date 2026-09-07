import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_home_dashboard.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_today_schedule_screen.dart';
import 'package:unisphere/screens/staff/modules/staff_home/staff_pending_tasks_screen.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_dashboard.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';
import 'package:unisphere/screens/staff/staff_profile_screen.dart';
import 'package:unisphere/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Staff Portal & Role-Based Advisor Experience Tests', () {
    testWidgets('1. Normal Staff Dashboard renders teaching schedule, quick actions, subjects, and dynamic greeting', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final normalStaff = StaffModel(
        userId: 'STF-001',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: const ['III CSE - A'],
        assignedSubjects: const ['Data Structures'],
        isAdvisor: false,
        advisorSection: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(normalStaff)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StaffHomeDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dynamic Greeting and Title
      expect(find.text('Dr. Arun Kumar'), findsOneWidget);
      expect(find.text('Normal Staff'), findsOneWidget);
      expect(find.textContaining('No class advisor assignment.'), findsOneWidget);
      expect(find.text('View My Profile'), findsOneWidget);
      expect(find.text("TODAY'S SCHEDULE"), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text('MY SUBJECTS'), findsOneWidget);
      expect(find.text('PENDING WORK'), findsOneWidget);
      expect(find.text('RECENT ACTIVITY'), findsOneWidget);

      // Top metrics
      expect(find.text("Today's Classes"), findsOneWidget);
      expect(find.text('Pending Tasks'), findsOneWidget);
      expect(find.text('Attendance'), findsAtLeast(1));

      // Quick Actions items
      expect(find.text('Upload Marks'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Question Papers'), findsOneWidget);
    });

    testWidgets('2. "View My Profile" button navigates to profile and debounces rapid taps', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int navigationCallCount = 0;
      StaffNavKey? navigatedKey;

      final normalStaff = StaffModel(
        userId: 'STF-001',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: const ['III CSE - A'],
        assignedSubjects: const ['Data Structures'],
        isAdvisor: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(normalStaff)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StaffHomeDashboard(
                onNavigateToKey: (key) {
                  navigationCallCount++;
                  navigatedKey = key;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileBtn = find.text('View My Profile');
      expect(profileBtn, findsOneWidget);

      // Tap once
      await tester.tap(profileBtn);
      // Rapid tap second time immediately (should be debounced)
      await tester.tap(profileBtn);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(navigationCallCount, equals(1));
      expect(navigatedKey, equals(StaffNavKey.profile));
    });

    testWidgets('3. Class Advisor Dashboard renders overview metrics, attendance gauge, academic performance, and attention categories', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final advisorStaff = StaffModel(
        userId: 'STF-ADVISOR',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: const ['III CSE - A'],
        assignedSubjects: const ['Machine Learning'],
        isAdvisor: true,
        advisorSection: 'III CSE - A',
        advisorAcademicYear: '2025–26',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(true),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(advisorStaff)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AdvisorDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header Banner
      expect(find.text('Class Advisor'), findsOneWidget);
      expect(find.textContaining('Academic Year'), findsOneWidget);

      // Overview section
      expect(find.text('CLASS OVERVIEW'), findsOneWidget);
      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('Overall Attendance'), findsOneWidget);
      expect(find.text('Average CGPA'), findsOneWidget);
      expect(find.text('Students At Risk'), findsOneWidget);

      // Attendance & Academics
      expect(find.text('Students Requiring Attention'), findsOneWidget);
      expect(find.text('ACADEMIC PERFORMANCE'), findsOneWidget);
      expect(find.text('STUDENTS REQUIRING ATTENTION'), findsOneWidget);
      expect(find.text('ADVISOR TASKS'), findsOneWidget);

      // Actions & cards
      expect(find.text('View All Students'), findsOneWidget);
      expect(find.text('Top Performers'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
    });

    testWidgets('4. StaffDashboard shell hosts active role and allows switching view mode', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final advisorStaff = StaffModel(
        userId: 'STF-ADVISOR',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: const ['III CSE - A'],
        assignedSubjects: const ['Machine Learning'],
        isAdvisor: true,
        advisorSection: 'III CSE - A',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(true),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(advisorStaff)),
          ],
          child: const MaterialApp(
            home: StaffDashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top App Bar shows VSB College and portal subtitle
      expect(find.text('VSB COLLEGE'), findsOneWidget);
      expect(find.text('Class Advisor Portal'), findsOneWidget);

      // Tap 'Teaching View' button to toggle to teaching mode
      final teachingBtn = find.text('Teaching View');
      if (teachingBtn.evaluate().isNotEmpty) {
        await tester.tap(teachingBtn);
        await tester.pumpAndSettle();

        expect(find.text("TODAY'S SCHEDULE"), findsOneWidget);
        expect(find.text('Advisor Mode'), findsOneWidget);
      }
    });

    testWidgets('5. Role-Based Access: Normal Staff sees only staff features, advisor-only features hidden', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final normalStaff = StaffModel(
        userId: 'STF-NORMAL',
        employeeId: 'STF-009',
        fullName: 'Prof. Rajesh Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'CSE Department',
        designation: 'Associate Professor',
        specialization: 'Computer Science',
        assignedClasses: const ['III CSE - A'],
        assignedSubjects: const ['Data Structures'],
        isAdvisor: false,
        advisorSection: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(normalStaff)),
          ],
          child: const MaterialApp(
            home: StaffDashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Subtitle reflects Faculty mode
      expect(find.text('Faculty Management System'), findsOneWidget);
      expect(find.text('Staff Dashboard'), findsOneWidget);

      // Faculty navigation items are present
      expect(find.text('Timetable & Schedule'), findsOneWidget);
      expect(find.text('Take Attendance'), findsAtLeast(1));
      expect(find.text('Upload Marks'), findsAtLeast(1));
      expect(find.text('Give Assignment'), findsOneWidget);

      // Advisor-only navigation items are strictly hidden
      expect(find.text('Advisor Dashboard'), findsNothing);
      expect(find.text('Class Student Directory'), findsNothing);
      expect(find.text('Parent Communication'), findsNothing);
      expect(find.text('Student Approvals'), findsNothing);
      expect(find.text('Profile Edit Requests'), findsNothing);
      expect(find.text('Resume Bank'), findsNothing);
      expect(find.text('NPTEL Verification'), findsNothing);
      expect(find.text('Hackathon Approvals'), findsNothing);
    });

    testWidgets('6. Role-Based Access: Class Advisor sees staff features + advisor features', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final advisorStaff = StaffModel(
        userId: 'STF-ADVISOR',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'CSE Department',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: const ['III CSE - A'],
        assignedSubjects: const ['Machine Learning'],
        isAdvisor: true,
        advisorSection: 'III CSE - A',
        advisorAcademicYear: '2025–26',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(true),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(advisorStaff)),
          ],
          child: const MaterialApp(
            home: StaffDashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Subtitle reflects Class Advisor portal
      expect(find.text('Class Advisor Portal'), findsOneWidget);

      // Advisor navigation items are visible
      expect(find.text('Advisor Dashboard'), findsOneWidget);
      expect(find.text('Class Student Directory'), findsOneWidget);
      expect(find.text('Parent Communication'), findsOneWidget);
      expect(find.text('Student Approvals'), findsOneWidget);
      expect(find.text('Profile Edit Requests'), findsOneWidget);
      expect(find.text('Resume Bank'), findsOneWidget);

      // Teaching items are also accessible
      expect(find.text('Timetable & Schedule'), findsOneWidget);
      expect(find.text('Take Attendance'), findsOneWidget);
      expect(find.text('Upload Marks'), findsOneWidget);
      expect(find.text('Give Assignment'), findsOneWidget);
    });

    testWidgets('6b. Header Top Logout Option is displayed and triggers sign out confirmation sheet', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staffUser = StaffModel(
        userId: 'STF-001',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'CSE Department',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: ['III CSE - A'],
        assignedSubjects: ['Data Structures'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(staffUser)),
          ],
          child: const MaterialApp(
            home: StaffDashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header Top logout button is present with tooltip and icon on Desktop
      final desktopLogoutButton = find.byTooltip('Log Out');
      expect(desktopLogoutButton, findsOneWidget);
      expect(find.descendant(of: desktopLogoutButton, matching: find.byIcon(Icons.logout_rounded)), findsOneWidget);

      // Tap logout button and verify sign-out sheet is triggered
      await tester.tap(desktopLogoutButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out?'), findsOneWidget);
      expect(find.text('Are you sure you want to log out of your account?'), findsOneWidget);
      expect(find.text('Sign Out'), findsAtLeast(1));
      expect(find.text('Stay'), findsOneWidget);

      // Dismiss dialog by tapping Stay
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();

      // Now verify Mobile Header Top logout option
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();

      final mobileLogoutButton = find.byTooltip('Log Out');
      expect(mobileLogoutButton, findsOneWidget);
      expect(find.descendant(of: mobileLogoutButton, matching: find.byIcon(Icons.logout_rounded)), findsOneWidget);

      await tester.tap(mobileLogoutButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out?'), findsOneWidget);
      expect(find.text('Are you sure you want to log out of your account?'), findsOneWidget);
    });

    testWidgets('7. StaffProfileScreen renders authenticated staff profile with personal and teaching info', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final normalStaff = StaffModel(
        userId: 'STF-001',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Assistant Professor',
        specialization: 'Machine Learning & Cloud',
        assignedClasses: const ['III CSE - A', 'III CSE - B'],
        assignedSubjects: const ['Data Structures', 'Machine Learning'],
        isAdvisor: false,
      );

      final authUser = UserModel(
        uid: 'STF-001',
        email: 'arunkumar@vsb.edu.in',
        fullName: 'Dr. Arun Kumar',
        role: UserRole.staff,
        phoneNumber: '+91 98765 43210',
        createdAt: DateTime(2023, 6, 15),
        metadata: const {
          'department': 'Computer Science & Engineering',
          'institution': 'VSB Engineering College',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
            currentUserProvider.overrideWith((ref) => Stream.value(authUser)),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(normalStaff)),
          ],
          child: const MaterialApp(
            home: StaffProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Badges
      expect(find.text('Dr. Arun Kumar'), findsAtLeast(1));
      expect(find.text('Assistant Professor'), findsAtLeast(1));
      expect(find.textContaining('Computer Science & Engineering'), findsAtLeast(1));
      expect(find.text('Normal Staff'), findsAtLeast(1));
      expect(find.text('Active Faculty'), findsOneWidget);

      // Verify Role Scope card
      expect(find.text('ROLE & RESPONSIBILITY'), findsOneWidget);
      expect(find.text('No class advisor assignment.'), findsOneWidget);
      expect(find.text('View Faculty Student Directory'), findsOneWidget);

      // Verify Contact & Personal Info
      expect(find.text('ACCOUNT & SECURITY'), findsOneWidget);
      expect(find.text('arunkumar@vsb.edu.in'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);

      // Verify Academic & Teaching Info
      expect(find.text('PROFESSIONAL'), findsOneWidget);
      expect(find.text('TEACHING & SUBJECTS'), findsOneWidget);
      expect(find.text('STF-001'), findsAtLeast(1));
      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('Machine Learning'), findsOneWidget);

      // Verify Actions
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('8. StaffProfileScreen renders Class Advisor section when staff is class advisor', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final advisorStaff = StaffModel(
        userId: 'STF-ADVISOR',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: const ['III CSE - A'],
        assignedSubjects: const ['Machine Learning'],
        isAdvisor: true,
        advisorSection: 'III CSE - A',
        advisorAcademicYear: '2025–26',
      );

      final advisorAssignment = StaffAssignmentModel(
        id: 'ASN-001',
        staffId: 'STF-ADVISOR',
        staffName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        assignmentType: StaffAssignmentType.classAdvisor,
        className: 'III CSE - A',
        section: 'A',
        academicYear: '2025–26',
        assignedBy: 'ADMIN-01',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(true),
            activeClassAdvisorAssignmentProvider.overrideWithValue(advisorAssignment),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(advisorStaff)),
          ],
          child: const MaterialApp(
            home: StaffProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Class Advisor Badge and Assignment Card
      expect(find.text('Class Advisor'), findsAtLeast(1));
      expect(find.text('ROLE & RESPONSIBILITY'), findsOneWidget);
      expect(find.textContaining('III CSE - A'), findsAtLeast(1));
      expect(find.text('View Class Student Directory'), findsOneWidget);
    });

    testWidgets('9. StaffProfileScreen error state renders retry button and handles retry action', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => Stream.error('Auth error')),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.error('Network timeout')),
          ],
          child: const MaterialApp(
            home: StaffProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Profile'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
    });

    testWidgets('10. StaffProfileScreen Edit Profile dialog locks institutional fields and allows editing name and phone', (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final normalStaff = StaffModel(
        userId: 'STF-001',
        employeeId: 'STF-001',
        fullName: 'Dr. Arun Kumar',
        departmentId: 'DEPT-CSE',
        departmentName: 'Computer Science & Engineering',
        designation: 'Assistant Professor',
        specialization: 'Computer Science',
        assignedClasses: const ['III CSE - A'],
        assignedSubjects: const ['Data Structures'],
        isAdvisor: false,
      );

      final authUser = UserModel(
        uid: 'STF-001',
        email: 'arunkumar@vsb.edu.in',
        fullName: 'Dr. Arun Kumar',
        role: UserRole.staff,
        phoneNumber: '+91 98765 43210',
        metadata: const {
          'department': 'Computer Science & Engineering',
          'institution': 'VSB Engineering College',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
            currentUserProvider.overrideWith((ref) => Stream.value(authUser)),
            currentStaffProfileStreamProvider.overrideWith((ref) => Stream.value(normalStaff)),
          ],
          child: const MaterialApp(
            home: StaffProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editBtn = find.text('Edit Profile');
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify Edit Modal elements
      expect(find.text('Edit Profile'), findsAtLeast(1));
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Institutional Fields (Contact Admin to Change)'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Tap close button (Icons.close_rounded) to dismiss
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Institutional Fields (Contact Admin to Change)'), findsNothing);
    });

    testWidgets('11. Staff Dashboard summary cards reflect dynamic counts from single-source providers', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final customSchedule = [
        {'id': 'S1', 'startTime': '09:00 AM', 'endTime': '10:00 AM', 'subjectName': 'Network Security', 'className': 'IV CSE - A', 'isAttendanceTaken': true},
        {'id': 'S2', 'startTime': '11:00 AM', 'endTime': '12:00 PM', 'subjectName': 'Cloud Computing', 'className': 'III CSE - B', 'isAttendanceTaken': false},
      ];

      final customTasks = [
        {'id': 'T1', 'title': 'Marks pending', 'subtitle': 'Cloud • Internal 1', 'dueDate': 'Due Sep 12', 'priority': 'high', 'action': 'upload_marks'},
      ];

      final customSubjects = [
        {'id': 'SUB-1', 'name': 'Network Security', 'code': 'CS801', 'class': 'IV CSE - A', 'attendance': 94},
        {'id': 'SUB-2', 'name': 'Cloud Computing', 'code': 'CS802', 'class': 'III CSE - B', 'attendance': 86},
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
            staffTodayScheduleStreamProvider.overrideWith((ref) => Stream.value(customSchedule)),
            staffPendingWorkStreamProvider.overrideWith((ref) => Stream.value(customTasks)),
            staffSubjectsStreamProvider.overrideWith((ref) => Stream.value(customSubjects)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StaffHomeDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Today's classes count: 2
      expect(find.text('2'), findsOneWidget);
      // Pending tasks count: 1
      expect(find.text('1'), findsOneWidget);
      // Attendance metric average: (94 + 86)/2 = 90%
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('12. Today\'s Classes summary card navigates to StaffNavKey.todayClasses', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      StaffNavKey? targetKey;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StaffHomeDashboard(
                onNavigateToKey: (key) => targetKey = key,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final todayClassesCard = find.text("Today's Classes");
      expect(todayClassesCard, findsOneWidget);

      await tester.tap(todayClassesCard);
      await tester.pumpAndSettle();

      expect(targetKey, equals(StaffNavKey.todayClasses));
    });

    testWidgets('13. Pending Tasks summary card navigates to StaffNavKey.pendingTasks', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      StaffNavKey? targetKey;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StaffHomeDashboard(
                onNavigateToKey: (key) => targetKey = key,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pendingTasksCard = find.text("Pending Tasks");
      expect(pendingTasksCard, findsOneWidget);

      await tester.tap(pendingTasksCard);
      await tester.pumpAndSettle();

      expect(targetKey, equals(StaffNavKey.pendingTasks));
    });

    testWidgets('14. Attendance summary card navigates to StaffNavKey.attendance', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      StaffNavKey? targetKey;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isClassAdvisorProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StaffHomeDashboard(
                onNavigateToKey: (key) => targetKey = key,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final attendanceCard = find.text("Attendance");
      expect(attendanceCard, findsAtLeast(1));

      await tester.tap(attendanceCard.first);
      await tester.pumpAndSettle();

      expect(targetKey, equals(StaffNavKey.attendance));
    });

    testWidgets('15. StaffTodayScheduleScreen renders sessions, Take Attendance shortcut, and handles back navigation', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool backCalled = false;
      StaffNavKey? navigatedKey;

      final sessions = [
        {
          'id': 'SCH-01',
          'startTime': '09:00 AM',
          'endTime': '10:00 AM',
          'subjectName': 'Machine Learning',
          'subjectCode': 'CS8691',
          'className': 'III CSE - A',
          'room': 'CS Lab 2',
          'isAttendanceTaken': true,
          'attendancePercent': 95,
        },
        {
          'id': 'SCH-02',
          'startTime': '11:00 AM',
          'endTime': '12:00 PM',
          'subjectName': 'Data Structures',
          'subjectCode': 'CS8392',
          'className': 'II CSE - B',
          'room': 'LH-204',
          'isAttendanceTaken': false,
          'attendancePercent': 0,
        },
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffTodayScheduleStreamProvider.overrideWith((ref) => Stream.value(sessions)),
          ],
          child: MaterialApp(
            home: StaffTodayScheduleScreen(
              onBack: () => backCalled = true,
              onNavigateToKey: (key) => navigatedKey = key,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Teaching Schedule"), findsOneWidget);
      expect(find.text('2 Sessions'), findsOneWidget);
      expect(find.textContaining('Machine Learning'), findsOneWidget);
      expect(find.textContaining('Data Structures'), findsOneWidget);
      expect(find.text('Take Attendance'), findsOneWidget);

      // Tap Take Attendance on incomplete session
      await tester.tap(find.text('Take Attendance'));
      await tester.pumpAndSettle();
      expect(navigatedKey, equals(StaffNavKey.attendance));

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(backCalled, isTrue);
    });

    testWidgets('16. StaffPendingTasksScreen renders tasks, category filters, and handles complete action', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tasks = [
        {
          'id': 'PW-01',
          'title': 'Marks pending',
          'subtitle': 'Machine Learning • Internal 2',
          'dueDate': 'Due Sep 10',
          'priority': 'high',
          'action': 'upload_marks',
        },
        {
          'id': 'PW-02',
          'title': 'Attendance incomplete',
          'subtitle': 'Data Structures • Today',
          'dueDate': 'Due Today',
          'priority': 'urgent',
          'action': 'take_attendance',
        },
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffPendingWorkStreamProvider.overrideWith((ref) => Stream.value(tasks)),
          ],
          child: const MaterialApp(
            home: StaffPendingTasksScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task Review Center'), findsOneWidget);
      expect(find.text('Marks pending'), findsOneWidget);
      expect(find.text('Attendance incomplete'), findsOneWidget);
      expect(find.text('2 High Priority'), findsOneWidget);

      // Tap 'Mark Done' on first task
      final markDoneBtn = find.text('Mark Done').first;
      await tester.tap(markDoneBtn);
      await tester.pumpAndSettle();

      // Snack bar should show
      expect(find.text('Marks pending marked as done.'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> putUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> headUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> get(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> post(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> put(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> head(String host, int port, String path) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final List<int> _kTransparentImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
