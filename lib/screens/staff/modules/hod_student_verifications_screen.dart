import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

final hodVerificationsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseFirestoreServiceProvider).getPendingHodVerificationsStream();
});

class HodStudentVerificationsScreen extends ConsumerStatefulWidget {
  const HodStudentVerificationsScreen({super.key});

  @override
  ConsumerState<HodStudentVerificationsScreen> createState() => _HodStudentVerificationsScreenState();
}

class _HodStudentVerificationsScreenState extends ConsumerState<HodStudentVerificationsScreen> {
  String _selectedFilter = 'pending_hod'; // 'all', 'pending_hod', 'approved', 'rejected'

  @override
  Widget build(BuildContext context) {
    final verificationsAsync = ref.watch(hodVerificationsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('HOD Profile Verifications', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('Pending HOD', 'pending_hod', const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved', const Color(0xFF16A34A)),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected', const Color(0xFFDC2626)),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all', const Color(0xFF2563EB)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Profiles List
          Expanded(
            child: AppLiquidPullToRefresh(
              gifAsset: 'assets/tibsy-dp.gif',
              onRefresh: () async {
                ref.invalidate(hodVerificationsStreamProvider);
                await Future.delayed(const Duration(milliseconds: 1000));
              },
              child: verificationsAsync.when(
                loading: () => const Center(child: Loader(label: 'Loading student verifications...')),
                error: (err, stack) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: SizedBox(
                    height: 300,
                    child: Center(child: Text('Error loading profiles: $err')),
                  ),
                ),
                data: (profiles) {
                  final filtered = profiles.where((p) {
                    final vStatus = p['verificationStatus']?.toString() ?? p['completionStatus']?.toString() ?? 'pending_hod';
                    if (_selectedFilter == 'all') return true;
                    if (_selectedFilter == 'pending_hod') {
                      return vStatus == 'pending_hod' || vStatus == 'submitted' || vStatus == 'pending';
                    }
                    return vStatus == _selectedFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: SizedBox(
                        height: 350,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_user_rounded, size: 64, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 16),
                              Text(
                                'No student profiles in "$_selectedFilter" queue',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      final studentUid = item['studentUid']?.toString() ?? docId(item);
                      final personal = item['personal'] as Map<String, dynamic>? ?? {};
                      final name = personal['fullName']?.toString() ?? item['studentName']?.toString() ?? 'Student';
                      final regNo = personal['registerNumber']?.toString() ?? item['registerNumber']?.toString() ?? 'N/A';
                      final dept = personal['department']?.toString() ?? item['department']?.toString() ?? 'Department';
                      final email = personal['collegeEmail']?.toString() ?? item['collegeEmail']?.toString() ?? '';
                      final photoUrl = personal['profilePhotoUrl']?.toString();
                      final vStatus = item['verificationStatus']?.toString() ?? 'pending_hod';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFEFF6FF),
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? const Icon(Icons.person_rounded, color: Color(0xFF2563EB))
                              : null,
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                        subtitle: Text('$regNo • $dept\n$email', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        trailing: _buildStatusBadge(vStatus),
                        children: [
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailSection('👤 Personal', [
                                  'DOB: ${personal['dateOfBirth'] ?? 'N/A'}',
                                  'Gender: ${personal['gender'] ?? 'N/A'}',
                                  'Blood Group: ${personal['bloodGroup'] ?? 'N/A'}',
                                  'Community: ${personal['community'] ?? 'N/A'} (${personal['religion'] ?? 'N/A'})',
                                ]),
                                const SizedBox(height: 10),
                                _buildDetailSection('📞 Contact', [
                                  'Mobile: ${item['contact']?['primaryMobile'] ?? 'N/A'}',
                                  'Address: ${item['contact']?['permanentAddress']?['addressLine1'] ?? 'N/A'}, ${item['contact']?['permanentAddress']?['city'] ?? ''}',
                                ]),
                                const SizedBox(height: 10),
                                _buildDetailSection('👨‍👩‍👧 Parents', [
                                  'Father: ${item['parents']?['father']?['name'] ?? 'N/A'} (${item['parents']?['father']?['mobileNumber'] ?? ''})',
                                  'Mother: ${item['parents']?['mother']?['name'] ?? 'N/A'} (${item['parents']?['mother']?['mobileNumber'] ?? ''})',
                                ]),
                                const SizedBox(height: 10),
                                _buildDetailSection('📄 Step 7 Documents', [
                                  if (item['documents'] is List && (item['documents'] as List).isNotEmpty)
                                    ...((item['documents'] as List).map((doc) {
                                      final dMap = doc is Map ? doc : {};
                                      final fName = dMap['fileName']?.toString() ?? '';
                                      final dName = dMap['name']?.toString() ?? 'Document';
                                      return fName.isNotEmpty ? '✅ $dName ($fName)' : '⚠️ $dName: Pending Upload';
                                    }))
                                  else
                                    'No documents submitted',
                                ]),
                                const SizedBox(height: 14),

                                if (vStatus == 'pending_hod' || vStatus == 'submitted' || vStatus == 'pending')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            await ref.read(firebaseFirestoreServiceProvider).approveStudentProfileByHod(
                                                  studentUid: studentUid,
                                                  hodUid: currentUser?.uid ?? 'HOD-UID',
                                                  hodName: currentUser?.name ?? 'HOD Officer',
                                                );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('🟢 Profile approved for $name!'), backgroundColor: const Color(0xFF16A34A)),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                                          label: const Text('Approve & Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showRejectDialog(context, studentUid, name, currentUser?.uid, currentUser?.name),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFDC2626),
                                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          icon: const Icon(Icons.cancel_rounded, size: 18),
                                          label: const Text('Reject Revision', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ),
        ],
      ),
    );
  }

  String docId(Map<String, dynamic> item) {
    return item['uid']?.toString() ?? item['studentUid']?.toString() ?? 'N/A';
  }

  Widget _buildFilterChip(String label, String value, Color activeColor) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'approved' || status == 'verified') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
        child: const Text('Approved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
      );
    } else if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
        child: const Text('Rejected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
      child: const Text('Pending HOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
    );
  }

  Widget _buildDetailSection(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        ...lines.map((l) => Text(l, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
      ],
    );
  }

  void _showRejectDialog(BuildContext context, String studentUid, String name, String? hodUid, String? hodName) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reject Profile for $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection (e.g. Invalid 10th mark sheet photo)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              await ref.read(firebaseFirestoreServiceProvider).rejectStudentProfileByHod(
                    studentUid: studentUid,
                    hodUid: hodUid ?? 'HOD-UID',
                    hodName: hodName ?? 'HOD Officer',
                    reason: reasonCtrl.text.trim(),
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🔴 Profile rejected for $name'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Submit Rejection'),
          ),
        ],
      ),
    );
  }
}
