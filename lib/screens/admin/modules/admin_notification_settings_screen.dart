import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/notification_rule_model.dart';
import 'package:unisphere/providers/notification_rules_provider.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class AdminNotificationSettingsScreen extends ConsumerStatefulWidget {
  const AdminNotificationSettingsScreen({super.key});

  @override
  ConsumerState<AdminNotificationSettingsScreen> createState() =>
      _AdminNotificationSettingsScreenState();
}

class _AdminNotificationSettingsScreenState
    extends ConsumerState<AdminNotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rulesState = ref.watch(notificationRulesProvider);
    final notifier = ref.read(notificationRulesProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notification Automation Settings',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Run All Rule Checks Now',
            icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary),
            onPressed: () async {
              final count = await notifier.triggerManualRuleCheck();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Automated rule check complete. Dispatched $count notifications.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'System Automation Rules'),
            Tab(text: 'Execution & Duplicate Logs'),
          ],
        ),
      ),
      body: rulesState.isLoading
          ? const Center(child: Loader(label: 'Loading automation rules...'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRulesTab(context, rulesState.rules, notifier),
                _buildExecutionLogsTab(context),
              ],
            ),
    );
  }

  Widget _buildRulesTab(
    BuildContext context,
    List<NotificationRuleModel> rules,
    NotificationRulesNotifier notifier,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return _buildRuleCard(context, rule, notifier);
      },
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    NotificationRuleModel rule,
    NotificationRulesNotifier notifier,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_suggest_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.ruleName,
                        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Category: ${rule.category} | Priority: ${rule.priority.toUpperCase()}',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.enabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => notifier.toggleRule(rule.ruleId, val),
                ),
              ],
            ),
            const Divider(height: 24),

            // Threshold inputs
            if (rule.category == 'Attendance') ...[
              Row(
                children: [
                  Expanded(
                    child: _buildThresholdBox(
                      'Warning Threshold',
                      '${rule.warningThreshold.toInt()}%',
                      'Alerts student when attendance falls below',
                      onTap: () => _editRuleThreshold(context, rule, notifier),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThresholdBox(
                      'Critical Threshold',
                      '${rule.criticalThreshold.toInt()}%',
                      'Triggers urgent parent & student warning',
                      onTap: () => _editRuleThreshold(context, rule, notifier),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Consecutive Absences Limit', '${rule.consecutiveAbsenceLimit} days'),
            ],

            if (rule.category == 'Academic' || rule.category == 'Finance') ...[
              _buildInfoRow('Reminder Intervals', rule.reminderDays.map((d) => '$d days before').join(', ')),
            ],

            const SizedBox(height: 8),
            _buildInfoRow('Cooldown Period', '${rule.cooldownHours} hours (prevents duplicate spam)'),
            _buildInfoRow('Target Roles', rule.targetRoles.join(', ')),
            _buildInfoRow('Enabled Channels', rule.enabledChannels.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdBox(String label, String value, String desc, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(desc, style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _editRuleThreshold(
    BuildContext context,
    NotificationRuleModel rule,
    NotificationRulesNotifier notifier,
  ) {
    final warnCtrl = TextEditingController(text: rule.warningThreshold.toString());
    final critCtrl = TextEditingController(text: rule.criticalThreshold.toString());
    final cooldownCtrl = TextEditingController(text: rule.cooldownHours.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Automation Rule Values', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: warnCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Warning Threshold (%)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: critCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Critical Threshold (%)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cooldownCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cooldown Hours'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final w = double.tryParse(warnCtrl.text) ?? rule.warningThreshold;
              final c = double.tryParse(critCtrl.text) ?? rule.criticalThreshold;
              final cd = int.tryParse(cooldownCtrl.text) ?? rule.cooldownHours;

              notifier.updateRule(rule.copyWith(
                warningThreshold: w,
                criticalThreshold: c,
                cooldownHours: cd,
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rule updated successfully!')),
              );
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionLogsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildLogTile('rule_attendance_critical', 'Suppressed duplicate critical alert (in cooldown period).', '12 mins ago', Colors.orange),
        _buildLogTile('rule_assignment_deadlines', 'Evaluated assignment deadline reminders across active courses.', '1 hour ago', Colors.green),
        _buildLogTile('rule_fee_deadlines', 'Fee deadline rules evaluated for current billing cycle.', '3 hours ago', Colors.green),
        _buildLogTile('rule_admin_unverified_accts', 'System integrity check completed. No anomalies detected.', '5 hours ago', Colors.blue),
      ],
    );
  }

  Widget _buildLogTile(String ruleId, String message, String time, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.shield_outlined, color: color, size: 20)),
        title: Text(ruleId, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(message, style: GoogleFonts.manrope(fontSize: 12)),
        trailing: Text(time, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textTertiary)),
      ),
    );
  }
}
