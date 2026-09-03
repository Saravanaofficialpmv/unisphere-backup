import 'package:flutter/material.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/submission_model.dart';
import 'package:unisphere/services/assignment_service.dart';
import 'package:unisphere/widgets/common/apple_glass_card.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class StaffSubmissionReview extends StatefulWidget {
  const StaffSubmissionReview({super.key});

  @override
  State<StaffSubmissionReview> createState() => _StaffSubmissionReviewState();
}

class _StaffSubmissionReviewState extends State<StaffSubmissionReview> {
  final AssignmentService _service = AssignmentService();
  String? _selectedAssignmentId;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
    if (_service.assignments.isNotEmpty) {
      _selectedAssignmentId = _service.assignments.first.id;
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final assignments = _service.assignments;
    final submissions = _selectedAssignmentId != null
        ? _service.getSubmissionsForAssignment(_selectedAssignmentId!)
        : <SubmissionModel>[];

    return Container(
      color: Colors.white,
      child: AppLiquidPullToRefresh(
        gifAsset: 'assets/tibsy-dp.gif',
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 1000));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            _buildHeaderBanner(),
            const SizedBox(height: 24),

            // Select Assignment Dropdown Selector
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text('Select Assignment to Review:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAssignmentId,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                        items: assignments.map((asg) {
                          return DropdownMenuItem<String>(
                            value: asg.id,
                            child: Text(
                              '${asg.courseCode} - ${asg.title}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedAssignmentId = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submissions List Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Student File Submissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('${submissions.length} Total Submissions', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),

            if (submissions.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No student submissions received for this assignment yet.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: submissions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final sub = submissions[index];
                  return _buildSubmissionCard(sub);
                },
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.rate_review_rounded, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student Submissions & Evaluation Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Review submitted files, inspect register numbers, evaluate work, and publish grades with comments.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(SubmissionModel sub) {
    final isGraded = sub.isGraded;

    return AppleGlassCard.frosted(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(sub.registerNumber, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(sub.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text('File: ${sub.fileName ?? "Submission.pdf"} (${((sub.fileSizeBytes ?? 2000000) / (1024 * 1024)).toStringAsFixed(2)} MB)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (isGraded) ...[
                  const SizedBox(height: 4),
                  Text('Feedback: "${sub.feedback ?? ""}"', style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isGraded) ...[
                Text('${sub.obtainedMarks} / 100', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                const Text('Graded', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _openGradingDialog(sub),
                icon: Icon(isGraded ? Icons.edit_rounded : Icons.grade_rounded, size: 16),
                label: Text(isGraded ? 'Edit Grade' : 'Grade & Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGraded ? const Color(0xFF10B981) : AppColors.primary,
                  minimumSize: const Size(130, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = const Color(0xFFDBEAFE);
    Color fg = const Color(0xFF1D4ED8);
    if (status == 'Graded') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF047857);
    } else if (status == 'Late') {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _openGradingDialog(SubmissionModel sub) {
    final marksController = TextEditingController(text: sub.obtainedMarks?.toString() ?? '92');
    final feedbackController = TextEditingController(text: sub.feedback ?? 'Good work on your implementation!');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.grading_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('Grade ${sub.studentName} (${sub.registerNumber})'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Attached: ${sub.fileName}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),

            TextFormField(
              controller: marksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Marks Awarded (out of 100)',
                suffixText: '/ 100',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Instructor Feedback & Comments',
                hintText: 'Enter detailed feedback for the student...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final marks = int.tryParse(marksController.text) ?? 90;
              _service.gradeSubmission(
                submissionId: sub.id,
                marks: marks,
                feedback: feedbackController.text.trim(),
                gradedBy: 'Prof. Sarah Jenkins',
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Grade & Feedback Published to Student! 🎉'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save & Publish Grade'),
          ),
        ],
      ),
    );
  }
}
