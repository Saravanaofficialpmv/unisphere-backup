import 'package:flutter/material.dart';

/// A flexible, container-aware responsive grid for enterprise ERP layouts.
/// Automatically adjusts column count based on available width.
class AppResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;

  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.largeDesktopColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns;

        if (width >= 1400) {
          columns = largeDesktopColumns;
        } else if (width >= 900) {
          columns = desktopColumns;
        } else if (width >= 560) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
        }

        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map((child) => Padding(
                      padding: EdgeInsets.only(bottom: runSpacing),
                      child: child,
                    ))
                .toList(),
          );
        }

        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
