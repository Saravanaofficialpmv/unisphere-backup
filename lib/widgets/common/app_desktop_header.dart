import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/widgets/common/notification_bell_button.dart';
import 'package:unisphere/widgets/common/notification_sheet.dart';

/// Professional enterprise ERP global header bar for desktop screens.
class AppDesktopHeader extends ConsumerWidget implements PreferredSizeWidget {
  final List<String> breadcrumbs;
  final String title;
  final String? subtitle;
  final String? departmentName;
  final String? roleName;
  final Color? roleColor;
  final String? userName;
  final String? userPhotoUrl;
  final VoidCallback? onBack;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onLogoutTap;
  final List<Widget>? extraActions;

  const AppDesktopHeader({
    super.key,
    required this.breadcrumbs,
    required this.title,
    this.subtitle,
    this.departmentName,
    this.roleName,
    this.roleColor,
    this.userName,
    this.userPhotoUrl,
    this.onBack,
    this.onSearchTap,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onLogoutTap,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveRoleColor = roleColor ?? AppColors.primary;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              tooltip: 'Go Back',
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
          ],
          // Left: Breadcrumbs & Context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Breadcrumbs trail
                if (breadcrumbs.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < breadcrumbs.length; i++) ...[
                          Text(
                            breadcrumbs[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == breadcrumbs.length - 1 ? FontWeight.w700 : FontWeight.w500,
                              color: i == breadcrumbs.length - 1 ? AppColors.textPrimary : AppColors.textTertiary,
                            ),
                          ),
                          if (i < breadcrumbs.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                        if (departmentName != null && departmentName!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: effectiveRoleColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              departmentName!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: effectiveRoleColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 2),
                // Page title
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Global Search bar
          if (MediaQuery.of(context).size.width >= 960)
            SizedBox(
              width: 240,
              height: 36,
              child: Material(
                color: AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onSearchTap ?? () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderSubtle),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Quick search...',
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          '⌘K',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Extra Actions
          if (extraActions != null) ...extraActions!,

          // Notification Bell
          NotificationBellButton(
            onTap: onNotificationsTap ?? () => showNotificationSheet(context),
          ),

          const SizedBox(width: 12),

          // Vertical divider
          Container(
            height: 28,
            width: 1,
            color: AppColors.divider,
          ),

          const SizedBox(width: 12),

          // Profile chip
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: effectiveRoleColor.withValues(alpha: 0.12),
                    backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty ? NetworkImage(userPhotoUrl!) : null,
                    child: userPhotoUrl == null || userPhotoUrl!.isEmpty
                        ? Text(
                            (userName != null && userName!.isNotEmpty) ? userName![0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: effectiveRoleColor,
                            ),
                          )
                        : null,
                  ),
                  if (userName != null && userName!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (roleName != null)
                          Text(
                            roleName!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: effectiveRoleColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (onLogoutTap != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Log Out',
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: onLogoutTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
