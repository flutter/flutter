// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A one device pixel thick horizontal line, with padding on either
/// side.
///
/// In the material design language, this represents a divider.
///
/// Dividers can be used in lists, [Drawer]s, and elsewhere to separate content
/// vertically. To create a one-pixel divider between items in a list, consider
/// using [ListTile.divideTiles], which is optimized for this case.
///
/// The box's total height is controlled by [height]. The appropriate padding is
/// automatically computed from the height.
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
    this.height: 16.0,
    this.indent: 0.0,
    this.color
  }) : assert(height >= 0.0),
       super(key: key);

  /// The divider's vertical extent.
  ///
  /// The divider itself is always drawn as one device pixel thick horizontal
  /// line that is centered within the height specified by this value.
  ///
  /// A divider with a height of 0.0 is always drawn as a line with a height of
  /// exactly one device pixel, without any padding around it.
  final double height;

  /// The amount of empty space to the left of the divider.
  final double indent;

  /// The color to use when painting the line.
  ///
  /// Defaults to the current theme's divider color, given by
  /// [ThemeData.dividerColor].
  ///
  /// ```dart
  ///  new Divider(
  ///    color: Colors.deepOrange,
  ///  ),
  /// ```
  final Color color;

  @override
  Widget build(BuildContext context) {
    return new SizedBox(
      height: height,
      child: new Center(
        child: new Container(
          height: 0.0,
          margin: new EdgeInsets.only(left: indent),
          decoration: new BoxDecoration(
            border: new Border(
              bottom: new BorderSide(
                color: color ?? Theme.of(context).dividerColor,
                width: 0.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
