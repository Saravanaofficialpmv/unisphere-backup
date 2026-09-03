import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/student_profile_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';

import 'package:unisphere/widgets/common/custom_loader.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class ClassAdvisorEditRequestsScreen extends ConsumerStatefulWidget {
  const ClassAdvisorEditRequestsScreen({super.key});

  @override
  ConsumerState<ClassAdvisorEditRequestsScreen> createState() =>
      _ClassAdvisorEditRequestsScreenState();
}

class _ClassAdvisorEditRequestsScreenState
    extends ConsumerState<ClassAdvisorEditRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Student Profile Edit Requests',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
      ),
      body: AppLiquidPullToRefresh(
        gifAsset: 'assets/tibsy-dp.gif',
        onRefresh: () async {
          ref.invalidate(firebaseFirestoreServiceProvider);
          await Future.delayed(const Duration(milliseconds: 1000));
        },
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: ref.watch(firebaseFirestoreServiceProvider).getProfileEditRequestsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Loader(label: 'Loading edit requests...'));
            }

            final rawRequests = snapshot.data ?? [];
            final requests = rawRequests
                .map((r) => ProfileEditRequest.fromMap(r, r['requestId'] ?? ''))
                .toList();

            if (requests.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.assignment_turned_in_rounded, size: 54, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text('No Pending Edit Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF475569))),
                        SizedBox(height: 4),
                        Text('All student profile edit requests have been reviewed.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildRequestCard(req, user?.uid ?? 'STAFF-001');
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(ProfileEditRequest req, String staffUid) {
    final isPending = req.status == 'pending_advisor';
    final statusColor = isPending
        ? const Color(0xFFF59E0B)
        : (req.status == 'approved' ? const Color(0xFF10B981) : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text(
                        req.studentName.isNotEmpty ? req.studentName[0].toUpperCase() : 'S',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${req.registerNumber} • ${req.department} (${req.section})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    req.status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reason: "${req.reason}"', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFF334155))),
                const SizedBox(height: 12),
                const Text('Requested Field Changes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                ...req.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('• ${item.label}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          Text(item.currentValue, style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Text(item.requestedValue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ],
                      ),
                    )),
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _processRequest(req, false, staffUid),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _processRequest(req, true, staffUid),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Approve All Fields', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processRequest(ProfileEditRequest req, bool isApprove, String staffUid) async {
    final updatedItems = req.items.map((item) {
      final map = item.toMap();
      map['status'] = isApprove ? 'approved' : 'rejected';
      return map;
    }).toList();

    await ref.read(firebaseFirestoreServiceProvider).processProfileEditRequest(
          requestId: req.requestId,
          studentUid: req.studentUid,
          updatedItems: updatedItems,
          overallStatus: isApprove ? 'approved' : 'rejected',
          advisorComments: isApprove ? 'Approved by Class Advisor' : 'Rejected by Class Advisor',
          advisorUid: staffUid,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApprove ? '✅ Edit request approved! Student profile updated.' : '❌ Edit request rejected.'),
          backgroundColor: isApprove ? const Color(0xFF10B981) : Colors.red,
        ),
      );
    }
  }
}
