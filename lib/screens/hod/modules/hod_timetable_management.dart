import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';

class HodTimetableManagement extends ConsumerStatefulWidget {
  const HodTimetableManagement({super.key});

  @override
  ConsumerState<HodTimetableManagement> createState() => _HodTimetableManagementState();
}

class _HodTimetableManagementState extends ConsumerState<HodTimetableManagement> {
  String _selectedYear = '3rd Year';
  String _selectedSection = 'CS-A';
  String _activeView = 'Student View';
  String _selectedDay = 'Monday';

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> _sections = ['CS-A', 'CS-B', 'CS-C', 'Sec A', 'Sec B'];

  final Map<String, List<Map<String, String>>> _timetableData = {};

  @override
  Widget build(BuildContext context) {
    final timetables = ref.watch(allTimetablesStreamProvider).value ?? [];
    final docId = '${_selectedYear.replaceAll(' ', '_')}_${_selectedSection.replaceAll(' ', '_')}'.toLowerCase();
    final uploadedDoc = timetables.firstWhere((t) => t['id'] == docId, orElse: () => {});

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEPARTMENT SCHEDULING HUB',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            const Text(
              'Timetable Management',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select Year & Section to upload timetables (Excel, PDF, CSV, Images) for student & staff portals.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _buildYearSectionSelectors(),
            const SizedBox(height: 16),
            _buildUploadedFileCard(uploadedDoc),
            const SizedBox(height: 20),
            _buildViewSelector(),
            const SizedBox(height: 16),
            _buildDaySelector(),
            const SizedBox(height: 20),
            _buildTimetableGrid(),
            const SizedBox(height: 24),
            _buildTimetableActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSectionSelectors() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'TARGET CLASS SELECTION (YEAR & SECTION)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Academic Year', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedYear,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedYear = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Class Section', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSection,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSection = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileCard(Map<String, dynamic> doc) {
    final hasFile = doc.isNotEmpty && doc['fileName'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFile ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hasFile ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasFile ? const Color(0xFF2563EB) : const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(hasFile ? Icons.description_rounded : Icons.cloud_upload_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFile ? doc['fileName'] : 'No File Uploaded for $_selectedYear ($_selectedSection)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasFile
                      ? 'Uploaded: ${doc['fileType'] ?? 'Document'} • $_selectedYear ($_selectedSection)'
                      : 'Tap button below to upload Excel, PDF, CSV or Image timetable.',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showUploadTimetableModal(context),
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: Text(hasFile ? 'Replace File' : 'Upload File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    final views = ['Faculty View', 'Student View', 'Classroom View', 'Laboratory View'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: views.map((v) {
          final isSelected = _activeView == v;
          return GestureDetector(
            onTap: () => setState(() => _activeView = v),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final isSel = _selectedDay == d;
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = d),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              d.substring(0, 3),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSel ? AppColors.primary : AppColors.textSecondary),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimetableGrid() {
    final periods = _timetableData[_selectedDay] ?? [];
    if (periods.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No classes scheduled for $_selectedDay', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Upload or generate timetable to display scheduled periods.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      children: periods.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Text(item['period']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['subject']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${item['staff']} • ${item['room']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary), onPressed: () => _showSwapModal(context, item)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimetableActions(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: () => _notify(context, 'Faculty assigned to vacant slot!'),
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
          label: const Text('Assign Faculty'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
        OutlinedButton.icon(
          onPressed: () => _notify(context, 'Classroom venue swapped!'),
          icon: const Icon(Icons.meeting_room_outlined, size: 16),
          label: const Text('Assign Classroom'),
        ),
        OutlinedButton.icon(
          onPressed: () => _notify(context, 'Temporary replacement staff assigned.'),
          icon: const Icon(Icons.find_replace_outlined, size: 16),
          label: const Text('Replace Faculty'),
        ),
        OutlinedButton.icon(
          onPressed: () => _notify(context, 'Timetable PDF Exported!'),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Export Timetable'),
        ),
      ],
    );
  }

  void _showSwapModal(BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Swap Slot: ${item['subject']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Current Staff: ${item['staff']} (${item['room']})', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _notify(context, 'Substitution updated successfully!');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Confirm Substitution / Swap', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadTimetableModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: '${_selectedYear.replaceAll(' ', '_')}_${_selectedSection.replaceAll(' ', '_')}_Timetable.xlsx');
    String selectedFormat = 'Excel Sheet (.xlsx)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload Timetable Document',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target Class: $_selectedYear ($_selectedSection)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('File Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('File Format / Extension', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Excel Sheet (.xlsx)', 'PDF Document (.pdf)', 'CSV File (.csv)', 'Image (.png)'].map((fmt) {
                      final isSel = selectedFormat == fmt;
                      return ChoiceChip(
                        label: Text(fmt),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedFormat = fmt);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final fileName = nameCtrl.text.trim();
                        if (fileName.isEmpty) return;

                        await FirebaseFirestoreService().saveYearSectionTimetable(
                          year: _selectedYear,
                          section: _selectedSection,
                          fileName: fileName,
                          fileType: selectedFormat,
                          fileUrl: 'https://unisphere.edu/storage/timetables/$fileName',
                          periods: _timetableData[_selectedDay],
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _notify(context, '✅ Timetable uploaded for $_selectedYear ($_selectedSection)!');
                        }
                      },
                      icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                      label: const Text('Publish & Save Timetable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _notify(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
  }
}
