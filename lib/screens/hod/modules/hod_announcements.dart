import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/announcement_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/services/supabase_service.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

class HodAnnouncements extends ConsumerStatefulWidget {
  const HodAnnouncements({super.key});

  @override
  ConsumerState<HodAnnouncements> createState() => _HodAnnouncementsState();
}

class _HodAnnouncementsState extends ConsumerState<HodAnnouncements> {
  String _selectedCategory = 'Department Notice';
  String _selectedFilter = 'All';
  String _selectedPriority = 'Normal';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _notifyParents = true;
  bool _notifyStudents = true;
  bool _notifyStaff = true;
  bool _isPublishing = false;

  final List<Map<String, String>> _fallbackBroadcasts = [
    {
      'id': 'fb-1',
      'title': 'Mid-Term Practical Schedule Published',
      'category': 'Examination',
      'date': 'Today, 10:30 AM',
      'target': 'All Students & Faculty',
      'content': 'Practical examinations for 3rd Year CSE will commence from 18th August. Detailed batch lists are posted on notice boards.',
      'priority': 'Important',
    },
    {
      'id': 'fb-2',
      'title': 'Google Cloud Campus Placement Drive',
      'category': 'Placement',
      'date': 'Yesterday',
      'target': '4th Year Students',
      'content': 'Pre-placement talk by Google Engineers on Friday @ 2 PM in Main Auditorium.',
      'priority': 'Normal',
    },
    {
      'id': 'fb-3',
      'title': 'National Conference on AI & ML',
      'category': 'Department Notice',
      'date': '02 Aug 2026',
      'target': 'Department Staff',
      'content': 'Call for papers extended till 15th August for all CSE faculty members.',
      'priority': 'Normal',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an announcement title.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write announcement content.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final currentUser = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
      final author = (currentUser?.name != null && currentUser!.name.isNotEmpty)
          ? currentUser.name
          : 'Dr. R. Kumar (HOD)';

      final targetedRoles = <String>[];
      if (_notifyStudents) targetedRoles.add('student');
      if (_notifyStaff) targetedRoles.add('staff');
      if (_notifyParents) targetedRoles.add('parent');

      final announcementId = 'ann_${DateTime.now().millisecondsSinceEpoch}';
      final newAnnouncement = AnnouncementModel(
        id: announcementId,
        title: title,
        content: content,
        authorName: author,
        createdAt: DateTime.now(),
        category: _selectedCategory,
        priority: _selectedPriority,
        targetedRoles: targetedRoles,
        targetedClasses: ['CS-A', 'CS-B', 'CS-C'],
      );

      await ref.read(firebaseFirestoreServiceProvider).addAnnouncement(newAnnouncement);
      ref.invalidate(announcementsStreamProvider);

      if (mounted) {
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _isPublishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Announcement Broadcasted to Department & Firestore successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publishing notice error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEPARTMENT BROADCAST HUB',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            const Text(
              'Announcements & Circulars',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),

            _buildCreateAnnouncementForm(),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT BROADCASTS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
                ),
                _buildCategoryFilterRow(),
              ],
            ),
            const SizedBox(height: 14),

            announcementsAsync.when(
              data: (list) {
                final filtered = list.where((a) {
                  if (_selectedFilter == 'All') return true;
                  return (a.category ?? '').toLowerCase() == _selectedFilter.toLowerCase();
                }).toList();

                if (filtered.isEmpty && list.isEmpty) {
                  return _buildFallbackList();
                }

                if (filtered.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Text('No announcements in $_selectedFilter category.', style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildLiveAnnouncementTile(item);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CustomLoader(label: 'Loading Department Announcements...'),
                ),
              ),
              error: (_, __) => _buildFallbackList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    final categories = ['All', 'Department Notice', 'Examination', 'Placement'];
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedFilter,
        icon: const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.primary),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedFilter = v);
        },
      ),
    );
  }

  Widget _buildFallbackList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fallbackBroadcasts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = _fallbackBroadcasts[index];
        return _buildStaticTile(item);
      },
    );
  }

  Widget _buildCreateAnnouncementForm() {
    final categories = [
      'Department Notice',
      'Examination',
      'Placement',
      'Workshop',
      'Seminar',
      'Circular',
      'Holiday',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Publish New Circular / Notice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text('HOD Broadcast', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Select Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Announcement Title (e.g. Mid-Semester Exam Schedule)...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write announcement content or instructions here...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilterChip(
                selected: _notifyStudents,
                label: const Text('Students', style: TextStyle(fontSize: 12)),
                onSelected: (v) => setState(() => _notifyStudents = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _notifyStaff,
                label: const Text('Staff', style: TextStyle(fontSize: 12)),
                onSelected: (v) => setState(() => _notifyStaff = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _notifyParents,
                label: const Text('Parents', style: TextStyle(fontSize: 12)),
                onSelected: (v) => setState(() => _notifyParents = v),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPriority,
                  items: ['Normal', 'Important', 'Urgent'].map((p) => DropdownMenuItem(value: p, child: Text('Priority: $p'))).toList(),
                  onChanged: (v) => setState(() => _selectedPriority = v ?? 'Normal'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _handlePublish,
              icon: _isPublishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.campaign_outlined, color: Colors.white),
              label: Text(
                _isPublishing ? 'Broadcasting...' : 'Publish Announcement',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAnnouncementTile(AnnouncementModel item) {
    final isUrgent = item.priority == 'Urgent';
    final isImportant = item.priority == 'Important';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isUrgent ? Border.all(color: AppColors.error, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(item.category ?? 'Notice', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  if (isUrgent || isImportant) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUrgent ? AppColors.error.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.priority,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isUrgent ? AppColors.error : AppColors.warning),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(item.content, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.account_circle_outlined, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('By: ${item.authorName}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaticTile(Map<String, String> item) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(item['category']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              Text(item['date']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(item['title']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(item['content']!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
