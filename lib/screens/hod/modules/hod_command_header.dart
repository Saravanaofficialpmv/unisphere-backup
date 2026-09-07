import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/hod_dashboard_provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/common/apple_glass_card.dart';

/// Top-level HOD Command Header displaying personalized identity,
/// academic year, current semester, and department charter context.
class HodCommandHeader extends ConsumerWidget {
  final bool isReturningUser;

  const HodCommandHeader({
    super.key,
    this.isReturningUser = true,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dept = ref.watch(currentHodDepartmentProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider).value ?? ref.watch(authServiceProvider).currentUser;

    final hodName = (currentUser?.fullName != null && currentUser!.fullName.trim().isNotEmpty)
        ? currentUser.fullName
        : ((currentUser?.name != null && currentUser!.name.trim().isNotEmpty)
            ? currentUser.name
            : (dept?.hodName != null && dept!.hodName!.trim().isNotEmpty
                ? dept.hodName!
                : 'Dr. Ramesh Sundaram'));

    final deptName = (dept?.name != null && dept!.name.trim().isNotEmpty && dept.name != 'Computer Science & Engineering')
        ? dept.name
        : (currentUser?.departmentName ??
            currentUser?.department ??
            currentUser?.metadata?['departmentName']?.toString() ??
            currentUser?.metadata?['department']?.toString() ??
            dept?.name ??
            'Computer Science & Engineering');

    final timeGreeting = _getTimeGreeting();

    return AppleGlassCard.frosted(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      borderRadius: 16,
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
                    Text(
                      isReturningUser ? '$timeGreeting, Welcome Back! 👋' : 'Welcome to Department Governance! 👋',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.hodRole,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hodName.startsWith('Dr.') ? hodName : 'Dr. $hodName',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.hodRole.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.hodRole.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        'Head of Department • $deptName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: isMobile ? 52 : 64,
                height: isMobile ? 52 : 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.hodRole.withValues(alpha: 0.16),
                      AppColors.hodRole.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.hodRole.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: AppColors.hodRole,
                  size: isMobile ? 26 : 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _buildContextMetaItem(Icons.domain_rounded, 'Department', deptName),
              _buildContextMetaItem(Icons.calendar_today_rounded, 'Academic Year', '2026–27'),
              _buildContextMetaItem(Icons.timeline_rounded, 'Semester', 'Current Semester (Even)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextMetaItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.hodRole),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
