import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/student_resume_model.dart';
import 'package:unisphere/services/resume_service.dart';
import 'package:unisphere/widgets/resume/resume_completeness_card.dart';
import 'package:unisphere/widgets/resume/resume_document_view.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';
import 'package:unisphere/widgets/common/app_liquid_pull_to_refresh.dart';

class AdviserResumeBankScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const AdviserResumeBankScreen({super.key, this.onBack});

  @override
  ConsumerState<AdviserResumeBankScreen> createState() => _AdviserResumeBankScreenState();
}

class _AdviserResumeBankScreenState extends ConsumerState<AdviserResumeBankScreen> {
  String _searchQuery = '';
  String _selectedYear = 'All';
  String _selectedSection = 'All';
  String _selectedStudentId = 'DEMO-STU';
  StudentResumeModel? _activeResume;
  bool _isLoadingResume = false;
  bool _showSidePanel = true;

  // Assigned student roster
  final List<Map<String, dynamic>> _assignedStudents = [
    {
      'id': 'DEMO-STU',
      'regNo': 'RA2111003010001',
      'name': 'Alex Johnson',
      'year': '3rd Year',
      'section': 'Sec B',
      'dept': 'Computer Science & Engineering',
      'cgpa': '8.92',
      'attendance': '88.5%',
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    },
    {
      'id': '917721104012',
      'regNo': '917721104012',
      'name': 'Aravind Swamy',
      'year': '3rd Year',
      'section': 'Sec A',
      'dept': 'Computer Science & Engineering',
      'cgpa': '9.12',
      'attendance': '96.5%',
      'photo': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
    },
    {
      'id': '917721104045',
      'regNo': '917721104045',
      'name': 'Priya Dharshini',
      'year': '3rd Year',
      'section': 'Sec A',
      'dept': 'Computer Science & Engineering',
      'cgpa': '8.85',
      'attendance': '92.0%',
      'photo': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    },
    {
      'id': '917722104022',
      'regNo': '917722104022',
      'name': 'Karthik Raja',
      'year': '2nd Year',
      'section': 'Sec B',
      'dept': 'Computer Science & Engineering',
      'cgpa': '7.45',
      'attendance': '71.5%',
      'photo': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    },
    {
      'id': '917723104089',
      'regNo': '917723104089',
      'name': 'Sneha Murali',
      'year': '1st Year',
      'section': 'Sec C',
      'dept': 'Computer Science & Engineering',
      'cgpa': '9.50',
      'attendance': '98.0%',
      'photo': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStudentResume(_selectedStudentId);
  }

  Future<void> _loadStudentResume(String studentId) async {
    setState(() {
      _selectedStudentId = studentId;
      _isLoadingResume = true;
    });

    final resumeService = ref.read(resumeServiceProvider);
    final res = await resumeService.generateResumeForStudent(studentId);

    if (mounted) {
      setState(() {
        _activeResume = res;
        _isLoadingResume = false;
      });
    }
  }

  void _sendAdvisorNotification(String studentName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resume completion advisory notification sent to $studentName.'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    final filteredStudents = _assignedStudents.where((s) {
      final nameMatches = s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['regNo'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final yearMatches = _selectedYear == 'All' || s['year'] == _selectedYear;
      final secMatches = _selectedSection == 'All' || s['section'] == _selectedSection;
      return nameMatches && yearMatches && secMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
                onPressed: widget.onBack,
              )
            : null,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Class Adviser Resume Bank',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Review assigned student resumes & readiness',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showSidePanel ? Icons.view_sidebar_rounded : Icons.view_sidebar_outlined, color: const Color(0xFF2563EB)),
            tooltip: 'Toggle Advisory Insights Panel',
            onPressed: () => setState(() => _showSidePanel = !_showSidePanel),
          ),
        ],
      ),
      body: AppLiquidPullToRefresh(
        gifAsset: 'assets/tibsy-dp.gif',
        onRefresh: () async {
          ref.invalidate(resumeServiceProvider);
          await _loadStudentResume(_selectedStudentId);
        },
        child: isDesktop ? _buildDesktopLayout(filteredStudents) : _buildMobileLayout(filteredStudents),
      ),
    );
  }

  Widget _buildDesktopLayout(List<Map<String, dynamic>> students) {
    return Row(
      children: [
        // Left Panel: Student Roster & Filters (Width 320px)
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              _buildRosterFilterHeader(),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, idx) {
                    final s = students[idx];
                    final isSelected = s['id'] == _selectedStudentId || s['regNo'] == _selectedStudentId;
                    return _buildStudentRosterTile(s, isSelected);
                  },
                ),
              ),
            ],
          ),
        ),

        // Main Panel: A4 Resume Preview
        Expanded(
          child: _isLoadingResume
              ? const Center(child: Loader(label: 'Fetching student resume records...'))
              : _activeResume == null
                  ? const Center(child: Text('Select a student to inspect resume.'))
                  : Column(
                      children: [
                        _buildAdvisoryNoticeBanner(),
                        Expanded(
                          child: ResumeDocumentView(
                            resume: _activeResume!,
                            showControls: true,
                          ),
                        ),
                      ],
                    ),
        ),

        // Right Panel: Advisory Insights & Completeness Analysis (Width 310px)
        if (_showSidePanel && _activeResume != null)
          Container(
            width: 310,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADVISORY INSIGHTS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  ResumeCompletenessCard(
                    completeness: _activeResume!.completeness,
                    isCompact: false,
                  ),
                  const SizedBox(height: 16),
                  _buildMissingRecommendationsSection(),
                  const SizedBox(height: 16),
                  _buildAdviserActionButtons(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout(List<Map<String, dynamic>> students) {
    return Column(
      children: [
        _buildRosterFilterHeader(),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: students.length,
            itemBuilder: (context, idx) {
              final s = students[idx];
              final isSelected = s['id'] == _selectedStudentId;
              return GestureDetector(
                onTap: () => _loadStudentResume(s['id']),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(s['photo']),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${s['year']} • ${s['section']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoadingResume
              ? const Center(child: Loader(label: 'Loading resume...'))
              : _activeResume == null
                  ? const Center(child: Text('No student selected.'))
                  : ResumeDocumentView(
                      resume: _activeResume!,
                      showControls: true,
                    ),
        ),
      ],
    );
  }

  Widget _buildRosterFilterHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search student or reg no...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Years')),
                        DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
                        DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
                        DropdownMenuItem(value: '3rd Year', child: Text('3rd Year')),
                        DropdownMenuItem(value: '4th Year', child: Text('4th Year')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSection,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Sections')),
                        DropdownMenuItem(value: 'Sec A', child: Text('Sec A')),
                        DropdownMenuItem(value: 'Sec B', child: Text('Sec B')),
                        DropdownMenuItem(value: 'Sec C', child: Text('Sec C')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSection = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRosterTile(Map<String, dynamic> s, bool isSelected) {
    return Container(
      color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
      child: ListTile(
        onTap: () => _loadStudentResume(s['id']),
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(s['photo']),
        ),
        title: Text(
          s['name'],
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          '${s['regNo']} • ${s['year']} (${s['section']})',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Text(
            'CGPA ${s['cgpa']}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisoryNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFFFBEB),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Adviser View Mode: Content is synchronized directly with primary college databases. Modifications must be initiated by student via Profile / Projects / Certifications.',
              style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => _sendAdvisorNotification(_activeResume?.header.fullName ?? 'Student'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Send Guidance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingRecommendationsSection() {
    final missing = _activeResume!.completeness.missingRecommended;

    return Container(
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
              Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Text(
                'Improvement Opportunities',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (missing.isEmpty)
            const Text(
              'Student profile is 100% complete with all recommendations satisfied.',
              style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
            )
          else
            ...missing.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          m.title,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildAdviserActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _sendAdvisorNotification(_activeResume?.header.fullName ?? 'Student'),
            icon: const Icon(Icons.send_rounded, size: 14),
            label: const Text('Send Optimization Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
