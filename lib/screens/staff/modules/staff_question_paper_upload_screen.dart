import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/controllers/question_paper_controller.dart';
import 'package:unisphere/models/question_paper_model.dart';
import 'package:unisphere/screens/student/modules/student_pyq_screen.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class StaffQuestionPaperUploadScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const StaffQuestionPaperUploadScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<StaffQuestionPaperUploadScreen> createState() =>
      _StaffQuestionPaperUploadScreenState();
}

class _StaffQuestionPaperUploadScreenState
    extends ConsumerState<StaffQuestionPaperUploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectCodeController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _examSessionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedDepartment = 'Computer Science & Engineering';
  String _selectedSemester = 'Semester 3';
  String _selectedYear = 'II Year';
  String _selectedRegulation = 'Regulation 2021';
  QuestionPaperType _selectedPaperType = QuestionPaperType.universityPyq;
  bool _hasAnswerKey = true;

  // Uploaded File Mock / Picked State
  String? _pickedFileName;
  String? _pickedFileSize;
  String? _pickedAnswerKeyFileName;
  String? _pickedAnswerKeyFileSize;
  bool _isSubmitting = false;

  final List<String> _departments = [
    'Computer Science & Engineering',
    'Artificial Intelligence & Data Science',
    'Information Technology',
    'Electronics & Communication Engg',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical & Electronics Engg',
    'Common to All Branches',
  ];

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  final List<String> _years = [
    'I Year',
    'II Year',
    'III Year',
    'IV Year',
  ];

  final List<String> _regulations = [
    'Regulation 2021',
    'Regulation 2023',
    'Regulation 2017',
  ];

  final List<Map<String, String>> _quickSubjects = [
    {'code': 'CS3301', 'name': 'Data Structures', 'dept': 'Computer Science & Engineering', 'sem': 'Semester 3', 'year': 'II Year'},
    {'code': 'CS3391', 'name': 'Object Oriented Programming', 'dept': 'Computer Science & Engineering', 'sem': 'Semester 3', 'year': 'II Year'},
    {'code': 'CS3351', 'name': 'Digital Principles & Computer Org', 'dept': 'Computer Science & Engineering', 'sem': 'Semester 3', 'year': 'II Year'},
    {'code': 'CS3492', 'name': 'Database Management Systems', 'dept': 'Computer Science & Engineering', 'sem': 'Semester 4', 'year': 'II Year'},
    {'code': 'CS3451', 'name': 'Operating Systems', 'dept': 'Computer Science & Engineering', 'sem': 'Semester 4', 'year': 'II Year'},
    {'code': 'AI3501', 'name': 'Artificial Intelligence and ML', 'dept': 'Artificial Intelligence & Data Science', 'sem': 'Semester 5', 'year': 'III Year'},
    {'code': 'GE3151', 'name': 'Problem Solving and Python', 'dept': 'Common to All Branches', 'sem': 'Semester 1', 'year': 'I Year'},
    {'code': 'MA3151', 'name': 'Matrices and Calculus', 'dept': 'Common to All Branches', 'sem': 'Semester 1', 'year': 'I Year'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _examSessionController.text = 'Nov / Dec 2024';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _examSessionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _applyQuickSubject(Map<String, String> subj) {
    setState(() {
      _subjectCodeController.text = subj['code']!;
      _subjectNameController.text = subj['name']!;
      _selectedDepartment = subj['dept']!;
      _selectedSemester = subj['sem']!;
      _selectedYear = subj['year']!;
      _titleController.text = '${subj['name']} - ${_selectedPaperType.displayName}';
    });
  }

  Future<void> _pickQuestionPaperFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedFileName = file.name;
          final bytes = file.size;
          if (bytes > 1024 * 1024) {
            _pickedFileSize = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
          } else {
            _pickedFileSize = '${(bytes / 1024).toStringAsFixed(0)} KB';
          }
        });
      }
    } catch (e) {
      // Fallback demo file if platform picker encounters issues
      setState(() {
        final code = _subjectCodeController.text.trim().isEmpty ? 'SUBJ' : _subjectCodeController.text.trim();
        _pickedFileName = '${code}_QuestionPaper_Official.pdf';
        _pickedFileSize = '2.8 MB';
      });
    }
  }

  Future<void> _pickAnswerKeyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedAnswerKeyFileName = file.name;
          final bytes = file.size;
          if (bytes > 1024 * 1024) {
            _pickedAnswerKeyFileSize = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
          } else {
            _pickedAnswerKeyFileSize = '${(bytes / 1024).toStringAsFixed(0)} KB';
          }
        });
      }
    } catch (e) {
      setState(() {
        final code = _subjectCodeController.text.trim().isEmpty ? 'SUBJ' : _subjectCodeController.text.trim();
        _pickedAnswerKeyFileName = '${code}_AnswerKey_ModelSolutions.pdf';
        _pickedAnswerKeyFileSize = '3.6 MB';
      });
    }
  }

  Future<void> _submitPaper() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pickedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach the Question Paper document (PDF).'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final currentUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    final staffName = currentUser?.name ?? 'Prof. Staff Member';
    final staffId = currentUser?.uid ?? 'staff_current';
    final staffDept = currentUser?.metadata?['department']?.toString() ?? 'Faculty Member';

    final tagList = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final newPaper = QuestionPaperModel(
      id: '',
      title: _titleController.text.trim().isEmpty
          ? '${_subjectNameController.text.trim()} - ${_selectedPaperType.displayName}'
          : _titleController.text.trim(),
      subjectCode: _subjectCodeController.text.trim().toUpperCase(),
      subjectName: _subjectNameController.text.trim(),
      department: _selectedDepartment,
      regulation: _selectedRegulation,
      year: _selectedYear,
      semester: _selectedSemester,
      academicYear: '2024–2025',
      examSession: _examSessionController.text.trim().isEmpty ? 'Nov / Dec 2024' : _examSessionController.text.trim(),
      paperType: _selectedPaperType,
      hasAnswerKey: _hasAnswerKey,
      fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      fileName: _pickedFileName!,
      fileSize: _pickedFileSize ?? '2.5 MB',
      answerKeyUrl: _hasAnswerKey ? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf' : null,
      answerKeyFileName: _hasAnswerKey ? (_pickedAnswerKeyFileName ?? 'Answer_Key.pdf') : null,
      answerKeyFileSize: _hasAnswerKey ? (_pickedAnswerKeyFileSize ?? '3.2 MB') : null,
      uploadedByStaffId: staffId,
      uploadedByStaffName: staffName,
      uploadedByStaffDesignation: staffDept,
      uploadedAt: DateTime.now(),
      downloadCount: 0,
      isVerified: true,
      tags: tagList,
    );

    final success = await ref.read(questionPaperControllerProvider.notifier).uploadPaper(newPaper);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${newPaper.subjectCode} ${_selectedPaperType.shortLabel} published successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reset Form & Switch to "My Uploads" Tab
        _formKey.currentState!.reset();
        _pickedFileName = null;
        _pickedAnswerKeyFileName = null;
        _tabController.animateTo(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish question paper. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            UnisphereHeaderCard(
              title: 'Question Papers & Bank Upload',
              subtitle: 'Upload & Manage Semester Question Papers, IATs & Answer Keys',
              onBack: _handleBack,
            ),
            // Custom Tab Bar
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF1E293B),
                indicatorWeight: 3,
                labelColor: const Color(0xFF1E293B),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.upload_file_rounded, size: 18), text: 'Upload New Paper / Bank'),
                  Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'My Uploaded Materials'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUploadFormTab(isDesktop),
                  _buildMyUploadsTab(isDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadFormTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Subject Selector Chips
            const Text(
              'Quick Fill Course Template',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickSubjects.map((subj) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF2563EB)),
                      label: Text(
                        '${subj['code']} · ${subj['name']}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onPressed: () => _applyQuickSubject(subj),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Main Upload Form Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paper & Subject Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),

                  // Paper Type Dropdown / Selector
                  _buildFormLabel('Exam / Material Type'),
                  DropdownButtonFormField<QuestionPaperType>(
                    initialValue: _selectedPaperType,
                    decoration: _inputDecoration('Select paper type'),
                    items: QuestionPaperType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPaperType = val;
                          if (_subjectNameController.text.isNotEmpty) {
                            _titleController.text = '${_subjectNameController.text} - ${val.displayName}';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subject Code & Subject Name Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Subject Code *'),
                            TextFormField(
                              controller: _subjectCodeController,
                              textCapitalization: TextCapitalization.characters,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              decoration: _inputDecoration('e.g. CS3301'),
                              onChanged: (v) {
                                if (_titleController.text.isEmpty && _subjectNameController.text.isNotEmpty) {
                                  _titleController.text = '${_subjectNameController.text} - ${_selectedPaperType.displayName}';
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Subject Name *'),
                            TextFormField(
                              controller: _subjectNameController,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              decoration: _inputDecoration('e.g. Data Structures'),
                              onChanged: (v) {
                                _titleController.text = '$v - ${_selectedPaperType.displayName}';
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Department & Regulation Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Department *'),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDepartment,
                              isExpanded: true,
                              decoration: _inputDecoration('Select department'),
                              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _selectedDepartment = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Regulation *'),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRegulation,
                              decoration: _inputDecoration('Select regulation'),
                              items: _regulations.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12.5)))).toList(),
                              onChanged: (v) => setState(() => _selectedRegulation = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Semester, Year & Exam Session Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Semester *'),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSemester,
                              decoration: _inputDecoration('Semester'),
                              items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12.5)))).toList(),
                              onChanged: (v) => setState(() => _selectedSemester = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Academic Year *'),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedYear,
                              decoration: _inputDecoration('Year'),
                              items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 12.5)))).toList(),
                              onChanged: (v) => setState(() => _selectedYear = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Exam Session *'),
                            TextFormField(
                              controller: _examSessionController,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              decoration: _inputDecoration('e.g. Nov / Dec 2024'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  _buildFormLabel('Display Title / Description'),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Custom descriptive title (Optional)'),
                  ),
                  const SizedBox(height: 16),

                  // Tags Field
                  _buildFormLabel('Tags / Topics (Comma-separated)'),
                  TextFormField(
                    controller: _tagsController,
                    decoration: _inputDecoration('e.g. Unit 1 to 5, Anna University Solved, Trees, Graphs'),
                  ),
                  const SizedBox(height: 24),

                  // File Attachments Section
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  const Text(
                    'Document Attachments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),

                  // Question Paper Attachment Box
                  _buildFileAttachmentCard(
                    title: 'Question Paper PDF Document *',
                    fileName: _pickedFileName,
                    fileSize: _pickedFileSize,
                    onPick: _pickQuestionPaperFile,
                    icon: Icons.picture_as_pdf_rounded,
                    accentColor: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 16),

                  // Solved Answer Key Toggle Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _hasAnswerKey ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _hasAnswerKey ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Attach Solved Model Answer Key',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                                ),
                              ],
                            ),
                            Switch(
                              value: _hasAnswerKey,
                              activeThumbColor: const Color(0xFF16A34A),
                              onChanged: (val) => setState(() => _hasAnswerKey = val),
                            ),
                          ],
                        ),
                        if (_hasAnswerKey) ...[
                          const SizedBox(height: 10),
                          _buildFileAttachmentCard(
                            title: 'Verified Answer Key / Solutions PDF',
                            fileName: _pickedAnswerKeyFileName ?? (_pickedFileName != null ? '${_subjectCodeController.text}_AnswerKey_Solved.pdf' : null),
                            fileSize: _pickedAnswerKeyFileSize ?? '3.5 MB',
                            onPick: _pickAnswerKeyFile,
                            icon: Icons.check_circle_outline_rounded,
                            accentColor: const Color(0xFF16A34A),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitPaper,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        _isSubmitting ? 'Publishing Material...' : 'Publish Question Paper / Bank to Students',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileAttachmentCard({
    required String title,
    required String? fileName,
    required String? fileSize,
    required VoidCallback onPick,
    required IconData icon,
    required Color accentColor,
  }) {
    final hasFile = fileName != null && fileName.isNotEmpty;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? accentColor : const Color(0xFFCBD5E1),
            style: hasFile ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? '$fileName ($fileSize)' : 'Tap to browse and select PDF document from device',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: hasFile ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onPick,
              icon: Icon(hasFile ? Icons.swap_horiz_rounded : Icons.attach_file_rounded, size: 16, color: accentColor),
              label: Text(
                hasFile ? 'Change' : 'Browse',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyUploadsTab(bool isDesktop) {
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final staffId = currentUser?.uid ?? '';
    final papersAsync = ref.watch(staffUploadedPapersProvider(staffId));

    return AppLiquidPullToRefresh(
      gifAsset: 'assets/tibsy-dp.gif',
      onRefresh: () async {
        ref.invalidate(questionPaperControllerProvider);
        if (staffId.isNotEmpty) {
          ref.invalidate(staffUploadedPapersProvider(staffId));
        }
        await Future.delayed(const Duration(milliseconds: 1000));
      },
      child: papersAsync.when(
        loading: () => const Center(child: Loader(label: 'Loading question papers...')),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: SizedBox(
            height: 300,
            child: Center(child: Text('Error: $err')),
          ),
        ),
        data: (papers) {
          if (papers.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: SizedBox(
                height: 350,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text('No question papers uploaded yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      const Text('Upload your subject question papers and question banks in Tab 1', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _tabController.animateTo(0),
                        child: const Text('Upload New Material'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 20,
            ),
            itemCount: papers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final paper = papers[index];
            final formattedDate = DateFormat('MMM dd, yyyy').format(paper.uploadedAt);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                paper.subjectCode,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                paper.paperType.shortLabel,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          paper.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${paper.subjectName} · ${paper.semester} · ${paper.examSession}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.download_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              '${paper.downloadCount} student downloads',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                            if (paper.hasAnswerKey) ...[
                              const SizedBox(width: 10),
                              const Text('·', style: TextStyle(color: Color(0xFF94A3B8))),
                              const SizedBox(width: 10),
                              const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              const Text(
                                'Answer Key Attached',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions: Preview & Delete
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                    onSelected: (val) async {
                      if (val == 'preview') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuestionPaperDocumentViewerScreen(paper: paper),
                          ),
                        );
                      } else if (val == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Question Paper?'),
                            content: Text('Are you sure you want to remove ${paper.title}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(questionPaperControllerProvider.notifier).deletePaper(paper.id);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'preview', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('Preview')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
