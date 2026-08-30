import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/parent_portal_types.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Modern Reference Design Student Identity Card
/// Rebuilt to match the credit-card reference design with:
/// - Rounded corners (r: 28)
/// - Top-left organic wave swoosh & cyan accent circle
/// - Top-right interlocking dual-ring geometric emblem
/// - Bold prominent student name & details
/// - Dual-column bottom row (Student Reg No & Exp/Batch Date)
/// ─────────────────────────────────────────────────────────────────────────────
class StudentReferenceCardCarousel extends StatelessWidget {
  final List<ParentStudentWard> wards;
  final ParentStudentWard selectedWard;
  final ValueChanged<ParentStudentWard>? onWardChanged;
  final VoidCallback? onTap;
  final bool enableSliding;

  const StudentReferenceCardCarousel({
    super.key,
    required this.wards,
    required this.selectedWard,
    this.onWardChanged,
    this.onTap,
    this.enableSliding = false,
  });

  @override
  Widget build(BuildContext context) {
    return StudentReferenceCard(
      ward: selectedWard,
      onTap: onTap,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Individual Student Reference Card (Exact Reference Visuals + Unisphere Blue Palette)
/// ─────────────────────────────────────────────────────────────────────────────
class StudentReferenceCard extends ConsumerWidget {
  final ParentStudentWard ward;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const StudentReferenceCard({
    super.key,
    required this.ward,
    this.onTap,
    this.borderRadius,
  });

  String _formatCardRegNumber(String reg) {
    final clean = reg.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return '9225 2324 3098';

    // Show full register number grouped in 4-digit chunks for sleek card layout
    final chunks = <String>[];
    for (int i = 0; i < clean.length; i += 4) {
      final end = (i + 4 < clean.length) ? i + 4 : clean.length;
      chunks.add(clean.substring(i, end));
    }
    return chunks.join(' ');
  }

  String _formatBatchYear(ParentStudentWard ward) {
    if (ward.batch.trim().isNotEmpty && ward.batch.contains('-')) {
      return ward.batch;
    }
    // Derive academic batch (From - To) if not explicitly set
    final year = ward.currentYear.toLowerCase();
    if (year.contains('4') || year.contains('iv') || year.contains('final')) {
      return '2022 - 2026';
    } else if (year.contains('3') || year.contains('iii')) {
      return '2023 - 2027';
    } else if (year.contains('2') || year.contains('ii')) {
      return '2024 - 2028';
    } else if (year.contains('1') || year.contains('i')) {
      return '2025 - 2029';
    }
    return ward.batch.isNotEmpty ? ward.batch : '2023 - 2027';
  }

  String _getFormattedDepartment(String rawDept) {
    if (rawDept.contains('Artificial') || rawDept.contains('AI') || rawDept.contains('Data Science')) {
      return 'AI & Data Science';
    }
    if (rawDept.contains('Computer')) return 'Computer Science';
    if (rawDept.contains('Electronics')) return 'Electronics & Comm.';
    if (rawDept.contains('Mechanical')) return 'Mechanical Engg';
    if (rawDept.contains('Civil')) return 'Civil Engg';
    return rawDept;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDept = _getFormattedDepartment(ward.department);
    final cardRegNo = _formatCardRegNumber(ward.regNo);
    final batchYear = _formatBatchYear(ward);
    final cardRadius = borderRadius ?? BorderRadius.circular(28);

    return InkWell(
      onTap: onTap,
      borderRadius: cardRadius,
      child: Container(
        height: 196,
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1E3A8A), // Deep Royal Navy Blue
              Color(0xFF2563EB), // Vibrant Brand Royal Blue
              Color(0xFF3B82F6), // Electric Cobalt Blue
            ],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E40AF).withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: cardRadius,
          child: Stack(
            children: [
              // 1. Custom Painted Wave & Cyan Accent Arc (Matching Reference Design Art)
              Positioned.fill(
                child: CustomPaint(
                  painter: StudentCardWavePainter(),
                ),
              ),

              // 2. Card Content Layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TOP ROW: Interlocking Dual-Ring Emblem (Top Right)
                    const Align(
                      alignment: Alignment.topRight,
                      child: DualRingCardLogo(),
                    ),

                    // CENTER: Prominent Student Identity & Avatar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Student Avatar with Active Green Dot
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: (ward.photoUrl != null && ward.photoUrl!.isNotEmpty)
                                    ? Image.network(
                                        ward.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildAvatarFallback(ward.avatarInitials),
                                      )
                                    : _buildAvatarFallback(ward.avatarInitials),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Large Bold Student Name & Department Tag
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ward.name,
                                style: GoogleFonts.manrope(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                  height: 1.15,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.memory_rounded,
                                          size: 10.5,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3.5),
                                        Text(
                                          formattedDept,
                                          style: GoogleFonts.manrope(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF6EE7B7).withValues(alpha: 0.6),
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Text(
                                      'Active',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFD1FAE5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // BOTTOM ROW: Dual-Column (Student ID Masked Card Format & EXP Date)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left Column: Credit / Student ID Number
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'STUDENT ID / REG NO',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cardRegNo,
                              style: GoogleFonts.spaceMono(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),

                        // Right Column: Batch Year (From - To)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'BATCH YEAR',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              batchYear,
                              style: GoogleFonts.manrope(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String initials) {
    return Container(
      color: const Color(0xFF1D4ED8),
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : 'ST',
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Modern Interlocking Dual-Ring Logo (Matching Reference Design Top-Right)
/// ─────────────────────────────────────────────────────────────────────────────
class DualRingCardLogo extends StatelessWidget {
  final double size;

  const DualRingCardLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 24,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Left Circle: Filled with sleek dark translucent slate
          Positioned(
            left: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          // Right Circle: Stroke outline ring intersecting
          Positioned(
            left: 14,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white,
                  width: 2.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Custom Painter for Top-Left Organic Wave Swoosh & Cyan Accent Arc
/// ─────────────────────────────────────────────────────────────────────────────
class StudentCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Accent Cyan Circle poking out from top-left (Matching Reference Arc)
    final circlePaint = Paint()
      ..color = const Color(0xFF38BDF8) // Electric Sky/Cyan Accent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(w * 0.16, h * 0.04),
      w * 0.085,
      circlePaint,
    );

    // 2. Primary Organic Swoosh Wave (Pure White Layer)
    final swooshPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, h * 0.24);

    // Dynamic wave curves across top-left to top-center
    path.cubicTo(
      w * 0.10,
      h * 0.22,
      w * 0.14,
      h * 0.12,
      w * 0.26,
      h * 0.12,
    );

    path.cubicTo(
      w * 0.34,
      h * 0.12,
      w * 0.38,
      h * 0.02,
      w * 0.48,
      0,
    );

    path.lineTo(w * 0.28, 0);
    path.cubicTo(
      w * 0.22,
      h * 0.06,
      w * 0.16,
      h * 0.08,
      0,
      h * 0.12,
    );

    path.close();
    canvas.drawPath(path, swooshPaint);

    // 3. Subtle Secondary White Swoosh Accent Tip (Adds depth and motion)
    final secondaryPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final secondaryPath = Path();
    secondaryPath.moveTo(w * 0.22, h * 0.14);
    secondaryPath.cubicTo(
      w * 0.30,
      h * 0.14,
      w * 0.36,
      h * 0.08,
      w * 0.44,
      h * 0.06,
    );
    secondaryPath.cubicTo(
      w * 0.38,
      h * 0.16,
      w * 0.28,
      h * 0.18,
      w * 0.22,
      h * 0.14,
    );
    secondaryPath.close();
    canvas.drawPath(secondaryPath, secondaryPaint);

    // 4. Subtle Ambient Background Glow on Top-Right Corner
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.88, h * 0.2), radius: 60));

    canvas.drawCircle(Offset(w * 0.88, h * 0.2), 60, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
