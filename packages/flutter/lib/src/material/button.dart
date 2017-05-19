// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'flat_button.dart';
import 'ink_well.dart';
import 'material.dart';
import 'raised_button.dart';
import 'theme.dart';

/// Whether a button should use the accent color for its text.
///
/// See also:
///
///  * [ButtonTheme], which uses this enum to define the [ButtonTheme.textTheme].
///  * [RaisedButton], which styles itself based on the ambient [ButtonTheme].
///  * [FlatButton], which styles itself based on the ambient [ButtonTheme].
enum ButtonTextTheme {
  /// The button should use the normal color (e.g., black or white depending on the [ThemeData.brightness]) for its text.
  normal,

  /// The button should use the accent color (e.g., [ThemeData.accentColor]) for its text.
  accent,
}

/// Defines the button color used by a widget subtree.
///
/// See also:
///
///  * [ButtonTextTheme], which is used by [textTheme].
///  * [RaisedButton], which styles itself based on the ambient [ButtonTheme].
///  * [FlatButton], which styles itself based on the ambient [ButtonTheme].
class ButtonTheme extends InheritedWidget {
  /// Creates a button theme.
  ///
  /// The child argument is required.
  const ButtonTheme({
    Key key,
    this.textTheme: ButtonTextTheme.normal,
    this.minWidth: 88.0,
    this.height: 36.0,
    this.padding: const EdgeInsets.symmetric(horizontal: 16.0),
    Widget child
  }) : super(key: key, child: child);

  /// Creates a button theme that is appropriate for button bars, as used in
  /// dialog footers and in the headers of data tables.
  ///
  /// This theme is denser, with a smaller [minWidth] and [padding], than the
  /// default theme. Also, this theme uses [ButtonTextTheme.accent] rather than
  /// [ButtonTextTheme.normal].
  ///
  /// For best effect, the label of the button at the edge of the container
  /// should have text that ends up wider than 64.0 pixels. This ensures that
  /// the alignment of the text matches the alignment of the edge of the
  /// container.
  ///
  /// For example, buttons at the bottom of [Dialog] or [Card] widgets use this
  /// button theme.
  const ButtonTheme.bar({
    Key key,
    this.textTheme: ButtonTextTheme.accent,
    this.minWidth: 64.0,
    this.height: 36.0,
    this.padding: const EdgeInsets.symmetric(horizontal: 8.0),
    Widget child
  }) : super(key: key, child: child);

  /// The button color that this subtree should use.
  final ButtonTextTheme textTheme;

  /// The smallest horizontal extent that the button will occupy.
  ///
  /// Defaults to 88.0 logical pixels.
  final double minWidth;

  /// The vertical extent of the button.
  ///
  /// Defaults to 36.0 logical pixels.
  final double height;

  /// The amount of space to surround the child inside the bounds of the button.
  ///
  /// Defaults to 16.0 pixels of horizontal padding.
  final EdgeInsets padding;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ButtonTheme theme = ButtonTheme.of(context);
  /// ```
  static ButtonTheme of(BuildContext context) {
    final ButtonTheme result = context.inheritFromWidgetOfExactType(ButtonTheme);
    return result ?? const ButtonTheme();
  }

  @override
  bool updateShouldNotify(ButtonTheme oldTheme) {
    return textTheme != oldTheme.textTheme
        || padding != oldTheme.padding
        || minWidth != oldTheme.minWidth
        || height != oldTheme.height;
  }
}

/// The framework for building material design buttons.
///
/// Rather than using this class directly, consider using [FlatButton] or
/// [RaisedButton], which configure this class with appropriate defaults that
/// match the material design specification.
///
/// MaterialButtons whose [onPressed] handler is null will be disabled. To have
/// an enabled button, make sure to pass a non-null value for onPressed.
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

  /// The color scheme to use for this button's text.
  ///
  /// Defaults to the button color from [ButtonTheme].
  final ButtonTextTheme textTheme;

  /// The color to use for this button's text.
  final Color textColor;

  /// The primary color of the button, as printed on the [Material], while it
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

  /// The z-coordinate at which to place this button.
  ///
  /// Defaults to 0.
  final double elevation;

  /// The z-coordinate at which to place this button when highlighted.
  ///
  /// Defaults to 0.
  final double highlightElevation;

  /// The smallest horizontal extent that the button will occupy.
  ///
  /// Defaults to the value from the current [ButtonTheme].
  final double minWidth;

  /// The vertical extent of the button.
  ///
  /// Defaults to the value from the current [ButtonTheme].
  final double height;

  /// The amount of space to surround the child inside the bounds of the button.
  ///
  /// Defaults to the value from the current [ButtonTheme].
  final EdgeInsets padding;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  _MaterialButtonState createState() => new _MaterialButtonState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (!enabled)
      description.add('disabled');
  }
}

class _MaterialButtonState extends State<MaterialButton> {
  bool _highlight = false;

  Brightness get _colorBrightness {
    return widget.colorBrightness ?? Theme.of(context).brightness;
  }

  Color get _textColor {
    if (widget.textColor != null)
      return widget.textColor;
    if (widget.enabled) {
      switch (widget.textTheme ?? ButtonTheme.of(context).textTheme) {
        case ButtonTextTheme.accent:
          return Theme.of(context).accentColor;
        case ButtonTextTheme.normal:
          switch (_colorBrightness) {
            case Brightness.light:
              return Colors.black87;
            case Brightness.dark:
              return Colors.white;
          }
      }
    } else {
      assert(_colorBrightness != null);
      switch (_colorBrightness) {
        case Brightness.light:
          return Colors.black26;
        case Brightness.dark:
          return Colors.white30;
      }
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
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
    final Color textColor = _textColor;
    final TextStyle style = theme.textTheme.button.copyWith(color: textColor);
    final ButtonTheme buttonTheme = ButtonTheme.of(context);
    final double height = widget.height ?? buttonTheme.height;
    final double elevation = (_highlight ? widget.highlightElevation : widget.elevation) ?? 0.0;
    final bool hasColorOrElevation = (widget.color != null || elevation > 0);
    Widget contents = IconTheme.merge(
      data: new IconThemeData(
        color: textColor
      ),
      child: new InkWell(
        borderRadius: hasColorOrElevation ? null : kMaterialEdges[MaterialType.button],
        highlightColor: widget.highlightColor ?? theme.highlightColor,
        splashColor: widget.splashColor ?? theme.splashColor,
        onTap: widget.onPressed,
        onHighlightChanged: _handleHighlightChanged,
        child: new Container(
          padding: widget.padding ?? ButtonTheme.of(context).padding,
          child: new Center(
            widthFactor: 1.0,
            child: widget.child
          )
        )
      )
    );
    if (hasColorOrElevation) {
      contents = new Material(
        type: MaterialType.button,
        color: widget.color,
        elevation: elevation,
        textStyle: style,
        child: contents
      );
    } else {
      contents = new AnimatedDefaultTextStyle(
        style: style,
        duration: kThemeChangeDuration,
        child: contents
      );
    }
    return new ConstrainedBox(
      constraints: new BoxConstraints(
        minWidth: widget.minWidth ?? buttonTheme.minWidth,
        minHeight: height,
        maxHeight: height
      ),
      child: contents
    );
  }
}
