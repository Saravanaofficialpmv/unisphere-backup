import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/attendance_system_provider.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class StaffAttendanceMarkingModule extends ConsumerStatefulWidget {
  const StaffAttendanceMarkingModule({super.key});

  @override
  ConsumerState<StaffAttendanceMarkingModule> createState() => _StaffAttendanceMarkingModuleState();
}

class _StaffAttendanceMarkingModuleState extends ConsumerState<StaffAttendanceMarkingModule> {
  String _selectedSection = 'CS-A';
  String _selectedSubject = 'CS301 - Computer Networks';
  String _selectedSlot = '09:00 - 10:00 AM';

  final List<Map<String, dynamic>> _studentsList = [
    {'id': '917722104001', 'name': 'Aarav Sharma', 'isPresent': true},
    {'id': '917722104002', 'name': 'Aditi Rao', 'isPresent': true},
    {'id': '917722104003', 'name': 'Bhavya Nair', 'isPresent': true},
    {'id': '917722104018', 'name': 'Deepak Kumar', 'isPresent': false},
    {'id': '917722104022', 'name': 'Karthik Raja', 'isPresent': true},
    {'id': '917722104030', 'name': 'Meera Patel', 'isPresent': true},
    {'id': '917722104045', 'name': 'Rohan Gupta', 'isPresent': true},
    {'id': '917722104052', 'name': 'Sanjay V.', 'isPresent': false},
    {'id': '917722104060', 'name': 'Tanvi Iyer', 'isPresent': true},
    {'id': '917722104068', 'name': 'Vikram Singh', 'isPresent': true},
  ];

  void _markAll(bool present) {
    setState(() {
      for (final s in _studentsList) {
        s['isPresent'] = present;
      }
    });
  }

  void _submitAttendance() {
    final code = _selectedSubject.split(' - ')[0];
    final name = _selectedSubject.split(' - ')[1];

    ref.read(attendanceSystemProvider.notifier).submitStaffSessionAttendance(
          subjectCode: code,
          subjectName: name,
          facultyName: 'Dr. Robert Vance',
          timeSlot: _selectedSlot,
          studentResults: _studentsList,
        );

    final presentCount = _studentsList.where((s) => s['isPresent'] == true).length;
    final total = _studentsList.length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance submitted! ($presentCount / $total Present) for $_selectedSection'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _studentsList.where((s) => s['isPresent'] == true).length;
    final absentCount = _studentsList.length - presentCount;

    return AppLiquidPullToRefresh(
      gifAsset: 'assets/tibsy-dp.gif',
      onRefresh: () async {
        ref.invalidate(attendanceSystemProvider);
        await Future.delayed(const Duration(milliseconds: 1000));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FACULTY CONTROL CENTER',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mark Class Attendance',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),

          // Config Selector Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Section', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSection,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.background,
                            ),
                            items: ['CS-A', 'CS-B', 'CS-C', 'CS-D']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSection = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time Slot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSlot,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.background,
                            ),
                            items: ['09:00 - 10:00 AM', '10:15 - 11:15 AM', '11:30 AM - 12:30 PM', '01:30 - 02:30 PM']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSlot = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Subject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubject,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  items: [
                    'CS301 - Computer Networks',
                    'CS302 - Database Systems',
                    'CS303 - Web Technology',
                    'CS304 - Software Engineering',
                    'CS305 - AI & Machine Learning',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSubject = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary & Quick Preset Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                    child: Text('Present: $presentCount', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                    child: Text('Absent: $absentCount', style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _markAll(true),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('All Present', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  TextButton.icon(
                    onPressed: () => _markAll(false),
                    icon: const Icon(Icons.highlight_off_rounded, size: 16, color: AppColors.error),
                    label: const Text('All Absent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Students Roster List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _studentsList.length,
            itemBuilder: (context, index) {
              final student = _studentsList[index];
              final bool isPresent = student['isPresent'];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isPresent ? const Color(0xFFE2E8F0) : const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isPresent ? const Color(0xFFEFF6FF) : const Color(0xFFFEE2E2),
                          child: Text(
                            student['name'][0],
                            style: TextStyle(fontWeight: FontWeight.bold, color: isPresent ? const Color(0xFF2563EB) : const Color(0xFFDC2626)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Reg: ${student['id']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isPresent,
                      activeThumbColor: const Color(0xFF059669),
                      onChanged: (val) {
                        setState(() {
                          student['isPresent'] = val;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitAttendance,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Submit Session Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
    );
  }
}
