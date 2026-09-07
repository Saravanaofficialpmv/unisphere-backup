import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/academic_schedule_model.dart';
import 'package:unisphere/providers/academic_schedule_provider.dart';
import 'package:unisphere/providers/hod_dashboard_provider.dart';
import 'package:unisphere/screens/features/academic_schedule_detail_screen.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/academic_schedule_service.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class HodAcademicScheduleScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const HodAcademicScheduleScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<HodAcademicScheduleScreen> createState() => _HodAcademicScheduleScreenState();
}

class _HodAcademicScheduleScreenState extends ConsumerState<HodAcademicScheduleScreen> {
  String _selectedYearFilter = 'All';

  final List<String> _yearFilters = ['All', 'I Year', 'II Year', 'III Year', 'IV Year'];

  void _openUploadSheet(BuildContext context, {AcademicScheduleModel? replacingSchedule}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadScheduleSheet(replacingSchedule: replacingSchedule),
    );
  }

  Future<void> _confirmArchive(BuildContext context, AcademicScheduleModel schedule) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Archive Academic Schedule?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to archive "${schedule.title}" (v${schedule.version}.0)? Students will no longer see this as the active schedule.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(academicScheduleServiceProvider).archiveSchedule(
            scheduleId: schedule.id,
            userId: user.uid,
            userName: user.fullName,
            userRole: user.role.name,
          );
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Academic schedule archived successfully.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, AcademicScheduleModel schedule) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Schedule Record?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${schedule.title}" (v${schedule.version}.0)? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(academicScheduleServiceProvider).deleteSchedule(
            scheduleId: schedule.id,
            userId: user.uid,
            userName: user.fullName,
            userRole: user.role.name,
          );
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule record deleted successfully.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(AcademicScheduleModel schedule) async {
    if (schedule.fileUrl.isNotEmpty) {
      final uri = Uri.parse(schedule.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${schedule.fileName}"...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;
    final userDept = (dept?.name != null && dept!.name.isNotEmpty && dept.name != 'Computer Science & Engineering')
        ? dept.name
        : (user?.departmentName ??
            user?.department ??
            user?.metadata?['department']?.toString() ??
            'Department');

    final schedulesAsync = ref.watch(departmentAcademicSchedulesProvider(userDept));

    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: SafeArea(
        child: Column(
          children: [
            // Unisphere Header Card
            UnisphereHeaderCard(
              title: 'Academic Schedule & Important Days',
              subtitle: 'Upload, Version-Control & Publish College Schedules',
              onBack: widget.onBack ?? (Navigator.canPop(context) ? () => Navigator.of(context).pop() : null),
              rightActions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                  tooltip: 'Upload New Schedule',
                  onPressed: () => _openUploadSheet(context),
                ),
              ],
            ),

            // Year Filter Chips Row (Scrollable to prevent overflow)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    const Text('Target Year:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    ..._yearFilters.map((y) {
                      final isSelected = _selectedYearFilter == y;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(
                            y,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedYearFilter = y);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Schedules List
            Expanded(
              child: schedulesAsync.when(
                data: (allSchedules) {
                  final filtered = allSchedules.where((s) {
                    if (_selectedYearFilter == 'All') return true;
                    return AcademicScheduleService.normalizeTargetYear(s.targetStudentYear) ==
                        AcademicScheduleService.normalizeTargetYear(_selectedYearFilter);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                              ),
                              child: const Icon(Icons.calendar_month_outlined, size: 36, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Schedules for $_selectedYearFilter',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap "Upload New Schedule" to publish the official Excel, PDF or image schedule file.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
                              label: const Text('Upload Official Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () => _openUploadSheet(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Split into Active vs Archived versions
                  final activeSchedules = filtered.where((s) => s.isActive).toList();
                  final archivedSchedules = filtered.where((s) => !s.isActive).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Active Schedules Section
                      if (activeSchedules.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 3.5,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'CURRENT ACTIVE / LATEST SCHEDULE',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...activeSchedules.map((s) => _buildHodScheduleCard(context, s, isLatestActive: true)),
                        const SizedBox(height: 20),
                      ],

                      // Archived Version History Section
                      if (archivedSchedules.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 3.5,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.textTertiary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ARCHIVED / PREVIOUS VERSIONS',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...archivedSchedules.map((s) => _buildHodScheduleCard(context, s, isLatestActive: false)),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: Loader(label: 'Loading academic schedules...')),
                error: (err, _) => Center(child: Text('Error loading schedules: $err', style: const TextStyle(color: AppColors.textSecondary))),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Upload New Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
        onPressed: () => _openUploadSheet(context),
      ),
    );
  }

  Widget _buildHodScheduleCard(BuildContext context, AcademicScheduleModel schedule, {required bool isLatestActive}) {
    return Container(
      key: ValueKey('hod_sched_card_${schedule.id}_${schedule.version}'),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLatestActive ? const Color(0xFF10B981).withValues(alpha: 0.35) : AppColors.border,
          width: isLatestActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLatestActive ? const Color(0xFFF0FDF4) : AppColors.backgroundSubtle,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLatestActive ? const Color(0xFF10B981) : Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLatestActive ? '● ACTIVE / LATEST' : '● ARCHIVED',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Version ${schedule.version}.0',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  schedule.formattedUpdatedDate,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Body Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isLatestActive ? AppColors.primarySubtle : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        schedule.fileType == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded,
                        color: isLatestActive ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.title,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Target: ${schedule.targetStudentYear} (${schedule.semester}) • Academic Year: ${schedule.academicYear}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'File: ${schedule.fileName} (${schedule.formattedFileSize.isNotEmpty ? schedule.formattedFileSize : schedule.fileExtensionUpper})',
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 10),

                // Actions Row
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AcademicScheduleDetailScreen(schedule: schedule)),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('View / Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    if (isLatestActive) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _openUploadSheet(context, replacingSchedule: schedule),
                        icon: const Icon(Icons.upgrade_rounded, size: 16),
                        label: const Text('Replace Version', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _downloadFile(schedule),
                      icon: const Icon(Icons.download_rounded, size: 15, color: AppColors.textPrimary),
                      label: const Text('Download', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ),
                    const Spacer(),
                    if (isLatestActive)
                      IconButton(
                        key: ValueKey('archive_btn_${schedule.id}'),
                        icon: const Icon(Icons.archive_outlined, color: AppColors.warning, size: 20),
                        tooltip: 'Archive Schedule',
                        onPressed: () => _confirmArchive(context, schedule),
                      )
                    else
                      IconButton(
                        key: ValueKey('delete_btn_${schedule.id}'),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        tooltip: 'Delete Schedule Record',
                        onPressed: () => _confirmDelete(context, schedule),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UploadScheduleSheet extends ConsumerStatefulWidget {
  final AcademicScheduleModel? replacingSchedule;

  const UploadScheduleSheet({
    super.key,
    this.replacingSchedule,
  });

  @override
  ConsumerState<UploadScheduleSheet> createState() => _UploadScheduleSheetState();
}

class _UploadScheduleSheetState extends ConsumerState<UploadScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedTargetYear;
  late String _selectedAcademicYear;
  late String _selectedSemester;
  late String _selectedDepartment;
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _selectedFileSize;
  bool _isUploading = false;

  final List<String> _targetYears = ['I Year', 'II Year', 'III Year', 'IV Year', 'All Years'];
  final List<String> _academicYears = ['2026-27', '2025-26', '2027-28'];
  final List<String> _semesters = ['Odd Semester (Sem 1/3/5/7)', 'Even Semester (Sem 2/4/6/8)', 'Annual'];

  @override
  void initState() {
    super.initState();
    final prev = widget.replacingSchedule;
    _titleController = TextEditingController(text: prev != null ? prev.title : 'Academic Schedule for I Year');
    _descController = TextEditingController(text: prev?.description ?? '');
    _selectedTargetYear = prev?.targetStudentYear ?? 'I Year';
    _selectedAcademicYear = prev?.academicYear ?? '2026-27';
    _selectedSemester = prev?.semester ?? 'Odd Semester (Sem 1/3/5/7)';
    _selectedDepartment = prev?.departmentName ?? 'All Departments';
    _selectedFileName = prev?.fileName ?? 'Academic schedule for I Year_07.08.2026.xls';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        File? localFile;
        if (platformFile.path != null && platformFile.path!.isNotEmpty) {
          localFile = File(platformFile.path!);
        }

        final size = platformFile.size;

        // Validate max 15MB
        if (size > 15 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File exceeds 15MB limit. Please choose a smaller file.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = localFile;
          _selectedFileBytes = platformFile.bytes;
          _selectedFileName = platformFile.name;
          _selectedFileSize = platformFile.size;
        });
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  Future<void> _handleSave({required bool publishNow}) async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final service = ref.read(academicScheduleServiceProvider);

      String fileName = _selectedFileName ?? (widget.replacingSchedule?.fileName ?? 'Academic schedule for I Year_07.08.2026.xls');

      // Sample key dates generator for I Year
      List<ScheduleEventItem> sampleEvents = [
        ScheduleEventItem(
          dateString: '07 Aug 2026',
          date: DateTime(2026, 8, 7),
          title: 'Commencement of Classes for I Year (Odd Sem)',
          category: 'Academic',
          description: 'Official reopening and orientation for freshers',
        ),
        ScheduleEventItem(
          dateString: '15 Aug 2026',
          date: DateTime(2026, 8, 15),
          title: 'Independence Day',
          category: 'Holiday',
          isHoliday: true,
        ),
        ScheduleEventItem(
          dateString: '01 Sep 2026 - 05 Sep 2026',
          date: DateTime(2026, 9, 1),
          title: 'Continuous Assessment Test 1 (CAT-1)',
          category: 'Assessment',
          description: 'First internal assessment examinations',
        ),
        ScheduleEventItem(
          dateString: '17 Sep 2026',
          date: DateTime(2026, 9, 17),
          title: 'Milad-un-Nabi',
          category: 'Holiday',
          isHoliday: true,
        ),
        ScheduleEventItem(
          dateString: '02 Oct 2026',
          date: DateTime(2026, 10, 2),
          title: 'Gandhi Jayanti',
          category: 'Holiday',
          isHoliday: true,
        ),
        ScheduleEventItem(
          dateString: '12 Oct 2026 - 16 Oct 2026',
          date: DateTime(2026, 10, 12),
          title: 'Continuous Assessment Test 2 (CAT-2)',
          category: 'Assessment',
          description: 'Second internal assessment examinations',
        ),
        ScheduleEventItem(
          dateString: '20 Oct 2026',
          date: DateTime(2026, 10, 20),
          title: 'Student Online Feedback Cycle 1',
          category: 'Academic',
        ),
        ScheduleEventItem(
          dateString: '31 Oct 2026',
          date: DateTime(2026, 10, 31),
          title: 'Deepavali',
          category: 'Holiday',
          isHoliday: true,
        ),
        ScheduleEventItem(
          dateString: '16 Nov 2026 - 20 Nov 2026',
          date: DateTime(2026, 11, 16),
          title: 'Model Practical & Theory Examinations',
          category: 'Examination',
          description: 'Final preparatory exams before University Finals',
        ),
        ScheduleEventItem(
          dateString: '28 Nov 2026',
          date: DateTime(2026, 11, 28),
          title: 'Last Working Day for I Year (Odd Sem)',
          category: 'Academic',
        ),
        ScheduleEventItem(
          dateString: '07 Dec 2026',
          date: DateTime(2026, 12, 7),
          title: 'Commencement of University End-Sem Theory Exams',
          category: 'Examination',
        ),
      ];

      final result = await service.uploadAndPublishSchedule(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        academicYear: _selectedAcademicYear,
        departmentId: 'all',
        departmentName: _selectedDepartment,
        targetStudentYear: _selectedTargetYear,
        semester: _selectedSemester,
        file: _selectedFile,
        fileBytes: _selectedFileBytes,
        originalFileName: fileName,
        customFileSize: _selectedFileSize,
        userId: user.uid,
        userName: user.fullName,
        userRole: user.role.name,
        scheduleEvents: sampleEvents,
        publishNow: publishNow,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null
                  ? '🎉 Schedule published as Version ${result.version}.0 (Previous version archived automatically)!'
                  : 'Academic schedule saved successfully.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading schedule: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReplacing = widget.replacingSchedule != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 12),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReplacing ? 'Replace with Newer Version' : 'Upload Academic Schedule',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      if (isReplacing)
                        Text(
                          'Will automatically archive Version ${widget.replacingSchedule!.version}.0',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                decoration: InputDecoration(
                  labelText: 'Schedule Title *',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              // Target Year & Academic Year Dropdowns Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTargetYear,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Target Student Year',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.backgroundSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      items: _targetYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTargetYear = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedAcademicYear,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Academic Year',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.backgroundSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAcademicYear = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Semester Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedSemester,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Target Semester Scope',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
                items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSemester = val);
                },
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Notes / Remarks (Optional)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),

              // File Selection Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedFile != null ? AppColors.success.withValues(alpha: 0.12) : AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _selectedFile != null ? Icons.check_circle_rounded : Icons.file_upload_outlined,
                                color: _selectedFile != null ? AppColors.success : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFileName ?? (widget.replacingSchedule != null ? widget.replacingSchedule!.fileName : 'Select Schedule File'),
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'Supports: .XLS, .XLSX, .PDF, .JPG, .PNG (<15MB)',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open_rounded, size: 16, color: Colors.white),
                          label: const Text('Browse', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save / Publish Buttons
              if (_isUploading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Loader.inline(size: 32, label: 'Uploading & publishing schedule...'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _handleSave(publishNow: false),
                        child: const Text('Save Draft', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _handleSave(publishNow: true),
                        child: const Text('Publish Schedule (Active)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
}
