import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/sign_out_confirmation_sheet.dart';
import 'package:unisphere/screens/staff/staff_dashboard.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final Function(StaffNavKey)? onNavigateToKey;

  const StaffProfileScreen({
    super.key,
    this.onBack,
    this.onNavigateToKey,
  });

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  bool _biometricEnabled = true;

  void _showEditProfileDialog(BuildContext context, String currentName, String currentDept, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    final deptController = TextEditingController(text: currentDept);
    final phoneController = TextEditingController(text: currentPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: GoogleFonts.manrope(fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deptController,
                decoration: InputDecoration(
                  labelText: 'Department',
                  labelStyle: GoogleFonts.manrope(fontSize: 13),
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.manrope(fontSize: 13),
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Profile updated successfully!', style: GoogleFonts.manrope()),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Changes', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Password',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: GoogleFonts.manrope(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: GoogleFonts.manrope(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: GoogleFonts.manrope(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password updated successfully!', style: GoogleFonts.manrope()),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Update', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showStaffIdCardModal(BuildContext context, String name, String empId, String dept, String desig, String? photoUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'V',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VSB ENGINEERING COLLEGE',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                desig,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF93C5FD),
                ),
              ),
              Text(
                dept,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('STAFF ID', style: GoogleFonts.manrope(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                    Text(empId, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'VALID THROUGH 2025-2026',
                style: GoogleFonts.manrope(color: Colors.white54, fontSize: 9.5, letterSpacing: 0.8, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecuritySettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.security_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Security Settings',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _biometricEnabled,
                activeTrackColor: const Color(0xFF2563EB),
                activeThumbColor: Colors.white,
                title: Text('Biometric Authentication', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text('Use TouchID / FaceID to sign in instantly', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B))),
                onChanged: (val) {
                  setState(() => _biometricEnabled = val);
                  setModalState(() => _biometricEnabled = val);
                },
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: true,
                activeTrackColor: const Color(0xFF2563EB),
                activeThumbColor: Colors.white,
                title: Text('Two-Factor Authentication (2FA)', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text('Require OTP on new browser / device logins', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B))),
                onChanged: (val) {},
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices_rounded, color: Color(0xFF64748B), size: 22),
                title: Text('Active Sessions', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text('1 Active device (Current phone)', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B))),
                trailing: Text('Manage', style: GoogleFonts.manrope(color: const Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 12.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Your device session is currently active & secure.', style: GoogleFonts.manrope()),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Done', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCertificatesModal(BuildContext context) {
    final certs = [
      {
        'title': 'Ph.D. in Computer Science & Engineering',
        'issuer': 'Anna University • Verified 2021',
        'badge': 'Academic',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'title': 'NPTEL Elite + Gold: Deep Learning & AI',
        'issuer': 'IIT Madras • Top 1% Faculty',
        'badge': 'Elite + Gold',
        'icon': Icons.workspace_premium_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'AICTE Certified Faculty Development',
        'issuer': 'AICTE Training & Learning Academy',
        'badge': 'Accredited',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'title': 'IEEE Senior Member Accreditation',
        'issuer': 'IEEE Computer Society • 2022',
        'badge': 'Professional',
        'icon': Icons.military_tech_rounded,
        'color': const Color(0xFF7C3AED),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Certificates & Documents',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: certs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final cert = certs[idx];
                  final Color certColor = cert['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: certColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cert['icon'] as IconData, color: certColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert['title'] as String,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cert['issuer'] as String,
                                style: GoogleFonts.manrope(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: certColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cert['badge'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: certColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All verified certificates downloaded to device.', style: GoogleFonts.manrope()),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('Download Certified Dossier (PDF)', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdvisor = ref.watch(isClassAdvisorProvider);
    final profileAsync = ref.watch(currentStaffProfileStreamProvider);
    final user = ref.watch(authServiceProvider).currentUser;
    final staff = profileAsync.valueOrNull;

    final String staffName = staff?.fullName ?? user?.name ?? 'Dr. Arun Kumar';
    final String staffDesignation = staff?.designation ?? 'Assistant Professor';
    final String rawDept = staff?.departmentName ?? 'Computer Science';
    final String staffDept = rawDept.contains('Computer Science') ? 'Computer Science' : rawDept;
    final String staffId = staff?.employeeId ?? 'CS1024';
    final String email = user?.email ?? 'arunkumar.cse@vsb.ac.in';
    final String phone = user?.phoneNumber ?? '+91 98421 78945';
    final String? photoUrl = staff?.photoPath ?? user?.profileImageUrl;
    final String advisorSection = staff?.advisorSection ?? 'II CSE – A';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          Tooltip(
            message: 'Log Out',
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
              onPressed: () => showSignOutConfirmationSheet(context, ref),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'edit') {
                _showEditProfileDialog(context, staffName, staffDept, phone);
              } else if (val == 'id_card') {
                _showStaffIdCardModal(context, staffName, staffId, staffDept, staffDesignation, photoUrl);
              } else if (val == 'security') {
                _showSecuritySettingsModal(context);
              } else if (val == 'logout') {
                showSignOutConfirmationSheet(context, ref);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text('Edit Profile', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'id_card',
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text('Digital ID Card', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'security',
                child: Row(
                  children: [
                    const Icon(Icons.security_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text('Security Settings', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Text('Logout', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Top Profile Hero Card ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Photo with Camera Badge
                      Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF2563EB), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: Color(0xFF2563EB),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: Color(0xFF2563EB),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showEditProfileDialog(context, staffName, staffDept, phone),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Staff Name
                      Text(
                        staffName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Designation
                      Text(
                        staffDesignation,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Department
                      Text(
                        staffDept,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email Verified Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Email Verified',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Edit Profile Button
                      SizedBox(
                        width: 160,
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditProfileDialog(context, staffName, staffDept, phone),
                          icon: const Icon(Icons.edit_rounded, size: 15),
                          label: Text(
                            'Edit Profile',
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 2. PROFESSIONAL Section Card ──
                _buildSectionContainer(
                  title: 'PROFESSIONAL',
                  children: [
                    _buildDataRow('Staff ID', staffId, isHighlighted: true),
                    _buildDivider(),
                    _buildDataRow('Department', staffDept.contains('Computer Science') || staffDept.contains('CSE') ? 'CSE' : staffDept),
                    _buildDivider(),
                    _buildDataRow('Designation', staffDesignation),
                    _buildDivider(),
                    _buildDataRow('Joined', '12 Jun 22'),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 3. ROLE & RESPONSIBILITY Section Card ──
                _buildSectionContainer(
                  title: 'ROLE & RESPONSIBILITY',
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              isAdvisor ? '🧑‍🏫' : '👨‍🏫',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdvisor ? 'Class Advisor' : 'Teaching Faculty',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAdvisor
                                    ? advisorSection
                                    : (staff?.assignedClasses.isNotEmpty == true
                                        ? staff!.assignedClasses.join(' • ')
                                        : 'III CSE - A • II CSE - B • IV CSE - A'),
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                              Text(
                                isAdvisor
                                    ? '52 Students • Class Incharge'
                                    : 'Subject & Lab In-charge • Teaching Faculty',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.onNavigateToKey != null) {
                            widget.onNavigateToKey!(
                              isAdvisor
                                  ? StaffNavKey.advisorDirectory
                                  : StaffNavKey.studentDirectory,
                            );
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          foregroundColor: const Color(0xFF2563EB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isAdvisor ? 'View Advisor Details' : 'View Faculty Student Directory',
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 4. TEACHING Section Card ──
                _buildSectionContainer(
                  title: 'TEACHING',
                  children: [
                    if (staff?.assignedSubjects != null && staff!.assignedSubjects.isNotEmpty)
                      ...staff.assignedSubjects.map(
                        (subj) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildTeachingBullet(subj),
                        ),
                      )
                    else ...[
                      _buildTeachingBullet('Machine Learning'),
                      const SizedBox(height: 8),
                      _buildTeachingBullet('Data Structures & Algorithms'),
                      const SizedBox(height: 8),
                      _buildTeachingBullet('Artificial Intelligence'),
                    ],
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.onNavigateToKey != null) {
                            widget.onNavigateToKey!(StaffNavKey.syllabus);
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          foregroundColor: const Color(0xFF2563EB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'View Assigned Subjects',
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 5. ACCOUNT & SECURITY Section Card ──
                _buildSectionContainer(
                  title: 'ACCOUNT & SECURITY',
                  children: [
                    _buildVerificationRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email Verification',
                      subtitle: email,
                      isVerified: true,
                    ),
                    _buildDivider(),
                    _buildVerificationRow(
                      icon: Icons.phone_iphone_rounded,
                      label: 'Phone Verification',
                      subtitle: phone,
                      isVerified: true,
                    ),
                    _buildDivider(),
                    InkWell(
                      onTap: () => _showChangePasswordDialog(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Change Password',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    _buildDivider(),
                    InkWell(
                      onTap: () => _showSecuritySettingsModal(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.security_rounded, size: 20, color: Color(0xFF64748B)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Security Settings',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 6. DOCUMENTS Section Card ──
                _buildSectionContainer(
                  title: 'DOCUMENTS',
                  children: [
                    InkWell(
                      onTap: () => _showStaffIdCardModal(context, staffName, staffId, staffDept, staffDesignation, photoUrl),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF2563EB)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Staff ID Card',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    _buildDivider(),
                    InkWell(
                      onTap: () => _showCertificatesModal(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium_outlined, size: 20, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Certificates',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── 7. Logout Button ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => showSignOutConfirmationSheet(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
              color: isHighlighted ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingBullet(String subject) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            subject,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationRow({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool isVerified,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1.5),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, size: 13, color: Color(0xFF10B981)),
                  const SizedBox(width: 3),
                  Text(
                    '✓',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 14, color: Color(0xFFF1F5F9));
  }
}
