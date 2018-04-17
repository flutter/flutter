// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'constants.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

/// Creates a button based on [Semantics], [Material], and [InkWell]
/// widgets.
///
/// This class does not use the current [Theme] or [ButtonTheme] to
/// compute default values for unspecified parameters. It's intended to
/// be used for custom Material buttons that optionally incorporate defaults
/// from the themes or from app-specific sources.
///
/// [RaisedButton] and [FlatButton] configure a [RawMaterialButton] based
/// on the current [Theme] and [ButtonTheme].
class RawMaterialButton extends StatefulWidget {
  /// Create a button based on [Semantics], [Material], and [InkWell] widgets.
  ///
  /// The [shape], [elevation], [padding], and [constraints] arguments
  /// must not be null.
  const RawMaterialButton({
    Key key,
    @required this.onPressed,
    this.onHighlightChanged,
    this.textStyle,
    this.fillColor,
    this.highlightColor,
    this.splashColor,
    this.elevation: 2.0,
    this.highlightElevation: 8.0,
    this.disabledElevation: 0.0,
    this.padding: EdgeInsets.zero,
    this.constraints: const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
    this.shape: const RoundedRectangleBorder(),
    this.animationDuration: kThemeChangeDuration,
    this.child,
  }) : assert(shape != null),
       assert(elevation != null),
       assert(highlightElevation != null),
       assert(disabledElevation != null),
       assert(padding != null),
       assert(constraints != null),
       assert(animationDuration != null),
       super(key: key);

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled, see [enabled].
  final VoidCallback onPressed;

  /// Called by the underlying [InkWell] widget's [InkWell.onHighlightChanged]
  /// callback.
  final ValueChanged<bool> onHighlightChanged;

  /// Defines the default text style, with [Material.textStyle], for the
  /// button's [child].
  final TextStyle textStyle;

  /// The color of the button's [Material].
  final Color fillColor;

  /// The highlight color for the button's [InkWell].
  final Color highlightColor;

  /// The splash color for the button's [InkWell].
  final Color splashColor;

  /// The elevation for the button's [Material] when the button
  /// is [enabled] but not pressed.
  ///
  /// Defaults to 2.0.
  ///
  /// See also:
  ///
  ///  * [highlightElevation], the default elevation.
  ///  * [disabledElevation], the elevation when the button is disabled.
  final double elevation;

  /// The elevation for the button's [Material] when the button
  /// is [enabled] and pressed.
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
  ///  * [elevation], the default elevation.
  ///  * [highlightElevation], the elevation when the button is pressed.
  final double disabledElevation;

  /// The internal padding for the button's [child].
  final EdgeInsetsGeometry padding;

  /// Defines the button's size.
  ///
  /// Typically used to constrain the button's minimum size.
  final BoxConstraints constraints;

  /// The shape of the button's [Material].
  ///
  /// The button's highlight and splash are clipped to this shape. If the
  /// button has an elevation, then its drop shadow is defined by this shape.
  final ShapeBorder shape;

  /// Defines the duration of animated changes for [shape] and [elevation].
  ///
  /// The default value is [kThemeChangeDuration].
  final Duration animationDuration;

  /// Typically the button's label.
  final Widget child;

  /// Whether the button is enabled or disabled.
  ///
  /// Buttons are disabled by default. To enable a button, set its [onPressed]
  /// property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  _RawMaterialButtonState createState() => new _RawMaterialButtonState();
}

class _RawMaterialButtonState extends State<RawMaterialButton> {
  bool _highlight = false;
  void _handleHighlightChanged(bool value) {
    setState(() {
      _highlight = value;
      if (widget.onHighlightChanged != null)
        widget.onHighlightChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double elevation = widget.enabled
      ? (_highlight ? widget.highlightElevation : widget.elevation)
      : widget.disabledElevation;

    return new Semantics(
      container: true,
      button: true,
      enabled: widget.enabled,
      child: new ConstrainedBox(
        constraints: widget.constraints,
        child: new Material(
          elevation: elevation,
          textStyle: widget.textStyle,
          shape: widget.shape,
          color: widget.fillColor,
          type: widget.fillColor == null ? MaterialType.transparency : MaterialType.button,
          animationDuration: widget.animationDuration,
          child: new InkWell(
            onHighlightChanged: _handleHighlightChanged,
            splashColor: widget.splashColor,
            highlightColor: widget.highlightColor,
            onTap: widget.onPressed,
            child: IconTheme.merge(
              data: new IconThemeData(color: widget.textStyle?.color),
              child: new Container(
                padding: widget.padding,
                child: new Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A utility class for building Material buttons that depend on the
/// ambient [ButtonTheme] and [Theme].
///
/// The button's size will expand to fit the child widget, if necessary.
///
/// MaterialButtons whose [onPressed] handler is null will be disabled. To have
/// an enabled button, make sure to pass a non-null value for onPressed.
///
/// Rather than using this class directly, consider using [FlatButton] or
/// [RaisedButton], which configure this class with appropriate defaults that
/// match the material design specification.
///
/// To create a button directly, without inheriting theme defaults, use
/// [RawMaterialButton].
///
/// If you want an ink-splash effect for taps, but don't want to use a button,
/// consider using [InkWell] directly.
///
/// See also:
///
///  * [IconButton], to create buttons that contain icons rather than text.
class MaterialButton extends StatelessWidget {
  /// Creates a material button.
  ///
  /// Rather than creating a material button directly, consider using
  /// [FlatButton] or [RaisedButton]. To create a custom Material button
  /// consider using [RawMaterialButton].
  const MaterialButton({
    Key key,
    this.colorBrightness,
    this.textTheme,
    this.textColor,
    this.color,
    this.highlightColor,
    this.splashColor,
    this.elevation,
    this.highlightElevation,
    this.minWidth,
    this.height,
    this.padding,
    @required this.onPressed,
    this.child
  }) : super(key: key);

  /// The theme brightness to use for this button.
  ///
  /// Defaults to the brightness from [ThemeData.brightness].
  final Brightness colorBrightness;

  /// Defines the button's base colors, and the defaults for the button's minimum
  /// size, internal padding, and shape.
  final ButtonTextTheme textTheme;

  /// The color to use for this button's text.
  final Color textColor;

  /// The button's fill color, displayed by its [Material], while the button
  /// is in its default (unpressed, enabled) state.
  ///
  /// Defaults to null, meaning that the color is automatically derived from the [Theme].
  ///
  /// Typically, a material design color will be used, as follows:
  ///
  /// ```dart
  ///  new MaterialButton(
  ///    color: Colors.blue[500],
  ///    onPressed: _handleTap,
  ///    child: new Text('DEMO'),
  ///  ),
  /// ```
  final Color color;

  /// The primary color of the button when the button is in the down (pressed)
  /// state.
  ///
  /// The splash is represented as a circular overlay that appears above the
  /// [highlightColor] overlay. The splash overlay has a center point that
  /// matches the hit point of the user touch event. The splash overlay will
  /// expand to fill the button area if the touch is held for long enough time.
  /// If the splash color has transparency then the highlight and button color
  /// will show through.
  ///
  /// Defaults to the Theme's splash color, [ThemeData.splashColor].
  final Color splashColor;

  /// The secondary color of the button when the button is in the down (pressed)
  /// state.
  ///
  /// The highlight color is represented as a solid color that is overlaid over
  /// the button color (if any). If the highlight color has transparency, the
  /// button color will show through. The highlight fades in quickly as the
  /// button is held down.
  ///
  /// Defaults to the Theme's highlight color, [ThemeData.highlightColor].
  final Color highlightColor;

  /// The z-coordinate at which to place this button. This controls the size of
  /// the shadow below the button.
  ///
  /// Defaults to 0.
  ///
  /// See also:
  ///
  ///  * [FlatButton], a material button specialized for the case where the
  ///    elevation is zero.
  ///  * [RaisedButton], a material button specialized for the case where the
  ///    elevation is non-zero.
  final double elevation;

  /// The z-coordinate at which to place this button when highlighted. This
  /// controls the size of the shadow below the button.
  ///
  /// Defaults to 0.
  ///
  /// See also:
  ///
  ///  * [elevation], the default elevation.
  final double highlightElevation;

  /// The smallest horizontal extent that the button will occupy.
  ///
  /// Defaults to the value from the current [ButtonTheme].
  final double minWidth;

  /// The vertical extent of the button.
  ///
  /// Defaults to the value from the current [ButtonTheme].
  final double height;

  /// The internal padding for the button's [child].
  ///
  /// Defaults to the value from the current [ButtonTheme],
  /// [ButtonThemeData.padding].
  final EdgeInsetsGeometry padding;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  Brightness _getBrightness(ThemeData theme) {
    return colorBrightness ?? theme.brightness;
  }

  ButtonTextTheme _getTextTheme(ButtonThemeData buttonTheme) {
    return textTheme ?? buttonTheme.textTheme;
  }

  Color _getTextColor(ThemeData theme, ButtonThemeData buttonTheme, Color fillColor) {
    if (textColor != null)
      return textColor;

    final bool themeIsDark = _getBrightness(theme) == Brightness.dark;
    final bool fillIsDark = fillColor != null
      ? ThemeData.estimateBrightnessForColor(fillColor) == Brightness.dark
      : themeIsDark;

    switch (_getTextTheme(buttonTheme)) {
      case ButtonTextTheme.normal:
        return enabled
          ? (themeIsDark ? Colors.white : Colors.black87)
          : (themeIsDark ? Colors.white30 : Colors.black26);
      case ButtonTextTheme.accent:
        return enabled
          ? theme.accentColor
          : (themeIsDark ? Colors.white30 : Colors.black26);
      case ButtonTextTheme.primary:
        return enabled
          ? (fillIsDark ? Colors.white : Colors.black)
          : (themeIsDark ? Colors.white30 : Colors.black38);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    final Color textColor = _getTextColor(theme, buttonTheme, color);

    return new RawMaterialButton(
      onPressed: onPressed,
      fillColor: color,
      textStyle: theme.textTheme.button.copyWith(color: textColor),
      highlightColor: highlightColor ?? theme.highlightColor,
      splashColor: splashColor ?? theme.splashColor,
      elevation: elevation ?? 2.0,
      highlightElevation: highlightElevation ?? 8.0,
      padding: padding ?? buttonTheme.padding,
      constraints: buttonTheme.constraints.copyWith(
        minWidth: minWidth,
        minHeight: height,
      ),
      shape: buttonTheme.shape,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}
