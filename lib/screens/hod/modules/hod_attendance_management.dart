import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/widgets/common/app_progress_indicators.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/attendance_system_provider.dart';
import 'package:unisphere/models/attendance_model.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';

class HodAttendanceManagement extends ConsumerStatefulWidget {
  const HodAttendanceManagement({super.key});

  @override
  ConsumerState<HodAttendanceManagement> createState() => _HodAttendanceManagementState();
}

class _HodAttendanceManagementState extends ConsumerState<HodAttendanceManagement> {
  String _selectedSection = 'CS-A';

  @override
  Widget build(BuildContext context) {
    final systemState = ref.watch(attendanceSystemProvider);
    final activeSemData = systemState.activeSemester;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEPARTMENT ANALYTICS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            const Text(
              'Attendance Management',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            _buildHodWorkingDaysCard(context, systemState),
            const SizedBox(height: 24),
            _buildStatCards(activeSemData),
            const SizedBox(height: 24),
            _buildSectionFilter(),
            const SizedBox(height: 20),
            _buildVisualCharts(),
            const SizedBox(height: 24),
            _buildLowAttendanceList(),
            const SizedBox(height: 24),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHodWorkingDaysCard(BuildContext context, AttendanceSystemState systemState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'SEMESTER WORKING DAYS (HOD CONTROL)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'HOD Authority',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Configure overall semester working days for your department. Student attendance percentages recalculate live based on these numbers.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: systemState.hodSemesterConfigs.entries.map((entry) {
                final semNum = entry.key;
                final config = entry.value;
                final isCurrent = semNum == 4;

                return GestureDetector(
                  onTap: () => _showEditWorkingDaysModal(context, semNum, config.totalWorkingDays),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFF60A5FA) : const Color(0xFF475569),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Sem $semNum',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34D399),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(color: Color(0xFF064E3B), fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              '${config.totalWorkingDays} Days',
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF60A5FA)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditWorkingDaysModal(BuildContext context, int semNum, int currentDays) {
    int days = currentDays;
    final controller = TextEditingController(text: days.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('Set Sem $semNum Working Days'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Decide total semester working days for Semester $semNum. Student attendance percentages will immediately update.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      if (days > 1) {
                        setModalState(() {
                          days--;
                          controller.text = days.toString();
                        });
                      }
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setModalState(() => days = parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () {
                      setModalState(() {
                        days++;
                        controller.text = days.toString();
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Quick Presets:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [80, 85, 90, 95, 100].map((preset) {
                  final isSelected = days == preset;
                  return ChoiceChip(
                    label: Text('$preset'),
                    selected: isSelected,
                    onSelected: (val) {
                      setModalState(() {
                        days = preset;
                        controller.text = preset.toString();
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(attendanceSystemProvider.notifier).updateSemesterWorkingDaysByHod(semNum, days);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Semester $semNum total working days updated to $days Days by HOD.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(SemesterAttendance activeSemData) {
    final activePctStr = '${activeSemData.attendancePercentage.toStringAsFixed(1)}%';
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Active Sem Attendance', activePctStr, Icons.school_outlined, AppColors.primary),
        _buildStatCard('Faculty Attendance', '95.2%', Icons.badge_outlined, const Color(0xFF7C3AED)),
        _buildStatCard('HOD Working Days', '${activeSemData.totalWorkingDays} Days', Icons.event_available_outlined, const Color(0xFF059669)),
        _buildStatCard('Low Attendance (<75%)', '3 Students', Icons.warning_amber_rounded, AppColors.error),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color color) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['CS-A', 'CS-B', 'CS-C', 'CS-D'].map((sec) {
          final isSel = _selectedSection == sec;
          return GestureDetector(
            onTap: () => setState(() => _selectedSection = sec),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                'Section $sec',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSel ? Colors.white : AppColors.textPrimary),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVisualCharts() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            children: [
              Text('Section $_selectedSection Attendance Breakdown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppCircularGauge(
                  radius: 45.0,
                  lineWidth: 9.0,
                  percent: 0.942,
                  center: const Text("94.2%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  progressColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Present', '94.2%', AppColors.primary),
                    const SizedBox(height: 8),
                    _buildLegendItem('Absent', '3.8%', AppColors.error),
                    const SizedBox(height: 8),
                    _buildLegendItem('On Duty (OD)', '2.0%', AppColors.warning),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Weekly Attendance Trend (Mon - Fri)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('Mon', 0.96),
              _buildBar('Tue', 0.94),
              _buildBar('Wed', 0.98),
              _buildBar('Thu', 0.91),
              _buildBar('Fri', 0.92),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String val, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBar(String day, double heightFactor) {
    return Column(
      children: [
        Container(
          height: 80 * heightFactor,
          width: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLowAttendanceList() {
    final allStudents = ref.watch(allStudentsStreamProvider).value ?? [];
    final lowStudents = allStudents.where((s) {
      final att = (s.metadata?['attendance'] as num?)?.toDouble() ?? 100.0;
      return att < 75.0;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
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
              Text('Low Attendance Alerts (<75%)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error)),
              Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          if (lowStudents.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                'No students currently flagged with attendance below 75%.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            Column(
              children: lowStudents.map((s) {
                final att = (s.metadata?['attendance'] as num?)?.toDouble() ?? 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.fullName.isNotEmpty ? s.fullName : s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(s.registerNumber ?? s.uid, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      Text('${att.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: () => _notifyMsg(context, 'Attendance Excel report exported!'),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Export Attendance'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
        OutlinedButton.icon(
          onPressed: () => _notifyMsg(context, 'Push notifications sent to low attendance students.'),
          icon: const Icon(Icons.notifications_active_outlined, size: 16),
          label: const Text('Notify Students'),
        ),
        OutlinedButton.icon(
          onPressed: () => _notifyMsg(context, 'SMS warning alerts sent to parents of default students.'),
          icon: const Icon(Icons.sms_outlined, size: 16),
          label: const Text('Notify Parents'),
        ),
        OutlinedButton.icon(
          onPressed: () => _notifyMsg(context, 'Formal warning letters generated.'),
          icon: const Icon(Icons.warning_amber_rounded, size: 16),
          label: const Text('Generate Letters'),
        ),
      ],
    );
  }

  void _notifyMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }
}
