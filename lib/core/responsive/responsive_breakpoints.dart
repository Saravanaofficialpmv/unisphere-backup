import 'package:flutter/material.dart';

/// Centralized responsive breakpoint definition and utility class for UniSphere.
/// Ensures consistent desktop vs. tablet vs. mobile adaptive layouts.
class AppResponsive {
  // Primary Breakpoint: Below 800px is Mobile, 800px and above is Desktop ERP.
  static const double mobileMax = 799.0;
  static const double desktopMin = 800.0;

  // Granular Breakpoints:
  static const double compactMobileMax = 599.0;
  static const double tabletMin = 600.0;
  static const double standardDesktopMin = 1200.0;
  static const double largeDesktopMin = 1600.0;

  /// Returns true if the device width is < 800px (Mobile phone or compact tablet)
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < desktopMin;
  }

  /// Returns true if the device width is >= 800px (Desktop or wide tablet)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopMin;
  }

  /// Returns true if width is between 600px and 799px
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletMin && width < desktopMin;
  }

  /// Returns true if width is between 800px and 1199px
  static bool isCompactDesktop(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= desktopMin && width < standardDesktopMin;
  }

  /// Returns true if width is between 1200px and 1599px
  static bool isStandardDesktop(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= standardDesktopMin && width < largeDesktopMin;
  }

  /// Returns true if width is >= 1600px
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= largeDesktopMin;
  }

  /// Responsive value helper that selects the value based on current screen width
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
    T? largeDesktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= largeDesktopMin && largeDesktop != null) {
      return largeDesktop;
    }
    if (width >= desktopMin) {
      return desktop;
    }
    if (width >= tabletMin && tablet != null) {
      return tablet;
    }
    return mobile;
  }
}
