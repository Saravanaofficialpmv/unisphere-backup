import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/theme/app_animations.dart';
import 'package:unisphere/widgets/common/main_sidebar.dart';

/// Opens the floating parent navigation launcher sheet.
Future<void> showParentNavigationSheet({
  required BuildContext context,
  required int selectedIndex,
  required Function(int index) onDestinationSelected,
  required List<SidebarItem> items,
  String? userName,
  String? userEmail,
  String? profileUrl,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => ParentNavigationSheet(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      items: items,
      userName: userName,
      userEmail: userEmail,
      profileUrl: profileUrl,
    ),
  );
}

class ParentNavigationSheet extends ConsumerStatefulWidget {
  final int selectedIndex;
  final Function(int index) onDestinationSelected;
  final List<SidebarItem> items;
  final String? userName;
  final String? userEmail;
  final String? profileUrl;

  const ParentNavigationSheet({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.userName,
    this.userEmail,
    this.profileUrl,
  });

  @override
  ConsumerState<ParentNavigationSheet> createState() => _ParentNavigationSheetState();
}

class _ParentNavigationSheetState extends ConsumerState<ParentNavigationSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<_CategoryData> _categories = [
    _CategoryData('All', Icons.grid_view_rounded, AppColors.primary),
    _CategoryData('Academics', Icons.school_rounded, const Color(0xFF2563EB)),
    _CategoryData('Campus & Services', Icons.family_restroom_rounded, const Color(0xFF7C3AED)),
    _CategoryData('Alerts & Media', Icons.campaign_rounded, const Color(0xFF10B981)),
    _CategoryData('Account', Icons.manage_accounts_rounded, const Color(0xFFF59E0B)),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Groups items by their section header or intelligent categorization.
  Map<String, List<_IndexedSidebarItem>> _categorizeItems() {
    final Map<String, List<_IndexedSidebarItem>> result = {
      'Academics': [],
      'Campus & Services': [],
      'Alerts & Media': [],
      'Account': [],
    };

    String currentCategory = 'Academics';

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (item.isDivider) {
        final label = item.label.toUpperCase();
        if (label.contains('CAMPUS') || label.contains('CHILD') || label.contains('SERVICE')) {
          currentCategory = 'Campus & Services';
        } else if (label.contains('ALERT') || label.contains('ANNOUNCE') || label.contains('MEDIA')) {
          currentCategory = 'Alerts & Media';
        } else if (label.contains('ACCOUNT') || label.contains('PROFILE')) {
          currentCategory = 'Account';
        } else {
          currentCategory = 'Academics';
        }
        continue;
      }

      final labelLower = item.label.toLowerCase();
      String itemCategory = currentCategory;
      if (labelLower.contains('alert') || labelLower.contains('announcement') || labelLower.contains('gallery') || labelLower.contains('photo')) {
        itemCategory = 'Alerts & Media';
      } else if (labelLower.contains('fee') || labelLower.contains('transport') || labelLower.contains('event')) {
        itemCategory = 'Campus & Services';
      } else if (labelLower.contains('profile')) {
        itemCategory = 'Account';
      } else if (labelLower.contains('dashboard') || labelLower.contains('attendance') || labelLower.contains('mark') || labelLower.contains('performance')) {
        itemCategory = 'Academics';
      }

      result[itemCategory]?.add(_IndexedSidebarItem(index: i, item: item, category: itemCategory));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final categorized = _categorizeItems();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter items based on category and search query
    List<_IndexedSidebarItem> filteredItems = [];
    categorized.forEach((cat, list) {
      if (_selectedCategory == 'All' || _selectedCategory == cat) {
        for (final entry in list) {
          if (_searchQuery.isEmpty ||
              entry.item.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (entry.item.badge != null && entry.item.badge!.toLowerCase().contains(_searchQuery.toLowerCase()))) {
            filteredItems.add(entry);
          }
        }
      }
    });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Prevent taps inside the sheet from closing
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle Pill
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search academics, attendance, exams, updates...',
                          hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textTertiary),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),

                  // Category Filter Pills
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final catData = _categories[idx];
                        final isSelected = _selectedCategory == catData.name;

                        return AppPressable(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = catData.name);
                          },
                          scaleFactor: 0.95,
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: AppAnimations.fast,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                width: 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.28),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  catData.icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  catData.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Modules List
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: AppColors.textTertiary),
                                const SizedBox(height: 12),
                                Text(
                                  'No modules matching "$_searchQuery"',
                                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : _buildListView(scrollController, filteredItems),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the clean streamlined list view layout.
  Widget _buildListView(ScrollController scrollController, List<_IndexedSidebarItem> items) {
    final bottomPad = math.max(36.0, MediaQuery.of(context).padding.bottom + 24.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final itemData = items[idx];
        final isSelected = widget.selectedIndex == itemData.index;
        final catColor = _getCategoryColor(itemData.category);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppPressable(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              widget.onDestinationSelected(itemData.index);
            },
            scaleFactor: 0.98,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primarySubtle
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      itemData.item.icon,
                      size: 20,
                      color: isSelected ? Colors.white : catColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemData.item.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          itemData.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (itemData.item.badge != null)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: itemData.item.badgeColor ?? AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        itemData.item.badge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                    size: isSelected ? 22 : 20,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Academics':
        return const Color(0xFF2563EB); // Royal Blue
      case 'Campus & Services':
        return const Color(0xFF7C3AED); // Purple
      case 'Alerts & Media':
        return const Color(0xFF10B981); // Emerald
      case 'Account':
        return const Color(0xFFF59E0B); // Amber
      default:
        return AppColors.primary;
    }
  }
}

class _CategoryData {
  final String name;
  final IconData icon;
  final Color color;

  _CategoryData(this.name, this.icon, this.color);
}

class _IndexedSidebarItem {
  final int index;
  final SidebarItem item;
  final String category;

  _IndexedSidebarItem({
    required this.index,
    required this.item,
    required this.category,
  });
}
