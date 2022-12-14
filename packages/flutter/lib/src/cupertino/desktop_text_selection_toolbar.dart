// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';

// The minimum padding from all edges of the selection toolbar to all edges of
// the screen.
const double _kToolbarScreenPadding = 8.0;

// These values were measured from a screenshot of TextEdit on macOS 10.15.7 on
// a Macbook Pro.
const double _kToolbarWidth = 222.0;
const Radius _kToolbarBorderRadius = Radius.circular(4.0);
const EdgeInsets _kToolbarPadding = EdgeInsets.symmetric(
  vertical: 3.0,
);

// These values were measured from a screenshot of TextEdit on macOS 10.16 on a
// Macbook Pro.
const CupertinoDynamicColor _kToolbarBorderColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFBBBBBB),
  darkColor: Color(0xFF505152),
);
const CupertinoDynamicColor _kToolbarBackgroundColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xffECE8E6),
  darkColor: Color(0xff302928),
);

/// A macOS-style text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// Tries to position itself as closely as possible to [anchor] while remaining
/// fully inside the viewport.
///
/// See also:
///
///  * [CupertinoAdaptiveTextSelectionToolbar], where this is used to build the
///    toolbar for desktop platforms.
///  * [AdaptiveTextSelectionToolbar], where this is used to build the toolbar on
///    macOS.
///  * [DesktopTextSelectionToolbar], which is similar but builds a
///    Material-style desktop toolbar.
class CupertinoDesktopTextSelectionToolbar extends StatelessWidget {
  /// Creates a const instance of CupertinoTextSelectionToolbar.
  const CupertinoDesktopTextSelectionToolbar({
    super.key,
    required this.anchor,
    required this.children,
  }) : assert(children.length > 0);

  /// {@macro flutter.material.DesktopTextSelectionToolbar.anchor}
  final Offset anchor;

  /// {@macro flutter.material.TextSelectionToolbar.children}
  ///
  /// See also:
  ///   * [CupertinoDesktopTextSelectionToolbarButton], which builds a default
  ///     macOS-style text selection toolbar text button.
  final List<Widget> children;

  // Builds a toolbar just like the default Mac toolbar, with the right color
  // background, padding, and rounded corners.
  static Widget _defaultToolbarBuilder(BuildContext context, Widget child) {
    return Container(
      width: _kToolbarWidth,
      decoration: BoxDecoration(
        color: _kToolbarBackgroundColor.resolveFrom(context),
        border: Border.all(
          color: _kToolbarBorderColor.resolveFrom(context),
        ),
        borderRadius: const BorderRadius.all(_kToolbarBorderRadius),
      ),
      child: Padding(
        padding: _kToolbarPadding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final double paddingAbove = MediaQuery.paddingOf(context).top + _kToolbarScreenPadding;
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        paddingAbove,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: DesktopTextSelectionToolbarLayoutDelegate(
          anchor: anchor - localAdjustment,
        ),
        child: _defaultToolbarBuilder(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
