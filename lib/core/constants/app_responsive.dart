import 'package:flutter/material.dart';

/// Extension untuk BuildContext untuk akses responsive values yang mudah
extension ResponsiveExt on BuildContext {
  // Breakpoints
  static const double _mobileBreak = 600;   // < 600: mobile
  static const double _tabletBreak = 900;   // 600-900: tablet, > 900: desktop

  // Screen detection
  bool get isMobile => screenWidth < _mobileBreak;
  bool get isTablet => screenWidth >= _mobileBreak && screenWidth < _tabletBreak;
  bool get isDesktop => screenWidth >= _tabletBreak;

  // Dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Responsive scaling
  double fontSize(double base) {
    if (isMobile) return base;
    if (isTablet) return base + 2;
    return base + 4;
  }

  double padding(double base) {
    if (isMobile) return base;
    if (isTablet) return base * 1.2;
    return base * 1.5;
  }

  double radius(double base) {
    if (isMobile) return base;
    if (isTablet) return base + 2;
    return base + 4;
  }

  double iconSize(double base) {
    if (isMobile) return base;
    if (isTablet) return base + 4;
    return base + 8;
  }

  int get gridColumns {
    if (isMobile) return 1;
    if (isTablet) return 2;
    return 3;
  }

  // Spacing constants
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;
}
