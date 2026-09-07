import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/user_session_service.dart';

import 'package:unisphere/core/responsive/responsive_breakpoints.dart';
import 'package:unisphere/widgets/common/app_kpi_card.dart';
import 'package:unisphere/widgets/common/app_page_header.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
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
      debugPrint('Error checking admin user session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppResponsive.isDesktop(context);

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(
            title: 'Executive Institutional Overview',
            subtitle: 'Real-time metrics, student enrollment, faculty readiness, and governance actions',
            icon: Icons.dashboard_customize_rounded,
            accentColor: AppColors.primary,
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _checkUserSession(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 4 Enterprise KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1200 ? 4 : 2;
              final cardWidth = (width - ((crossAxisCount - 1) * 16)) / crossAxisCount;

              final kpiCards = [
                const AppKpiCard(
                  title: 'Total Students',
                  value: '1,240',
                  subtitle: 'Enrolled across all 12 departments',
                  trend: '+8% this year',
                  isPositiveTrend: true,
                  icon: Icons.school_rounded,
                  accentColor: AppColors.primary,
                ),
                const AppKpiCard(
                  title: 'Faculty & Staff',
                  value: '142',
                  subtitle: 'Active institutional members',
                  trend: '100% assigned',
                  isPositiveTrend: true,
                  icon: Icons.badge_outlined,
                  accentColor: AppColors.primaryLight,
                ),
                const AppKpiCard(
                  title: 'Departments',
                  value: '12',
                  subtitle: 'Governed academic faculties',
                  trend: 'All accredited',
                  isPositiveTrend: true,
                  icon: Icons.business_rounded,
                  accentColor: Color(0xFF8B5CF6),
                ),
                const AppKpiCard(
                  title: 'System Health',
                  value: '99.9%',
                  subtitle: 'Firestore & Authentication engines',
                  trend: 'Optimal status',
                  isPositiveTrend: true,
                  icon: Icons.health_and_safety_rounded,
                  accentColor: AppColors.success,
                ),
              ];

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: kpiCards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          // Multi-column Analytics & Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildTrendGraph(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildSystemPulse(),
                    const SizedBox(height: 24),
                    _buildAnnouncementsList(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildHeroStats(),
        const SizedBox(height: 24),
        _buildTrendGraph(),
        const SizedBox(height: 24),
        _buildAnnouncementsList(),
        const SizedBox(height: 24),
        _buildQuickActions(),
        const SizedBox(height: 24),
        _buildSystemPulse(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EXECUTIVE PORTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        const Text('Dashboard Overview', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(_isReturningUser ? 'Welcome back, Admin 👋 ' : 'Welcome, Admin 👋 ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text('System status: Optimal', style: TextStyle(color: Colors.blue.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroStats() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildMeshHeroCard()),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 180, // Increased from 160 to prevent overflow
            child: Column(
              children: [
                Expanded(child: _buildSmallStat('STAFF', '142', Icons.badge_outlined)),
                const SizedBox(height: 12),
                Expanded(child: _buildSmallStat('DEPTS', '12', Icons.account_tree_outlined)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeshHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 180, // Increased to match side cards
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20, child: Icon(Icons.people_alt, size: 120, color: Colors.white.withValues(alpha: 0.1))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL STUDENTS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('1,240', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('↑ 8% growth', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced vertical padding
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade600),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTrendGraph() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Student Growth Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _layeredBar('JAN', 0.6, 0.4),
              _layeredBar('FEB', 0.4, 0.2),
              _layeredBar('MAR', 0.8, 0.5),
              _layeredBar('APR', 0.5, 0.3),
              _layeredBar('MAY', 0.9, 0.6),
              _layeredBar('JUN', 0.7, 0.4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _layeredBar(String label, double h1, double h2) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(height: 80 * h1, width: 20, decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10))),
            Container(height: 80 * h2, width: 20, decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(10))),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _announceTile('Annual Science Fair 2024', Colors.blue),
        const SizedBox(height: 8),
        _announceTile('Scheduled Maintenance', Colors.orange),
      ],
    );
  }

  Widget _announceTile(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.campaign, color: color, size: 18)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('View All', style: TextStyle(fontSize: 11, color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _actionBtn('+ Add Student', Icons.person_add)),
            const SizedBox(width: 12),
            Expanded(child: _actionBtn('+ Create Notice', Icons.campaign)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _actionBtn('+ Assign Task', Icons.assignment)),
            const SizedBox(width: 12),
            Expanded(child: _actionBtn('+ Create Class', Icons.school)),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildSystemPulse() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const CircleAvatar(radius: 3, backgroundColor: Colors.indigo),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Pulse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                Text('98.4% Staff currently online', style: TextStyle(fontSize: 10, color: Colors.indigo)),
              ],
            ),
          ),
          // Custom Styled Button to avoid infinite width layout crash
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.indigo.shade700, borderRadius: BorderRadius.circular(8)),
              child: const Text('MONITOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
