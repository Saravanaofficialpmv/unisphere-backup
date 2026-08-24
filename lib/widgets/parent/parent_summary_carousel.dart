import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:unisphere/services/parent_service.dart';

/// Horizontally sliding summary carousel for the top of the Parent Dashboard.
/// Contains:
/// 1. Key Metrics Overview (CGPA | Attendance | Today's Status)
/// 2. Upcoming Exam (Mathematics · Aug 28)
/// 3. Academic Performance (85% · Good / 8.2 CGPA)
/// 4. Pending Tasks (2 Pending / All caught up)
class ParentSummaryCarousel extends StatefulWidget {
  final ParentStudentWard? selectedWard;
  final Function(int index)? onNavigateToTab;

  const ParentSummaryCarousel({
    super.key,
    this.selectedWard,
    this.onNavigateToTab,
  });

  @override
  State<ParentSummaryCarousel> createState() => _ParentSummaryCarouselState();
}

class _ParentSummaryCarouselState extends State<ParentSummaryCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // 0.94 viewportFraction gives a subtle peek of the adjacent card to indicate swipeability
    _pageController = PageController(viewportFraction: 0.94);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final ward = widget.selectedWard;
        final regNo = ward?.regNo ?? '';

        // Live database updates
        final liveWard = regNo.isNotEmpty
            ? ref.watch(activeWardLiveStreamProvider(regNo)).value
            : null;
        final currentWard = liveWard ?? ward;

        final double rawPercent = currentWard?.attendancePercent ?? 0.87;
        final int presencePercent = (rawPercent > 1.0) ? rawPercent.toInt() : (rawPercent * 100).toInt();
        final String cgpa = (currentWard?.cgpa != null && currentWard!.cgpa.isNotEmpty)
            ? currentWard.cgpa
            : '8.2';
        final String todayStatus = (currentWard?.todayStatus != null && currentWard!.todayStatus.isNotEmpty)
            ? currentWard.todayStatus
            : (rawPercent < 0.70 ? 'Absent' : 'Present');

        final isCSE = currentWard?.department.contains('Computer') ?? true;

        // Exam Data
        final bool hasUpcomingExam = currentWard != null && currentWard.regNo.isNotEmpty;
        final String examTitle = hasUpcomingExam
            ? (isCSE ? 'Mathematics · Aug 28' : 'Signals & Systems · Aug 30')
            : 'No upcoming exams';
        final String examSubtitle = hasUpcomingExam
            ? (isCSE ? 'Semester Assessment • 10:00 AM' : 'Mid-Term Exam • 09:30 AM')
            : 'All scheduled assessments completed';
        final String examBadge = hasUpcomingExam ? 'In 6 Days' : 'Completed';

        // Academic Performance Data
        final String perfScore = '$cgpa CGPA';
        final String perfStatus = (currentWard?.academicStatus != null && currentWard!.academicStatus.isNotEmpty)
            ? currentWard.academicStatus
            : 'Good';
        final String performanceText = '$perfScore · $perfStatus';
        final double progressPercent = double.tryParse(cgpa) != null
            ? ((double.tryParse(cgpa) ?? 8.2) / 10.0).clamp(0.0, 1.0)
            : 0.85;

        // Pending Tasks Data
        final int pendingCount = isCSE ? 2 : 1;
        final String pendingText = pendingCount > 0 ? '$pendingCount Pending' : 'All caught up';
        final String pendingSubtitle = pendingCount > 0
            ? (isCSE ? 'DBMS Lab Record & OS Assignment due soon' : 'Analog Circuits Problem Set 2 due Friday')
            : 'All assignments & submissions are up to date';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 98,
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Slide 1: 3-Metric Overview (CGPA | Attendance | Today's Status)
                  _buildMetricsStripCard(
                    cgpa: cgpa,
                    presencePercent: presencePercent,
                    todayStatus: todayStatus,
                  ),

                  // Slide 2: Upcoming Exam
                  _buildSlideCard(
                    icon: Icons.edit_calendar_rounded,
                    iconBgColor: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    category: 'Upcoming Exam',
                    title: examTitle,
                    subtitle: examSubtitle,
                    badge: examBadge,
                    badgeBgColor: const Color(0xFFEFF6FF),
                    badgeTextColor: const Color(0xFF2563EB),
                    onTap: () => widget.onNavigateToTab?.call(5),
                  ),

                  // Slide 3: Academic Performance
                  _buildSlideCard(
                    icon: Icons.auto_graph_rounded,
                    iconBgColor: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    category: 'Academic Performance',
                    title: performanceText,
                    subtitle: 'Ranked in top 15% of department batch',
                    badge: 'Overall Standing',
                    badgeBgColor: const Color(0xFFF5F3FF),
                    badgeTextColor: const Color(0xFF7C3AED),
                    progress: progressPercent,
                    onTap: () => widget.onNavigateToTab?.call(2),
                  ),

                  // Slide 4: Pending Tasks
                  _buildSlideCard(
                    icon: pendingCount > 0 ? Icons.pending_actions_rounded : Icons.task_alt_rounded,
                    iconBgColor: pendingCount > 0 ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                    iconColor: pendingCount > 0 ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                    category: 'Pending Tasks',
                    title: pendingText,
                    subtitle: pendingSubtitle,
                    badge: pendingCount > 0 ? 'Action Needed' : 'Completed',
                    badgeBgColor: pendingCount > 0 ? const Color(0xFFFFF7ED) : const Color(0xFFDCFCE7),
                    badgeTextColor: pendingCount > 0 ? const Color(0xFFEA580C) : const Color(0xFF15803D),
                    onTap: () => widget.onNavigateToTab?.call(2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Subtle Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: isSelected ? 16 : 5,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  // 1. Key Metrics Strip Slide (CGPA | Attendance | Today's Status)
  Widget _buildMetricsStripCard({
    required String cgpa,
    required int presencePercent,
    required String todayStatus,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. CGPA
          Expanded(
            child: InkWell(
              onTap: () => widget.onNavigateToTab?.call(2),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bar_chart_rounded, size: 14.5, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 4),
                        Text(
                          'CGPA',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cgpa,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),

          // 2. Attendance
          Expanded(
            child: InkWell(
              onTap: () => widget.onNavigateToTab?.call(1),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12.5, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Attendance',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$presencePercent%',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),

          // 3. Today's Status
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _getTodayStatusDotColor(todayStatus),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "Today's Status",
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    todayStatus,
                    style: GoogleFonts.manrope(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: _getTodayStatusTextColor(todayStatus),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Generic Slide Card (Upcoming Exam / Academic Performance / Pending Tasks)
  Widget _buildSlideCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String category,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeBgColor,
    required Color badgeTextColor,
    VoidCallback? onTap,
    double? progress,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon + Category Label + Badge Pill
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 13,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.manrope(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // Middle: Main Value
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Bottom: Subtitle or Progress Bar
                if (progress != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4.0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                else
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTodayStatusDotColor(String status) {
    switch (status.toLowerCase()) {
      case 'absent':
        return const Color(0xFFEF4444);
      case 'leave':
      case 'on leave':
        return const Color(0xFFF59E0B);
      case 'present':
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getTodayStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'absent':
        return const Color(0xFFDC2626);
      case 'leave':
      case 'on leave':
        return const Color(0xFFD97706);
      case 'present':
      default:
        return const Color(0xFF15803D);
    }
  }
}
