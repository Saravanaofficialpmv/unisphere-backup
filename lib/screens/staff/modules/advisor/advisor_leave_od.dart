import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/repositories/staff_repository.dart';

class AdvisorLeaveODSection extends ConsumerStatefulWidget {
  final VoidCallback? onViewAll;

  const AdvisorLeaveODSection({super.key, this.onViewAll});

  @override
  ConsumerState<AdvisorLeaveODSection> createState() => _AdvisorLeaveODSectionState();
}

class _AdvisorLeaveODSectionState extends ConsumerState<AdvisorLeaveODSection> {
  final Map<String, String> _processedStatus = {};

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(advisorLeaveODRequestsStreamProvider);
    final requests = requestsAsync.valueOrNull ?? [];

    final defaultRequests = [
      {
        'id': 'LOD-01',
        'studentName': 'Arun Kumar',
        'type': 'Medical Leave',
        'duration': 'Sep 04 – Sep 05',
        'avatar': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100',
      },
      {
        'id': 'LOD-02',
        'studentName': 'Priya Sharma',
        'type': 'On Duty',
        'duration': 'Sep 06',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      },
    ];

    final displayItems = requests.isNotEmpty
        ? requests.take(2).map((r) => {
              'id': r['id']?.toString() ?? 'LOD-X',
              'studentName': r['studentName']?.toString() ?? 'Student',
              'type': r['type']?.toString() ?? 'Leave',
              'duration': r['duration']?.toString() ?? 'Today',
              'avatar': r['avatar']?.toString() ?? '',
            }).toList()
        : defaultRequests;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'LEAVE / OD REQUESTS',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '4 Pending',
                        style: GoogleFonts.manrope(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onViewAll != null)
                InkWell(
                  onTap: widget.onViewAll,
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.staffRole,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.staffRole),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayItems.map((item) {
            final id = item['id'] as String;
            final studentName = item['studentName'] as String;
            final type = item['type'] as String;
            final duration = item['duration'] as String;
            final avatar = item['avatar'] as String;
            final status = _processedStatus[id];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? Text(
                            studentName.isNotEmpty ? studentName[0] : 'S',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.staffRole,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$type\n$duration',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'Approved'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: status == 'Approved'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 28,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _processedStatus[id] = 'Approved';
                              });
                              ref
                                  .read(staffRepositoryProvider)
                                  .updateLeaveODStatus(requestId: id, status: 'Approved');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF16A34A)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Approve',
                              style: GoogleFonts.manrope(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 28,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _processedStatus[id] = 'Rejected';
                              });
                              ref
                                  .read(staffRepositoryProvider)
                                  .updateLeaveODStatus(requestId: id, status: 'Rejected');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Reject',
                              style: GoogleFonts.manrope(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
