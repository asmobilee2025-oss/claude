import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize {
    final w = width;
    if (w < 600) return ScreenSize.compact;
    if (w < 1100) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isExpanded => screenSize == ScreenSize.expanded;
}

/// Centers content and caps its width on large screens.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = 1200});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}
