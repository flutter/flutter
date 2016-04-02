// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'icon.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'theme.dart';
import 'tooltip.dart';

/// A material design "icon button".
///
/// An icon button is a picture printed on a [Material] widget that reacts to
/// touches by filling with color.
///
/// Use icon buttons on toolbars.
///
/// If the [onPressed] callback is not specified or null, then the button will
/// be disabled, will not react to touch.
///
/// See also:
///
///  * [Icons]
///  * [AppBar]
class IconButton extends StatelessWidget {
  const IconButton({
    Key key,
    this.size: 24.0,
    this.icon,
    this.color,
    this.disabledColor,
    this.onPressed,
    this.tooltip
  }) : super(key: key);

  /// The size of the icon inside the button.
  ///
  /// The button itself will be larger than the icon by 8.0 logical pixels in
  /// each direction.
  final double size;

  /// The icon to display inside the button.
  final IconData icon;

  /// The color to use for the icon inside the button, if the icon is enabled.
  /// Defaults to the current color, as defined by [Icon.color].
  ///
  /// The icon is enabled if [onPressed] is not null.
  ///
  /// See also [disabledColor].
  final Color color;

  /// The color to use for the icon inside the button, if the icon is disabled.
  /// Defaults to the [ThemeData.disabledColor] of the current [Theme].
  ///
  /// The icon is disabled if [onPressed] is null.
  ///
  /// See also [color].
  final Color disabledColor;

  /// The callback that is invoked when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Color currentColor;
    if (onPressed != null)
      currentColor = color;
    else
      currentColor = disabledColor ?? Theme.of(context).disabledColor;
    Widget result = new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Icon(
        size: size,
        icon: icon,
        color: currentColor
      )
    );
    if (tooltip != null) {
      result = new Tooltip(
        message: tooltip,
        child: result
      );
    }
    return new InkResponse(
      onTap: onPressed,
      child: result
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$icon');
    if (onPressed == null)
      description.add('disabled');
    if (tooltip != null)
      description.add('tooltip: "$tooltip"');
  }
}
