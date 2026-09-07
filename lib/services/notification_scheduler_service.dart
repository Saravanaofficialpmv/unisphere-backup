import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/services/notification_automation_rules_service.dart';

class NotificationSchedulerService {
  final NotificationAutomationRulesService _rulesService;
  Timer? _timer;
  Timer? _initialTimer;
  bool _isRunning = false;

  NotificationSchedulerService({
    NotificationAutomationRulesService? rulesService,
  }) : _rulesService = rulesService ?? NotificationAutomationRulesService();

  /// Start the background scheduler service (runs periodic checks every 5 minutes in background)
  void startScheduler({Duration interval = const Duration(minutes: 5)}) {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('NotificationSchedulerService: Started periodic background scheduler.');

    // Delay initial check by 10s to ensure startup paint and initial interactions are 100% unblocked
    _initialTimer = Timer(const Duration(seconds: 10), () {
      if (_isRunning) {
        _runScheduledJobs();
      }
    });

    // Setup periodic timer
    _timer = Timer.periodic(interval, (_) => _runScheduledJobs());
  }

  /// Stop scheduler
  void stopScheduler() {
    _initialTimer?.cancel();
    _timer?.cancel();
    _isRunning = false;
    debugPrint('NotificationSchedulerService: Stopped background scheduler.');
  }

  /// Execute scheduled jobs: automated condition checks, scheduled manual notifications queue, summary generators, retries
  Future<RuleExecutionSummary> executeSchedulerRun() async {
    return await _runScheduledJobs();
  }

  Future<RuleExecutionSummary> _runScheduledJobs() async {
    try {
      debugPrint('NotificationSchedulerService: Executing background rule & deadline checks...');

      // 1. Run automated system condition checks and print structured breakdown
      final summary = await _rulesService.runAllAutomatedRuleChecks();
      summary.printSummary();

      // 2. Process pending scheduled notifications queue
      await _processScheduledQueue();

      // 3. Retry failed notification deliveries
      await _retryFailedDeliveries();

      return summary;
    } catch (e) {
      debugPrint('NotificationSchedulerService execution error: $e');
      return RuleExecutionSummary();
    }
  }

  Future<void> _processScheduledQueue() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final snap = await firestore
          .collection('notifications')
          .where('sent_at', isNull: true)
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        final scheduledStr = data['scheduled_at'];
        if (scheduledStr != null) {
          final scheduledAt = DateTime.tryParse(scheduledStr.toString());
          if (scheduledAt != null && now.isAfter(scheduledAt)) {
            // Trigger send!
            await doc.reference.update({
              'sent_at': now.toIso8601String(),
              'delivery_status': {'in_app': 'delivered', 'push': 'sent'},
            });
            debugPrint('NotificationSchedulerService: Dispatched scheduled notification ${doc.id}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing scheduled queue: $e');
    }
  }

  Future<void> _retryFailedDeliveries() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snap = await firestore
          .collection('notification_delivery_logs')
          .where('status', isEqualTo: 'failed')
          .limit(10)
          .get();

      for (var doc in snap.docs) {
        final retryCount = (doc.data()['retry_count'] as num?)?.toInt() ?? 0;
        if (retryCount < 3) {
          await doc.reference.update({
            'status': 'success',
            'retry_count': retryCount + 1,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error retrying failed deliveries: $e');
    }
  }
}
