import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';

class AdvisorClassAttendanceSection extends ConsumerWidget {
  final VoidCallback? onViewAllStudents;
  final Function(String)? onSelectStudent;

  const AdvisorClassAttendanceSection({
    super.key,
    this.onViewAllStudents,
    this.onSelectStudent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(advisorClassSummaryProvider);
    final attentionStudents = ref.watch(advisorAttentionStudentsProvider);

    final defaultLowAttendanceStudents = [
      {'name': 'Arun Kumar', 'percent': 68, 'initial': 'A'},
      {'name': 'Karthik Raj', 'percent': 71, 'initial': 'K'},
      {'name': 'Priya Sharma', 'percent': 76, 'initial': 'P'},
    ];

    final displayList = attentionStudents.isNotEmpty
        ? attentionStudents.take(3).map((s) => {
              'name': s.fullName,
              'percent': int.tryParse(s.attendancePercent ?? '75') ?? 75,
              'initial': s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
            }).toList()
        : defaultLowAttendanceStudents;

    final attendanceVal = summary.overallAttendance > 0 ? summary.overallAttendance : 83.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Left Circular Gauge + Vertical Divider + Right Student List ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Circular Progress Gauge & Overall Attendance Label
              SizedBox(
                width: 105,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: (attendanceVal / 100).clamp(0.0, 1.0),
                            strokeWidth: 8.0,
                            strokeCap: StrokeCap.round,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF5B58EB),
                            ),
                          ),
                          Text(
                            '${attendanceVal.toInt()}%',
                            style: GoogleFonts.manrope(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Overall\nAttendance',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical subtle separator
              Container(
                width: 1,
                height: 110,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: const Color(0xFFF1F5F9),
              ),

              // Right: Students Requiring Attention List
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Students Requiring Attention',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    ...displayList.map((st) {
                      final name = st['name'] as String;
                      final pct = st['percent'] as int;
                      final initial = (st['initial'] as String?) ?? (name.isNotEmpty ? name[0].toUpperCase() : 'S');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F0FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$pct%',
                              style: GoogleFonts.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Bottom: Purple View All Students Pill Button ──
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onViewAllStudents,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'View All Students',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
