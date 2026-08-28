import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/models/notification_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/repositories/notification_repository.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/notification_scheduler_service.dart';

// Provider for starting and managing background notification scheduler
final notificationSchedulerProvider = Provider<NotificationSchedulerService>((ref) {
  final scheduler = NotificationSchedulerService();
  scheduler.startScheduler();
  ref.onDispose(() => scheduler.stopScheduler());
  return scheduler;
});

class NotificationItem {
  final NotificationModel rawModel;
  final String id;
  final String title;
  final String category; // 'All', 'Academic', 'Attendance', 'Finance', 'Career', 'Events', 'System', 'Approvals'
  final String priority; // 'critical', 'high', 'medium', 'low'
  final String type; // 'automated' | 'manual'
  final String timeAgo;
  final String summary;
  final String fullDetails;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final bool isUnread;
  final String? featureId;
  final Map<String, String>? metadata;

  NotificationItem({
    required this.rawModel,
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.type,
    required this.timeAgo,
    required this.summary,
    required this.fullDetails,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    this.isUnread = true,
    this.featureId,
    this.metadata,
  });

  factory NotificationItem.fromModel(NotificationModel model) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (model.category.toLowerCase()) {
      case 'attendance':
        icon = Icons.calendar_month_rounded;
        iconColor = const Color(0xFFDC2626);
        iconBgColor = const Color(0xFFFEE2E2);
        break;
      case 'academic':
        icon = Icons.school_rounded;
        iconColor = const Color(0xFF2563EB);
        iconBgColor = const Color(0xFFDBEAFE);
        break;
      case 'finance':
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFFD97706);
        iconBgColor = const Color(0xFFFEF3C7);
        break;
      case 'career':
      case 'placement':
        icon = Icons.work_rounded;
        iconColor = const Color(0xFF059669);
        iconBgColor = const Color(0xFFD1FAE5);
        break;
      case 'events':
      case 'hackathon':
        icon = Icons.emoji_events_rounded;
        iconColor = const Color(0xFF7C3AED);
        iconBgColor = const Color(0xFFEDE9FE);
        break;
      case 'system':
        icon = Icons.security_rounded;
        iconColor = const Color(0xFF475569);
        iconBgColor = const Color(0xFFF1F5F9);
        break;
      default:
        icon = Icons.notifications_active_rounded;
        iconColor = const Color(0xFF4F46E5);
        iconBgColor = const Color(0xFFEEF2FF);
    }

    // Priority badge style
    String badgeText = model.priority.toUpperCase();
    Color badgeColor = const Color(0xFF94A3B8);
    Color badgeTextColor = Colors.white;

    if (model.priority == 'critical') {
      badgeColor = const Color(0xFFEF4444);
      badgeText = '🚨 CRITICAL';
    } else if (model.priority == 'high') {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = '⚠️ HIGH';
    } else if (model.priority == 'medium') {
      badgeColor = const Color(0xFF3B82F6);
      badgeText = 'INFO';
    } else {
      badgeColor = const Color(0xFF6B7280);
      badgeText = 'NOTICE';
    }

    final diff = DateTime.now().difference(model.createdAt);
    String timeAgoStr;
    if (diff.inMinutes < 1) {
      timeAgoStr = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgoStr = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgoStr = '${diff.inHours}h ago';
    } else {
      timeAgoStr = DateFormat('MMM d, h:mm a').format(model.createdAt);
    }

    return NotificationItem(
      rawModel: model,
      id: model.id,
      title: model.title,
      category: _normalizeCategory(model.category),
      priority: model.priority,
      type: model.type,
      timeAgo: timeAgoStr,
      summary: model.message,
      fullDetails: model.message,
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      badgeText: badgeText,
      badgeColor: badgeColor,
      badgeTextColor: badgeTextColor,
      isUnread: !model.isRead,
      featureId: model.relatedModule,
      metadata: {
        'related_module': model.relatedModule ?? '',
        'related_record_id': model.relatedRecordId ?? '',
        'sender_name': model.senderName ?? 'System',
        'type': model.type,
      },
    );
  }

  static String _normalizeCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('att')) return 'Attendance';
    if (c.contains('acad') || c.contains('exam') || c.contains('assign')) return 'Academic';
    if (c.contains('fin') || c.contains('fee')) return 'Finance';
    if (c.contains('car') || c.contains('place')) return 'Career';
    if (c.contains('event') || c.contains('hack')) return 'Events';
    if (c.contains('sys') || c.contains('sec')) return 'System';
    return 'General';
  }

  NotificationItem copyWith({bool? isUnread}) {
    return NotificationItem(
      rawModel: rawModel.copyWith(isRead: !(isUnread ?? this.isUnread)),
      id: id,
      title: title,
      category: category,
      priority: priority,
      type: type,
      timeAgo: timeAgo,
      summary: summary,
      fullDetails: fullDetails,
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      badgeText: badgeText,
      badgeColor: badgeColor,
      badgeTextColor: badgeTextColor,
      isUnread: isUnread ?? this.isUnread,
      featureId: featureId,
      metadata: metadata,
    );
  }
}

class NotificationState {
  final List<NotificationItem> items;
  final String selectedCategory;
  final String searchQuery;
  final String filterType; // 'All', 'automated', 'manual'
  final String filterPriority; // 'All', 'critical', 'high', 'medium', 'low'

  NotificationState({
    required this.items,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.filterType = 'All',
    this.filterPriority = 'All',
  });

  int get unreadCount => items.where((item) => item.isUnread).length;

  List<NotificationItem> get filteredItems {
    return items.where((item) {
      final matchesCategory = selectedCategory == 'All' || item.category == selectedCategory;
      final matchesType = filterType == 'All' || item.type.toLowerCase() == filterType.toLowerCase();
      final matchesPriority = filterPriority == 'All' || item.priority.toLowerCase() == filterPriority.toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          item.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.summary.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesType && matchesPriority && matchesSearch;
    }).toList();
  }

  NotificationState copyWith({
    List<NotificationItem>? items,
    String? selectedCategory,
    String? searchQuery,
    String? filterType,
    String? filterPriority,
  }) {
    return NotificationState(
      items: items ?? this.items,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: filterType ?? this.filterType,
      filterPriority: filterPriority ?? this.filterPriority,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  final UserModel? _currentUser;
  StreamSubscription<List<NotificationModel>>? _subscription;

  NotificationNotifier(this._repository, this._currentUser)
      : super(NotificationState(items: _getInitialNotificationsForRole(_currentUser))) {
    _listenToNotifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenToNotifications() {
    final user = _currentUser;
    final isParent = user?.role == UserRole.parent;
    final userId = user?.uid ?? (isParent ? 'DEMO-PRT' : 'DEMO-STU');
    final userRole = user?.role.name ?? (isParent ? 'parent' : 'student');
    final userDept = user?.metadata?['department'] ?? user?.metadata?['department_name'];
    final childId = user?.metadata?['child_id'] ?? user?.metadata?['student_id'] ?? user?.metadata?['roll_number'];

    _subscription?.cancel();
    _subscription = _repository.watchUserNotifications(
      userId,
      userRole: userRole,
      department: userDept?.toString(),
      childStudentId: childId?.toString(),
    ).listen((models) {
      if (models.isNotEmpty) {
        final items = models.map((m) => NotificationItem.fromModel(m)).toList();
        state = state.copyWith(items: items);
      }
    });
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilterType(String type) {
    state = state.copyWith(filterType: type);
  }

  void setFilterPriority(String priority) {
    state = state.copyWith(filterPriority: priority);
  }

  Future<void> addNotification({
    NotificationItem? item,
    String? title,
    String? category,
    String? summary,
    String? fullDetails,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    String? priority,
    String? type,
  }) async {
    final newItem = item ??
        NotificationItem.fromModel(
          NotificationModel(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
            title: title ?? 'Notification',
            message: summary ?? fullDetails ?? '',
            type: type ?? 'automated',
            category: category ?? 'General',
            priority: priority ?? 'medium',
            createdAt: DateTime.now(),
            recipientUserIds: [_currentUser?.uid ?? (_currentUser?.role == UserRole.parent ? 'DEMO-PRT' : 'DEMO-STU')],
          ),
        );
    state = state.copyWith(items: [newItem, ...state.items]);
    await _repository.sendNotification(newItem.rawModel);
  }

  Future<void> markAsRead(String id) async {
    final updatedItems = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(isUnread: false);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
    await _repository.markAsRead(id, userId: _currentUser?.uid ?? (_currentUser?.role == UserRole.parent ? 'DEMO-PRT' : 'DEMO-STU'));
  }

  Future<void> markAllAsRead() async {
    final updatedItems = state.items.map((item) => item.copyWith(isUnread: false)).toList();
    state = state.copyWith(items: updatedItems);
    await _repository.markAllAsRead(_currentUser?.uid ?? (_currentUser?.role == UserRole.parent ? 'DEMO-PRT' : 'DEMO-STU'));
  }

  static List<NotificationItem> _getInitialNotificationsForRole(UserModel? user) {
    if (user?.role == UserRole.parent) {
      return [
        NotificationItem.fromModel(NotificationModel(
          id: 'notif-parent-demo-1',
          title: '⚠️ Parent Notice: Student Low Attendance Alert',
          message: 'Your ward Alex Johnson has fallen below the 75% minimum attendance requirement (74.5%). Please ensure regular class attendance.',
          type: 'automated',
          category: 'Attendance',
          priority: 'critical',
          senderId: 'system_rule_attendance',
          senderName: 'System Automation Engine',
          recipientType: 'user',
          recipientUserIds: ['DEMO-PRT'],
          targetRoles: ['parent'],
          relatedModule: 'attendance',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          isRead: false,
        )),
        NotificationItem.fromModel(NotificationModel(
          id: 'notif-parent-demo-2',
          title: '💳 Fee Payment Reminder: Semester VI Tuition Fee',
          message: 'Semester VI Tuition Fee (₹45,000) for Alex Johnson is due on 25th August. Please process payment online.',
          type: 'automated',
          category: 'Finance',
          priority: 'high',
          senderId: 'system_rule_fees',
          senderName: 'Finance Department',
          recipientType: 'user',
          recipientUserIds: ['DEMO-PRT'],
          targetRoles: ['parent'],
          relatedModule: 'fee',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: false,
        )),
        NotificationItem.fromModel(NotificationModel(
          id: 'notif-parent-demo-3',
          title: '📅 End-Semester Examination & PTM Schedule',
          message: 'End-semester theory examinations begin on September 15th. Parent-Teacher Meeting is scheduled for September 5th.',
          type: 'manual',
          category: 'Academic',
          priority: 'medium',
          senderId: 'DEMO-HOD',
          senderName: 'Academic Affairs Office',
          senderRole: 'HOD',
          recipientType: 'role',
          targetRoles: ['parent', 'student'],
          relatedModule: 'exam',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        )),
      ];
    }

    return [
      NotificationItem.fromModel(NotificationModel(
        id: 'notif-demo-1',
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
      )),
      NotificationItem.fromModel(NotificationModel(
        id: 'notif-demo-2',
        title: '⏰ Assignment Due Tomorrow',
        message: 'Computer Networks Socket Programming assignment is due in 1 day (Tomorrow, 11:59 PM).',
        type: 'automated',
        category: 'Academic',
        priority: 'high',
        senderId: 'system_rule_assignments',
        senderName: 'System Automation Engine',
        recipientType: 'user',
        recipientUserIds: ['DEMO-STU'],
        targetRoles: ['student'],
        relatedModule: 'assignment',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      )),
      NotificationItem.fromModel(NotificationModel(
        id: 'notif-demo-3',
        title: '📢 Department Circular: End-Sem Exam Rules',
        message: 'Dr. R. Kumar published end-semester examination guidelines for Computer Science Department.',
        type: 'manual',
        category: 'Academic',
        priority: 'medium',
        senderId: 'DEMO-HOD',
        senderName: 'Dr. R. Kumar',
        senderRole: 'HOD',
        recipientType: 'department',
        targetDepartment: 'Computer Science',
        relatedModule: 'exam',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      )),
      NotificationItem.fromModel(NotificationModel(
        id: 'notif-demo-4',
        title: '🎯 Placement Drive: Google SWE Campus Recruitment',
        message: 'Applications are open for Google SWE On-Campus Recruitment Drive. Deadline: 24th August.',
        type: 'manual',
        category: 'Career',
        priority: 'high',
        senderId: 'DEMO-ADM',
        senderName: 'Placement Office',
        recipientType: 'role',
        targetRoles: ['student'],
        relatedModule: 'placement',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      )),
    ];
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  // Ensure scheduler is triggered
  ref.watch(notificationSchedulerProvider);

  final repository = ref.watch(notificationRepositoryProvider);
  final currentUser = ref.watch(authServiceProvider).currentUser;
  return NotificationNotifier(repository, currentUser);
});
