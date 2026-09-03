import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/staff_dashboard_provider.dart';
import 'package:unisphere/screens/staff/modules/advisor/advisor_student_detail.dart';

class AdvisorStudentDirectoryScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  final VoidCallback? onBack;

  const AdvisorStudentDirectoryScreen({
    super.key,
    this.initialFilter,
    this.onBack,
  });

  @override
  ConsumerState<AdvisorStudentDirectoryScreen> createState() =>
      _AdvisorStudentDirectoryScreenState();
}

class _AdvisorStudentDirectoryScreenState
    extends ConsumerState<AdvisorStudentDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'all';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final advisor = ref.watch(activeClassAdvisorAssignmentProvider);
    final section = advisor?.section ?? 'III CSE - A';
    final studentsAsync = ref.watch(advisorClassStudentsStreamProvider);
    final allStudents = studentsAsync.valueOrNull ?? [];

    final query = _searchController.text.trim().toLowerCase();

    final filteredStudents = allStudents.where((s) {
      final matchesSearch = query.isEmpty ||
          s.fullName.toLowerCase().contains(query) ||
          s.registerNumber.toLowerCase().contains(query) ||
          s.rollNumber.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      final att = double.tryParse(s.attendancePercent ?? '85') ?? 85.0;
      final cgpa = double.tryParse(s.cgpa ?? '8.0') ?? 8.0;

      switch (_selectedFilter) {
        case 'low_attendance':
        case 'attendance':
          return att < 75.0;
        case 'academic_risk':
        case 'at_risk':
        case 'attention':
          return att < 75.0 || cgpa < 6.5 || s.academicStatus.toLowerCase() == 'at risk';
        case 'top':
          return cgpa >= 8.5;
        case 'pending_mentor':
          return att < 80.0 || cgpa < 7.0;
        case 'continuous_absence':
          return att < 70.0;
        case 'all':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MY CLASS DIRECTORY',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '$section • ${allStudents.length} Students',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name, register number...',
                  hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.staffRole, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchController.clear()),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('All Students', 'all'),
                  _buildChip('Low Attendance (<75%)', 'low_attendance'),
                  _buildChip('At Risk', 'at_risk'),
                  _buildChip('Top Performers', 'top'),
                  _buildChip('Pending Mentor', 'pending_mentor'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Roster List
            Text(
              'STUDENT ROSTER (${filteredStudents.length})',
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            if (filteredStudents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      Text(
                        'No students found matching your criteria',
                        style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredStudents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final att = double.tryParse(student.attendancePercent ?? '85') ?? 85.0;
                  final cgpa = double.tryParse(student.cgpa ?? '8.0') ?? 8.0;
                  final isRisk = att < 75.0 || cgpa < 6.5 || student.academicStatus.toLowerCase() == 'at risk';

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => AdvisorStudentDetailModal.show(context, student),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFEEF2FF),
                              backgroundImage: student.studentPhotoPath != null && student.studentPhotoPath!.isNotEmpty
                                  ? NetworkImage(student.studentPhotoPath!)
                                  : null,
                              child: student.studentPhotoPath == null || student.studentPhotoPath!.isEmpty
                                  ? Text(
                                      student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.staffRole,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.fullName,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student.registerNumber} • CGPA: ${cgpa.toStringAsFixed(1)} • Att: ${att.toInt()}%',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRisk ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isRisk ? 'At Risk' : 'Active',
                                style: GoogleFonts.manrope(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isRisk ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String key) {
    final isSelected = _selectedFilter == key;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.staffRole,
        backgroundColor: Colors.white,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppColors.staffRole : AppColors.border,
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedFilter = key;
          });
        },
      ),
    );
  }
}
