import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:unisphere/services/parent_service.dart';
import 'package:unisphere/widgets/student/student_reference_card.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Unified Student Reference Card with Attached Status Deck (Reference Design)
/// Uses layered Stack with full bounded height so touch/swipe hit-testing
/// works flawlessly across both the upper card and the lower status deck.
/// ─────────────────────────────────────────────────────────────────────────────
class StudentReferenceCardWithDeck extends StatelessWidget {
  final ParentStudentWard selectedWard;
  final VoidCallback? onCardTap;
  final Function(int index)? onNavigateToTab;

  const StudentReferenceCardWithDeck({
    super.key,
    required this.selectedWard,
    this.onCardTap,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    // Total combined height: 196 (card) + 56 (visible status deck) = 252
    return SizedBox(
      height: 252,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 1. Background Green Status Deck (Positioned at the bottom)
          Positioned(
            top: 140,
            bottom: 0,
            left: 4,
            right: 4,
            child: ParentSummaryCarousel(
              selectedWard: selectedWard,
              onNavigateToTab: onNavigateToTab,
            ),
          ),

          // 2. Foreground Student Identity Card (Positioned at the top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 196,
            child: StudentReferenceCard(
              ward: selectedWard,
              onTap: onCardTap,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Attached Status Deck (Reference Design Style)
/// Tucked directly underneath the Student Identity Card with:
/// - Vibrant electric lime/neon green background
/// - Bold high-contrast typography & dark circular icon
/// - Smooth horizontal swiping across key student highlights
/// - Direct tap navigation to detailed views
/// ─────────────────────────────────────────────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
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

        final double rawPercent = currentWard?.attendancePercent ?? 0.0;
        final int presencePercent = (rawPercent > 1.0) ? rawPercent.toInt() : (rawPercent * 100).toInt();
        final String cgpa = (currentWard?.cgpa != null && currentWard!.cgpa.isNotEmpty && currentWard.cgpa != '-')
            ? currentWard.cgpa
            : '-';
        final String todayStatus = (currentWard?.todayStatus != null && currentWard!.todayStatus.isNotEmpty)
            ? currentWard.todayStatus
            : 'Present';

        // Exam Data
        final bool hasUpcomingExam = (currentWard != null && currentWard.regNo == '23CSE1042');
        final String examTitle = hasUpcomingExam ? 'Mathematics · Aug 28' : 'No upcoming assessments';
        final String examBadge = hasUpcomingExam ? 'In 6 Days' : 'Up to date';

        // Academic Standing
        final String perfStatus = (currentWard?.academicStatus != null && currentWard!.academicStatus.isNotEmpty && currentWard.academicStatus != '-')
            ? currentWard.academicStatus
            : 'Good Standing';

        final String batchText = (currentWard?.batch != null && currentWard!.batch.isNotEmpty)
            ? currentWard.batch
            : '2023 - 2027';

        // Build list of high-energy status items for horizontal scrolling
        final items = <_StatusItemData>[
          _StatusItemData(
            icon: Icons.bolt_rounded,
            title: 'Today: $todayStatus • $presencePercent% Attendance',
            badge: '$presencePercent%',
            tabIndex: 1,
          ),
          _StatusItemData(
            icon: Icons.trending_up_rounded,
            title: '$cgpa CGPA • $perfStatus (Top 15%)',
            badge: 'Academics',
            tabIndex: 2,
          ),
          _StatusItemData(
            icon: Icons.event_note_rounded,
            title: 'Exam: $examTitle',
            badge: examBadge,
            tabIndex: 5,
          ),
          _StatusItemData(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Fees: ₹37,500 Paid • ₹12,500 Pending',
            badge: 'Payment',
            tabIndex: 3,
          ),
          _StatusItemData(
            icon: Icons.school_rounded,
            title: 'Batch $batchText • ${currentWard?.currentYear ?? 'III Year'}',
            badge: 'Enrolled',
            tabIndex: 0,
          ),
        ];

        return Container(
          width: double.infinity,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF06B6D4), // Vibrant Cyan 500
                Color(0xFF38BDF8), // Electric Sky 400
                Color(0xFF06B6D4), // Vibrant Cyan 500
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.36),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 56,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: items.length,
                  onPageChanged: (index) {
                    HapticFeedback.selectionClick();
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onNavigateToTab?.call(item.tabIndex);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Dark Circular Lightning / Status Icon (Exact Reference Look)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFF082F49),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  item.icon,
                                  size: 16,
                                  color: const Color(0xFF67E8F9),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 2. Bold High-Contrast Text
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF082F49),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusItemData {
  final IconData icon;
  final String title;
  final String badge;
  final int tabIndex;

  const _StatusItemData({
    required this.icon,
    required this.title,
    required this.badge,
    required this.tabIndex,
  });
}
