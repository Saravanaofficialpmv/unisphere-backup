import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/syllabus_model.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/screens/student/modules/subject_details_screen.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/syllabus_service.dart';

class HodSyllabusManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const HodSyllabusManagementScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<HodSyllabusManagementScreen> createState() => _HodSyllabusManagementScreenState();
}

class _HodSyllabusManagementScreenState extends ConsumerState<HodSyllabusManagementScreen> {
  final SyllabusService _syllabusService = SyllabusService();
  final TextEditingController _searchController = TextEditingController();

  String _department = 'Computer Science & Engineering';
  String _selectedAcademicYear = '2026–2027';
  String _selectedYear = 'I Year';
  String _selectedSemester = 'Semester 1';
  String _selectedTypeFilter = 'All';

  bool _isLoading = true;
  List<SyllabusSubjectModel> _allDepartmentSyllabi = [];

  final List<String> _academicYearsList = ['2026–2027', '2025–2026', '2027–2028', '2024–2025'];
  final List<String> _availableYears = ['I Year', 'II Year', 'III Year', 'IV Year'];

  List<String> _getAvailableSemesters(String year) {
    switch (year) {
      case 'I Year':
        return ['Semester 1', 'Semester 2'];
      case 'II Year':
        return ['Semester 3', 'Semester 4'];
      case 'III Year':
        return ['Semester 5', 'Semester 6'];
      case 'IV Year':
        return ['Semester 7', 'Semester 8'];
      default:
        return ['Semester 1', 'Semester 2'];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDepartmentAndSyllabi();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDepartmentAndSyllabi() {
    final dept = ref.read(currentHodDepartmentProvider).valueOrNull;
    final user = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    final meta = user?.metadata ?? {};
    final deptVal = (dept?.name != null && dept!.name.isNotEmpty && dept.name != 'Computer Science & Engineering')
        ? dept.name
        : (user?.departmentName ??
            user?.department ??
            meta['department']?.toString() ??
            meta['dept']?.toString() ??
            meta['departmentName']?.toString() ??
            dept?.name ??
            'Department');
    _department = deptVal;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await _syllabusService.getHODAllSyllabi(department: _department);
    if (mounted) {
      setState(() {
        _allDepartmentSyllabi = results;
        _isLoading = false;
      });
    }
  }

  List<SyllabusSubjectModel> get _filteredSubjects {
    final query = _searchController.text.trim().toLowerCase();
    return _allDepartmentSyllabi.where((s) {
      // 1. Academic Year filter
      if (s.academicYear != _selectedAcademicYear && s.effectiveStartYear != SyllabusService.parseStartYear(_selectedAcademicYear)) {
        return false;
      }

      // 2. Year filter
      if (_normalizeYear(s.year) != _normalizeYear(_selectedYear)) return false;

      // 3. Semester filter
      if (_normalizeSemester(s.semester) != _normalizeSemester(_selectedSemester)) return false;

      // 4. Type filter
      if (_selectedTypeFilter == 'Drafts Only' && s.isPublished) return false;
      if (_selectedTypeFilter == 'Published Only' && !s.isPublished) return false;
      if (_selectedTypeFilter != 'All' && _selectedTypeFilter != 'Drafts Only' && _selectedTypeFilter != 'Published Only') {
        if (s.subjectType.toLowerCase() != _selectedTypeFilter.toLowerCase()) return false;
      }

      // 5. Search query
      if (query.isNotEmpty) {
        final nameMatch = s.subjectName.toLowerCase().contains(query);
        final codeMatch = s.subjectCode.toLowerCase().contains(query);
        if (!nameMatch && !codeMatch) return false;
      }

      return true;
    }).toList();
  }

  String _normalizeYear(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('2nd') || s.contains('ii year') || s.contains('2') || s == 'ii') return 'II Year';
    if (s.contains('3rd') || s.contains('iii year') || s.contains('3') || s == 'iii') return 'III Year';
    if (s.contains('4th') || s.contains('iv year') || s.contains('4') || s == 'iv') return 'IV Year';
    return 'I Year';
  }

  String _normalizeSemester(String rawSem) {
    final numMatch = RegExp(r'\d+').firstMatch(rawSem);
    if (numMatch != null) {
      return 'Semester ${numMatch.group(0)}';
    }
    return 'Semester 1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Syllabus Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('Curriculum Control & Publishing Engine', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Syllabi',
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Delete All Syllabus Data',
            onPressed: _handleDeleteAllSyllabi,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDepartmentHeaderBanner(),
                  const SizedBox(height: 16),
                  _buildControlsCard(),
                  const SizedBox(height: 16),
                  _buildActionBar(),
                  const SizedBox(height: 16),
                  _buildSubjectsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildDepartmentHeaderBanner() {
    final totalCount = _allDepartmentSyllabi.length;
    final publishedCount = _allDepartmentSyllabi.where((s) => s.isPublished).length;
    final draftCount = totalCount - publishedCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('HOD / ADMIN CONTROL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_selectedAcademicYear, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _department,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create, edit, publish, and manage academic syllabus curriculum and attached PDF documents.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHeaderStatChip('Total Subjects', '$totalCount', Icons.library_books_rounded, Colors.white70),
                const SizedBox(width: 12),
                _buildHeaderStatChip('Published', '$publishedCount', Icons.check_circle_rounded, const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _buildHeaderStatChip('Drafts', '$draftCount', Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildControlsCard() {
    final sems = _getAvailableSemesters(_selectedYear);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Select Academic Hierarchy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const Spacer(),
              // Academic Year Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAcademicYear,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    items: _academicYearsList.map((y) {
                      return DropdownMenuItem(value: y, child: Text(y));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedAcademicYear = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Academic Year:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableYears.map((yr) {
                final isSelected = yr == _selectedYear;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(yr),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedYear = yr;
                          final newSems = _getAvailableSemesters(yr);
                          if (!newSems.contains(_selectedSemester)) {
                            _selectedSemester = newSems.first;
                          }
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Semester:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sems.map((sem) {
                final isSelected = sem == _selectedSemester;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(sem),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedSemester = sem);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search subjects (e.g. CS101, C Prog...)',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text('Add Subject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showAddEditSubjectModal(),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Color(0xFFEF4444)),
              label: const Text('Delete All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _handleDeleteAllSyllabi,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Theory', 'Practical', 'Elective', 'Published Only', 'Drafts Only'].map((filter) {
              final isSelected = _selectedTypeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEFF6FF),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedTypeFilter = filter);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsList() {
    final subjects = _filteredSubjects;

    if (subjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            const Text(
              'No Syllabus Subjects Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'There are no subject syllabus records matching $_selectedAcademicYear · $_selectedYear · $_selectedSemester.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text('Add Subject Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showAddEditSubjectModal(),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _buildHodSubjectCard(subject);
      },
    );
  }

  Widget _buildHodSubjectCard(SyllabusSubjectModel subject) {
    final isPublished = subject.isPublished;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isPublished ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Code, Type, Credits, Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subject.subjectCode,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subject.subjectType,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${subject.credits} Credits',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                ),
                const Spacer(),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPublished ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isPublished ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPublished ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                        size: 12,
                        color: isPublished ? const Color(0xFF047857) : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPublished ? 'PUBLISHED' : 'DRAFT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPublished ? const Color(0xFF047857) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subject.subjectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              '${subject.subjectCode} · ${subject.subjectType} · ${subject.credits} Credits (${subject.year} · ${subject.semester})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            if (subject.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subject.description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              children: [
                // View Document Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 15, color: Color(0xFFDC2626)),
                  label: const Text('View Doc', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SubjectDetailsScreen(subject: subject),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Edit Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF2563EB)),
                  label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showAddEditSubjectModal(subject),
                ),
                const Spacer(),
                // Publish / Unpublish Button
                ElevatedButton.icon(
                  icon: Icon(isPublished ? Icons.unpublished_rounded : Icons.publish_rounded, size: 14, color: Colors.white),
                  label: Text(isPublished ? 'Unpublish' : 'Publish', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPublished ? const Color(0xFF64748B) : const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleTogglePublishStatus(subject),
                ),
                const SizedBox(width: 6),
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  tooltip: 'Delete Subject',
                  onPressed: () => _handleDeleteSubject(subject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTogglePublishStatus(SyllabusSubjectModel subject) async {
    final newStatus = subject.isPublished ? 'draft' : 'published';
    final ok = await _syllabusService.updateSubjectStatus(subject.id, newStatus);
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'published' ? 'Syllabus "${subject.subjectName}" published successfully!' : 'Syllabus changed to Draft.'),
            backgroundColor: newStatus == 'published' ? const Color(0xFF10B981) : const Color(0xFF475569),
          ),
        );
      }
      _fetchData();
    }
  }

  Future<void> _handleDeleteSubject(SyllabusSubjectModel subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Confirm Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to delete "${subject.subjectName}" (${subject.subjectCode})? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _syllabusService.deleteSubject(subject.id);
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${subject.subjectName}" successfully.'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
        _fetchData();
      }
    }
  }

  Future<void> _handleDeleteAllSyllabi() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete ALL Syllabus Data?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ALL syllabus records for "$_department"?',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warning: This action will permanently erase all published and draft subjects from Firestore.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.white),
            label: const Text('Delete All Data', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final ok = await _syllabusService.deleteAllSyllabi(department: _department);
      if (mounted) {
        setState(() {
          _allDepartmentSyllabi = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ok ? 'All syllabus data for $_department has been deleted.' : 'Failed to delete syllabus data. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: ok ? const Color(0xFFDC2626) : const Color(0xFFB45309),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showAddEditSubjectModal([SyllabusSubjectModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return AddEditSubjectModal(
          existing: existing,
          defaultAcademicYear: _selectedAcademicYear,
          defaultYear: _selectedYear,
          defaultSemester: _selectedSemester,
          department: _department,
          onSaved: _fetchData,
        );
      },
    );
  }
}

class AddEditSubjectModal extends StatefulWidget {
  final SyllabusSubjectModel? existing;
  final String defaultAcademicYear;
  final String defaultYear;
  final String defaultSemester;
  final String department;
  final VoidCallback onSaved;

  const AddEditSubjectModal({
    super.key,
    this.existing,
    required this.defaultAcademicYear,
    required this.defaultYear,
    required this.defaultSemester,
    required this.department,
    required this.onSaved,
  });

  @override
  State<AddEditSubjectModal> createState() => _AddEditSubjectModalState();
}

class _AddEditSubjectModalState extends State<AddEditSubjectModal> {
  final _formKey = GlobalKey<FormState>();
  final SyllabusService _syllabusService = SyllabusService();

  late String _academicYear;
  late String _year;
  late String _semester;
  late String _department;

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _creditsController;
  late TextEditingController _documentUrlController;
  late TextEditingController _docNameController;

  String _subjectType = 'Theory';
  bool _isSubmitting = false;
  String? _duplicateError;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;

    _academicYear = ex?.academicYear ?? widget.defaultAcademicYear;
    _year = ex?.year ?? widget.defaultYear;
    _semester = ex?.semester ?? widget.defaultSemester;
    _department = ex?.department ?? widget.department;

    _codeController = TextEditingController(text: ex?.subjectCode ?? '');
    _nameController = TextEditingController(text: ex?.subjectName ?? '');
    _descriptionController = TextEditingController(text: ex?.description ?? '');
    _creditsController = TextEditingController(text: (ex?.credits ?? 4).toString());
    _documentUrlController = TextEditingController(
      text: ex?.documentUrl.isNotEmpty == true ? ex!.documentUrl : 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    );
    _docNameController = TextEditingController(text: ex?.documentFileName ?? 'syllabus_document.pdf');

    _subjectType = ex?.subjectType ?? 'Theory';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    _documentUrlController.dispose();
    _docNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(String targetStatus) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _duplicateError = null;
    });

    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final credits = int.tryParse(_creditsController.text.trim()) ?? 4;
    final desc = _descriptionController.text.trim();
    final docUrl = _documentUrlController.text.trim();
    final docName = _docNameController.text.trim();

    // Check duplicate code within same academic year & semester
    final isDup = await _syllabusService.isDuplicateSubjectCode(
      subjectCode: code,
      academicYear: _academicYear,
      semester: _semester,
      department: _department,
      currentId: widget.existing?.id,
    );

    if (isDup) {
      setState(() {
        _isSubmitting = false;
        _duplicateError = 'Subject Code "$code" already exists in $_academicYear · $_semester!';
      });
      return;
    }

    final newSubject = SyllabusSubjectModel(
      id: widget.existing?.id ?? '',
      subjectCode: code,
      subjectName: name,
      department: _department,
      applicableBatch: '2026–2030',
      year: _year,
      semester: _semester,
      academicYear: _academicYear,
      effectiveStartYear: SyllabusService.parseStartYear(_academicYear),
      credits: credits,
      subjectType: _subjectType,
      description: desc,
      units: widget.existing?.units ?? [],
      textbooks: widget.existing?.textbooks ?? ['Standard University Textbook'],
      referenceBooks: widget.existing?.referenceBooks ?? ['Reference Guide'],
      documentUrl: docUrl,
      documentFileName: docName.isNotEmpty ? docName : '${code}_syllabus.pdf',
      documentSize: '1.8 MB',
      lastUpdated: DateTime.now(),
      status: targetStatus,
      uploadedBy: 'HOD / Department Admin',
    );

    bool success = false;
    if (widget.existing != null) {
      success = await _syllabusService.updateSubject(newSubject);
    } else {
      success = await _syllabusService.createSubject(newSubject);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null ? 'Subject "$name" updated successfully!' : 'Subject "$name" created successfully!'),
            backgroundColor: targetStatus == 'published' ? const Color(0xFF10B981) : const Color(0xFF475569),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(isEdit ? Icons.edit_note_rounded : Icons.library_add_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Subject Syllabus' : 'Add New Subject Syllabus',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 14),

              if (_duplicateError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEF4444))),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_duplicateError!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Dropdown Row: Academic Year & Year
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _academicYear,
                      decoration: InputDecoration(
                        labelText: 'Academic Year',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ['2026–2027', '2025–2026', '2027–2028', '2024–2025'].map((y) {
                        return DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setState(() => _academicYear = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _year,
                      decoration: InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ['I Year', 'II Year', 'III Year', 'IV Year'].map((y) {
                        return DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setState(() => _year = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dropdown Row: Semester & Type
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _semester,
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setState(() => _semester = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _subjectType,
                      decoration: InputDecoration(
                        labelText: 'Subject Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ['Theory', 'Practical', 'Elective', 'Other'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setState(() => _subjectType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject Code & Name
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Code *',
                        hintText: 'CS101',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Subject Name *',
                        hintText: 'Programming in C',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Credits & Document File Name
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _creditsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Credits *',
                        hintText: '4',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _docNameController,
                      decoration: InputDecoration(
                        labelText: 'PDF Document File Name',
                        hintText: 'CS101_syllabus.pdf',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Document URL Input
              TextFormField(
                controller: _documentUrlController,
                decoration: InputDecoration(
                  labelText: 'Syllabus PDF Document URL',
                  hintText: 'https://...',
                  prefixIcon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Subject Description (Optional)',
                  hintText: 'Covers core principles, algorithms, and practical implementations...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Save Draft & Save & Publish
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.drafts_rounded, size: 18),
                      label: const Text('Save as Draft'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : () => _submitForm('draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.publish_rounded, size: 18, color: Colors.white),
                      label: const Text('Publish Syllabus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : () => _submitForm('published'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
