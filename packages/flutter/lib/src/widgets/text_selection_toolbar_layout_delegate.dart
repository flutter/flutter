import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Positions the toolbar above [anchorAbove] if it fits, or otherwise below
/// [anchorBelow].
///
/// See also:
///
///   * [TextSelectionToolbar], which uses this to position itself.
///   * [CupertinoTextSelectionToolbar], which also uses this to position
///     itself.
class TextSelectionToolbarLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates an instance of TextSelectionToolbarLayoutDelegate.
  TextSelectionToolbarLayoutDelegate({
    required this.anchorAbove,
    required this.anchorBelow,
    this.fitsAbove,
    this.paddingAbove = 0.0,
  });

  /// {@macro flutter.material.TextSelectionToolbar.anchorAbove}
  final Offset anchorAbove;

  /// {@macro flutter.material.TextSelectionToolbar.anchorAbove}
  final Offset anchorBelow;

  /// Whether or not the child should be considered to fit above anchorAbove.
  ///
  /// Typically used to force the child to be drawn at anchorAbove even when it
  /// doesn't fit, such as when the Material [TextSelectionToolbar] draws an
  /// open overflow menu.
  ///
  /// If not provided, it will be calculated.
  final bool? fitsAbove;

  /// Any space above anchorAbove that isn't able to be occupied by the child,
  /// such as screen padding.
  final double paddingAbove;

  // Return the value that centers width as closely as possible to position
  // while fitting inside of min and max.
  static double _centerOn(double position, double width, double max) {
    // If it overflows on the left, put it as far left as possible.
    if (position - width / 2.0 < 0.0) {
      return 0.0;
    }

    // If it overflows on the right, put it as far right as possible.
    if (position + width / 2.0 > max) {
      return max - width;
    }

    // Otherwise it fits while perfectly centered.
    return position - width / 2.0;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bool fitsAbove = this.fitsAbove
        ?? anchorAbove.dy >= childSize.height + paddingAbove;
    final Offset anchor = fitsAbove ? anchorAbove : anchorBelow;

    return Offset(
      _centerOn(
        anchor.dx,
        childSize.width,
        size.width,
      ),
      fitsAbove 
        ? math.max(0.0, anchor.dy - childSize.height)
        : anchor.dy,
    );
  }

  @override
  bool shouldRelayout(TextSelectionToolbarLayoutDelegate oldDelegate) {
    return anchorAbove != oldDelegate.anchorAbove
        || anchorBelow != oldDelegate.anchorBelow
        || paddingAbove != oldDelegate.paddingAbove
        || fitsAbove != oldDelegate.fitsAbove;
  }
}
