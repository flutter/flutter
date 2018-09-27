// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines the axis we want the divider to lay on.
enum Axis {
  /// The divider lies on a vertical axis.
  Vertical,

  /// The divider lies on a horizontal axis.
  Horizontal
}

/// A one device pixel thick horizontal line, with padding on either
/// side.
///
/// In the material design language, this represents a divider.
///
/// Dividers can be used in lists, [Drawer]s, and elsewhere to separate content
/// vertically or horizontally. To create a one-pixel divider between items in
/// a list, consider using [ListTile.divideTiles], which is optimized for this case.
///
/// The box's total width or height is controlled by [height]. The appropriate
/// padding is automatically computed from the width or height.
///
/// See also:
///
///  * [PopupMenuDivider], which is the equivalent but for popup menus.
///  * [ListTile.divideTiles], another approach to dividing widgets in a list.
///  * <https://material.google.com/components/dividers.html>
class Divider extends StatelessWidget {
  /// Creates a material design divider.
  ///
  /// The height must be positive.
  const Divider({
    Key key,
    this.height = 16.0,
    this.indent = 0.0,
    this.axis = Axis.Horizontal,
    this.color
  }) : assert(height >= 0.0 && axis != null),
        super(key: key);

  /// The divider's dimensional extent.
  ///
  /// The divider itself is always drawn as one device pixel thick
  /// line that is centered within the height or width specified by this value.
  ///
  /// A divider with a size of 0.0 is always drawn as a line with a
  /// height of exactly one device pixel, without any padding around it.
  final double height;

  /// The amount of empty space to the left of the divider.
  final double indent;

  /// The color to use when painting the line.
  ///
  /// Defaults to the current theme's divider color, given by
  /// [ThemeData.dividerColor].
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// Divider(
  ///   color: Colors.deepOrange,
  /// )
  /// ```
  final Color color;

  /// Whether the divider should be vertical or horizontal. When vertical,
  /// the [height] argument becomes the width of the divider.
  final Axis axis;

  /// Computes the [BorderSide] that represents a divider of the specified
  /// color, or, if there is no specified color, of the default
  /// [ThemeData.dividerColor] specified in the ambient [Theme].
  ///
  /// The `width` argument can be used to override the default width of the
  /// divider border, which is usually 0.0 (a hairline border).
  ///
  /// ## Sample code
  ///
  /// This example uses this method to create a box that has a divider above and
  /// below it. This is sometimes useful with lists, for instance, to separate a
  /// scrollable section from the rest of the interface.
  ///
  /// ```dart
  /// DecoratedBox(
  ///   decoration: BoxDecoration(
  ///     border: Border(
  ///       top: Divider.createBorderSide(context),
  ///       bottom: Divider.createBorderSide(context),
  ///     ),
  ///   ),
  ///   // child: ...
  /// )
  /// ```
  static BorderSide createBorderSide(BuildContext context,
      { Color color, double width = 0.0 }) {
    assert(width != null);
    return BorderSide(
      color: color ?? Theme.of(context).dividerColor,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.Vertical) {
      return SizedBox(
        width: height,
        child: Center(
          child: Container(
            height: 0.0,
            margin: EdgeInsetsDirectional.only(start: indent),
            decoration: BoxDecoration(
              border: Border(
                left: createBorderSide(context, color: color),
              ),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: height,
        child: Center(
          child: Container(
            height: 0.0,
            margin: EdgeInsetsDirectional.only(start: indent),
            decoration: BoxDecoration(
              border: Border(
                bottom: createBorderSide(context, color: color),
              ),
            ),
          ),
        ),
      );
    }
  }
}
