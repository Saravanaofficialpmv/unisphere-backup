import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/repositories/staff_repository.dart';

class AdvisorTasksSection extends ConsumerStatefulWidget {
  final VoidCallback? onViewAll;

  const AdvisorTasksSection({super.key, this.onViewAll});

  @override
  ConsumerState<AdvisorTasksSection> createState() => _AdvisorTasksSectionState();
}

class _AdvisorTasksSectionState extends ConsumerState<AdvisorTasksSection> {
  final Map<String, bool> _localCompleted = {};

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(advisorTasksStreamProvider);
    final tasks = tasksAsync.valueOrNull ?? [];

    final taskItems = tasks.take(4).map((t) => {
          'id': t.id,
          'title': t.title,
          'dueDate': t.dueDate.startsWith('Due') ? t.dueDate : 'Due ${t.dueDate}',
          'done': _localCompleted[t.id] ?? t.isCompleted,
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ADVISOR TASKS',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            if (widget.onViewAll != null)
              InkWell(
                onTap: widget.onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.staffRole,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.staffRole,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: taskItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Text(
                      'No pending advisor tasks.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: taskItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
              final task = taskItems[index];
              final id = task['id'] as String;
              final title = task['title'] as String;
              final dueDate = task['dueDate'] as String;
              final isDone = task['done'] as bool;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        final newState = !isDone;
                        setState(() {
                          _localCompleted[id] = newState;
                        });
                        ref
                            .read(staffRepositoryProvider)
                            .toggleAdvisorTaskStatus(id, newState);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.staffRole : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isDone
                                ? AppColors.staffRole
                                : const Color(0xFF94A3B8),
                            width: 1.5,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dueDate,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
