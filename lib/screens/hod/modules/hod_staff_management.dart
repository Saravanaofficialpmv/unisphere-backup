import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/staff_model.dart';
import 'package:unisphere/services/staff_service.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class HodStaffManagement extends ConsumerStatefulWidget {
  const HodStaffManagement({super.key});

  @override
  ConsumerState<HodStaffManagement> createState() => _HodStaffManagementState();
}

class _HodStaffManagementState extends ConsumerState<HodStaffManagement> {
  String _searchQuery = '';
  String _selectedDesignation = 'All';
  String _selectedRoleFilter = 'All'; // 'All', 'Advisors', 'Teaching Faculty'

  final List<StaffModel> _defaultMockStaff = [
    StaffModel(
      userId: 'DEMO-STF',
      employeeId: 'FAC-CSE-001',
      fullName: 'Dr. S. Meenakshi',
      departmentId: 'DEPT-CSE',
      departmentName: 'Computer Science',
      designation: 'Professor',
      specialization: 'Distributed Systems & Cloud',
      photoPath: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      assignedClasses: ['CS-A', 'CS-B'],
      assignedSubjects: ['Distributed Systems', 'Cloud Computing'],
      experienceYears: 14,
      isAdvisor: true,
      advisorSection: 'CS-A',
    ),
    StaffModel(
      userId: 'STF-DR-VANCE',
      employeeId: 'FAC-CSE-004',
      fullName: 'Dr. Robert Vance',
      departmentId: 'DEPT-CSE',
      departmentName: 'Computer Science',
      designation: 'Associate Professor',
      specialization: 'Data Structures & Algorithms',
      photoPath: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      assignedClasses: ['CS-A'],
      assignedSubjects: ['Data Structures', 'Algorithms'],
      experienceYears: 9,
      isAdvisor: true,
      advisorSection: 'CS-B',
    ),
    StaffModel(
      userId: 'FAC-CSE-008',
      employeeId: 'FAC-CSE-008',
      fullName: 'Dr. Anita Roy',
      departmentId: 'DEPT-CSE',
      departmentName: 'Computer Science',
      designation: 'Assistant Professor',
      specialization: 'Machine Learning & AI',
      photoPath: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      assignedClasses: ['CS-C'],
      assignedSubjects: ['Machine Learning', 'AI Fundamentals'],
      experienceYears: 6,
      isAdvisor: false,
      advisorSection: null,
    ),
    StaffModel(
      userId: 'FAC-CSE-012',
      employeeId: 'FAC-CSE-012',
      fullName: 'Prof. Vikram Sharma',
      departmentId: 'DEPT-CSE',
      departmentName: 'Computer Science',
      designation: 'Assistant Professor',
      specialization: 'Database Management',
      photoPath: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      assignedClasses: ['CS-B'],
      assignedSubjects: ['Database Management', 'SQL Labs'],
      experienceYears: 5,
      isAdvisor: false,
      advisorSection: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffMembersStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AppLiquidPullToRefresh(
        gifAsset: 'assets/tibsy-dp.gif',
        onRefresh: () async {
          ref.invalidate(staffMembersStreamProvider);
          await Future.delayed(const Duration(milliseconds: 1000));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildRoleAnalyticsSummary(staffAsync),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 24),
              staffAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Loader(label: 'Loading faculty records...'),
                  ),
                ),
                error: (err, _) => _buildStaffList(_defaultMockStaff),
                data: (liveStaff) {
                  // Merge live staff with default mock list if empty
                  final allStaff = liveStaff.isNotEmpty ? liveStaff : _defaultMockStaff;
                  return _buildStaffList(allStaff);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () => _showAddFacultyModal(context),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Add New Faculty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'DEPARTMENT ADMINISTRATION',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2),
        ),
        SizedBox(height: 4),
        Text(
          'Staff & Role Management',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        SizedBox(height: 2),
        Text(
          'Assign staff as Class Advisors to grant Students Panel & verification permissions',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildRoleAnalyticsSummary(AsyncValue<List<StaffModel>> staffAsync) {
    final list = staffAsync.value ?? _defaultMockStaff;
    final total = list.length;
    final advisors = list.where((s) => s.isAdvisor).length;
    final teaching = total - advisors;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Total Faculty', '$total', const Color(0xFF2563EB), Icons.groups_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard('Class Advisors', '$advisors', const Color(0xFF7C3AED), Icons.school_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard('Teaching Faculty', '$teaching', const Color(0xFF059669), Icons.co_present_rounded),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: 'Search faculty by name, ID, or subject...',
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterDropdown(
            'Role Filter',
            _selectedRoleFilter,
            ['All', 'Class Advisors', 'Teaching Faculty'],
            (val) => setState(() => _selectedRoleFilter = val!),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(
            'Designation',
            _selectedDesignation,
            ['All', 'Professor', 'Associate Professor', 'Assistant Professor'],
            (val) => setState(() => _selectedDesignation = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text('$label: $e'))).toList(),
        ),
      ),
    );
  }

  Widget _buildStaffList(List<StaffModel> allStaff) {
    final filtered = allStaff.where((s) {
      final matchesSearch = s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.employeeId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.assignedSubjects.any((sub) => sub.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesDesignation = _selectedDesignation == 'All' || s.designation == _selectedDesignation;

      final matchesRole = _selectedRoleFilter == 'All' ||
          (_selectedRoleFilter == 'Class Advisors' && s.isAdvisor) ||
          (_selectedRoleFilter == 'Teaching Faculty' && !s.isAdvisor);

      return matchesSearch && matchesDesignation && matchesRole;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: const [
            Icon(Icons.person_search_rounded, size: 54, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'No faculty members found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FACULTY DIRECTORY (${filtered.length})',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.1),
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = filtered[index];
            return _buildFacultyCard(context, item);
          },
        ),
      ],
    );
  }

  Widget _buildFacultyCard(BuildContext context, StaffModel staff) {
    final hasAdvisorRole = staff.isAdvisor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasAdvisorRole ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0),
          width: hasAdvisorRole ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFEFF6FF),
                backgroundImage: staff.photoPath != null && staff.photoPath!.isNotEmpty
                    ? NetworkImage(staff.photoPath!)
                    : null,
                child: staff.photoPath == null || staff.photoPath!.isEmpty
                    ? const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            staff.fullName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: hasAdvisorRole ? const Color(0xFFF5F3FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasAdvisorRole ? const Color(0xFFC4B5FD) : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasAdvisorRole ? Icons.school_rounded : Icons.co_present_rounded,
                                size: 12,
                                color: hasAdvisorRole ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasAdvisorRole
                                    ? 'Advisor (${staff.advisorSection ?? "General"})'
                                    : 'Teaching Faculty',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hasAdvisorRole ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${staff.designation} • ${staff.employeeId} • ${staff.departmentName}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Handled Subjects Chips
          if (staff.assignedSubjects.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: staff.assignedSubjects.map((sub) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sub,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Action Buttons: Assign/Edit Role and View Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Permissions Info Indicator
              Row(
                children: [
                  Icon(
                    hasAdvisorRole ? Icons.admin_panel_settings_rounded : Icons.lock_outline_rounded,
                    size: 15,
                    color: hasAdvisorRole ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    hasAdvisorRole ? 'Students Panel Unlocked' : 'Teaching Access Only',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: hasAdvisorRole ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              // HOD Role Assignment Trigger Button
              ElevatedButton.icon(
                onPressed: () => _showAssignRoleModal(context, staff),
                icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                label: Text(
                  hasAdvisorRole ? 'Edit Advisor Role' : 'Assign Advisor Role',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasAdvisorRole ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignRoleModal(BuildContext context, StaffModel staff) {
    bool isAdvisor = staff.isAdvisor;
    String selectedSection = staff.advisorSection ?? 'CS-A';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF7C3AED), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assign Faculty Role & Permissions',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '${staff.fullName} (${staff.employeeId})',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),

                // Option 1: Standard Teaching Faculty
                InkWell(
                  onTap: () => setModalState(() => isAdvisor = false),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: !isAdvisor ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !isAdvisor ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: !isAdvisor ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !isAdvisor ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: !isAdvisor ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '👨‍🏫 Teaching Faculty (Regular Staff)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Core academic functions: syllabus, assignments, marks upload, attendance, schedule, question papers',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: Class Advisor
                InkWell(
                  onTap: () => setModalState(() => isAdvisor = true),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isAdvisor ? const Color(0xFFF5F3FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAdvisor ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                        width: isAdvisor ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAdvisor ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: isAdvisor ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🎓 Class Advisor (Special Control)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Unlocks Students Panel: Student Directory, Resume Bank, Edit Requests, Approvals, & Hackathons',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isAdvisor) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFEDE9FE)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text(
                                'Assigned Section: ',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: selectedSection,
                                underline: const SizedBox.shrink(),
                                items: ['CS-A', 'CS-B', 'CS-C', 'AIML-A', 'IT-A', 'ECE-A']
                                    .map((sec) => DropdownMenuItem(value: sec, child: Text(sec, style: const TextStyle(fontWeight: FontWeight.bold))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedSection = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              await ref.read(staffServiceProvider).assignStaffRole(
                                    staffUid: staff.userId,
                                    isAdvisor: isAdvisor,
                                    advisorSection: isAdvisor ? selectedSection : null,
                                  );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isAdvisor
                                          ? '✅ ${staff.fullName} is now Class Advisor for Section $selectedSection!'
                                          : '✅ ${staff.fullName} set to Teaching Faculty.',
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating role: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save & Apply Role Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddFacultyModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final desigCtrl = TextEditingController(text: 'Assistant Professor');
    final subjectsCtrl = TextEditingController();
    bool isAdvisor = false;
    String advisorSection = 'CS-A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add New Faculty Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: desigCtrl,
                      decoration: InputDecoration(
                        labelText: 'Designation',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectsCtrl,
                      decoration: InputDecoration(
                        labelText: 'Subjects Handled (comma-separated)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Assign as Class Advisor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Grants access to Students Panel & verification modules', style: TextStyle(fontSize: 11.5)),
                      value: isAdvisor,
                      onChanged: (val) => setModalState(() => isAdvisor = val),
                    ),
                    if (isAdvisor) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: advisorSection,
                        decoration: InputDecoration(
                          labelText: 'Assigned Section',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: ['CS-A', 'CS-B', 'CS-C', 'AIML-A', 'IT-A', 'ECE-A']
                            .map((sec) => DropdownMenuItem(value: sec, child: Text(sec)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => advisorSection = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;

                          final newStaff = StaffModel(
                            userId: 'STAFF-${DateTime.now().millisecondsSinceEpoch}',
                            employeeId: 'FAC-CSE-${DateTime.now().millisecond}',
                            fullName: name,
                            departmentId: 'DEPT-CSE',
                            departmentName: 'Computer Science',
                            designation: desigCtrl.text.trim(),
                            specialization: subjectsCtrl.text.trim(),
                            assignedClasses: [advisorSection],
                            assignedSubjects: subjectsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                            isAdvisor: isAdvisor,
                            advisorSection: isAdvisor ? advisorSection : null,
                            createdAt: DateTime.now(),
                          );

                          await ref.read(staffServiceProvider).saveStaff(newStaff);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Faculty Member $name Added Successfully!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Save & Invite Faculty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
