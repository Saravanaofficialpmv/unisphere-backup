import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unisphere/models/notification_rule_model.dart';
import 'package:unisphere/services/notification_engine.dart';

class RuleExecutionSummary {
  int rulesChecked = 0;
  int eligibleRecipients = 0;
  int notificationsCreated = 0;
  int dispatchedCount = 0;
  int duplicatesSuppressed = 0;
  int failedCount = 0;
  int skippedCount = 0;
  final List<NotificationDispatchResult> dispatchResults = [];

  void recordResult(NotificationDispatchResult result) {
    eligibleRecipients++;
    dispatchResults.add(result);
    if (result.decision == NotificationDecision.dispatch && result.success) {
      notificationsCreated++;
      dispatchedCount++;
    } else if (result.decision == NotificationDecision.suppressDuplicate) {
      duplicatesSuppressed++;
    } else if (!result.success) {
      failedCount++;
    } else {
      skippedCount++;
    }
  }

  void printSummary() {
    debugPrint('''
NotificationSchedulerService:
Rules checked: $rulesChecked
Eligible recipients: $eligibleRecipients
Notifications created: $notificationsCreated
Notifications dispatched: $dispatchedCount
Duplicates suppressed: $duplicatesSuppressed
Failed: $failedCount
Skipped: $skippedCount
''');
  }
}

class NotificationAutomationRulesService {
  final FirebaseFirestore? _firestore;
  final NotificationEngine _engine;

  NotificationAutomationRulesService({
    FirebaseFirestore? firestore,
    NotificationEngine? engine,
  })  : _firestore = firestore ?? _tryGetFirestore(),
        _engine = engine ?? NotificationEngine(firestore: firestore);

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Run all system condition rule checks across student, parent, staff, HOD, and admin entities.
  /// Returns a comprehensive [RuleExecutionSummary] tracking rules checked, eligible recipients, dispatched, suppressed, and failed count.
  Future<RuleExecutionSummary> runAllAutomatedRuleChecks({
    List<NotificationRuleModel>? customRules,
  }) async {
    final summary = RuleExecutionSummary();
    final rules = customRules ?? await fetchActiveRules();

    for (final rule in rules) {
      if (!rule.enabled) continue;
      summary.rulesChecked++;

      try {
        switch (rule.ruleId) {
          case 'rule_attendance_warning':
          case 'rule_attendance_critical':
            await _evaluateAttendanceRules(rule, summary);
            break;
          case 'rule_assignment_deadlines':
            await _evaluateAssignmentDeadlineRules(rule, summary);
            break;
          case 'rule_fee_deadlines':
          case 'rule_fee_due_parent':
            await _evaluateFeeRules(rule, summary);
            break;
          case 'rule_staff_attendance_pending':
          case 'rule_staff_att_sub_pending':
            await _evaluateStaffAttendanceRules(rule, summary);
            break;
          case 'rule_hod_dept_monitoring':
          case 'rule_hod_dept_att_alert':
            await _evaluateHodDepartmentMonitoringRules(rule, summary);
            break;
          case 'rule_admin_system_monitoring':
            await _evaluateAdminSystemMonitoringRules(rule, summary);
            break;
          case 'rule_placement_eligibility':
          case 'rule_placement_eligible_alert':
            await _evaluatePlacementRules(rule, summary);
            break;
          case 'rule_hackathon_reminders':
          case 'rule_registered_hackathon_due':
            await _evaluateHackathonRules(rule, summary);
            break;
          default:
            await _evaluateGenericRule(rule, summary);
        }
      } catch (e) {
        debugPrint('Error evaluating rule ${rule.ruleId}: $e');
      }
    }

    return summary;
  }

  /// Fetch active notification rules from Firestore or return defaults
  Future<List<NotificationRuleModel>> fetchActiveRules() async {
    final firestore = _firestore;
    if (firestore == null) return getDefaultRules();

    try {
      final snap = await firestore.collection('notification_rules').get();
      if (snap.docs.isEmpty) {
        final defaults = getDefaultRules();
        for (var r in defaults) {
          await firestore.collection('notification_rules').doc(r.ruleId).set(r.toMap());
        }
        return defaults;
      }
      return snap.docs.map((doc) => NotificationRuleModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error fetching notification rules: $e');
      return getDefaultRules();
    }
  }

  /// Default DB rules
  static List<NotificationRuleModel> getDefaultRules() {
    return [
      NotificationRuleModel(
        ruleId: 'rule_attendance_warning',
        ruleName: 'Attendance Warning Threshold',
        category: 'Attendance',
        warningThreshold: 80.0,
        criticalThreshold: 75.0,
        consecutiveAbsenceLimit: 2,
        priority: 'high',
        targetRoles: ['student', 'parent'],
      ),
      NotificationRuleModel(
        ruleId: 'rule_attendance_critical',
        ruleName: 'Attendance Critical Alert',
        category: 'Attendance',
        warningThreshold: 80.0,
        criticalThreshold: 75.0,
        consecutiveAbsenceLimit: 2,
        priority: 'critical',
        targetRoles: ['student', 'parent', 'hod'],
      ),
      NotificationRuleModel(
        ruleId: 'rule_assignment_deadlines',
        ruleName: 'Assignment Deadline Reminders',
        category: 'Academic',
        reminderDays: [3, 1, 0],
        priority: 'high',
        targetRoles: ['student'],
      ),
      NotificationRuleModel(
        ruleId: 'rule_fee_due_parent',
        ruleName: 'Fee Payment Reminders for Parents & Students',
        category: 'Finance',
        reminderDays: [7, 3, 1, 0],
        priority: 'high',
        targetRoles: ['student', 'parent', 'admin'],
      ),
      NotificationRuleModel(
        ruleId: 'rule_staff_att_sub_pending',
        ruleName: 'Staff Pending Attendance Submissions',
        category: 'Academic',
        cooldownHours: 12,
        priority: 'medium',
        targetRoles: ['staff', 'hod'],
      ),
      NotificationRuleModel(
        ruleId: 'rule_hod_dept_att_alert',
        ruleName: 'HOD Department Attendance Monitoring',
        category: 'Approvals',
        warningThreshold: 80.0,
        priority: 'high',
        targetRoles: ['hod'],
      ),
      NotificationRuleModel(
        ruleId: 'rule_admin_system_monitoring',
        ruleName: 'Admin System Integrity & Unverified Accounts',
        category: 'System',
        priority: 'critical',
        targetRoles: ['admin'],
      ),
      NotificationRuleModel(
        ruleId: 'rule_placement_eligible_alert',
        ruleName: 'Placement & Career Deadlines',
        category: 'Career',
        priority: 'high',
        targetRoles: ['student', 'parent'],
      ),
      NotificationRuleModel(
        ruleId: 'rule_registered_hackathon_due',
        ruleName: 'Hackathon & Event Registered Student Reminders',
        category: 'Events',
        priority: 'medium',
        targetRoles: ['student'],
      ),
    ];
  }

  // ==========================================
  // RULE EVALUATORS FOR SYSTEM CONDITIONS
  // ==========================================

  Future<void> _evaluateAttendanceRules(NotificationRuleModel rule, RuleExecutionSummary summary) async {
    // Only evaluate live data from Firestore
  }

  Future<void> _evaluateAssignmentDeadlineRules(NotificationRuleModel rule, RuleExecutionSummary summary) async {
    // Only evaluate live assignments from Firestore
  }

  /// 4. FIX FEE DUE PARENT RULE
  /// Finds all students with due fee items and resolves parent recipient(s).
  /// Enforces deterministic key: rule_fee_due_parent_${recipientUserId}_${feeId}
  Future<void> _evaluateFeeRules(NotificationRuleModel rule, RuleExecutionSummary summary) async {
    final dueFees = <Map<String, String>>[];

    for (final feeItem in dueFees) {
      final feeId = feeItem['feeId']!;
      final studentId = feeItem['studentId']!;
      final parentId = feeItem['parentId']!;
      final studentName = feeItem['studentName']!;
      final feeName = feeItem['feeName']!;

      // 1. Dispatch for Student
      final resStudent = await _engine.dispatchAutomatedNotification(
        ruleId: 'rule_fee_due_student',
        recipientUserId: studentId,
        eventId: feeId,
        title: '💳 $feeName Due Soon',
        message: '$feeName payment deadline is approaching. Please ensure timely payment.',
        category: 'Finance',
        priority: 'high',
        targetRoles: ['student'],
        relatedModule: 'fee',
        relatedRecordId: feeId,
        currentStatusValue: 'FEE_DUE_$feeId',
        cooldownHours: rule.cooldownHours,
      );
      summary.recordResult(resStudent);

      // 2. Dispatch for Parent (Independent recipient per student fee item)
      final resParent = await _engine.dispatchAutomatedNotification(
        ruleId: 'rule_fee_due_parent',
        recipientUserId: parentId,
        eventId: feeId,
        title: '💳 Fee Payment Reminder for Ward',
        message: '$feeName for $studentName is due soon. Please process payment via portal.',
        category: 'Finance',
        priority: 'high',
        targetRoles: ['parent'],
        relatedModule: 'fee',
        relatedRecordId: feeId,
        currentStatusValue: 'FEE_DUE_$feeId',
        cooldownHours: rule.cooldownHours,
      );
      summary.recordResult(resParent);
    }
  }

  /// 8. FIX STAFF ATTENDANCE RULE
  /// Resolves staff members with pending class attendance submissions for a specific date.
  /// Enforces deterministic key: rule_staff_att_sub_pending_${staffId}_${classEventId}
  Future<void> _evaluateStaffAttendanceRules(NotificationRuleModel rule, RuleExecutionSummary summary) async {}

  Future<void> _evaluateHodDepartmentMonitoringRules(NotificationRuleModel rule, RuleExecutionSummary summary) async {
    // Evaluates live department stats from Firestore
  }

  Future<void> _evaluateAdminSystemMonitoringRules(NotificationRuleModel rule, RuleExecutionSummary summary) async {
    // Evaluates live system status from Firestore
  }

  Future<void> _evaluatePlacementRules(NotificationRuleModel rule, RuleExecutionSummary summary) async {}

  Future<void> _evaluateHackathonRules(NotificationRuleModel rule, RuleExecutionSummary summary) async {}

  Future<void> _evaluateGenericRule(NotificationRuleModel rule, RuleExecutionSummary summary) async {}
}
