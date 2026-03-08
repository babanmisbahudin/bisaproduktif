import 'package:flutter/material.dart';

/// Breakpoints untuk responsiveness (dalam logical pixels)
class ResponsiveBreakpoints {
  static const double mobile = 600; // < 600: mobile
  static const double tablet = 900; // 600-900: tablet
  // > 900: desktop/large tablet
}

/// Helper untuk mendapatkan dimensi responsif berdasarkan screen width
class ResponsiveDimensions {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Responsive font size (scales with screen width)
  /// mobile: base size, tablet: +2, desktop: +4
  static double fontSize(BuildContext context, double baseSize) {
    final w = width(context);
    if (w < ResponsiveBreakpoints.mobile) return baseSize;
    if (w < ResponsiveBreakpoints.tablet) return baseSize + 2;
    return baseSize + 4;
  }

  /// Responsive padding (scales with width)
  static double padding(BuildContext context, double basePadding) {
    final w = width(context);
    if (w < ResponsiveBreakpoints.mobile) return basePadding;
    if (w < ResponsiveBreakpoints.tablet) return basePadding * 1.2;
    return basePadding * 1.5;
  }

  /// Responsive radius
  static double radius(BuildContext context, double baseRadius) {
    final w = width(context);
    if (w < ResponsiveBreakpoints.mobile) return baseRadius;
    if (w < ResponsiveBreakpoints.tablet) return baseRadius + 2;
    return baseRadius + 4;
  }

  /// Responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    final w = width(context);
    if (w < ResponsiveBreakpoints.mobile) return baseSize;
    if (w < ResponsiveBreakpoints.tablet) return baseSize + 4;
    return baseSize + 8;
  }

  /// Grid columns berdasarkan screen size
  static int gridColumns(BuildContext context) {
    final w = width(context);
    if (w < ResponsiveBreakpoints.mobile) return 1;
    if (w < ResponsiveBreakpoints.tablet) return 2;
    return 3;
  }

  /// Responsive spacing
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;
}

/// Extension untuk BuildContext untuk akses yang lebih mudah
extension ResponsiveExt on BuildContext {
  bool get isMobile => ResponsiveDimensions.isMobile(this);
  bool get isTablet => ResponsiveDimensions.isTablet(this);
  bool get isDesktop => ResponsiveDimensions.isDesktop(this);

  double get screenWidth => ResponsiveDimensions.width(this);
  double get screenHeight => ResponsiveDimensions.height(this);

  double fontSize(double base) => ResponsiveDimensions.fontSize(this, base);
  double padding(double base) => ResponsiveDimensions.padding(this, base);
  double radius(double base) => ResponsiveDimensions.radius(this, base);
  double iconSize(double base) => ResponsiveDimensions.iconSize(this, base);
  int get gridColumns => ResponsiveDimensions.gridColumns(this);
}
