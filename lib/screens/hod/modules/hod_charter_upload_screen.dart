import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/repositories/department_repository.dart';
import 'package:unisphere/widgets/common/department_vision_sheet.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class HodCharterUploadScreen extends ConsumerStatefulWidget {
  const HodCharterUploadScreen({super.key});

  @override
  ConsumerState<HodCharterUploadScreen> createState() => _HodCharterUploadScreenState();
}

class _HodCharterUploadScreenState extends ConsumerState<HodCharterUploadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasLoadedCharterFromRemote = false;

  // Controllers for Live Vision, Mission, PEOs & PSOs
  final TextEditingController _instVisionController = TextEditingController(
    text:
        'We endeavor to impart futuristic technical education of the highest quality to the student community and to inculcate discipline in them to face the world with self-confidence and thus we prepare them for life as responsible citizens to uphold human values and to be of service at large. We strive to bring up the Institution as an Institution of academic excellence of international standard.',
  );

  final TextEditingController _instMissionController = TextEditingController(
    text:
        'We transform persons into personalities by the state-of-the-art infrastructure, time consciousness, quick response and the best academic practices through assessment and advice.',
  );

  final TextEditingController _visionController = TextEditingController(
    text:
        'To emerge as a premier centre of excellence in Artificial Intelligence and Data Science by creating globally competent professionals, advancing impactful research, fostering innovation and entrepreneurship, and developing ethical, intelligent technologies for a sustainable and inclusive society.',
  );

  final List<TextEditingController> _missionControllers = [
    TextEditingController(
      text:
          'Provide world-class education through innovative pedagogy, outcome-based learning, and industry-aligned curricula in Artificial Intelligence and Data Science.',
    ),
    TextEditingController(
      text:
          'Promote interdisciplinary research, innovation, and lifelong learning to address global challenges through intelligent and data-driven solutions.',
    ),
    TextEditingController(
      text:
          'Collaborate with industries, research institutions, and professional bodies to enhance experiential learning, technology development, and employability.',
    ),
    TextEditingController(
      text:
          'Cultivate ethical leadership, entrepreneurial mindset, social responsibility, and professional excellence for sustainable technological advancement.',
    ),
  ];

  final List<TextEditingController> _peoControllers = [
    TextEditingController(
      text:
          'Graduates will excel as competent professionals by applying Artificial Intelligence, Data Science, and computational intelligence to develop innovative solutions for complex engineering, industrial, and societal problems.',
    ),
    TextEditingController(
      text:
          'Graduates will engage in lifelong learning, research, higher education, and technological innovation by adopting emerging AI technologies and contributing to knowledge creation and sustainable development.',
    ),
    TextEditingController(
      text:
          'Graduates will exhibit ethical values, leadership, entrepreneurial mindset, and effective communication while contributing to multidisciplinary teams and creating technology solutions with global impact.',
    ),
  ];

  final List<TextEditingController> _psoControllers = [
    TextEditingController(
      text:
          'Design, implement, and optimize intelligent systems using Artificial Intelligence, Machine Learning, Deep Learning, Natural Language Processing, and Computer Vision techniques to solve domain-specific challenges.',
    ),
    TextEditingController(
      text:
          'Apply advanced data engineering, analytics, visualization, and predictive modeling techniques using state-of-the-art industrial tools and AI frameworks to transform data into actionable intelligence for strategic decision-making.',
    ),
    TextEditingController(
      text:
          'Engineer scalable, reliable, secure, and ethical AI-enabled solutions by integrating cloud computing, edge intelligence, Generative AI, IoT, and MLOps while effectively managing multidisciplinary projects and adhering to professional and societal responsibilities.',
    ),
  ];

  // Uploaded Files List
  final List<Map<String, String>> _uploadedFiles = [
    {
      'name': 'AI_DS_Official_CO_PO_PSO_Specification_2026.pdf',
      'size': '2.4 MB',
      'date': 'Aug 12, 2026',
      'status': 'Active & Published',
    },
    {
      'name': 'Department_Vision_Mission_PEOs_Signed.pdf',
      'size': '1.1 MB',
      'date': 'Aug 10, 2026',
      'status': 'Archived',
    },
  ];

  // CO-PO Mapping Matrix (5 COs x 11 POs)
  final List<List<int>> _coPoMatrix = List.generate(
    5,
    (coIndex) => List.generate(11, (poIndex) => (coIndex + poIndex) % 3 + 1),
  );

  // PO-PSO Correlation Matrix (11 POs x 3 PSOs)
  final List<List<int>> _poPsoMatrix = [
    [3, 3, 2], // PO1
    [3, 3, 2], // PO2
    [3, 3, 3], // PO3
    [3, 3, 2], // PO4
    [3, 3, 3], // PO5
    [1, 2, 3], // PO6
    [2, 2, 3], // PO7
    [2, 2, 3], // PO8
    [2, 2, 3], // PO9
    [2, 3, 3], // PO10
    [3, 3, 3], // PO11
  ];

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _visionController.dispose();
    for (var c in _missionControllers) {
      c.dispose();
    }
    for (var c in _peoControllers) {
      c.dispose();
    }
    for (var c in _psoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      final file = result.files.first;
      setState(() {
        _isUploading = false;
        _uploadedFiles.insert(0, {
          'name': file.name,
          'size': '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB',
          'date': 'Just Now',
          'status': 'Active & Published',
        });
      });

      await _publishChanges();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${file.name}" uploaded successfully and published to all portals!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _populateFromRemote(Map<String, dynamic> remote) {
    if (_hasLoadedCharterFromRemote || remote.isEmpty) return;
    _hasLoadedCharterFromRemote = true;

    if (remote['instVision'] is String && (remote['instVision'] as String).isNotEmpty) {
      _instVisionController.text = remote['instVision'];
    }
    if (remote['instMission'] is String && (remote['instMission'] as String).isNotEmpty) {
      _instMissionController.text = remote['instMission'];
    }
    if (remote['vision'] is String && (remote['vision'] as String).isNotEmpty) {
      _visionController.text = remote['vision'];
    }
    if (remote['missions'] is List && (remote['missions'] as List).isNotEmpty) {
      final list = (remote['missions'] as List).map((e) => e.toString()).toList();
      _missionControllers.clear();
      for (final m in list) {
        _missionControllers.add(TextEditingController(text: m));
      }
    }
    if (remote['peos'] is List && (remote['peos'] as List).isNotEmpty) {
      final list = (remote['peos'] as List).map((e) => e.toString()).toList();
      _peoControllers.clear();
      for (final p in list) {
        _peoControllers.add(TextEditingController(text: p));
      }
    }
    if (remote['psos'] is List && (remote['psos'] as List).isNotEmpty) {
      final list = (remote['psos'] as List).map((e) => e.toString()).toList();
      _psoControllers.clear();
      for (final p in list) {
        _psoControllers.add(TextEditingController(text: p));
      }
    }
    if (remote['uploadedFiles'] is List && (remote['uploadedFiles'] as List).isNotEmpty) {
      _uploadedFiles.clear();
      for (final f in remote['uploadedFiles']) {
        if (f is Map) {
          _uploadedFiles.add(Map<String, String>.from(f.map((k, v) => MapEntry(k.toString(), v.toString()))));
        }
      }
    }
  }

  Future<void> _publishChanges() async {
    final deptId = ref.read(hodDepartmentIdProvider);
    final charterData = {
      'vision': _visionController.text.trim(),
      'instVision': _instVisionController.text.trim(),
      'instMission': _instMissionController.text.trim(),
      'missions': _missionControllers.map((c) => c.text.trim()).toList(),
      'peos': _peoControllers.map((c) => c.text.trim()).toList(),
      'psos': _psoControllers.map((c) => c.text.trim()).toList(),
      'coPoMatrix': _coPoMatrix,
      'poPsoMatrix': _poPsoMatrix,
      'uploadedFiles': _uploadedFiles,
      'updatedBy': 'HOD',
    };

    try {
      await ref.read(departmentRepositoryProvider).saveDepartmentCharter(deptId, charterData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Department CO/PO/PSO Charter published & synced live to Student, Staff & Parent portals!')),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving charter: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final charterAsync = ref.watch(hodDepartmentCharterStreamProvider);
    charterAsync.whenData((charter) {
      if (charter.isNotEmpty) {
        _populateFromRemote(charter);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('CO / PO / PSO Charter Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview_rounded, color: AppColors.hodRole),
            tooltip: 'Preview Live Student View',
            onPressed: () => showDepartmentVisionSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Top Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.upload_file_rounded, color: Color(0xFF7C3AED), size: 30),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOD Outcome Specification Portal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Upload official PDF documents, edit live Vision, Mission, PEOs, POs & PSOs, and manage CO-PO matrices.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 1),

          // Tab Navigation Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.hodRole,
              indicatorWeight: 3,
              labelColor: AppColors.hodRole,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'PDF Uploads'),
                Tab(text: 'Edit Vision & Outcomes'),
                Tab(text: 'CO-PO Matrix'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPdfUploadTab(),
                _buildEditContentTab(),
                _buildCoPoMatrixTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _publishChanges,
            icon: const Icon(Icons.rocket_launch_rounded, size: 20),
            label: const Text('Publish & Sync Live Outcomes to All Portals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hodRole,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab 1: PDF Document Uploads ──────────────────────
  Widget _buildPdfUploadTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Upload Action Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.hodRole.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.hodRole.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_rounded, color: AppColors.hodRole, size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'Upload Department Syllabus & Outcomes PDF',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload official HOD-signed PDF documents for AI & DS CO, PO, and PSO specifications.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              _isUploading
                  ? const CustomLoader(size: 36, label: 'Uploading & processing document...')
                  : ElevatedButton.icon(
                      onPressed: _pickAndUploadPdf,
                      icon: const Icon(Icons.file_upload_rounded, size: 18),
                      label: const Text('Select PDF / Word File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hodRole,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Uploaded Specification Documents',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),

        ..._uploadedFiles.map((doc) {
          final bool isActive = doc['status'] == 'Active & Published';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name']!,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${doc['size']} • Uploaded ${doc['date']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doc['status']!,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    setState(() {
                      _uploadedFiles.remove(doc);
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Tab 2: Edit Vision & Outcomes ──────────────────────
  Widget _buildEditContentTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Institute Vision & Mission Section
        _buildSectionTitle('Institute Vision & Mission'),
        const SizedBox(height: 8),
        TextField(
          controller: _instVisionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Vision of the Institute',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _instMissionController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Mission of the Institute',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        // Department Vision Section
        _buildSectionTitle('Department Vision'),
        const SizedBox(height: 8),
        TextField(
          controller: _visionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Vision of the Department',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        // Mission Section
        _buildSectionTitle('Department Mission (4 Pillars M1–M4)'),
        const SizedBox(height: 8),
        ...List.generate(_missionControllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _missionControllers[i],
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Mission M${i + 1}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // PEO Section
        _buildSectionTitle('Programme Educational Objectives (PEOs 1-3)'),
        const SizedBox(height: 8),
        ...List.generate(_peoControllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _peoControllers[i],
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'PEO ${i + 1}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // PSO Section
        _buildSectionTitle('Program Specific Outcomes (PSOs 1-3)'),
        const SizedBox(height: 8),
        ...List.generate(_psoControllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _psoControllers[i],
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'PSO ${i + 1}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Tab 3: CO-PO & PO-PSO Mapping Matrix ──────────────────────
  Widget _buildCoPoMatrixTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DataTable(
              columnSpacing: 16,
              columns: [
                const DataColumn(label: Text('COs', style: TextStyle(fontWeight: FontWeight.bold))),
                ...List.generate(11, (i) => DataColumn(label: Text('PO${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)))),
              ],
              rows: List.generate(5, (coIdx) {
                return DataRow(
                  cells: [
                    DataCell(Text('CO ${coIdx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.hodRole))),
                    ...List.generate(11, (poIdx) {
                      final val = _coPoMatrix[coIdx][poIdx];
                      return DataCell(
                        DropdownButton<int>(
                          value: val,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 (Low)')),
                            DropdownMenuItem(value: 2, child: Text('2 (Med)')),
                            DropdownMenuItem(value: 3, child: Text('3 (High)')),
                          ],
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setState(() {
                                _coPoMatrix[coIdx][poIdx] = newVal;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ],
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Program Outcomes', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('PSO 1 (AI Systems)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('PSO 2 (Analytics)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('PSO 3 (Intell. MLOps)', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(11, (poIdx) {
                return DataRow(
                  cells: [
                    DataCell(Text('PO ${poIdx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.hodRole))),
                    ...List.generate(3, (psoIdx) {
                      final val = _poPsoMatrix[poIdx][psoIdx];
                      return DataCell(
                        DropdownButton<int>(
                          value: val,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 (Low)')),
                            DropdownMenuItem(value: 2, child: Text('2 (Med)')),
                            DropdownMenuItem(value: 3, child: Text('3 (High)')),
                          ],
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setState(() {
                                _poPsoMatrix[poIdx][psoIdx] = newVal;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ],
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    );
  }
}
