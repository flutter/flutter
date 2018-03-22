// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'raised_button.dart';
import 'theme.dart';

// The total time to make the button's fill color opaque and change
// its elevation.
const Duration _kPressDuration = const Duration(milliseconds: 150);

// Half of _kPressDuration: just the time to change the button's
// elevation.
const Duration _kElevationDuration = const Duration(milliseconds: 75);

/// A cross between [RaisedButton] and [FlatButton]: a bordered button whose
/// elevation increases and whose background becomes opaque when the button
/// is pressed.
///
/// An outline button's elevation is initially 0.0 and its background [color]
/// is transparent. When the button is pressed its background becomes opaque
/// and then its elevation increases to [highlightElevation].
///
/// The outline button has a border whose shape is defined by [shape]
/// and whose appearance is defined by [borderSide], [disabledBorderColor],
/// and [highlightedBorderColor].
///
/// If the [onPressed] callback is null, then the button will be disabled and by
/// default will resemble a flat button in the [disabledColor].
///
/// If you want an ink-splash effect for taps, but don't want to use a button,
/// consider using [InkWell] directly.
///
/// Outline buttons have a minimum size of 88.0 by 36.0 which can be overidden
/// with [ButtonTheme].
///
/// See also:
///
///  * [RaisedButton], a filled material design button with a shadow.
///  * [FlatButton], a material design button without a shadow.
///  * [DropdownButton], a button that shows options to select from.
///  * [FloatingActionButton], the round button in material applications.
///  * [IconButton], to create buttons that just contain icons.
///  * [InkWell], which implements the ink splash part of a flat button.
///  * <https://material.google.com/components/buttons.html>
class OutlineButton extends StatefulWidget {
  /// Create a filled button.
  ///
  /// The [highlightElevation], and [borderWidth]
  /// arguments must not be null.
  const OutlineButton({
    Key key,
    @required this.onPressed,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.highlightColor,
    this.splashColor,
    this.highlightElevation: 2.0,
    this.borderSide,
    this.disabledBorderColor,
    this.highlightedBorderColor,
    this.padding,
    this.shape,
    this.child,
  }) : assert(highlightElevation != null && highlightElevation >= 0.0),
       super(key: key);

  /// Create an outline button from a pair of widgets that serve as the button's
  /// [icon] and [label].
  ///
  /// The icon and label are arranged in a row and padded by 12 logical pixels
  /// at the start, and 16 at the end, with an 8 pixel gap in between.
  ///
  /// The [highlightElevation], [icon], and [label] must not be null.
  OutlineButton.icon({
    Key key,
    @required this.onPressed,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.highlightColor,
    this.splashColor,
    this.highlightElevation: 2.0,
    this.borderSide,
    this.disabledBorderColor,
    this.highlightedBorderColor,
    this.shape,
    @required Widget icon,
    @required Widget label,
  }) : assert(highlightElevation != null && highlightElevation >= 0.0),
       assert(icon != null),
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
  ///
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
  ///
  ///  * [textColor], which specifies the color to use for this button's text
  ///    when the button is [enabled].
  final Color disabledTextColor;

  /// The button's opaque fill color when it's [enabled] and has been pressed.
  ///
  /// If null this value defaults to white for light themes (see
  /// [ThemeData.brightness]), and black for dark themes.
  final Color color;

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

  /// The elevation of the button when it's [enabled] and has been pressed.
  ///
  /// If null, this value defaults to 2.0.
  ///
  /// The elevation of an outline button is always 0.0 unless its enabled
  /// and has been pressed.
  final double highlightElevation;

  /// Defines the color of the border when the button is enabled but not
  /// pressed, and the border outline's width and style in general.
  ///
  /// If the border side's [BorderSide.style] is [BorderStyle.none], then
  /// an outline is not drawn.
  ///
  /// If null the default border's style is [BorderStyle.solid], its
  /// [BorderSide.width] is 2.0, and its color is a light shade of grey.
  final BorderSide borderSide;

  /// The outline border's color when the button is [enabled] and pressed.
  ///
  /// If null this value defaults to the theme's primary color,
  /// [ThemeData.primaryColor].
  final Color highlightedBorderColor;

  /// The outline border's color when the button is not [enabled].
  ///
  /// If null this value defaults to a very light shade of grey for light
  /// themes (see [ThemeData.brightness]), and a very dark shade of grey for
  /// dark themes.
  final Color disabledBorderColor;

  /// The internal padding for the button's [child].
  ///
  /// Defaults to the value from the current [ButtonTheme],
  /// [ButtonThemeData.padding].
  final EdgeInsetsGeometry padding;

  /// The shape of the button's [Material] and its outline.
  ///
  /// The button's highlight and splash are clipped to this shape. If the
  /// button has a [highlightElevation], then its drop shadow is defined by this
  /// shape as well.
  final ShapeBorder shape;

  /// The button's label.
  ///
  /// Often a [Text] widget in all caps.
  final Widget child;

  /// Whether the button is enabled or disabled.
  ///
  /// Buttons are disabled by default. To enable a button, set its [onPressed]
  /// property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  _OutlineButtonState createState() => new _OutlineButtonState();


  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new ObjectFlagProperty<VoidCallback>('onPressed', onPressed, ifNull: 'disabled'));
    properties.add(new DiagnosticsProperty<ButtonTextTheme>('textTheme', textTheme, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('textColor', textColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('disabledTextColor', disabledTextColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('highlightColor', highlightColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('splashColor', splashColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<double>('highlightElevation', highlightElevation, defaultValue: 2.0));
    properties.add(new DiagnosticsProperty<BorderSide>('borderSide', borderSide, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('disabledBorderColor', disabledBorderColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<Color>('highlightedBorderColor', highlightedBorderColor, defaultValue: null));
    properties.add(new DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(new DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}

class _OutlineButtonState extends State<OutlineButton> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _fillAnimation;
  Animation<double> _elevationAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    // The Material widget animates its shape (which includes the outline
    // border) and elevation over _kElevationDuration. When pressed, the
    // button makes its fill color opaque white first, and then sets
    // its highlightElevation. We can't change the elevation while the
    // button's fill is translucent, because the shadow fills the interior
    // of the button.

    _controller = new AnimationController(
      duration: _kPressDuration,
      vsync: this
    );
    _fillAnimation = new CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _elevationAnimation = new CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.5),
      reverseCurve: const Interval(1.0, 1.0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ButtonTextTheme _getTextTheme(ButtonThemeData buttonTheme) {
    return widget.textTheme ?? buttonTheme.textTheme;
  }

  // TODO(hmuller): this method is the same as FlatButton
  Color _getTextColor(ThemeData theme, ButtonThemeData buttonTheme) {
    final Color color = widget.enabled ? widget.textColor : widget.disabledTextColor;
    if (color != null)
      return color;

    final bool themeIsDark = theme.brightness == Brightness.dark;
    switch (_getTextTheme(buttonTheme)) {
      case ButtonTextTheme.normal:
        return widget.enabled
          ? (themeIsDark ? Colors.white : Colors.black87)
          : theme.disabledColor;
      case ButtonTextTheme.accent:
        return widget.enabled
          ? theme.accentColor
          : theme.disabledColor;
      case ButtonTextTheme.primary:
        return widget.enabled
          ? theme.buttonColor
          : (themeIsDark ? Colors.white30 : Colors.black38);
    }
    return null;
  }

  Color _getFillColor(ThemeData theme) {
    final bool themeIsDark = theme.brightness == Brightness.dark;
    final Color color = widget.color ?? (themeIsDark
      ? const Color(0x00000000)
      : const Color(0x00FFFFFF));
    final Tween<Color> colorTween = new ColorTween(
      begin: color.withAlpha(0x00),
      end: color.withAlpha(0xFF),
    );
    return colorTween.evaluate(_fillAnimation);
  }

  // TODO(hmuller): this method is the same as FlatButton
  Color _getSplashColor(ThemeData theme, ButtonThemeData buttonTheme) {
    if (widget.splashColor != null)
      return widget.splashColor;

    switch (_getTextTheme(buttonTheme)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return theme.splashColor;
      case ButtonTextTheme.primary:
        return theme.brightness == Brightness.dark
          ? Colors.white12
          : theme.primaryColor.withOpacity(0.12);
    }
    return Colors.transparent;
  }

  BorderSide _getOutline(ThemeData theme, ButtonThemeData buttonTheme) {
    final bool themeIsDark = theme.brightness == Brightness.dark;
    if (widget.borderSide?.style == BorderStyle.none)
      return widget.borderSide;

    final Color color = widget.enabled
      ? (_pressed
         ? widget.highlightedBorderColor ?? theme.primaryColor
         : (widget.borderSide?.color ??
            (themeIsDark ? Colors.grey[600] : Colors.grey[200])))
      : (widget.disabledBorderColor ??
         (themeIsDark ? Colors.grey[800] : Colors.grey[100]));

    return new BorderSide(
      color: color,
      width: widget.borderSide?.width ?? 2.0,
    );
  }

  double _getHighlightElevation() {
    return new Tween<double>(
      begin: 0.0,
      end: widget.highlightElevation ?? 2.0,
    ).evaluate(_elevationAnimation);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    final Color textColor = _getTextColor(theme, buttonTheme);
    final Color splashColor = _getSplashColor(theme, buttonTheme);

    return new AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget child) {
        return new RaisedButton(
          textColor: textColor,
          disabledTextColor: widget.disabledTextColor,
          color: _getFillColor(theme),
          splashColor: splashColor,
          highlightColor: widget.highlightColor,
          disabledColor: Colors.transparent,
          onPressed: widget.onPressed,
          elevation: 0.0,
          disabledElevation: 0.0,
          highlightElevation: _getHighlightElevation(),
          onHighlightChanged: (bool value) {
            setState(() {
              _pressed = value;
              if (value)
                _controller.forward();
              else
                _controller.reverse();
            });
          },
          padding: widget.padding,
          shape: new _OutlineBorder(
            shape: widget.shape ?? buttonTheme.shape,
            side: _getOutline(theme, buttonTheme),
          ),
          animationDuration: _kElevationDuration,
          child: widget.child,
        );
      },
    );
  }
}

// Render the button's outline border using using the OutlineButton's
// border parameters and the button or buttonTheme's shape.
class _OutlineBorder extends ShapeBorder {
  const _OutlineBorder({
    @required this.shape,
    @required this.side,
  }) : assert(shape != null),
       assert(side != null);

  final ShapeBorder shape;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) {
    return new _OutlineBorder(
      shape: shape.scale(t),
      side: side.scale(t),
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
    if (a is _OutlineBorder) {
      return new _OutlineBorder(
        side: BorderSide.lerp(a.side, side, t),
        shape: ShapeBorder.lerp(a.shape, shape, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    assert(t != null);
    if (b is _OutlineBorder) {
      return new _OutlineBorder(
        side: BorderSide.lerp(side, b.side, t),
        shape: ShapeBorder.lerp(shape, b.shape, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return shape.getInnerPath(rect.deflate(side.width), textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return shape.getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        canvas.drawPath(shape.getOuterPath(rect), side.toPaint());
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final _OutlineBorder typedOther = other;
    return side == typedOther.side && shape == typedOther.shape;
  }

  @override
  int get hashCode => hashValues(side, shape);
}
