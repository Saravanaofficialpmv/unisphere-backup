import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';
import 'package:unisphere/services/nptel_service.dart';
import 'package:unisphere/widgets/nptel/nptel_upload_modal.dart';
import 'package:unisphere/widgets/nptel/nptel_information_card.dart';
import 'package:unisphere/widgets/nptel/industry_information_card.dart';

class CertificateModel {
  final String id;
  final String title;
  final String issuer;
  final String category;
  final String portfolioType; // 'NPTEL Certifications' or 'Industry Certifications'
  final String fileType; // PDF, PNG, JPG
  final String fileSize;
  final DateTime uploadDate;
  final DateTime? issueDate;
  final String credentialId;
  String status; // 'Approved', 'Pending', 'Rejected'
  final String? rejectionReason;
  final String certificateUrl;
  final String? grade; // 'Elite', 'Elite + Gold', 'Elite + Silver', etc.
  final String? score; // '82%', '92%', etc.

  CertificateModel({
    required this.id,
    required this.title,
    required this.issuer,
    required this.category,
    this.portfolioType = 'Industry Certifications',
    required this.fileType,
    required this.fileSize,
    required this.uploadDate,
    this.issueDate,
    required this.credentialId,
    required this.status,
    this.rejectionReason,
    required this.certificateUrl,
    this.grade,
    this.score,
  });
}

class CertificationsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final String? initialPortfolioFilter;
  const CertificationsScreen({super.key, this.onBack, this.initialPortfolioFilter});

  @override
  ConsumerState<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends ConsumerState<CertificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NptelService _nptelService = NptelService();
  String _selectedStatusFilter = 'All';
  String _selectedPortfolioFilter = 'All'; // 'All', 'NPTEL Certifications', 'Industry Certifications'
  final String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialPortfolioFilter != null) {
      _selectedPortfolioFilter = widget.initialPortfolioFilter!;
    }
    _nptelService.addListener(_onNptelUpdate);
  }

  @override
  void dispose() {
    _nptelService.removeListener(_onNptelUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onNptelUpdate() {
    if (mounted) setState(() {});
  }

  final List<CertificateModel> _certificates = [
    CertificateModel(
      id: 'CERT-NPTEL-JAVA',
      title: 'Programming in Java',
      issuer: 'IIT Kharagpur & NPTEL',
      category: 'Academic',
      portfolioType: 'NPTEL Certifications',
      fileType: 'PDF',
      fileSize: '1.4 MB',
      uploadDate: DateTime.now().subtract(const Duration(days: 3)),
      issueDate: DateTime(2026, 08, 01),
      credentialId: 'NPTEL26CS820',
      status: 'Approved',
      grade: 'Elite',
      score: '82%',
      certificateUrl: 'https://nptel.ac.in/noc/E-certificate',
    ),
    CertificateModel(
      id: 'CERT-001',
      title: 'AWS Certified Solutions Architect – Associate',
      issuer: 'Amazon Web Services (AWS)',
      category: 'Cloud & DevOps',
      portfolioType: 'Industry Certifications',
      fileType: 'PDF',
      fileSize: '1.8 MB',
      uploadDate: DateTime.now().subtract(const Duration(days: 12)),
      issueDate: DateTime(2025, 11, 15),
      credentialId: 'AWS-ASA-9920148',
      status: 'Approved',
      certificateUrl: 'https://aws.amazon.com/verification',
    ),
    CertificateModel(
      id: 'CERT-002',
      title: 'Google Cloud Associate Cloud Engineer',
      issuer: 'Google Cloud Training',
      category: 'Cloud & DevOps',
      portfolioType: 'Industry Certifications',
      fileType: 'PNG',
      fileSize: '2.4 MB',
      uploadDate: DateTime.now().subtract(const Duration(days: 5)),
      issueDate: DateTime(2026, 01, 10),
      credentialId: 'GCP-ACE-778102',
      status: 'Approved',
      certificateUrl: 'https://google.accredible.com/verify',
    ),
    CertificateModel(
      id: 'CERT-003',
      title: 'Meta Front-End Developer Professional Certificate',
      issuer: 'Coursera & Meta',
      category: 'Technical',
      portfolioType: 'Industry Certifications',
      fileType: 'PDF',
      fileSize: '3.1 MB',
      uploadDate: DateTime.now().subtract(const Duration(days: 2)),
      issueDate: DateTime(2026, 02, 01),
      credentialId: 'META-FED-88419',
      status: 'Pending',
      certificateUrl: 'https://coursera.org/verify/meta-fed',
    ),
    CertificateModel(
      id: 'CERT-004',
      title: 'NPTEL Elite + Gold: Data Structures and Algorithms in Java',
      issuer: 'IIT Madras & NPTEL',
      category: 'Academic',
      portfolioType: 'NPTEL Certifications',
      fileType: 'PDF',
      fileSize: '1.2 MB',
      uploadDate: DateTime.now().subtract(const Duration(days: 20)),
      issueDate: DateTime(2025, 10, 30),
      credentialId: 'NPTEL-CS-2025-091',
      status: 'Approved',
      grade: 'Elite + Gold',
      score: '92%',
      certificateUrl: 'https://nptel.ac.in/noc/E-certificate',
    ),
    CertificateModel(
      id: 'CERT-005',
      title: 'NPTEL Elite + Silver: Database Management Systems',
      issuer: 'IIT Kharagpur & NPTEL',
      category: 'Academic',
      portfolioType: 'NPTEL Certifications',
      fileType: 'PDF',
      fileSize: '1.5 MB',
      uploadDate: DateTime.now().subtract(const Duration(days: 45)),
      issueDate: DateTime(2025, 04, 20),
      credentialId: 'NPTEL-CS-2024-042',
      status: 'Approved',
      grade: 'Elite + Silver',
      score: '86%',
      certificateUrl: 'https://nptel.ac.in/noc/E-certificate',
    ),
    CertificateModel(
      id: 'CERT-006',
      title: 'Certified Ethical Hacker (CEH v12)',
      issuer: 'EC-Council',
      category: 'Cybersecurity',
      portfolioType: 'Industry Certifications',
      fileType: 'JPG',
      fileSize: '4.0 MB',
      uploadDate: DateTime.now().subtract(const Duration(days: 1)),
      issueDate: DateTime(2026, 01, 20),
      credentialId: 'ECC-CEH-33910',
      status: 'Rejected',
      rejectionReason: 'Certificate image is blurry and issuer stamp is not clearly legible. Please re-upload a clear PDF scan.',
      certificateUrl: 'https://aspen.eccouncil.org/verify',
    ),
  ];

  List<CertificateModel> get _filteredCertificates {
    return _certificates.where((cert) {
      final matchesSearch = cert.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          cert.issuer.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          cert.credentialId.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesStatus = _selectedStatusFilter == 'All' || cert.status == _selectedStatusFilter;
      final matchesPortfolio = _selectedPortfolioFilter == 'All' || cert.portfolioType == _selectedPortfolioFilter;
      final matchesCategory = _selectedCategoryFilter == 'All' || cert.category == _selectedCategoryFilter;

      return matchesSearch && matchesStatus && matchesPortfolio && matchesCategory;
    }).toList();
  }


  void _addNewCertificate(CertificateModel cert) {
    setState(() {
      _certificates.insert(0, cert);
    });
  }

  void _navigateBackToFeatureHub(BuildContext context) async {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _certificates.length;
    final approvedCount = _certificates.where((c) => c.status == 'Approved').length;
    final pendingCount = _certificates.where((c) => c.status == 'Pending').length;
    final rejectedCount = _certificates.where((c) => c.status == 'Rejected').length;

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            UnisphereHeaderCard(
              title: 'Certifications & Uploads',
              subtitle: 'Verified Certificates, Verification & Transcripts',
              onBack: () => _navigateBackToFeatureHub(context),
              rightActions: [
                IconButton(
                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                  tooltip: 'Upload Certificate',
                  onPressed: () => _showUploadCertificateDialog(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analytics Overview Header
                    _buildAnalyticsCards(totalCount, approvedCount, pendingCount, rejectedCount),
                    const SizedBox(height: 20),

                    // Search & Filter Controls
                    _buildSearchAndFilterControls(),
                    const SizedBox(height: 16),


                    // Certificates List
                    if (_filteredCertificates.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: _filteredCertificates.map((cert) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildCertificateCard(cert),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final bool canPopRoute = ModalRoute.of(context)?.canPop ?? false;
    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !mounted) return;
        if (widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: scaffold,
    );
  }

  // ── Analytics Overview Cards ────────────────────────────────────────────────
  Widget _buildAnalyticsCards(int total, int approved, int pending, int rejected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Color(0xFFA78BFA), size: 20),
              SizedBox(width: 8),
              Text(
                'Certification Portfolio',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatBadge('TOTAL', '$total', Colors.white, Colors.white10)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBadge('APPROVED', '$approved', const Color(0xFF34D399), const Color(0xFF065F46).withValues(alpha: 0.4))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBadge('PENDING', '$pending', const Color(0xFFFBBF24), const Color(0xFF78350F).withValues(alpha: 0.4))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBadge('REJECTED', '$rejected', const Color(0xFFF87171), const Color(0xFF7F1D1D).withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.8), letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search & Filter Controls ────────────────────────────────────────────────
  Widget _buildSearchAndFilterControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search certificates, issuers, or credentials...',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => setState(() => _searchController.clear()),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Portfolio Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPortfolioChip('All', 'All Portfolio'),
              const SizedBox(width: 8),
              _buildPortfolioChip('NPTEL Certifications', '🎓 NPTEL Certifications'),
              const SizedBox(width: 8),
              _buildPortfolioChip('Industry Certifications', '🏢 Industry Certifications'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Approved'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioChip(String value, String label) {
    final isSelected = _selectedPortfolioFilter == value;
    const chipColor = Color(0xFF1E293B);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedPortfolioFilter = value);
          if (value == 'NPTEL Certifications') {
            NptelInformationCard.showModal(
              context,
              certificate: _nptelService.certificates.isNotEmpty ? _nptelService.certificates.first : null,
              onUploadTap: () => NptelUploadModal.show(context),
            );
          } else if (value == 'Industry Certifications') {
            IndustryInformationCard.showModal(
              context,
              onUploadTap: () => NptelUploadModal.show(context),
            );
          }
        }
      },
      selectedColor: chipColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? chipColor : const Color(0xFFCBD5E1)),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildFilterChip(String status) {
    final isSelected = _selectedStatusFilter == status;
    Color chipColor;
    switch (status) {
      case 'Approved':
        chipColor = const Color(0xFF10B981);
        break;
      case 'Pending':
        chipColor = const Color(0xFFF59E0B);
        break;
      case 'Rejected':
        chipColor = const Color(0xFFEF4444);
        break;
      default:
        chipColor = const Color(0xFF7C3AED);
    }

    return ChoiceChip(
      label: Text(status),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedStatusFilter = status);
      },
      selectedColor: chipColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? chipColor : const Color(0xFFE2E8F0)),
      ),
      showCheckmark: false,
    );
  }

  // ── Certificate Card Item ─────────────────────────────────────────────────
  Widget _buildCertificateCard(CertificateModel cert) {
    Color statusBg;
    Color statusText;
    IconData statusIcon;

    switch (cert.status) {
      case 'Approved':
        statusBg = const Color(0xFFD1FAE5);
        statusText = const Color(0xFF065F46);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Pending':
        statusBg = const Color(0xFFFEF3C7);
        statusText = const Color(0xFF92400E);
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'Rejected':
        statusBg = const Color(0xFFFEE2E2);
        statusText = const Color(0xFF991B1B);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusBg = const Color(0xFFE2E8F0);
        statusText = const Color(0xFF475569);
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cert.portfolioType == 'NPTEL Certifications'
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cert.portfolioType == 'NPTEL Certifications'
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cert.portfolioType == 'NPTEL Certifications' ? Icons.school_rounded : Icons.verified_rounded,
                            size: 12,
                            color: cert.portfolioType == 'NPTEL Certifications' ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cert.portfolioType == 'NPTEL Certifications' ? 'NPTEL' : 'Industry',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cert.portfolioType == 'NPTEL Certifications' ? const Color(0xFFB45309) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cert.fileType == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                            size: 12,
                            color: cert.fileType == 'PDF' ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${cert.fileType} • ${cert.fileSize}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusText),
                      const SizedBox(width: 4),
                      Text(
                        cert.status.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Certificate Details
            Text(
              cert.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cert.issuer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.key_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'ID: ${cert.credentialId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_month_outlined, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Uploaded ${cert.uploadDate.day}/${cert.uploadDate.month}/${cert.uploadDate.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),

            if (cert.status == 'Rejected' && cert.rejectionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cert.rejectionReason!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPreviewModal(context, cert),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: cert.status == 'Approved'
                        ? () => _downloadCertificate(context, cert)
                        : null,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFF1F5F9),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_off_rounded, size: 40, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Certificates Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search query or status filter.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ── Download Action ───────────────────────────────────────────────────────
  void _downloadCertificate(BuildContext context, CertificateModel cert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading official certificate document for ${cert.title}...'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  // ── Preview Modal ─────────────────────────────────────────────────────────
  void _showPreviewModal(BuildContext context, CertificateModel cert) {
    final bool isNptel = cert.portfolioType == 'NPTEL Certifications' || cert.issuer.toLowerCase().contains('nptel');
    final String grade = cert.grade ?? (isNptel ? 'Elite' : 'Professional');
    final String score = cert.score ?? (isNptel ? '82%' : 'Passed');
    final String issueDateStr = cert.issueDate != null
        ? '${_getMonthName(cert.issueDate!.month)} ${cert.issueDate!.year}'
        : 'Aug 2026';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isNptel ? Icons.school_rounded : Icons.verified_rounded,
                        color: isNptel ? const Color(0xFFF59E0B) : const Color(0xFF60A5FA),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isNptel ? 'NPTEL Official E-Certificate' : 'Industry Certification',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mock Certificate Canvas Preview
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, size: 48, color: Color(0xFFD97706)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNptel ? 'NPTEL ONLINE CERTIFICATION' : 'VENDOR CERTIFICATION',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF78350F)),
                                ),
                                const Text('Ministry of Education, Govt. of India', style: TextStyle(fontSize: 9, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFFFDE68A), thickness: 1.5),
                        const SizedBox(height: 10),
                        const Text('This is to certify that', style: TextStyle(fontSize: 11, color: Color(0xFF78350F), fontStyle: FontStyle.italic)),
                        const SizedBox(height: 6),
                        const Text(
                          'Saravana Kumar',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'serif'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'has successfully completed the 12-week course',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Text(
                            cert.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Certificate Metadata Summary Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCertMetaItem('Status', cert.status == 'Approved' ? 'Certified ✓' : cert.status, const Color(0xFF059669)),
                                  _buildCertMetaItem('Grade', grade, const Color(0xFFD97706)),
                                  _buildCertMetaItem('Score', score, const Color(0xFF2563EB)),
                                  _buildCertMetaItem('Issued', issueDateStr, const Color(0xFF475569)),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('ISSUING AUTHORITY', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(cert.issuer, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('CREDENTIAL ID', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(cert.credentialId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontFamily: 'monospace')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Verification Note
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Digitally signed & verified by NPTEL Online Certification portal & HOD office.',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final uri = Uri.parse(cert.certificateUrl);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Verify Credential', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _downloadCertificate(context, cert);
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('View Certificate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCertMetaItem(String label, String val, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'Aug';
  }

  // ── Upload Certificate Modal Form ─────────────────────────────────────────
  void _showUploadCertificateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Certificate Category to Upload',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('NPTEL Certificate Upload', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Submit NPTEL course details, score & certificate ID for credit verification'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    NptelUploadModal.show(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF7C3AED)),
                  ),
                  title: const Text('Industry / Other Certification', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('AWS, Google Cloud, Meta, Coursera, or custom certifications'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    _showStandardUploadDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStandardUploadDialog(BuildContext context) {
    final titleController = TextEditingController();
    final issuerController = TextEditingController();
    final credIdController = TextEditingController();
    String selectedCategory = 'Technical';
    String selectedFileType = 'PDF';
    String? pickedFileName;
    String? pickedFileSize;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.upload_file_rounded, color: Color(0xFF7C3AED), size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Upload Certificate',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Form Fields
                      const Text('Certificate Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. AWS Certified Developer Associate',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Issuing Organization *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: issuerController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Amazon Web Services / Coursera',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ['Technical', 'Cloud & DevOps', 'Cybersecurity', 'Academic', 'Soft Skills'].map((cat) {
                          final isSelected = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569))),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedCategory = cat);
                            },
                            selectedColor: const Color(0xFF7C3AED),
                            backgroundColor: const Color(0xFFF8FAFC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1))),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      const Text('File Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      Row(
                        children: ['PDF', 'PNG', 'JPG'].map((fmt) {
                          final isSelected = selectedFileType == fmt;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: ChoiceChip(
                                label: Center(child: Text(fmt, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF475569)))),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) setModalState(() => selectedFileType = fmt);
                                },
                                selectedColor: const Color(0xFF7C3AED),
                                backgroundColor: const Color(0xFFF8FAFC),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1))),
                                showCheckmark: false,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      const Text('Credential ID / Verification URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: credIdController,
                        decoration: InputDecoration(
                          hintText: 'e.g. AWS-DEV-109284',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // File Attachment Zone Box
                      InkWell(
                        onTap: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                              allowMultiple: false,
                              withData: true,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final f = result.files.first;
                              final sizeInMb = (f.size / (1024 * 1024)).toStringAsFixed(1);
                              final displaySize = sizeInMb == '0.0' ? '0.5 MB' : '$sizeInMb MB';
                              final ext = (f.extension ?? 'pdf').toUpperCase();
                              setModalState(() {
                                pickedFileName = f.name;
                                pickedFileSize = displaySize;
                                if (['PDF', 'PNG', 'JPG'].contains(ext)) {
                                  selectedFileType = ext;
                                }
                              });
                            }
                          } catch (e) {
                            debugPrint('Error picking certificate file: $e');
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: pickedFileName != null ? const Color(0xFFF5F3FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: pickedFileName != null ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                              width: pickedFileName != null ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                pickedFileName != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                                size: 36,
                                color: const Color(0xFF7C3AED),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pickedFileName != null ? pickedFileName! : 'Tap to select file from device',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pickedFileSize != null ? 'Selected file size: $pickedFileSize' : 'Supports PDF, PNG, JPG (Max 10 MB)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: pickedFileName != null ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                                  fontWeight: pickedFileName != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty || issuerController.text.trim().isEmpty) {
                              return;
                            }

                            final newCert = CertificateModel(
                              id: 'CERT-00${_certificates.length + 1}',
                              title: titleController.text.trim(),
                              issuer: issuerController.text.trim(),
                              category: selectedCategory,
                              fileType: selectedFileType,
                              fileSize: pickedFileSize ?? '2.1 MB',
                              uploadDate: DateTime.now(),
                              credentialId: credIdController.text.trim().isNotEmpty ? credIdController.text.trim() : 'VERIFIED-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                              status: 'Pending',
                              certificateUrl: pickedFileName != null ? 'https://unisphere.edu/docs/$pickedFileName' : 'https://unisphere.edu/verify',
                            );

                            Navigator.pop(context);
                            _addNewCertificate(newCert);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Submit for Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
