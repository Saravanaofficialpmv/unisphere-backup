import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<UserModel> _fetchedUsers = [];

  ManualNotificationComposerNotifier(
    this._engine,
    this._repository,
    this._currentUser,
  ) : super(ManualNotificationComposerState()) {
    _applyRbacDefaults();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      _fetchedUsers = snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
      recalculateAudience();
    } catch (_) {}
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
    final candidates = _fetchedUsers.map((u) {
      final meta = u.metadata ?? {};
      final regNo = meta['registerNumber'] ?? meta['regNo'] ?? '';
      final sec = meta['section'] ?? '';
      final att = meta['attendance'] != null ? ' | Att: ${meta['attendance']}%' : '';
      final detail = 'Reg: $regNo | $sec$att';
      return RecipientAudienceItem(
        uid: u.uid,
        name: u.fullName.isNotEmpty ? u.fullName : (u.name.isNotEmpty ? u.name : u.email),
        role: u.role.name,
        department: meta['department']?.toString() ?? u.departmentName ?? u.department ?? '',
        details: detail,
      );
    }).toList();

    final sender = _currentUser;
    final senderDept = sender?.metadata?['department'] ?? sender?.metadata?['department_name'] ?? '';

    for (final item in candidates) {
      // 1. RBAC Department Isolation Check for HOD
      if (sender?.role == UserRole.hod && senderDept.isNotEmpty && item.department.toLowerCase() != senderDept.toString().toLowerCase()) {
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
            final attMatch = RegExp(r'Att:\s*(\d+)').firstMatch(item.details);
            final attVal = attMatch != null ? int.tryParse(attMatch.group(1)!) : null;
            matches = attVal != null && attVal < 75;
            break;
          case 'pending_fees':
            matches = item.role == 'student' || item.role == 'parent';
            break;
          case 'incomplete_profile':
            matches = item.role == 'student';
            break;
          case 'placement_eligible':
            matches = item.role == 'student';
            break;
          case 'event_registered':
            matches = true;
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
