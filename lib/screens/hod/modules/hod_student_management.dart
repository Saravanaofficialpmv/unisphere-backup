import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/student_model.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/screens/staff/modules/hod_student_verifications_screen.dart';
import 'package:unisphere/widgets/student/student_full_detail_modal.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class HodStudentManagement extends ConsumerStatefulWidget {
  const HodStudentManagement({super.key});

  @override
  ConsumerState<HodStudentManagement> createState() => _HodStudentManagementState();
}

class _HodStudentManagementState extends ConsumerState<HodStudentManagement> {
  String _searchQuery = '';
  String _selectedYear = 'All';
  String _selectedSection = 'All';
  String _selectedRiskFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(hodStudentsStreamProvider);
    final verificationsAsync = ref.watch(hodVerificationsStreamProvider);
    final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final deptName = (dept?.name != null && dept!.name.isNotEmpty && dept.name != 'Computer Science & Engineering')
        ? dept.name
        : (currentUser?.departmentName ??
            currentUser?.department ??
            currentUser?.metadata?['departmentName']?.toString() ??
            currentUser?.metadata?['department']?.toString() ??
            dept?.name ??
            'Department');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEPARTMENT ROSTER & DIRECTORY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student Directory',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        deptName,
                        style: const TextStyle(fontSize: 12, color: AppColors.hodRole, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HodStudentVerificationsScreen()),
                    );
                  },
                  icon: const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.hodRole),
                  label: const Text('Verifications Hub', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.hodRole)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pending verifications banner
            _buildPendingVerificationsSection(verificationsAsync),
            const SizedBox(height: 20),

            _buildSearchBar(),
            const SizedBox(height: 14),
            _buildFilters(),
            const SizedBox(height: 20),

            studentsAsync.when(
              data: (studentList) {
                final filtered = studentList.where((s) {
                  final cleanQuery = _searchQuery.toLowerCase().trim();
                  final matchesSearch = cleanQuery.isEmpty ||
                      s.fullName.toLowerCase().contains(cleanQuery) ||
                      s.registerNumber.toLowerCase().contains(cleanQuery) ||
                      s.rollNumber.toLowerCase().contains(cleanQuery) ||
                      s.section.toLowerCase().contains(cleanQuery);

                  final matchesYear = _selectedYear == 'All' ||
                      s.batch.contains(_selectedYear) ||
                      s.semester.contains(_selectedYear);

                  final matchesSection = _selectedSection == 'All' ||
                      s.section.toLowerCase() == _selectedSection.toLowerCase();

                  final att = double.tryParse(s.attendancePercent ?? '') ?? 100.0;
                  final cgpa = double.tryParse(s.cgpa ?? '') ?? 10.0;
                  final isAtRisk = att < 75.0 || cgpa < 6.5 || s.academicStatus.toLowerCase() == 'at risk';

                  final matchesRisk = switch (_selectedRiskFilter) {
                    'At Risk Only' => isAtRisk,
                    'Attendance Shortage (<75%)' => att < 75.0,
                    'Low CGPA (<6.5)' => cgpa < 6.5,
                    _ => true,
                  };

                  return matchesSearch && matchesYear && matchesSection && matchesRisk;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DEPARTMENT STUDENTS (${filtered.length})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
                        ),
                        if (_selectedRiskFilter != 'All' || _searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _selectedYear = 'All';
                                _selectedSection = 'All';
                                _selectedRiskFilter = 'All';
                              });
                            },
                            child: const Text('Clear Filters', style: TextStyle(fontSize: 12, color: AppColors.hodRole, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: const [
                            Icon(Icons.person_search_rounded, size: 48, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text('No matching department students found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Try adjusting your search criteria or filters.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildStudentCard(context, filtered[index]);
                        },
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CustomLoader(label: 'Loading Department Students...'),
                ),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: Text('Notice loading department students: $err', style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search by Register Number (e.g. 23CS1045) or Name...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.hodRole),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Year', _selectedYear, ['All', '1st Year', '2nd Year', '3rd Year', '4th Year'], (v) {
            if (v != null) setState(() => _selectedYear = v);
          }),
          const SizedBox(width: 10),
          _buildFilterChip('Section', _selectedSection, ['All', 'III CSE - A', 'II CSE - B', 'IV CSE - A', 'Sec A', 'Sec B', 'CS-A', 'CS-B'], (v) {
            if (v != null) setState(() => _selectedSection = v);
          }),
          const SizedBox(width: 10),
          _buildFilterChip('Academic Risk', _selectedRiskFilter, [
            'All',
            'At Risk Only',
            'Attendance Shortage (<75%)',
            'Low CGPA (<6.5)',
          ], (v) {
            if (v != null) setState(() => _selectedRiskFilter = v);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value != 'All' ? AppColors.hodRole : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: value != 'All' ? AppColors.hodRole : AppColors.textPrimary,
          ),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text('$label: $e'))).toList(),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel student) {
    final double attVal = double.tryParse(student.attendancePercent ?? '') ?? 0.0;
    final isLowAtt = attVal < 75.0 && attVal > 0;
    final double cgpaVal = double.tryParse(student.cgpa ?? '') ?? 0.0;
    final isLowCgpa = cgpaVal < 6.5 && cgpaVal > 0;
    final isAtRisk = isLowAtt || isLowCgpa || student.academicStatus.toLowerCase() == 'at risk';

    final hasPhoto = student.studentPhotoPath != null && student.studentPhotoPath!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isAtRisk ? Border.all(color: AppColors.error.withValues(alpha: 0.35)) : null,
        boxShadow: [
          BoxShadow(
            color: isAtRisk ? AppColors.error.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.hodRole.withValues(alpha: 0.12),
                backgroundImage: hasPhoto ? NetworkImage(student.studentPhotoPath!) : null,
                child: !hasPhoto
                    ? Text(
                        student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.hodRole),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    // Prominent Register Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.hodRole.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.hodRole.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Reg No: ${student.registerNumber}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.hodRole),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.section} • ${student.semester}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowAtt
                          ? AppColors.error.withValues(alpha: 0.12)
                          : const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Att: ${student.attendancePercent ?? "N/A"}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLowAtt ? AppColors.error : const Color(0xFF059669),
                      ),
                    ),
                  ),
                  if (isAtRisk) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('At Risk', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error)),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('CGPA', student.cgpa ?? 'N/A', isLowCgpa ? AppColors.error : const Color(0xFF2563EB)),
              _buildMiniStat('Batch', student.batch.isNotEmpty ? student.batch : '2023–27', AppColors.textPrimary),
              _buildMiniStat('Status', student.academicStatus, isAtRisk ? AppColors.error : AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showStudentFullDetailModal(context, student.toMap());
              },
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: const Text('View Consolidated Student Record'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.hodRole,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppColors.hodRole),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPendingVerificationsSection(AsyncValue<List<Map<String, dynamic>>> verificationsAsync) {
    final pendingItems = (verificationsAsync.valueOrNull ?? [])
        .where((v) => v['status'] == 'pending_hod')
        .toList();

    if (pendingItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pendingItems.length} Student Profiles Awaiting HOD Verification',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                  const Text(
                    'Review submitted details, address, and parent records',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HodStudentVerificationsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Review Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
