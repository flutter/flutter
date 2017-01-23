// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';
import 'tooltip.dart';

/// A material design icon button.
///
/// An icon button is a picture printed on a [Material] widget that reacts to
/// touches by filling with color.
///
/// Icon buttons are commonly used in the [AppBar.actions] field, but they can
/// be used in many other places as well.
///
/// If the [onPressed] callback is null, then the button will be disabled and
/// will not react to touch.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [Icons]
///  * [AppBar]
class IconButton extends StatelessWidget {
  /// Creates an icon button.
  ///
  /// Icon buttons are commonly used in the [AppBar.actions] field, but they can
  /// be used in many other places as well.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  ///
  /// The [size], [padding], and [alignment] arguments must not be null (though
  /// they each have default values).
  ///
  /// The [icon] argument must be specified, and is typically either an [Icon]
  /// or an [ImageIcon].
  const IconButton({
    Key key,
    this.size: 24.0,
    this.padding: const EdgeInsets.all(8.0),
    this.alignment: FractionalOffset.center,
    @required this.icon,
    this.color,
    this.disabledColor,
    @required this.onPressed,
    this.tooltip
  }) : super(key: key);

  /// The size of the icon inside the button.
  ///
  /// This property must not be null. It defaults to 24.0.
  ///
  /// The size given here is passed down to the widget in the [icon] property
  /// via an [IconTheme]. Setting the size here instead of in, for example, the
  /// [Icon.size] property allows the [IconButton] to size the splash area to
  /// fit the [Icon]. If you were to set the size of the [Icon] using
  /// [Icon.size] instead, then the [IconButton] would default to 24.0 and then
  /// the [Icon] itself would likely get clipped.
  final double size;

  /// The padding around the button's icon. The entire padded icon will react
  /// to input gestures.
  ///
  /// This property must not be null. It defaults to 8.0 padding on all sides.
  final EdgeInsets padding;

  /// Defines how the icon is positioned within the IconButton.
  ///
  /// This property must not be null. It defaults to [FractionalOffset.center].
  final FractionalOffset alignment;

  /// The icon to display inside the button.
  ///
  /// The [size] and [color] of the icon is configured automatically based on
  /// the properties of _this_ widget using an [IconTheme] and therefore should
  /// not be explicitly given in the icon widget.
  ///
  /// This property must not be null.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// The color to use for the icon inside the button, if the icon is enabled.
  /// Defaults to leaving this up to the [icon] widget.
  ///
  /// The icon is enabled if [onPressed] is not null.
  ///
  /// See also [disabledColor].
  ///
  /// ```dart
  ///  new IconButton(
  ///    color: Colors.blue[500],
  ///    onPressed: _handleTap,
  ///    icon: Icons.widgets,
  ///  ),
  /// ```
  final Color color;

  /// The color to use for the icon inside the button, if the icon is disabled.
  /// Defaults to the [ThemeData.disabledColor] of the current [Theme].
  ///
  /// The icon is disabled if [onPressed] is null.
  ///
  /// See also [color].
  final Color disabledColor;

  /// The callback that is called when the button is tapped or otherwise activated.
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
      padding: padding,
      child: new LimitedBox(
        maxWidth: size,
        maxHeight: size,
        child: new ConstrainedBox(
          constraints: new BoxConstraints.loose(
            new Size.square(math.max(size, Material.defaultSplashRadius * 2.0))
          ),
          child: new Align(
            alignment: alignment,
            child: new IconTheme.merge(
              context: context,
              data: new IconThemeData(
                size: size,
                color: currentColor
              ),
              child: icon
            )
          )
        )
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
      child: result,
      radius: math.max(size, Material.defaultSplashRadius),
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
