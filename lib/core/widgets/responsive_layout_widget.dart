import 'package:flutter/material.dart';
import '../constants/app_responsive.dart';

/// Responsive container yang auto-adjust padding, radius, width based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double basePaddingH;
  final double basePaddingV;
  final double baseRadius;
  final Color? backgroundColor;
  final BoxBorder? border;
  final bool isCard;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.basePaddingH = 16,
    this.basePaddingV = 12,
    this.baseRadius = 12,
    this.backgroundColor,
    this.border,
    this.isCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.padding(basePaddingH),
        vertical: context.padding(basePaddingV),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(context.radius(baseRadius)),
        border: border,
        boxShadow: isCard
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double baseHeight;
  final Axis axis;

  const ResponsiveSpacing({
    super.key,
    this.baseHeight = 16,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.padding(baseHeight);
    return axis == Axis.vertical
        ? SizedBox(height: size)
        : SizedBox(width: size);
  }
}

/// Responsive grid untuk habit/goal cards
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double baseSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.baseSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.gridColumns;
    final spacing = context.padding(baseSpacing);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: columns == 1 ? 1 / 0.4 : 1 / 0.5,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// Adaptive layout: mobile = column, tablet/desktop = row
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return desktopLayout ?? mobileLayout;
    } else if (context.isTablet) {
      return tabletLayout ?? mobileLayout;
    }
    return mobileLayout;
  }
}

/// Responsive bottom sheet container
class ResponsiveBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsets basePadding;
  final double baseRadius;

  const ResponsiveBottomSheet({
    super.key,
    required this.child,
    this.basePadding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
    this.baseRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: basePadding.copyWith(
        left: context.padding(basePadding.left),
        right: context.padding(basePadding.right),
        top: context.padding(basePadding.top),
        bottom: context.padding(basePadding.bottom),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.radius(baseRadius)),
          topRight: Radius.circular(context.radius(baseRadius)),
        ),
      ),
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }
}

/// Responsive text helper untuk consistent typography
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.baseSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: context.fontSize(baseSize),
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
