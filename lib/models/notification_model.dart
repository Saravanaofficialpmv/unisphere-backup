class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'automated' | 'manual'
  final String category; // 'Academic', 'Attendance', 'Finance', 'Career', 'Events', 'System', 'Approvals', 'General'
  final String priority; // 'critical', 'high', 'medium', 'low'
  final String senderId; // User UID or system rule source e.g. 'system_rule_attendance'
  final String? senderName;
  final String? senderRole;
  final String recipientType; // 'user', 'role', 'department', 'class', 'filtered', 'all'
  final List<String> recipientUserIds;
  final List<String> targetRoles;
  final String? targetDepartment;
  final String? targetYear;
  final String? targetSemester;
  final String? targetSection;
  final String? relatedModule; // 'attendance', 'assignment', 'fee', 'placement', 'exam', 'approval', 'hackathon', 'system'
  final String? relatedRecordId;
  final String? deepLink;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final Map<String, bool> readStatus; // userId -> isRead
  final Map<String, dynamic> deliveryStatus; // channel -> status
  final DateTime? expiryDate;
  final bool isRead; // Backward compatible flag for current user view

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.category = 'General',
    this.priority = 'medium',
    this.senderId = 'system',
    this.senderName,
    this.senderRole,
    this.recipientType = 'user',
    this.recipientUserIds = const [],
    this.targetRoles = const [],
    this.targetDepartment,
    this.targetYear,
    this.targetSemester,
    this.targetSection,
    this.relatedModule,
    this.relatedRecordId,
    this.deepLink,
    required this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.readStatus = const {},
    this.deliveryStatus = const {'in_app': 'sent'},
    this.expiryDate,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId, {String? currentUserId}) {
    final readMap = (map['read_status'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as bool),
        ) ??
        {};

    final isReadVal = currentUserId != null
        ? (readMap[currentUserId] ?? (map['is_read'] ?? map['isRead'] ?? false))
        : (map['is_read'] ?? map['isRead'] ?? false);

    return NotificationModel(
      id: docId,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'automated',
      category: map['category'] ?? map['type'] ?? 'General',
      priority: map['priority'] ?? 'medium',
      senderId: map['sender_id'] ?? map['senderId'] ?? map['target_user_id'] ?? 'system',
      senderName: map['sender_name'] ?? map['senderName'],
      senderRole: map['sender_role'] ?? map['senderRole'],
      recipientType: map['recipient_type'] ?? map['recipientType'] ?? 'user',
      recipientUserIds: List<String>.from(map['recipient_user_ids'] ?? (map['target_user_id'] != null ? [map['target_user_id']] : [])),
      targetRoles: List<String>.from(map['target_roles'] ?? []),
      targetDepartment: map['target_department'],
      targetYear: map['target_year'],
      targetSemester: map['target_semester'],
      targetSection: map['target_section'],
      relatedModule: map['related_module'] ?? map['type'],
      relatedRecordId: map['related_record_id'],
      deepLink: map['deep_link'] ?? map['deepLink'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      scheduledAt: map['scheduled_at'] != null ? DateTime.tryParse(map['scheduled_at'].toString()) : null,
      sentAt: map['sent_at'] != null ? DateTime.tryParse(map['sent_at'].toString()) : null,
      readStatus: readMap,
      deliveryStatus: Map<String, dynamic>.from(map['delivery_status'] ?? {'in_app': 'sent'}),
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date'].toString()) : null,
      isRead: isReadVal as bool,
    );
  }

  String get targetType => recipientType;
  List<String> get targetUserIds => recipientUserIds;
  String? get relatedEntityId => relatedRecordId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'status': 'sent',
      'category': category,
      'priority': priority,
      'sender_id': senderId,
      'senderId': senderId,
      'sender_name': senderName,
      'senderName': senderName,
      'sender_role': senderRole,
      'senderRole': senderRole,
      'recipient_type': recipientType,
      'recipientType': recipientType,
      'targetType': recipientType,
      'recipient_user_ids': recipientUserIds,
      'targetUserIds': recipientUserIds,
      'target_roles': targetRoles,
      'target_department': targetDepartment,
      'target_year': targetYear,
      'target_semester': targetSemester,
      'target_section': targetSection,
      'related_module': relatedModule,
      'relatedModule': relatedModule,
      'related_record_id': relatedRecordId,
      'relatedRecordId': relatedRecordId,
      'relatedEntityId': relatedRecordId,
      'deep_link': deepLink,
      'created_at': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'read_status': readStatus,
      'delivery_status': deliveryStatus,
      'expiry_date': expiryDate?.toIso8601String(),
      'is_read': isRead,
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? category,
    String? priority,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? recipientType,
    List<String>? recipientUserIds,
    List<String>? targetRoles,
    String? targetDepartment,
    String? targetYear,
    String? targetSemester,
    String? targetSection,
    String? relatedModule,
    String? relatedRecordId,
    String? deepLink,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? sentAt,
    Map<String, bool>? readStatus,
    Map<String, dynamic>? deliveryStatus,
    DateTime? expiryDate,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      recipientType: recipientType ?? this.recipientType,
      recipientUserIds: recipientUserIds ?? this.recipientUserIds,
      targetRoles: targetRoles ?? this.targetRoles,
      targetDepartment: targetDepartment ?? this.targetDepartment,
      targetYear: targetYear ?? this.targetYear,
      targetSemester: targetSemester ?? this.targetSemester,
      targetSection: targetSection ?? this.targetSection,
      relatedModule: relatedModule ?? this.relatedModule,
      relatedRecordId: relatedRecordId ?? this.relatedRecordId,
      deepLink: deepLink ?? this.deepLink,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      readStatus: readStatus ?? this.readStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      expiryDate: expiryDate ?? this.expiryDate,
      isRead: isRead ?? this.isRead,
    );
  }
}
