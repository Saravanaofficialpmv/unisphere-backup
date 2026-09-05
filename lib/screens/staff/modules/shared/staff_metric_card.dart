import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';

class StaffMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final String? imageAsset;
  final Color? iconColor;
  final Color? iconBgColor;
  final List<Color>? gradientColors;
  final String? trendText;
  final double? progress;
  final VoidCallback? onTap;
  final bool isDense;

  const StaffMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.imageAsset,
    this.iconColor,
    this.iconBgColor,
    this.gradientColors,
    this.trendText,
    this.progress,
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

    double? effectiveProgress = progress;
    if (effectiveProgress == null && value.contains('%')) {
      final parsed = double.tryParse(value.replaceAll('%', '').trim());
      if (parsed != null && parsed > 0) {
        effectiveProgress = (parsed / 100.0).clamp(0.0, 1.0);
      }
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: effectiveGradients.first.withValues(alpha: 0.12),
        highlightColor: effectiveGradients.first.withValues(alpha: 0.06),
        child: Container(
          height: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isDense ? 9 : 11,
            vertical: isDense ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                effectiveGradients.first.withValues(alpha: 0.035),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: effectiveGradients.first.withValues(alpha: 0.16),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: effectiveGradients.first.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Header: Solid 3D Gradient Icon Badge & Compact Chevron ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (imageAsset != null)
                    Container(
                      width: isDense ? 34 : 38,
                      height: isDense ? 34 : 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: effectiveGradients.first.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset(
                          imageAsset!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: isDense ? 34 : 38,
                      height: isDense ? 34 : 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: effectiveGradients,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: effectiveGradients.first.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon ?? Icons.analytics_rounded,
                          size: isDense ? 18 : 20,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Compact Micro Chevron or Dot
                  if (onTap != null)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Metric Value & Title & Subtitle ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: isDense ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      if (trendText != null && trendText!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: effectiveGradients.first.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trendText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: effectiveGradients.first,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: isDense ? 10.5 : 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 1),
                  SizedBox(
                    height: 14,
                    child: (subtitle != null && subtitle!.isNotEmpty)
                        ? Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Micro Progress Bar
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 3.5,
                      width: double.infinity,
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                      child: effectiveProgress != null && effectiveProgress > 0
                          ? FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: effectiveProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: effectiveGradients,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
