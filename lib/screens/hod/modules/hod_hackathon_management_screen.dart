import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/hackathon_registration_model.dart';
import 'package:unisphere/controllers/hackathon_controller.dart';
import 'package:unisphere/controllers/hackathon_registration_controller.dart';
import 'package:unisphere/widgets/hackathons/create_hackathon_dialog.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/services/auth_service.dart';

class HodHackathonManagementScreen extends ConsumerStatefulWidget {
  const HodHackathonManagementScreen({super.key});

  @override
  ConsumerState<HodHackathonManagementScreen> createState() => _HodHackathonManagementScreenState();
}

class _HodHackathonManagementScreenState extends ConsumerState<HodHackathonManagementScreen> {
  String _selectedFilter = 'All';

  void _showTeamDetailModal(BuildContext context, HackathonRegistrationModel item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Team Roster — ${item.teamName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 12),
              Text('Hackathon: ${item.hackathonTitle}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Text('External Reg ID: ${item.externalRegistrationId} • Assigned Advisor: ${item.assignedAdvisorName}', style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Enrolled Members (Max 6):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ...item.teamMembers.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(m, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.registrationScreenshotUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: const Color(0xFFF1F5F9),
                    child: const Center(child: Text('Screenshot Proof Verified')),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hackathonsState = ref.watch(hackathonControllerProvider);
    final registrations = ref.watch(hackathonRegistrationProvider);

    final hackathons = hackathonsState.hackathons;
    final totalHackathons = hackathons.length;
    final totalTeams = registrations.length;
    final verifiedCount = registrations.where((r) => r.isVerified).length;
    final pendingCount = registrations.where((r) => r.isPendingVerification).length;
    final correctionCount = registrations.where((r) => r.isCorrectionRequired).length;

    // Year breakdown
    final year3Count = registrations.where((r) => r.year.contains('3rd')).length;
    final year2Count = registrations.where((r) => r.year.contains('2nd')).length;
    final year4Count = registrations.where((r) => r.year.contains('4th')).length;
    final year1Count = registrations.where((r) => r.year.contains('1st')).length;

    final filteredTeams = registrations.where((r) {
      if (_selectedFilter == 'Verified') return r.isVerified;
      if (_selectedFilter == 'Pending') return r.isPendingVerification;
      if (_selectedFilter == 'Correction') return r.isCorrectionRequired;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Create Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'HOD Dashboard — Hackathons & Contests Hub',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Track department participation, year/section counts, verified registrations & publish new hackathons',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final currentUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
                      final userName = (currentUser?.fullName != null && currentUser!.fullName.isNotEmpty)
                          ? currentUser.fullName
                          : 'Head of Department';
                      CreateHackathonDialog.show(
                        context,
                        userRole: 'hod',
                        userName: userName,
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Create Hackathon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Executive Counters
            Row(
              children: [
                Expanded(
                  child: _buildSummaryBox('Total Hackathons', '$totalHackathons', Icons.campaign_rounded, const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryBox('Total Teams Registered', '$totalTeams', Icons.groups_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryBox('Verified Registrations', '$verifiedCount', Icons.check_circle_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryBox('Pending Advisor Review', '$pendingCount', Icons.hourglass_top_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryBox('Correction Required', '$correctionCount', Icons.error_outline_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Year-wise & Section-wise Breakdown Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Participation Counts by Student Academic Year', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildYearProgressCard('3rd Year CSE', year3Count, totalTeams == 0 ? 1 : totalTeams, const Color(0xFF4F46E5))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildYearProgressCard('2nd Year CSE', year2Count, totalTeams == 0 ? 1 : totalTeams, const Color(0xFF10B981))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildYearProgressCard('4th Year CSE', year4Count, totalTeams == 0 ? 1 : totalTeams, const Color(0xFF3B82F6))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildYearProgressCard('1st Year CSE', year1Count, totalTeams == 0 ? 1 : totalTeams, const Color(0xFFF59E0B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hackathons List & Student Teams Roster
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Student Team Registrations & Verification Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Verified', 'Pending', 'Correction'].map((f) {
                    final isSelected = _selectedFilter == f;
                    return ChoiceChip(
                      label: Text(f == 'Correction' ? 'Correction Required' : f),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = f);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Team Registrations Table Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTeams.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final team = filteredTeams[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Text(
                        team.teamName.isNotEmpty ? team.teamName[0].toUpperCase() : 'T',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: team.isVerified
                                ? const Color(0xFFDCFCE7)
                                : team.isCorrectionRequired
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            team.verificationStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: team.isVerified
                                  ? const Color(0xFF15803D)
                                  : team.isCorrectionRequired
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Hackathon: ${team.hackathonTitle} • Lead: ${team.studentName} (${team.year} ${team.section}) • Advisor: ${team.assignedAdvisorName}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _showTeamDetailModal(context, team),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('View Details'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, String val, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildYearProgressCard(String yearLabel, int count, int total, Color color) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(yearLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$count teams', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
