import 'package:flutter/material.dart';
import 'package:unisphere/models/nptel_certificate_model.dart';
import 'package:unisphere/services/nptel_service.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class StaffNptelVerificationScreen extends StatefulWidget {
  const StaffNptelVerificationScreen({super.key});

  @override
  State<StaffNptelVerificationScreen> createState() => _StaffNptelVerificationScreenState();
}

class _StaffNptelVerificationScreenState extends State<StaffNptelVerificationScreen> {
  final NptelService _nptelService = NptelService();
  String _selectedFilter = 'Pending Verification';

  @override
  void initState() {
    super.initState();
    _nptelService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _nptelService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _verifyCert(NptelCertificateModel cert) {
    _nptelService.verifyCertificate(cert.id, 'Dr. Sarah Miller (HOD - CSE)');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verified NPTEL Certificate for ${cert.studentName} (${cert.courseName})'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _rejectCert(NptelCertificateModel cert) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Reject Certificate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${cert.studentName} (${cert.rollNo})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Course: ${cert.courseName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            const Text('Reason for Rejection:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter specific reason so student can re-upload correctly...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim().isEmpty
                  ? 'Certificate ID mismatch or file illegible. Please re-verify and re-upload.'
                  : reasonController.text.trim();
              _nptelService.rejectCertificate(cert.id, reason, 'Dr. Sarah Miller (HOD - CSE)');
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rejected certificate for ${cert.studentName}. Student notified for re-upload.'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCerts = _nptelService.certificates;
    List<NptelCertificateModel> filteredList = allCerts;
    if (_selectedFilter != 'All') {
      filteredList = allCerts.where((c) => c.status == _selectedFilter).toList();
    }

    final pendingCount = _nptelService.pendingCertificates.length;
    final verifiedCount = _nptelService.verifiedCertificates.length;
    final rejectedCount = _nptelService.rejectedCertificates.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('NPTEL Certificate Verification Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: AppLiquidPullToRefresh(
        gifAsset: 'assets/tibsy-dp.gif',
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 1000));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Cards
            Row(
              children: [
                Expanded(child: _buildMetricCard('Pending Review', '$pendingCount', const Color(0xFFF59E0B), Icons.hourglass_top_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricCard('Verified', '$verifiedCount', const Color(0xFF10B981), Icons.verified_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricCard('Rejected', '$rejectedCount', const Color(0xFFEF4444), Icons.cancel_rounded)),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Pending Verification', '⏳ Pending Review ($pendingCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Verified', '✅ Verified ($verifiedCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected', '❌ Rejected ($rejectedCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('All', '📁 All Submissions (${allCerts.length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submissions List
            if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text(
                      'No certificates found for "$_selectedFilter"',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: filteredList.map((cert) => _buildCertReviewCard(cert)).toList(),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildCertReviewCard(NptelCertificateModel cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student & Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    child: Text(
                      cert.studentName[0],
                      style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${cert.rollNo} • ${cert.department}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cert.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cert.statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(cert.statusIcon, color: cert.statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      cert.status,
                      style: TextStyle(color: cert.statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Course details grid
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildDetailItem('Course Name', cert.courseName),
              _buildDetailItem('Course Code', cert.courseCode),
              _buildDetailItem('Semester', cert.semester),
              _buildDetailItem('Academic Year', cert.academicYear),
              _buildDetailItem('Score', cert.score),
              _buildDetailItem('Grade', cert.grade),
              _buildDetailItem('Certificate ID', cert.certificateId),
              _buildDetailItem('Issue Date', cert.issueDate),
            ],
          ),
          const SizedBox(height: 12),

          // File badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${cert.fileName} (${cert.fileSize})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening ${cert.fileName} in document viewer...')),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Document', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

          if (cert.status == 'Rejected' && cert.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                'Rejection Reason: ${cert.rejectionReason}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
              ),
            ),
          ],

          if (cert.status == 'Pending Verification') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectCert(cert),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _verifyCert(cert),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve / Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
