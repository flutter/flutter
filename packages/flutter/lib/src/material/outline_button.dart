// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'material_button.dart';
import 'material_state.dart';
import 'raised_button.dart';
import 'theme.dart';
import 'theme_data.dart';

// The total time to make the button's fill color opaque and change
// its elevation. Only applies when highlightElevation > 0.0.
const Duration _kPressDuration = Duration(milliseconds: 150);

// Half of _kPressDuration: just the time to change the button's
// elevation. Only applies when highlightElevation > 0.0.
const Duration _kElevationDuration = Duration(milliseconds: 75);

/// Similar to a [FlatButton] with a thin grey rounded rectangle border.
///
/// ### This class is obsolete, please use [OutlinedButton] instead.
///
/// FlatButton, RaisedButton, and OutlineButton have been replaced by
/// TextButton, ElevatedButton, and OutlinedButton respectively.
/// ButtonTheme has been replaced by TextButtonTheme,
/// ElevatedButtonTheme, and OutlinedButtonTheme. The original classes
/// will be deprecated soon, please migrate code that uses them.
/// There's a detailed migration guide for the new button and button
/// theme classes in
/// [flutter.dev/go/material-button-migration-guide](https://flutter.dev/go/material-button-migration-guide).
///
/// The outline button's border shape is defined by [shape]
/// and its appearance is defined by [borderSide], [disabledBorderColor],
/// and [highlightedBorderColor]. By default the border is a one pixel
/// wide grey rounded rectangle that does not change when the button is
/// pressed or disabled. By default the button's background is transparent.
///
/// If the [onPressed] or [onLongPress] callbacks are null, then the button will be disabled and by
/// default will resemble a flat button in the [disabledColor].
///
/// The button's [highlightElevation], which defines the size of the
/// drop shadow when the button is pressed, is 0.0 (no shadow) by default.
/// If [highlightElevation] is given a value greater than 0.0 then the button
/// becomes a cross between [RaisedButton] and [FlatButton]: a bordered
/// button whose elevation increases and whose background becomes opaque
/// when the button is pressed.
///
/// If you want an ink-splash effect for taps, but don't want to use a button,
/// consider using [InkWell] directly.
///
/// Outline buttons have a minimum size of 88.0 by 36.0 which can be overridden
/// with [ButtonTheme].
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// Here is an example of a basic [OutlineButton].
///
/// ```dart
///   Widget build(BuildContext context) {
///     return OutlineButton(
///       onPressed: () {
///         print('Received click');
///       },
///       child: Text('Click Me'),
///     );
///   }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RaisedButton], a filled material design button with a shadow.
///  * [FlatButton], a material design button without a shadow.
///  * [DropdownButton], a button that shows options to select from.
///  * [FloatingActionButton], the round button in material applications.
///  * [IconButton], to create buttons that just contain icons.
///  * [InkWell], which implements the ink splash part of a flat button.
///  * <https://material.io/design/components/buttons.html>
class OutlineButton extends MaterialButton {
  /// Create an outline button.
  ///
  /// The [highlightElevation] argument must be null or a positive value
  /// and the [autofocus] and [clipBehavior] arguments must not be null.
  const OutlineButton({
    Key key,
    @required VoidCallback onPressed,
    VoidCallback onLongPress,
    MouseCursor mouseCursor,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    double highlightElevation,
    this.borderSide,
    this.disabledBorderColor,
    this.highlightedBorderColor,
    EdgeInsetsGeometry padding,
    VisualDensity visualDensity,
    ShapeBorder shape,
    Clip clipBehavior = Clip.none,
    FocusNode focusNode,
    bool autofocus = false,
    MaterialTapTargetSize materialTapTargetSize,
    Widget child,
  }) : assert(highlightElevation == null || highlightElevation >= 0.0),
       assert(clipBehavior != null),
       assert(autofocus != null),
       super(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         mouseCursor: mouseCursor,
         textTheme: textTheme,
         textColor: textColor,
         disabledTextColor: disabledTextColor,
         color: color,
         focusColor: focusColor,
         hoverColor: hoverColor,
         highlightColor: highlightColor,
         splashColor: splashColor,
         highlightElevation: highlightElevation,
         padding: padding,
         visualDensity: visualDensity,
         shape: shape,
         clipBehavior: clipBehavior,
         focusNode: focusNode,
         materialTapTargetSize: materialTapTargetSize,
         autofocus: autofocus,
         child: child,
       );

  /// Create an outline button from a pair of widgets that serve as the button's
  /// [icon] and [label].
  ///
  /// The icon and label are arranged in a row and padded by 12 logical pixels
  /// at the start, and 16 at the end, with an 8 pixel gap in between.
  ///
  /// The [highlightElevation] argument must be null or a positive value. The
  /// [icon], [label], [autofocus], and [clipBehavior] arguments must not be null.
  factory OutlineButton.icon({
    Key key,
    @required VoidCallback onPressed,
    VoidCallback onLongPress,
    MouseCursor mouseCursor,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    double highlightElevation,
    Color highlightedBorderColor,
    Color disabledBorderColor,
    BorderSide borderSide,
    EdgeInsetsGeometry padding,
    VisualDensity visualDensity,
    ShapeBorder shape,
    Clip clipBehavior,
    FocusNode focusNode,
    bool autofocus,
    MaterialTapTargetSize materialTapTargetSize,
    @required Widget icon,
    @required Widget label,
  }) = _OutlineButtonWithIcon;

  /// The outline border's color when the button is [enabled] and pressed.
  ///
  /// By default the border's color does not change when the button
  /// is pressed.
  ///
  /// This field is ignored if [BorderSide.color] is a [MaterialStateProperty<Color>].
  final Color highlightedBorderColor;

  /// The outline border's color when the button is not [enabled].
  ///
  /// By default the outline border's color does not change when the
  /// button is disabled.
  ///
  /// This field is ignored if [BorderSide.color] is a [MaterialStateProperty<Color>].
  final Color disabledBorderColor;

  /// Defines the color of the border when the button is enabled but not
  /// pressed, and the border outline's width and style in general.
  ///
  /// If the border side's [BorderSide.style] is [BorderStyle.none], then
  /// an outline is not drawn.
  ///
  /// If null the default border's style is [BorderStyle.solid], its
  /// [BorderSide.width] is 1.0, and its color is a light shade of grey.
  ///
  /// If [BorderSide.color] is a [MaterialStateProperty<Color>], [MaterialStateProperty.resolve]
  /// is used in all states and both [highlightedBorderColor] and [disabledBorderColor]
  /// are ignored.
  final BorderSide borderSide;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    return _OutlineButton(
      autofocus: autofocus,
      onPressed: onPressed,
      onLongPress: onLongPress,
      mouseCursor: mouseCursor,
      brightness: buttonTheme.getBrightness(this),
      textTheme: textTheme,
      textColor: buttonTheme.getTextColor(this),
      disabledTextColor: buttonTheme.getDisabledTextColor(this),
      color: color,
      focusColor: buttonTheme.getFocusColor(this),
      hoverColor: buttonTheme.getHoverColor(this),
      highlightColor: buttonTheme.getHighlightColor(this),
      splashColor: buttonTheme.getSplashColor(this),
      highlightElevation: buttonTheme.getHighlightElevation(this),
      borderSide: borderSide,
      disabledBorderColor: disabledBorderColor,
      highlightedBorderColor: highlightedBorderColor ?? buttonTheme.colorScheme.primary,
      padding: buttonTheme.getPadding(this),
      visualDensity: visualDensity,
      shape: buttonTheme.getShape(this),
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      materialTapTargetSize: materialTapTargetSize,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BorderSide>('borderSide', borderSide, defaultValue: null));
    properties.add(ColorProperty('disabledBorderColor', disabledBorderColor, defaultValue: null));
    properties.add(ColorProperty('highlightedBorderColor', highlightedBorderColor, defaultValue: null));
  }
}

// The type of OutlineButtons created with OutlineButton.icon.
//
// This class only exists to give OutlineButtons created with OutlineButton.icon
// a distinct class for the sake of ButtonTheme. It can not be instantiated.
class _OutlineButtonWithIcon extends OutlineButton with MaterialButtonWithIconMixin {
  _OutlineButtonWithIcon({
    Key key,
    @required VoidCallback onPressed,
    VoidCallback onLongPress,
    MouseCursor mouseCursor,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    double highlightElevation,
    Color highlightedBorderColor,
    Color disabledBorderColor,
    BorderSide borderSide,
    EdgeInsetsGeometry padding,
    VisualDensity visualDensity,
    ShapeBorder shape,
    Clip clipBehavior = Clip.none,
    FocusNode focusNode,
    bool autofocus = false,
    MaterialTapTargetSize materialTapTargetSize,
    @required Widget icon,
    @required Widget label,
  }) : assert(highlightElevation == null || highlightElevation >= 0.0),
       assert(clipBehavior != null),
       assert(autofocus != null),
       assert(icon != null),
       assert(label != null),
       super(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         mouseCursor: mouseCursor,
         textTheme: textTheme,
         textColor: textColor,
         disabledTextColor: disabledTextColor,
         color: color,
         focusColor: focusColor,
         hoverColor: hoverColor,
         highlightColor: highlightColor,
         splashColor: splashColor,
         highlightElevation: highlightElevation,
         disabledBorderColor: disabledBorderColor,
         highlightedBorderColor: highlightedBorderColor,
         borderSide: borderSide,
         padding: padding,
         visualDensity: visualDensity,
         shape: shape,
         clipBehavior: clipBehavior,
         focusNode: focusNode,
         autofocus: autofocus,
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
    this.onLongPress,
    this.mouseCursor,
    this.brightness,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    @required this.highlightElevation,
    this.borderSide,
    this.disabledBorderColor,
    @required this.highlightedBorderColor,
    this.padding,
    this.visualDensity,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.child,
    this.materialTapTargetSize,
  }) : assert(highlightElevation != null && highlightElevation >= 0.0),
       assert(highlightedBorderColor != null),
       assert(clipBehavior != null),
       assert(autofocus != null),
       super(key: key);

  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final MouseCursor mouseCursor;
  final Brightness brightness;
  final ButtonTextTheme textTheme;
  final Color textColor;
  final Color disabledTextColor;
  final Color color;
  final Color splashColor;
  final Color focusColor;
  final Color hoverColor;
  final Color highlightColor;
  final double highlightElevation;
  final BorderSide borderSide;
  final Color disabledBorderColor;
  final Color highlightedBorderColor;
  final EdgeInsetsGeometry padding;
  final VisualDensity visualDensity;
  final ShapeBorder shape;
  final Clip clipBehavior;
  final FocusNode focusNode;
  final bool autofocus;
  final Widget child;
  final MaterialTapTargetSize materialTapTargetSize;

  bool get enabled => onPressed != null || onLongPress != null;

  @override
  _OutlineButtonState createState() => _OutlineButtonState();
}


class _OutlineButtonState extends State<_OutlineButton> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _fillAnimation;
  Animation<double> _elevationAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    // When highlightElevation > 0.0, the Material widget animates its
    // shape (which includes the outline border) and elevation over
    // _kElevationDuration. When pressed, the button makes its fill
    // color opaque white first, and then sets its
    // highlightElevation. We can't change the elevation while the
    // button's fill is translucent, because the shadow fills the
    // interior of the button.

    _controller = AnimationController(
      duration: _kPressDuration,
      vsync: this,
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _elevationAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.5),
      reverseCurve: const Interval(1.0, 1.0),
    );
  }

  @override
  void didUpdateWidget(_OutlineButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pressed && !widget.enabled) {
      _pressed = false;
      _controller.reverse();
    }
  }

  void _handleHighlightChanged(bool value) {
    if (_pressed == value)
      return;
    setState(() {
      _pressed = value;
      if (value)
        _controller.forward();
      else
        _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getFillColor() {
    if (widget.highlightElevation == null || widget.highlightElevation == 0.0)
      return Colors.transparent;
    final Color color = widget.color ?? Theme.of(context).canvasColor;
    final Tween<Color> colorTween = ColorTween(
      begin: color.withAlpha(0x00),
      end: color.withAlpha(0xFF),
    );
    return colorTween.evaluate(_fillAnimation);
  }

  Color get _outlineColor {
    // If outline color is a `MaterialStateProperty`, it will be used in all
    // states, otherwise we determine the outline color in the current state.
    if (widget.borderSide?.color is MaterialStateProperty<Color>)
      return widget.borderSide.color;
    if (!widget.enabled)
      return widget.disabledBorderColor;
    if (_pressed)
      return widget.highlightedBorderColor;
    return widget.borderSide?.color;
  }

  BorderSide _getOutline() {
    if (widget.borderSide?.style == BorderStyle.none)
      return widget.borderSide;

    final Color themeColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.12);

    return BorderSide(
      color: _outlineColor ?? themeColor,
      width: widget.borderSide?.width ?? 1.0,
    );
  }

  double _getHighlightElevation() {
    if (widget.highlightElevation == null || widget.highlightElevation == 0.0)
      return 0.0;
    return Tween<double>(
      begin: 0.0,
      end: widget.highlightElevation,
    ).evaluate(_elevationAnimation);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget child) {
        return RaisedButton(
          autofocus: widget.autofocus,
          textColor: widget.textColor,
          disabledTextColor: widget.disabledTextColor,
          color: _getFillColor(),
          splashColor: widget.splashColor,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          highlightColor: widget.highlightColor,
          disabledColor: Colors.transparent,
          onPressed: widget.onPressed,
          onLongPress: widget.onLongPress,
          mouseCursor: widget.mouseCursor,
          elevation: 0.0,
          disabledElevation: 0.0,
          focusElevation: 0.0,
          hoverElevation: 0.0,
          highlightElevation: _getHighlightElevation(),
          onHighlightChanged: _handleHighlightChanged,
          padding: widget.padding,
          visualDensity: widget.visualDensity ?? theme.visualDensity,
          shape: _OutlineBorder(
            shape: widget.shape,
            side: _getOutline(),
          ),
          clipBehavior: widget.clipBehavior,
          focusNode: widget.focusNode,
          animationDuration: _kElevationDuration,
          materialTapTargetSize: widget.materialTapTargetSize,
          child: widget.child,
        );
      },
    );
  }
}

// Render the button's outline border using using the OutlineButton's
// border parameters and the button or buttonTheme's shape.
class _OutlineBorder extends ShapeBorder implements MaterialStateProperty<ShapeBorder>{
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
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is _OutlineBorder
        && other.side == side
        && other.shape == shape;
  }

  @override
  int get hashCode => hashValues(side, shape);

  @override
  ShapeBorder resolve(Set<MaterialState> states) {
    return _OutlineBorder(
      shape: shape,
      side: side.copyWith(color: MaterialStateProperty.resolveAs<Color>(side.color, states),
    ));
  }
}
