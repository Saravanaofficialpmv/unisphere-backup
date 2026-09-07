import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/repositories/staff_repository.dart';
import 'package:unisphere/repositories/department_repository.dart';
import 'package:unisphere/services/auth_service.dart';

class HodStaffManagement extends ConsumerStatefulWidget {
  const HodStaffManagement({super.key});

  @override
  ConsumerState<HodStaffManagement> createState() => _HodStaffManagementState();
}

class _HodStaffManagementState extends ConsumerState<HodStaffManagement> {
  String _searchQuery = '';
  String _selectedDesignation = 'All';
  String _selectedStatus = 'All';
  String _selectedRoleFilter = 'All';

  final List<Map<String, dynamic>> _fallbackFacultyList = [
    {
      'id': 'DEMO-STF',
      'employeeId': 'FAC-CSE-001',
      'name': 'Dr. Arun Kumar',
      'designation': 'Assistant Professor',
      'department': 'CSE',
      'subjects': ['Machine Learning', 'Data Structures', 'Artificial Intelligence'],
      'phone': '+91 98765 43210',
      'email': 'arun.kumar@unisphere.edu',
      'attendance': 'Present',
      'leaveStatus': 'Active',
      'experience': '8 Years',
      'workload': '16 hrs/week',
      'rating': '4.9',
      'isClassAdvisor': true,
      'advisorSection': 'III CSE - A',
      'advisorAcademicYear': '2026–27',
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    },
    {
      'id': 'FAC-CSE-002',
      'employeeId': 'FAC-CSE-002',
      'name': 'Dr. S. Meenakshi',
      'designation': 'Professor & HOD',
      'department': 'CSE',
      'subjects': ['Distributed Systems', 'Cloud Computing'],
      'phone': '+91 98765 43211',
      'email': 'meenakshi.s@unisphere.edu',
      'attendance': 'Present',
      'leaveStatus': 'On Duty',
      'experience': '14 Years',
      'workload': '12 hrs/week',
      'rating': '4.9',
      'isClassAdvisor': false,
      'advisorSection': null,
      'advisorAcademicYear': null,
      'photo': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
    },
    {
      'id': 'FAC-CSE-004',
      'employeeId': 'FAC-CSE-004',
      'name': 'Prof. Rajesh Kumar',
      'designation': 'Associate Professor',
      'department': 'CSE',
      'subjects': ['Data Structures', 'Algorithms'],
      'phone': '+91 98765 11223',
      'email': 'rajesh.k@unisphere.edu',
      'attendance': 'Present',
      'leaveStatus': 'Active',
      'experience': '9 Years',
      'workload': '18 hrs/week',
      'rating': '4.7',
      'isClassAdvisor': false,
      'advisorSection': null,
      'advisorAcademicYear': null,
      'photo': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    },
    {
      'id': 'FAC-CSE-008',
      'employeeId': 'FAC-CSE-008',
      'name': 'Dr. Anita Roy',
      'designation': 'Assistant Professor',
      'department': 'CSE',
      'subjects': ['Machine Learning', 'AI Fundamentals'],
      'phone': '+91 98765 88990',
      'email': 'anita.roy@unisphere.edu',
      'attendance': 'On Leave',
      'leaveStatus': 'Casual Leave Approved',
      'experience': '6 Years',
      'workload': '14 hrs/week',
      'rating': '4.8',
      'isClassAdvisor': true,
      'advisorSection': 'II CSE - B',
      'advisorAcademicYear': '2026–27',
      'photo': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(hodStaffStreamProvider);
    final assignmentsAsync = ref.watch(hodAssignmentsStreamProvider);
    final assignments = assignmentsAsync.valueOrNull ?? [];

    final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final activeDeptName = (dept?.name != null && dept!.name.isNotEmpty && dept.name != 'Computer Science & Engineering')
        ? dept.name
        : (currentUser?.departmentName ??
            currentUser?.department ??
            currentUser?.metadata?['departmentName']?.toString() ??
            currentUser?.metadata?['department']?.toString() ??
            dept?.name ??
            'Department');
    final activeDeptCode = (dept?.code != null && dept!.code.isNotEmpty && dept.code != 'CSE')
        ? dept.code
        : DepartmentRepository.deriveDepartmentCode(activeDeptName);

    final rawStaffList = staffAsync.valueOrNull ?? [];
    final List<Map<String, dynamic>> facultyList = rawStaffList.isNotEmpty
        ? rawStaffList.map((s) {
            final advisorAsgn = assignments.cast<StaffAssignmentModel?>().firstWhere(
                  (a) => a != null && a.staffId == s.userId && a.isClassAdvisor && a.status == 'active',
                  orElse: () => null,
                );
            final isAdvisor = advisorAsgn != null || s.isAdvisor;
            return {
              'id': s.userId,
              'employeeId': s.employeeId.isNotEmpty ? s.employeeId : 'FAC-${s.userId}',
              'name': s.fullName,
              'designation': s.designation,
              'department': s.departmentName.isNotEmpty ? s.departmentName : activeDeptCode,
              'subjects': s.assignedSubjects,
              'phone': '+91 98765 43210',
              'email': '${s.userId.toLowerCase()}@unisphere.edu',
              'attendance': 'Present',
              'leaveStatus': 'Active',
              'experience': '${s.experienceYears > 0 ? s.experienceYears : 8} Years',
              'workload': '16 hrs/week',
              'rating': '4.9',
              'isClassAdvisor': isAdvisor,
              'advisorSection': advisorAsgn?.section ?? advisorAsgn?.className ?? s.advisorSection ?? 'III $activeDeptCode - A',
              'advisorAcademicYear': advisorAsgn?.academicYear ?? s.advisorAcademicYear ?? '2026–27',
              'photo': s.photoPath ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
            };
          }).toList()
        : _fallbackFacultyList.map((f) => {
            ...f,
            'department': activeDeptCode,
            'advisorSection': f['advisorSection']?.toString().replaceAll('CSE', activeDeptCode),
          }).toList();

    final filteredStaff = facultyList.where((faculty) {
      final matchesSearch = faculty['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faculty['employeeId'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faculty['subjects'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDesignation = _selectedDesignation == 'All' || faculty['designation'].toString().contains(_selectedDesignation);
      final matchesStatus = _selectedStatus == 'All' || faculty['attendance'] == _selectedStatus;
      final matchesAdvisor = _selectedRoleFilter == 'All' ||
          (_selectedRoleFilter == 'Class Advisor' && faculty['isClassAdvisor'] == true);

      return matchesSearch && matchesDesignation && matchesStatus && matchesAdvisor;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 24),
            Text(
              'FACULTY & RESPONSIBILITY DIRECTORY (${filteredStaff.length})',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStaff.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = filteredStaff[index];
                return _buildFacultyCard(context, item);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEPARTMENT ADMINISTRATION',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Faculty & Staff Directory',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddFacultyModal(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.hodRole,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
          label: Text(
            'Add Faculty',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search faculty by name, ID, or subject...',
          hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            'Designation',
            _selectedDesignation,
            ['All', 'Professor', 'Associate Professor', 'Assistant Professor'],
            (val) => setState(() => _selectedDesignation = val!),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(
            'Status',
            _selectedStatus,
            ['All', 'Present', 'On Leave'],
            (val) => setState(() => _selectedStatus = val!),
          ),
          const SizedBox(width: 10),
          _buildFilterChip('Class Advisor', _selectedRoleFilter == 'Class Advisor', () {
            setState(() {
              _selectedRoleFilter = _selectedRoleFilter == 'Class Advisor' ? 'All' : 'Class Advisor';
            });
          }),
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
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
          style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text('$label: $e'))).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.hodRole : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.hodRole : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffAvatar(String? photo, String name, {double radius = 26}) {
    final cleanPhoto = (photo ?? '').trim();
    final isValidUrl = cleanPhoto.isNotEmpty && (cleanPhoto.startsWith('http://') || cleanPhoto.startsWith('https://'));
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage: isValidUrl ? NetworkImage(cleanPhoto) : null,
      child: !isValidUrl
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildFacultyCard(BuildContext context, Map<String, dynamic> item) {
    final attendanceStr = item['attendance']?.toString() ?? 'Present';
    final isPresent = attendanceStr == 'Present';
    final isAdvisor = item['isClassAdvisor'] == true;
    final advisorClass = item['advisorSection']?.toString() ?? 'III CSE - A';
    final advisorYear = item['advisorAcademicYear']?.toString() ?? '2025–26';
    final staffName = item['name']?.toString() ?? 'Faculty Member';
    final designation = item['designation']?.toString() ?? 'Faculty';
    final employeeId = item['employeeId']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
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
              _buildStaffAvatar(item['photo']?.toString(), staffName, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            staffName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPresent ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            attendanceStr,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$designation • $employeeId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Assigned Subjects
          Text(
            'Assigned Subjects:',
            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (item['subjects'] as List? ?? []).map((sub) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sub.toString(),
                  style: GoogleFonts.manrope(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Responsibilities Badge section
          Text(
            'Responsibilities:',
            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Faculty',
                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              if (isAdvisor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.hodRole.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.hodRole.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, size: 13, color: AppColors.hodRole),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Class Advisor: $advisorClass ($advisorYear)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.hodRole,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Actions Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAssignResponsibilityModal(context, item),
                icon: const Icon(Icons.assignment_ind_rounded, size: 15, color: AppColors.hodRole),
                label: Text(
                  isAdvisor ? 'Edit Assignment' : 'Assign Responsibility',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.hodRole,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.hodRole),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showFacultyDetailsModal(context, item),
                icon: const Icon(Icons.badge_outlined, size: 15),
                label: Text(
                  'View Profile',
                  style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignResponsibilityModal(BuildContext context, Map<String, dynamic> staffItem) {
    String selectedType = 'Class Advisor';
    String selectedClass = staffItem['advisorSection'] ?? 'III CSE - A';
    String selectedYear = staffItem['advisorAcademicYear'] ?? '2025–26';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ASSIGN RESPONSIBILITY',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Staff Member read-only card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _buildStaffAvatar(staffItem['photo']?.toString(), staffItem['name']?.toString() ?? '', radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staffItem['name'],
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${staffItem['designation']} • ${staffItem['department']}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Responsibility Type Dropdown
                    Text(
                      'Responsibility Type',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Class Advisor', child: Text('Class Advisor')),
                        DropdownMenuItem(value: 'Subject Faculty', child: Text('Subject Faculty')),
                        DropdownMenuItem(value: 'Department Responsibility', child: Text('Department Responsibility')),
                        DropdownMenuItem(value: 'Exam Responsibility', child: Text('Exam Responsibility')),
                        DropdownMenuItem(value: 'Committee Member', child: Text('Committee Member')),
                      ],
                      onChanged: (val) => setModalState(() => selectedType = val!),
                    ),
                    const SizedBox(height: 14),

                    // Department & Class Dropdown
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Department', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text('CSE', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assigned Class', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedClass,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'III CSE - A', child: Text('III CSE - A')),
                                  DropdownMenuItem(value: 'III CSE - B', child: Text('III CSE - B')),
                                  DropdownMenuItem(value: 'II CSE - A', child: Text('II CSE - A')),
                                  DropdownMenuItem(value: 'II CSE - B', child: Text('II CSE - B')),
                                  DropdownMenuItem(value: 'IV CSE - A', child: Text('IV CSE - A')),
                                ],
                                onChanged: (val) => setModalState(() => selectedClass = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Academic Year & Dates
                    Text('Academic Year', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedYear,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: '2025–26', child: Text('2025–26')),
                        DropdownMenuItem(value: '2026–27', child: Text('2026–27')),
                        DropdownMenuItem(value: '2024–25', child: Text('2024–25')),
                      ],
                      onChanged: (val) => setModalState(() => selectedYear = val!),
                    ),
                    const SizedBox(height: 20),

                    // Actions (Cancel / Assign)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final staffId = staffItem['id'] as String;
                              final currentDeptId = ref.read(hodDepartmentIdProvider);
                              final currentUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
                              final hodName = currentUser?.fullName ?? currentUser?.name ?? 'Head of Department';
                              final assignment = StaffAssignmentModel(
                                id: 'ASGN-${DateTime.now().millisecondsSinceEpoch}',
                                staffId: staffId,
                                staffName: staffItem['name'],
                                departmentId: currentDeptId,
                                assignmentType: selectedType == 'Class Advisor'
                                    ? StaffAssignmentType.classAdvisor
                                    : StaffAssignmentType.subjectFaculty,
                                classId: 'CLASS-$selectedClass',
                                className: selectedClass,
                                section: selectedClass,
                                academicYear: selectedYear,
                                assignedBy: '$hodName (HOD)',
                                status: 'active',
                              );

                              // Update local list for immediate visual responsiveness
                              setState(() {
                                staffItem['isClassAdvisor'] = selectedType == 'Class Advisor';
                                staffItem['advisorSection'] = selectedClass;
                                staffItem['advisorAcademicYear'] = selectedYear;
                              });

                              // Persist to repository
                              await ref.read(staffRepositoryProvider).assignResponsibility(assignment);

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Successfully assigned ${staffItem['name']} as $selectedType for $selectedClass!'),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.hodRole,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Assign Responsibility',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFacultyDetailsModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DefaultTabController(
          length: 4,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildStaffAvatar(item['photo']?.toString(), item['name']?.toString() ?? '', radius: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${item['designation']} (${item['employeeId']})',
                              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Basic Info'),
                    Tab(text: 'Subjects'),
                    Tab(text: 'Responsibilities'),
                    Tab(text: 'Workload'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDetailTile(Icons.email_outlined, 'Email Address', item['email']),
                          _buildDetailTile(Icons.phone_outlined, 'Phone Number', item['phone']),
                          _buildDetailTile(Icons.work_outline, 'Experience', item['experience']),
                          _buildDetailTile(Icons.star_outline, 'Rating', '${item['rating']} / 5.0'),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: (item['subjects'] as List<String>)
                            .map((s) => _buildDetailTile(Icons.menu_book_rounded, 'Subject', s))
                            .toList(),
                      ),
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDetailTile(Icons.school_rounded, 'Role', 'Faculty Member'),
                          if (item['isClassAdvisor'] == true)
                            _buildDetailTile(
                              Icons.stars_rounded,
                              'Class Advisor',
                              '${item['advisorSection']} (${item['advisorAcademicYear']})',
                            ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDetailTile(Icons.timer_outlined, 'Weekly Workload', item['workload']),
                          _buildDetailTile(Icons.check_circle_outline_rounded, 'Status', item['attendance']),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(val, style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddFacultyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    Text('Add New Faculty Member', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                const SizedBox(height: 12),
                TextField(decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                const SizedBox(height: 12),
                TextField(decoration: InputDecoration(labelText: 'Designation (e.g. Assistant Professor)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Faculty Member Added Successfully!'), backgroundColor: AppColors.success),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Submit & Send Invitation', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
