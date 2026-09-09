import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:unisphere/models/nptel_certificate_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/nptel_service.dart';

class NptelUploadModal extends ConsumerStatefulWidget {
  final NptelCertificateModel? existingCertificate;

  const NptelUploadModal({super.key, this.existingCertificate});

  static Future<void> show(BuildContext context, {NptelCertificateModel? existingCertificate}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: NptelUploadModal(existingCertificate: existingCertificate),
        ),
      ),
    );
  }

  @override
  ConsumerState<NptelUploadModal> createState() => _NptelUploadModalState();
}

class _NptelUploadModalState extends ConsumerState<NptelUploadModal> {
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, String>> _nptelCourses = [
    {'name': 'Programming in Java', 'code': 'NPTEL24CS01'},
    {'name': 'Data Structures and Algorithms in Java', 'code': 'NPTEL25CS09'},
    {'name': 'Database Management Systems', 'code': 'NPTEL25CS42'},
    {'name': 'Cloud Computing', 'code': 'NPTEL26CS14'},
    {'name': 'Python for Data Science', 'code': 'NPTEL26CS29'},
    {'name': 'Machine Learning', 'code': 'NPTEL26CS50'},
    {'name': 'Compiler Design', 'code': 'NPTEL26CS62'},
    {'name': 'Operating Systems', 'code': 'NPTEL26CS71'},
  ];

  final List<String> _semesters = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
  ];

  final List<String> _academicYears = [
    '2026–27',
    '2025–26',
    '2024–25',
    '2023–24',
  ];

  final List<String> _grades = [
    'Elite',
    'Elite + Gold',
    'Elite + Silver',
    'Successfully Completed',
    'Domain Scholar',
  ];

  late String _selectedCourseName;
  late TextEditingController _courseCodeController;
  late String _selectedSemester;
  late String _selectedAcademicYear;
  late TextEditingController _scoreController;
  late String _selectedGrade;
  late TextEditingController _certificateIdController;
  late TextEditingController _issueDateController;

  String? _selectedFileName;
  String _selectedFileSize = '1.4 MB';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCertificate;

    _selectedCourseName = existing?.courseName ?? 'Programming in Java';
    final matchedCourse = _nptelCourses.firstWhere(
      (c) => c['name'] == _selectedCourseName,
      orElse: () => _nptelCourses.first,
    );

    _courseCodeController = TextEditingController(text: existing?.courseCode ?? matchedCourse['code']);
    _selectedSemester = existing?.semester ?? '5th Semester';
    _selectedAcademicYear = existing?.academicYear ?? '2026–27';
    _scoreController = TextEditingController(text: existing?.score ?? '82%');
    _selectedGrade = existing?.grade ?? 'Elite';
    _certificateIdController = TextEditingController(text: existing?.certificateId ?? 'NPTEL-CS20268812');
    _issueDateController = TextEditingController(text: existing?.issueDate ?? '10 Aug 2026');
    _selectedFileName = existing?.fileName ?? 'nptel_java_certificate.pdf';
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _scoreController.dispose();
    _certificateIdController.dispose();
    _issueDateController.dispose();
    super.dispose();
  }

  void _onCourseChanged(String? newCourse) {
    if (newCourse != null) {
      setState(() {
        _selectedCourseName = newCourse;
        final matched = _nptelCourses.firstWhere(
          (c) => c['name'] == newCourse,
          orElse: () => {'name': newCourse, 'code': 'NPTEL24CS01'},
        );
        _courseCodeController.text = matched['code']!;
      });
    }
  }

  Future<void> _pickRealFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final sizeInMb = (file.size / (1024 * 1024)).toStringAsFixed(1);
        final displaySize = sizeInMb == '0.0' ? '0.6 MB' : '$sizeInMb MB';

        setState(() {
          _selectedFileName = file.name;
          _selectedFileSize = displaySize;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Selected PDF Document: ${file.name} ($displaySize)'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF2563EB),
            ),
          );
        }
        return;
      }
    } catch (_) {}
    _pickSimulatedFile();
  }

  void _pickSimulatedFile() {
    setState(() {
      _selectedFileName = '${_selectedCourseName.toLowerCase().replaceAll(' ', '_')}_cert.pdf';
      _selectedFileSize = '1.6 MB';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected $_selectedFileName ($_selectedFileSize)'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 8, 10),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final formatted = '${picked.day.toString().padLeft(2, '0')} ${monthNames[picked.month - 1]} ${picked.year}';
      setState(() {
        _issueDateController.text = formatted;
      });
    }
  }

  void _submitCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a certificate file to upload.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    await Future.delayed(const Duration(milliseconds: 600));

    final isReupload = widget.existingCertificate != null;

    if (isReupload) {
      NptelService().reuploadCertificate(
        existingId: widget.existingCertificate!.id,
        courseName: _selectedCourseName,
        courseCode: _courseCodeController.text.trim(),
        semester: _selectedSemester,
        academicYear: _selectedAcademicYear,
        score: _scoreController.text.trim(),
        grade: _selectedGrade,
        certificateId: _certificateIdController.text.trim(),
        issueDate: _issueDateController.text.trim(),
        fileName: _selectedFileName!,
        fileSize: _selectedFileSize,
      );
    } else {
      final user = ref.read(currentUserProvider).value;
      final studentName = user?.fullName ?? user?.name ?? (user?.email.split('@').first ?? 'Student');
      final rollNo = (user?.metadata?['registerNumber'] ?? user?.metadata?['rollNo'] ?? user?.uid ?? '').toString();
      final department = user?.metadata?['department']?.toString() ?? user?.departmentName ?? user?.department ?? '';
      final studentUid = user?.uid;
      final departmentId = user?.metadata?['departmentId']?.toString();

      final newCert = NptelCertificateModel(
        id: 'NPTEL-${DateTime.now().millisecondsSinceEpoch}',
        studentName: studentName,
        rollNo: rollNo,
        department: department,
        studentUid: studentUid,
        departmentId: departmentId,
        courseName: _selectedCourseName,
        courseCode: _courseCodeController.text.trim(),
        semester: _selectedSemester,
        academicYear: _selectedAcademicYear,
        score: _scoreController.text.trim(),
        grade: _selectedGrade,
        certificateId: _certificateIdController.text.trim(),
        issueDate: _issueDateController.text.trim(),
        fileName: _selectedFileName!,
        fileSize: _selectedFileSize,
        uploadDate: DateTime.now(),
        status: 'Pending Verification',
      );
      NptelService().uploadCertificate(newCert);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isReupload
                      ? 'Certificate re-uploaded successfully! Status updated to Pending Verification.'
                      : 'Certificate uploaded successfully! Submitted for Faculty/HOD Review.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReupload = widget.existingCertificate != null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.card_membership_rounded, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReupload ? 'Re-upload NPTEL Certificate' : 'NPTEL Certificate Upload',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            'Submit course details for academic credit verification',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Course Name & Course Code
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Course Name'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCourseName,
                          isExpanded: true,
                          decoration: _inputDecoration('Select Course'),
                          items: _nptelCourses.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['name'],
                              child: Text(c['name']!, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: _onCourseChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Course Code'),
                        TextFormField(
                          controller: _courseCodeController,
                          decoration: _inputDecoration('e.g. NPTEL24CS01'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Semester & Academic Year
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Semester'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSemester,
                          decoration: _inputDecoration('Select Semester'),
                          items: _semesters.map((sem) {
                            return DropdownMenuItem<String>(
                              value: sem,
                              child: Text(sem),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSemester = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Academic Year'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAcademicYear,
                          decoration: _inputDecoration('Academic Year'),
                          items: _academicYears.map((ay) {
                            return DropdownMenuItem<String>(
                              value: ay,
                              child: Text(ay),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedAcademicYear = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Score & Grade
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Score'),
                        TextFormField(
                          controller: _scoreController,
                          decoration: _inputDecoration('e.g. 82%'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Grade'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGrade,
                          decoration: _inputDecoration('Select Grade'),
                          items: _grades.map((g) {
                            return DropdownMenuItem<String>(
                              value: g,
                              child: Text(g),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedGrade = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Certificate ID & Issue Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Certificate ID'),
                        TextFormField(
                          controller: _certificateIdController,
                          decoration: _inputDecoration('NPTEL-XXXXXX'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Issue Date'),
                        TextFormField(
                          controller: _issueDateController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: _inputDecoration('Select Date').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Certificate File Upload Area
              _buildFieldLabel('Certificate Document (PDF)'),
              InkWell(
                onTap: _pickRealFile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedFileName != null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                      style: BorderStyle.solid,
                      width: _selectedFileName != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedFileName != null
                              ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _selectedFileName != null ? Icons.picture_as_pdf_rounded : Icons.cloud_upload_outlined,
                          color: _selectedFileName != null ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName ?? 'No PDF file chosen',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedFileName != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              _selectedFileName != null ? _selectedFileSize : 'Tap to open File Manager (PDF format)',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickRealFile,
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: const Text('Browse File'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _submitCertificate,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      _isUploading
                          ? 'Uploading...'
                          : (isReupload ? 'Re-upload Certificate' : 'Upload Certificate'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
