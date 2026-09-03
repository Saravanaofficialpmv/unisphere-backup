import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unisphere/models/manual_notification_draft_model.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/repositories/notification_repository.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/notification_engine.dart';

class RecipientAudienceItem {
  final String uid;
  final String name;
  final String role;
  final String department;
  final String details;

  RecipientAudienceItem({
    required this.uid,
    required this.name,
    required this.role,
    required this.department,
    required this.details,
  });
}

class ManualNotificationComposerState {
  final String title;
  final String message;
  final String category; // 'Academic', 'Attendance', 'Finance', 'Career', 'Events', 'System', 'General'
  final String priority; // 'critical', 'high', 'medium', 'low'
  final String targetType; // 'role', 'org', 'individual', 'filter'
  final List<String> selectedRoles; // ['student', 'parent', 'staff', 'hod', 'advisor']
  final String? selectedDepartment; // 'Computer Science', 'Information Technology', etc.
  final String? selectedYear; // '1st Year', '2nd Year', '3rd Year', '4th Year'
  final String? selectedSemester; // 'Semester V', 'Semester VI', etc.
  final String? selectedSection; // 'Sec A', 'Sec B'
  final List<String> selectedIndividualUserIds;
  final String selectedDynamicFilter; // 'none', 'low_attendance', 'pending_fees', 'incomplete_profile', 'placement_eligible', 'event_registered'
  final DateTime? scheduledAt;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final List<RecipientAudienceItem> resolvedAudience;

  ManualNotificationComposerState({
    this.title = '',
    this.message = '',
    this.category = 'General',
    this.priority = 'medium',
    this.targetType = 'role',
    this.selectedRoles = const ['student'],
    this.selectedDepartment,
    this.selectedYear,
    this.selectedSemester,
    this.selectedSection,
    this.selectedIndividualUserIds = const [],
    this.selectedDynamicFilter = 'none',
    this.scheduledAt,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.resolvedAudience = const [],
  });

  int get totalRecipientsCount => resolvedAudience.length;

  ManualNotificationComposerState copyWith({
    String? title,
    String? message,
    String? category,
    String? priority,
    String? targetType,
    List<String>? selectedRoles,
    String? selectedDepartment,
    String? selectedYear,
    String? selectedSemester,
    String? selectedSection,
    List<String>? selectedIndividualUserIds,
    String? selectedDynamicFilter,
    DateTime? scheduledAt,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    List<RecipientAudienceItem>? resolvedAudience,
  }) {
    return ManualNotificationComposerState(
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      targetType: targetType ?? this.targetType,
      selectedRoles: selectedRoles ?? this.selectedRoles,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedSemester: selectedSemester ?? this.selectedSemester,
      selectedSection: selectedSection ?? this.selectedSection,
      selectedIndividualUserIds: selectedIndividualUserIds ?? this.selectedIndividualUserIds,
      selectedDynamicFilter: selectedDynamicFilter ?? this.selectedDynamicFilter,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
      resolvedAudience: resolvedAudience ?? this.resolvedAudience,
    );
  }
}

class ManualNotificationComposerNotifier
    extends StateNotifier<ManualNotificationComposerState> {
  final NotificationEngine _engine;
  final NotificationRepository _repository;
  final UserModel? _currentUser;

  ManualNotificationComposerNotifier(
    this._engine,
    this._repository,
    this._currentUser,
  ) : super(ManualNotificationComposerState()) {
    _applyRbacDefaults();
    recalculateAudience();
  }

  void _applyRbacDefaults() {
    final user = _currentUser;
    if (user == null) return;

    if (user.role == UserRole.hod) {
      final dept = user.metadata?['department'] ?? user.metadata?['department_name'] ?? 'Computer Science';
      state = state.copyWith(selectedDepartment: dept.toString());
    } else if (user.role == UserRole.staff) {
      final dept = user.metadata?['department'] ?? user.metadata?['department_name'] ?? 'Computer Science';
      final sec = user.metadata?['section'] ?? 'Sec B';
      state = state.copyWith(selectedDepartment: dept.toString(), selectedSection: sec.toString());
    }
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateMessage(String message) {
    state = state.copyWith(message: message);
  }

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updatePriority(String priority) {
    state = state.copyWith(priority: priority);
  }

  void updateTargetType(String targetType) {
    state = state.copyWith(targetType: targetType);
    recalculateAudience();
  }

  void toggleRole(String role) {
    final roles = List<String>.from(state.selectedRoles);
    if (roles.contains(role)) {
      if (roles.length > 1) roles.remove(role);
    } else {
      roles.add(role);
    }
    state = state.copyWith(selectedRoles: roles);
    recalculateAudience();
  }

  void setDepartment(String? dept) {
    // RBAC check for HOD: cannot select outside department
    if (_currentUser?.role == UserRole.hod) {
      final userDept = _currentUser?.metadata?['department'] ?? _currentUser?.metadata?['department_name'] ?? 'Computer Science';
      state = state.copyWith(selectedDepartment: userDept.toString());
    } else {
      state = state.copyWith(selectedDepartment: dept);
    }
    recalculateAudience();
  }

  void setYear(String? year) {
    state = state.copyWith(selectedYear: year);
    recalculateAudience();
  }

  void setSemester(String? sem) {
    state = state.copyWith(selectedSemester: sem);
    recalculateAudience();
  }

  void setSection(String? sec) {
    state = state.copyWith(selectedSection: sec);
    recalculateAudience();
  }

  void setDynamicFilter(String filter) {
    state = state.copyWith(selectedDynamicFilter: filter);
    recalculateAudience();
  }

  void toggleIndividualUser(String uid) {
    final ids = List<String>.from(state.selectedIndividualUserIds);
    if (ids.contains(uid)) {
      ids.remove(uid);
    } else {
      ids.add(uid);
    }
    state = state.copyWith(selectedIndividualUserIds: ids);
    recalculateAudience();
  }

  void setScheduledAt(DateTime? dt) {
    state = state.copyWith(scheduledAt: dt);
  }

  /// Recalculate matched target audience list & count
  void recalculateAudience() {
    final List<RecipientAudienceItem> audience = [];
    final mockUsers = [
      RecipientAudienceItem(uid: 'DEMO-STU', name: 'Alex Johnson', role: 'student', department: 'Computer Science', details: 'Roll: 22CS01 | Sec B | Att: 74.5%'),
      RecipientAudienceItem(uid: 'STU-002', name: 'Priya Sharma', role: 'student', department: 'Computer Science', details: 'Roll: 22CS02 | Sec B | Att: 88.0%'),
      RecipientAudienceItem(uid: 'STU-003', name: 'Karthik Raja', role: 'student', department: 'Information Technology', details: 'Roll: 22IT05 | Sec A | Att: 69.2%'),
      RecipientAudienceItem(uid: 'DEMO-PRT', name: 'Rajesh Kumar (Parent)', role: 'parent', department: 'Computer Science', details: 'Ward: Alex Johnson'),
      RecipientAudienceItem(uid: 'DEMO-STF', name: 'Dr. K. Tharani Kumar (Faculty)', role: 'staff', department: 'Computer Science', details: 'Assistant Professor'),
      RecipientAudienceItem(uid: 'DEMO-HOD', name: 'Dr. R. Kumar (HOD)', role: 'hod', department: 'Computer Science', details: 'Head of Department'),
    ];

    final sender = _currentUser;
    final senderDept = sender?.metadata?['department'] ?? sender?.metadata?['department_name'] ?? 'Computer Science';

    for (final item in mockUsers) {
      // 1. RBAC Department Isolation Check for HOD
      if (sender?.role == UserRole.hod && item.department.toLowerCase() != senderDept.toString().toLowerCase()) {
        continue; // Enforce HOD department boundary
      }

      bool matches = false;

      if (state.targetType == 'role') {
        matches = state.selectedRoles.contains(item.role);
      } else if (state.targetType == 'org') {
        final matchesDept = state.selectedDepartment == null || state.selectedDepartment == 'Entire College' || item.department.toLowerCase() == state.selectedDepartment!.toLowerCase();
        final matchesSec = state.selectedSection == null || state.selectedSection == 'All Sections' || item.details.contains(state.selectedSection!);
        matches = matchesDept && matchesSec;
      } else if (state.targetType == 'individual') {
        matches = state.selectedIndividualUserIds.contains(item.uid);
      } else if (state.targetType == 'filter') {
        switch (state.selectedDynamicFilter) {
          case 'low_attendance':
            matches = item.details.contains('74.5%') || item.details.contains('69.2%');
            break;
          case 'pending_fees':
            matches = item.role == 'student' || item.role == 'parent';
            break;
          case 'incomplete_profile':
            matches = item.uid == 'STU-003';
            break;
          case 'placement_eligible':
            matches = item.role == 'student' && !item.details.contains('69.2%');
            break;
          case 'event_registered':
            matches = item.uid == 'DEMO-STU';
            break;
          default:
            matches = true;
        }
      }

      if (matches) {
        audience.add(item);
      }
    }

    state = state.copyWith(resolvedAudience: audience);
  }

  /// Dispatch manual notification
  Future<bool> sendNotification() async {
    final author = _currentUser;
    if (author == null) {
      state = state.copyWith(errorMessage: 'Current user not authenticated.');
      return false;
    }

    if (state.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a notification title.');
      return false;
    }

    if (state.message.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter notification message content.');
      return false;
    }

    if (state.resolvedAudience.isEmpty) {
      state = state.copyWith(errorMessage: 'No target recipients selected. Total count is 0.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final recipientUserIds = state.resolvedAudience.map((u) => u.uid).toList();

      await _engine.dispatchManualNotification(
        author: author,
        title: state.title.trim(),
        message: state.message.trim(),
        category: state.category,
        priority: state.priority,
        recipientType: state.targetType,
        recipientUserIds: recipientUserIds,
        targetRoles: state.selectedRoles,
        targetDepartment: state.selectedDepartment,
        targetYear: state.selectedYear,
        targetSemester: state.selectedSemester,
        targetSection: state.selectedSection,
        scheduledAt: state.scheduledAt,
      );

      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Notification successfully ${state.scheduledAt != null ? "scheduled" : "sent"} to ${recipientUserIds.length} recipients!',
        title: '',
        message: '',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Save current notification as draft
  Future<bool> saveDraft() async {
    final author = _currentUser;
    if (author == null) return false;

    final draft = ManualNotificationDraftModel(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      authorId: author.uid,
      authorName: author.name,
      authorRole: author.role.name,
      title: state.title,
      message: state.message,
      priority: state.priority,
      category: state.category,
      recipientType: state.targetType,
      recipientsConfig: {
        'roles': state.selectedRoles,
        'department': state.selectedDepartment,
        'section': state.selectedSection,
        'filter': state.selectedDynamicFilter,
      },
      updatedAt: DateTime.now(),
    );

    await _repository.saveDraft(draft);
    state = state.copyWith(successMessage: 'Notification saved as draft!');
    return true;
  }
}

final manualNotificationComposerProvider = StateNotifierProvider.autoDispose<
    ManualNotificationComposerNotifier, ManualNotificationComposerState>((ref) {
  final engine = NotificationEngine();
  final repository = ref.watch(notificationRepositoryProvider);
  final currentUser = ref.watch(authServiceProvider).currentUser;
  return ManualNotificationComposerNotifier(engine, repository, currentUser);
});
