// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'theme.dart';

/// A material design "flat button".
///
/// A flat button is a section printed on a [Material] widget that reacts to
/// touches by filling with color.
///
/// Use flat buttons on toolbars, in dialogs, or inline with other content but
/// offset from that content with padding so that the button's presence is
/// obvious. Flat buttons intentionally do not have visible borders and must
/// therefore rely on their position relative to other content for context. In
/// dialogs and cards, they should be grouped together in one of the bottom
/// corners. Avoid using flat buttons where they would blend in with other
/// content, for example in the middle of lists.
///
/// Material design flat buttons have an all-caps label, some internal padding,
/// and some defined dimensions. To have a part of your application be
/// interactive, with ink splashes, without also committing to these stylistic
/// choices, consider using [InkWell] instead.
///
/// If the [onPressed] callback is null, then the button will be disabled,
/// will not react to touch, and will be colored as specified by
/// the [disabledColor] property instead of the [color] property. If you are
/// trying to change the button's [color] and it is not having any effect, check
/// that you are passing a non-null [onPressed] handler.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [RaisedButton], which is a button that hovers above the containing
///    material.
///  * [DropdownButton], which offers the user a choice of a number of options.
///  * [SimpleDialogOption], which is used in [SimpleDialog]s.
///  * [IconButton], to create buttons that just contain icons.
///  * [InkWell], which implements the ink splash part of a flat button.
///  * <https://material.google.com/components/buttons.html>
class FlatButton extends StatelessWidget {
  /// Creates a flat button.
  ///
  /// The [child] argument is required and is typically a [Text] widget in all
  /// caps.
  const FlatButton({
    Key key,
    @required this.onPressed,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    this.textTheme,
    this.colorBrightness,
    @required this.child
  }) : assert(child != null),
       super(key: key);

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// The color to use for this button's text.
  ///
  /// Defaults to the color determined by the [textTheme].
  final Color textColor;

  /// The color to use for this button's text when the button cannot be pressed.
  ///
  /// Defaults to a color derived from the [Theme].
  final Color disabledTextColor;

  /// The primary color of the button, as printed on the [Material], while it
  /// is in its default (unpressed, enabled) state.
  ///
  /// Defaults to null, meaning that the color is automatically derived from the [Theme].
  ///
  /// Typically, a material design color will be used, as follows:
  ///
  /// ```dart
  ///  new FlatButton(
  ///    color: Colors.blue,
  ///    onPressed: _handleTap,
  ///    child: new Text('DEMO'),
  ///  ),
  /// ```
  final Color color;

  /// The primary color of the button when the button is in the down (pressed) state.
  /// The splash is represented as a circular overlay that appears above the
  /// [highlightColor] overlay. The splash overlay has a center point that matches
  /// the hit point of the user touch event. The splash overlay will expand to
  /// fill the button area if the touch is held for long enough time. If the splash
  /// color has transparency then the highlight and button color will show through.
  ///
  /// Defaults to the splash color from the [Theme].
  final Color splashColor;

  /// The secondary color of the button when the button is in the down (pressed)
  /// state. The higlight color is represented as a solid color that is overlaid over the
  /// button color (if any). If the highlight color has transparency, the button color
  /// will show through. The highlight fades in quickly as the button is held down.
  ///
  /// Defaults to the highlight color from the [Theme].
  final Color highlightColor;

  /// The color of the button when the button is disabled. Buttons are disabled
  /// by default. To enable a button, set its [onPressed] property to a non-null
  /// value.
  final Color disabledColor;

  /// The color scheme to use for this button's text.
  ///
  /// Defaults to the button color from [ButtonTheme].
  final ButtonTextTheme textTheme;

  /// The theme brightness to use for this button.
  ///
  /// Defaults to the brightness from [ThemeData.brightness].
  final Brightness colorBrightness;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget in all caps.
  final Widget child;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    return new MaterialButton(
      onPressed: onPressed,
      textColor: enabled ? textColor : disabledTextColor,
      color: enabled ? color : disabledColor,
      highlightColor: highlightColor ?? Theme.of(context).highlightColor,
      splashColor: splashColor ?? Theme.of(context).splashColor,
      textTheme: textTheme,
      colorBrightness: colorBrightness,
      child: child
    );
  }
}
