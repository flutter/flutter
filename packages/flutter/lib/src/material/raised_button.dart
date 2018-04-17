// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_theme.dart';
import 'colors.dart';
import 'constants.dart';
import 'theme.dart';

/// A material design "raised button".
///
/// A raised button is based on a [Material] widget whose [Material.elevation]
/// increases when the button is pressed.
///
/// Use raised buttons to add dimension to otherwise mostly flat layouts, e.g.
/// in long busy lists of content, or in wide spaces. Avoid using raised buttons
/// on already-raised content such as dialogs or cards.
///
/// If the [onPressed] callback is null, then the button will be disabled and by
/// default will resemble a flat button in the [disabledColor]. If you are
/// trying to change the button's [color] and it is not having any effect, check
/// that you are passing a non-null [onPressed] handler.
///
/// If you want an ink-splash effect for taps, but don't want to use a button,
/// consider using [InkWell] directly.
///
/// Raised buttons have a minimum size of 88.0 by 36.0 which can be overidden
/// with [ButtonTheme].
///
/// See also:
///
///  * [FlatButton], a material design button without a shadow.
///  * [DropdownButton], a button that shows options to select from.
///  * [FloatingActionButton], the round button in material applications.
///  * [IconButton], to create buttons that just contain icons.
///  * [InkWell], which implements the ink splash part of a flat button.
///  * [RawMaterialButton], the widget this widget is based on.
///  * <https://material.google.com/components/buttons.html>
class RaisedButton extends StatelessWidget {
  /// Create a filled button.
  ///
  /// The [elevation], [highlightElevation], and [disabledElevation]
  /// arguments must not be null.
  const RaisedButton({
    Key key,
    @required this.onPressed,
    this.onHighlightChanged,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.disabledColor,
    this.highlightColor,
    this.splashColor,
    this.colorBrightness,
    this.elevation: 2.0,
    this.highlightElevation: 8.0,
    this.disabledElevation: 0.0,
    this.padding,
    this.shape,
    this.animationDuration: kThemeChangeDuration,
    this.child,
  }) : assert(elevation != null),
       assert(highlightElevation != null),
       assert(disabledElevation != null),
       assert(animationDuration != null),
       super(key: key);

  /// Create a filled button from a pair of widgets that serve as the button's
  /// [icon] and [label].
  ///
  /// The icon and label are arranged in a row and padded by 12 logical pixels
  /// at the start, and 16 at the end, with an 8 pixel gap in between.
  ///
  /// The [elevation], [highlightElevation], [disabledElevation], [icon], and
  /// [label] arguments must not be null.
  RaisedButton.icon({
    Key key,
    @required this.onPressed,
    this.onHighlightChanged,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.disabledColor,
    this.highlightColor,
    this.splashColor,
    this.colorBrightness,
    this.elevation: 2.0,
    this.highlightElevation: 8.0,
    this.disabledElevation: 0.0,
    this.shape,
    this.animationDuration: kThemeChangeDuration,
    @required Widget icon,
    @required Widget label,
  }) : assert(elevation != null),
       assert(highlightElevation != null),
       assert(disabledElevation != null),
       assert(icon != null),
       assert(label != null),
       assert(animationDuration != null),
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

  /// Called by the underlying [InkWell] widget's [InkWell.onHighlightChanged]
  /// callback.
  final ValueChanged<bool> onHighlightChanged;

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
  /// is in its default (unpressed, [enabled]) state.
  ///
  /// The default fill color is the theme's button color, [ThemeData.buttonColor].
  ///
  /// Typically the default color will be overidden with a Material color,
  /// for example:
  ///
  /// ```dart
  ///  new RaisedButton(
  ///    color: Colors.blue,
  ///    onPressed: _handleTap,
  ///    child: new Text('DEMO'),
  ///  ),
  /// ```
  ///
  /// See also:
  ///   * [disabledColor] - the fill color of the button when the button is disabled.
  final Color color;

  /// The fill color of the button when the button is disabled.
  ///
  /// The default value of this color is the theme's disabled color,
  /// [ThemeData.disabledColor].
  ///
  /// See also:
  ///   * [color] - the fill color of the button when the button is [enabled].
  final Color disabledColor;

  /// The splash color of the button's [InkWell].
  ///
  /// The ink splash indicates that the button has been touched. It
  /// appears on top of the button's child and spreads in an expanding
  /// circle beginning where the touch occurred.
  ///
  /// The default splash color is the current theme's splash color,
  /// [ThemeData.splashColor].
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

  /// The z-coordinate at which to place this button. This controls the size of
  /// the shadow below the raised button.
  ///
  /// Defaults to 2, the appropriate elevation for raised buttons.
  ///
  /// See also:
  ///
  ///  * [FlatButton], a button with no elevation or fill color.
  ///  * [disabledElevation], the elevation when the button is disabled.
  ///  * [highlightElevation], the elevation when the button is pressed.
  final double elevation;

  /// The elevation for the button's [Material] when the button
  /// is [enabled] but not pressed.
  ///
  /// Defaults to 2.0.
  ///
  /// See also:
  ///
  ///  * [highlightElevation], the default elevation.
  ///  * [disabledElevation], the elevation when the button is disabled.

  /// The elevation for the button's [Material] when the button
  /// is [enabled] and pressed.
  ///
  /// This controls the size of the shadow below the button. When a tap
  /// down gesture occurs within the button, its [InkWell] displays a
  /// [highlightColor] "highlight".
  ///
  /// Defaults to 8.0.
  ///
  /// See also:
  ///
  ///  * [elevation], the default elevation.
  ///  * [disabledElevation], the elevation when the button is disabled.
  final double highlightElevation;

  /// The elevation for the button's [Material] when the button
  /// is not [enabled].
  ///
  /// Defaults to 0.0.
  ///
  /// See also:
  ///
  ///  * [elevation], the default elevation.
  ///  * [highlightElevation], the elevation when the button is pressed.
  final double disabledElevation;

  /// The theme brightness to use for this button.
  ///
  /// Defaults to the theme's brightness, [ThemeData.brightness].
  final Brightness colorBrightness;

  /// The button's label.
  ///
  /// Often a [Text] widget in all caps.
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

  /// Defines the duration of animated changes for [shape] and [elevation].
  ///
  /// The default value is [kThemeChangeDuration].
  final Duration animationDuration;

  Brightness _getBrightness(ThemeData theme) {
    return colorBrightness ?? theme.brightness;
  }

  ButtonTextTheme _getTextTheme(ButtonThemeData buttonTheme) {
    return textTheme ?? buttonTheme.textTheme;
  }

  Color _getFillColor(ThemeData theme, ButtonThemeData buttonTheme) {
    final Color fillColor = enabled ? color : disabledColor;
    if (fillColor != null)
      return fillColor;

    final bool themeIsDark = _getBrightness(theme) == Brightness.dark;
    switch (_getTextTheme(buttonTheme)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return enabled
          ? theme.buttonColor
          : theme.disabledColor;
      case ButtonTextTheme.primary:
        return enabled
          ? theme.buttonColor
          : (themeIsDark ? Colors.white12 : Colors.black12);
    }
    return null;
  }

  Color _getTextColor(ThemeData theme, ButtonThemeData buttonTheme, Color fillColor) {
    final Color color = enabled ? textColor : disabledTextColor;
    if (color != null)
      return color;

    final bool themeIsDark = _getBrightness(theme) == Brightness.dark;
    final bool fillIsDark = fillColor != null
      ? ThemeData.estimateBrightnessForColor(fillColor) == Brightness.dark
      : themeIsDark;

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
          ? (fillIsDark ? Colors.white : Colors.black)
          : (themeIsDark ? Colors.white30 : Colors.black38);
    }
    return null;
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
    final Color fillColor = _getFillColor(theme, buttonTheme);
    final Color textColor = _getTextColor(theme, buttonTheme, fillColor);

    return new RawMaterialButton(
      onPressed: onPressed,
      onHighlightChanged: onHighlightChanged,
      fillColor: fillColor,
      textStyle: theme.textTheme.button.copyWith(color: textColor),
      highlightColor: _getHighlightColor(theme, buttonTheme),
      splashColor: splashColor ?? theme.splashColor,
      elevation: elevation,
      highlightElevation: highlightElevation,
      disabledElevation: disabledElevation,
      padding: padding ?? buttonTheme.padding,
      constraints: buttonTheme.constraints,
      shape: shape ?? buttonTheme.shape,
      animationDuration: animationDuration,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new ObjectFlagProperty<VoidCallback>('onPressed', onPressed, ifNull: 'disabled'));
    properties.add(new DiagnosticsProperty<Color>('textColor', textColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('disabledTextColor', disabledTextColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('disabledColor', disabledColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('highlightColor', highlightColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('splashColor', splashColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Brightness>('colorBrightness', colorBrightness, defaultValue: null));
    properties.add(new DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(new DiagnosticsProperty<double>('highlightElevation', highlightElevation, defaultValue: null));
    properties.add(new DiagnosticsProperty<double>('disabledElevation', disabledElevation, defaultValue: null));
    properties.add(new DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(new DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}
