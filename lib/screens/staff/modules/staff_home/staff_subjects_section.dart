import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/modules/shared/staff_subject_card.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';

class StaffSubjectsSection extends ConsumerWidget {
  final Function(int)? onNavigateToTab;
  final Function(StaffNavKey)? onNavigateToKey;

  const StaffSubjectsSection({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(staffSubjectsStreamProvider);
    final subjects = subjectsAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MY SUBJECTS',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            InkWell(
              onTap: () {
                if (onNavigateToKey != null) {
                  onNavigateToKey!(StaffNavKey.syllabus);
                } else if (onNavigateToTab != null) {
                  onNavigateToTab!(1); // Syllabus / Subjects management
                }
              },
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
        if (subjects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Center(
              child: Text(
                'No subjects assigned yet',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final sub = subjects[index];
              return StaffSubjectCard(
                subjectName: sub['name'] ?? 'Subject Name',
                subjectCode: sub['code'] ?? 'CS0000',
                className: sub['class'] ?? 'Section',
                studentsCount: (sub['studentsCount'] ?? 60) as int,
                attendancePercent: (sub['attendance'] ?? 90) as int,
                onTap: () {
                  if (onNavigateToKey != null) {
                    onNavigateToKey!(StaffNavKey.syllabus);
                  } else if (onNavigateToTab != null) {
                    onNavigateToTab!(1);
                  }
                },
              );
            },
          ),
      ],
    );
  }
}
