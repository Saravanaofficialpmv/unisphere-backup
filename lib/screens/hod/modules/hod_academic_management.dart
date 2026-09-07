import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/staff_model.dart';
import 'package:unisphere/services/staff_service.dart';
import 'package:unisphere/screens/hod/modules/hod_syllabus_management_screen.dart';
import 'package:unisphere/screens/hod/modules/hod_academic_schedule_screen.dart';
import 'package:unisphere/screens/hod/modules/hod_staff_management.dart';

class HodAcademicManagement extends ConsumerStatefulWidget {
  const HodAcademicManagement({super.key});

  @override
  ConsumerState<HodAcademicManagement> createState() => _HodAcademicManagementState();
}

class _HodAcademicManagementState extends ConsumerState<HodAcademicManagement> {
  String _selectedTab = 'Allocations';

  // Dynamic state for Course & Faculty Allocation
  final List<Map<String, dynamic>> _courseAllocations = [
    {
      'code': 'CS301',
      'title': 'Distributed Systems & Cloud',
      'semester': 'Semester 6',
      'section': 'CS-A',
      'credits': 4,
      'faculty': 'Dr. S. Meenakshi',
      'facultyUid': 'STF-001',
      'hoursPerWeek': 4,
      'type': 'Theory',
    },
    {
      'code': 'CS302',
      'title': 'Applied Machine Learning',
      'semester': 'Semester 6',
      'section': 'CS-A & B',
      'credits': 4,
      'faculty': 'Dr. Anita Roy',
      'facultyUid': 'STF-002',
      'hoursPerWeek': 4,
      'type': 'Theory',
    },
    {
      'code': 'CS303',
      'title': 'Database Management & Warehousing',
      'semester': 'Semester 4',
      'section': 'CS-B',
      'credits': 3,
      'faculty': 'Prof. Vikram Sharma',
      'facultyUid': 'STF-003',
      'hoursPerWeek': 3,
      'type': 'Theory',
    },
    {
      'code': 'CS304',
      'title': 'Cloud Computing Laboratory',
      'semester': 'Semester 6',
      'section': 'CS-A',
      'credits': 2,
      'faculty': 'Prof. Rajesh Kumar',
      'facultyUid': 'STF-004',
      'hoursPerWeek': 3,
      'type': 'Practical',
    },
    {
      'code': 'CS305',
      'title': 'Design & Analysis of Algorithms',
      'semester': 'Semester 4',
      'section': 'CS-A',
      'credits': 4,
      'faculty': 'Dr. K. Tharani Kumar',
      'facultyUid': 'DEMO-STF',
      'hoursPerWeek': 4,
      'type': 'Theory',
    },
  ];

  // Class Advisors per section
  final List<Map<String, String>> _sectionAdvisors = [
    {'section': '3rd Year CS-A', 'advisor': 'Dr. S. Meenakshi', 'students': '64 Students', 'room': 'LH-201'},
    {'section': '3rd Year CS-B', 'advisor': 'Prof. Rajesh Kumar', 'students': '62 Students', 'room': 'LH-202'},
    {'section': '2nd Year CS-A', 'advisor': 'Dr. Anita Roy', 'students': '65 Students', 'room': 'LH-105'},
    {'section': '2nd Year CS-B', 'advisor': 'Prof. Vikram Sharma', 'students': '60 Students', 'room': 'LH-106'},
    {'section': '1st Year CS-A', 'advisor': 'Dr. K. Tharani Kumar', 'students': '66 Students', 'room': 'LH-003'},
  ];

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffMembersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEPARTMENT CURRICULUM & ROSTER',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Academic Management',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAllocateSubjectDialog(context, staffAsync.value ?? []),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Allocate Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Navigation Tabs
            _buildTabSelector(),
            const SizedBox(height: 20),

            if (_selectedTab == 'Allocations') ...[
              _buildCourseAllocationSection(staffAsync.value ?? []),
            ] else if (_selectedTab == 'Workload') ...[
              _buildFacultyWorkloadSection(staffAsync.value ?? []),
            ] else if (_selectedTab == 'Class Advisors') ...[
              _buildClassAdvisorsSection(),
            ] else ...[
              _buildAcademicShortcutsGrid(context),
            ],

            const SizedBox(height: 28),
            _buildAcademicActionCards(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['Allocations', 'Workload', 'Class Advisors', 'Curriculum Hub'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSel = _selectedTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = tab),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                boxShadow: isSel
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCourseAllocationSection(List<StaffModel> staffList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE COURSE ALLOCATIONS (${_courseAllocations.length})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
            ),
            Text(
              'Current Semester: Even 2026',
              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _courseAllocations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _courseAllocations[index];
            final isTheory = item['type'] == 'Theory';

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isTheory ? const Color(0xFFEEF2FF) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isTheory ? Icons.book_outlined : Icons.computer_outlined,
                      color: isTheory ? const Color(0xFF3730A3) : const Color(0xFFB45309),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item['code'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${item['section']} • ${item['semester']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(item['faculty'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Text('• ${item['credits']} Credits (${item['hoursPerWeek']} hrs/wk)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    tooltip: 'Reassign Faculty',
                    onPressed: () => _showReassignFacultyModal(context, item, staffList),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFacultyWorkloadSection(List<StaffModel> staffList) {
    final workloads = [
      {'name': 'Dr. S. Meenakshi', 'designation': 'Associate Professor', 'hours': 18, 'subjects': 'CS301, CS102 Lab', 'status': 'Optimal (18/20 hrs)'},
      {'name': 'Dr. Anita Roy', 'designation': 'Assistant Professor (Sr.G)', 'hours': 16, 'subjects': 'CS302, Elective-I', 'status': 'Optimal (16/20 hrs)'},
      {'name': 'Prof. Vikram Sharma', 'designation': 'Assistant Professor', 'hours': 20, 'subjects': 'CS303, CS304 Lab', 'status': 'Full Load (20/20 hrs)'},
      {'name': 'Prof. Rajesh Kumar', 'designation': 'Assistant Professor', 'hours': 17, 'subjects': 'CS304 Lab, Soft Skills', 'status': 'Optimal (17/20 hrs)'},
      {'name': 'Dr. K. Tharani Kumar', 'designation': 'Assistant Professor', 'hours': 16, 'subjects': 'CS305, Algo Lab', 'status': 'Optimal (16/20 hrs)'},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('FACULTY TEACHING WORKLOAD TRACKER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              Icon(Icons.assessment_outlined, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          const Text('AICTE & UGC Norm: 16 - 20 Teaching Hours per week per Faculty member.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ...workloads.map((w) {
            final double fraction = ((w['hours'] as int) / 20.0).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(w['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${w['hours']} hrs/week', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(w['subjects'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(w['status'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        fraction >= 1.0 ? AppColors.warning : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildClassAdvisorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CLASS ADVISOR ASSIGNMENTS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HodStaffManagement()),
                );
              },
              icon: const Icon(Icons.manage_accounts_rounded, size: 16),
              label: const Text('Manage in Staff Panel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sectionAdvisors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _sectionAdvisors[index];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.badge_rounded, color: Color(0xFF16A34A), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['section']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('Advisor: ${item['advisor']}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${item['students']} • Classroom: ${item['room']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HodStaffManagement()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAcademicShortcutsGrid(BuildContext context) {
    final items = [
      {'title': 'Syllabus & Units', 'sub': 'Curriculum modules & hours', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF2563EB)},
      {'title': 'Academic Calendar', 'sub': 'Working days & exams', 'icon': Icons.calendar_month_outlined, 'color': const Color(0xFF7C3AED)},
      {'title': 'Elective Allotment', 'sub': 'Professional electives', 'icon': Icons.rule_outlined, 'color': const Color(0xFF059669)},
      {'title': 'Lab Infrastructure', 'sub': 'Systems & software labs', 'icon': Icons.computer_outlined, 'color': const Color(0xFFD97706)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final Color col = item['color'] as Color;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (index == 0) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HodSyllabusManagementScreen()));
            } else if (index == 1) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HodAcademicScheduleScreen()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${item['title']} configuration panel...'), backgroundColor: AppColors.primary),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(item['icon'] as IconData, color: col, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(item['sub'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicActionCards(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QUICK CURRICULAR ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HodSyllabusManagementScreen()));
                },
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('Manage Syllabus'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HodAcademicScheduleScreen()));
                },
                icon: const Icon(Icons.event_note_rounded, size: 16),
                label: const Text('Academic Schedule'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HodStaffManagement()));
                },
                icon: const Icon(Icons.badge_outlined, size: 16),
                label: const Text('Staff & Advisors'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllocateSubjectDialog(BuildContext context, List<StaffModel> staffList) {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    String selectedSem = 'Semester 6';
    String selectedSec = 'CS-A';
    String selectedType = 'Theory';
    String? selectedFaculty = staffList.isNotEmpty ? staffList.first.fullName : 'Dr. S. Meenakshi';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Allocate New Subject', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Subject Code (e.g. CS306)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Subject Title (e.g. Compiler Design)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSem,
                    decoration: const InputDecoration(labelText: 'Target Semester', border: OutlineInputBorder()),
                    items: ['Semester 2', 'Semester 4', 'Semester 6', 'Semester 8']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedSem = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSec,
                    decoration: const InputDecoration(labelText: 'Target Section', border: OutlineInputBorder()),
                    items: ['CS-A', 'CS-B', 'CS-C', 'CS-A & B']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedSec = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFaculty,
                    decoration: const InputDecoration(labelText: 'Assigned Faculty', border: OutlineInputBorder()),
                    items: (staffList.isNotEmpty
                            ? staffList.map((s) => s.fullName).toList()
                            : ['Dr. S. Meenakshi', 'Dr. Anita Roy', 'Prof. Vikram Sharma', 'Prof. Rajesh Kumar', 'Dr. K. Tharani Kumar'])
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedFaculty = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (codeCtrl.text.trim().isEmpty || titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter Subject Code and Title.'), backgroundColor: AppColors.error),
                    );
                    return;
                  }
                  setState(() {
                    _courseAllocations.insert(0, {
                      'code': codeCtrl.text.trim().toUpperCase(),
                      'title': titleCtrl.text.trim(),
                      'semester': selectedSem,
                      'section': selectedSec,
                      'credits': selectedType == 'Theory' ? 4 : 2,
                      'faculty': selectedFaculty ?? 'Assigned Faculty',
                      'facultyUid': 'STF-${DateTime.now().millisecondsSinceEpoch}',
                      'hoursPerWeek': selectedType == 'Theory' ? 4 : 3,
                      'type': selectedType,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🎉 ${codeCtrl.text.trim().toUpperCase()} allocated to $selectedFaculty!'), backgroundColor: const Color(0xFF10B981)),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Allocate Subject'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReassignFacultyModal(BuildContext context, Map<String, dynamic> item, List<StaffModel> staffList) {
    String? selectedFaculty = item['faculty'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Reassign Faculty — ${item['code']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedFaculty,
                  decoration: const InputDecoration(labelText: 'Select Faculty Member', border: OutlineInputBorder()),
                  items: (staffList.isNotEmpty
                          ? staffList.map((s) => s.fullName).toList()
                          : ['Dr. S. Meenakshi', 'Dr. Anita Roy', 'Prof. Vikram Sharma', 'Prof. Rajesh Kumar', 'Dr. K. Tharani Kumar'])
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedFaculty = v),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    item['faculty'] = selectedFaculty;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated faculty for ${item['code']} to $selectedFaculty'), backgroundColor: const Color(0xFF10B981)),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Save Assignment'),
              ),
            ],
          );
        },
      ),
    );
  }
}
