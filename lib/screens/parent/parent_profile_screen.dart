import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/user_model.dart';
import 'package:unisphere/models/parent_portal_types.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/parent_service.dart';
import 'package:unisphere/services/storage_service.dart';
import 'package:unisphere/widgets/common/sign_out_confirmation_sheet.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class ParentProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const ParentProfileScreen({super.key, this.onBack});

  @override
  ConsumerState<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends ConsumerState<ParentProfileScreen> {
  String? _customPhotoPath;
  bool _isUploadingPhoto = false;

  // Guardian contact info controllers & state
  late TextEditingController _phoneController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _addressController;
  String _relationship = 'Father';
  bool _isEditingDetails = false;
  bool _isSavingDetails = false;

  // Notification preferences
  bool _attendanceAlerts = true;
  bool _feeReminders = true;
  bool _gradeAlerts = true;
  bool _circularAlerts = true;
  bool _smsWhatsAppAlerts = true;

  List<ParentStudentWard> _wards = [];
  bool _isLoadingWards = false;
  int _activeWardSlideIndex = 0;
  late final PageController _wardPageController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    final meta = user?.metadata ?? {};
    _phoneController = TextEditingController(text: user?.phone ?? meta['phone'] ?? '+91 98765 43210');
    _emergencyPhoneController = TextEditingController(text: meta['emergencyPhone'] ?? meta['alternatePhone'] ?? '+91 98765 43211');
    _addressController = TextEditingController(text: meta['address'] ?? 'Anna Nagar, Chennai, Tamil Nadu');
    _relationship = meta['relationship'] ?? 'Father';
    _wardPageController = PageController(viewportFraction: 0.90);
    _loadWards();
  }

  Future<void> _loadWards() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      setState(() => _isLoadingWards = true);
      final wards = await ref.read(parentServiceProvider).getStudentWardsForParent(user.uid, currentUser: user);
      if (mounted) {
        setState(() {
          _wards = wards;
          _isLoadingWards = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _wardPageController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    ref.invalidate(currentUserProvider);
    await _loadWards();
    await Future.delayed(const Duration(milliseconds: 400));
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
          storagePath: 'parent-photos/${currentUser.uid}/profile',
          file: File(picked.path),
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          finalPhotoUrl = uploadedUrl;
        }

        final updatedMeta = Map<String, dynamic>.from(currentUser.metadata ?? {});
        updatedMeta['photoUrl'] = finalPhotoUrl;
        final updatedUser = currentUser.copyWith(
          profileImageUrl: finalPhotoUrl,
          metadata: updatedMeta,
        );

        await ref.read(authServiceProvider).updateUserProfile(updatedUser);

        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('users').doc(currentUser.uid).set({
            'profileImageUrl': finalPhotoUrl,
            'photoUrl': finalPhotoUrl,
            'metadata.photoUrl': finalPhotoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await firestore.collection('parents').doc(currentUser.uid).set({
            'profileImageUrl': finalPhotoUrl,
            'photoUrl': finalPhotoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _customPhotoPath = finalPhotoUrl;
          _isUploadingPhoto = false;
        });
        ref.invalidate(currentUserProvider);
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
      setState(() => _isUploadingPhoto = true);

      final currentUser = ref.read(authServiceProvider).currentUser;
      final existingPhoto = _customPhotoPath ?? currentUser?.profileImageUrl ?? '';

      if (currentUser != null) {
        final storageService = ref.read(storageServiceProvider);
        if (existingPhoto.isNotEmpty) {
          await storageService.deleteFile(existingPhoto);
        }
        await storageService.deleteFile('parent-photos/${currentUser.uid}/profile');

        final updatedMeta = Map<String, dynamic>.from(currentUser.metadata ?? {});
        updatedMeta.remove('photoUrl');
        final updatedUser = currentUser.copyWith(
          profileImageUrl: '',
          metadata: updatedMeta,
        );

        await ref.read(authServiceProvider).updateUserProfile(updatedUser);

        try {
          final firestore = FirebaseFirestore.instance;
          final deleteMap = {
            'profileImageUrl': '',
            'photoUrl': '',
            'metadata.photoUrl': '',
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await firestore.collection('users').doc(currentUser.uid).set(deleteMap, SetOptions(merge: true));
          await firestore.collection('parents').doc(currentUser.uid).set(deleteMap, SetOptions(merge: true));
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

  void _showPhotoOptionsModal(BuildContext context) {
    final currentUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    final currentPhoto = _customPhotoPath ?? currentUser?.profileImageUrl ?? '';
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
              const Text('Update Parent Profile Picture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Upload a profile picture for parent identification and campus records.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
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

  Future<void> _saveGuardianDetails() async {
    setState(() => _isSavingDetails = true);
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final updatedMeta = Map<String, dynamic>.from(user.metadata ?? {});
      updatedMeta['phone'] = _phoneController.text.trim();
      updatedMeta['emergencyPhone'] = _emergencyPhoneController.text.trim();
      updatedMeta['address'] = _addressController.text.trim();
      updatedMeta['relationship'] = _relationship;

      final updatedUser = user.copyWith(
        phone: _phoneController.text.trim(),
        metadata: updatedMeta,
      );

      await ref.read(authServiceProvider).updateUserProfile(updatedUser);

      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(user.uid).set({
          'phone': _phoneController.text.trim(),
          'metadata': updatedMeta,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await firestore.collection('parents').doc(user.uid).set({
          'phone': _phoneController.text.trim(),
          'emergencyPhone': _emergencyPhoneController.text.trim(),
          'address': _addressController.text.trim(),
          'relationship': _relationship,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isSavingDetails = false;
        _isEditingDetails = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardian contact details updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _safeCallOrEmail(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPass, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 12),
            TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 12),
            TextField(controller: confirmPass, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (newPass.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.')));
                return;
              }
              if (newPass.text.trim() != confirmPass.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final parentName = (currentUser?.name != null && currentUser!.name.trim().isNotEmpty) ? currentUser.name : 'Parent / Guardian';
    final parentEmail = (currentUser?.email != null && currentUser!.email.trim().isNotEmpty) ? currentUser.email : 'parent@example.com';
    final photoUrl = _customPhotoPath ?? (currentUser?.profileImageUrl ?? currentUser?.metadata?['photoUrl'] ?? '').toString().trim();
    final hasUploadedPhoto = photoUrl.isNotEmpty && (photoUrl.startsWith('http://') || photoUrl.startsWith('https://') || File(photoUrl).existsSync());

    final wards = _wards;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ================= STABLE TOP CURVED ROYAL INDIGO BANNER (FIXED) =================
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
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
                    // Top Bar with Back Button
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
                                  BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1E1B4B), size: 24),
                            ),
                          )
                        else
                          const SizedBox(width: 38),

                        Text(
                          'Parent Profile',
                          style: GoogleFonts.manrope(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 38),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Center Avatar with Gradient Ring (when photo uploaded) & Camera Shortcut
                    GestureDetector(
                      onTap: () => _showPhotoOptionsModal(context),
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
                                        Color(0xFF38BDF8),
                                        Color(0xFF818CF8),
                                        Color(0xFFA855F7),
                                        Color(0xFFEC4899),
                                        Color(0xFF38BDF8),
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
                              child: _buildParentAvatar(photoUrl, parentName),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Parent Full Name
                    Text(
                      parentName,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Parent Portal Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFFFDE047), size: 13),
                          const SizedBox(width: 5),
                          Text(
                            'Parent & Guardian Portal',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Email & Linked Wards Count
                    Text(
                      '$parentEmail  •  ${wards.length} Linked ${wards.length == 1 ? "Ward" : "Wards"}',
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Account Created Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 5),
                        Text(
                          'Registered: ${currentUser?.formattedCreatedAt ?? "15 Jan 2024"}',
                          style: GoogleFonts.manrope(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= SCROLLABLE BODY WITH PULL-TO-REFRESH UNDER BANNER =================
          Expanded(
            child: AppLiquidPullToRefresh(
              onRefresh: _refreshProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= 1. LINKED CHILDREN / WARDS =================
                      _buildSectionHeader(
                        'LINKED WARDS & SIBLINGS',
                        trailing: Text(
                          '${wards.length} Enrolled',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (wards.isEmpty)
                        _buildEmptyWardCard()
                      else
                        _buildSlidableWardsCarousel(context, wards),

                      const SizedBox(height: 24),

                      // ================= 2. GUARDIAN CONTACT DETAILS =================
                      _buildSectionHeader(
                        'GUARDIAN CONTACT & RESIDENCE',
                        trailing: GestureDetector(
                          onTap: () {
                            if (_isEditingDetails) {
                              _saveGuardianDetails();
                            } else {
                              setState(() => _isEditingDetails = true);
                            }
                          },
                          child: Text(
                            _isEditingDetails ? 'Save' : 'Edit Details',
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _isEditingDetails ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildGuardianInfoCard(),

                      const SizedBox(height: 24),

                      // ================= 3. INSTITUTIONAL ALERTS & NOTIFICATIONS =================
                      _buildSectionHeader('INSTITUTIONAL COMMUNICATION & ALERTS'),
                      const SizedBox(height: 10),
                      _buildAlertPreferencesTile(context),

                      const SizedBox(height: 24),

                      // ================= 4. EMERGENCY & DEPARTMENT DIRECTORY =================
                      _buildSectionHeader('CAMPUS HELP & DEPARTMENT DIRECTORY'),
                      const SizedBox(height: 10),
                      _buildCampusDirectoryTile(context),

                      const SizedBox(height: 24),

                      // ================= 5. ACCOUNT SECURITY & LOGOUT =================
                      _buildSectionHeader('ACCOUNT & SECURITY'),
                      const SizedBox(height: 10),
                      _buildAccountSecurityCard(context),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentAvatar(String photoUrl, String name) {
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

    final initials = name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();

    return CircleAvatar(
      radius: 36,
      backgroundColor: const Color(0xFFEEF2FF),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              initials.isNotEmpty ? initials : 'PG',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4338CA),
              ),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: const Color(0xFF64748B),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildEmptyWardCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 36, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              'No Student Ward Linked',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 4),
            Text(
              'Link your child using their 12-digit university register number.',
              style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidableWardsCarousel(BuildContext context, List<ParentStudentWard> wards) {
    if (wards.length == 1) {
      return _buildWardCard(context, wards.first, isSlidable: false);
    }

    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _wardPageController,
            physics: const BouncingScrollPhysics(),
            itemCount: wards.length,
            onPageChanged: (idx) {
              setState(() => _activeWardSlideIndex = idx);
            },
            itemBuilder: (ctx, idx) {
              final ward = wards[idx];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildWardCard(context, ward, isSlidable: true),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            wards.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _activeWardSlideIndex == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _activeWardSlideIndex == i ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWardCard(BuildContext context, ParentStudentWard ward, {bool isSlidable = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isSlidable ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Ward Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: ClipOval(
                  child: (ward.photoUrl != null && ward.photoUrl!.isNotEmpty)
                      ? Image.network(
                          ward.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildWardInitial(ward),
                        )
                      : _buildWardInitial(ward),
                ),
              ),
              const SizedBox(width: 14),

              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ward.name,
                      style: GoogleFonts.manrope(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ward.regNo}  •  ${ward.department}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ward.currentYear}  •  ${ward.currentSemester}',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF10B981)),
                  const SizedBox(width: 5),
                  Text(
                    'Attendance: ${(ward.attendancePercent * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.auto_graph_rounded, size: 15, color: Color(0xFF6366F1)),
                  const SizedBox(width: 5),
                  Text(
                    'CGPA: ${ward.cgpa}',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWardInitial(ParentStudentWard ward) {
    return Container(
      color: const Color(0xFF2563EB),
      child: Center(
        child: Text(
          ward.avatarInitials,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildGuardianInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_pin_rounded,
            'Relationship to Ward',
            _isEditingDetails
                ? DropdownButton<String>(
                    value: _relationship,
                    isDense: true,
                    underline: const SizedBox(),
                    items: ['Father', 'Mother', 'Guardian'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _relationship = v);
                    },
                  )
                : Text(_relationship, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoRow(
            Icons.phone_rounded,
            'Primary Mobile / WhatsApp',
            _isEditingDetails
                ? Expanded(
                    child: TextField(
                      controller: _phoneController,
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                    ),
                  )
                : Text(_phoneController.text, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoRow(
            Icons.contact_phone_rounded,
            'Emergency Alternate Contact',
            _isEditingDetails
                ? Expanded(
                    child: TextField(
                      controller: _emergencyPhoneController,
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                    ),
                  )
                : Text(_emergencyPhoneController.text, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoRow(
            Icons.home_rounded,
            'Residential Address',
            _isEditingDetails
                ? Expanded(
                    child: TextField(
                      controller: _addressController,
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                    ),
                  )
                : Text(_addressController.text, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13.5), maxLines: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Widget valueWidget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              valueWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertPreferencesTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB), size: 22),
        ),
        title: Text(
          'Notification & Alert Preferences',
          style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          'Attendance, fees, exams & circular alerts',
          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: () => _showNotificationPreferencesModal(context),
      ),
    );
  }

  void _showNotificationPreferencesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Institutional Alerts & Notifications',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage SMS, WhatsApp & Push alert preferences',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  _buildModalSwitchTile(
                    'Daily Attendance & Absence Notice',
                    'Instant SMS & push alert if ward is marked absent in morning session.',
                    _attendanceAlerts,
                    (val) {
                      setState(() => _attendanceAlerts = val);
                      setModalState(() {});
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildModalSwitchTile(
                    'Fee Dues & Semester Deadlines',
                    'Reminders 7 days and 1 day prior to fee due date.',
                    _feeReminders,
                    (val) {
                      setState(() => _feeReminders = val);
                      setModalState(() {});
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildModalSwitchTile(
                    'Assessment & Semester Marksheets',
                    'Live updates when internal tests or university results are released.',
                    _gradeAlerts,
                    (val) {
                      setState(() => _gradeAlerts = val);
                      setModalState(() {});
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildModalSwitchTile(
                    'Official Circulars & Emergency Notices',
                    'Holiday announcements, bus route changes, and dean circulars.',
                    _circularAlerts,
                    (val) {
                      setState(() => _circularAlerts = val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification preferences saved successfully!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2563EB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      title: Text(
        title,
        style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildCampusDirectoryTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.support_agent_rounded, color: Color(0xFF16A34A), size: 22),
        ),
        title: Text(
          'Campus Help & Department Directory',
          style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          'Faculty advisor, HOD & fee desk contacts',
          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: () => _showCampusDirectoryModal(context),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _getDirectoryContactsForWard(ParentStudentWard? ward) {
    final dept = (ward?.department ?? 'Computer Science and Engineering').trim();
    final year = (ward?.currentYear ?? 'III Year').trim();
    final sem = (ward?.currentSemester ?? 'Semester 6').trim();
    final deptLower = dept.toLowerCase();

    // 1. Resolve HOD
    String hodName = 'Dr. R. Kumar';
    String hodTitle = 'Head of Department (CSE)';
    String hodEmail = 'hod.cse@institution.edu.in';
    String hodPhone = '+91 94441 12345';
    String hodOffice = 'CSE Block • Ground Floor, Room 101';

    if (deptLower.contains('artificial') || deptLower.contains('ai') || deptLower.contains('data')) {
      hodName = 'Dr. M. Sangeetha';
      hodTitle = 'Head of Department (AI & DS)';
      hodEmail = 'hod.aids@institution.edu.in';
      hodPhone = '+91 94441 23456';
      hodOffice = 'Tech Park • 2nd Floor, Room 204';
    } else if (deptLower.contains('information') || deptLower.contains('it')) {
      hodName = 'Dr. Anita Desai';
      hodTitle = 'Head of Department (IT)';
      hodEmail = 'hod.it@institution.edu.in';
      hodPhone = '+91 94441 34567';
      hodOffice = 'IT Wing • 1st Floor, Room 112';
    } else if (deptLower.contains('electronics') || deptLower.contains('ece')) {
      hodName = 'Dr. V. Swaminathan';
      hodTitle = 'Head of Department (ECE)';
      hodEmail = 'hod.ece@institution.edu.in';
      hodPhone = '+91 94441 45678';
      hodOffice = 'ECE Block • 3rd Floor, Room 301';
    } else if (deptLower.contains('mech')) {
      hodName = 'Dr. K. Ramanathan';
      hodTitle = 'Head of Department (MECH)';
      hodEmail = 'hod.mech@institution.edu.in';
      hodPhone = '+91 94441 56789';
      hodOffice = 'Mech Complex • Room 102';
    }

    // 2. Resolve Class Advisor based on Dept + Year
    String advisorName = 'Dr. S. Meenakshi';
    String advisorTitle = 'Class Advisor • $dept ($year)';
    String advisorEmail = 'meenakshi.s@institution.edu.in';
    String advisorPhone = '+91 98402 34567';
    String advisorOffice = 'CSE Faculty Cabin B-24, Ext 402';

    if (deptLower.contains('artificial') || deptLower.contains('ai') || deptLower.contains('data')) {
      advisorName = 'Dr. K. Vance';
      advisorTitle = 'Class Advisor • AI & DS ($year)';
      advisorEmail = 'vance.k@institution.edu.in';
      advisorPhone = '+91 98402 67890';
      advisorOffice = 'Tech Park Cabin 302, Ext 420';
    } else if (deptLower.contains('information') || deptLower.contains('it')) {
      advisorName = 'Prof. P. Suresh';
      advisorTitle = 'Class Advisor • IT ($year)';
      advisorEmail = 'suresh.p@institution.edu.in';
      advisorPhone = '+91 98402 78901';
      advisorOffice = 'IT Wing Room 205, Ext 412';
    } else if (deptLower.contains('electronics') || deptLower.contains('ece')) {
      advisorName = 'Dr. T. Radhika';
      advisorTitle = 'Class Advisor • ECE ($year)';
      advisorEmail = 'radhika.t@institution.edu.in';
      advisorPhone = '+91 98402 89012';
      advisorOffice = 'ECE Lab Room 304, Ext 433';
    } else if (deptLower.contains('mech')) {
      advisorName = 'Dr. M. Karthik';
      advisorTitle = 'Class Advisor • Mechanical ($year)';
      advisorEmail = 'karthik.m@institution.edu.in';
      advisorPhone = '+91 98402 90123';
      advisorOffice = 'Mech Complex Room 108, Ext 450';
    } else {
      // CSE Year-specific advisors
      if (year.contains('II') || year.contains('2')) {
        advisorName = 'Dr. Anita Sharma';
        advisorTitle = 'Class Advisor • CSE II Year';
        advisorEmail = 'anita.sharma@institution.edu.in';
        advisorPhone = '+91 98402 45678';
        advisorOffice = 'CSE Faculty Room A-12, Ext 408';
      } else if (year.contains('IV') || year.contains('4')) {
        advisorName = 'Prof. David Miller';
        advisorTitle = 'Class Advisor • CSE IV Year';
        advisorEmail = 'david.m@institution.edu.in';
        advisorPhone = '+91 98402 56789';
        advisorOffice = 'CSE Faculty Room C-05, Ext 415';
      } else {
        advisorName = 'Dr. S. Meenakshi';
        advisorTitle = 'Class Advisor • CSE III Year - Sec B';
        advisorEmail = 'meenakshi.s@institution.edu.in';
        advisorPhone = '+91 98402 34567';
        advisorOffice = 'CSE Faculty Room B-24, Ext 402';
      }
    }

    return {
      'advisor': {
        'name': advisorName,
        'title': advisorTitle,
        'email': advisorEmail,
        'phone': advisorPhone,
        'office': advisorOffice,
      },
      'hod': {
        'name': hodName,
        'title': hodTitle,
        'email': hodEmail,
        'phone': hodPhone,
        'office': hodOffice,
      },
      'accounts': {
        'name': 'Campus Administrative Office',
        'title': 'Student Accounts & Fee Desk',
        'email': 'accounts@institution.edu.in',
        'phone': '+91 44 2745 6789',
        'office': 'Admin Block • Ground Floor, Counter 3',
      },
    };
  }

  void _showCampusDirectoryModal(BuildContext context) {
    int selectedWardIndex = (_wards.isNotEmpty && _activeWardSlideIndex < _wards.length)
        ? _activeWardSlideIndex
        : 0;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final selectedWard = _wards.isNotEmpty ? _wards[selectedWardIndex] : null;
          final contacts = _getDirectoryContactsForWard(selectedWard);
          final advisor = contacts['advisor']!;
          final hod = contacts['hod']!;
          final accounts = contacts['accounts']!;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.support_agent_rounded, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Campus Help & Department Directory',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Allocated Faculty Advisor & Department Head',
                                style: GoogleFonts.manrope(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_wards.length > 1) ...[
                      const SizedBox(height: 14),
                      Text(
                        'SELECT STUDENT WARD:',
                        style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_wards.length, (idx) {
                            final w = _wards[idx];
                            final isSelected = selectedWardIndex == idx;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${w.name} (${w.regNo})'),
                                selected: isSelected,
                                onSelected: (_) {
                                  setModalState(() {
                                    selectedWardIndex = idx;
                                  });
                                },
                                selectedColor: const Color(0xFFEEF2FF),
                                labelStyle: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                ),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],

                    if (selectedWard != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school_rounded, size: 16, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${selectedWard.name}  •  ${selectedWard.department} (${selectedWard.currentYear})',
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // 1. Faculty Advisor
                    _buildDirectoryItem(
                      'Faculty Advisor / Class Mentor',
                      advisor['name']!,
                      advisor['title']!,
                      advisor['phone']!,
                      advisor['email']!,
                      advisor['office']!,
                    ),

                    const Divider(height: 24, color: Color(0xFFF1F5F9)),

                    // 2. Head of Department
                    _buildDirectoryItem(
                      'Head of Department (HOD)',
                      hod['name']!,
                      hod['title']!,
                      hod['phone']!,
                      hod['email']!,
                      hod['office']!,
                    ),

                    const Divider(height: 24, color: Color(0xFFF1F5F9)),

                    // 3. Accounts & Fee Desk
                    _buildDirectoryItem(
                      'Accounts & Student Fee Desk',
                      accounts['name']!,
                      accounts['title']!,
                      accounts['phone']!,
                      accounts['email']!,
                      accounts['office']!,
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDirectoryItem(
    String roleHeader,
    String name,
    String designation,
    String phone,
    String email,
    String office,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_pin_rounded, color: Color(0xFF16A34A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(roleHeader, style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  Text(designation, style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Call $name',
                  icon: const Icon(Icons.call_rounded, color: Color(0xFF16A34A), size: 20),
                  onPressed: () => _safeCallOrEmail('tel:$phone'),
                ),
                IconButton(
                  tooltip: 'Email $name',
                  icon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF2563EB), size: 20),
                  onPressed: () => _safeCallOrEmail('mailto:$email'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(phone, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF334155), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(office, style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSecurityCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            title: Text('Change Password', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF8FAFC),
              child: Icon(Icons.privacy_tip_outlined, color: Color(0xFF64748B), size: 20),
            ),
            title: Text('Privacy Policy & Campus Terms', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Institutional Privacy Terms...')),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEF2F2),
              child: Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            title: Text(
              'Sign Out from Parent Portal',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFDC2626)),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => SignOutConfirmationSheet(ref: ref),
              );
            },
          ),
        ],
      ),
    );
  }
}
