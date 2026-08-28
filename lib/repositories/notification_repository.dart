import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/notification_model.dart';
import 'package:unisphere/models/notification_rule_model.dart';
import 'package:unisphere/models/manual_notification_draft_model.dart';
import 'package:unisphere/models/notification_delivery_log_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationRepository {
  final FirebaseFirestore? _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Watch targeted notifications for a user based on UID, Role, Department, and optional child/ward ID
  Stream<List<NotificationModel>> watchUserNotifications(
    String targetUserId, {
    String? userRole,
    String? department,
    String? childStudentId,
  }) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);

    final roleNormalized = userRole?.toLowerCase().trim() ?? '';
    final isParent = roleNormalized == 'parent';
    final isAdmin = roleNormalized == 'admin' || roleNormalized == 'administrator';

    return firestore
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id, currentUserId: targetUserId))
          .where((n) {
        final targetRolesLower = n.targetRoles.map((r) => r.toLowerCase().trim()).toList();

        // 1. Direct recipient match (e.g. DEMO-PRT, parent UID, or PRT-studentRoll)
        if (n.recipientUserIds.contains(targetUserId)) {
          return true;
        }

        // 2. Specific Parent logic
        if (isParent) {
          // If child/ward roll number or student ID is matched via PRT- prefix
          if (childStudentId != null && (n.recipientUserIds.contains('PRT-$childStudentId') || n.recipientUserIds.contains(childStudentId) && targetRolesLower.contains('parent'))) {
            return true;
          }
          // If the notification targets parents specifically
          if (targetRolesLower.contains('parent')) {
            if (n.targetDepartment != null && department != null) {
              return n.targetDepartment!.toLowerCase() == department.toLowerCase();
            }
            return true;
          }
          // If global broadcast with parent role included or empty targetRoles
          if (n.recipientUserIds.contains('ALL') && (targetRolesLower.isEmpty || targetRolesLower.contains('parent'))) {
            return true;
          }
          // Parents MUST NOT receive student/staff/admin-only notifications
          return false;
        }

        // 3. Admin view sees all
        if (isAdmin) {
          return true;
        }

        // 4. Global broadcast for other roles
        if (n.recipientUserIds.contains('ALL')) {
          if (targetRolesLower.isEmpty || (userRole != null && targetRolesLower.contains(roleNormalized))) {
            return true;
          }
        }

        // 5. Target Role match for other roles
        if (userRole != null && targetRolesLower.contains(roleNormalized)) {
          if (n.targetDepartment != null && department != null) {
            return n.targetDepartment!.toLowerCase() == department.toLowerCase();
          }
          return true;
        }

        return false;
      }).toList();
    }).handleError((e) {
      debugPrint('Firestore notifications stream error: $e');
      return <NotificationModel>[];
    });
  }

  /// Send notification
  Future<void> sendNotification(NotificationModel notification) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sendNotification error: $e');
    }
  }

  /// Mark single notification as read for user
  Future<void> markAsRead(String notificationId, {String? userId}) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final updates = <String, dynamic>{
        'is_read': true,
      };
      if (userId != null) {
        updates['read_status.$userId'] = true;
      }
      await firestore
          .collection('notifications')
          .doc(notificationId)
          .update(updates);
    } catch (e) {
      debugPrint('Firestore markAsRead error: $e');
    }
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final snap = await firestore.collection('notifications').get();
      final batch = firestore.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {
          'is_read': true,
          'read_status.$userId': true,
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore markAllAsRead error: $e');
    }
  }

  // ==========================================
  // NOTIFICATION RULES CRUD
  // ==========================================
  Stream<List<NotificationRuleModel>> watchNotificationRules() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);

    return firestore.collection('notification_rules').snapshots().map((snap) {
      return snap.docs.map((doc) => NotificationRuleModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> saveNotificationRule(NotificationRuleModel rule) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('notification_rules').doc(rule.ruleId).set(rule.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving notification rule: $e');
    }
  }

  // ==========================================
  // DRAFTS CRUD
  // ==========================================
  Future<List<ManualNotificationDraftModel>> fetchDrafts(String authorId) async {
    final firestore = _firestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('manual_notification_drafts')
          .where('author_id', isEqualTo: authorId)
          .get();
      return snap.docs.map((doc) => ManualNotificationDraftModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error fetching drafts: $e');
      return [];
    }
  }

  Future<void> saveDraft(ManualNotificationDraftModel draft) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('manual_notification_drafts').doc(draft.id).set(draft.toMap());
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  Future<void> deleteDraft(String draftId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('manual_notification_drafts').doc(draftId).delete();
    } catch (e) {
      debugPrint('Error deleting draft: $e');
    }
  }

  // ==========================================
  // DELIVERY LOGS
  // ==========================================
  Future<List<NotificationDeliveryLogModel>> fetchDeliveryLogs() async {
    final firestore = _firestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('notification_delivery_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((doc) => NotificationDeliveryLogModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error fetching delivery logs: $e');
      return [];
    }
  }
}
