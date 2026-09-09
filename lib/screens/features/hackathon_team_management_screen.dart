import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/hackathon_model.dart';
import 'package:unisphere/models/hackathon_registration_model.dart';
import 'package:unisphere/controllers/hackathon_registration_controller.dart';
import 'package:unisphere/services/auth_service.dart';

class HackathonTeamManagementScreen extends ConsumerWidget {
  final HackathonModel hackathon;

  const HackathonTeamManagementScreen({super.key, required this.hackathon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final allRegs = ref.watch(hackathonRegistrationProvider);
    final reg = allRegs.cast<HackathonRegistrationModel?>().firstWhere(
      (r) => r?.hackathonId == hackathon.id,
      orElse: () => null,
    );

    final teamName = reg?.teamName ?? 'My Hackathon Team';
    final leadName = reg?.studentName ?? user?.fullName ?? user?.name ?? 'Team Leader';
    final leadEmail = reg?.email ?? user?.email ?? '';
    final members = reg?.teamMembers ?? [leadName];
    final status = reg != null
        ? (reg.isVerified
            ? 'Confirmed & Ready for Check-in'
            : (reg.verificationStatus.isNotEmpty ? reg.verificationStatus.toUpperCase() : reg.status.toUpperCase()))
        : 'Registered';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Team Management Portal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('REGISTERED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('Reg ID: ${hackathon.registrationId ?? "REG-CONFIRMED"}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(hackathon.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Organized by ${hackathon.organizer}', style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Team Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMetaRow('Team Name', teamName),
                  const Divider(height: 20),
                  _buildMetaRow('Team Lead', '$leadName${leadEmail.isNotEmpty ? ' ($leadEmail)' : ''}'),
                  const Divider(height: 20),
                  _buildMetaRow('Status', status),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Roster & Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),

            for (int i = 0; i < members.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMemberTile(
                  members[i],
                  i == 0 ? 'Team Leader' : 'Team Member',
                  i == 0 ? leadEmail : 'Member',
                  i == 0,
                ),
              ),
            const SizedBox(height: 24),

            const Text('Project Submission Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_upload_rounded, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text('Repository & Demo Links', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Submissions will open 6 hours before the hackathon end date. Make sure your GitHub repository is public.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('Manage GitHub / Devpost Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            val,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(String name, String role, String email, bool isLead) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isLead ? const Color(0xFF7C3AED) : const Color(0xFF3B82F6),
            radius: 18,
            child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          if (isLead)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(6)),
              child: const Text('LEAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
            ),
        ],
      ),
    );
  }
}
