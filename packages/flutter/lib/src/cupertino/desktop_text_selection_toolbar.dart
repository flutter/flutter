// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;

// These values were measured from a screenshot of TextEdit on MacOS 10.15.7 on
// a Macbook Pro.
const double _kToolbarWidth = 222.0;
const Radius _kToolbarBorderRadius = Radius.circular(4.0);

// These values were measured from a screenshot of TextEdit on MacOS 10.16 on a
// Macbook Pro.
const CupertinoDynamicColor _kToolbarBorderColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFBBBBBB),
  darkColor: Color(0xFF505152),
);
const CupertinoDynamicColor _kToolbarBackgroundColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xffECE8E6),
  darkColor: Color(0xff302928),
);

/// A MacOS-style text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// Tries to position itself as closely as possible to [anchor] while remaining
/// fully on-screen.
///
/// See also:
///
///  * [CupertinoAdaptiveTextSelectionToolbar], where this is used to build the
///    toolbar for desktop platforms.
///  * [AdaptiveTextSelectionToolbar], where this is used to build the toolbar on
///    MacOS.
///  * [DesktopTextSelectionToolbar], which is similar but builds a
///    Material-style desktop toolbar.
class CupertinoDesktopTextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of CupertinoTextSelectionToolbar.
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
  ///     MacOS-style text selection toolbar text button.
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
        padding: const EdgeInsets.symmetric(
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
