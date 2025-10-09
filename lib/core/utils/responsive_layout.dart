import 'package:flutter/material.dart';

/// Responsive Layout System - Task B14
/// Implement responsive layouts for tablets and foldables
/// 
/// Features:
/// - Breakpoints for different screen sizes
/// - Multi-column layouts
/// - Adaptive widgets
/// - Tablet optimization

class ResponsiveLayout {
  /// Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// Check if mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if desktop
  static bool isDesktop(BuildContext context) {
    final type = getDeviceType(context);
    return type == DeviceType.desktop || type == DeviceType.largeDesktop;
  }

  /// Get responsive value
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get column count
  static int getColumnCount(BuildContext context) {
    return value(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get padding
  static EdgeInsets getPadding(BuildContext context) {
    return EdgeInsets.all(
      value(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  /// Get max width for content
  static double getMaxContentWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveLayout.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Adaptive layout widget
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
          case DeviceType.largeDesktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Responsive grid
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columnCount = ResponsiveLayout.getColumnCount(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive row/column
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRowColumn({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, spacing, true),
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, spacing, false),
      );
    }
  }

  List<Widget> _addSpacing(List<Widget> children, double spacing, bool isColumn) {
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          isColumn
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
    }
    return result;
  }
}

/// Responsive container with max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);
    final defaultPadding = ResponsiveLayout.getPadding(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding ?? defaultPadding,
        child: child,
      ),
    );
  }
}

/// Responsive sidebar layout
class ResponsiveSidebarLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget content;
  final double sidebarWidth;

  const ResponsiveSidebarLayout({
    Key? key,
    required this.sidebar,
    required this.content,
    this.sidebarWidth = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      // Stack layout for mobile
      return content;
    } else {
      // Side-by-side layout for tablet/desktop
      return Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: sidebar,
          ),
          Expanded(child: content),
        ],
      );
    }
  }
}

/// Responsive text size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.mobileFontSize = 14,
    this.tabletFontSize,
    this.desktopFontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveLayout.value(
      context,
      mobile: mobileFontSize,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
    );
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Usage Examples:
/// 
/// ```dart
/// // Adaptive layout
/// AdaptiveLayout(
///   mobile: MobileHomeScreen(),
///   tablet: TabletHomeScreen(),
///   desktop: DesktopHomeScreen(),
/// )
/// 
/// // Responsive builder
/// ResponsiveBuilder(
///   builder: (context, deviceType) {
///     if (deviceType == DeviceType.mobile) {
///       return SingleColumnLayout();
///     } else {
///       return TwoColumnLayout();
///     }
///   },
/// )
/// 
/// // Responsive grid
/// ResponsiveGrid(
///   children: [
///     Card1(),
///     Card2(),
///     Card3(),
///   ],
/// )
/// 
/// // Responsive row/column
/// ResponsiveRowColumn(
///   children: [
///     Button1(),
///     Button2(),
///   ],
/// )
/// 
/// // Responsive container
/// ResponsiveContainer(
///   child: MyContent(),
/// )
/// 
/// // Responsive text
/// ResponsiveText(
///   'Hello World',
///   mobileFontSize: 14,
///   tabletFontSize: 16,
///   desktopFontSize: 18,
/// )
/// ```

