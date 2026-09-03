import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';

class StaffAssignmentBadge extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool isAdvisor;
  final VoidCallback? onTap;

  const StaffAssignmentBadge({
    super.key,
    required this.label,
    this.sublabel,
    this.isAdvisor = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isAdvisor
              ? AppColors.staffRole.withValues(alpha: 0.12)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAdvisor
                ? AppColors.staffRole.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdvisor) ...[
              Icon(
                Icons.stars_rounded,
                size: 14,
                color: AppColors.staffRole,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isAdvisor ? AppColors.staffRole : AppColors.primary,
              ),
            ),
            if (sublabel != null && sublabel!.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '• $sublabel',
                style: GoogleFonts.manrope(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: isAdvisor
                      ? AppColors.staffRole.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
