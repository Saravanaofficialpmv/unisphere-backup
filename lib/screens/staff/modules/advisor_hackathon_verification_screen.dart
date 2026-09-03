import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/hackathon_registration_model.dart';
import 'package:unisphere/controllers/hackathon_registration_controller.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class AdvisorHackathonVerificationScreen extends ConsumerStatefulWidget {
  const AdvisorHackathonVerificationScreen({super.key});

  @override
  ConsumerState<AdvisorHackathonVerificationScreen> createState() => _AdvisorHackathonVerificationScreenState();
}

class _AdvisorHackathonVerificationScreenState extends ConsumerState<AdvisorHackathonVerificationScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showScreenshotDialog(BuildContext context, HackathonRegistrationModel item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'External Registration Proof — ${item.teamName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Ext Reg ID: ${item.externalRegistrationId} • Hackathon: ${item.hackathonTitle}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.registrationScreenshotUrl,
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_rounded, color: Color(0xFF94A3B8), size: 40),
                          SizedBox(height: 8),
                          Text('Registration Screenshot Uploaded (Proof Verified)', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close Preview'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCorrectionDialog(BuildContext context, HackathonRegistrationModel item) {
    final noteCtrl = TextEditingController(text: 'Please upload a clearer screenshot showing your External Registration ID and Team Name clearly.');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            const Text('Request Correction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify reason/instructions for team "${item.teamName}" (${item.studentName}):', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter correction requirement notes...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(hackathonRegistrationProvider.notifier).requestCorrection(item.id, noteCtrl.text.trim());
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Correction requested for team "${item.teamName}". Student notified.'),
                  backgroundColor: const Color(0xFFF59E0B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Correction Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registrations = ref.watch(hackathonRegistrationProvider);

    final pendingCount = registrations.where((r) => r.isPendingVerification).length;
    final verifiedCount = registrations.where((r) => r.isVerified).length;
    final correctionCount = registrations.where((r) => r.isCorrectionRequired).length;

    final filteredList = registrations.where((r) {
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Pending' && r.isPendingVerification) ||
          (_selectedFilter == 'Verified' && r.isVerified) ||
          (_selectedFilter == 'Correction' && r.isCorrectionRequired);
      final matchesSearch = r.teamName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.hackathonTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.externalRegistrationId.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AppLiquidPullToRefresh(
        gifAsset: 'assets/tibsy-dp.gif',
        onRefresh: () async {
          ref.invalidate(hackathonRegistrationProvider);
          await Future.delayed(const Duration(milliseconds: 1000));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF38BDF8), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Advisor Dashboard — Hackathon Verifications',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Review external registration screenshot proofs & verify student team details (Year & Section matching)',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Pending Verifications',
                    '$pendingCount',
                    Icons.hourglass_top_rounded,
                    const Color(0xFFF59E0B),
                    const Color(0xFFFFFBEB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Verified Teams',
                    '$verifiedCount',
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                    const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Correction Required',
                    '$correctionCount',
                    Icons.error_outline_rounded,
                    const Color(0xFFEF4444),
                    const Color(0xFFFEF2F2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Submissions',
                    '${registrations.length}',
                    Icons.groups_rounded,
                    const Color(0xFF6366F1),
                    const Color(0xFFEEF2FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by team name, student, external reg ID...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Pending', 'Verified', 'Correction'].map((f) {
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
            const SizedBox(height: 20),

            // Registration Cards List
            if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF94A3B8)),
                    SizedBox(height: 12),
                    Text('No team registrations found matching your criteria.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  return _buildRegistrationVerificationCard(context, item);
                },
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationVerificationCard(BuildContext context, HackathonRegistrationModel item) {
    Color statusBg;
    Color statusColor;
    String statusLabel;

    if (item.isVerified) {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
      statusLabel = '🟢 VERIFIED BY ADVISOR';
    } else if (item.isCorrectionRequired) {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFFB91C1C);
      statusLabel = '🔴 CORRECTION REQUIRED';
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFB45309);
      statusLabel = '🟡 PENDING VERIFICATION';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Team Name & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.teamName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('Hackathon: ${item.hackathonTitle}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details Grid (Student Lead, Roll, Year & Section, Ext Reg ID, Assigned Advisor)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team Leader & ID', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${item.studentName} (${item.studentId})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Year & Section', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${item.year} — ${item.section}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('External Reg ID', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(item.externalRegistrationId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assigned Advisor', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(item.assignedAdvisorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Team Members List (Up to 6)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text('Team Members (${item.teamMembers.length} / Max 6):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: item.teamMembers.map((m) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: Text(m, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4338CA))),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Registration Screenshot Proof Preview Box & Actions
          Row(
            children: [
              // Screenshot Preview Thumbnail
              InkWell(
                onTap: () => _showScreenshotDialog(context, item),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_outlined, color: Color(0xFF4F46E5), size: 18),
                      const SizedBox(width: 6),
                      const Text('View Screenshot Proof', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Action Buttons
              if (!item.isVerified)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(hackathonRegistrationProvider.notifier).verifyRegistration(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Registration for team "${item.teamName}" verified & approved!'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Verify & Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              const SizedBox(width: 10),

              OutlinedButton.icon(
                onPressed: () => _showCorrectionDialog(context, item),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Request Correction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          // Correction Notes Banner if Correction Required
          if (item.isCorrectionRequired && item.advisorCorrectionNotes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Correction Reason Sent: "${item.advisorCorrectionNotes}"',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
