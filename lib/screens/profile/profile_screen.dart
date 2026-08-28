import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/storage_service.dart';
import 'package:unisphere/services/parent_service.dart';
import 'package:unisphere/widgets/common/sign_out_confirmation_sheet.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/providers/academic_overview_provider.dart';
import 'package:unisphere/screens/features/leetcode_detail_screen.dart';
import 'package:unisphere/screens/features/github_detail_screen.dart';
import 'package:unisphere/widgets/student/student_profile_edit_request_modal.dart';
import 'package:unisphere/screens/student/modules/student_resume_screen.dart';
import 'package:unisphere/screens/parent/parent_profile_screen.dart';
import 'package:unisphere/core/constants/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Notification states
  bool _announcementNotifs = true;
  bool _gradeNotifs = true;
  bool _attendanceNotifs = true;
  bool _feeNotifs = true;
  bool _placementNotifs = true;
  bool _biometricEnabled = true;
  String? _customPhotoPath;
  bool _isUploadingPhoto = false;

  // Custom added certifications
  final List<Map<String, dynamic>> _certifications = [
    {
      'title': 'NPTEL Elite + Gold: Data Structures & Algorithms',
      'issuer': 'IIT Madras & NPTEL',
      'badge': 'Elite + Gold 🏅',
      'color': const Color(0xFFD97706),
      'score': '92% (Top 1% National)',
      'id': 'NPTEL22CS45890123',
      'date': 'Oct 2023',
    },
    {
      'title': 'AWS Certified Solutions Architect – Associate',
      'issuer': 'Amazon Web Services (AWS)',
      'badge': 'Verified ☁️',
      'color': const Color(0xFF2563EB),
      'score': 'Score 840 / 1000',
      'id': 'AWS-ARCH-2024-8891',
      'date': 'Jan 2024',
    },
    {
      'title': 'Google Cloud Associate Cloud Engineer',
      'issuer': 'Google Cloud Training',
      'badge': 'Verified 🌐',
      'color': const Color(0xFF059669),
      'score': 'Professional Grade',
      'id': 'GCP-ACE-9901452',
      'date': 'Mar 2024',
    },
    {
      'title': 'Programming in Java (NPTEL)',
      'issuer': 'IIT Kharagpur & NPTEL',
      'badge': 'Elite ✓',
      'color': const Color(0xFF7C3AED),
      'score': 'Score 82%',
      'id': 'NPTEL23CS1249821',
      'date': 'May 2023',
    },
  ];

  Future<void> _refreshProfileData() async {
    ref.invalidate(currentUserProvider);
    ref.invalidate(academicOverviewProvider);
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  void _openResumePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentResumeScreen(
          onBack: () => Navigator.maybePop(context),
        ),
      ),
    );
  }

  Future<void> _safeLaunchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening: $url')));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    if (currentUser?.role == UserRole.parent) {
      return ParentProfileScreen(onBack: widget.onBack);
    }
    final name = (currentUser?.name != null && currentUser!.name.trim().isNotEmpty) ? currentUser.name : 'Alex Johnson';
    final email = (currentUser?.email != null && currentUser!.email.trim().isNotEmpty) ? currentUser.email : 'saravanapmvofficial@gmail.com';
    final isDemo = email.toLowerCase().trim() == 'saravanapmvofficial@gmail.com';
    final regNo = currentUser?.metadata?['registerNumber']?.toString().isNotEmpty == true 
        ? currentUser!.metadata!['registerNumber'].toString() 
        : (isDemo ? 'RA2111003010001' : (currentUser?.uid.startsWith('DEMO-') == true ? 'DEMO-REG-001' : 'RA2111003010001'));
    final dept = currentUser?.metadata?['department']?.toString().isNotEmpty == true 
        ? currentUser!.metadata!['department'].toString() 
        : (isDemo ? 'Computer Science and Engineering' : 'Computer Science and Engineering');
    final year = currentUser?.metadata?['year']?.toString().isNotEmpty == true 
        ? currentUser!.metadata!['year'].toString() 
        : (isDemo ? '3rd Year (Semester VI)' : '3rd Year (Semester VI)');
    final photoUrl = _customPhotoPath ?? (currentUser?.profileImageUrl ?? currentUser?.metadata?['passportPhotoUrl'] ?? currentUser?.metadata?['photoUrl'] ?? '').toString().trim();
    final hasUploadedPhoto = photoUrl.isNotEmpty && (photoUrl.startsWith('http://') || photoUrl.startsWith('https://') || File(photoUrl).existsSync());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ================= STABLE TOP CURVED ROYAL INDIGO BANNER =================
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3730A3),
                  Color(0xFF4338CA),
                  Color(0xFF4F46E5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x334338CA),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    // Top Bar with Circular Back Button & More Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.onBack != null || Navigator.canPop(context))
                          GestureDetector(
                            onTap: widget.onBack ?? () => Navigator.maybePop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: Color(0xFF1E1B4B),
                                size: 24,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 38),

                        // Empty placeholder on the right for balanced spacing
                        const SizedBox(width: 38),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Center Avatar with Gradient Ring (when photo uploaded) & Camera Shortcut
                    GestureDetector(
                      onTap: () => _showUploadPassportPhotoModal(context),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: hasUploadedPhoto
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF38BDF8), // Vivid Cyan
                                        Color(0xFF818CF8), // Soft Indigo
                                        Color(0xFFA855F7), // Purple
                                        Color(0xFFEC4899), // Rose Pink
                                        Color(0xFF38BDF8), // Continuous Loop
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: hasUploadedPhoto ? null : Colors.white,
                              boxShadow: hasUploadedPhoto
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF818CF8).withValues(alpha: 0.65),
                                        blurRadius: 18,
                                        spreadRadius: 2.5,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFFEC4899).withValues(alpha: 0.45),
                                        blurRadius: 26,
                                        spreadRadius: 1.5,
                                      ),
                                    ]
                                  : const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 14,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Container(
                              padding: EdgeInsets.all(hasUploadedPhoto ? 2.5 : 0),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: _buildProfileHeaderAvatar(photoUrl),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Student Name
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email & ID Subtitle
                    Text(
                      '$email  •  $regNo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Account Creation Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Created: ${currentUser?.formattedCreatedAt ?? "15 Jan 2024"}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= SCROLLABLE CONTENT WITH REFRESH UNDER BANNER =================
          Expanded(
            child: AppLiquidPullToRefresh(
              onRefresh: _refreshProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // ================= HERO MEMBERSHIP / PRO CARD =================
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F172A),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('👑', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$name, Verified Student',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Access your complete institutional bio data, academic marksheets, digital credentials, and placement resume.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showCompleteStudentBioDataModal(context, currentUser, name, email, regNo, dept, year),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4338CA),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('VIEW FULL BIO DATA', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _openResumePage(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    foregroundColor: const Color(0xFF0F172A),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('VIEW RESUME', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ================= SECTION 1: STUDENT BIO DATA & ACADEMICS =================
                    _buildSectionPillHeader('Student Bio Data & Academics'),

                    _buildGroupedCard([
                      _buildGroupedTile(
                        icon: Icons.person_pin_rounded,
                        title: 'Complete Student Bio-Data (A to Z)',
                        onTap: () => _showCompleteStudentBioDataModal(context, currentUser, name, email, regNo, dept, year),
                      ),
                      _buildGroupedTile(
                        icon: Icons.school_outlined,
                        title: 'Academics, CGPA & Mentor Record',
                        onTap: () => _showAcademicsModal(context),
                      ),
                      _buildGroupedTile(
                        icon: Icons.grid_view_rounded,
                        title: 'Connected Coding & Social Apps',
                        onTap: () => _showConnectedProfilesModal(context),
                      ),
                      _buildGroupedTile(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Certifications & NPTEL Portfolio',
                        onTap: () => _showCertificationsModal(context),
                      ),
                      _buildGroupedTile(
                        icon: Icons.folder_shared_outlined,
                        title: 'Official Document Vault',
                        showDivider: false,
                        onTap: () => _showDocumentVaultModal(context),
                      ),
                    ]),

                    const SizedBox(height: 8),

                    // ================= SECTION 2: PREFERENCES & SECURITY =================
                    _buildSectionPillHeader('Preferences & Security'),

                    _buildGroupedCard([
                      _buildGroupedTile(
                        icon: Icons.calendar_month_rounded,
                        title: 'Account Creation Date',
                        subtitle: 'Member since ${currentUser?.formattedCreatedAt ?? "15 Jan 2024"}',
                        iconColor: const Color(0xFF4F46E5),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Text(
                            currentUser?.formattedCreatedAt ?? '15 Jan 2024',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ),
                        onTap: () => _showAccountInfoModal(context, currentUser),
                      ),
                      _buildGroupedTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Settings',
                        onTap: () => _showNotificationSettingsModal(context),
                      ),
                      _buildGroupedTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Security & Authentication',
                        onTap: () => _showSecuritySettingsModal(context, currentUser),
                      ),
                      _buildGroupedTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Profile Verification Status',
                        onTap: () => _showVerificationStatusModal(context, currentUser),
                      ),
                      _buildGroupedTile(
                        icon: Icons.edit_note_rounded,
                        title: 'Request Profile Data Correction',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useRootNavigator: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const StudentProfileEditRequestModal(),
                          );
                        },
                      ),
                      _buildGroupedTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Campus IT HelpDesk & Support',
                        onTap: () => _showCampusSupportModal(context),
                      ),
                      _buildGroupedTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out of Account',
                        iconColor: const Color(0xFFDC2626),
                        textColor: const Color(0xFFDC2626),
                        showDivider: false,
                        onTap: () => showSignOutConfirmationSheet(context, ref),
                      ),
                    ]),

                    // Bottom clearance so floating nav bar does not hide content
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPER UI BUILDERS =================
  Widget _buildSectionPillHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildGroupedTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool showDivider = true,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? const Color(0xFF475569), size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: textColor ?? const Color(0xFF1E293B),
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor != null ? iconColor.withValues(alpha: 0.6) : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 52,
            endIndent: 16,
            color: Color(0xFFF1F5F9),
          ),
      ],
    );
  }

  Widget _buildProfileHeaderAvatar(String photoUrl) {
    ImageProvider? imageProvider;
    if (photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        imageProvider = NetworkImage(photoUrl);
      } else {
        final file = File(photoUrl);
        if (file.existsSync()) {
          imageProvider = FileImage(file);
        }
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFFEEF2FF),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, size: 42, color: Color(0xFF4338CA))
              : null,
        ),
        if (_isUploadingPhoto)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ================= 🌟 MASTER A TO Z STUDENT BIO-DATA MODAL =================
  void _showCompleteStudentBioDataModal(
    BuildContext context,
    UserModel? currentUser,
    String name,
    String email,
    String regNo,
    String dept,
    String year,
  ) {
    final meta = currentUser?.metadata ?? {};
    final personal = meta['personal'] as Map<String, dynamic>? ?? {};
    final contact = meta['contact'] as Map<String, dynamic>? ?? {};
    final permAddr = (contact['permanentAddress'] as Map<String, dynamic>?) ?? {};
    final currAddr = (contact['currentAddress'] as Map<String, dynamic>?) ?? {};
    final parents = meta['parents'] as Map<String, dynamic>? ?? {};
    final father = (parents['father'] as Map<String, dynamic>?) ?? {};
    final mother = (parents['mother'] as Map<String, dynamic>?) ?? {};
    final guardian = (parents['guardian'] as Map<String, dynamic>?) ?? {};
    final education = meta['education'] as Map<String, dynamic>? ?? {};
    final tenth = (education['tenth'] as Map<String, dynamic>?) ?? {};
    final twelfth = (education['twelfthOrDiploma'] as Map<String, dynamic>?) ?? {};
    final diploma = (education['diploma'] as Map<String, dynamic>?) ?? {};
    final living = meta['living'] as Map<String, dynamic>? ?? {};
    final livingDetails = (living['details'] as Map<String, dynamic>?) ?? {};
    final transport = meta['transport'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DefaultTabController(
          length: 6,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Top drag bar & title
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header Info Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF4338CA), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: const Icon(Icons.person, color: Color(0xFF4338CA), size: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    personal['fullName']?.toString() ?? name,
                                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF6EE7B7)),
                                  ),
                                  child: const Text('100% COMPLETE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$regNo • $dept',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Tab Header
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: const TabBar(
                    isScrollable: true,
                    labelColor: Color(0xFF4338CA),
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Color(0xFF4338CA),
                    indicatorWeight: 3,
                    labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: '👤 Personal & Bio'),
                      Tab(text: '📞 Contact & Address'),
                      Tab(text: '👨‍👩‍👧 Parents & Family'),
                      Tab(text: '🎓 10th & 12th Education'),
                      Tab(text: '🏠 Living & Hostel'),
                      Tab(text: '🚌 Commute & Transport'),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: PERSONAL & BIO
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildModalInfoCard([
                              _buildModalRow('Full Legal Name', personal['fullName']?.toString() ?? name),
                              _buildModalRow('Register / Roll No', personal['registerNumber']?.toString() ?? regNo),
                              _buildModalRow('Department & Degree', personal['department']?.toString() ?? dept),
                              _buildModalRow('Year & Batch', '$year (Batch 2022–2026)'),
                              _buildModalRow('College Email', personal['collegeEmail']?.toString() ?? email),
                              _buildModalRow('Date of Birth (DOB)', personal['dob']?.toString() ?? personal['dateOfBirth']?.toString() ?? '15 May 2005'),
                              _buildModalRow('Gender', personal['gender']?.toString() ?? 'Male'),
                              _buildModalRow('Blood Group', personal['bloodGroup']?.toString() ?? 'O+', isBadge: true, badgeColor: const Color(0xFFFEE2E2), badgeTextColor: const Color(0xFFDC2626)),
                              _buildModalRow('Nationality', personal['nationality']?.toString() ?? 'Indian'),
                              _buildModalRow('Mother Tongue', personal['motherTongue']?.toString() ?? 'Tamil'),
                              _buildModalRow('Religion', personal['religion']?.toString() ?? 'Hindu'),
                              _buildModalRow('Community Category', personal['community']?.toString() ?? 'BC (Backward Class)', isBadge: true),
                              _buildModalRow('Caste / Sub-Caste', personal['caste']?.toString() ?? 'Kongu Vellalar'),
                              _buildModalRow('First Graduate in Family', personal['isFirstGraduate'] == true ? 'Yes (Verified)' : 'No'),
                              _buildModalRow('Differently Abled (PwD)', personal['isDifferentlyAbled'] == true ? 'Yes' : 'No (None)'),
                            ]),
                          ],
                        ),
                      ),

                      // TAB 2: CONTACT & ADDRESS
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildModalInfoCard([
                              _buildModalRow('Primary Mobile Number', contact['primaryMobile']?.toString() ?? currentUser?.phoneNumber ?? '+91 98765 43210'),
                              _buildModalRow('Alternate Mobile', contact['alternateMobile']?.toString() ?? '+91 94433 22110'),
                              _buildModalRow('Personal Email', contact['personalEmail']?.toString() ?? 'student.personal@gmail.com'),
                              _buildModalRow('Emergency Contact Person', contact['emergencyContactName']?.toString() ?? 'Ramesh Johnson (Father)'),
                              _buildModalRow('Emergency Relationship', contact['emergencyContactRelationship']?.toString() ?? 'Father'),
                              _buildModalRow('Emergency Contact No', contact['emergencyContactNumber']?.toString() ?? '+91 94444 12345'),
                            ]),
                            const SizedBox(height: 14),
                            _buildSectionPillHeader('Permanent Residential Address'),
                            _buildModalInfoCard([
                              _buildModalRow('Address Line 1', permAddr['addressLine1']?.toString() ?? 'No. 42, Anna Nagar West'),
                              _buildModalRow('Area / Street', permAddr['area']?.toString() ?? '2nd Main Road'),
                              _buildModalRow('City / Town', permAddr['city']?.toString() ?? 'Chennai'),
                              _buildModalRow('District', permAddr['district']?.toString() ?? 'Chennai District'),
                              _buildModalRow('State & Country', '${permAddr['state']?.toString() ?? "Tamil Nadu"}, ${permAddr['country']?.toString() ?? "India"}'),
                              _buildModalRow('Pincode / Postal Code', permAddr['pincode']?.toString() ?? '600040', isBadge: true),
                            ]),
                            const SizedBox(height: 14),
                            _buildSectionPillHeader('Current Communication Address'),
                            _buildModalInfoCard([
                              _buildModalRow('Current Address Line', currAddr['addressLine1']?.toString() ?? 'Room 304, Men\'s Hostel Block B'),
                              _buildModalRow('City & State', '${currAddr['city']?.toString() ?? "VSB Campus, Karur"}, ${currAddr['state']?.toString() ?? "Tamil Nadu"}'),
                              _buildModalRow('Postal Code', currAddr['pincode']?.toString() ?? '639111'),
                            ]),
                          ],
                        ),
                      ),

                      // TAB 3: PARENTS & GUARDIAN
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildSectionPillHeader('Father\'s Profile'),
                            _buildModalInfoCard([
                              _buildModalRow('Father Full Name', father['name']?.toString() ?? 'Ramesh Johnson'),
                              _buildModalRow('Father Mobile Number', father['mobileNumber']?.toString() ?? '+91 94444 12345'),
                              _buildModalRow('Father Email', father['email']?.toString() ?? 'ramesh.j@gmail.com'),
                              _buildModalRow('Highest Qualification', father['qualification']?.toString() ?? 'B.E. Mechanical Engineering'),
                              _buildModalRow('Occupation / Sector', father['occupation']?.toString() ?? 'Senior Engineer (L&T)'),
                              _buildModalRow('Annual Income', father['annualIncome']?.toString() ?? '₹6,50,000 / annum'),
                            ]),
                            const SizedBox(height: 14),
                            _buildSectionPillHeader('Mother\'s Profile'),
                            _buildModalInfoCard([
                              _buildModalRow('Mother Full Name', mother['name']?.toString() ?? 'Meenakshi Ramesh'),
                              _buildModalRow('Mother Mobile Number', mother['mobileNumber']?.toString() ?? '+91 94444 54321'),
                              _buildModalRow('Mother Email', mother['email']?.toString() ?? 'meenakshi.r@gmail.com'),
                              _buildModalRow('Highest Qualification', mother['qualification']?.toString() ?? 'M.Sc. Mathematics, B.Ed.'),
                              _buildModalRow('Occupation / Sector', mother['occupation']?.toString() ?? 'High School Teacher'),
                              _buildModalRow('Annual Income', mother['annualIncome']?.toString() ?? '₹4,20,000 / annum'),
                            ]),
                            _buildSectionPillHeader('Total Parent & Family Annual Income'),
                            _buildModalInfoCard([
                              _buildModalRow(
                                'Combined Annual Income',
                                parents['parentAnnualIncome']?.toString() ??
                                    parents['annualIncome']?.toString() ??
                                    '₹10,70,000 / annum',
                                isBadge: true,
                                badgeColor: const Color(0xFFEFF6FF),
                                badgeTextColor: const Color(0xFF2563EB),
                              ),
                            ]),
                            if (guardian['name'] != null && guardian['name'].toString().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _buildSectionPillHeader('Local Guardian (if applicable)'),
                              _buildModalInfoCard([
                                _buildModalRow('Guardian Name', guardian['name']?.toString() ?? ''),
                                _buildModalRow('Relationship', guardian['relationship']?.toString() ?? ''),
                                _buildModalRow('Guardian Mobile', guardian['mobileNumber']?.toString() ?? ''),
                              ]),
                            ],
                          ],
                        ),
                      ),

                      // TAB 4: PREVIOUS EDUCATION (10th, 12th, DIPLOMA)
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildSectionPillHeader('10th Standard (SSLC / Secondary School)'),
                            _buildModalInfoCard([
                              _buildModalRow('School / Institution Name', tenth['institutionName']?.toString() ?? 'Government Higher Secondary School'),
                              _buildModalRow('Board of Examination', tenth['boardOrUniversity']?.toString() ?? 'Tamil Nadu State Board'),
                              _buildModalRow('Medium of Study', tenth['medium']?.toString() ?? 'English Medium'),
                              _buildModalRow('10th Register Number', tenth['registerNumber']?.toString() ?? 'SSLC-2020-89104'),
                              _buildModalRow('Year of Passing', tenth['passingYear']?.toString() ?? '2021'),
                              _buildModalRow('Marks Obtained', '${tenth['marksObtained'] ?? 465} / ${tenth['totalMarks'] ?? 500}'),
                              _buildModalRow('Aggregate Percentage', '${tenth['percentage'] ?? 93.0}%', isBadge: true, badgeColor: const Color(0xFFD1FAE5), badgeTextColor: const Color(0xFF065F46)),
                            ]),
                            const SizedBox(height: 14),
                            _buildSectionPillHeader('12th Standard (HSC / Higher Secondary)'),
                            _buildModalInfoCard([
                              _buildModalRow('School / Institution Name', twelfth['institutionName']?.toString() ?? 'VSB Higher Secondary School'),
                              _buildModalRow('Board of Examination', twelfth['boardOrUniversity']?.toString() ?? 'Tamil Nadu State Board'),
                              _buildModalRow('Medium of Study', twelfth['medium']?.toString() ?? 'English Medium'),
                              _buildModalRow('12th Register Number', twelfth['registerNumber']?.toString() ?? 'HSC-2022-45210'),
                              _buildModalRow('Year of Passing', twelfth['passingYear']?.toString() ?? '2023'),
                              _buildModalRow('Marks Obtained', '${twelfth['marksObtained'] ?? 552} / ${twelfth['totalMarks'] ?? 600}'),
                              _buildModalRow('Aggregate Percentage', '${twelfth['percentage'] ?? 92.0}%', isBadge: true, badgeColor: const Color(0xFFD1FAE5), badgeTextColor: const Color(0xFF065F46)),
                            ]),
                            if (education['hasDiploma'] == true || diploma['institutionName'] != null) ...[
                              const SizedBox(height: 14),
                              _buildSectionPillHeader('Diploma / Lateral Entry Record'),
                              _buildModalInfoCard([
                                _buildModalRow('Polytechnic Institution', diploma['institutionName']?.toString() ?? 'VSB Polytechnic College'),
                                _buildModalRow('Discipline', diploma['registerNumber']?.toString() ?? 'Diploma in Computer Eng.'),
                                _buildModalRow('Diploma Percentage', '${diploma['percentage'] ?? 88.5}%', isBadge: true),
                              ]),
                            ],
                          ],
                        ),
                      ),

                      // TAB 5: LIVING & ACCOMMODATION
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildModalInfoCard([
                              _buildModalRow('Accommodation Category', living['livingType']?.toString() == 'collegeHostel' ? 'College Hostel' : 'Day Scholar / PG Hostel', isBadge: true),
                              _buildModalRow('Residence Name', livingDetails['pgName']?.toString() ?? 'Hostel Block B (Men\'s Campus Hostel)'),
                              _buildModalRow('Room / Unit Number', 'Room 304 (3rd Floor)'),
                              _buildModalRow('Mess Type Preference', 'South Indian Vegetarian & Non-Veg'),
                              _buildModalRow('Hostel Warden Name', 'Dr. S. Karthikeyan (+91 98421 90812)'),
                              _buildModalRow('Roommates On Record', livingDetails['roommates']?.toString() ?? 'Karthik S. & Ramesh M. (CSE Batch A)'),
                              _buildModalRow('Local Guardian Address', livingDetails['pgAddress']?.toString() ?? 'Covai Road, Near VSB Main Campus, Karur'),
                            ]),
                          ],
                        ),
                      ),

                      // TAB 6: COMMUTE & TRANSPORT
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildModalInfoCard([
                              _buildModalRow('Primary Commuting Mode', transport['mode']?.toString() ?? 'College Bus Route #14', isBadge: true),
                              _buildModalRow('Boarding Bus Stop', 'Karur Bus Stand / Anna Statue Junction'),
                              _buildModalRow('Bus Incharge / Driver', 'Murugan (+91 94861 22345)'),
                              _buildModalRow('One-way Distance', transport['oneWayDistanceKm']?.toString() ?? '18 km'),
                              _buildModalRow('Average Commute Duration', transport['oneWayTravelTimeMinutes']?.toString() ?? '35 mins'),
                              _buildModalRow('Usual Campus In-Time', transport['usualArrivalTime']?.toString() ?? '08:30 AM'),
                              _buildModalRow('Usual Departure Out-Time', transport['usualDepartureTime']?.toString() ?? '05:00 PM'),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Request Correction Action
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useRootNavigator: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const StudentProfileEditRequestModal(),
                        );
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text(
                        'Request Profile Correction',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= MODAL SHEETS FOR DETAIL VIEWS =================

  // 1. CONNECTED APPS & ACCOUNTS MODAL
  void _showConnectedProfilesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final overviewData = ref.watch(academicOverviewProvider);

            return _buildBottomSheetContainer(
              context: context,
              title: 'Connected Apps & Accounts',
              subtitle: 'Sync your GitHub, LeetCode, and LinkedIn activity with UNISPHERE',
              child: Column(
                children: [
                  _buildModalLinkTile(
                    title: 'LinkedIn Profile',
                    handle: overviewData.linkedinUrl.isNotEmpty ? overviewData.linkedinUrl : 'Not Linked (Tap to Connect)',
                    icon: Icons.work_rounded,
                    brandColor: const Color(0xFF0A66C2),
                    badge: overviewData.linkedinUrl.isNotEmpty ? 'Connected ✓' : 'Connect +',
                    onTap: () async {
                      if (overviewData.linkedinUrl.isEmpty) {
                        Navigator.pop(context);
                        _showSubmitLinkedInDialog(context, ref);
                        return;
                      }
                      await _safeLaunchUrl(overviewData.linkedinUrl);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildModalLinkTile(
                    title: 'GitHub Developer Account',
                    handle: overviewData.githubUsername.isNotEmpty ? '@${overviewData.githubUsername}' : 'Not Linked (Tap to Connect)',
                    icon: Icons.terminal_rounded,
                    brandColor: const Color(0xFF0F172A),
                    badge: overviewData.githubUsername.isNotEmpty ? '${overviewData.githubRepos} Repos ⚡' : 'Connect +',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GitHubDetailScreen()));
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildModalLinkTile(
                    title: 'LeetCode DSA Platform',
                    handle: overviewData.leetcodeUsername.isNotEmpty ? '@${overviewData.leetcodeUsername}' : 'Not Linked (Tap to Connect)',
                    icon: Icons.code_rounded,
                    brandColor: const Color(0xFFEA580C),
                    badge: overviewData.leetcodeUsername.isNotEmpty ? '${overviewData.leetcodeSolved} Solved 🏆' : 'Connect +',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeetCodeDetailScreen()));
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildModalLinkTile(
                    title: 'Personal Portfolio Website',
                    handle: 'https://saroo.online',
                    icon: Icons.language_rounded,
                    brandColor: const Color(0xFF2563EB),
                    badge: 'Live Site 🌐',
                    onTap: () => _safeLaunchUrl('https://saroo.online'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSubmitLinkedInDialog(context, ref);
                      },
                      icon: const Icon(Icons.add_link_rounded, size: 18),
                      label: const Text('Add / Update Social Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4338CA),
                        side: const BorderSide(color: Color(0xFFC7D2FE)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 2. ACADEMICS & MENTOR MODAL
  void _showAcademicsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheetContainer(
          context: context,
          title: 'Academics, CGPA & Mentor',
          subtitle: 'Official University curriculum, GPA, and Faculty Advisor',
          child: Column(
            children: [
              _buildModalInfoCard([
                _buildModalRow('Program & Degree', 'B.E. Computer Science and Engineering'),
                _buildModalRow('Section & Batch', 'Section A • Batch 1 (2022–2026)'),
                _buildModalRow('Current Semester', 'Semester VI (3rd Year)'),
                _buildModalRow('Cumulative GPA (CGPA)', '8.84 / 10.0', isBadge: true, badgeColor: const Color(0xFFD1FAE5), badgeTextColor: const Color(0xFF065F46)),
                _buildModalRow('Earned Credits', '112 / 160 Credits'),
                _buildModalRow('Date of Joining', '18 August 2022'),
              ]),
              const SizedBox(height: 14),

              // Semester-wise SGPA Breakdown
              _buildSectionPillHeader('Semester-Wise SGPA Performance'),
              _buildModalInfoCard([
                _buildModalRow('Semester I', '8.70 SGPA (Passed)'),
                _buildModalRow('Semester II', '8.80 SGPA (Passed)'),
                _buildModalRow('Semester III', '8.95 SGPA (Passed)'),
                _buildModalRow('Semester IV', '8.82 SGPA (Passed)'),
                _buildModalRow('Semester V', '8.90 SGPA (Passed)'),
                _buildModalRow('Semester VI (Current)', '8.84 Expected', isBadge: true, badgeColor: const Color(0xFFEEF2FF), badgeTextColor: const Color(0xFF4338CA)),
              ]),

              const SizedBox(height: 14),

              // Faculty Advisor Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_search_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Faculty Advisor / Mentor', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              Text('Dr. R. Ananth (Professor - CSE)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('ananth.r@unisphere.edu', style: TextStyle(fontSize: 11.5, color: Color(0xFF4338CA), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _safeLaunchUrl('mailto:ananth.r@unisphere.edu?subject=Student%20Consultation'),
                            icon: const Icon(Icons.email_outlined, size: 16),
                            label: const Text('Email Advisor'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4338CA),
                              side: const BorderSide(color: Color(0xFFC7D2FE)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showBookAppointmentDialog(context);
                            },
                            icon: const Icon(Icons.calendar_month_rounded, size: 16),
                            label: const Text('Book Meeting'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4338CA),
                              foregroundColor: Colors.white,
                              elevation: 0,
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
            ],
          ),
        );
      },
    );
  }

  // 3. CERTIFICATIONS MODAL
  void _showCertificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildBottomSheetContainer(
              context: context,
              title: 'Certifications & Credentials',
              subtitle: 'Verified records of NPTEL IIT & Industry Credentials (${_certifications.length} Credentials)',
              child: Column(
                children: [
                  ..._certifications.map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: InkWell(
                        onTap: () => _showCertificateDetailModal(context, c),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (c['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.workspace_premium_rounded, color: c['color'] as Color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['title'] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 2),
                                  Text('${c['issuer']} • ${c['score']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (c['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(c['badge'] as String, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: c['color'] as Color)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddCertificateDialog(context, (newCert) {
                          setModalState(() {
                            _certifications.add(newCert);
                          });
                          setState(() {});
                        });
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add New Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 4. DOCUMENT VAULT MODAL
  void _showDocumentVaultModal(BuildContext context) {
    final docs = [
      {'title': 'Student Formal Passport Photo', 'sub': 'JPEG • 0.8 MB • Verified ✓', 'icon': Icons.account_box_outlined},
      {'title': '10th Standard Marksheet', 'sub': 'PDF • 1.4 MB • Verified ✓', 'icon': Icons.picture_as_pdf_outlined},
      {'title': '12th Higher Secondary Marksheet', 'sub': 'PDF • 1.6 MB • Verified ✓', 'icon': Icons.picture_as_pdf_outlined},
      {'title': 'Transfer Certificate (TC)', 'sub': 'PDF • 0.9 MB • Verified ✓', 'icon': Icons.picture_as_pdf_outlined},
      {'title': 'Government Aadhar Copy', 'sub': 'PDF • 410 KB • Verified ✓', 'icon': Icons.badge_outlined},
      {'title': 'Community Certificate', 'sub': 'PDF • 650 KB • Verified ✓', 'icon': Icons.verified_outlined},
      {'title': 'Medical Fitness Certificate', 'sub': 'PDF • 530 KB • Verified ✓', 'icon': Icons.health_and_safety_outlined},
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheetContainer(
          context: context,
          title: 'Official Document Vault',
          subtitle: 'Download registrar-sealed digital records and verified marksheets',
          child: Column(
            children: docs.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4338CA).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(d['icon'] as IconData, color: const Color(0xFF4338CA), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(d['sub'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: Color(0xFF4338CA), size: 20),
                      onPressed: () => _simulateDocumentDownload(context, d['title'] as String),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 5. NOTIFICATION SETTINGS MODAL
  void _showNotificationSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildBottomSheetContainer(
              context: context,
              title: 'Notification Preferences',
              subtitle: 'Control alerts for announcements, grades, and exams',
              child: Column(
                children: [
                  _buildModalSwitch(
                    title: 'Academic Announcements',
                    sub: 'Instant alerts for official department circulars',
                    value: _announcementNotifs,
                    onChanged: (val) {
                      setModalState(() => _announcementNotifs = val);
                      setState(() => _announcementNotifs = val);
                      _showPreferenceUpdatedSnackbar('Academic Announcements preference saved');
                    },
                  ),
                  _buildModalSwitch(
                    title: 'Grade & Mark Release Alerts',
                    sub: 'Notification when internal or semester grades are out',
                    value: _gradeNotifs,
                    onChanged: (val) {
                      setModalState(() => _gradeNotifs = val);
                      setState(() => _gradeNotifs = val);
                      _showPreferenceUpdatedSnackbar('Grade alerts preference saved');
                    },
                  ),
                  _buildModalSwitch(
                    title: 'Daily Attendance Warning',
                    sub: 'Alert when attendance falls below 75%',
                    value: _attendanceNotifs,
                    onChanged: (val) {
                      setModalState(() => _attendanceNotifs = val);
                      setState(() => _attendanceNotifs = val);
                      _showPreferenceUpdatedSnackbar('Attendance warnings preference saved');
                    },
                  ),
                  _buildModalSwitch(
                    title: 'Fee Due Reminders',
                    sub: 'Reminders for upcoming tuition and exam fees',
                    value: _feeNotifs,
                    onChanged: (val) {
                      setModalState(() => _feeNotifs = val);
                      setState(() => _feeNotifs = val);
                      _showPreferenceUpdatedSnackbar('Fee reminders preference saved');
                    },
                  ),
                  _buildModalSwitch(
                    title: 'Placement & Job Drive Alerts',
                    sub: 'Instant notices for on-campus interview schedules',
                    value: _placementNotifs,
                    onChanged: (val) {
                      setModalState(() => _placementNotifs = val);
                      setState(() => _placementNotifs = val);
                      _showPreferenceUpdatedSnackbar('Placement alerts preference saved');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 6. SECURITY SETTINGS MODAL
  void _showSecuritySettingsModal(BuildContext context, UserModel? currentUser) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildBottomSheetContainer(
              context: context,
              title: 'Security & Authentication',
              subtitle: 'Password protection & Biometric login credentials',
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Account Created On', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                currentUser?.formattedCreatedAt ?? '15 Jan 2024',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                        ),
                      ],
                    ),
                  ),
                  _buildModalActionTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Account Password',
                    sub: 'Update your portal sign-in password',
                    onTap: () {
                      Navigator.pop(context);
                      _showChangePasswordDialog();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildModalSwitch(
                    title: 'Biometric 2FA Login',
                    sub: 'Use FaceID or Fingerprint to unlock portal',
                    value: _biometricEnabled,
                    onChanged: (val) {
                      setModalState(() => _biometricEnabled = val);
                      setState(() => _biometricEnabled = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(val ? '🔒 Biometric 2FA enabled' : '🔓 Biometric 2FA disabled')),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildModalActionTile(
                    icon: Icons.devices_rounded,
                    title: 'Active Logged-in Devices',
                    sub: 'iPhone 15 Pro • Active Now',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All other sessions signed out successfully.')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 6b. ACCOUNT INFO & REGISTRATION DETAILS MODAL
  void _showAccountInfoModal(BuildContext context, UserModel? currentUser) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheetContainer(
          context: context,
          title: 'Account & Registration Details',
          subtitle: 'Official UniSphere campus identity registration records',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildAccountMetaRow('Full Name', currentUser?.name ?? 'User'),
                    const Divider(height: 16),
                    _buildAccountMetaRow('Email Address', currentUser?.email ?? 'user@unisphere.edu'),
                    const Divider(height: 16),
                    _buildAccountMetaRow('Account Role', currentUser?.roleName ?? 'Student'),
                    const Divider(height: 16),
                    _buildAccountMetaRow('Account Creation Date', currentUser?.formattedCreatedAt ?? '15 Jan 2024', isHighlight: true),
                    const Divider(height: 16),
                    _buildAccountMetaRow('Account Status', 'Active & Verified 🟢'),
                    const Divider(height: 16),
                    _buildAccountMetaRow('Account UID', currentUser?.uid ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountMetaRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.primary : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // 7. VERIFICATION STATUS MODAL
  void _showVerificationStatusModal(BuildContext context, UserModel? currentUser) {
    final meta = currentUser?.metadata ?? {};
    final status = meta['verificationStatus'] ?? 'verified';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheetContainer(
          context: context,
          title: 'Campus Verification Status',
          subtitle: 'Institutional identity status verified by Registrar Office',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status == 'verified' ? '🟢 Verified Academic Profile' : '🟡 Verification Pending',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Approved by ${meta['verifiedBy'] ?? "Dr. R. Kumar (HOD, CSE)"} on 12 Sep 2022\nOfficial Seal ID: REG-UNI-2022-8812',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading Official Institutional Verification Certificate PDF...')),
                    );
                  },
                  icon: const Icon(Icons.download_done_rounded, size: 18),
                  label: const Text('Download Verification Certificate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 8. CAMPUS IT HELPDESK & SUPPORT MODAL
  void _showCampusSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheetContainer(
          context: context,
          title: 'Campus IT HelpDesk & Support',
          subtitle: 'Get technical assistance for Wi-Fi, LMS, ID badges, and portal accounts',
          child: Column(
            children: [
              _buildModalActionTile(
                icon: Icons.confirmation_number_outlined,
                title: 'Submit IT Support Ticket',
                sub: 'Report an issue with attendance, login, or ID card',
                onTap: () {
                  Navigator.pop(context);
                  _showSubmitTicketDialog(context);
                },
              ),
              const SizedBox(height: 10),
              _buildModalActionTile(
                icon: Icons.phone_in_talk_rounded,
                title: 'IT HelpDesk Emergency Hotline',
                sub: '+91 44 2250 1234 (Ext: 404)',
                onTap: () => _safeLaunchUrl('tel:+914422501234'),
              ),
              const SizedBox(height: 10),
              _buildModalActionTile(
                icon: Icons.mail_outline_rounded,
                title: 'Email Technical Support',
                sub: 'support@unisphere.edu',
                onTap: () => _safeLaunchUrl('mailto:support@unisphere.edu?subject=Unisphere%20Support%20Request'),
              ),
              const SizedBox(height: 10),
              _buildModalActionTile(
                icon: Icons.menu_book_outlined,
                title: 'Campus Student Handbook & FAQs',
                sub: 'Read portal guides and Wi-Fi configuration steps',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Student Knowledgebase & FAQs...')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= MODAL HELPER WIDGETS =================
  Widget _buildBottomSheetContainer({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + bottomPadding + 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalInfoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: rows,
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isBadge = false, Color? badgeColor, Color? badgeTextColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: isBadge
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor ?? const Color(0xFF4338CA),
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalLinkTile({
    required String title,
    required String handle,
    required IconData icon,
    required Color brandColor,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: brandColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        subtitle: Text(handle, style: TextStyle(fontSize: 11.5, color: brandColor, fontWeight: FontWeight.w600)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: brandColor)),
        ),
      ),
    );
  }

  Widget _buildModalSwitch({
    required String title,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        value: value,
        activeThumbColor: const Color(0xFF4338CA),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModalActionTile({
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4338CA).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4338CA), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      ),
    );
  }

  void _showPreferenceUpdatedSnackbar(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= DIALOGS & INTERACTIVE WORKFLOWS =================
  void _showSubmitLinkedInDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.work_rounded, color: Color(0xFF0A66C2)),
            SizedBox(width: 8),
            Text('Connect LinkedIn Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your full public LinkedIn Profile URL to connect and display on your student dashboard.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://linkedin.com/in/username',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                ref.read(academicOverviewProvider.notifier).updateData(linkedinUrl: text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('LinkedIn Profile linked successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A66C2), foregroundColor: Colors.white),
            child: const Text('Connect URL'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password (min 6 chars)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (newPass.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters.')));
                return;
              }
              if (newPass.text.trim() != confirmPass.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match.')));
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _isUploadingPhoto = true;
        _customPhotoPath = picked.path;
      });

      final currentUser = ref.read(authServiceProvider).currentUser;
      String finalPhotoUrl = picked.path;

      if (currentUser != null) {
        final storageService = ref.read(storageServiceProvider);
        final uploadedUrl = await storageService.uploadFile(
          storagePath: storageService.studentPhotoPath(currentUser.uid),
          file: File(picked.path),
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          finalPhotoUrl = uploadedUrl;
        }

        final updatedMeta = Map<String, dynamic>.from(currentUser.metadata ?? {});
        updatedMeta['passportPhotoUrl'] = finalPhotoUrl;
        updatedMeta['photoUrl'] = finalPhotoUrl;
        final updatedUser = currentUser.copyWith(
          profileImageUrl: finalPhotoUrl,
          metadata: updatedMeta,
        );

        await ref.read(authServiceProvider).updateUserProfile(updatedUser);

        final regNo = (updatedMeta['registerNumber'] ?? updatedMeta['regNo'])?.toString().trim();
        if (regNo != null && regNo.isNotEmpty) {
          ref.read(parentServiceProvider).cacheStudentProfile(regNo, {
            'fullName': updatedUser.fullName,
            'name': updatedUser.fullName,
            'photoUrl': finalPhotoUrl,
            'profileImageUrl': finalPhotoUrl,
            'passportPhotoUrl': finalPhotoUrl,
            ...updatedMeta,
          });
        }
      }

      if (mounted) {
        setState(() {
          _customPhotoPath = finalPhotoUrl;
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating photo: $e')),
        );
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      setState(() {
        _isUploadingPhoto = true;
      });

      final currentUser = ref.read(authServiceProvider).currentUser;
      final existingPhotoUrl = _customPhotoPath ?? (currentUser?.profileImageUrl ?? currentUser?.metadata?['passportPhotoUrl'] ?? currentUser?.metadata?['photoUrl'] ?? '').toString().trim();

      if (currentUser != null) {
        final storageService = ref.read(storageServiceProvider);
        if (existingPhotoUrl.isNotEmpty) {
          await storageService.deleteFile(existingPhotoUrl);
        }
        await storageService.deleteFile(storageService.studentPhotoPath(currentUser.uid));

        final updatedMeta = Map<String, dynamic>.from(currentUser.metadata ?? {});
        updatedMeta.remove('passportPhotoUrl');
        updatedMeta.remove('photoUrl');
        updatedMeta['passportPhotoUrl'] = '';
        updatedMeta['photoUrl'] = '';

        final updatedUser = currentUser.copyWith(
          profileImageUrl: '',
          metadata: updatedMeta,
        );

        await ref.read(authServiceProvider).updateUserProfile(updatedUser);

        final firestore = FirebaseFirestore.instance;
        final regNo = (updatedMeta['registerNumber'] ?? updatedMeta['regNo'])?.toString().trim();

        final deleteMap = {
          'profileImageUrl': '',
          'photoUrl': '',
          'passportPhotoUrl': '',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        try {
          await firestore.collection('users').doc(currentUser.uid).set(deleteMap, SetOptions(merge: true));
          await firestore.collection('students').doc(currentUser.uid).set(deleteMap, SetOptions(merge: true));
          await firestore.collection('student_profiles').doc(currentUser.uid).set({
            'photoUrl': '',
            'profileImageUrl': '',
            'personal.photoUrl': '',
            'personal.passportPhotoUrl': '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (regNo != null && regNo.isNotEmpty) {
            await firestore.collection('students').doc(regNo).set(deleteMap, SetOptions(merge: true));
            await firestore.collection('students').doc(regNo.toUpperCase()).set(deleteMap, SetOptions(merge: true));
            await firestore.collection('users').doc(regNo).set(deleteMap, SetOptions(merge: true));
            await firestore.collection('users').doc(regNo.toUpperCase()).set(deleteMap, SetOptions(merge: true));
            await firestore.collection('student_profiles').doc(regNo).set({
              'photoUrl': '',
              'profileImageUrl': '',
              'personal.photoUrl': '',
              'personal.passportPhotoUrl': '',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            ref.read(parentServiceProvider).cacheStudentProfile(regNo, {
              'fullName': updatedUser.fullName,
              'name': updatedUser.fullName,
              'photoUrl': '',
              'profileImageUrl': '',
              'passportPhotoUrl': '',
              ...updatedMeta,
            });
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _customPhotoPath = '';
          _isUploadingPhoto = false;
        });
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing photo: $e')),
        );
      }
    }
  }

  void _showUploadPassportPhotoModal(BuildContext context) {
    final currentUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    final currentPhoto = _customPhotoPath ?? (currentUser?.profileImageUrl ?? currentUser?.metadata?['passportPhotoUrl'] ?? currentUser?.metadata?['photoUrl'] ?? '').toString().trim();
    final hasPhoto = currentPhoto.isNotEmpty;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Profile Picture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Upload a clear formal passport size picture for campus ID and resume.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFEEF2FF), child: Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB))),
                title: const Text('Take a Photo (Camera)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFEEF2FF), child: Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB))),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              if (hasPhoto) ...[
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                  ),
                  title: const Text(
                    'Remove Profile Picture',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePhoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCertificateDetailModal(BuildContext context, Map<String, dynamic> cert) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: cert['color'] as Color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(cert['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildModalInfoCard([
              _buildModalRow('Issuing Authority', cert['issuer'] as String),
              _buildModalRow('Credential ID', cert['id'] as String? ?? 'NPTEL-2024-9912'),
              _buildModalRow('Issue Date', cert['date'] as String? ?? '2023–2024'),
              _buildModalRow('Score / Grade', cert['score'] as String, isBadge: true),
              _buildModalRow('Verification Status', 'Verified on Blockchain ✓', isBadge: true, badgeColor: const Color(0xFFD1FAE5), badgeTextColor: const Color(0xFF065F46)),
            ]),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credential badge link copied to clipboard!')));
                    },
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Share Badge'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading Certificate for ${cert['title']}...')));
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  void _showAddCertificateDialog(BuildContext context, Function(Map<String, dynamic>) onAdd) {
    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    final idCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Credential', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Certification Title', isDense: true, border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: issuerCtrl, decoration: const InputDecoration(labelText: 'Issuing Body (e.g. NPTEL, AWS)', isDense: true, border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: scoreCtrl, decoration: const InputDecoration(labelText: 'Score / Grade (e.g. 94% / Elite)', isDense: true, border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Credential ID / URL', isDense: true, border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                onAdd({
                  'title': titleCtrl.text.trim(),
                  'issuer': issuerCtrl.text.trim().isNotEmpty ? issuerCtrl.text.trim() : 'Professional Cert',
                  'badge': 'Verified ✓',
                  'color': const Color(0xFF2563EB),
                  'score': scoreCtrl.text.trim().isNotEmpty ? scoreCtrl.text.trim() : 'Passed',
                  'id': idCtrl.text.trim().isNotEmpty ? idCtrl.text.trim() : 'CERT-2024-NEW',
                  'date': 'Aug 2024',
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New certification added to your profile!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white),
            child: const Text('Save Certificate'),
          ),
        ],
      ),
    );
  }

  void _simulateDocumentDownload(BuildContext context, String docTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4338CA)),
            const SizedBox(height: 16),
            Text('Downloading $docTitle...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Verifying registrar cryptographic signature', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Downloaded $docTitle to Device Storage.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    });
  }

  void _showBookAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Book Mentor Consultation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Faculty Advisor: Dr. R. Ananth', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
            SizedBox(height: 6),
            Text('Available Slots: Monday – Friday (03:30 PM – 04:30 PM)\nVenue: CSE Faculty Cabin #204', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Purpose of Consultation',
                hintText: 'e.g. Project Review / Attendance / Career Advice',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment request sent to Dr. R. Ananth for confirmation.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  void _showSubmitTicketDialog(BuildContext context) {
    final subCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit IT Support Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Issue Subject', hintText: 'e.g. Wi-Fi MAC Address Whitelisting', isDense: true, border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', hintText: 'Provide details about the issue...', isDense: true, border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (subCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support Ticket #IT-2024-8902 submitted to Campus IT HelpDesk.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white),
            child: const Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }
}
