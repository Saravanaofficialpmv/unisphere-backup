import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RuleExecutionRecord {
  final String ruleId;
  final String recipientUserId;
  final String eventId;
  final String deduplicationKey;
  final DateTime lastTriggeredAt;
  final String? lastStatusValue;
  final String status; // 'sent', 'pending', 'failed', 'read'
  final DateTime cooldownUntil;

  RuleExecutionRecord({
    required this.ruleId,
    required this.recipientUserId,
    required this.eventId,
    required this.deduplicationKey,
    required this.lastTriggeredAt,
    this.lastStatusValue,
    this.status = 'sent',
    required this.cooldownUntil,
  });

  factory RuleExecutionRecord.fromMap(Map<String, dynamic> map, String docId) {
    final key = map['deduplication_key']?.toString() ?? docId;
    return RuleExecutionRecord(
      ruleId: map['rule_id']?.toString() ?? '',
      recipientUserId: map['recipient_user_id']?.toString() ?? map['target_id']?.toString() ?? '',
      eventId: map['event_id']?.toString() ?? '',
      deduplicationKey: key,
      lastTriggeredAt: map['last_triggered_at'] != null
          ? DateTime.tryParse(map['last_triggered_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastStatusValue: map['last_status_value']?.toString(),
      status: map['status']?.toString() ?? 'sent',
      cooldownUntil: map['cooldown_until'] != null
          ? DateTime.tryParse(map['cooldown_until'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rule_id': ruleId,
      'recipient_user_id': recipientUserId,
      'event_id': eventId,
      'deduplication_key': deduplicationKey,
      'last_triggered_at': lastTriggeredAt.toIso8601String(),
      'last_status_value': lastStatusValue,
      'status': status,
      'cooldown_until': cooldownUntil.toIso8601String(),
    };
  }
}

class NotificationDuplicatePreventer {
  final FirebaseFirestore? _firestore;
  static final Map<String, RuleExecutionRecord> _localCache = {};

  NotificationDuplicatePreventer({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static void clearCache() {
    _localCache.clear();
  }

  /// Construct the mandatory deterministic deduplication key: `${ruleId}_${recipientUserId}_${eventId}`
  static String buildKey({
    required String ruleId,
    required String recipientUserId,
    required String eventId,
  }) {
    final cleanRule = ruleId.trim();
    final cleanRecipient = recipientUserId.trim();
    final cleanEvent = eventId.trim();

    if (cleanEvent.isEmpty) {
      return '${cleanRule}_$cleanRecipient';
    }
    return '${cleanRule}_${cleanRecipient}_$cleanEvent';
  }

  /// Check if a notification rule should trigger for specific (ruleId, recipientUserId, eventId).
  /// Returns `true` if allowed (dispatch/retry), `false` if duplicate (suppress).
  Future<bool> shouldTrigger({
    required String ruleId,
    required String recipientUserId,
    required String eventId,
    required int cooldownHours,
    String? currentStatusValue,
  }) async {
    final key = buildKey(
      ruleId: ruleId,
      recipientUserId: recipientUserId,
      eventId: eventId,
    );
    final now = DateTime.now();

    // 1. Check local cache or Firestore execution history / notifications
    RuleExecutionRecord? record = _localCache[key];
    if (record == null && _firestore != null) {
      try {
        final doc = await _firestore
            .collection('notification_rule_execution_history')
            .doc(key)
            .get();
        if (doc.exists && doc.data() != null) {
          record = RuleExecutionRecord.fromMap(doc.data()!, doc.id);
          _localCache[key] = record;
        } else {
          // Check if notification document exists under notifications/{key}
          final notifDoc = await _firestore.collection('notifications').doc(key).get();
          if (notifDoc.exists && notifDoc.data() != null) {
            final statusVal = notifDoc.data()!['status']?.toString() ?? 'sent';
            final createdAt = notifDoc.data()!['created_at'] != null
                ? DateTime.tryParse(notifDoc.data()!['created_at'].toString()) ?? DateTime.now()
                : (notifDoc.data()!['createdAt'] != null
                    ? DateTime.tryParse(notifDoc.data()!['createdAt'].toString()) ?? DateTime.now()
                    : DateTime.now());
            record = RuleExecutionRecord(
              ruleId: ruleId,
              recipientUserId: recipientUserId,
              eventId: eventId,
              deduplicationKey: key,
              lastTriggeredAt: createdAt,
              lastStatusValue: notifDoc.data()!['last_status_value']?.toString(),
              status: statusVal,
              cooldownUntil: createdAt.add(Duration(hours: cooldownHours)),
            );
            _localCache[key] = record;
          }
        }
      } catch (e) {
        debugPrint('NotificationDuplicatePreventer error checking history: $e');
      }
    }

    if (record == null) {
      // Never dispatched before -> ALLOW
      return true;
    }

    // 2. FAILED NOTIFICATION HANDLING: If status is 'failed', verify against notifications collection before retrying
    if (record.status == 'failed') {
      if (_firestore != null) {
        try {
          final notifDoc = await _firestore.collection('notifications').doc(key).get();
          if (notifDoc.exists && notifDoc.data() != null) {
            final createdAt = notifDoc.data()!['created_at'] != null
                ? DateTime.tryParse(notifDoc.data()!['created_at'].toString()) ?? DateTime.now()
                : (notifDoc.data()!['createdAt'] != null
                    ? DateTime.tryParse(notifDoc.data()!['createdAt'].toString()) ?? DateTime.now()
                    : DateTime.now());
            if (now.isBefore(createdAt.add(Duration(hours: cooldownHours)))) {
              // Notification was actually persisted and is within cooldown -> SUPPRESS
              return false;
            }
          }
        } catch (_) {}
      }
      return true;
    }

    // 3. Status state changed meaningfully -> ALLOW
    if (currentStatusValue != null &&
        record.lastStatusValue != null &&
        record.lastStatusValue != currentStatusValue) {
      return true;
    }

    // 4. Cooldown expired -> ALLOW
    if (now.isAfter(record.cooldownUntil)) {
      return true;
    }

    // Otherwise SUPPRESS DUPLICATE
    return false;
  }

  /// Log execution to local cache and Firestore execution history / atomic protection table.
  Future<void> recordExecution({
    required String ruleId,
    required String recipientUserId,
    required String eventId,
    String status = 'sent',
    required int cooldownHours,
    String? currentStatusValue,
  }) async {
    final key = buildKey(
      ruleId: ruleId,
      recipientUserId: recipientUserId,
      eventId: eventId,
    );
    final now = DateTime.now();
    final cooldownUntil = now.add(Duration(hours: cooldownHours));

    final record = RuleExecutionRecord(
      ruleId: ruleId,
      recipientUserId: recipientUserId,
      eventId: eventId,
      deduplicationKey: key,
      lastTriggeredAt: now,
      lastStatusValue: currentStatusValue,
      status: status,
      cooldownUntil: cooldownUntil,
    );

    _localCache[key] = record;

    if (_firestore != null) {
      try {
        await _firestore
            .collection('notification_rule_execution_history')
            .doc(key)
            .set(record.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('NotificationDuplicatePreventer error saving execution history: $e');
      }
    }
  }
}
