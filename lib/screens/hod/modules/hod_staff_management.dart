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
      'id': 'UNI-STF-CSE-001',
      'employeeId': 'UNI-STF-CSE-001',
      'name': 'Arun Kumar',
      'designation': 'Assistant Professor',
      'department': 'CSE',
      'subjects': ['Machine Learning', 'Data Structures', 'Artificial Intelligence'],
      'phone': '+91 98765 43210',
      'email': 'arun@college.edu',
      'attendance': 'Present',
      'leaveStatus': 'Active',
      'experience': '8 Years',
      'workload': '16 hrs/week',
      'rating': '4.9',
      'isClassAdvisor': true,
      'advisorSection': 'III CSE - A',
      'advisorAcademicYear': '2025–26',
      'otherResponsibilities': <String>[],
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    },
    {
      'id': 'UNI-STF-CSE-002',
      'employeeId': 'UNI-STF-CSE-002',
      'name': 'Priya Devi',
      'designation': 'Associate Professor',
      'department': 'CSE',
      'subjects': ['Cloud Computing', 'Distributed Systems'],
      'phone': '+91 98765 43211',
      'email': 'priya@college.edu',
      'attendance': 'Present',
      'leaveStatus': 'Active',
      'experience': '10 Years',
      'workload': '14 hrs/week',
      'rating': '4.9',
      'isClassAdvisor': false,
      'advisorSection': null,
      'advisorAcademicYear': null,
      'otherResponsibilities': ['Exam Coordinator'],
      'photo': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
    },
    {
      'id': 'UNI-STF-CSE-003',
      'employeeId': 'UNI-STF-CSE-003',
      'name': 'Dr. K. Tharani Kumar',
      'designation': 'Assistant Professor',
      'department': 'CSE',
      'subjects': ['Artificial Intelligence', 'Data Analytics'],
      'phone': '+91 98765 43212',
      'email': 'tharani.kumar@college.edu',
      'attendance': 'Present',
      'leaveStatus': 'Active',
      'experience': '8 Years',
      'workload': '16 hrs/week',
      'rating': '4.9',
      'isClassAdvisor': true,
      'advisorSection': 'III CSE - A',
      'advisorAcademicYear': '2025–26',
      'otherResponsibilities': ['Lab In-charge (AI Lab)'],
      'photo': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    },
    {
      'id': 'UNI-STF-CSE-004',
      'employeeId': 'UNI-STF-CSE-004',
      'name': 'Prof. Rajesh Kumar',
      'designation': 'Associate Professor',
      'department': 'CSE',
      'subjects': ['Data Structures', 'Algorithms'],
      'phone': '+91 98765 11223',
      'email': 'rajesh.k@college.edu',
      'attendance': 'Present',
      'leaveStatus': 'Active',
      'experience': '9 Years',
      'workload': '18 hrs/week',
      'rating': '4.7',
      'isClassAdvisor': false,
      'advisorSection': null,
      'advisorAcademicYear': null,
      'otherResponsibilities': ['Timetable Coordinator'],
      'photo': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    },
    {
      'id': 'UNI-STF-CSE-005',
      'employeeId': 'UNI-STF-CSE-005',
      'name': 'Dr. Anita Roy',
      'designation': 'Assistant Professor',
      'department': 'CSE',
      'subjects': ['Machine Learning', 'AI Fundamentals'],
      'phone': '+91 98765 88990',
      'email': 'anita.roy@college.edu',
      'attendance': 'On Leave',
      'leaveStatus': 'Casual Leave Approved',
      'experience': '6 Years',
      'workload': '14 hrs/week',
      'rating': '4.8',
      'isClassAdvisor': true,
      'advisorSection': 'II CSE - B',
      'advisorAcademicYear': '2025–26',
      'otherResponsibilities': <String>[],
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
                  (a) => a != null && (a.staffId == s.userId || a.staffId == s.employeeId) && a.isClassAdvisor && a.status == 'active',
                  orElse: () => null,
                );
            final otherAsgns = assignments
                .where((a) => (a.staffId == s.userId || a.staffId == s.employeeId) && a.status == 'active' && a.assignmentType != StaffAssignmentType.classAdvisor)
                .map((a) => a.responsibilityTitle ?? a.subjectName ?? a.assignmentType.displayName)
                .toList();

            final isAdvisor = advisorAsgn != null || s.isAdvisor;
            return {
              'id': s.userId,
              'employeeId': s.employeeId.isNotEmpty ? s.employeeId : 'UNI-STF-$activeDeptCode-${s.userId}',
              'name': s.fullName,
              'designation': s.designation,
              'department': s.departmentName.isNotEmpty ? s.departmentName : activeDeptCode,
              'subjects': s.assignedSubjects,
              'phone': '+91 98765 43210',
              'email': s.email ?? '${s.fullName.toLowerCase().replaceAll(' ', '.').replaceAll('dr.', '')}@college.edu',
              'attendance': 'Present',
              'leaveStatus': 'Active',
              'experience': '${s.experienceYears > 0 ? s.experienceYears : 8} Years',
              'workload': '16 hrs/week',
              'rating': '4.9',
              'isClassAdvisor': isAdvisor,
              'advisorSection': advisorAsgn?.section ?? advisorAsgn?.className ?? s.advisorSection ?? 'III $activeDeptCode - A',
              'advisorAcademicYear': advisorAsgn?.academicYear ?? s.advisorAcademicYear ?? '2025–26',
              'otherResponsibilities': otherAsgns,
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
          faculty['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
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
    final email = item['email']?.toString() ?? 'staff@college.edu';
    final designation = item['designation']?.toString() ?? 'Faculty';
    final employeeId = item['employeeId']?.toString() ?? '';
    final otherResponsibilities = (item['otherResponsibilities'] as List?)?.map((e) => e.toString()).toList() ?? [];

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
          // Header: Avatar, Name, Email, ID & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 12, color: AppColors.hodRole),
                        const SizedBox(width: 4),
                        Text(
                          'ID: $employeeId',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.hodRole,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• $designation',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

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
          const SizedBox(height: 10),

          // Responsibilities Badge section
          Text(
            'Active Responsibilities:',
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
                  'Subject Faculty',
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
              for (final resp in otherResponsibilities)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 12, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 4),
                      Text(
                        resp,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C3AED),
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
              ElevatedButton.icon(
                onPressed: () => _showAssignResponsibilityModal(context, item),
                icon: const Icon(Icons.assignment_ind_rounded, size: 15, color: Colors.white),
                label: Text(
                  'Assign Work',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hodRole,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showFacultyDetailsModal(context, item),
                icon: const Icon(Icons.badge_outlined, size: 15, color: AppColors.primary),
                label: Text(
                  'View Profile',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignResponsibilityModal(BuildContext context, Map<String, dynamic> staffItem) {
    // Branch Selection: 1. Subject Faculty, 2. Class Advisor, 3. Other Department Responsibility
    String selectedBranch = staffItem['isClassAdvisor'] == true ? 'Class Advisor' : 'Subject Faculty';
    String selectedClass = staffItem['advisorSection'] ?? 'III CSE - A';
    String selectedYear = staffItem['advisorAcademicYear'] ?? '2025–26';
    String selectedSubject = (staffItem['subjects'] as List?)?.isNotEmpty == true ? staffItem['subjects'][0] : 'Machine Learning';
    String subjectCode = 'CS8691';
    String selectedDeptResp = 'Exam Coordinator';
    final customRespController = TextEditingController();

    final List<Map<String, String>> presetSubjects = [
      {'name': 'Machine Learning', 'code': 'CS8691'},
      {'name': 'Data Structures', 'code': 'CS8392'},
      {'name': 'Artificial Intelligence', 'code': 'CS8791'},
      {'name': 'Cloud Computing', 'code': 'CS8651'},
      {'name': 'Operating Systems', 'code': 'CS8492'},
      {'name': 'Database Management Systems', 'code': 'CS8491'},
      {'name': 'Design & Analysis of Algorithms', 'code': 'CS8451'},
      {'name': 'Internet Programming', 'code': 'CS8652'},
    ];

    final List<String> presetDeptResponsibilities = [
      'Exam Coordinator',
      'Placement & Internship In-charge',
      'Timetable & Workload Coordinator',
      'Lab In-charge / Infrastructure',
      'NBA / NAAC Accreditation Coordinator',
      'Project & Hackathon In-charge',
      'Department Symposium & Events Convenor',
      'Research & Publication Coordinator',
      'Other Custom Responsibility',
    ];

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ASSIGN WORK & RESPONSIBILITY',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Assign teaching or administrative roles to faculty',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.textSecondary,
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
                                  staffItem['name'] ?? '',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${staffItem['email']} • ID: ${staffItem['employeeId']}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3-Way Work Branch Selector
                    Text(
                      'SELECT WORK CATEGORY',
                      style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWorkTypeTab(
                            title: 'Subject Faculty',
                            icon: Icons.menu_book_rounded,
                            isSelected: selectedBranch == 'Subject Faculty',
                            onTap: () => setModalState(() => selectedBranch = 'Subject Faculty'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildWorkTypeTab(
                            title: 'Class Advisor',
                            icon: Icons.stars_rounded,
                            isSelected: selectedBranch == 'Class Advisor',
                            onTap: () => setModalState(() => selectedBranch = 'Class Advisor'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildWorkTypeTab(
                            title: 'Other Dept',
                            icon: Icons.account_tree_outlined,
                            isSelected: selectedBranch == 'Other Dept',
                            onTap: () => setModalState(() => selectedBranch = 'Other Dept'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Branch 1: Subject Faculty Form ──
                    if (selectedBranch == 'Subject Faculty') ...[
                      Text(
                        'Select Subject / Course',
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubject,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: presetSubjects.map((sub) {
                          return DropdownMenuItem(
                            value: sub['name']!,
                            child: Text('${sub['name']} (${sub['code']})', style: GoogleFonts.manrope(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedSubject = val!;
                            final match = presetSubjects.firstWhere((s) => s['name'] == val, orElse: () => {'code': 'CS8000'});
                            subjectCode = match['code']!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Class / Section', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
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
                                    DropdownMenuItem(value: 'IV CSE - B', child: Text('IV CSE - B')),
                                  ],
                                  onChanged: (val) => setModalState(() => selectedClass = val!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Academic Year', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedYear,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: '2025–26', child: Text('2025–26')),
                                    DropdownMenuItem(value: '2026–27', child: Text('2026–27')),
                                    DropdownMenuItem(value: '2024–25', child: Text('2024–25')),
                                  ],
                                  onChanged: (val) => setModalState(() => selectedYear = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Branch 2: Class Advisor Form ──
                    if (selectedBranch == 'Class Advisor') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Class Advisors can endorse OD/leaves, monitor at-risk attendance, and manage class students.',
                                style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF92400E), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Assigned Class Section', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
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
                                    DropdownMenuItem(value: 'IV CSE - B', child: Text('IV CSE - B')),
                                  ],
                                  onChanged: (val) => setModalState(() => selectedClass = val!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Academic Year', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedYear,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: '2025–26', child: Text('2025–26')),
                                    DropdownMenuItem(value: '2026–27', child: Text('2026–27')),
                                    DropdownMenuItem(value: '2024–25', child: Text('2024–25')),
                                  ],
                                  onChanged: (val) => setModalState(() => selectedYear = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Branch 3: Other Department Responsibility Form ──
                    if (selectedBranch == 'Other Dept') ...[
                      Text(
                        'Select Department Responsibility',
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDeptResp,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: presetDeptResponsibilities.map((resp) {
                          return DropdownMenuItem(
                            value: resp,
                            child: Text(resp, style: GoogleFonts.manrope(fontSize: 12.5)),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedDeptResp = val!),
                      ),
                      if (selectedDeptResp == 'Other Custom Responsibility') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: customRespController,
                          decoration: InputDecoration(
                            labelText: 'Custom Responsibility Title',
                            hintText: 'e.g. Industry Collaboration Lead',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Academic Year / Tenure', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedYear,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: '2025–26', child: Text('2025–26')),
                              DropdownMenuItem(value: '2026–27', child: Text('2026–27')),
                              DropdownMenuItem(value: '2024–25', child: Text('2024–25')),
                            ],
                            onChanged: (val) => setModalState(() => selectedYear = val!),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Actions (Cancel / Confirm Assignment)
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

                              StaffAssignmentModel assignment;
                              String successMessage = '';

                              if (selectedBranch == 'Subject Faculty') {
                                assignment = StaffAssignmentModel(
                                  id: 'ASGN-SUB-${DateTime.now().millisecondsSinceEpoch}',
                                  staffId: staffId,
                                  staffName: staffItem['name'],
                                  departmentId: currentDeptId,
                                  assignmentType: StaffAssignmentType.subjectFaculty,
                                  subjectId: 'SUB-$subjectCode',
                                  subjectName: selectedSubject,
                                  subjectCode: subjectCode,
                                  classId: 'CLASS-$selectedClass',
                                  className: selectedClass,
                                  section: selectedClass,
                                  academicYear: selectedYear,
                                  assignedBy: '$hodName (HOD)',
                                  status: 'active',
                                );
                                successMessage = 'Assigned ${staffItem['name']} to $selectedSubject ($selectedClass)!';

                                setState(() {
                                  final currentSubs = List<String>.from(staffItem['subjects'] as List? ?? []);
                                  if (!currentSubs.contains(selectedSubject)) {
                                    currentSubs.add(selectedSubject);
                                    staffItem['subjects'] = currentSubs;
                                  }
                                });
                              } else if (selectedBranch == 'Class Advisor') {
                                assignment = StaffAssignmentModel(
                                  id: 'ASGN-ADV-${DateTime.now().millisecondsSinceEpoch}',
                                  staffId: staffId,
                                  staffName: staffItem['name'],
                                  departmentId: currentDeptId,
                                  assignmentType: StaffAssignmentType.classAdvisor,
                                  classId: 'CLASS-$selectedClass',
                                  className: selectedClass,
                                  section: selectedClass,
                                  academicYear: selectedYear,
                                  assignedBy: '$hodName (HOD)',
                                  status: 'active',
                                );
                                successMessage = 'Assigned ${staffItem['name']} as Class Advisor for $selectedClass!';

                                setState(() {
                                  staffItem['isClassAdvisor'] = true;
                                  staffItem['advisorSection'] = selectedClass;
                                  staffItem['advisorAcademicYear'] = selectedYear;
                                });
                              } else {
                                final respTitle = selectedDeptResp == 'Other Custom Responsibility' && customRespController.text.trim().isNotEmpty
                                    ? customRespController.text.trim()
                                    : selectedDeptResp;

                                assignment = StaffAssignmentModel(
                                  id: 'ASGN-DEPT-${DateTime.now().millisecondsSinceEpoch}',
                                  staffId: staffId,
                                  staffName: staffItem['name'],
                                  departmentId: currentDeptId,
                                  assignmentType: StaffAssignmentType.departmentResponsibility,
                                  responsibilityTitle: respTitle,
                                  academicYear: selectedYear,
                                  assignedBy: '$hodName (HOD)',
                                  status: 'active',
                                );
                                successMessage = 'Assigned $respTitle to ${staffItem['name']}!';

                                setState(() {
                                  final currentResp = List<String>.from(staffItem['otherResponsibilities'] as List? ?? []);
                                  if (!currentResp.contains(respTitle)) {
                                    currentResp.add(respTitle);
                                    staffItem['otherResponsibilities'] = currentResp;
                                  }
                                });
                              }

                              // Persist assignment to repository
                              await ref.read(staffRepositoryProvider).assignResponsibility(assignment);

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(successMessage),
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
                              'Confirm Assignment',
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

  Widget _buildWorkTypeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.hodRole.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.hodRole : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.hodRole : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.hodRole : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
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
