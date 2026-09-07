import 'package:flutter/material.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/widgets/common/sign_out_confirmation_sheet.dart';
import 'package:unisphere/core/theme/app_animations.dart';

class MainSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<SidebarItem> items;
  final String userName;
  final String userEmail;
  final String? profileUrl;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final String? roleBadge;
  final Color? roleColor;

  const MainSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    required this.userName,
    required this.userEmail,
    this.profileUrl,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.roleBadge,
    this.roleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveWidth = isCollapsed ? 76.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: effectiveWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 14),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.isDivider) {
                  return _buildSectionDivider(item);
                }
                return _buildNavItem(index, item);
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (isCollapsed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (roleColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (roleColor ?? AppColors.primary).withValues(alpha: 0.25),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.school_rounded,
                  color: roleColor ?? AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            if (onToggleCollapse != null) ...[
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                tooltip: 'Expand Sidebar',
                onPressed: onToggleCollapse,
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.school_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UNISPHERE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Institutional ERP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: roleColor ?? AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onToggleCollapse != null)
                IconButton(
                  icon: const Icon(Icons.menu_open_rounded, size: 20, color: AppColors.textSecondary),
                  tooltip: 'Collapse Sidebar',
                  onPressed: onToggleCollapse,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceSecondary,
                  backgroundImage: profileUrl != null ? NetworkImage(profileUrl!) : null,
                  child: profileUrl == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: roleColor ?? AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (roleBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (roleColor ?? AppColors.primary).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            roleBadge!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: roleColor ?? AppColors.primary,
                            ),
                          ),
                        )
                      else
                        Text(
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(SidebarItem item) {
    if (isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, indent: 8, endIndent: 8, color: AppColors.divider),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
      child: Text(
        item.label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, SidebarItem item) {
    final isSelected = selectedIndex == index;
    final activeColor = roleColor ?? AppColors.primary;

    final navContent = AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.fastCurve,
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 12 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border(
                left: BorderSide(color: activeColor, width: 3.5),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 20,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : AppColors.textPrimary,
                ),
              ),
            ),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: item.badgeColor ?? activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: item.badgeColor != null ? Colors.white : activeColor,
                  ),
                ),
              ),
          ],
        ],
      ),
    );

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Tooltip(
          message: isCollapsed ? item.label : '',
          waitDuration: const Duration(milliseconds: 350),
          child: AppPressable(
            onTap: () => onDestinationSelected(index),
            scaleFactor: 0.98,
            borderRadius: BorderRadius.circular(10),
            child: navContent,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: IconButton(
          icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
          tooltip: 'Sign Out',
          onPressed: () => showSignOutConfirmationSheet(context, ref),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showSignOutConfirmationSheet(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (onToggleCollapse != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.textSecondary),
              tooltip: 'Collapse Sidebar',
              onPressed: onToggleCollapse,
            ),
          ],
        ],
      ),
    );
  }
}

class SidebarItem {
  final String label;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final bool isDivider;

  SidebarItem({
    required this.label,
    required this.icon,
    this.badge,
    this.badgeColor,
    this.isDivider = false,
  });

  factory SidebarItem.divider(String label) => SidebarItem(
    label: label,
    icon: Icons.abc,
    isDivider: true,
  );
}
