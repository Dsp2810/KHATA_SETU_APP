import 'package:flutter/material.dart';

/// Responsive breakpoints & helpers for KhataSetu.
/// Usage: `final r = Responsive(context);`
class Responsive {
  final BuildContext context;
  late final double width;
  late final double height;
  late final double textScale;

  Responsive(this.context) {
    final mq = MediaQuery.of(context);
    width = mq.size.width;
    height = mq.size.height;
    textScale = mq.textScaler.scale(1.0);
  }

  // ─── Breakpoints ───
  bool get isSmallPhone => width < 360;
  bool get isPhone => width < 600;
  bool get isTablet => width >= 600 && width < 900;
  bool get isDesktop => width >= 900;

  // ─── Grid helpers ───
  /// Adaptive cross-axis count for product/item grids.
  int get gridCrossAxisCount {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  /// Adaptive child aspect ratio for product cards.
  double get gridChildAspectRatio {
    if (width >= 600) return 0.85;
    if (width >= 360) return 0.78;
    return 0.72;
  }

  /// Max cross-axis extent for SliverGrid.
  double get maxGridExtent => isTablet ? 220.0 : 200.0;

  // ─── Sizing helpers ───
  /// Fractional width (0..1)
  double wp(double fraction) => width * fraction;

  /// Fractional height (0..1)
  double hp(double fraction) => height * fraction;

  /// Horizontal padding that adapts: more on tablets.
  double get horizontalPadding {
    if (isDesktop) return 48.0;
    if (isTablet) return 32.0;
    return 16.0;
  }

  /// Chart height — scales with screen height.
  double get chartHeight {
    if (height > 800) return 200;
    if (height > 650) return 170;
    return 140;
  }

  /// Pie chart diameter — scales with width.
  double get pieChartSize {
    if (width >= 600) return 180;
    if (width >= 400) return 150;
    return 120;
  }

  /// SliverAppBar expanded height — scales with height.
  double get sliverExpandedHeight {
    if (height > 800) return 300;
    if (height > 650) return 260;
    return 220;
  }

  /// Quick action icon size.
  double get quickActionIconSize {
    if (width >= 600) return 56;
    if (width >= 360) return 48;
    return 40;
  }

  /// Shop name max width in app bar.
  double get shopNameMaxWidth => wp(0.25);
}

/// Extension for easy access: `context.responsive`
extension ResponsiveX on BuildContext {
  Responsive get responsive => Responsive(this);
}
