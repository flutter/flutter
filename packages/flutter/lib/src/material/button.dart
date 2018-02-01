// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

/// Creates a button based on [Semantics], [Material], and [InkWell].
///
/// [RaisedButton] and [FlatButton] configure a [ShapedMaterialButton] based
/// on the current [Theme] and [ButtonTheme].
class ShapedMaterialButton extends StatelessWidget {
  /// Create a button based on [Semantics], [Material], and [InkWell].
  ///
  /// The [borderRadius], [elevation], [padding], and [constraints] arguments
  /// must not be null.
  const ShapedMaterialButton({
    Key key,
    @required this.onPressed,
    this.textStyle,
    this.fillColor,
    this.highlightColor,
    this.splashColor,
    this.elevation: 0.0,
    this.padding: EdgeInsets.zero,
    this.onHighlightChanged,
    this.constraints: const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
    this.borderRadius: BorderRadius.zero,
    this.child
  }) : assert(borderRadius != null),
       assert(elevation != null),
       assert(padding != null),
       assert(constraints != null),
       super(key: key);

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled, see [enabled].
  final VoidCallback onPressed;

  /// Defines the default text style, with [Material.textStyle], for the
  /// button's [child].
  final TextStyle textStyle;

  /// The color of the button's [Material].
  final Color fillColor;

  /// The highlight color for the button's [InkWell].
  final Color highlightColor;

  /// The splash color for the button's [InkWell].
  final Color splashColor;

  /// The elevation for the button's [Material].
  final double elevation;

  /// The internal padding for the button's [child].
  final EdgeInsetsGeometry padding;

  /// Called when a tap-down gesture is detected.
  ///
  /// Typically used to configure the button's elevation.
  final ValueChanged<bool> onHighlightChanged;

  /// Defines the button's size.
  ///
  /// Typically used to constrain the button's minimum size.
  final BoxConstraints constraints;

  /// The shape of the button's [Material].
  ///
  /// The button's highlight and splash are clipped to this shape. If the
  /// button has an elevation, then its drop shadow is defined by this
  /// shape as well.
  final BorderRadius borderRadius;

  /// Typically the button's label.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      child: new ConstrainedBox(
        constraints: constraints,
        child: new Material(
          elevation: elevation,
          textStyle: textStyle,
          borderRadius: borderRadius,
          color: fillColor,
          child: new InkWell(
            onHighlightChanged: onHighlightChanged,
            borderRadius: borderRadius,
            splashColor: splashColor,
            highlightColor: highlightColor,
            onTap: onPressed,
            child: IconTheme.merge(
              data: new IconThemeData(color: textStyle?.color),
              child: new Container(
                padding: padding,
                child: new Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: child,
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
/// [ShapedMaterialButton].
///
/// If you want an ink-splash effect for taps, but don't want to use a button,
/// consider using [InkWell] directly.
///
/// See also:
///
///  * [IconButton], to create buttons that contain icons rather than text.
class MaterialButton extends StatefulWidget {
  /// Creates a material button.
  ///
  /// Rather than creating a material button directly, consider using
  /// [FlatButton] or [RaisedButton].
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

  /// The the button's fill color, displayed by its [Material], while the button
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

  @override
  _MaterialButtonState createState() => new _MaterialButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _MaterialButtonState extends State<MaterialButton> {
  bool _highlight = false;

  Brightness _getBrightness(ThemeData theme) {
    return widget.colorBrightness ?? theme.brightness;
  }

  ButtonTextTheme _getTextTheme(ButtonThemeData buttonTheme) {
    return widget.textTheme ?? buttonTheme.textTheme;
  }

  Color _getTextColor(ThemeData theme, ButtonThemeData buttonTheme, Color fillColor) {
    if (widget.textColor != null)
      return widget.textColor;

    final bool enabled = widget.enabled;
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

  void _handleHighlightChanged(bool value) {
    setState(() {
      _highlight = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    final Color textColor = _getTextColor(theme, buttonTheme, widget.color);

    return new ShapedMaterialButton(
      onPressed: widget.onPressed,
      fillColor: widget.color,
      textStyle: theme.textTheme.button.copyWith(color: textColor),
      highlightColor: widget.highlightColor ?? theme.highlightColor,
      splashColor: widget.splashColor ?? theme.splashColor,
      elevation: (_highlight ? widget.highlightElevation : widget.elevation) ?? 0.0,
      padding: widget.padding ?? buttonTheme.padding,
      onHighlightChanged: _handleHighlightChanged,
      constraints: buttonTheme.constraints.copyWith(
        minWidth: widget.minWidth,
        minHeight: widget.height,
      ),
      borderRadius: buttonTheme.borderRadius,
      child: widget.child,
    );
  }
}
