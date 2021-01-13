import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'text_selection_toolbar.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;

// Colors extracted from https://developer.apple.com/design/resources/.
// TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/41507.
const Color _kToolbarDividerColor = Color(0xFF808080);

// These values were measured from a screenshot of TextEdit on MacOS 10.15.7 on
// a Macbook Pro.
const double _kToolbarWidth = 222.0;
const Color _kToolbarBorderColor = Color(0xFF505152);
const Radius _kToolbarBorderRadius = Radius.circular(4.0);
const Color _kToolbarBackgroundColor = Color(0xFF2D2E31);

/// An iOS-style text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// Tries to position itself above [anchorAbove], but if it doesn't fit, then
/// it positions itself below [anchorBelow].
///
/// If any children don't fit in the menu, an overflow menu will automatically
/// be created.
///
/// See also:
///
///  * [TextSelectionControls.buildToolbar], where this is used by default to
///    build an iOS-style toolbar.
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
  final CupertinoToolbarBuilder toolbarBuilder;

  // Builds a toolbar just like the default iOS toolbar, with the right color
  // background and a rounded cutout with an arrow.
  static Widget _defaultToolbarBuilder(BuildContext context, Offset anchor, bool isAbove, Widget child) {
    // TODO(justinmc): I just removed Shape here, is this ok otherwise?
    return DecoratedBox(
      decoration: const BoxDecoration(color: _kToolbarDividerColor),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double paddingAbove = mediaQuery.padding.top + _kToolbarScreenPadding;

    const Offset contentPaddingAdjustment = Offset.zero;// Offset(0.0, _kToolbarContentDistance);
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
          anchor: anchor,
          //anchorAbove: anchorAbove - localAdjustment - contentPaddingAdjustment,
          //anchorBelow: anchorBelow - localAdjustment + contentPaddingAdjustment,
        ),
        child: Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

// Positions the toolbar at [anchor] if it fits, otherwise moves it up until it
// is fully on-screen.
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
    final bool fitsAbove = anchor.dy >= childSize.height;

    return anchor;
    /*
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
    */
  }

  @override
  bool shouldRelayout(_DesktopTextSelectionToolbarLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor;
  }
}
