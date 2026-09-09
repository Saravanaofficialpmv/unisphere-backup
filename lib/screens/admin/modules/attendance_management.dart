import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/attendance_system_provider.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';

class AttendanceManagementModule extends ConsumerStatefulWidget {
  const AttendanceManagementModule({super.key});

  @override
  ConsumerState<AttendanceManagementModule> createState() => _AttendanceManagementModuleState();
}

class _AttendanceManagementModuleState extends ConsumerState<AttendanceManagementModule> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;
    final systemState = ref.watch(attendanceSystemProvider);
    final activeSemData = systemState.activeSemester;
    final activePct = activeSemData.attendancePercentage.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildTopStatsGrid(isDesktop, activePct),
        const SizedBox(height: 24),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildAttendanceTrends()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildAtRiskStudents()),
            ],
          )
        else
          Column(
            children: [
              _buildAttendanceTrends(),
              const SizedBox(height: 24),
              _buildAtRiskStudents(),
            ],
          ),
        const SizedBox(height: 24),
        _buildClassPerformanceTable(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INSTITUTIONAL OVERVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1)),
        SizedBox(height: 8),
        Text('Attendance Monitoring Hub', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildTopStatsGrid(bool isDesktop, String activePct) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Daily Presence Rate', '$activePct%', '+1.2%', Colors.blue),
        _buildStatCard('Staff Attendance', '98.5%', '+0.4%', Colors.green),
        _buildStatCard('Critical Absences', '3', 'Action Required', Colors.red, isAlert: true),
        _buildStatCard('Recent Notifications', '156', 'Sent in 24h', Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String sub, Color color, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              if (!isAlert) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(sub, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold))),
            ],
          ),
          if (isAlert) Row(children: [Icon(Icons.report_problem_outlined, size: 10, color: color), const SizedBox(width: 4), Text(sub, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold))]),
        ],
      ),
    );
  }

  Widget _buildAttendanceTrends() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Monthly comparison between Students and Staff', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  _legendDot(Colors.blue, 'STUDENTS'),
                  const SizedBox(width: 12),
                  _legendDot(Colors.grey, 'STAFF'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(height: 200, width: double.infinity, child: CustomPaint(painter: AttendanceChartPainter())),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ['JAN', 'MAR', 'MAY', 'JUL', 'SEP', 'NOV'].map((m) => Text(m, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))).toList()),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [CircleAvatar(radius: 3, backgroundColor: color), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))]);
  }

  Widget _buildAtRiskStudents() {
    final allStudents = ref.watch(allStudentsStreamProvider).value ?? [];
    final atRisk = allStudents.where((s) {
      final att = (s.metadata?['attendance'] as num?)?.toDouble() ?? 100.0;
      return att < 75.0;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('At-Risk Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (atRisk.isEmpty ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${atRisk.length} Flagged',
                  style: TextStyle(
                    color: atRisk.isEmpty ? Colors.green : Colors.red,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (atRisk.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No students currently flagged below 75% attendance.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            )
          else ...[
            ...atRisk.map((s) {
              final att = (s.metadata?['attendance'] as num?)?.toDouble() ?? 0.0;
              final dept = s.department?.toUpperCase() ?? 'CSE';
              return _atRiskCard(s.fullName.isNotEmpty ? s.fullName : s.name, '${att.toStringAsFixed(1)}% Attendance', dept);
            }),
            const SizedBox(height: 20),
            Center(child: TextButton(onPressed: () {}, child: const Text('View All Critical Cases', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)))),
          ],
        ],
      ),
    );
  }

  Widget _atRiskCard(String name, String status, String code) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person_outline, color: Colors.blue, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(status, style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.mail_outline, size: 16, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildClassPerformanceTable() {
    final timetables = ref.watch(allTimetablesStreamProvider).value ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class-wise Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Granular data across all departments', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _actionBtn(Icons.tune, 'Filter'),
                  const SizedBox(width: 12),
                  _actionBtn(Icons.download_outlined, 'Export Report'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (timetables.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: const Text('No class-wise attendance records available.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 32,
                headingRowHeight: 40,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 65,
                columns: const [
                  DataColumn(label: Text('CLASS / GROUP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text('DEPARTMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text('LEAD INSTRUCTOR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text('AVG. ATTENDANCE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                  DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                ],
                rows: timetables.map((t) {
                  final className = t['className']?.toString() ?? t['name']?.toString() ?? 'Class';
                  final dept = t['department']?.toString() ?? 'General';
                  final lead = t['faculty']?.toString() ?? t['instructor']?.toString() ?? 'Faculty';
                  final attend = t['avgAttendance']?.toString() ?? '100%';
                  return _tableRow(className, dept, lead, attend, 'ACTIVE', Colors.green);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _tableRow(String name, String dept, String lead, String attend, String status, Color color) {
    final leadInitial = lead.isNotEmpty ? lead[0].toUpperCase() : 'F';
    return DataRow(cells: [
      DataCell(Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      DataCell(Text(dept, style: const TextStyle(fontSize: 12))),
      DataCell(Row(children: [CircleAvatar(radius: 12, backgroundColor: Colors.blue.withValues(alpha: 0.1), child: Text(leadInitial, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue))), const SizedBox(width: 8), Text(lead, style: const TextStyle(fontSize: 11))])),
      DataCell(Text(attend, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)))),
    ]);
  }

  Widget _actionBtn(IconData icon, String label) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary))]));
  }
}

class AttendanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 3;
    final paint2 = Paint()..color = Colors.grey.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 3;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.cubicTo(size.width * 0.2, size.height * 0.4, size.width * 0.4, size.height * 0.9, size.width * 0.6, size.height * 0.5);
    path1.cubicTo(size.width * 0.8, size.height * 0.1, size.width * 0.9, size.height * 0.8, size.width, size.height * 0.4);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.5);

    canvas.drawPath(path2, paint2);
    canvas.drawPath(path1, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
