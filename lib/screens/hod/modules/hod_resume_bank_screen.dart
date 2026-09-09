import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/models/student_resume_model.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/services/resume_service.dart';
import 'package:unisphere/widgets/resume/resume_document_view.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class HodResumeBankScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const HodResumeBankScreen({super.key, this.onBack});

  @override
  ConsumerState<HodResumeBankScreen> createState() => _HodResumeBankScreenState();
}

class _HodResumeBankScreenState extends ConsumerState<HodResumeBankScreen> {
  String _searchQuery = '';
  String _selectedYear = 'All';
  String _selectedSection = 'All';
  String _selectedCompleteness = 'All';

  void _openResumeModal(String studentId, String studentName) {
    final resumeFuture = ref.read(resumeServiceProvider).generateResumeForStudent(studentId);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 900,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<StudentResumeModel?>(
            future: resumeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Loader(label: 'Generating high-fidelity resume...'));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Unable to load resume.'));
              }

              final resume = snapshot.data!;

              return Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'HOD Resume Inspection: ${resume.header.fullName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Expanded(
                    child: ResumeDocumentView(
                      resume: resume,
                      showControls: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbStudents = ref.watch(allStudentsStreamProvider).value ?? [];
    final deptStudents = dbStudents.map((u) {
      final meta = u.metadata ?? {};
      return {
        'id': u.uid,
        'regNo': (meta['registerNumber'] ?? meta['regNo'] ?? u.uid).toString(),
        'name': u.fullName.isNotEmpty
            ? u.fullName
            : (u.name.isNotEmpty
                ? u.name
                : (u.email.contains('@') ? u.email.split('@').first : 'Student')),
        'year': meta['year'] ?? (meta['semester'] ?? '1st Year'),
        'section': meta['section'] ?? 'Sec A',
        'cgpa': meta['cgpa']?.toString() ?? '0.0',
        'attendance': meta['attendance'] != null ? '${meta['attendance']}%' : '-',
        'completeness': meta['resumeCompleteness'] is int ? meta['resumeCompleteness'] as int : 50,
        'topSkills': (meta['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>['Academic Student'],
        'certsCount': 0,
        'projectsCount': 0,
        'photo': u.profileImageUrl ?? meta['photoUrl'] ?? '',
      };
    }).toList();

    final filtered = deptStudents.where((s) {
      final matchesSearch = s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['regNo'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s['topSkills'] as List).any((sk) => sk.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesYear = _selectedYear == 'All' || s['year'] == _selectedYear;
      final matchesSection = _selectedSection == 'All' || s['section'] == _selectedSection;
      
      final int compScore = (s['completeness'] as num?)?.toInt() ?? 0;
      bool matchesComp = true;
      if (_selectedCompleteness == 'Ready') {
        matchesComp = compScore >= 90;
      } else if (_selectedCompleteness == 'Needs Work') {
        matchesComp = compScore < 75;
      }

      return matchesSearch && matchesYear && matchesSection && matchesComp;
    }).toList();

    final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final deptName = (dept?.name != null && dept!.name.isNotEmpty && dept.name != 'Computer Science & Engineering')
        ? dept.name
        : (currentUser?.departmentName ??
            currentUser?.department ??
            currentUser?.metadata?['departmentName']?.toString() ??
            currentUser?.metadata?['department']?.toString() ??
            dept?.name ??
            'Department');

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
              child: const Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Dept. Resume Bank',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$deptName • Placement Roster',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating departmental placement resume roster export...'),
                    backgroundColor: Color(0xFF2563EB),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 14),
              label: const Text('Export', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Department Analytics Cards
            _buildDepartmentAnalyticsRow(),

            const SizedBox(height: 20),

            // Search & Filter Bar
            _buildFilterBar(),

            const SizedBox(height: 16),

            // Student Roster Grid / List
            Text(
              'STUDENT RESUME DIRECTORY (${filtered.length} Students)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 175,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final s = filtered[idx];
                    return _buildStudentCard(s);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentAnalyticsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildAnalyticsPill('Total Students', '480', Icons.people_alt_rounded, const Color(0xFF2563EB), isWide),
            _buildAnalyticsPill('Resumes Synced', '100%', Icons.sync_rounded, const Color(0xFF10B981), isWide),
            _buildAnalyticsPill('Avg. Completeness', '88%', Icons.insights_rounded, const Color(0xFF7C3AED), isWide),
            _buildAnalyticsPill('Verified Certs', '342', Icons.workspace_premium_rounded, const Color(0xFFD97706), isWide),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsPill(String title, String value, IconData icon, Color color, bool isWide) {
    return Container(
      width: isWide ? 210 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by student name, reg number, or tech skill (e.g. Flutter, Python)...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Academic Years')),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSection,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
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
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCompleteness,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Completeness Levels')),
                        DropdownMenuItem(value: 'Ready', child: Text('Recruiter Ready (>=90%)')),
                        DropdownMenuItem(value: 'Needs Work', child: Text('Needs Enhancement (<75%)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCompleteness = val);
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

  Widget _buildStudentCard(Map<String, dynamic> s) {
    final int completeness = s['completeness'] ?? 80;
    Color compColor = completeness >= 90 ? const Color(0xFF10B981) : (completeness >= 75 ? const Color(0xFF2563EB) : const Color(0xFFD97706));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(s['photo']),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name'],
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${s['regNo']} • ${s['year']} (${s['section']})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: compColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: compColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$completeness% Complete',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: compColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: (s['topSkills'] as List<String>).map((sk) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sk,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CGPA: ${s['cgpa']} • ${s['projectsCount']} Projects • ${s['certsCount']} Certs',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
              ),
              ElevatedButton.icon(
                onPressed: () => _openResumeModal(s['id'], s['name']),
                icon: const Icon(Icons.visibility_rounded, size: 12),
                label: const Text('Inspect Resume', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
