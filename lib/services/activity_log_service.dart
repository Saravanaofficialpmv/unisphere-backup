import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/activity_log_model.dart';

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});

class ActivityLogService {
  final FirebaseFirestore? _firestore;

  ActivityLogService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Log important system activities to activityLogs/{logId}
  Future<void> logActivity({
    required String userId,
    required String action,
    required String module,
    String? entityId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final firestore = _firestore;
    if (firestore == null || userId.isEmpty) return;

    try {
      final logId = 'LOG-${DateTime.now().millisecondsSinceEpoch}';
      final model = ActivityLogModel(
        logId: logId,
        userId: userId,
        action: action,
        module: module,
        entityId: entityId,
        description: description,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      final data = model.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      await firestore.collection('activityLogs').doc(logId).set(data);
    } catch (e) {
      debugPrint('ActivityLogService logActivity notice: $e');
    }
  }

  /// Fetch activity logs for a user or module
  Future<List<ActivityLogModel>> getActivityLogs({String? userId, String? module, int limit = 20}) async {
    final firestore = _firestore;
    if (firestore == null) return [];
    try {
      Query query = firestore.collection('activityLogs').orderBy('createdAt', descending: true).limit(limit);
      if (userId != null && userId.isNotEmpty) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (module != null && module.isNotEmpty) {
        query = query.where('module', isEqualTo: module);
      }
      final snap = await query.get();
      return snap.docs.map((d) => ActivityLogModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    } catch (e) {
      debugPrint('ActivityLogService getActivityLogs notice: $e');
      return [];
    }
  }

  /// Stream live activity logs for real-time dashboard activity feed
  Stream<List<ActivityLogModel>> watchRecentActivity({int limit = 10, String? module}) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);
    try {
      Query query = firestore.collection('activityLogs').orderBy('createdAt', descending: true).limit(limit);
      if (module != null && module.isNotEmpty) {
        query = query.where('module', isEqualTo: module);
      }
      return query.snapshots().map((snap) => snap.docs
          .map((d) => ActivityLogModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());
    } catch (e) {
      debugPrint('ActivityLogService watchRecentActivity notice: $e');
      return Stream.value([]);
    }
  }
}
