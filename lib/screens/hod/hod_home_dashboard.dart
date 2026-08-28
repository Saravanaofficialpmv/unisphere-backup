import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/user_session_service.dart';
import 'package:unisphere/widgets/common/apple_glass_card.dart';
import 'package:unisphere/widgets/common/app_progress_indicators.dart';

class HodHomeDashboard extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const HodHomeDashboard({super.key, this.onNavigate});

  @override
  ConsumerState<HodHomeDashboard> createState() => _HodHomeDashboardState();
}

class _HodHomeDashboardState extends ConsumerState<HodHomeDashboard> {
  bool _isReturningUser = true;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      final currentUser = ref.read(authServiceProvider).currentUser;
      final uid = currentUser?.uid ?? '';
      final sessionService = ref.read(userSessionServiceProvider);
      final isReturning = await sessionService.isReturningUser(uid);
      if (mounted) {
        setState(() {
          _isReturningUser = isReturning;
        });
      }
      if (!isReturning && uid.isNotEmpty) {
        await sessionService.markUserSessionSeen(uid);
      }
    } catch (e) {
      debugPrint('Error checking HOD user session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return AmbientGlassBackground(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonalizedGreeting(isMobile),
            const SizedBox(height: 24),
            _buildSummaryCards(context),
            const SizedBox(height: 28),
            _buildDepartmentOverview(context),
            const SizedBox(height: 28),
            _buildAnalyticsGraphs(context),
            const SizedBox(height: 28),
            _buildActivityFeed(),
            const SizedBox(height: 28),
            _buildQuickActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedGreeting(bool isMobile) {
    return AppleGlassCard.frosted(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      borderRadius: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isReturningUser ? 'Good Morning, Welcome Back! 👋' : 'Good Morning, Welcome! 👋',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dr. R. Kumar',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Frosted Glass Pill Badge
                RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.0,
                          ),
                        ),
                        child: const Text(
                          'Head of Department • Computer Science & Engineering',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Specular Glass Shield Badge
          Container(
            width: isMobile ? 56 : 68,
            height: isMobile ? 56 : 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.90),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: isMobile ? 28 : 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      int count = constraints.maxWidth < 650 ? 2 : 4;
      double itemHeight = 165;
      final double crossAxisSpacing = 16.0;
      final double totalSpacing = crossAxisSpacing * (count - 1);
      final double itemWidth = (constraints.maxWidth - totalSpacing) / count;
      final double childAspectRatio = itemWidth / itemHeight;

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: count,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
        children: [
          _buildSummaryCard('Total Students', '1,280', Icons.school_outlined, '4 Batches (CS-A, B, C)', const Color(0xFFEEF2FF), const Color(0xFF3730A3)),
          _buildSummaryCard('Total Faculty', '42', Icons.badge_outlined, 'Professors & Instructors', const Color(0xFFF3E8FF), const Color(0xFF6B21A8)),
          _buildSummaryCard('Classes Today', '18', Icons.class_outlined, 'Lectures & Labs Running', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
          _buildSummaryCard('Overall Attendance', '94.2%', Icons.analytics_outlined, 'Students Present Today', const Color(0xFFD1FAE5), const Color(0xFF065F46)),
        ],
      );
    });
  }

  Widget _buildSummaryCard(String title, String num, IconData icon, String sub, Color bgColor, Color iconColor) {
    return AppleGlassCard.frosted(
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Icon(Icons.trending_up_rounded, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(num, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: iconColor)),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentOverview(BuildContext context) {
    final overviewData = [
      {'label': 'Students Present Today', 'value': '1,205 / 1,280', 'icon': Icons.person_add_alt_1_outlined, 'color': AppColors.primary},
      {'label': 'Faculty Present', 'value': '40 / 42', 'icon': Icons.how_to_reg_outlined, 'color': const Color(0xFF059669)},
      {'label': 'Pending Leave Requests', 'value': '5 Requests', 'icon': Icons.pending_actions_outlined, 'color': AppColors.warning},
      {'label': 'Upcoming Events', 'value': '3 Events', 'icon': Icons.event_available_outlined, 'color': const Color(0xFF7C3AED)},
      {'label': 'Placement Drives', 'value': '2 Scheduled', 'icon': Icons.work_outline, 'color': const Color(0xFF0891B2)},
      {'label': 'Circulars Published', 'value': '14 Circulars', 'icon': Icons.campaign_outlined, 'color': const Color(0xFFDC2626)},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DEPARTMENT OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: overviewData.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final item = overviewData[index];
              final Color col = item['color'] as Color;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, color: col, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item['label'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600), maxLines: 1),
                          const SizedBox(height: 2),
                          Text(item['value'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: col)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGraphs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('WEEKLY ATTENDANCE & PERFORMANCE TREND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          _buildGraphBar('Mon', '96.2%', 0.962, AppColors.primary),
          const SizedBox(height: 10),
          _buildGraphBar('Tue', '94.5%', 0.945, const Color(0xFF7C3AED)),
          const SizedBox(height: 10),
          _buildGraphBar('Wed', '97.8%', 0.978, const Color(0xFF059669)),
          const SizedBox(height: 10),
          _buildGraphBar('Thu', '92.1%', 0.921, AppColors.warning),
          const SizedBox(height: 10),
          _buildGraphBar('Fri', '94.0%', 0.940, const Color(0xFF0891B2)),
        ],
      ),
    );
  }

  Widget _buildGraphBar(String day, String val, double pct, Color color) {
    return Row(
      children: [
        SizedBox(width: 34, child: Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
        Expanded(
          child: AppLinearProgressBar(
            lineHeight: 10.0,
            percent: pct,
            progressColor: color,
            backgroundColor: AppColors.background,
            borderRadius: 10.0,
          ),
        ),
        const SizedBox(width: 12),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildActivityFeed() {
    final activities = [
      'Attendance submitted by faculty (Prof. S. Sharma - CS301)',
      'Leave requests approved for Dr. M. Anita',
      'Circulars published: Mid-Term Exam Timetable',
      'Internal marks uploaded for CS-A Distributed Systems',
      'Placement drive scheduled: Google Cloud Campus Hiring',
      'Timetable updated for Semester 5 Laboratories',
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TODAY\'S ACTIVITY FEED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Column(
            children: activities.map((act) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(act, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    final actions = [
      {'label': 'Manage Staff', 'icon': Icons.badge_outlined, 'index': 3},
      {'label': 'Students', 'icon': Icons.school_outlined, 'index': 4},
      {'label': 'Attendance', 'icon': Icons.fact_check_outlined, 'index': 10},
      {'label': 'Timetable', 'icon': Icons.calendar_month_outlined, 'index': 12},
      {'label': 'Academic Schedule', 'icon': Icons.event_note_rounded, 'index': 14},
      {'label': 'Reports', 'icon': Icons.insights_outlined, 'index': 7},
      {'label': 'Upload CO/PO/PSO', 'icon': Icons.upload_file_rounded, 'index': 16},
      {'label': 'Announcements', 'icon': Icons.campaign_outlined, 'index': 17},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUICK ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final act = actions[index];
            return ElevatedButton(
              onPressed: () {
                if (widget.onNavigate != null) widget.onNavigate!(act['index'] as int);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(act['icon'] as IconData, size: 20),
                  const SizedBox(height: 4),
                  Text(act['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
