import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/academic_record_model.dart';
import 'package:unisphere/providers/academic_record_provider.dart';
import 'package:unisphere/providers/gradebook_provider.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';

class GradebookScreen extends ConsumerStatefulWidget {
  final bool initialShowPlanner;
  final VoidCallback? onBack;

  const GradebookScreen({
    super.key,
    this.initialShowPlanner = false,
    this.onBack,
  });

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  int _selectedSemIndex = 3; // Default Sem 4
  String _selectedInternalFilter = 'All'; // 'All', 'IA-1', 'IA-2', 'Model'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final initialIdx = ref.read(gradebookProvider).selectedSemesterIndex;
    if (initialIdx >= 0) {
      _selectedSemIndex = initialIdx;
    }
    if (widget.initialShowPlanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCgpaCalculatorModal(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (!mounted) return;
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/student');
    }
  }

  void _showCgpaCalculatorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CgpaCalculatorModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool canPopRoute = ModalRoute.of(context)?.canPop ?? false;

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !mounted) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInternalMarksTab(),
                    _buildUniversityResultsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return UnisphereHeaderCard(
      title: 'Academic Marks & Results',
      subtitle: 'Internal Assessment & Official COE University Results',
      onBack: () => _handleBack(context),
      rightActions: [
        // Mini CGPA Calculator Button
        GestureDetector(
          onTap: () => _showCgpaCalculatorModal(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calculate_rounded, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'CGPA Calc',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
      bottomWidget: _buildSegmentedTabBar(),
    );
  }

  Widget _buildSegmentedTabBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: TabBar(
        controller: _tabController,
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
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_rounded, size: 15),
                SizedBox(width: 5),
                Text('Internal Marks'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, size: 15),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'University Results',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInternalMarksEmptyState(String semName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(
              Icons.assignment_late_outlined,
              size: 36,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Academic Records Unavailable for $semName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Subject faculty members have not yet uploaded or finalized internal assessment marks (IA-1, IA-2, Model Exam) for this semester.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1: INTERNAL MARKS (Live Stream from Cloud Firestore)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildInternalMarksTab() {
    final gradebookState = ref.watch(gradebookProvider);
    final currentSem = gradebookState.currentSemester;
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final activeRegNo = currentUser?.metadata?['registerNumber']?.toString().trim() ?? '';
    final studentId = activeRegNo.isNotEmpty ? activeRegNo : (currentUser?.uid ?? '');

    final recordsAsync = studentId.isNotEmpty
        ? ref.watch(studentAcademicRecordsStreamProvider(studentId))
        : ref.watch(currentStudentAcademicRecordsStreamProvider);

    final String selectedSemTitle = currentSem?.name ?? 'Semester ${_selectedSemIndex + 1}';
    final int currentSelectedSemNumber = _selectedSemIndex + 1;

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Faculty Portal Info Banner with Live Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                    child: const Icon(Icons.verified_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'FACULTY UPLOADED INTERNAL MARKS',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF), letterSpacing: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text('LIVE', style: TextStyle(color: Color(0xFF059669), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Internal marks are evaluated & uploaded directly by subject faculty in Cloud Firestore.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Semester Selector Pills
            _buildSemesterPills(gradebookState.semesters),
            const SizedBox(height: 16),

            // Term Status Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFF60A5FA), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$selectedSemTitle INTERNAL MARKS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _selectedSemIndex == 3 ? const Color(0xFF2563EB) : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedSemIndex == 3 ? 'Active Term' : (_selectedSemIndex < 3 ? 'Completed Term' : 'Term $_selectedSemIndex'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            recordsAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                ),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Failed to stream marks: $err',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              data: (allRecords) {
                final semRecords = allRecords.where((r) => r.semester == currentSelectedSemNumber).toList();

                if (semRecords.isEmpty) {
                  return _buildNoInternalMarksEmptyState(selectedSemTitle);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Assessment Filter Buttons (All, IA-1, IA-2, Model, Attendance)
                    _buildInternalFilterPills(),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedInternalFilter == 'All'
                                ? 'Subject Internal Assessments ($selectedSemTitle)'
                                : '$_selectedInternalFilter Subject Marks & Retest History',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Staff Verified', style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: semRecords.length,
                      itemBuilder: (context, index) {
                        final record = semRecords[index];
                        if (_selectedInternalFilter == 'All') {
                          return _buildInternalSubjectCard(record);
                        } else {
                          return _buildEventSubjectCard(record, _selectedInternalFilter);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternalFilterPills() {
    final filters = [
      {'id': 'All', 'label': '📊 All Summary'},
      {'id': 'IA-1', 'label': '📝 Internal 1 (IA-1)'},
      {'id': 'IA-2', 'label': '📝 Internal 2 (IA-2)'},
      {'id': 'Model', 'label': '🎓 Model Exam'},
      {'id': 'Attendance', 'label': '📋 Attendance'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final id = f['id'] as String;
          final isSel = _selectedInternalFilter == id;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedInternalFilter = id;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF1D4ED8) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  if (isSel)
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Text(
                f['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventSubjectCard(AcademicRecord record, String eventKey) {
    AssessmentComponent? comp;

    if (eventKey == 'IA-1') {
      comp = record.ia1;
    } else if (eventKey == 'IA-2') {
      comp = record.ia2;
    } else if (eventKey == 'Model') {
      comp = record.modelExam;
    } else if (eventKey == 'Attendance') {
      comp = record.attendance;
    }

    final bool hasRetest = comp?.isRetest == true || (record.hasRetest && (eventKey == 'IA-1' || eventKey == 'IA-2'));
    final String finalScore = comp?.displayRaw ?? 'N/A';
    final String initialScore = comp?.initialAttempt ?? finalScore;
    final String convScore = comp?.displayConverted ?? 'N/A';
    final String retestScore = comp?.retestScore ?? (record.retest?.retestScore ?? finalScore);
    final String statusText = comp?.retestStatus ?? (record.retest?.status ?? 'Retest Cleared');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasRetest ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: hasRetest ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject Code & Name + Final Event Score Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.courseCode,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.courseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasRetest ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasRetest ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      finalScore,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: hasRetest ? const Color(0xFF059669) : const Color(0xFF1D4ED8),
                      ),
                    ),
                    Text(
                      'Conv: $convScore',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: hasRetest ? const Color(0xFF047857) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Faculty In-Charge: ${record.facultyName}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Attempts Breakdown (Initial Attempt vs Retest)
          if (hasRetest) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Initial Attempt: $initialScore',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB91C1C),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Initial Fail / Low',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.published_with_changes_rounded, size: 14, color: Color(0xFF059669)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Retest Attempt: $retestScore',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Regular Attempt Passed: $finalScore (No Retest Required)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInternalSubjectCard(AcademicRecord record) {
    final ia1Val = record.ia1?.obtained ?? 0.0;
    final ia2Val = record.ia2?.obtained ?? 0.0;
    final modelVal = record.modelExam?.obtained ?? 0.0;
    final attVal = record.attendance?.obtained ?? 0.0;
    final totalPct = record.percent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Subject Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.courseCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        record.courseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text(
                            record.internalMarks.display,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Faculty In-Charge: ${record.facultyName}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Middle Section: 4 Styled Assessment Component Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInternalMetricCard(
                        'IA-1 (50)',
                        record.ia1?.displayRaw ?? '0/50',
                        record.ia1?.displayConverted ?? '0/15',
                        ia1Val / (record.ia1?.max ?? 50.0),
                        const Color(0xFF2563EB),
                        const Color(0xFFEEF2FF),
                        Icons.edit_note_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInternalMetricCard(
                        'IA-2 (50)',
                        record.ia2?.displayRaw ?? '0/50',
                        record.ia2?.displayConverted ?? '0/15',
                        ia2Val / (record.ia2?.max ?? 50.0),
                        const Color(0xFF3B82F6),
                        const Color(0xFFEFF6FF),
                        Icons.quiz_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInternalMetricCard(
                        'Model (100)',
                        record.modelExam?.displayRaw ?? '0/100',
                        record.modelExam?.displayConverted ?? '0/20',
                        modelVal / (record.modelExam?.max ?? 100.0),
                        const Color(0xFF10B981),
                        const Color(0xFFECFDF5),
                        Icons.assignment_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInternalMetricCard(
                        'Attd / Assign',
                        record.attendance?.displayRaw ?? '0/10',
                        record.attendance?.displayConverted ?? '0/10',
                        attVal / (record.attendance?.max ?? 10.0),
                        const Color(0xFFF59E0B),
                        const Color(0xFFFFFBEB),
                        Icons.verified_user_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Overall Internal Weightage Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Internal Weightage Progress',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${(totalPct * 100).toStringAsFixed(1)}% Weightage',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalPct,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalMetricCard(
    String label,
    String raw,
    String conv,
    double pct,
    Color accentColor,
    Color bgColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              Text(
                conv,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            raw,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUniversityResultsEmptyState(String semName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 36,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No University Results Published for $semName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Official COE end-semester grades and SGPA will be published here following central valuation and Controller of Examinations declaration.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Text(
                  'Switch to Semester 1 - 4 above to view verified grades',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2: UNIVERSITY RESULTS (Published by Controller of Examinations - COE Team)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildUniversityResultsTab() {
    final gradebookState = ref.watch(gradebookProvider);
    final currentSem = gradebookState.currentSemester;
    final String selectedSemTitle = currentSem?.name ?? 'Semester ${_selectedSemIndex + 1}';
    final bool hasSubjects = currentSem != null && currentSem.subjects.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Official COE Publication Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'OFFICIAL COE UNIVERSITY RESULTS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), letterSpacing: 0.8),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 14),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Published officially by the Controller of Examinations (COE) Office. Dedicated COE Portal handles revaluations & transcripts.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFE2E8F0), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Semester Pills Row
          _buildSemesterPills(gradebookState.semesters),
          const SizedBox(height: 16),

          if (!hasSubjects) ...[
            _buildNoUniversityResultsEmptyState(selectedSemTitle),
          ] else ...[
            // Official SGPA Badge Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$selectedSemTitle Official Result',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Credits Earned: ${currentSem.earnedCredits} / ${currentSem.registeredCredits}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${currentSem.sgpa.toStringAsFixed(2)} SGPA',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                        ),
                        const Text(
                          'COE Verified',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Official End-Semester University Exam Grades ($selectedSemTitle)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentSem.subjects.length,
              itemBuilder: (context, index) {
                final sub = currentSem.subjects[index];
                return _buildUniversitySubjectCard(sub);
              },
            ),
          ],

          const SizedBox(height: 16),

          // Revaluation Info Footer Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'For paper revaluation, answer script copy requests, or mark sheet corrections, submit application through the COE Student Portal.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),);
  }

  Widget _buildUniversitySubjectCard(SubjectModel sub) {
    final gp = sub.gradePoint;
    final isPassed = sub.isPassed;
    final bool isRA = sub.grade == 'RA';
    final Color gradeColor = isPassed ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final Color gradeBg = isPassed ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2);

    final bool hasReExamHistory = isRA || sub.code == 'ME101' || sub.code == 'EE101';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRA ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isRA ? 1.5 : 1.0,
        ),
      ),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sub.code,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sub.credits} Credits • Grade Point: ${gp != null ? gp.toInt() : 'N/A'}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: gradeBg, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Text(
                      sub.grade,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: gradeColor),
                    ),
                    Text(
                      isPassed ? 'PASS' : 'RE-APPEAR',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: gradeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Re-Exam & Arrear Attempt Banner
          if (isRA) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Initial Attempt: RA (Fail) • Re-Exam Scheduled (Apr 2026 Arrear Session)',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (hasReExamHistory) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.published_with_changes_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Re-Exam Cleared: Grade \'B+\' (Nov 2024 Arrear Session) • Initial Attempt: RA',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSemesterPills(List<SemesterModel> semesters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(semesters.length, (index) {
          final sem = semesters[index];
          final isSel = index == _selectedSemIndex;
          final isCurrent = sem.isCurrent;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSemIndex = index;
              });
              ref.read(gradebookProvider.notifier).selectSemester(index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF1D4ED8) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  if (isSel)
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sem ${sem.number}',
                    style: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF34D399) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: isSel ? const Color(0xFF064E3B) : const Color(0xFF15803D),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// CGPA & SGPA DUAL CALCULATOR MODAL SHEET (With Interactive Switching)
// ───────────────────────────────────────────────────────────────────────────
class _CgpaCalculatorModalSheet extends ConsumerStatefulWidget {
  const _CgpaCalculatorModalSheet();

  @override
  ConsumerState<_CgpaCalculatorModalSheet> createState() => _CgpaCalculatorModalSheetState();
}

class _SemesterCalcItem {
  final String label;
  final TextEditingController sgpaCtrl;
  final TextEditingController credCtrl;

  _SemesterCalcItem({
    required this.label,
    required String sgpa,
    required String credits,
  })  : sgpaCtrl = TextEditingController(text: sgpa),
        credCtrl = TextEditingController(text: credits);

  void dispose() {
    sgpaCtrl.dispose();
    credCtrl.dispose();
  }
}

class _SubjectCalcItem {
  final TextEditingController nameCtrl;
  String grade;
  final TextEditingController credCtrl;

  _SubjectCalcItem({
    required String name,
    required this.grade,
    required String credits,
  })  : nameCtrl = TextEditingController(text: name),
        credCtrl = TextEditingController(text: credits);

  void dispose() {
    nameCtrl.dispose();
    credCtrl.dispose();
  }
}

class _CgpaCalculatorModalSheetState extends ConsumerState<_CgpaCalculatorModalSheet> {
  // 0: CGPA Mode (Semester-wise), 1: SGPA Mode (Subject-wise)
  int _activeMode = 0;

  // ──────────── CGPA MODE STATE ────────────
  late List<_SemesterCalcItem> _semesters;
  double _calculatedCgpa = 8.56;
  int _totalCgpaCredits = 67;

  // ──────────── SGPA MODE STATE ────────────
  late List<_SubjectCalcItem> _subjects;
  double _calculatedSgpa = 8.85;
  int _totalSgpaCredits = 17;

  final List<Map<String, dynamic>> _gradeOptions = [
    {'grade': 'O', 'point': 10.0, 'label': 'O (10) — Outstanding'},
    {'grade': 'A+', 'point': 9.0, 'label': 'A+ (9) — Excellent'},
    {'grade': 'A', 'point': 8.0, 'label': 'A (8) — Very Good'},
    {'grade': 'B+', 'point': 7.0, 'label': 'B+ (7) — Good'},
    {'grade': 'B', 'point': 6.0, 'label': 'B (6) — Above Average'},
    {'grade': 'C', 'point': 5.0, 'label': 'C (5) — Average / Pass'},
    {'grade': 'RA', 'point': 0.0, 'label': 'RA (0) — Re-appearance'},
  ];

  @override
  void initState() {
    super.initState();
    _initCgpaItems();
    _initSgpaItems();
    _recalculateCgpa();
    _recalculateSgpa();
  }

  void _initCgpaItems() {
    _semesters = [
      _SemesterCalcItem(label: 'Sem 1', sgpa: '8.50', credits: '14'),
      _SemesterCalcItem(label: 'Sem 2', sgpa: '8.60', credits: '15'),
      _SemesterCalcItem(label: 'Sem 3', sgpa: '8.33', credits: '18'),
      _SemesterCalcItem(label: 'Sem 4', sgpa: '8.80', credits: '20'),
    ];
  }

  void _initSgpaItems() {
    _subjects = [
      _SubjectCalcItem(name: 'Data Structures & Algorithms', grade: 'A+', credits: '4'),
      _SubjectCalcItem(name: 'Database Management Systems', grade: 'O', credits: '4'),
      _SubjectCalcItem(name: 'Operating Systems Concepts', grade: 'A', credits: '3'),
      _SubjectCalcItem(name: 'Discrete Mathematics & Logic', grade: 'A+', credits: '4'),
      _SubjectCalcItem(name: 'Web Technology Practical Lab', grade: 'O', credits: '2'),
    ];
  }

  @override
  void dispose() {
    for (final s in _semesters) {
      s.dispose();
    }
    for (final sub in _subjects) {
      sub.dispose();
    }
    super.dispose();
  }

  void _recalculateCgpa() {
    double totalPoints = 0;
    int totalCredits = 0;

    for (final sem in _semesters) {
      final sgpa = double.tryParse(sem.sgpaCtrl.text.trim()) ?? 0.0;
      final cred = int.tryParse(sem.credCtrl.text.trim()) ?? 0;
      if (cred > 0) {
        totalPoints += (sgpa.clamp(0.0, 10.0) * cred);
        totalCredits += cred;
      }
    }

    setState(() {
      _totalCgpaCredits = totalCredits;
      _calculatedCgpa = totalCredits > 0 ? (totalPoints / totalCredits).clamp(0.0, 10.0) : 0.0;
    });
  }

  void _recalculateSgpa() {
    double totalPoints = 0;
    int totalCredits = 0;

    for (final sub in _subjects) {
      final gradeOption = _gradeOptions.firstWhere(
        (g) => g['grade'] == sub.grade,
        orElse: () => {'grade': 'A', 'point': 8.0},
      );
      final point = (gradeOption['point'] as num).toDouble();
      final cred = int.tryParse(sub.credCtrl.text.trim()) ?? 0;
      if (cred > 0) {
        totalPoints += (point * cred);
        totalCredits += cred;
      }
    }

    setState(() {
      _totalSgpaCredits = totalCredits;
      _calculatedSgpa = totalCredits > 0 ? (totalPoints / totalCredits).clamp(0.0, 10.0) : 0.0;
    });
  }

  void _addSemester() {
    setState(() {
      final newIndex = _semesters.length + 1;
      _semesters.add(_SemesterCalcItem(
        label: 'Sem $newIndex',
        sgpa: '8.50',
        credits: '20',
      ));
    });
    _recalculateCgpa();
  }

  void _removeSemester(int index) {
    if (_semesters.length <= 1) return;
    setState(() {
      final item = _semesters.removeAt(index);
      item.dispose();
    });
    _recalculateCgpa();
  }

  void _addSubject() {
    setState(() {
      final newIndex = _subjects.length + 1;
      _subjects.add(_SubjectCalcItem(
        name: 'Theory / Lab Course $newIndex',
        grade: 'A+',
        credits: '3',
      ));
    });
    _recalculateSgpa();
  }

  void _removeSubject(int index) {
    if (_subjects.length <= 1) return;
    setState(() {
      final item = _subjects.removeAt(index);
      item.dispose();
    });
    _recalculateSgpa();
  }

  String _getCgpaClassification(double cgpa) {
    if (cgpa >= 8.5) return 'First Class with Distinction ⭐';
    if (cgpa >= 6.5) return 'First Class 👍';
    if (cgpa >= 5.0) return 'Second Class 📘';
    return 'Needs Improvement ⚠️';
  }

  String _getSgpaClassification(double sgpa) {
    if (sgpa >= 9.0) return 'Outstanding Performance 🌟';
    if (sgpa >= 8.0) return 'Excellent Performance ✨';
    if (sgpa >= 7.0) return 'Very Good Performance 🎯';
    if (sgpa >= 6.0) return 'Good Performance 👍';
    if (sgpa >= 5.0) return 'Average Performance 📘';
    return 'Re-appear / Arrears ⚠️';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Academic Calculator',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 🌟 INTERACTIVE MODE SWITCHER (CGPA vs SGPA)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _activeMode = 0);
                              _recalculateCgpa();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeMode == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _activeMode == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_graph_rounded,
                                    size: 16,
                                    color: _activeMode == 0 ? AppColors.primary : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'CGPA Calculator',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _activeMode == 0 ? AppColors.primary : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _activeMode = 1);
                              _recalculateSgpa();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeMode == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _activeMode == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 16,
                                    color: _activeMode == 1 ? AppColors.primary : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SGPA Calculator',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _activeMode == 1 ? AppColors.primary : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: _activeMode == 0 ? _buildCgpaModeView() : _buildSgpaModeView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. CGPA MODE VIEW (SEMESTER-WISE CUMULATIVE CALCULATION)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCgpaModeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        const Text(
          'Project your Cumulative Grade Point Average (CGPA) across multiple semesters based on semester SGPA & earned credits.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),

        // Result Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calculated Cumulative CGPA',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _calculatedCgpa.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Percentage: ${(_calculatedCgpa * 10).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total Credits: $_totalCgpaCredits',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCgpaClassification(_calculatedCgpa),
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Semester Rows Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Semester Breakdown',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            TextButton.icon(
              onPressed: _addSemester,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('+ Add Semester', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Semester List
        ...List.generate(_semesters.length, (index) {
          final item = _semesters[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: item.sgpaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'SGPA (0-10)',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    onChanged: (_) => _recalculateCgpa(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: item.credCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Credits',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    onChanged: (_) => _recalculateCgpa(),
                  ),
                ),
                if (_semesters.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                    onPressed: () => _removeSemester(index),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // Recalculate Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _recalculateCgpa,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Recalculate CGPA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SGPA MODE VIEW (SUBJECT & GRADE-WISE SEMESTER CALCULATION)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSgpaModeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        const Text(
          'Calculate Semester Grade Point Average (SGPA) for a semester by selecting grades (O, A+, A, B+, B, C, RA) and subject credits.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),

        // Result Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calculated Semester SGPA',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _calculatedSgpa.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Percentage: ${(_calculatedSgpa * 10).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Semester Credits: $_totalSgpaCredits',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getSgpaClassification(_calculatedSgpa),
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Subjects Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Enrolled Subjects & Courses',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            TextButton.icon(
              onPressed: _addSubject,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('+ Add Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4338CA),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Subjects List
        ...List.generate(_subjects.length, (index) {
          final sub = _subjects[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sub.nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Subject / Course Title',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_subjects.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        padding: const EdgeInsets.only(left: 6),
                        constraints: const BoxConstraints(),
                        onPressed: () => _removeSubject(index),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Grade Dropdown Selector
                    Expanded(
                      flex: 6,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: sub.grade,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            items: _gradeOptions.map((g) {
                              return DropdownMenuItem<String>(
                                value: g['grade'] as String,
                                child: Text(
                                  g['label'] as String,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => sub.grade = val);
                                _recalculateSgpa();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Credits Field
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: sub.credCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Credits',
                          labelStyle: const TextStyle(fontSize: 11.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        onChanged: (_) => _recalculateSgpa(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // Recalculate Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _recalculateSgpa,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Recalculate SGPA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
