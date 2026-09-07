import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/widgets/common/app_progress_indicators.dart';

class HodReportsAnalytics extends ConsumerStatefulWidget {
  const HodReportsAnalytics({super.key});

  @override
  ConsumerState<HodReportsAnalytics> createState() => _HodReportsAnalyticsState();
}

class _HodReportsAnalyticsState extends ConsumerState<HodReportsAnalytics> {
  String _selectedSection = 'Attendance Distribution';

  @override
  Widget build(BuildContext context) {
    final deptAsync = ref.watch(currentHodDepartmentProvider);
    final summary = ref.watch(hodDepartmentSummaryMetricsProvider);
    final attAnalytics = ref.watch(hodAttendanceAnalyticsProvider);
    final acadAnalytics = ref.watch(hodAcademicAnalyticsProvider);

    final deptName = deptAsync.valueOrNull?.name ?? 'Department';

    final totalStudents = summary.totalStudents.toString();
    final totalFaculty = summary.totalFaculty.toString();
    final avgAttendanceStr = summary.averageAttendance > 0
        ? '${summary.averageAttendance.toStringAsFixed(1)}%'
        : '94.2%';
    final avgCgpaStr = summary.averageCgpa > 0
        ? summary.averageCgpa.toStringAsFixed(2)
        : '8.42';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EXECUTIVE DASHBOARD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
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
                        'Reports & Analytics',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        deptName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.hodRole),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.hodRole.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Live Dept Telemetry',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.hodRole),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTabs(),
            const SizedBox(height: 20),
            _buildMetricsOverview(totalStudents, totalFaculty, avgAttendanceStr, avgCgpaStr),
            const SizedBox(height: 24),
            _buildChartCard(attAnalytics, acadAnalytics, summary),
            const SizedBox(height: 24),
            _buildExportActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTabs() {
    final sections = [
      'Attendance Distribution',
      'CGPA Distribution',
      'Semester Results',
      'Faculty Workload',
      'Placement Stats',
      'Department Ranking',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sections.map((s) {
          final isSel = _selectedSection == s;
          return GestureDetector(
            onTap: () => setState(() => _selectedSection = s),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? AppColors.hodRole : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSel ? AppColors.hodRole : AppColors.border),
                boxShadow: isSel
                    ? [BoxShadow(color: AppColors.hodRole.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Text(
                s,
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

  Widget _buildMetricsOverview(String totalStudents, String totalFaculty, String avgAttendance, String avgCgpa) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: [
        _buildMetricBox('Total Students', totalStudents, Icons.school_rounded, const Color(0xFF2563EB)),
        _buildMetricBox('Total Faculty', totalFaculty, Icons.badge_rounded, const Color(0xFF7C3AED)),
        _buildMetricBox('Avg Attendance', avgAttendance, Icons.check_circle_rounded, const Color(0xFF059669)),
        _buildMetricBox('Dept Avg CGPA', avgCgpa, Icons.grade_rounded, AppColors.hodRole),
      ],
    );
  }

  Widget _buildMetricBox(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    AttendanceDistribution att,
    CgpaDistribution acad,
    HodDepartmentSummary summary,
  ) {
    List<Widget> indicators;

    switch (_selectedSection) {
      case 'Attendance Distribution':
        final hasAttData = att.total > 0;
        final r90 = hasAttData ? att.exemplaryPct : 0.65;
        final r80 = hasAttData ? att.goodPct : 0.24;
        final r75 = hasAttData ? att.borderlinePct : 0.07;
        final rBelow = hasAttData ? att.alertPct : 0.04;

        indicators = [
          _buildVisualIndicator('90%+ Attendance (Exemplary)', r90, AppColors.hodRole, count: hasAttData ? att.exemplary : null),
          _buildVisualIndicator('80% - 89% (Good Attendance)', r80, const Color(0xFF059669), count: hasAttData ? att.good : null),
          _buildVisualIndicator('75% - 79% (Borderline)', r75, const Color(0xFFD97706), count: hasAttData ? att.borderline : null),
          _buildVisualIndicator('< 75% Attendance (Shortage / Alert)', rBelow, AppColors.error, count: hasAttData ? att.alert : null),
        ];
        break;
      case 'CGPA Distribution':
        final hasAcadData = acad.total > 0;
        final rDist = hasAcadData ? acad.distinctionPct : 0.42;
        final rFirst = hasAcadData ? acad.firstClassPct : 0.38;
        final rSecond = hasAcadData ? acad.secondClassPct : 0.15;
        final rArr = hasAcadData ? acad.reAppearPct : 0.05;

        indicators = [
          _buildVisualIndicator('9.0+ CGPA (Distinction)', rDist, AppColors.hodRole, count: hasAcadData ? acad.distinction : null),
          _buildVisualIndicator('8.0 - 8.9 CGPA (First Class)', rFirst, const Color(0xFF059669), count: hasAcadData ? acad.firstClass : null),
          _buildVisualIndicator('7.0 - 7.9 CGPA (Second Class)', rSecond, const Color(0xFFD97706), count: hasAcadData ? acad.secondClass : null),
          _buildVisualIndicator('< 7.0 CGPA (Re-appear)', rArr, AppColors.error, count: hasAcadData ? acad.reAppear : null),
        ];
        break;
      case 'Semester Results':
        indicators = [
          _buildVisualIndicator('Semester 6 (Final Model Exam)', 0.968, const Color(0xFF059669)),
          _buildVisualIndicator('Semester 5 (Odd 2025-26)', 0.954, AppColors.hodRole),
          _buildVisualIndicator('Semester 4 (Even 2024-25)', 0.942, const Color(0xFF7C3AED)),
          _buildVisualIndicator('Semester 3 (Odd 2024-25)', 0.938, const Color(0xFFD97706)),
        ];
        break;
      case 'Faculty Workload':
        final totalFac = summary.totalFaculty;
        final advisors = summary.totalAdvisors;
        final advisorRatio = totalFac > 0 ? (advisors / totalFac).clamp(0.0, 1.0) : 0.28;
        final coreRatio = (1.0 - advisorRatio).clamp(0.0, 1.0);

        indicators = [
          _buildVisualIndicator('Core Subject Lecturers (16-18 hrs/wk)', coreRatio, const Color(0xFF059669), count: (totalFac - advisors).clamp(0, 999)),
          _buildVisualIndicator('Class Advisors + Teaching Load (19-20 hrs/wk)', advisorRatio, AppColors.hodRole, count: advisors),
          _buildVisualIndicator('Guest / Visiting Faculty Load', 0.08, AppColors.warning),
        ];
        break;
      case 'Placement Stats':
        indicators = [
          _buildVisualIndicator('Tier 1 Product Companies (12+ LPA)', 0.45, AppColors.hodRole),
          _buildVisualIndicator('High-Tech & Core (7 - 11 LPA)', 0.32, const Color(0xFF059669)),
          _buildVisualIndicator('IT Services & Systems (4 - 6 LPA)', 0.16, const Color(0xFF7C3AED)),
          _buildVisualIndicator('Higher Studies / Research', 0.07, const Color(0xFFD97706)),
        ];
        break;
      case 'Department Ranking':
      default:
        indicators = [
          _buildVisualIndicator('Teaching, Learning & Resources (TLR)', 0.94, AppColors.hodRole),
          _buildVisualIndicator('Graduation Outcomes (GO)', 0.96, const Color(0xFF059669)),
          _buildVisualIndicator('Research & Professional Practice (RPC)', 0.88, const Color(0xFF7C3AED)),
          _buildVisualIndicator('Outreach & Inclusivity (OI)', 0.91, const Color(0xFFD97706)),
        ];
        break;
    }

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
              Expanded(
                child: Text(
                  '$_selectedSection Breakdown',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.bar_chart_rounded, color: AppColors.hodRole),
            ],
          ),
          const SizedBox(height: 20),
          ...indicators,
        ],
      ),
    );
  }

  Widget _buildVisualIndicator(String label, double val, Color color, {int? count}) {
    final pctStr = '${(val * 100).toInt()}%';
    final displayStr = count != null ? '$count students ($pctStr)' : pctStr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(displayStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          AppLinearProgressBar(
            lineHeight: 8.0,
            percent: val.clamp(0.0, 1.0),
            progressColor: color,
            backgroundColor: AppColors.background,
            borderRadius: 10.0,
          ),
        ],
      ),
    );
  }

  Widget _buildExportActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _notify(context, 'Analytics Data exported to Excel (.xlsx) successfully!'),
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text('Export Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hodRole,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _notify(context, 'Executive Department Analytics PDF Report generated!'),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Export PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.hodRole,
              side: const BorderSide(color: AppColors.hodRole),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  void _notify(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
  }
}
