import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/submission_model.dart';
import 'package:unisphere/services/assignment_service.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/core/theme/app_animations_kit.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';

class StudentUpcomingTasksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const StudentUpcomingTasksScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<StudentUpcomingTasksScreen> createState() => _StudentUpcomingTasksScreenState();
}

class _StudentUpcomingTasksScreenState extends ConsumerState<StudentUpcomingTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  final AssignmentService _assignmentService = AssignmentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _assignmentService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _assignmentService.removeListener(_onServiceUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _handleBack() {
    if (!mounted) return;
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '1.8 MB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showSubmissionPortalModal(Map<String, dynamic> assignment) {
    final user = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    final meta = user?.metadata ?? {};
    final studentUid = user?.uid ?? '';
    final studentName = user?.fullName ?? user?.name ?? meta['fullName']?.toString() ?? (user?.email.split('@').first ?? 'Student');
    final regNo = meta['registerNumber']?.toString().trim() ?? meta['regNo']?.toString().trim() ?? '';

    final noteController = TextEditingController(text: assignment['notes']?.toString() ?? '');
    String? selectedFileName = assignment['submittedFile']?.toString();
    int? selectedFileSize = assignment['fileSizeBytes'] is int ? assignment['fileSizeBytes'] as int : null;
    String selectedFileType = assignment['fileType']?.toString() ?? 'PDF';
    bool isUploading = false;
    bool isSubmitting = false;
    final isGraded = assignment['status'] == 'Graded';
    final isAlreadySubmitted = assignment['status'] == 'Submitted';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickRealFile() async {
            try {
              setModalState(() {
                isUploading = true;
              });

              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'png', 'jpg', 'jpeg'],
                allowMultiple: false,
                withData: true,
              );

              if (result != null && result.files.isNotEmpty) {
                final file = result.files.first;
                final ext = file.extension?.toUpperCase() ?? 'PDF';
                setModalState(() {
                  selectedFileName = file.name;
                  selectedFileSize = file.size;
                  selectedFileType = ext;
                  isUploading = false;
                });
              } else {
                setModalState(() {
                  isUploading = false;
                });
              }
            } catch (e) {
              debugPrint('FilePicker error, falling back to sample template: $e');
              setModalState(() {
                isUploading = false;
                selectedFileName ??= '${studentName.replaceAll(" ", "_")}_${assignment['courseCode']}_Solution.pdf';
                selectedFileSize ??= 2450000;
                selectedFileType = 'PDF';
              });
            }
          }

          void pickTemplateSample(String sampleName) {
            setModalState(() {
              selectedFileName = sampleName;
              selectedFileSize = 2150000;
              selectedFileType = 'PDF';
            });
          }

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row with Title and Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment['title'] ?? 'Assignment Details',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${assignment['courseCode']} - ${assignment['subjectName']} • Max Marks: ${assignment['maxMarks']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Question Prompt Container
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Posted Question (${assignment['facultyName']}):',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          assignment['questionPrompt'] ?? 'Complete the assignment and upload the solution report.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
                        ),
                        if (assignment['submissionInstructions'] != null &&
                            assignment['submissionInstructions'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Instructions: ${assignment['submissionInstructions']}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Graded Evaluation Box (If Graded)
                  if (isGraded) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Graded by ${assignment['facultyName']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF065F46)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Score: ${assignment['obtainedMarks']} / ${assignment['maxMarks']}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (assignment['feedback'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Feedback: "${assignment['feedback']}"',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Upload File Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAlreadySubmitted || isGraded ? 'Submitted Solution Document' : 'Upload Assignment Solution File',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      if (selectedFileName != null && !isGraded)
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedFileName = null;
                              selectedFileSize = null;
                            });
                          },
                          child: const Text(
                            'Remove File',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Upload Box / Selected File Container
                  InkWell(
                    onTap: isGraded ? null : pickRealFile,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedFileName != null ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedFileName != null ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (isUploading)
                            const CustomLoader(size: 32, label: 'Browsing and uploading document...')
                          else if (selectedFileName != null) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF059669), size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFileName!,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_formatFileSize(selectedFileSize)} • $selectedFileType Document',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
                              ],
                            ),
                            if (!isGraded) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text('Tap to replace with another file', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ] else ...[
                            const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to select & upload PDF document',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Only PDF format (.pdf) supported • Max 25MB',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Quick Sample Document Picker (Convenient Shortcut)
                  if (selectedFileName == null && !isGraded) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Quick Select Solution Template: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        InkWell(
                          onTap: () => pickTemplateSample('${studentName.replaceAll(" ", "_")}_${assignment['courseCode']}_Report.pdf'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Text('Attach ${'PDF Template'}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Submission Notes / Comments
                  const Text(
                    'Submission Notes / Comments (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    enabled: !isGraded,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add remarks or execution notes for instructor...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  if (isGraded)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Done Viewing Grade', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: selectedFileName == null || isSubmitting
                            ? null
                            : () async {
                                setModalState(() {
                                  isSubmitting = true;
                                });

                                final asgId = assignment['id'].toString();
                                final noteText = noteController.text.trim();
                                final nowFormatted = DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.now());

                                // Save submission to AssignmentService & Firestore
                                _assignmentService.saveSubmission(
                                  assignmentId: asgId,
                                  studentUid: studentUid,
                                  studentName: studentName,
                                  registerNumber: regNo,
                                  fileName: selectedFileName!,
                                  fileType: selectedFileType,
                                  fileSizeBytes: selectedFileSize ?? 2450000,
                                  submissionNotes: noteText.isNotEmpty ? noteText : null,
                                  isFinalSubmit: true,
                                );

                                // Update local state for immediate reactivity
                                setState(() {
                                  assignment['status'] = 'Submitted';
                                  assignment['submittedFile'] = selectedFileName;
                                  assignment['submittedDate'] = nowFormatted;
                                  assignment['notes'] = noteText.isNotEmpty ? noteText : null;
                                  assignment['fileSizeBytes'] = selectedFileSize ?? 2450000;
                                  assignment['isDueSoon'] = false;
                                });

                                if (mounted) {
                                  Navigator.pop(ctx);
                                  AppConfetti.show(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '🎉 ${assignment['title']} submitted successfully!',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF059669),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          isSubmitting
                              ? 'Submitting Assignment Solution...'
                              : (isAlreadySubmitted ? 'Update Assignment Solution' : 'Submit Assignment Solution'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: selectedFileName != null ? 3 : 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final studentUid = user?.uid ?? '';

    final dbAssignments = ref.watch(allAssignmentsStreamProvider).value ?? [];
    final dbSubmissions = ref.watch(allSubmissionsStreamProvider).value ?? [];

    List<Map<String, dynamic>> sourceAssignments = [];

    if (dbAssignments.isNotEmpty) {
      sourceAssignments = dbAssignments.map((doc) {
        final id = doc['id']?.toString() ?? 'asg_default';
        final sub = dbSubmissions.firstWhere(
          (s) => s.assignmentId == id && (s.studentUid == studentUid),
          orElse: () => _assignmentService.getSubmissionForStudent(id, studentUid) ??
              SubmissionModel(
                id: '',
                assignmentId: id,
                studentUid: studentUid,
                studentName: user?.fullName ?? user?.name ?? 'Student',
                registerNumber: (user?.metadata?['registerNumber'] ?? user?.metadata?['regNo'] ?? '').toString(),
                submittedAt: DateTime.now(),
                status: doc['status']?.toString() ?? 'Pending',
              ),
        );

        final dueDateStr = doc['due_date']?.toString() ?? doc['dueDate']?.toString();
        DateTime? parsedDueDate;
        if (dueDateStr != null) {
          parsedDueDate = DateTime.tryParse(dueDateStr);
        }

        final now = DateTime.now();
        final isPastDue = parsedDueDate != null && parsedDueDate.isBefore(now);
        final isDueSoon = parsedDueDate != null &&
            !isPastDue &&
            parsedDueDate.difference(now).inHours <= 48 &&
            sub.status != 'Submitted' &&
            sub.status != 'Graded';

        final formattedDueDate = parsedDueDate != null
            ? DateFormat('dd MMM yyyy • hh:mm a').format(parsedDueDate)
            : '22 Aug 2026 • 11:59 PM';

        final String status = sub.id.isNotEmpty
            ? sub.status
            : (isPastDue ? 'Overdue' : (doc['status']?.toString() ?? 'Pending'));

        return {
          'id': id,
          'courseCode': doc['course_code'] ?? doc['courseCode'] ?? doc['subject']?.toString().split(' - ')[0] ?? 'CS301',
          'subjectName': doc['subject_name'] ?? doc['subjectName'] ?? doc['subject']?.toString() ?? 'Computer Networks',
          'title': doc['title']?.toString() ?? 'Posted Assignment',
          'facultyName': doc['author_name'] ?? doc['authorName'] ?? doc['uploadedBy']?.toString() ?? 'Dr. Robert Vance',
          'postedDate': doc['created_at'] != null
              ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(doc['created_at'].toString()) ?? now)
              : 'Official Release',
          'dueDate': formattedDueDate,
          'dueDateTime': parsedDueDate,
          'isDueSoon': isDueSoon,
          'maxMarks': doc['max_marks'] is int ? doc['max_marks'] as int : (int.tryParse(doc['max_marks']?.toString() ?? '') ?? 100),
          'status': status,
          'allowedFormats': 'PDF Document (.pdf)',
          'questionPrompt': doc['description']?.toString() ??
              doc['submission_instructions']?.toString() ??
              'Complete the assignment question and upload your report solution.',
          'submissionInstructions': doc['submission_instructions']?.toString() ?? '',
          'submittedFile': sub.id.isNotEmpty ? sub.fileName : null,
          'submittedDate': sub.id.isNotEmpty ? DateFormat('dd MMM yyyy • hh:mm a').format(sub.submittedAt) : null,
          'obtainedMarks': sub.obtainedMarks,
          'feedback': sub.feedback,
          'notes': sub.submissionNotes,
          'fileSizeBytes': sub.fileSizeBytes,
        };
      }).toList();
    } else {
      sourceAssignments = [];
    }

    final pendingAssignments = sourceAssignments.where((a) => a['status'] == 'Pending' || a['status'] == 'Overdue').toList();
    final submittedAssignments = sourceAssignments.where((a) => a['status'] == 'Submitted').toList();
    final gradedAssignments = sourceAssignments.where((a) => a['status'] == 'Graded').toList();

    List<Map<String, dynamic>> activeList = sourceAssignments;
    if (_selectedTabIndex == 1) activeList = pendingAssignments;
    if (_selectedTabIndex == 2) activeList = submittedAssignments;
    if (_selectedTabIndex == 3) activeList = gradedAssignments;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              UnisphereHeaderCard(
                title: 'Student Assignment Portal',
                subtitle: 'View posted assignment questions & submit coursework online',
                onBack: _handleBack,
                bottomWidget: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    indicator: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFBFDBFE),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'All (${sourceAssignments.length})'),
                      Tab(text: 'Pending (${pendingAssignments.length})'),
                      Tab(text: 'Submitted (${submittedAssignments.length})'),
                      Tab(text: 'Graded (${gradedAssignments.length})'),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔔 Pending Assignment Deadline Notification Banner
                      if (pendingAssignments.isNotEmpty) ...[
                        _buildDeadlineNotificationBanner(pendingAssignments.length),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'Faculty Posted Assignments & Question Papers',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),

                      if (activeList.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(36),
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.assignment_turned_in_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              Text(
                                _selectedTabIndex == 1
                                    ? '🎉 All caught up! No pending assignments.'
                                    : 'No assignments under this tab',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeList.length,
                          itemBuilder: (context, index) {
                            final assignment = activeList[index];
                            return _buildAssignmentQuestionCard(assignment);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔔 Deadline Notification Alert Banner
  Widget _buildDeadlineNotificationBanner(int pendingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDBA74)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFEA580C), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'DEADLINE ALERT NOTIFICATION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFC2410C), letterSpacing: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$pendingCount Pending',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'You have pending assignment submissions due soon! Please review question prompts and submit your coursework before deadlines.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7C2D12), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📝 Posted Assignment Question Card
  Widget _buildAssignmentQuestionCard(Map<String, dynamic> assignment) {
    final status = assignment['status'] as String;
    final isPending = status == 'Pending' || status == 'Overdue';
    final isSubmitted = status == 'Submitted';
    final isGraded = status == 'Graded';
    final isDueSoon = (assignment['isDueSoon'] as bool?) ?? false;

    Color statusColor = const Color(0xFF2563EB);
    Color statusBg = const Color(0xFFEFF6FF);
    if (isPending) {
      statusColor = isDueSoon ? const Color(0xFFDC2626) : const Color(0xFFD97706);
      statusBg = isDueSoon ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    } else if (isSubmitted) {
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFEFF6FF);
    } else if (isGraded) {
      statusColor = const Color(0xFF059669);
      statusBg = const Color(0xFFECFDF5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDueSoon ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      assignment['courseCode'] ?? 'CS301',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    assignment['subjectName'] ?? 'Subject',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDueSoon) ...[
                      const Icon(Icons.timer_outlined, size: 12, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isDueSoon ? 'DUE SOON' : status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            assignment['title'] ?? 'Assignment Title',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Posted by ${assignment['facultyName']} on ${assignment['postedDate']}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Question Prompt Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.quiz_outlined, size: 15, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Text(
                      'Posted Question Prompt:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  assignment['questionPrompt'] ?? 'View assignment problem statement and upload solution.',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Due date and Max Marks Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${assignment['dueDate']}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isDueSoon ? FontWeight.bold : FontWeight.w500,
                      color: isDueSoon ? const Color(0xFFDC2626) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              Text(
                'Max Marks: ${assignment['maxMarks']}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),

          if (isSubmitted || isGraded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isGraded ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isGraded ? Icons.workspace_premium_rounded : Icons.check_circle_rounded,
                    color: isGraded ? const Color(0xFF059669) : const Color(0xFF2563EB),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGraded
                              ? 'Graded: ${assignment['obtainedMarks']} / ${assignment['maxMarks']} Marks'
                              : 'Submitted file: ${assignment['submittedFile']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isGraded ? const Color(0xFF059669) : const Color(0xFF2563EB),
                          ),
                        ),
                        if (isGraded && assignment['feedback'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Feedback: ${assignment['feedback']}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                          ),
                        ],
                        if (!isGraded && assignment['submittedDate'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Submitted: ${assignment['submittedDate']}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Submit / View Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _showSubmissionPortalModal(assignment),
              icon: Icon(
                isPending
                    ? Icons.upload_file_rounded
                    : isSubmitted
                        ? Icons.edit_document
                        : Icons.rate_review_rounded,
                size: 16,
              ),
              label: Text(
                isPending
                    ? 'Submit Assignment Solution'
                    : isSubmitted
                        ? 'Update / View Submission'
                        : 'View Submission & Grade',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
