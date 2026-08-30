import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/widgets/common/notification_sheet.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Modern Recent Updates Card Widget (Unisphere Design System)
/// Displays a live stream of real-time notifications with:
/// - Curved squircle container with soft multi-layer shadow and slate border
/// - Header with branded badge, bold typography, glowing unread pill, and 'View All'
/// - Category squircles with pastel semantic tints and crisp icons
/// - Dual-column layout with category pill chip, clean title, and relative time
/// - Glowing unread status indicator and smooth ripple touch interactions
/// ─────────────────────────────────────────────────────────────────────────────
class RecentUpdatesCard extends ConsumerWidget {
  final int maxItems;
  final VoidCallback? onViewAll;
  final Function(NotificationItem item)? onItemTap;
  final dynamic onNavigateToTab;

  const RecentUpdatesCard({
    super.key,
    this.maxItems = 4,
    this.onViewAll,
    this.onItemTap,
    this.onNavigateToTab,
  });

  void _safeNavigate(int index, {bool openCalculator = false}) {
    if (onNavigateToTab == null) return;
    try {
      (onNavigateToTab as dynamic).call(index, openCalculator: openCalculator);
    } catch (_) {
      try {
        (onNavigateToTab as dynamic).call(index);
      } catch (e) {
        debugPrint('Navigation callback error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationProvider);
    final liveItems = notificationsState.items.take(maxItems).toList();
    final unreadCount = notificationsState.unreadCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 1. HEADER ROW (Title + Unread Badge + View All Action) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Header Title & Notification Pill Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Spark/Bolt Accent Badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Updates',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      _buildUnreadCountPill(unreadCount),
                    ],
                  ],
                ),

                // Right 'View All' Link Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onViewAll ??
                        () => showNotificationSheet(
                              context,
                              onNavigateToTab: onNavigateToTab != null
                                  ? (idx, {openCalculator = false}) =>
                                      _safeNavigate(idx, openCalculator: openCalculator)
                                  : null,
                            ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── 2. NOTIFICATION LIST ROWS ──
            if (liveItems.isNotEmpty)
              ...List.generate(liveItems.length, (index) {
                final item = liveItems[index];
                final isLast = index == liveItems.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: _RecentUpdateTile(
                    item: item,
                    onTap: () {
                      if (onItemTap != null) {
                        onItemTap!(item);
                      } else {
                        // Mark as read in background and open sheet
                        ref.read(notificationProvider.notifier).markAsRead(item.id);
                        showNotificationSheet(
                          context,
                          onNavigateToTab: onNavigateToTab != null
                              ? (idx, {openCalculator = false}) =>
                                  _safeNavigate(idx, openCalculator: openCalculator)
                              : null,
                        );
                      }
                    },
                  ),
                );
              })
            else
              // Fallback State when no live updates exist
              _buildFallbackUpdates(context, ref),
          ],
        ),
      ),
    );
  }

  /// Gradient Pill Badge for Unread Counts
  Widget _buildUnreadCountPill(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count NEW',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Default Fallback Update Tiles
  Widget _buildFallbackUpdates(BuildContext context, WidgetRef ref) {
    final fallbackList = [
      _FallbackItemData(
        icon: Icons.campaign_rounded,
        iconBg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
        category: 'Academic',
        categoryBg: const Color(0xFFFFF7ED),
        categoryColor: const Color(0xFFEA580C),
        title: 'Internal assessment marks published',
        time: 'Today, 10:30 AM',
        onTap: () => _safeNavigate(2),
      ),
      _FallbackItemData(
        icon: Icons.calendar_month_rounded,
        iconBg: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF7C3AED),
        category: 'Exams',
        categoryBg: const Color(0xFFF3E8FF),
        categoryColor: const Color(0xFF7C3AED),
        title: 'End semester exam timetable updated',
        time: 'Yesterday, 04:15 PM',
        onTap: () => _safeNavigate(5),
      ),
    ];

    return Column(
      children: List.generate(fallbackList.length, (i) {
        final item = fallbackList[i];
        final isLast = i == fallbackList.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: _FallbackUpdateTile(data: item),
        );
      }),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Modern Interactive Notification Row Tile
/// ─────────────────────────────────────────────────────────────────────────────
class _RecentUpdateTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _RecentUpdateTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryStyle = _resolveCategoryVisuals(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: const Color(0xFFF8FAFC),
        splashColor: AppColors.primarySubtle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Curated Category Squircle Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: categoryStyle.bgColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Icon(
                    categoryStyle.icon,
                    color: categoryStyle.iconColor,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 2. Title and Metadata Row (Category Tag + Relative Time)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Notification Title
                    Text(
                      item.title,
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: item.isUnread ? FontWeight.w800 : FontWeight.w600,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3.5),

                    // Category Pill Tag + Time Ago
                    Row(
                      children: [
                        // Category Chip Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: categoryStyle.tagBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryStyle.label,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: categoryStyle.tagTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Timestamp
                        Expanded(
                          child: Text(
                            item.timeAgo,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Right Status: Glowing Unread Indicator Dot
              if (item.isUnread) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // 4. Sleek Slate Chevron Arrow
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CategoryVisuals _resolveCategoryVisuals(NotificationItem item) {
    final cat = item.category.toLowerCase();
    final title = item.title.toLowerCase();

    // 1. Finance / Fees
    if (cat.contains('finance') || title.contains('fee') || title.contains('payment')) {
      return _CategoryVisuals(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
        tagBgColor: const Color(0xFFFFFBEB),
        tagTextColor: const Color(0xFFB45309),
        label: 'Finance',
      );
    }

    // 2. Attendance & Shortage Alerts
    if (cat.contains('attendance') || title.contains('attendance') || title.contains('shortage')) {
      return _CategoryVisuals(
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEE2E2),
        tagBgColor: const Color(0xFFFEF2F2),
        tagTextColor: const Color(0xFFB91C1C),
        label: 'Attendance',
      );
    }

    // 3. Exams & Schedule
    if (cat.contains('exam') || title.contains('exam') || title.contains('test')) {
      return _CategoryVisuals(
        icon: Icons.description_rounded,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFEDE9FE),
        tagBgColor: const Color(0xFFF5F3FF),
        tagTextColor: const Color(0xFF6D28D9),
        label: 'Exams',
      );
    }

    // 4. Career & Placement
    if (cat.contains('career') || cat.contains('placement') || title.contains('internship') || title.contains('job')) {
      return _CategoryVisuals(
        icon: Icons.work_rounded,
        iconColor: const Color(0xFF059669),
        bgColor: const Color(0xFFD1FAE5),
        tagBgColor: const Color(0xFFECFDF5),
        tagTextColor: const Color(0xFF047857),
        label: 'Career',
      );
    }

    // 5. Events & Hackathons
    if (cat.contains('events') || cat.contains('hackathon') || title.contains('fest') || title.contains('hackathon')) {
      return _CategoryVisuals(
        icon: Icons.emoji_events_rounded,
        iconColor: const Color(0xFFDB2777),
        bgColor: const Color(0xFFFCE7F3),
        tagBgColor: const Color(0xFFFDF2F8),
        tagTextColor: const Color(0xFFBE185D),
        label: 'Events',
      );
    }

    // 6. Academics / Marks (Default)
    return _CategoryVisuals(
      icon: Icons.school_rounded,
      iconColor: const Color(0xFF2563EB),
      bgColor: const Color(0xFFDBEAFE),
      tagBgColor: const Color(0xFFEFF6FF),
      tagTextColor: const Color(0xFF1D4ED8),
      label: item.category.isNotEmpty && item.category != 'All' ? item.category : 'Academic',
    );
  }
}

class _CategoryVisuals {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color tagBgColor;
  final Color tagTextColor;
  final String label;

  _CategoryVisuals({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.label,
  });
}

/// Fallback data model
class _FallbackItemData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String category;
  final Color categoryBg;
  final Color categoryColor;
  final String title;
  final String time;
  final VoidCallback onTap;

  _FallbackItemData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.category,
    required this.categoryBg,
    required this.categoryColor,
    required this.title,
    required this.time,
    required this.onTap,
  });
}

class _FallbackUpdateTile extends StatelessWidget {
  final _FallbackItemData data;

  const _FallbackUpdateTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: const Color(0xFFF8FAFC),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Icon(data.icon, color: data.iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3.5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: data.categoryBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data.category,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: data.categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            data.time,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
