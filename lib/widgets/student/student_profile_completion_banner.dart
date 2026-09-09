import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/widgets/student/student_profile_completion_sheet.dart';

/// Reusable profile completion banner that seamlessly works across mobile and desktop.
/// Automatically listens to live student profile status from Firestore.
class StudentProfileCompletionBanner extends ConsumerStatefulWidget {
  final EdgeInsetsGeometry? margin;

  const StudentProfileCompletionBanner({
    super.key,
    this.margin,
  });

  /// Static helper to trigger the profile completion sheet from anywhere.
  static void openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StudentProfileCompletionSheet(),
    );
  }

  @override
  ConsumerState<StudentProfileCompletionBanner> createState() =>
      _StudentProfileCompletionBannerState();
}

class _StudentProfileCompletionBannerState
    extends ConsumerState<StudentProfileCompletionBanner> {
  bool _dismissedVerifiedBanner = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value ??
        ref.watch(authServiceProvider).currentUser;

    if (user?.role != UserRole.student) return const SizedBox.shrink();

    final regNo = user?.metadata?['registerNumber']?.toString().trim() ?? '';
    final studentId = regNo.isNotEmpty ? regNo : (user?.uid ?? '');

    return StreamBuilder<Map<String, dynamic>?>(
      stream: ref
          .watch(firebaseFirestoreServiceProvider)
          .getFullStudentProfileStream(studentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final profileDoc = snapshot.data ?? {};
        final meta = user?.metadata ?? {};

        // Resolve latest status from live Firestore doc or user metadata
        final status = (profileDoc['verificationStatus'] ??
                profileDoc['completionStatus'] ??
                meta['verificationStatus'] ??
                meta['profileCompletionStatus'] ??
                'incomplete')
            .toString()
            .toLowerCase();

        // 1. If submitted / pending HOD verification, hide banner
        final isPending = status == 'pending_hod' ||
            status == 'submitted' ||
            status == 'pending' ||
            status == 'under_review';
        if (isPending) {
          return const SizedBox.shrink();
        }

        // 2. If approved / verified, show badge for 24h, then auto-remove
        final isApproved = status == 'approved' || status == 'verified';
        if (isApproved) {
          if (_dismissedVerifiedBanner) return const SizedBox.shrink();

          DateTime? verifiedAt;
          final rawVerified = profileDoc['verifiedAt'] ??
              meta['verifiedAt'] ??
              meta['approvedAt'];
          if (rawVerified is String) {
            verifiedAt = DateTime.tryParse(rawVerified);
          } else if (rawVerified is Timestamp) {
            verifiedAt = rawVerified.toDate();
          }

          if (verifiedAt != null) {
            final elapsed = DateTime.now().difference(verifiedAt);
            if (elapsed.inHours >= 24) {
              return const SizedBox.shrink();
            }
          }

          return Container(
            margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBBF7D0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🟢 360° Profile Verified & Approved',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your profile details have been verified and approved by HOD.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  tooltip: 'Dismiss',
                  onPressed: () {
                    setState(() {
                      _dismissedVerifiedBanner = true;
                    });
                  },
                ),
              ],
            ),
          );
        }

        // 3. If rejected, show revision required banner
        final isRejected = status == 'rejected' ||
            status == 'needs_revision' ||
            status == 'correction_required';
        if (isRejected) {
          final reason = profileDoc['rejectionReason']?.toString() ??
              meta['rejectionReason']?.toString() ??
              'HOD requested revision of your uploaded profile details.';

          return Container(
            margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔴 Profile Revision Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Reason: $reason',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => StudentProfileCompletionBanner.openSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Edit & Resubmit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 4. Default: Incomplete / Draft -> Show "Complete Your Profile"
        return Container(
          width: double.infinity,
          margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final actionButton = ElevatedButton(
                onPressed: () => StudentProfileCompletionBanner.openSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  minimumSize: const Size(0, 38),
                ),
                child: const Text(
                  'Complete Now →',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment_ind_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '🎓 Complete Your Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fill in your personal, academic, accommodation & transport details for HOD verification.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: actionButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_ind_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎓 Complete Your Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Fill in your personal, academic, accommodation & transport details for HOD verification.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  actionButton,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
