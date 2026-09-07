import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/theme/app_animations.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

enum TaskFilterCategory { all, urgentAndHigh, marks, attendance, assignments, questionPapers }

class StaffPendingTasksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final Function(StaffNavKey)? onNavigateToKey;

  const StaffPendingTasksScreen({
    super.key,
    this.onBack,
    this.onNavigateToKey,
  });

  @override
  ConsumerState<StaffPendingTasksScreen> createState() => _StaffPendingTasksScreenState();
}

class _StaffPendingTasksScreenState extends ConsumerState<StaffPendingTasksScreen> {
  TaskFilterCategory _selectedCategory = TaskFilterCategory.all;
  final Set<String> _locallyCompletedTaskIds = {};

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/staff');
    }
  }

  void _handleTaskAction(Map<String, dynamic> task) {
    final action = task['action']?.toString().toLowerCase() ?? '';
    final title = task['title']?.toString().toLowerCase() ?? '';

    if (action.contains('attendance') || title.contains('attendance')) {
      if (widget.onNavigateToKey != null) {
        widget.onNavigateToKey!(StaffNavKey.attendance);
      } else {
        context.go('/staff/attendance');
      }
    } else if (action.contains('marks') || title.contains('marks')) {
      if (widget.onNavigateToKey != null) {
        widget.onNavigateToKey!(StaffNavKey.marks);
      } else {
        context.go('/staff/marks');
      }
    } else if (action.contains('review') || title.contains('assignment')) {
      if (widget.onNavigateToKey != null) {
        widget.onNavigateToKey!(StaffNavKey.submissions);
      } else {
        context.go('/staff/submissions');
      }
    } else {
      _showTaskDetailModal(task);
    }
  }

  void _showTaskDetailModal(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                _buildPriorityBadge(task['priority']?.toString() ?? 'normal'),
                const Spacer(),
                Text(
                  task['dueDate']?.toString() ?? '',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task['title']?.toString() ?? 'Pending Task',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task['subtitle']?.toString() ?? '',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        final id = task['id']?.toString() ?? '';
                        if (id.isNotEmpty) _locallyCompletedTaskIds.add(id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${task['title']} marked as done.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF0F172A),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Mark as Complete',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleTaskAction(task);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Take Action',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final p = priority.toLowerCase();
    Color bg;
    Color fg;
    String label;

    switch (p) {
      case 'urgent':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'URGENT';
        break;
      case 'high':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'HIGH PRIORITY';
        break;
      case 'medium':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        label = 'MEDIUM';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'NORMAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  bool _matchesCategory(Map<String, dynamic> task, TaskFilterCategory cat) {
    final priority = task['priority']?.toString().toLowerCase() ?? '';
    final title = task['title']?.toString().toLowerCase() ?? '';
    final subtitle = task['subtitle']?.toString().toLowerCase() ?? '';
    final action = task['action']?.toString().toLowerCase() ?? '';

    switch (cat) {
      case TaskFilterCategory.all:
        return true;
      case TaskFilterCategory.urgentAndHigh:
        return priority == 'urgent' || priority == 'high';
      case TaskFilterCategory.marks:
        return title.contains('mark') || subtitle.contains('internal') || action.contains('mark');
      case TaskFilterCategory.attendance:
        return title.contains('attendance') || subtitle.contains('attendance') || action.contains('attendance');
      case TaskFilterCategory.assignments:
        return title.contains('assignment') || subtitle.contains('submission') || action.contains('review');
      case TaskFilterCategory.questionPapers:
        return title.contains('question') || subtitle.contains('semester') || action.contains('qp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(staffPendingWorkStreamProvider);
    final authUser = ref.watch(currentUserProvider).valueOrNull ?? ref.watch(authServiceProvider).currentUser;
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final staff = profileAsync.valueOrNull;

    final String staffName = (staff?.fullName != null && staff!.fullName.trim().isNotEmpty)
        ? staff.fullName
        : ((authUser?.fullName != null && authUser!.fullName.trim().isNotEmpty)
            ? authUser.fullName
            : 'Faculty Member');

    final String staffDept = (staff?.departmentName != null && staff!.departmentName.trim().isNotEmpty)
        ? staff.departmentName
        : (authUser?.metadata?['department']?.toString() ?? 'Computer Science & Engineering');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: _handleBack,
        ),
        title: Text(
          'Task Review Center',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
            onPressed: () => ref.invalidate(staffPendingWorkStreamProvider),
            tooltip: 'Refresh Tasks',
          ),
        ],
      ),
      body: pendingAsync.when(
        loading: () => Center(child: Loader.page()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load pending tasks',
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please check your network and try again.',
                  style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(staffPendingWorkStreamProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.staffRole,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (allTasks) {
          final activeTasks = allTasks
              .where((t) => !_locallyCompletedTaskIds.contains(t['id']?.toString() ?? ''))
              .toList();

          final filteredTasks = activeTasks
              .where((t) => _matchesCategory(t, _selectedCategory))
              .toList();

          final urgentCount = activeTasks.where((t) {
            final p = t['priority']?.toString().toLowerCase() ?? '';
            return p == 'urgent' || p == 'high';
          }).length;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F172A), // Slate 900
                            Color(0xFF881337), // Rose 900
                            Color(0xFFE11D48), // Rose 600
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.assignment_turned_in_rounded, size: 12, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Staff Action Center',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (urgentCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$urgentCount High Priority',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            staffName,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            staffDept,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: Colors.white70),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${activeTasks.length} pending task${activeTasks.length == 1 ? '' : 's'} require your review or action.',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Filter Chips ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip('All (${activeTasks.length})', TaskFilterCategory.all),
                          const SizedBox(width: 8),
                          _buildFilterChip('High Priority ($urgentCount)', TaskFilterCategory.urgentAndHigh),
                          const SizedBox(width: 8),
                          _buildFilterChip('Marks', TaskFilterCategory.marks),
                          const SizedBox(width: 8),
                          _buildFilterChip('Attendance', TaskFilterCategory.attendance),
                          const SizedBox(width: 8),
                          _buildFilterChip('Assignments', TaskFilterCategory.assignments),
                          const SizedBox(width: 8),
                          _buildFilterChip('Question Papers', TaskFilterCategory.questionPapers),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Task List ──
                    if (filteredTasks.isEmpty)
                      _buildEmptyState(activeTasks.isEmpty)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final task = filteredTasks[index];
                          return _buildTaskCard(task);
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskFilterCategory category) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title']?.toString() ?? 'Pending Task';
    final subtitle = task['subtitle']?.toString() ?? '';
    final dueDate = task['dueDate']?.toString() ?? 'Pending';
    final priority = task['priority']?.toString() ?? 'normal';
    final action = task['action']?.toString() ?? '';

    String actionLabel = 'Take Action';
    IconData actionIcon = Icons.arrow_forward_rounded;

    if (action.contains('attendance') || title.toLowerCase().contains('attendance')) {
      actionLabel = 'Mark Attendance';
      actionIcon = Icons.how_to_reg_rounded;
    } else if (action.contains('marks') || title.toLowerCase().contains('mark')) {
      actionLabel = 'Upload Marks';
      actionIcon = Icons.grade_rounded;
    } else if (action.contains('review') || title.toLowerCase().contains('assignment')) {
      actionLabel = 'Review Submissions';
      actionIcon = Icons.rate_review_rounded;
    } else if (action.contains('qp') || title.toLowerCase().contains('question')) {
      actionLabel = 'Upload QP';
      actionIcon = Icons.upload_file_rounded;
    }

    return AppPressable(
      onTap: () => _handleTaskAction(task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPriorityBadge(priority),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.alarm_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      dueDate,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: priority.toLowerCase() == 'urgent'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    final id = task['id']?.toString() ?? '';
                    if (id.isNotEmpty) {
                      setState(() {
                        _locallyCompletedTaskIds.add(id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$title marked as done.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF0F172A),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          'Mark Done',
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleTaskAction(task),
                  icon: Icon(actionIcon, size: 14),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAllDone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 44,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAllDone ? 'All Caught Up!' : 'No Tasks in this Filter',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAllDone
                ? 'You have completed all pending tasks. Outstanding work will appear here when assigned.'
                : 'There are no pending items matching the selected filter criteria.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isAllDone
                ? _handleBack
                : () {
                    setState(() {
                      _selectedCategory = TaskFilterCategory.all;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isAllDone ? 'Back to Dashboard' : 'View All Tasks',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
