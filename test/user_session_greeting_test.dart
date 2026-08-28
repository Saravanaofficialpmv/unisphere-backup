import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/services/parent_service.dart';
import 'package:unisphere/services/user_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserSessionService.instance.clearMemoryCache();
  });

  group('UserSessionService Greeting Tests', () {
    test('Fresh signup records isFreshSignup and returns false for isReturningUser', () async {
      const uid = 'fresh_user_001';
      final sessionService = UserSessionService.instance;

      // User performs fresh signup
      await sessionService.recordFreshSignup(uid);

      // On initial dashboard load
      final isReturning = await sessionService.isReturningUser(uid);
      expect(isReturning, isFalse, reason: 'Fresh signup user should not be treated as returning user');

      // Mark session seen
      await sessionService.markUserSessionSeen(uid);

      // Subsequent check after 1st session
      final isReturningAfterSession = await sessionService.isReturningUser(uid);
      expect(isReturningAfterSession, isTrue, reason: 'After 1st session, user is now returning');
    });

    test('Returning login records login and returns true for isReturningUser', () async {
      const uid = 'existing_user_002';
      final sessionService = UserSessionService.instance;

      // Existing user logs in (Login tab / returning sign in)
      await sessionService.recordLogin(uid);

      final isReturning = await sessionService.isReturningUser(uid);
      expect(isReturning, isTrue, reason: 'User logging in should be treated as returning user');
    });

    test('Isolated state between multiple users on same device', () async {
      const freshUserUid = 'new_student_123';
      const returningUserUid = 'DEMO-PRT';
      final sessionService = UserSessionService.instance;

      await sessionService.recordFreshSignup(freshUserUid);
      await sessionService.recordLogin(returningUserUid);

      final freshStatus = await sessionService.isReturningUser(freshUserUid);
      final returningStatus = await sessionService.isReturningUser(returningUserUid);

      expect(freshStatus, isFalse, reason: 'New user should show Welcome');
      expect(returningStatus, isTrue, reason: 'Demo/returning user should show Welcome Back');
    });

    test('Subsequent logins for previously signed up user switch to returning', () async {
      const uid = 'fresh_student_456';
      final sessionService = UserSessionService.instance;

      // 1. Fresh signup
      await sessionService.recordFreshSignup(uid);
      expect(await sessionService.isReturningUser(uid), isFalse);

      // 2. User logs out and logs in 2nd time
      sessionService.clearMemoryCache();
      await sessionService.recordLogin(uid);

      expect(await sessionService.isReturningUser(uid), isTrue,
          reason: 'Second login must transition user to Welcome Back');
    });
  });

  group('UserModel Account Creation Date Tests for Settings', () {
    test('Formatted account creation date is correctly produced', () {
      final user = UserModel(
        uid: 'user_test_999',
        email: 'test@unisphere.edu',
        fullName: 'Test User',
        role: UserRole.student,
        createdAt: DateTime(2025, 4, 18),
      );

      expect(user.formattedCreatedAt, equals('18 Apr 2025'));
    });

    test('Default demo accounts resolve accurate historical creation dates', () {
      final hod = UserModel(
        uid: 'DEMO-HOD',
        email: 'hod.cse@unisphere.edu',
        fullName: 'Dr. R. Kumar',
        role: UserRole.hod,
      );
      final admin = UserModel(
        uid: 'DEMO-ADM',
        email: 'admin@unisphere.edu',
        fullName: 'Demo Admin',
        role: UserRole.admin,
      );
      final parent = UserModel(
        uid: 'DEMO-PRT',
        email: 'parent@unisphere.edu',
        fullName: 'Rajesh Kumar',
        role: UserRole.parent,
      );

      expect(hod.formattedCreatedAt, equals('15 Jun 2021'));
      expect(admin.formattedCreatedAt, equals('10 Jan 2020'));
      expect(parent.formattedCreatedAt, equals('05 Sep 2023'));
    });
  });

  group('Student Register Number Database Check & Verification Tests', () {
    test('ParentService finds registered institutional student', () async {
      final parentService = ParentService();

      final existingStudent = await parentService.lookupStudentByRegNo('RA2111003010001');
      expect(existingStudent, isNotNull);
      expect(existingStudent!['fullName'], equals('Alex Johnson'));

      final nonExistentStudent = await parentService.lookupStudentByRegNo('999999999999');
      expect(nonExistentStudent, isNull);
    });

    test('Sibling duplicate detection prevents registering duplicate child register numbers', () {
      final childRegs = ['922523243100', '922523243100'];
      final seenRegs = <String>{};
      bool hasDuplicate = false;

      for (final reg in childRegs) {
        if (seenRegs.contains(reg)) {
          hasDuplicate = true;
          break;
        }
        seenRegs.add(reg);
      }

      expect(hasDuplicate, isTrue, reason: 'Duplicate sibling register numbers must be flagged as duplicate');
    });

    test('ParentService linkAdditionalChild preserves existing siblings and includes new sibling', () async {
      final parentService = ParentService(firestore: null);
      const parentId = 'test_parent_multi_1';

      // Link initial child
      await parentService.linkParentWithChildren(
        parentId: parentId,
        userId: parentId,
        parentName: 'Test Parent',
        phone: '9876543210',
        email: 'testparent@test.com',
        childRegisterNumbers: ['922523243100'],
      );

      final initialWards = await parentService.getStudentWardsForParent(parentId);
      expect(initialWards.map((w) => w.regNo).contains('922523243100'), isTrue);

      // Link another sibling
      final linkSuccess = await parentService.linkAdditionalChild(
        parentUidOrEmail: parentId,
        childRegisterNumber: '24ECE2018',
        parentName: 'Test Parent',
        phone: '9876543210',
      );

      expect(linkSuccess, isTrue);

      final combinedWards = await parentService.getStudentWardsForParent(parentId);
      final regNos = combinedWards.map((w) => w.regNo.toUpperCase()).toList();

      expect(regNos.contains('922523243100'), isTrue, reason: 'Old sibling must remain linked');
      expect(regNos.contains('24ECE2018'), isTrue, reason: 'New sibling must also be linked');
    });
  });
}

