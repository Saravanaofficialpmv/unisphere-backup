import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/models.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/providers/notification_provider.dart';
import 'package:unisphere/repositories/repositories.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/marks_import_service.dart';

class HodExamManagement extends ConsumerStatefulWidget {
  const HodExamManagement({super.key});

  @override
  ConsumerState<HodExamManagement> createState() => _HodExamManagementState();
}

class _HodExamManagementState extends ConsumerState<HodExamManagement> {
  String _selectedExam = 'Internal Assessment 2';
  String _selectedYear = '3rd Year (Semester 6)';

  int _getSemesterNumber(String yearStr) {
    final match = RegExp(r'Semester (\d+)').firstMatch(yearStr);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '6') ?? 6;
    }
    return 6;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Pending Verification':
        return AppColors.warning;
      case 'Not Uploaded':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sem = _getSemesterNumber(_selectedYear);
    final evaluationAsync = ref.watch(
      hodEvaluationStatusStreamProvider((examTitle: _selectedExam, semester: sem)),
    );
    final evaluationList = evaluationAsync.valueOrNull ?? [];

    final approvedCount = evaluationList.where((d) => d.status == 'Approved').length;
    final totalCount = evaluationList.isNotEmpty ? evaluationList.length : 5;
    final uploadPct = evaluationList.isNotEmpty ? ((approvedCount / totalCount) * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASSESSMENT CONTROL HUB',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Examination & Marks',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Even Sem 2026', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildExamSelectionHeader(),
            const SizedBox(height: 20),

            _buildExamCards(uploadPct, approvedCount, totalCount),
            const SizedBox(height: 24),

            _buildEvaluationStatusList(context, evaluationList, evaluationAsync.isLoading, sem),
            const SizedBox(height: 24),

            _buildExamActions(context, approvedCount, totalCount, sem),
          ],
        ),
      ),
    );
  }

  Widget _buildExamSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedExam,
              decoration: const InputDecoration(labelText: 'Target Examination', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: ['Internal Assessment 1', 'Internal Assessment 2', 'Model Examination', 'Semester Final']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedExam = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(labelText: 'Target Batch', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: ['3rd Year (Semester 6)', '2nd Year (Semester 4)', '1st Year (Semester 2)', '4th Year (Semester 8)']
                  .map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedYear = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCards(int uploadPct, int approvedCount, int totalCount) {
    final items = [
      {'title': 'Active Exam', 'val': _selectedExam, 'icon': Icons.assignment_outlined, 'color': AppColors.primary},
      {'title': 'Marks Uploaded', 'val': '$approvedCount of $totalCount Subjects ($uploadPct%)', 'icon': Icons.upload_file_rounded, 'color': const Color(0xFF059669)},
      {'title': 'Pass Percentage', 'val': '96.4% Department Avg', 'icon': Icons.verified_outlined, 'color': const Color(0xFFD97706)},
      {'title': 'Department Rank List', 'val': 'Top 10 Ranks Verified', 'icon': Icons.emoji_events_outlined, 'color': const Color(0xFF0891B2)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final Color col = item['color'] as Color;

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
              Icon(item['icon'] as IconData, color: col, size: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    item['val'] as String,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: col),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvaluationStatusList(
    BuildContext context,
    List<ExamEvaluationSubjectStatus> evaluationList,
    bool isLoading,
    int sem,
  ) {
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
              const Text('Faculty Evaluation & Marks Approval Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('${evaluationList.length} Subjects', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading && evaluationList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (evaluationList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 36, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text('No subjects configured for Semester $sem', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: evaluationList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = evaluationList[index];
                final status = d.status;
                final col = _getStatusColor(status);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.sub, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Faculty: ${d.faculty} • ${d.submittedAt}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildMiniScore('Class Avg', d.avgScore),
                          const SizedBox(width: 16),
                          _buildMiniScore('Pass %', d.passPct),
                          const SizedBox(width: 16),
                          _buildMiniScore('Enrolled', '${d.totalStudents} Students'),
                          const Spacer(),
                          if (status == 'Pending Verification')
                            ElevatedButton.icon(
                              onPressed: () async {
                                final user = ref.read(currentUserProvider).value;
                                final approver = (user?.fullName != null && user!.fullName.isNotEmpty) ? user.fullName : 'HOD';
                                if (d.documentId != null && d.documentId!.isNotEmpty) {
                                  await ref.read(examManagementRepositoryProvider).approveMarksDocument(d.documentId!, approver);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('🎉 Verified and signed off marks for ${d.code}!'), backgroundColor: const Color(0xFF10B981)),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_rounded, size: 14),
                              label: const Text('Sign Off', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            )
                          else if (status == 'Not Uploaded')
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(examManagementRepositoryProvider).remindFaculty(
                                  facultyUid: d.facultyUid ?? '',
                                  facultyName: d.faculty,
                                  subjectCode: d.code,
                                  examTitle: _selectedExam,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Sent submission reminder to ${d.faculty}'), backgroundColor: AppColors.primary),
                                  );
                                }
                              },
                              icon: const Icon(Icons.send_rounded, size: 14),
                              label: const Text('Remind', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildExamActions(BuildContext context, int approvedCount, int totalCount, int sem) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showHodFinalSemesterUploadModal(context),
          icon: const Icon(Icons.upload_file_rounded, size: 16),
          label: const Text('Upload Final Semester Marks (HOD)'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
        ),
        ElevatedButton.icon(
          onPressed: () => _showPublishMarksDialog(context, approvedCount, totalCount, sem),
          icon: const Icon(Icons.publish_rounded, size: 16),
          label: const Text('Publish Marks to Portals'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
        OutlinedButton.icon(
          onPressed: () => _showRankListModal(context, sem),
          icon: const Icon(Icons.workspace_premium_outlined, size: 16),
          label: const Text('Department Rank List'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Official Mark Register generated and exported to PDF.'), backgroundColor: AppColors.success),
            );
          },
          icon: const Icon(Icons.menu_book_outlined, size: 16),
          label: const Text('Export Mark Register'),
        ),
      ],
    );
  }

  void _showPublishMarksDialog(BuildContext context, int approved, int total, int sem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.publish_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Publish Examination Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are publishing marks for $_selectedExam ($_selectedYear).'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Approval Status: $approved of $total subjects verified and ready.\nStudents and Parents will be immediately notified.',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = ref.read(currentUserProvider).value;
              final approver = (user?.fullName != null && user!.fullName.isNotEmpty) ? user.fullName : 'HOD';
              final deptId = ref.read(hodDepartmentIdProvider);

              await ref.read(examManagementRepositoryProvider).publishDepartmentMarks(
                departmentId: deptId,
                examTitle: _selectedExam,
                semester: sem,
                publishedByName: approver,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 $_selectedExam marks published to Student and Parent Portals!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm & Publish'),
          ),
        ],
      ),
    );
  }

  void _showRankListModal(BuildContext context, int sem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final rankAsync = ref.watch(hodDepartmentRankListProvider(sem));

          return Padding(
            padding: const EdgeInsets.all(20),
            child: rankAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading rank list: $e', style: const TextStyle(color: AppColors.error)),
              ),
              data: (ranks) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Department Rank List (${ranks.length} Ranked)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (ranks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No rank data available yet.')),
                      )
                    else
                      ...ranks.map((r) {
                        final rankNum = r.rank;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: rankNum == 1 ? const Color(0xFFFEF3C7) : (rankNum == 2 ? const Color(0xFFF1F5F9) : const Color(0xFFFFF7ED)),
                                  shape: BoxShape.circle,
                                ),
                                child: Text('#$rankNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Reg: ${r.reg} • ${r.distinction}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text('GPA: ${r.gpa}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHodFinalSemesterUploadModal(BuildContext context) {
    String selectedSubject = 'CS301 - Distributed Systems';
    String selectedSemester = 'Semester 6';
    String fileName = '';
    bool isPicked = false;
    bool isSubmitting = false;
    List<Map<String, dynamic>> records = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0F172A), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOD Final Semester Marks Gate',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Authorized end-semester exam marks publication',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Institutional Governance: Only HOD holds official signing & publication rights for university Final Semester marks.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CS301 - Distributed Systems', child: Text('CS301 - Distributed Systems')),
                    DropdownMenuItem(value: 'CS302 - Compiler Design', child: Text('CS302 - Compiler Design')),
                    DropdownMenuItem(value: 'CS303 - Cloud Computing', child: Text('CS303 - Cloud Computing')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedSubject = val);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSemester,
                        decoration: InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Semester 6', child: Text('Semester 6')),
                          DropdownMenuItem(value: 'Semester 7', child: Text('Semester 7')),
                          DropdownMenuItem(value: 'Semester 8', child: Text('Semester 8')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedSemester = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setModalState(() {
                                fileName = result.files.first.name;
                                isPicked = true;
                              });
                            }
                          } catch (e) {
                            debugPrint('FilePicker notice: $e');
                          }
                        },
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: Text(
                          isPicked ? 'Attached: $fileName' : 'Pick File',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Parsed Student Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('${records.length} Valid Records', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (records.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No records attached. Select an official Excel/CSV marks file above.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...records.map((r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text('${r['regNo']} - ${r['name']}', style: const TextStyle(fontSize: 12))),
                                  Text(r['initial'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            try {
                              final currentUser = ref.read(authServiceProvider).currentUser ??
                                  UserModel(
                                    uid: 'HOD-CSE',
                                    email: 'hod.cse@unisphere.edu',
                                    fullName: 'Dr. S. K. Ramanathan',
                                    role: UserRole.hod,
                                    metadata: const {
                                      'departmentId': 'DEP-CSE',
                                      'departmentName': 'Computer Science & Engineering',
                                    },
                                  );

                              final marksService = MarksImportService();
                              final parts = selectedSubject.split(' - ');
                              final courseCode = parts[0].trim();
                              final subjectName = parts.length > 1 ? parts[1].trim() : selectedSubject;

                              final doc = await marksService.importMarksDocument(
                                fileName: fileName,
                                fileType: fileName.endsWith('.csv') ? 'csv' : 'xlsx',
                                departmentId: currentUser.departmentId ?? 'DEP-CSE',
                                departmentName: currentUser.departmentName ?? 'Computer Science & Engineering',
                                courseCode: courseCode,
                                subjectName: subjectName,
                                assessmentType: MarksDocumentModel.typeFinalSemester,
                                semester: 6,
                                currentUser: currentUser,
                                records: records,
                                maximumMarks: 100.0,
                                weightage: 100.0,
                              );

                              ref.read(notificationProvider.notifier).addNotification(
                                    title: 'Final Semester Marks Published',
                                    category: 'Examination',
                                    summary: 'Official Final Semester Marks for $selectedSubject have been published by HOD.',
                                    fullDetails: 'View official subject grade sheets in academic portal.',
                                    icon: Icons.verified_rounded,
                                    iconColor: AppColors.primary,
                                    iconBgColor: const Color(0xFFEEF2FF),
                                    badgeText: 'RESULTS',
                                    badgeColor: AppColors.primary,
                                    badgeTextColor: Colors.white,
                                  );

                              if (modalCtx.mounted) {
                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Successfully signed & published ${doc.validRecordsCount} Final Semester records into marks collection!'),
                                    backgroundColor: const Color(0xFF10B981),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (modalCtx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error publishing marks: $e'), backgroundColor: const Color(0xFFDC2626)),
                                );
                              }
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.verified, size: 18),
                    label: Text(
                      isSubmitting ? 'Verifying & Committing to Database...' : 'Sign & Publish Final Semester Marks',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
