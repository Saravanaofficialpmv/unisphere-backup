import 'package:flutter/material.dart';
import 'package:unisphere/widgets/common/unisphere_bottom_nav_bar.dart';

/// Floating capsule navigation bar for the Student Panel,
/// styled with the modern Unisphere Frosted Glass & Electric Blue Design System.
///
/// Order:
/// 1. Home (Home Dashboard)
/// 2. Classes (Interactive Timetable / Classes)
/// 3. Center "U" Button (Feature Hub & Launcher Sheet)
/// 4. Notifications (Campus Announcements & Alerts)
/// 5. Profile (Student Profile)
class StudentFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isMenuOpen;
  final bool isVisible;
  final int unreadNotificationsCount;
  final VoidCallback onSidebarTap;
  final VoidCallback onHomeTap;
  final VoidCallback onResumeTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback onLogoutTap;

  const StudentFloatingNavBar({
    super.key,
    required this.currentIndex,
    this.isMenuOpen = false,
    this.isVisible = true,
    this.unreadNotificationsCount = 3,
    required this.onSidebarTap,
    required this.onHomeTap,
    required this.onResumeTap,
    required this.onProfileTap,
    this.onNotificationsTap,
    required this.onLogoutTap,
  });

  UnisphereNavSlot get _activeSlot {
    if (isMenuOpen) return UnisphereNavSlot.center;
    if (currentIndex == 1 || currentIndex == 19) return UnisphereNavSlot.classes;
    if (currentIndex == 0) return UnisphereNavSlot.home;
    if (currentIndex == 22) return UnisphereNavSlot.notifications;
    if (currentIndex == 24) return UnisphereNavSlot.profile;
    return UnisphereNavSlot.home;
  }

  @override
  Widget build(BuildContext context) {
    return UnisphereBottomNavBar(
      activeSlot: _activeSlot,
      isVisible: isVisible,
      unreadNotificationsCount: unreadNotificationsCount,
      classesLabel: 'Classes',
      classesIcon: Icons.assignment_outlined,
      classesActiveIcon: Icons.assignment_rounded,
      onHomeTap: onHomeTap,
      onClassesTap: onResumeTap,
      onCenterTap: onSidebarTap,
      onNotificationsTap: onNotificationsTap ?? onSidebarTap,
      onProfileTap: onProfileTap,
    );
  }
}
