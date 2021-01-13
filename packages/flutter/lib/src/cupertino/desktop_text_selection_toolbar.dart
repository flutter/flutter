import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'text_selection_toolbar.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;

// These values were measured from a screenshot of TextEdit on MacOS 10.15.7 on
// a Macbook Pro.
const double _kToolbarWidth = 222.0;
const Color _kToolbarBorderColor = Color(0xFF505152);
const Radius _kToolbarBorderRadius = Radius.circular(4.0);
const Color _kToolbarBackgroundColor = Color(0xFF2D2E31);

/// The type for a Function that builds a toolbar's container with the given
/// child.
///
/// The anchor is provided in global coordinates.
///
/// See also:
///
///   * [CupertinoDesktopTextSelectionToolbar.toolbarBuilder], which is of this type.
///   * [CupertinoTextSelectionToolbar.toolbarBuilder], which is similar, but for a
///     mobile Cupertino-style toolbar.
///   * [TextSelectionToolbar.toolbarBuilder], which is similar, but for a
///     Material-style toolbar.
typedef CupertinoDesktopToolbarBuilder = Widget Function(
  BuildContext context,
  Offset anchor,
  Widget child,
);

/// A Mac-style text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// Tries to position itself as closesly as possible to [anchor] while remaining
/// fully on-screen.
///
/// See also:
///
///  * [TextSelectionControls.buildToolbar], where this is used by default to
///    build a Mac-style toolbar.
///  * [TextSelectionToolbar], which is similar, but builds an Android-style
///    toolbar.
class CupertinoDesktopTextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of CupertinoTextSelectionToolbar.
  const CupertinoDesktopTextSelectionToolbar({
    Key? key,
    required this.anchor,
    required this.children,
    this.toolbarBuilder = _defaultToolbarBuilder,
  }) : assert(children.length > 0),
       super(key: key);

  /// The point at which the toolbar will attempt to position itself as closely
  /// as possible.
  final Offset anchor;

  /// {@macro flutter.material.TextSelectionToolbar.children}
  ///
  /// See also:
  ///   * [CupertinoTextSelectionToolbarButton], which builds a default
  ///     Cupertino-style text selection toolbar text button.
  final List<Widget> children;

  /// {@macro flutter.material.TextSelectionToolbar.toolbarBuilder}
  ///
  /// The given anchor and isAbove can be used to position an arrow, as in the
  /// default Cupertino toolbar.
  final CupertinoDesktopToolbarBuilder toolbarBuilder;

  // Builds a toolbar just like the default Mac toolbar, with the right color
  // background, padding, and rounded corners.
  static Widget _defaultToolbarBuilder(BuildContext context, Offset anchor, Widget child) {
    return Container(
      width: _kToolbarWidth,
      decoration: BoxDecoration(
        color: _kToolbarBackgroundColor,
        border: Border.all(
          color: _kToolbarBorderColor,
        ),
        borderRadius: const BorderRadius.all(_kToolbarBorderRadius)
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 0.0,
          // This value was measured from a screenshot of TextEdit on MacOS
          // 10.15.7 on a Macbook Pro.
          vertical: 3.0,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double paddingAbove = mediaQuery.padding.top + _kToolbarScreenPadding;
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        paddingAbove,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: _DesktopTextSelectionToolbarLayoutDelegate(
          anchor: anchor - localAdjustment,
        ),
        child: toolbarBuilder(context, anchor, Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        )),
      ),
    );
  }
}

// Positions the toolbar at [anchor] if it fits, otherwise moves it so that it
// just fits fully on-screen.
//
// See also:
//
//   * [CupertinoDesktopTextSelectionToolbar], which uses this to position itself.
//   * [TextSelectionToolbarLayoutDelegate], which does a similar layout for
//     the mobile text selection toolbars.
class _DesktopTextSelectionToolbarLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates an instance of TextSelectionToolbarLayoutDelegate.
  _DesktopTextSelectionToolbarLayoutDelegate({
    required this.anchor,
  });

  /// The point at which to render the menu, if possible.
  ///
  /// Should be provided in local coordinates.
  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final Offset overhang = Offset(
      anchor.dx + childSize.width - size.width,
      anchor.dy + childSize.height - size.height,
    );
    return Offset(
      overhang.dx > 0.0 ? anchor.dx - overhang.dx : anchor.dx,
      overhang.dy > 0.0 ? anchor.dy - overhang.dy : anchor.dy,
    );
  }

  @override
  bool shouldRelayout(_DesktopTextSelectionToolbarLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor;
  }
}
