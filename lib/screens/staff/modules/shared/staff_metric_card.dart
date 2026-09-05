import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';

class StaffMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final List<Color>? gradientColors;
  final String? trendText;
  final VoidCallback? onTap;
  final bool isDense;

  const StaffMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.gradientColors,
    this.trendText,
    this.onTap,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? gradientColors?.first ?? AppColors.staffRole;
    final effectiveGradients = gradientColors ?? [
      effectiveColor,
      effectiveColor.withValues(alpha: 0.8),
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: effectiveColor.withValues(alpha: 0.08),
        highlightColor: effectiveColor.withValues(alpha: 0.04),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDense ? 10 : 13,
            vertical: isDense ? 10 : 13,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: effectiveColor.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Header: Advanced Icon & Chevron Pill ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Advanced Multi-Layer Gradient Icon Container
                  Container(
                    width: isDense ? 36 : 42,
                    height: isDense ? 36 : 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          effectiveGradients.first.withValues(alpha: 0.16),
                          effectiveGradients.last.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: effectiveGradients.first.withValues(alpha: 0.28),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: effectiveGradients.first.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: isDense ? 19 : 22,
                        color: effectiveGradients.first,
                      ),
                    ),
                  ),

                  // Trend Tag or Chevron Button Pill
                  if (trendText != null && trendText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: effectiveGradients.first.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: effectiveGradients.first.withValues(alpha: 0.18),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        trendText!,
                        style: GoogleFonts.manrope(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: effectiveGradients.first,
                        ),
                      ),
                    )
                  else if (onTap != null)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: isDense ? 8 : 12),

              // ── Metric Value & Title ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: isDense ? 19 : 23,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: isDense ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
