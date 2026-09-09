import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/theme/app_animations_kit.dart';
import 'package:unisphere/widgets/common/app_progress_indicators.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';
import 'package:unisphere/models/attendance_model.dart';
import 'package:unisphere/providers/attendance_system_provider.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/providers/post_od_provider.dart';
import 'package:unisphere/services/auth_service.dart';

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const StudentAttendanceScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends ConsumerState<StudentAttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _historyFilter = 'All';
  String _searchQuery = '';

  // Track expanded subject card index
  int? _expandedSubjectIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (!mounted) return;
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showLeaveApplicationModal() {
    final reasonController = TextEditingController();
    final eventNameController = TextEditingController(text: 'Inter-College AI Hackathon 2026');
    String leaveType = 'On Duty (OD)';
    String startDate = '14 Aug 2026';
    String endDate = '16 Aug 2026';

    String letterFileName = 'Official_HOD_OD_Permission_Letter.pdf';
    bool hasLetter = true;

    String screenshotFileName = 'Event_Registration_Confirmation_Screenshot.png';
    bool hasScreenshot = true;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.90,
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF2563EB), size: 24),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submit OD / Leave Request Panel',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Attach HOD Request Letter & Registration Proof',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Application Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: leaveType,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                        items: ['On Duty (OD)', 'Event / Sports OD', 'Medical Leave', 'Casual Leave']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => leaveType = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      const Text('Event / Institution Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: eventNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. IIT Madras Tech Fest, National Hackathon...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Text(startDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('End Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_rounded, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Text(endDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text('Reason & Activity Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe event participation details, track name, role...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('REQUIRED MANDATORY DOCUMENTS FOR HOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF), letterSpacing: 0.8)),
                      const SizedBox(height: 10),

                      // 📄 DOCUMENT 1: OFFICIAL OD REQUEST LETTER TO HOD
                      const Text('1. Official OD Permission Letter (PDF / DOC)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          setModalState(() {
                            hasLetter = !hasLetter;
                            letterFileName = 'HOD_OD_Permission_Request_Letter.pdf';
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasLetter ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: hasLetter ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1), width: hasLetter ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasLetter ? Icons.picture_as_pdf_rounded : Icons.note_add_rounded,
                                color: hasLetter ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasLetter ? letterFileName : 'Attach Signed OD Request Letter for HOD',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: hasLetter ? const Color(0xFF1E3A8A) : const Color(0xFF475569),
                                      ),
                                    ),
                                    Text(
                                      hasLetter ? 'Letter attached (PDF • 240 KB)' : 'Tap to select PDF letter addressed to HOD',
                                      style: TextStyle(fontSize: 10.5, color: hasLetter ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                hasLetter ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                color: hasLetter ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 📸 DOCUMENT 2: EVENT REGISTRATION SCREENSHOT PROOF
                      const Text('2. Event Registration Screenshot (Image Proof)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          setModalState(() {
                            hasScreenshot = !hasScreenshot;
                            screenshotFileName = 'Event_Registration_Pass_Screenshot.png';
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasScreenshot ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: hasScreenshot ? const Color(0xFF10B981) : const Color(0xFFCBD5E1), width: hasScreenshot ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasScreenshot ? Icons.image_rounded : Icons.add_a_photo_rounded,
                                color: hasScreenshot ? const Color(0xFF059669) : const Color(0xFF64748B),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasScreenshot ? screenshotFileName : 'Attach Registration Pass Screenshot',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: hasScreenshot ? const Color(0xFF065F46) : const Color(0xFF475569),
                                      ),
                                    ),
                                    Text(
                                      hasScreenshot ? 'Registration proof attached (PNG • 1.2 MB)' : 'Tap to upload ticket or email registration proof',
                                      style: TextStyle(fontSize: 10.5, color: hasScreenshot ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                hasScreenshot ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                color: hasScreenshot ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final authUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
                    final meta = authUser?.metadata ?? {};
                    final stuName = (authUser?.fullName != null && authUser!.fullName.trim().isNotEmpty)
                        ? authUser.fullName.trim()
                        : 'Student';
                    final stuId = authUser?.uid ?? 'student_1';
                    final regNo = (meta['registerNumber'] ?? meta['regNo'] ?? stuId).toString().trim();
                    final deptId = (meta['departmentId'] ?? meta['department'] ?? 'CSE').toString().trim();
                    final section = (meta['section'] ?? 'CS-A').toString().trim();

                    final req = LeaveRequestModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      studentId: regNo.isNotEmpty ? regNo : stuId,
                      studentName: stuName,
                      registerNumber: regNo,
                      departmentId: deptId,
                      section: section,
                      role: 'Student',
                      type: leaveType,
                      duration: '$startDate - $endDate (3 Days)',
                      reason: reasonController.text.trim().isEmpty
                          ? '${eventNameController.text} - Event OD Request'
                          : '${eventNameController.text}: ${reasonController.text.trim()}',
                      status: 'Pending Approval',
                      appliedDate: 'Today',
                      hasAttachment: hasLetter || hasScreenshot,
                      requestLetterUrl: hasLetter ? letterFileName : null,
                      registrationScreenshotUrl: hasScreenshot ? screenshotFileName : null,
                    );

                    ref.read(attendanceSystemProvider.notifier).addLeaveRequest(req);

                    ref.read(notificationProvider.notifier).addNotification(
                          title: '📄 OD Leave Request Submitted to HOD',
                          category: 'Academic',
                          summary: 'OD Request submitted for ${eventNameController.text} with HOD Request Letter & Registration Screenshot attached.',
                          fullDetails: 'OD Request sent for HOD verification with official request letter and event registration proof.',
                          icon: Icons.assignment_turned_in_rounded,
                          iconColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFEFF6FF),
                          badgeText: 'OD PENDING',
                          badgeColor: const Color(0xFFD97706),
                          badgeTextColor: Colors.white,
                        );

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('OD Request submitted to HOD with Request Letter & Registration Screenshot!'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Submit OD Request to HOD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostOdLeaderFormModal() {
    final eventNameCtrl = TextEditingController();
    final prizeTitleCtrl = TextEditingController();
    final cashPrizeCtrl = TextEditingController();
    final lossReasonCtrl = TextEditingController();
    String outcomeChoice = 'Won'; // 'Won' or 'Lost'
    String eventCategory = 'Hackathon & Coding';
    String teamCertificateFile = '';

    final currentUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    final leaderName = currentUser?.fullName ?? currentUser?.name ?? 'Student';
    final leaderId = (currentUser?.metadata?['registerNumber'] ?? currentUser?.metadata?['regNo'] ?? currentUser?.uid ?? '').toString();

    final selectedMembers = <Map<String, String>>[
      if (leaderId.isNotEmpty)
        {'uid': leaderId, 'name': '$leaderName (Leader)', 'rollNo': leaderId},
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: Color(0xFF1D4ED8), size: 24),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Post-OD Event Return Form', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('Team Leader Outcome & Certificate Submission', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Event Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: eventCategory,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                        items: ['Hackathon & Coding', 'Technical Paper Presentation', 'Robotics & Hardware Expo', 'Sports & Cultural Fest']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => eventCategory = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      const Text('Event / Competition Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: eventNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter institution & event name...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('EVENT OUTCOME STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF), letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => outcomeChoice = 'Won'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: outcomeChoice == 'Won' ? const Color(0xFFECFDF5) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: outcomeChoice == 'Won' ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                                    width: outcomeChoice == 'Won' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.military_tech_rounded, color: outcomeChoice == 'Won' ? const Color(0xFF059669) : const Color(0xFF64748B), size: 24),
                                    const SizedBox(height: 4),
                                    Text('🏆 WON / PRIZE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: outcomeChoice == 'Won' ? const Color(0xFF047857) : const Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => outcomeChoice = 'Lost'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: outcomeChoice == 'Lost' ? const Color(0xFFFEF2F2) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: outcomeChoice == 'Lost' ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                    width: outcomeChoice == 'Lost' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.flag_rounded, color: outcomeChoice == 'Lost' ? const Color(0xFFDC2626) : const Color(0xFF64748B), size: 24),
                                    const SizedBox(height: 4),
                                    Text('❌ LOST / PARTICIPATED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: outcomeChoice == 'Lost' ? const Color(0xFFB91C1C) : const Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (outcomeChoice == 'Won') ...[
                        const Text('Prize / Merit Position', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: prizeTitleCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. 1st Place Winner, 2nd Runner Up',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Cash Reward / Trophy Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: cashPrizeCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. ₹25,000 cash prize & Winner Shield',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Team Winner Certificate Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              teamCertificateFile = 'IITM_Hackathon_Winner_Certificate.pdf';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(teamCertificateFile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                                      const Text('Tap to attach/change team certificate scan', style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6))),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // MANDATORY LOSS REASON ANALYSIS
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Mandatory HOD Requirement: Explain the technical issues, jury feedback, or reasons for not placing in top positions.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Reason for Loss & Post-Mortem Analysis *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: lossReasonCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter detailed post-mortem report (e.g. GPU memory limits during live demo, prototype latency, jury suggestions)...',
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Text('Registered Team Members (Notified upon submission)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      ...selectedMembers.map((m) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 16, color: Color(0xFF2563EB)),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${m['name']} (${m['rollNo']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                if (m['uid'] == leaderId)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('LEADER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                  ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (outcomeChoice == 'Lost' && lossReasonCtrl.text.trim().length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill out the mandatory Reason for Loss / Post-Mortem Analysis before submitting.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }

                    ref.read(postOdProvider.notifier).submitLeaderOutcome(
                          odRequestId: 'l2',
                          eventName: eventNameCtrl.text,
                          eventCategory: eventCategory,
                          eventDate: DateTime.now().toIso8601String().split('T').first,
                          teamLeaderUid: leaderId,
                          teamLeaderName: '$leaderName (Leader)',
                          teamLeaderRollNo: leaderId,
                          outcome: outcomeChoice,
                          prizeTitle: outcomeChoice == 'Won' ? prizeTitleCtrl.text : null,
                          cashPrizeAmount: outcomeChoice == 'Won' ? cashPrizeCtrl.text : null,
                          lossReason: outcomeChoice == 'Lost' ? lossReasonCtrl.text : null,
                          teamCertificateUrl: outcomeChoice == 'Won' ? teamCertificateFile : null,
                          members: selectedMembers,
                        );

                    ref.read(notificationProvider.notifier).addNotification(
                          title: outcomeChoice == 'Won' ? '🏆 OD Outcome Filed: WON 1st Prize!' : 'OD Outcome Filed: Post-Mortem Submitted',
                          category: 'Academic',
                          summary: outcomeChoice == 'Won'
                              ? 'Team Leader $leaderName reported WON for ${eventNameCtrl.text}. Teammates must upload certificates.'
                              : 'Team Leader $leaderName filed Post-OD Loss Analysis report to HOD.',
                          fullDetails: 'OD Return Status filed for ${eventNameCtrl.text}. HOD verification pending.',
                          icon: Icons.military_tech_rounded,
                          iconColor: outcomeChoice == 'Won' ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          iconBgColor: outcomeChoice == 'Won' ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
                          badgeText: 'OD UPDATE',
                          badgeColor: const Color(0xFF2563EB),
                          badgeTextColor: Colors.white,
                        );

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(outcomeChoice == 'Won'
                            ? 'OD Outcome "WON" submitted! Teammates have been notified to upload certificates.'
                            : 'Post-OD Loss Analysis report submitted to HOD successfully.'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Submit Post-OD Outcome to HOD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberCertificateUploadSheet(BuildContext context, String outcomeId, String eventName) {
    String filename = 'Alex_Individual_Merit_Cert.pdf';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFF2563EB), size: 24),
                      SizedBox(width: 10),
                      Text('Upload Teammate Certificate', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Event: $eventName', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              const Text('Attach Your Individual Certificate Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 8),

              InkWell(
                onTap: () {
                  setModalState(() {
                    filename = 'Individual_Participation_Certificate.pdf';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(filename, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                            const Text('Tap to choose clear PDF scan of certificate', style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6))),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final u = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
                    final myUid = (u?.metadata?['registerNumber'] ?? u?.metadata?['regNo'] ?? u?.uid ?? '').toString();
                    ref.read(postOdProvider.notifier).submitMemberCertificate(
                          outcomeId: outcomeId,
                          memberUid: myUid,
                          certificateUrl: filename,
                        );

                    ref.read(notificationProvider.notifier).addNotification(
                          title: '📜 Certificate Uploaded for HOD Approval',
                          category: 'Academic',
                          summary: 'Individual certificate uploaded for $eventName. HOD review pending.',
                          fullDetails: 'Certificate submitted for OD approval.',
                          icon: Icons.workspace_premium_rounded,
                          iconColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFEFF6FF),
                          badgeText: 'CERTIFICATE',
                          badgeColor: const Color(0xFF10B981),
                          badgeTextColor: Colors.white,
                        );

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Individual certificate submitted successfully! HOD verification in progress.'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Submit Certificate for HOD Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemState = ref.watch(attendanceSystemProvider);
    final semDataList = systemState.studentSemesters;
    final activeSemData = systemState.selectedSemester;

    final double overallPercentage = activeSemData.attendancePercentage / 100.0;
    final int overallAttended = activeSemData.attendedWorkingDays;
    final int overallTotalDays = activeSemData.totalWorkingDays;
    final String statusStr = activeSemData.statusLabel;
    final String safeMarginStr = activeSemData.safeMarginText;
    final bool isCurrentSem = activeSemData.isCurrentSemester;

    final filteredLogs = systemState.attendanceLogs.where((l) {
      final matchesFilter = _historyFilter == 'All' || l.status.label == _historyFilter;
      final matchesQuery = _searchQuery.isEmpty ||
          l.subjectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              UnisphereHeaderCard(
                title: 'Attendance Tracker',
                subtitle: 'Monitor your course attendance and records',
                onBack: () => _handleBack(context),
                rightActions: [
                  IconButton(
                    icon: const Icon(Icons.note_add_outlined, color: Colors.white70),
                    tooltip: 'Apply Leave',
                    onPressed: _showLeaveApplicationModal,
                  ),
                ],
                bottomWidget: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFBFDBFE),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Daily Attendance'),
                      Tab(text: 'History Log'),
                      Tab(text: 'Leave & OD'),
                    ],
                  ),
                ),
              ),

              // Tab Content Body
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: Daily Basis Attendance Log
                    _buildDailyAttendanceTab(
                      semDataList: semDataList,
                      selectedSemData: activeSemData,
                      dailyLogs: systemState.dailyLogs,
                      summaryCard: _buildSummaryCard(
                        overallPercentage: overallPercentage,
                        overallAttended: overallAttended,
                        overallTotalDays: overallTotalDays,
                        statusStr: statusStr,
                        safeMarginStr: safeMarginStr,
                        isCurrentSem: isCurrentSem,
                      ),
                    ),

                    // Tab 1: History Log
                    _buildHistoryLogTab(
                      filteredLogs: filteredLogs,
                      totalLogsCount: systemState.attendanceLogs.length,
                      summaryCard: _buildSummaryCard(
                        overallPercentage: overallPercentage,
                        overallAttended: overallAttended,
                        overallTotalDays: overallTotalDays,
                        statusStr: statusStr,
                        safeMarginStr: safeMarginStr,
                        isCurrentSem: isCurrentSem,
                      ),
                    ),

                    // Tab 2: Leave & OD Tracker
                    _buildLeaveTrackerTab(
                      leaveRequests: systemState.leaveRequests,
                      summaryCard: _buildSummaryCard(
                        overallPercentage: overallPercentage,
                        overallAttended: overallAttended,
                        overallTotalDays: overallTotalDays,
                        statusStr: statusStr,
                        safeMarginStr: safeMarginStr,
                        isCurrentSem: isCurrentSem,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double overallPercentage,
    required int overallAttended,
    required int overallTotalDays,
    required String statusStr,
    required String safeMarginStr,
    required bool isCurrentSem,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: overallPercentage.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animPercent, _) {
              return AppCircularGauge(
                radius: 42.0,
                lineWidth: 7.0,
                percent: animPercent,
                center: AppCountUpText(
                  end: (overallPercentage * 100),
                  precision: 1,
                  suffix: '%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                progressColor: const Color(0xFF34D399),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusStr,
                        style: const TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isCurrentSem)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE SEMESTER',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$overallAttended / $overallTotalDays Days Attended (HOD Set)',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, size: 12, color: Color(0xFF34D399)),
                      const SizedBox(width: 4),
                      Text(
                        safeMarginStr,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAttendanceTab({
    required List<SemesterAttendance> semDataList,
    required SemesterAttendance selectedSemData,
    required List<DailyAttendanceLog> dailyLogs,
    required Widget summaryCard,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summaryCard,
              _buildSemesterPills(semDataList),
              const SizedBox(height: 6),

              // Daily Attendance Policy Banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.today_rounded, color: Color(0xFF2563EB), size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY BASIS ATTENDANCE POLICY',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 0.8),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Attendance is recorded per day. Being Present on a day marks you Present for all subjects scheduled on that day.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Attendance Logs',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${dailyLogs.where((d) => d.isPresent).length} / ${dailyLogs.length} Days Attended',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
          ),
          if (dailyLogs.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 36, color: Color(0xFF64748B)),
                  SizedBox(height: 10),
                  Text(
                    'No Daily Attendance Logs Yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Faculty daily session attendance marking will appear here live once recorded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dailyLogs.length,
              itemBuilder: (context, index) {
              final log = dailyLogs[index];
              final isExpanded = _expandedSubjectIndex == index;
              final isPresent = log.isPresent;
              final isOd = log.isOnDuty;

              Color badgeColor = isPresent
                  ? const Color(0xFF059669)
                  : (isOd ? const Color(0xFF2563EB) : const Color(0xFFDC2626));
              Color badgeBg = isPresent
                  ? const Color(0xFFECFDF5)
                  : (isOd ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2));
              IconData badgeIcon = isPresent
                  ? Icons.check_circle_rounded
                  : (isOd ? Icons.workspace_premium_rounded : Icons.cancel_rounded);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _expandedSubjectIndex = isExpanded ? null : index;
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                              child: Icon(badgeIcon, color: badgeColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${log.dayName}, ${log.dateStr}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Class In-Charge: ${log.classInCharge} • ${log.subjectsCovered.length} Classes Conducted',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                isPresent ? 'PRESENT (FULL DAY)' : (isOd ? 'ON DUTY (OD)' : 'ABSENT (FULL DAY)'),
                                style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        if (log.remarks != null) ...[
                          const SizedBox(height: 8),
                          Text('Note: ${log.remarks}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                        ],

                        // Expanded Subject Schedule Breakdown for the Day
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          const Text('Timetable Sessions Covered On This Day (All marked with Daily Status):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 8),
                          ...log.subjectsCovered.map((sub) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: badgeBg.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(sub, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                                    Text(
                                      log.status.label,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildSemesterPills(List<SemesterAttendance> semDataList) {
    final systemState = ref.watch(attendanceSystemProvider);
    final selectedIndex = systemState.selectedSemesterIndex;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: List.generate(semDataList.length, (index) {
          final sem = semDataList[index];
          final isSel = index == selectedIndex;
          final isCurrent = sem.isCurrentSemester;

          return GestureDetector(
            onTap: () {
              ref.read(attendanceSystemProvider.notifier).selectSemesterIndex(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF1D4ED8) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  if (isSel)
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sem ${sem.semesterNumber}',
                    style: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF34D399) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: isSel ? const Color(0xFF064E3B) : const Color(0xFF15803D),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHistoryLogTab({
    required List<AttendanceRecord> filteredLogs,
    required int totalLogsCount,
    required Widget summaryCard,
  }) {
    final presentCount = filteredLogs.where((l) => l.status == AttendanceStatus.present).length;
    final absentCount = filteredLogs.where((l) => l.status == AttendanceStatus.absent).length;
    final odCount = filteredLogs.where((l) => l.status == AttendanceStatus.onDuty).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summaryCard,

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search session by subject or code...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                {'label': 'All ($totalLogsCount)', 'value': 'All'},
                {'label': 'Present ($presentCount)', 'value': 'Present'},
                {'label': 'Absent ($absentCount)', 'value': 'Absent'},
                {'label': 'On Duty ($odCount)', 'value': 'On Duty'},
              ].map((filterObj) {
                final String filterVal = filterObj['value']!;
                final String filterLabel = filterObj['label']!;
                final isSel = _historyFilter == filterVal;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filterLabel),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _historyFilter = filterVal);
                    },
                    selectedColor: const Color(0xFF1D4ED8),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0)),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              final log = filteredLogs[index];
              final statusStr = log.status.label;
              Color statusColor;
              Color statusBg;
              IconData statusIcon;

              if (log.status == AttendanceStatus.present) {
                statusColor = const Color(0xFF059669);
                statusBg = const Color(0xFFECFDF5);
                statusIcon = Icons.check_circle_rounded;
              } else if (log.status == AttendanceStatus.absent) {
                statusColor = const Color(0xFFDC2626);
                statusBg = const Color(0xFFFEE2E2);
                statusIcon = Icons.cancel_rounded;
              } else {
                statusColor = const Color(0xFF2563EB);
                statusBg = const Color(0xFFEFF6FF);
                statusIcon = Icons.business_center_rounded;
              }

              final dateFormatted = '${log.date.day.toString().padLeft(2, '0')} ${_monthName(log.date.month)} ${log.date.year}';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.subjectCode} - ${log.subjectName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dateFormatted • ${log.timeSlot}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        statusStr,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  ),
);
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  Widget _buildLeaveTrackerTab({
    required List<LeaveRequestModel> leaveRequests,
    required Widget summaryCard,
  }) {
    final approvedCount = leaveRequests.where((r) => r.status == 'Approved').length;
    final pendingCount = leaveRequests.where((r) => r.status == 'Pending Approval').length;
    final postOdState = ref.watch(postOdProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summaryCard,
              const SizedBox(height: 12),
              // Stat cards row
              Row(
                children: [
                  _buildLeaveStatCard('Approved Leaves', '$approvedCount Days', Icons.event_available_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
                  const SizedBox(width: 10),
                  _buildLeaveStatCard('OD Granted', '2 Days', Icons.workspace_premium_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                  const SizedBox(width: 10),
                  _buildLeaveStatCard('Pending', '$pendingCount Request', Icons.pending_actions_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                ],
              ),
              const SizedBox(height: 16),

              // ── POST-OD RETURN & OUTCOME STATUS MODULE ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'POST-OD RETURN STATUS & CERTS',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Text('HOD Required', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Returned from Hackathon / OD? Team Leader submits outcome (Won/Lost with reason). Teammates upload certificates for HOD approval.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFDBEAFE)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showPostOdLeaderFormModal,
                            icon: const Icon(Icons.rate_review_rounded, size: 14),
                            label: const Text('Submit OD Outcome (Leader)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Display List of Post-OD Outcome Cards
              if (postOdState.outcomes.isNotEmpty) ...[
                const Text(
                  'Post-OD Event Return History & Certificates',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                ...postOdState.outcomes.map((item) {
                  final isWon = item.isWon;
                  final outcomeColor = isWon ? const Color(0xFF059669) : const Color(0xFFDC2626);
                  final outcomeBg = isWon ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.eventName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: outcomeBg, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                isWon ? '🏆 WON (${item.prizeTitle})' : '❌ LOST / PARTICIPATED',
                                style: TextStyle(color: outcomeColor, fontWeight: FontWeight.bold, fontSize: 10.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Leader: ${item.teamLeaderName} • Date: ${item.eventDate}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),

                        if (isWon) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Row(
                              children: [
                                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Reward: ${item.cashPrizeAmount ?? 'Merit Certificate & Trophy'}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Display Mandatory Loss Reason
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFCA5A5))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 14),
                                    SizedBox(width: 6),
                                    Text('Post-Mortem Analysis & Loss Reason (Submitted to HOD)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item.lossReason ?? 'Reason details recorded.', style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        // Teammate Certificates Row & Upload Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.teamMembers.where((m) => m.hasSubmittedCert).length} / ${item.teamMembers.length} Certificates Attached',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            if (isWon)
                              ElevatedButton.icon(
                                onPressed: () => _showMemberCertificateUploadSheet(context, item.id, item.eventName),
                                icon: const Icon(Icons.upload_file_rounded, size: 12),
                                label: const Text('Upload My Cert', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),

                        if (item.hodRemarks != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'HOD Remarks: ${item.hodRemarks}',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // ── DEDICATED OD LEAVE REQUEST HERO PANEL ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 540;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF2563EB), size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Apply for On-Duty (OD) Leave',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Submit signed Request Letter & Event Registration Screenshot to HOD.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showLeaveApplicationModal,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Apply OD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF2563EB), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Apply for On-Duty (OD) Leave',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Submit signed Request Letter & Event Registration Screenshot to HOD.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.25),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          onPressed: _showLeaveApplicationModal,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Apply OD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

          const Text(
            'Recent Leave Applications',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          ...leaveRequests.map((req) {
            final isApp = req.status == 'Approved';
            final statusColor = isApp ? const Color(0xFF059669) : const Color(0xFFD97706);
            final statusBg = isApp ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(req.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(req.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(req.duration, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                  const SizedBox(height: 4),
                  Text('Reason: ${req.reason}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  if (req.requestLetterUrl != null || req.registrationScreenshotUrl != null || req.hasAttachment) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (req.requestLetterUrl != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFBFDBFE))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text('Letter: ${req.requestLetterUrl}', style: const TextStyle(fontSize: 10, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        if (req.registrationScreenshotUrl != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFA7F3D0))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.image_rounded, size: 12, color: Color(0xFF059669)),
                                const SizedBox(width: 4),
                                Text('Proof: ${req.registrationScreenshotUrl}', style: const TextStyle(fontSize: 10, color: Color(0xFF065F46), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildLeaveStatCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF475569)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
