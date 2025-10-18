import 'package:flutter/material.dart';

/// Shared layout breakpoints and spacing helpers for responsive design.
class LayoutConstants {
  LayoutConstants._();

  /// Width below which we treat the layout as compact (phone portrait).
  static const double compactMaxWidth = 360;

  /// Width above which we treat the layout as expanded (tablet/desktop).
  static const double expandedMinWidth = 900;

  /// Maximum content width for primary flows to avoid overly wide layouts.
  static const double maxContentWidth = 560;

  /// Default outer padding based on screen size.
  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= compactMaxWidth) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
    if (width >= expandedMinWidth) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  }

  /// Gap between elements based on available width.
  static double responsiveGap(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= compactMaxWidth) return 12;
    if (width >= expandedMinWidth) return 24;
    return 16;
  }

  /// Constrains child to [maxContentWidth] and centers it.
  static Widget maxWidthConstrained({
    required Widget child,
    double maxWidth = maxContentWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
