import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/hackathon_model.dart';
import 'package:unisphere/controllers/hackathon_controller.dart';
import 'package:unisphere/controllers/hackathon_registration_controller.dart';
import 'package:unisphere/screens/features/hackathon_team_management_screen.dart';
import 'package:unisphere/services/auth_service.dart';

class HackathonRegistrationScreen extends ConsumerStatefulWidget {
  final HackathonModel hackathon;

  const HackathonRegistrationScreen({super.key, required this.hackathon});

  @override
  ConsumerState<HackathonRegistrationScreen> createState() => _HackathonRegistrationScreenState();
}

class _HackathonRegistrationScreenState extends ConsumerState<HackathonRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _studentIdController;
  late final TextEditingController _studentNameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _leaderEmailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _teamNameController;
  late final TextEditingController _externalRegIdController;
  late final TextEditingController _screenshotUrlController;

  String _selectedYear = '3rd Year';
  String _selectedSection = 'Sec A';

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> _sections = ['Sec A', 'Sec B', 'Sec C', 'Sec D'];

  final List<TextEditingController> _memberControllers = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    final meta = user?.metadata ?? {};
    _studentIdController = TextEditingController(text: meta['registerNumber']?.toString() ?? meta['regNo']?.toString() ?? user?.uid ?? '');
    _studentNameController = TextEditingController(text: user?.fullName ?? user?.name ?? '');
    _departmentController = TextEditingController(text: meta['department']?.toString() ?? user?.departmentName ?? user?.department ?? '');
    _leaderEmailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? meta['phone']?.toString() ?? '');
    _teamNameController = TextEditingController();
    _externalRegIdController = TextEditingController();
    _screenshotUrlController = TextEditingController();

    final userYear = meta['year']?.toString();
    if (userYear != null && _years.contains(userYear)) {
      _selectedYear = userYear;
    }
    final userSection = meta['section']?.toString();
    if (userSection != null && _sections.contains(userSection)) {
      _selectedSection = userSection;
    }

    // Default up to 5 additional members (Max team size 6 total)
    final initialExtraMembers = (widget.hackathon.teamSize - 1).clamp(1, 5);
    for (int i = 0; i < initialExtraMembers; i++) {
      _memberControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    _departmentController.dispose();
    _leaderEmailController.dispose();
    _phoneController.dispose();
    _teamNameController.dispose();
    _externalRegIdController.dispose();
    _screenshotUrlController.dispose();
    for (var controller in _memberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    if (_memberControllers.length < 5) {
      setState(() {
        _memberControllers.add(TextEditingController());
      });
    }
  }

  void _removeMemberField(int index) {
    if (_memberControllers.isNotEmpty) {
      setState(() {
        _memberControllers[index].dispose();
        _memberControllers.removeAt(index);
      });
    }
  }

  String _getAdvisorName() {
    if (_selectedYear.isNotEmpty && _selectedSection.isNotEmpty) {
      return 'Class Advisor ($_selectedYear Sec $_selectedSection)';
    }
    return 'Assigned Class Advisor';
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final leaderName = _studentNameController.text.trim();

    final membersList = _memberControllers
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // 1. Validation: Self-duplication check
    for (var m in membersList) {
      if (m.toLowerCase().contains(leaderName.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Team Leader is automatically pinned as lead. Do not add yourself as an additional teammate.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    // 2. Validation: Duplicate members check
    final lowercaseMembers = membersList.map((m) => m.toLowerCase()).toList();
    if (lowercaseMembers.length != lowercaseMembers.toSet().length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Duplicate team members detected. Please remove duplicate entries.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // 3. Validation: Max 6 total members (1 Leader + 5 members max)
    final totalMembers = 1 + membersList.length;
    if (totalMembers > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Maximum team size exceeded! Up to 6 total members allowed (1 Team Leader + 5 Teammates).'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // 4. Validation: Minimum team size requirement
    if (widget.hackathon.minTeamSize > 1 && totalMembers < widget.hackathon.minTeamSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Minimum team size requirement not satisfied! Minimum ${widget.hackathon.minTeamSize} members required.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Dispatch registration to local reactive registration provider
      final registrationRecord = ref
          .read(hackathonRegistrationProvider.notifier)
          .registerStudentForHackathon(
            hackathon: widget.hackathon,
            studentId: _studentIdController.text.trim(),
            studentName: _studentNameController.text.trim(),
            department: _departmentController.text.trim(),
            year: _selectedYear,
            section: _selectedSection,
            email: _leaderEmailController.text.trim(),
            phone: _phoneController.text.trim(),
            teamName: _teamNameController.text.trim(),
            teamMembers: membersList,
            externalRegistrationId: _externalRegIdController.text.trim(),
            registrationScreenshotUrl: _screenshotUrlController.text.trim(),
          );

      // 2. Inform API controller
      final payload = {
        'studentId': _studentIdController.text.trim(),
        'studentName': _studentNameController.text.trim(),
        'department': _departmentController.text.trim(),
        'year': _selectedYear,
        'section': _selectedSection,
        'email': _leaderEmailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'teamName': _teamNameController.text.trim(),
        'members': membersList,
        'externalRegistrationId': _externalRegIdController.text.trim(),
        'registrationScreenshotUrl': _screenshotUrlController.text.trim(),
        'registrationDate': DateTime.now().toIso8601String(),
        'status': 'Pending Verification',
      };

      await ref.read(hackathonControllerProvider.notifier).registerTeam(widget.hackathon.id, payload);

      if (!mounted) return;

      final updatedHackathon = widget.hackathon.copyWith(
        userRegistrationStatus: 'registered',
        registrationId: registrationRecord.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Registration submitted to ${_getAdvisorName()} for verification!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HackathonTeamManagementScreen(hackathon: updatedHackathon),
        ),
      );
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedAdvisorText = _getAdvisorName();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'CMS Hackathon Team Registration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.hackathon.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Maximum Team Size: 6 Members (1 Leader + 5 Members) • ${widget.hackathon.mode}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Auto-Identified Advisor Callout Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('System Auto-Identified Advisor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                          const SizedBox(height: 2),
                          Text(assignedAdvisorText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Student & Academic Information Section
              const Text('1. Student & Academic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _studentIdController,
                      decoration: InputDecoration(
                        labelText: 'Student Register No / ID',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF64748B)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _studentNameController,
                      decoration: InputDecoration(
                        labelText: 'Team Leader Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Year & Section Dropdowns (Key Node for Advisor Identification)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedYear,
                      items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                      decoration: InputDecoration(
                        labelText: 'Academic Year',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSection,
                      items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedSection = val!),
                      decoration: InputDecoration(
                        labelText: 'Class Section',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.class_rounded, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _leaderEmailController,
                      decoration: InputDecoration(
                        labelText: 'Leader Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Contact Phone',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // External Registration Details & Proof Section
              const Text('2. External Registration & Proof Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),

              TextFormField(
                controller: _externalRegIdController,
                decoration: InputDecoration(
                  labelText: 'External Registration ID / Reference No.',
                  hintText: 'e.g. UNSTOP-88412 or DEVFOLIO-9921',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF4F46E5)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'External registration ID is required' : null,
              ),
              const SizedBox(height: 12),

              // Registration Screenshot Proof Upload Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Color(0xFF4F46E5), size: 20),
                        SizedBox(width: 8),
                        Text('Upload Registration Screenshot Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _screenshotUrlController,
                      decoration: InputDecoration(
                        hintText: 'Paste image URL or attachment path...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Please attach registration screenshot proof' : null,
                    ),
                    const SizedBox(height: 12),
                    // Image Preview Box
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _screenshotUrlController.text.trim(),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_rounded, color: Color(0xFF94A3B8)),
                                SizedBox(width: 8),
                                Text('Registration Proof Preview Attached', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Team Details & Members (Max 6)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('3. Team Details & Members (Max 6 Total)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  if (_memberControllers.length < 5)
                    TextButton.icon(
                      onPressed: _addMemberField,
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _teamNameController,
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  hintText: 'e.g. CodeCatalysts',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.groups_rounded, color: Color(0xFF64748B)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter team name' : null,
              ),
              const SizedBox(height: 16),

              Text('Additional Teammates (${_memberControllers.length} added / Up to 5 max):',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 10),

              ...List.generate(_memberControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _memberControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Member ${index + 2} Name & Email',
                            hintText: 'Student ${index + 2} (student${index + 2}@unisphere.edu)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444)),
                        onPressed: () => _removeMemberField(index),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRegistration,
                  icon: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 20),
                  label: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Text('Submit Team Registration to Advisor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
