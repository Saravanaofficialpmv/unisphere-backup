import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/notification_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/repositories/notification_repository.dart';
import 'package:unisphere/services/notification_automation_rules_service.dart';
import 'package:unisphere/services/notification_duplicate_preventer.dart';
import 'package:unisphere/services/notification_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parent Real-Time Notification System Tests', () {
    test('1. Parent stream only returns notifications targeted to parent or ward', () {
      final allNotifications = [
        // 1. Parent fee reminder
        NotificationModel(
          id: 'notif-fee-parent',
          title: '💳 Semester VI Fee Due',
          message: 'Fee for Alex Johnson is due',
          type: 'automated',
          category: 'Finance',
          priority: 'high',
          recipientType: 'user',
          recipientUserIds: ['DEMO-PRT'],
          targetRoles: ['parent'],
          relatedModule: 'fee',
          createdAt: DateTime.now(),
          isRead: false,
        ),
        // 2. Parent attendance alert
        NotificationModel(
          id: 'notif-att-parent',
          title: '⚠️ Ward Low Attendance Notice',
          message: 'Attendance is 74.5%',
          type: 'automated',
          category: 'Attendance',
          priority: 'critical',
          recipientType: 'user',
          recipientUserIds: ['DEMO-PRT'],
          targetRoles: ['parent'],
          relatedModule: 'attendance',
          createdAt: DateTime.now(),
          isRead: false,
        ),
        // 3. Institutional Circular for Parents & Students
        NotificationModel(
          id: 'notif-circular-all',
          title: '📢 End-Semester PTM Schedule',
          message: 'PTM on Sept 5th',
          type: 'manual',
          category: 'Academic',
          priority: 'medium',
          recipientType: 'role',
          recipientUserIds: ['ALL'],
          targetRoles: ['parent', 'student'],
          relatedModule: 'exam',
          createdAt: DateTime.now(),
          isRead: true,
        ),
        // 4. STUDENT ONLY: Assignment reminder
        NotificationModel(
          id: 'notif-assign-student',
          title: '⏰ Socket Programming Due Tomorrow',
          message: 'Submit by 11:59 PM',
          type: 'automated',
          category: 'Academic',
          priority: 'high',
          recipientType: 'user',
          recipientUserIds: ['DEMO-STU'],
          targetRoles: ['student'],
          relatedModule: 'assignment',
          createdAt: DateTime.now(),
          isRead: false,
        ),
        // 5. STUDENT ONLY: Hackathon reminder
        NotificationModel(
          id: 'notif-hackathon-student',
          title: '🎯 Hackathon Check-in Tomorrow',
          message: 'Smart Campus Hackathon begins tomorrow',
          type: 'automated',
          category: 'Events',
          priority: 'medium',
          recipientType: 'user',
          recipientUserIds: ['DEMO-STU'],
          targetRoles: ['student'],
          relatedModule: 'hackathon',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];

      // Simulate repository filtering logic for Parent (DEMO-PRT)
      final parentFiltered = allNotifications.where((n) {
        final targetRolesLower = n.targetRoles.map((r) => r.toLowerCase().trim()).toList();
        final targetUserId = 'DEMO-PRT';
        final childStudentId = 'DEMO-STU';

        if (n.recipientUserIds.contains(targetUserId)) {
          return true;
        }
        if ((n.recipientUserIds.contains('PRT-$childStudentId') || n.recipientUserIds.contains(childStudentId) && targetRolesLower.contains('parent'))) {
          return true;
        }
        if (targetRolesLower.contains('parent')) {
          return true;
        }
        if (n.recipientUserIds.contains('ALL') && (targetRolesLower.isEmpty || targetRolesLower.contains('parent'))) {
          return true;
        }
        return false;
      }).toList();

      // Parent must receive notifications 1, 2, and 3
      expect(parentFiltered.length, 3);
      expect(parentFiltered.any((n) => n.id == 'notif-fee-parent'), isTrue);
      expect(parentFiltered.any((n) => n.id == 'notif-att-parent'), isTrue);
      expect(parentFiltered.any((n) => n.id == 'notif-circular-all'), isTrue);

      // Parent must NOT receive student-only notifications 4 and 5
      expect(parentFiltered.any((n) => n.id == 'notif-assign-student'), isFalse);
      expect(parentFiltered.any((n) => n.id == 'notif-hackathon-student'), isFalse);
    });

    test('2. NotificationNotifier initializes with parent-tailored items for parent user', () {
      final parentUser = UserModel(
        uid: 'DEMO-PRT',
        email: 'parent@unisphere.edu',
        name: 'Sarah Johnson',
        role: UserRole.parent,
        metadata: {
          'child_id': 'DEMO-STU',
          'student_name': 'Alex Johnson',
        },
      );

      final notifier = NotificationNotifier(NotificationRepository(), parentUser);
      final state = notifier.state;

      expect(state.items.isNotEmpty, isTrue);
      // All items must be parent related
      for (final item in state.items) {
        final roles = item.rawModel.targetRoles.map((r) => r.toLowerCase()).toList();
        final recipients = item.rawModel.recipientUserIds;
        final isParentTargeted = roles.contains('parent') || recipients.contains('DEMO-PRT') || recipients.contains('ALL');
        expect(isParentTargeted, isTrue, reason: 'Notification ${item.id} should be targeted to parent');
      }

      // Verify unread count calculation
      expect(state.unreadCount, state.items.where((i) => i.isUnread).length);
    });

    test('3. Marking parent notifications as read updates local state', () async {
      final parentUser = UserModel(
        uid: 'DEMO-PRT',
        email: 'parent@unisphere.edu',
        name: 'Sarah Johnson',
        role: UserRole.parent,
      );

      final notifier = NotificationNotifier(NotificationRepository(), parentUser);
      final initialUnread = notifier.state.unreadCount;
      expect(initialUnread > 0, isTrue);

      final firstUnreadId = notifier.state.items.firstWhere((i) => i.isUnread).id;
      await notifier.markAsRead(firstUnreadId);

      expect(notifier.state.items.firstWhere((i) => i.id == firstUnreadId).isUnread, isFalse);
      expect(notifier.state.unreadCount, initialUnread - 1);

      await notifier.markAllAsRead();
      expect(notifier.state.unreadCount, 0);
    });

    test('4. Automated Rule Engine dispatches parent and student fee notices independently', () async {
      final mockPreventer = NotificationDuplicatePreventer();
      final engine = NotificationEngine(duplicatePreventer: mockPreventer);

      final feeId = 'FEE-TEST-2026';
      // Dispatch for student
      final resStudent = await engine.dispatchAutomatedNotification(
        ruleId: 'rule_fee_due_student',
        recipientUserId: 'DEMO-STU',
        eventId: feeId,
        title: '💳 Tuition Fee Due',
        message: 'Your fee is due',
        category: 'Finance',
        priority: 'high',
        targetRoles: ['student'],
        relatedModule: 'fee',
      );
      expect(resStudent.decision, NotificationDecision.dispatch);
      expect(resStudent.deduplicationKey, 'rule_fee_due_student_DEMO-STU_$feeId');

      // Dispatch for parent independently
      final resParent = await engine.dispatchAutomatedNotification(
        ruleId: 'rule_fee_due_parent',
        recipientUserId: 'DEMO-PRT',
        eventId: feeId,
        title: '💳 Fee Payment Reminder for Ward',
        message: 'Fee for Alex Johnson is due',
        category: 'Finance',
        priority: 'high',
        targetRoles: ['parent'],
        relatedModule: 'fee',
      );
      expect(resParent.decision, NotificationDecision.dispatch);
      expect(resParent.deduplicationKey, 'rule_fee_due_parent_DEMO-PRT_$feeId');

      // Re-dispatching parent fee notice within cooldown is suppressed
      final resParentDupe = await engine.dispatchAutomatedNotification(
        ruleId: 'rule_fee_due_parent',
        recipientUserId: 'DEMO-PRT',
        eventId: feeId,
        title: '💳 Fee Payment Reminder for Ward',
        message: 'Fee for Alex Johnson is due',
        category: 'Finance',
        priority: 'high',
        targetRoles: ['parent'],
        relatedModule: 'fee',
      );
      expect(resParentDupe.decision, NotificationDecision.suppressDuplicate);
    });
  });
}
