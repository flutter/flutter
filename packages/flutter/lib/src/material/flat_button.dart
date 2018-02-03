// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_theme.dart';
import 'colors.dart';
import 'theme.dart';

/// A material design "flat button".
///
/// A flat button is a text label displayed on a (zero elevation) [Material]
/// widget that reacts to touches by filling with color.
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
/// Flat buttons will expand to fit the child widget, if necessary.
///
/// See also:
///
///  * [RaisedButton], a filled button whose material elevates when pressed.
///  * [DropdownButton], which offers the user a choice of a number of options.
///  * [SimpleDialogOption], which is used in [SimpleDialog]s.
///  * [IconButton], to create buttons that just contain icons.
///  * [InkWell], which implements the ink splash part of a flat button.
//// * [RawMaterialButton], the widget this widget is based on.
///  * <https://material.google.com/components/buttons.html>
class FlatButton extends StatelessWidget {
  /// Create a simple text button.
  const FlatButton({
    Key key,
    @required this.onPressed,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.disabledColor,
    this.highlightColor,
    this.splashColor,
    this.colorBrightness,
    this.padding,
    this.shape,
    @required this.child,
  }) : super(key: key);

  /// Create a text button from a pair of widgets that serve as the button's
  /// [icon] and [label].
  ///
  /// The icon and label are arranged in a row and padded by 12 logical pixels
  /// at the start, and 16 at the end, with an 8 pixel gap in between.
  ///
  /// The [icon] and [label] arguments must not be null.
  FlatButton.icon({
    Key key,
    @required this.onPressed,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.disabledColor,
    this.highlightColor,
    this.splashColor,
    this.colorBrightness,
    this.shape,
    @required Widget icon,
    @required Widget label,
  }) : assert(icon != null),
       assert(label != null),
       padding = const EdgeInsetsDirectional.only(start: 12.0, end: 16.0),
       child = new Row(
         mainAxisSize: MainAxisSize.min,
         children: <Widget>[
           icon,
           const SizedBox(width: 8.0),
           label,
         ],
       ),
       super(key: key);

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled, see [enabled].
  final VoidCallback onPressed;

  /// Defines the button's base colors, and the defaults for the button's minimum
  /// size, internal padding, and shape.
  ///
  /// Defaults to `ButtonTheme.of(context).textTheme`.
  final ButtonTextTheme textTheme;

  /// The color to use for this button's text.
  ///
  /// The button's [Material.textStyle] will be the current theme's button
  /// text style, [ThemeData.textTheme.button], configured with this color.
  ///
  /// The default text color depends on the button theme's text theme,
  /// [ButtonThemeData.textTheme].
  ///
  /// See also:
  ///   * [disabledTextColor], the text color to use when the button has been
  ///     disabled.
  final Color textColor;

  /// The color to use for this button's text when the button is disabled.
  ///
  /// The button's [Material.textStyle] will be the current theme's button
  /// text style, [ThemeData.textTheme.button], configured with this color.
  ///
  /// The default value is the theme's disabled color,
  /// [ThemeData.disabledColor].
  ///
  /// See also:
  ///  * [textColor] - The color to use for this button's text when the button is [enabled].
  final Color disabledTextColor;

  /// The button's fill color, displayed by its [Material], while it
  /// is in its default (unpressed, enabled) state.
  ///
  /// Typically not specified for [FlatButton]s.
  ///
  /// The default is null.
  final Color color;

  /// The fill color of the button when the button is disabled.
  ///
  /// Typically not specified for [FlatButton]s.
  ///
  /// The default is null.
  final Color disabledColor;

  /// The splash color of the button's [InkWell].
  ///
  /// The ink splash indicates that the button has been touched. It
  /// appears on top of the button's child and spreads in an expanding
  /// circle beginning where the touch occurred.
  ///
  /// If [textTheme] is [ButtonTextTheme.primary], the default splash color is
  /// is based on the theme's primary color [ThemeData.primaryColor],
  /// otherwise it's the current theme's splash color, [ThemeData.splashColor].
  ///
  /// The appearance of the splash can be configured with the theme's splash
  /// factory, [ThemeData.splashFactory].
  final Color splashColor;

  /// The highlight color of the button's [InkWell].
  ///
  /// The highlight indicates that the button is actively being pressed. It
  /// appears on top of the button's child and quickly spreads to fill
  /// the button, and then fades out.
  ///
  /// If [textTheme] is [ButtonTextTheme.primary], the default highlight color is
  /// transparent (in other words the highlight doesn't appear). Otherwise it's
  /// the current theme's highlight color, [ThemeData.highlightColor].
  final Color highlightColor;

  /// The theme brightness to use for this button.
  ///
  /// Defaults to the theme's brightness, [ThemeData.brightness].
  final Brightness colorBrightness;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget in all caps.
  final Widget child;

  /// Whether the button is enabled or disabled.
  ///
  /// Buttons are disabled by default. To enable a button, set its [onPressed]
  /// property to a non-null value.
  bool get enabled => onPressed != null;

  /// The internal padding for the button's [child].
  ///
  /// Defaults to the value from the current [ButtonTheme],
  /// [ButtonThemeData.padding].
  final EdgeInsetsGeometry padding;

  /// The shape of the button's [Material].
  ///
  /// The button's highlight and splash are clipped to this shape. If the
  /// button has an elevation, then its drop shadow is defined by this
  /// shape as well.
  final ShapeBorder shape;

  Brightness _getBrightness(ThemeData theme) {
    return colorBrightness ?? theme.brightness;
  }

  ButtonTextTheme _getTextTheme(ButtonThemeData buttonTheme) {
    return textTheme ?? buttonTheme.textTheme;
  }

  Color _getTextColor(ThemeData theme, ButtonThemeData buttonTheme, Color fillColor) {
    final Color color = enabled ? textColor : disabledTextColor;
    if (color != null)
      return color;

    final bool themeIsDark = _getBrightness(theme) == Brightness.dark;
    final bool fillIsDark = fillColor == null
      ? themeIsDark
      : ThemeData.estimateBrightnessForColor(fillColor) == Brightness.dark;

    switch (_getTextTheme(buttonTheme)) {
      case ButtonTextTheme.normal:
        return enabled
          ? (themeIsDark ? Colors.white : Colors.black87)
          : theme.disabledColor;
      case ButtonTextTheme.accent:
        return enabled
          ? theme.accentColor
          : theme.disabledColor;
      case ButtonTextTheme.primary:
        return enabled
          ? (fillIsDark ? Colors.white : theme.primaryColor)
          : (themeIsDark ? Colors.white30 : Colors.black38);
    }
    return null;
  }

  Color _getSplashColor(ThemeData theme, ButtonThemeData buttonTheme) {
    if (splashColor != null)
      return splashColor;

    switch (_getTextTheme(buttonTheme)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return theme.splashColor;
      case ButtonTextTheme.primary:
        return _getBrightness(theme) == Brightness.dark
          ? Colors.white12
          : theme.primaryColor.withOpacity(0.12);
    }
    return Colors.transparent;
  }

  Color _getHighlightColor(ThemeData theme, ButtonThemeData buttonTheme) {
    if (highlightColor != null)
      return highlightColor;

    switch (_getTextTheme(buttonTheme)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return theme.highlightColor;
      case ButtonTextTheme.primary:
        return Colors.transparent;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    final Color fillColor = enabled ? color : disabledColor;
    final Color textColor = _getTextColor(theme, buttonTheme, fillColor);

    return new RawMaterialButton(
      onPressed: onPressed,
      fillColor: fillColor,
      textStyle: theme.textTheme.button.copyWith(color: textColor),
      highlightColor: _getHighlightColor(theme, buttonTheme),
      splashColor: _getSplashColor(theme, buttonTheme),
      elevation: 0.0,
      highlightElevation: 0.0,
      padding: padding ?? buttonTheme.padding,
      constraints: buttonTheme.constraints,
      shape: shape ?? buttonTheme.shape,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new ObjectFlagProperty<VoidCallback>('onPressed', onPressed, ifNull: 'disabled'));
    description.add(new DiagnosticsProperty<ButtonTextTheme>('textTheme', textTheme, defaultValue: null));
    description.add(new DiagnosticsProperty<Color>('textColor', textColor, defaultValue: null));
    description.add(new DiagnosticsProperty<Color>('disabledTextColor', disabledTextColor, defaultValue: null));
    description.add(new DiagnosticsProperty<Color>('color', color, defaultValue: null));
    description.add(new DiagnosticsProperty<Color>('disabledColor', disabledColor, defaultValue: null));
    description.add(new DiagnosticsProperty<Color>('highlightColor', highlightColor, defaultValue: null));
    description.add(new DiagnosticsProperty<Color>('splashColor', splashColor, defaultValue: null));
    description.add(new DiagnosticsProperty<Brightness>('colorBrightness', colorBrightness, defaultValue: null));
    description.add(new DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    description.add(new DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}
