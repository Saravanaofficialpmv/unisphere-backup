import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere/models/notification_model.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/widgets/common/recent_updates_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecentUpdatesCard Widget Tests', () {
    testWidgets('1. Renders Header with title, bolt icon, and View All action', (WidgetTester tester) async {
      bool viewAllTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RecentUpdatesCard(
                onViewAll: () => viewAllTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title and View All
      expect(find.text('Recent Updates'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      // Tap View All
      await tester.tap(find.text('View All'));
      expect(viewAllTapped, isTrue);
    });

    testWidgets('2. Renders live items with category squircles, category tags, and glowing unread dots', (WidgetTester tester) async {
      final sampleItems = [
        NotificationItem(
          rawModel: NotificationModel(
            id: 'n1',
            title: '💳 Fee Payment Reminder for Ward',
            message: 'Semester VI fees pending',
            type: 'automated',
            category: 'Finance',
            priority: 'high',
            recipientType: 'user',
            recipientUserIds: ['DEMO-PRT'],
            targetRoles: ['parent'],
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            isRead: false,
          ),
          id: 'n1',
          title: '💳 Fee Payment Reminder for Ward',
          category: 'Finance',
          priority: 'high',
          type: 'automated',
          timeAgo: '1h ago',
          summary: 'Semester VI fees pending',
          fullDetails: 'Semester VI fees pending',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFEF3C7),
          badgeText: '⚠️ HIGH',
          badgeColor: const Color(0xFFF59E0B),
          badgeTextColor: Colors.white,
          isUnread: true,
        ),
        NotificationItem(
          rawModel: NotificationModel(
            id: 'n2',
            title: '⚠️ Parent Notice: Student Low Attendance',
            message: 'Attendance below 75%',
            type: 'automated',
            category: 'Attendance',
            priority: 'critical',
            recipientType: 'user',
            recipientUserIds: ['DEMO-PRT'],
            targetRoles: ['parent'],
            createdAt: DateTime.now().subtract(const Duration(hours: 8)),
            isRead: true,
          ),
          id: 'n2',
          title: '⚠️ Parent Notice: Student Low Attendance',
          category: 'Attendance',
          priority: 'critical',
          type: 'automated',
          timeAgo: '8h ago',
          summary: 'Attendance below 75%',
          fullDetails: 'Attendance below 75%',
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
          badgeText: '🚨 CRITICAL',
          badgeColor: const Color(0xFFEF4444),
          badgeTextColor: Colors.white,
          isUnread: false,
        ),
      ];

      NotificationItem? tappedItem;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationProvider.overrideWith((ref) => _MockNotificationNotifier(
                  NotificationState(
                    items: sampleItems,
                    selectedCategory: 'All',
                    searchQuery: '',
                  ),
                )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RecentUpdatesCard(
                onItemTap: (item) => tappedItem = item,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check unread badge
      expect(find.text('1 NEW'), findsOneWidget);

      // Check items rendered
      expect(find.text('💳 Fee Payment Reminder for Ward'), findsOneWidget);
      expect(find.text('⚠️ Parent Notice: Student Low Attendance'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('1h ago'), findsOneWidget);
      expect(find.text('8h ago'), findsOneWidget);

      // Tap item 1
      await tester.tap(find.text('💳 Fee Payment Reminder for Ward'));
      expect(tappedItem?.id, 'n1');
    });

    testWidgets('3. Renders fallback states when notifications list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationProvider.overrideWith((ref) => _MockNotificationNotifier(
                  NotificationState(
                    items: const [],
                    selectedCategory: 'All',
                    searchQuery: '',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RecentUpdatesCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check fallback content
      expect(find.text('Internal assessment marks published'), findsOneWidget);
      expect(find.text('End semester exam timetable updated'), findsOneWidget);
    });
  });
}

class _MockNotificationNotifier extends StateNotifier<NotificationState> implements NotificationNotifier {
  _MockNotificationNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
