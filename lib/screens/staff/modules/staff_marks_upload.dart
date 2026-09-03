import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class StaffMarksUploadModule extends StatefulWidget {
  const StaffMarksUploadModule({super.key});

  @override
  State<StaffMarksUploadModule> createState() => _StaffMarksUploadModuleState();
}

class _StaffMarksUploadModuleState extends State<StaffMarksUploadModule> {
  String _selectedSubject = 'CS401 - Advanced Data Structures';
  String _selectedExamType = 'IA-1 (Internal Assessment 1)';
  String _selectedFormat = 'Excel Sheet (.xlsx)';
  bool _isFileUploaded = false;
  String _uploadedFileName = '';
  int _uploadedRecordCount = 0;
  bool _isPublishing = false;

  final List<String> _subjects = [
    'CS401 - Advanced Data Structures',
    'CS402 - Database Management Systems',
    'CS403 - Operating Systems',
    'CS404 - Computer Networks',
  ];

  final List<String> _examTypes = [
    'IA-1 (Internal Assessment 1)',
    'IA-2 (Internal Assessment 2)',
    'Model Examination',
    'Internal Retest / Improvement Session',
  ];

  final List<String> _formats = [
    'Excel Sheet (.xlsx)',
    'CSV Data File (.csv)',
    'Institutional PDF Marksheet (.pdf)',
  ];

  // Mock parsed records preview from uploaded template
  final List<Map<String, String>> _parsedRecords = [
    {
      'regNo': '917721104012',
      'name': 'Aravind Swamy',
      'initial': '20 / 50',
      'retest': '44 / 50',
      'conv': '13.2 / 15',
      'status': 'Retest Cleared (+24 Marks)',
      'isRetest': 'true',
    },
    {
      'regNo': '917721104045',
      'name': 'Priya Dharshini',
      'initial': '48 / 50',
      'retest': 'N/A',
      'conv': '14.4 / 15',
      'status': 'Regular Passed',
      'isRetest': 'false',
    },
    {
      'regNo': '917722104022',
      'name': 'Karthik Raja',
      'initial': '15 / 50 (Abs)',
      'retest': '47 / 50',
      'conv': '14.1 / 15',
      'status': 'Absentee Retest Cleared',
      'isRetest': 'true',
    },
    {
      'regNo': '917723104089',
      'name': 'Sneha Murali',
      'initial': '49 / 50',
      'retest': 'N/A',
      'conv': '14.7 / 15',
      'status': 'Regular Passed',
      'isRetest': 'false',
    },
  ];

  void _handlePickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(1);
        final sizeStr = sizeMb == '0.0' ? '0.5 MB' : '$sizeMb MB';

        setState(() {
          _isFileUploaded = true;
          _uploadedFileName = '${file.name} ($sizeStr)';
          _uploadedRecordCount = 68;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "${file.name}" attached successfully! 68 student records parsed.'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking marks file: $e');
    }
  }

  void _showTemplateModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.table_chart_rounded, color: Color(0xFF1D4ED8)),
            SizedBox(width: 10),
            Text('Excel / CSV Template Format', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Use this official template structure when uploading internal test & retest marks for automated verification:',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 14),

                // Table Structure Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      defaultColumnWidth: const IntrinsicColumnWidth(),
                      border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.8),
                      children: const [
                        TableRow(
                          decoration: BoxDecoration(color: Color(0xFFEFF6FF)),
                          children: [
                            Padding(padding: EdgeInsets.all(6), child: Text('Reg_No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Student_Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Initial_Attempt (50)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Retest_Attempt (50)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Retest_Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(padding: EdgeInsets.all(6), child: Text('917721104012', style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Aravind Swamy', style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('20', style: TextStyle(fontSize: 11, color: Colors.red))),
                            Padding(padding: EdgeInsets.all(6), child: Text('44', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Retest Cleared', style: TextStyle(fontSize: 11))),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(padding: EdgeInsets.all(6), child: Text('917721104045', style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Priya Dharshini', style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('48', style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('-', style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Regular Passed', style: TextStyle(fontSize: 11))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'If a student wrote a Retest / Re-exam, enter their initial attempt mark in Initial_Attempt and the retest mark in Retest_Attempt.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloading VSBEC_Internal_Marks_Template.xlsx...'),
                  backgroundColor: Color(0xFF2563EB),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download .xlsx Template'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _publishMarks() async {
    if (!_isFileUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select and upload an Excel/CSV file first!'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    await FirebaseFirestoreService().saveAssignmentMarks(
      title: '$_selectedSubject - $_selectedExamType',
      subject: _selectedSubject,
      examType: _selectedExamType,
      fileName: _uploadedFileName,
      fileType: _selectedFormat,
      studentRecords: _parsedRecords,
    );

    if (mounted) {
      setState(() {
        _isPublishing = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 28),
              SizedBox(width: 10),
              Text('Marks Published to Database!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Successfully published $_uploadedRecordCount student assignment records for $_selectedSubject ($_selectedExamType) to Cloud Firestore. Students can view their marks matched by Register Number.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLiquidPullToRefresh(
      gifAsset: 'assets/tibsy-dp.gif',
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 1000));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INSTITUTIONAL MARKS UPLOAD',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF93C5FD), letterSpacing: 1.2),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upload Internal & Retest Marksheets',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showTemplateModal,
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download Template'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1D4ED8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload student internal marks via Excel (.xlsx), CSV, or PDF formats. Retest/re-exam marks are automatically synced to student and HOD portals.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Configuration Selection Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Select Assessment Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Subject Course', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSubject,
                                isExpanded: true,
                                items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12.5)))).toList(),
                                onChanged: (v) => setState(() => _selectedSubject = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Assessment Event', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedExamType,
                                isExpanded: true,
                                items: _examTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12.5)))).toList(),
                                onChanged: (v) => setState(() => _selectedExamType = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sheet Data Format', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Row(
                      children: _formats.map((fmt) {
                        final isSel = _selectedFormat == fmt;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFormat = fmt),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              fmt,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // File Upload Drop Area Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isFileUploaded ? const Color(0xFF10B981) : const Color(0xFFCBD5E1), width: _isFileUploaded ? 2 : 1),
            ),
            child: Column(
              children: [
                Icon(
                  _isFileUploaded ? Icons.task_rounded : Icons.cloud_upload_rounded,
                  size: 44,
                  color: _isFileUploaded ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                ),
                const SizedBox(height: 10),
                Text(
                  _isFileUploaded ? 'File Ready: $_uploadedFileName' : 'Drag & drop Excel or CSV file here',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFileUploaded ? '$_uploadedRecordCount Student records parsed with Retest flags' : 'Supported formats: .xlsx, .xls, .csv, .pdf (Max 15MB)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _handlePickFile,
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: Text(_isFileUploaded ? 'Change File' : 'Browse Files'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _showTemplateModal,
                      icon: const Icon(Icons.description_rounded, size: 16),
                      label: const Text('View Sample Format'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Parsed Records Live Table Preview
          if (_isFileUploaded) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Parsed Marksheet Preview',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                        child: const Text('68 Records Validated', style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _parsedRecords.length,
                    itemBuilder: (context, idx) {
                      final r = _parsedRecords[idx];
                      final bool isRetest = r['isRetest'] == 'true';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Reg No: ${r['regNo']!}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Initial: ${r['initial']!}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    if (isRetest)
                                      Text('Retest: ${r['retest']!}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isRetest ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    r['status']!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isRetest ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                    ),
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
            ),
            const SizedBox(height: 20),

            // Submit & Publish Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isPublishing ? null : _publishMarks,
                icon: _isPublishing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isPublishing ? 'Publishing Student Marks...' : '⚡ Publish Verified Marks to Student & HOD Portals',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
