// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart';

import 'theme.dart';

// Examples can assume:
// BuildContext context;

/// A one device pixel thick horizontal line, with padding on either
/// side.
///
/// In the material design language, this represents a divider. Dividers can be
/// used in lists, [Drawer]s, and elsewhere to separate content.
///
/// To create a one-pixel divider between [ListTile] items, consider using
/// [ListTile.divideTiles], which is optimized for this case.
///
/// The box's total height is controlled by [height]. The appropriate
/// padding is automatically computed from the height.
///
/// See also:
///
///  * [PopupMenuDivider], which is the equivalent but for popup menus.
///  * [ListTile.divideTiles], another approach to dividing widgets in a list.
///  * <https://material.io/design/components/dividers.html>
class Divider extends StatelessWidget {
  /// Creates a material design divider.
  ///
  /// The height must be positive.
  const Divider({
    Key key,
    this.height = 16.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
  }) : assert(height >= 0.0),
       super(key: key);


  /// The divider's height extent.
  ///
  /// The divider itself is always drawn as one device pixel thick horizontal
  /// line that is centered within the height specified by this value.
  ///
  /// A divider with a [height] of 0.0 is always drawn as a line with a height
  /// of exactly one device pixel, without any padding around it.
  final double height;

  /// The amount of empty space to the left of the divider.
  final double indent;

  /// The amount of empty space to the right of the divider.
  final double endIndent;

  /// The color to use when painting the line.
  ///
  /// Defaults to the current theme's divider color, given by
  /// [ThemeData.dividerColor].
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// Divider(
  ///   color: Colors.deepOrange,
  /// )
  /// ```
  /// {@end-tool}
  final Color color;

  /// Computes the [BorderSide] that represents a divider of the specified
  /// color, or, if there is no specified color, of the default
  /// [ThemeData.dividerColor] specified in the ambient [Theme].
  ///
  /// The `width` argument can be used to override the default width of the
  /// divider border, which is usually 0.0 (a hairline border).
  ///
  /// {@tool sample}
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
  /// {@end-tool}
  static BorderSide createBorderSide(BuildContext context, { Color color, double width = 0.0 }) {
    assert(width != null);
    return BorderSide(
      color: color ?? Theme.of(context).dividerColor,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: 0.0,
          margin: EdgeInsetsDirectional.only(start: indent, end: endIndent),
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

/// A one device pixel thick vertical line, with padding on either
/// side.
///
/// In the material design language, this represents a divider. Vertical
/// dividers can be used in horizontally scrolling lists, such as a
/// [ListView] with [ListView.scrollDirection] set to [Axis.horizontal].
///
/// The box's total width is controlled by [width]. The appropriate
/// padding is automatically computed from the width.
///
/// See also:
///
///  * [ListView.separated], which can be used to generate vertical dividers.
///  * <https://material.io/design/components/dividers.html>
class VerticalDivider extends StatelessWidget {
  /// Creates a material design divider.
  ///
  /// The width must be positive.
  const VerticalDivider({
    Key key,
    this.width = 16.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
  }) : assert(width >= 0.0),
       super(key: key);

  /// The divider's width.
  ///
  /// The divider itself is always drawn as one device pixel thick
  /// line that is centered within the width specified by this value.
  ///
  /// A divider with a [width] of 0.0 is always drawn as a line with a width
  /// of exactly one device pixel, without any padding around it.
  final double width;

  /// The amount of empty space on top of the divider.
  final double indent;

  /// The amount of empty space under the divider.
  final double endIndent;

  /// The color to use when painting the line.
  ///
  /// Defaults to the current theme's divider color, given by
  /// [ThemeData.dividerColor].
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// Divider(
  ///   color: Colors.deepOrange,
  /// )
  /// ```
  /// {@end-tool}
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          width: 0.0,
          margin: EdgeInsetsDirectional.only(top: indent, bottom: endIndent),
          decoration: BoxDecoration(
            border: Border(
              left: Divider.createBorderSide(context, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
