import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 0;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double wideDesktop = 1440;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;

  bool get isTablet =>
      screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;

  bool get isDesktop =>
      screenWidth >= Breakpoints.desktop &&
      screenWidth < Breakpoints.wideDesktop;

  bool get isWideDesktop => screenWidth >= Breakpoints.wideDesktop;

  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? wideDesktop,
  }) {
    if (isWideDesktop && wideDesktop != null) return wideDesktop;
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  EdgeInsets get responsivePadding {
    return responsiveValue(
      mobile: const EdgeInsets.all(12),
      tablet: const EdgeInsets.all(16),
      desktop: const EdgeInsets.all(24),
      wideDesktop: const EdgeInsets.all(32),
    );
  }

  double get responsiveHorizontalPadding {
    return responsiveValue(
      mobile: 12.0,
      tablet: 16.0,
      desktop: 24.0,
      wideDesktop: 32.0,
    );
  }

  double get sidebarWidth {
    return responsiveValue(
      mobile: 0.0,
      tablet: 200.0,
      desktop: 260.0,
      wideDesktop: 300.0,
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? wideDesktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wideDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.wideDesktop &&
            wideDesktop != null) {
          return wideDesktop!;
        }
        if (constraints.maxWidth >= Breakpoints.desktop && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= Breakpoints.tablet && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.responsiveValue(
      mobile: 1,
      tablet: 2,
      desktop: 3,
      wideDesktop: 4,
    );

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        final width =
            (context.screenWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;
        return SizedBox(width: width, child: child);
      }).toList(),
    );
  }
}
