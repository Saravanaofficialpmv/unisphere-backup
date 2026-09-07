import 'package:flutter/material.dart';
import 'package:unisphere/core/constants/app_colors.dart';

/// Professional application shell for desktop web / widescreen viewports.
/// Combines persistent sidebar, top global header, and responsive main viewport.
class AppDesktopShell extends StatelessWidget {
  final Widget sidebar;
  final PreferredSizeWidget? header;
  final Widget body;
  final Color backgroundColor;

  const AppDesktopShell({
    super.key,
    required this.sidebar,
    this.header,
    required this.body,
    this.backgroundColor = AppColors.backgroundSubtle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Pinned Global Header - Isolated from body repaint
          if (header != null) RepaintBoundary(child: header!),
          // Content Row: Sidebar + Main Content Viewport
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(child: sidebar),
                Expanded(
                  child: RepaintBoundary(
                    child: ClipRect(
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
