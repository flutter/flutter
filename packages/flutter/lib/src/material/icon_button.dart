// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';
import 'tooltip.dart';

// Minimum logical pixel size of the IconButton.
// See: <https://material.io/guidelines/layout/metrics-keylines.html#metrics-keylines-touch-target-size>
const double _kMinButtonSize = 48.0;

/// A material design icon button.
///
/// An icon button is a picture printed on a [Material] widget that reacts to
/// touches by filling with color (ink).
///
/// Icon buttons are commonly used in the [AppBar.actions] field, but they can
/// be used in many other places as well.
///
/// If the [onPressed] callback is null, then the button will be disabled and
/// will not react to touch.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// The hit region of an icon button will, if possible, be at least 48.0 pixels
/// in size, regardless of the actual [iconSize], to satisfy the [touch target
/// size](https://material.io/guidelines/layout/metrics-keylines.html#metrics-keylines-touch-target-size)
/// requirements in the Material Design specification. The [alignment] controls
/// how the icon itself is positioned within the hit region.
///
/// See also:
///
///  * [Icons], a library of predefined icons.
///  * [BackButton], an icon button for a "back" affordance which adapts to the
///    current platform's conventions.
///  * [CloseButton], an icon button for closing pages.
///  * [AppBar], to show a toolbar at the top of an application.
///  * [RaisedButton] and [FlatButton], for buttons with text in them.
///  * [InkResponse] and [InkWell], for the ink splash effect itself.
class IconButton extends StatelessWidget {
  /// Creates an icon button.
  ///
  /// Icon buttons are commonly used in the [AppBar.actions] field, but they can
  /// be used in many other places as well.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  ///
  /// The [iconSize], [padding], and [alignment] arguments must not be null (though
  /// they each have default values).
  ///
  /// The [icon] argument must be specified, and is typically either an [Icon]
  /// or an [ImageIcon].
  const IconButton({
    Key key,
    this.iconSize: 24.0,
    this.padding: const EdgeInsets.all(8.0),
    this.alignment: FractionalOffset.center,
    @required this.icon,
    this.color,
    this.disabledColor,
    @required this.onPressed,
    this.tooltip
  }) : assert(iconSize != null),
       assert(padding != null),
       assert(alignment != null),
       assert(icon != null),
       super(key: key);

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
  final double iconSize;

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
  /// The [Icon.size] and [Icon.color] of the icon is configured automatically
  /// based on the [iconSize] nad [color] properties of _this_ widget using an
  /// [IconTheme] and therefore should not be explicitly given in the icon
  /// widget.
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
  ///    color: Colors.blue,
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

    Widget result = new ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _kMinButtonSize, minHeight: _kMinButtonSize),
      child: new Padding(
        padding: padding,
        child: new SizedBox(
          height: iconSize,
          width: iconSize,
          child: new Align(
            alignment: alignment,
            child: IconTheme.merge(
              data: new IconThemeData(
                size: iconSize,
                color: currentColor
              ),
              child: icon
            ),
          ),
        ),
      ),
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
      radius: math.max(
        Material.defaultSplashRadius,
        (iconSize + math.min(padding.horizontal, padding.vertical)) * 0.7,
        // x 0.5 for diameter -> radius and + 40% overflow derived from other Material apps.
      ),
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
