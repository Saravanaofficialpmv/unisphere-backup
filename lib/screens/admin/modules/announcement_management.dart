import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/announcement_model.dart';
import 'package:unisphere/services/announcement_service.dart';
import 'package:unisphere/services/auth_service.dart';

class AnnouncementManagementModule extends ConsumerStatefulWidget {
  const AnnouncementManagementModule({super.key});

  @override
  ConsumerState<AnnouncementManagementModule> createState() => _AnnouncementManagementModuleState();
}

class _AnnouncementManagementModuleState extends ConsumerState<AnnouncementManagementModule> {
  final AnnouncementService _announcementService = AnnouncementService();
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Academic', 'Event', 'Holiday', 'Placement', 'Department', 'General'];

  @override
  void initState() {
    super.initState();
    _announcementService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _announcementService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categories[_selectedCategoryIndex];
    final allAnnouncements = _announcementService.announcements;
    final filteredAnnouncements = selectedCategory == 'All'
        ? allAnnouncements
        : allAnnouncements.where((a) => (a.category ?? '').toLowerCase() == selectedCategory.toLowerCase()).toList();

    final pinnedNotice = allAnnouncements.firstWhere(
      (a) => a.priority == 'Urgent' || a.priority == 'Important',
      orElse: () => allAnnouncements.isNotEmpty
          ? allAnnouncements.first
          : AnnouncementModel(
              id: 'sample',
              title: 'Welcome to UNISPHERE Portal',
              content: 'All administrative announcements and bulletins are broadcast here.',
              authorName: "Registrar's Office",
              createdAt: DateTime.now(),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildStatsSummary(allAnnouncements),
        const SizedBox(height: 24),
        _buildActionRow(context),
        const SizedBox(height: 16),
        _buildCategoryFilters(),
        const SizedBox(height: 24),
        if (allAnnouncements.isNotEmpty) ...[
          _buildPinnedSection(pinnedNotice),
          const SizedBox(height: 16),
        ],
        _buildRecentAnnouncements(filteredAnnouncements),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INSTITUTIONAL HUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('Announcements', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showCreateAnnouncementDialog(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Announcement'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<AnnouncementModel> announcements) {
    final activeCount = announcements.length;
    final urgentCount = announcements.where((a) => a.priority == 'Urgent' || a.priority == 'Important').length;

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('ACTIVE NOW', '$activeCount', Icons.check_circle, Colors.green),
          _buildStatCard('PRIORITY/URGENT', '$urgentCount', Icons.warning_amber_rounded, Colors.orange),
          _buildStatCard('CATEGORIES', '${_categories.length - 1}', Icons.category_rounded, Colors.blue),
          _buildStatCard('COVERAGE', '100%', Icons.groups_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_categories[index], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey.shade700)),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedCategoryIndex = index),
              selectedColor: Colors.blue.shade700,
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.transparent)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinnedSection(AnnouncementModel notice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.push_pin, size: 14, color: Colors.blue),
            SizedBox(width: 8),
            Text('PINNED NOTICES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 12),
        _buildPinnedNoticeCard(notice),
      ],
    );
  }

  Widget _buildPinnedNoticeCard(AnnouncementModel notice) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(4)),
                          child: Text((notice.category ?? 'ADMINISTRATIVE').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text('${DateFormat('dd MMM yyyy').format(notice.createdAt)} • ${notice.authorName}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(notice.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3)),
                    const SizedBox(height: 8),
                    Text(notice.content, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAnnouncements(List<AnnouncementModel> announcements) {
    if (announcements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: const Column(
          children: [
            Icon(Icons.campaign_outlined, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 10),
            Text('No announcements found', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    return Column(
      children: announcements.map((ann) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildRegistryCard(ann),
      )).toList(),
    );
  }

  Widget _buildRegistryCard(AnnouncementModel ann) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(ann.createdAt);
    final isUrgent = ann.priority == 'Urgent' || ann.priority == 'Important';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (ann.category ?? 'GENERAL').toUpperCase(),
                  style: TextStyle(color: isUrgent ? Colors.red : Colors.orange, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: isUrgent ? Colors.red : Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    ann.priority.toUpperCase(),
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red : Colors.green),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(ann.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(ann.content, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(radius: 12, backgroundColor: AppColors.background, child: Icon(Icons.person, size: 14)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ann.authorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(dateStr, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Announcement?'),
                      content: Text('Are you sure you want to delete "${ann.title}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _announcementService.deleteAnnouncement(ann.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Announcement removed successfully.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCategory = 'General';
    String selectedPriority = 'Normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.blue),
              SizedBox(width: 10),
              Text('Create Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Announcement Content *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: ['General', 'Academic', 'Examination', 'Department', 'Placement', 'Event', 'Holiday']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedCategory = v ?? 'General'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedPriority,
                        decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                        items: ['Normal', 'Important', 'Urgent']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedPriority = v ?? 'Normal'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out both title and content.'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final user = ref.read(currentUserProvider).value;
                final author = (user?.fullName != null && user!.fullName.isNotEmpty) ? user.fullName : 'Campus Administration';

                final newAnn = AnnouncementModel(
                  id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  content: content,
                  authorName: author,
                  category: selectedCategory,
                  priority: selectedPriority,
                  createdAt: DateTime.now(),
                  isNew: true,
                );

                _announcementService.addAnnouncement(newAnn);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 Announcement published and broadcast successfully!'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
              child: const Text('Publish Announcement'),
            ),
          ],
        ),
      ),
    );
  }
}

