// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'flat_button.dart';
import 'material_button.dart';
import 'theme.dart';
import 'theme_data.dart';

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
class OutlineButton extends MaterialButton {
  /// Create a filled button.
  ///
  /// The [borderWidth], and [clipBehavior] arguments must not be null.
  const OutlineButton({
    Key key,
    @required VoidCallback onPressed,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color highlightColor,
    Color splashColor,
    this.borderSide,
    this.disabledBorderColor,
    this.highlightedBorderColor,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    Clip clipBehavior = Clip.none,
    MaterialTapTargetSize materialTapTargetSize,
    Widget child,
  }) : super(
    key: key,
    onPressed: onPressed,
    textTheme: textTheme,
    textColor: textColor,
    disabledTextColor: disabledTextColor,
    color: color,
    highlightColor: highlightColor,
    splashColor: splashColor,
    padding: padding,
    shape: shape,
    clipBehavior: clipBehavior,
    materialTapTargetSize: materialTapTargetSize,
    child: child,
  );

  /// Create an outline button from a pair of widgets that serve as the button's
  /// [icon] and [label].
  ///
  /// The icon and label are arranged in a row and padded by 12 logical pixels
  /// at the start, and 16 at the end, with an 8 pixel gap in between.
  ///
  /// The [icon], [label], and [clipBehavior] must not be null.
  factory OutlineButton.icon({
    Key key,
    @required VoidCallback onPressed,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color highlightColor,
    Color splashColor,
    Color highlightedBorderColor,
    Color disabledBorderColor,
    BorderSide borderSide,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    Clip clipBehavior,
    MaterialTapTargetSize materialTapTargetSize,
    @required Widget icon,
    @required Widget label,
  }) = _OutlineButtonWithIcon;

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

  /// Defines the color of the border when the button is enabled but not
  /// pressed, and the border outline's width and style in general.
  ///
  /// If the border side's [BorderSide.style] is [BorderStyle.none], then
  /// an outline is not drawn.
  ///
  /// If null the default border's style is [BorderStyle.solid], its
  /// [BorderSide.width] is 2.0, and its color is a light shade of grey.
  final BorderSide borderSide;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    return _OutlineButton(
      onPressed: onPressed,
      brightness: buttonTheme.getBrightness(this),
      textTheme: textTheme,
      textColor: buttonTheme.getTextColor(this),
      disabledTextColor: buttonTheme.getDisabledTextColor(this),
      color: color,
      highlightColor: buttonTheme.getHighlightColor(this),
      splashColor: buttonTheme.getSplashColor(this),
      borderSide: borderSide,
      disabledBorderColor: disabledBorderColor,
      highlightedBorderColor: highlightedBorderColor,
      padding: buttonTheme.getPadding(this),
      shape: buttonTheme.getShape(this),
      clipBehavior: clipBehavior,
      materialTapTargetSize: materialTapTargetSize,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>('onPressed', onPressed, ifNull: 'disabled'));
    properties.add(DiagnosticsProperty<ButtonTextTheme>('textTheme', textTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('textColor', textColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledTextColor', disabledTextColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('highlightColor', highlightColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('splashColor', splashColor, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderSide>('borderSide', borderSide, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledBorderColor', disabledBorderColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('highlightedBorderColor', highlightedBorderColor, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}

// The type of of OutlineButtons created with [OutlineButton.icon].
//
// This class only exists to give RaisedButtons created with [RaisedButton.icon]
// a distinct class for the sake of [ButtonTheme]. It can not be instantiated.
class _OutlineButtonWithIcon extends OutlineButton with MaterialButtonWithIconMixin {
  _OutlineButtonWithIcon({
    Key key,
    @required VoidCallback onPressed,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color highlightColor,
    Color splashColor,
    Color highlightedBorderColor,
    Color disabledBorderColor,
    BorderSide borderSide,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    Clip clipBehavior,
    MaterialTapTargetSize materialTapTargetSize,
    @required Widget icon,
    @required Widget label,
  }) : assert(icon != null),
        assert(label != null),
        super(
        key: key,
        onPressed: onPressed,
        textTheme: textTheme,
        textColor: textColor,
        disabledTextColor: disabledTextColor,
        color: color,
        highlightColor: highlightColor,
        splashColor: splashColor,
        disabledBorderColor: disabledBorderColor,
        highlightedBorderColor: highlightedBorderColor,
        borderSide: borderSide,
        padding: padding,
        shape: shape,
        clipBehavior: clipBehavior,
        materialTapTargetSize: materialTapTargetSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            const SizedBox(width: 8.0),
            label,
          ],
        ),
      );
}

class _OutlineButton extends StatefulWidget {
  const _OutlineButton({
    Key key,
    @required this.onPressed,
    this.brightness,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.highlightColor,
    this.splashColor,
    this.borderSide,
    this.disabledBorderColor,
    this.highlightedBorderColor,
    this.padding,
    this.shape,
    this.clipBehavior,
    this.materialTapTargetSize,
    this.child,
  }) : super(key: key);

  final VoidCallback onPressed;
  final Brightness brightness;
  final ButtonTextTheme textTheme;
  final Color textColor;
  final Color disabledTextColor;
  final Color color;
  final Color splashColor;
  final Color highlightColor;
  final BorderSide borderSide;
  final Color disabledBorderColor;
  final Color highlightedBorderColor;
  final EdgeInsetsGeometry padding;
  final ShapeBorder shape;
  final Clip clipBehavior;
  final MaterialTapTargetSize materialTapTargetSize;
  final Widget child;

  bool get enabled => onPressed != null;

  @override
  _OutlineButtonState createState() => _OutlineButtonState();
}


class _OutlineButtonState extends State<_OutlineButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  BorderSide _getOutline() {
    final bool isDark = widget.brightness == Brightness.dark;
    if (widget.borderSide?.style == BorderStyle.none)
      return widget.borderSide;

    final Color color = (widget.enabled
        ? (_pressed
        ? (widget.highlightedBorderColor ?? widget.borderSide?.color)
        : widget.borderSide?.color)
        : widget.disabledBorderColor) ?? (isDark ? const Color(0x3bffffff) : const Color(0x3b000000));

    return BorderSide(
      color: color,
      width: widget.borderSide?.width ?? 1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      textColor: widget.textColor,
      disabledTextColor: widget.disabledTextColor,
      color: widget.color,
      splashColor: widget.splashColor,
      highlightColor: widget.highlightColor,
      disabledColor: Colors.transparent,
      onPressed: widget.onPressed,
      onHighlightChanged: (bool value) {
        setState(() {
          _pressed = value;
        });
      },
      padding: widget.padding,
      shape: _OutlineBorder(
        shape: widget.shape,
        side: _getOutline(),
      ),
      clipBehavior: widget.clipBehavior,
      materialTapTargetSize: widget.materialTapTargetSize,
      child: widget.child,
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
    return EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) {
    return _OutlineBorder(
      shape: shape.scale(t),
      side: side.scale(t),
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
    if (a is _OutlineBorder) {
      return _OutlineBorder(
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
      return _OutlineBorder(
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
        canvas.drawPath(shape.getOuterPath(rect, textDirection: textDirection), side.toPaint());
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
