// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'flat_button.dart';
import 'icon_theme_data.dart';
import 'icon_theme.dart';
import 'ink_well.dart';
import 'material.dart';
import 'raised_button.dart';
import 'theme.dart';

/// Whether a button should use the accent color for its text.
///
/// See also:
///
///  * [ButtonTheme]
///  * [RaisedButton]
///  * [FlatButton]
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
///  * [ButtonTextTheme]
///  * [RaisedButton]
///  * [FlatButton]
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

  const ButtonTheme.footer({
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

  /// The color from the closest instance of this class that encloses the given context.
  static ButtonTheme of(BuildContext context) {
    ButtonTheme result = context.inheritFromWidgetOfExactType(ButtonTheme);
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

/// A material design button.
///
/// Rather than using this class directly, consider using [FlatButton] or [RaisedButton].
///
/// MaterialButtons whose [onPressed] handler is null will be disabled. To have
/// an enabled button, make sure to pass a non-null value for onPressed.
class MaterialButton extends StatefulWidget {
  /// Creates a material button.
  ///
  /// Rather than creating a material button directly, consider using
  /// [FlatButton] or [RaisedButton].
  MaterialButton({
    Key key,
    this.colorBrightness,
    this.textTheme,
    this.textColor,
    this.color,
    this.elevation,
    this.highlightElevation,
    this.minWidth,
    this.height,
    this.padding,
    this.onPressed,
    this.child
  }) : super(key: key);

  /// The theme brightness to use for this button.
  ///
  /// Defaults to the brightness from [ThemeData.brightness].
  final ThemeBrightness colorBrightness;

  /// The color scheme to use for this button's text.
  ///
  /// Defaults to the button color from [ButtonTheme].
  final ButtonTextTheme textTheme;

  /// The color to use for this button's text.
  final Color textColor;

  /// The color of the button, as printed on the [Material].
  final Color color;

  /// The z-coordinate at which to place this button.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int elevation;

  /// The z-coordinate at which to place this button when highlighted.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int highlightElevation;

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

  /// The callback that is invoked when the button is tapped or otherwise activated.
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

  ThemeBrightness get _colorBrightness {
    return config.colorBrightness ?? Theme.of(context).brightness;
  }

  Color get _textColor {
    if (config.textColor != null)
      return config.textColor;
    if (config.enabled) {
      switch (config.textTheme ?? ButtonTheme.of(context).textTheme) {
        case ButtonTextTheme.accent:
          return Theme.of(context).accentColor;
        case ButtonTextTheme.normal:
          switch (_colorBrightness) {
            case ThemeBrightness.light:
              return Colors.black87;
            case ThemeBrightness.dark:
              return Colors.white;
          }
      }
    } else {
      switch (_colorBrightness) {
        case ThemeBrightness.light:
          return Colors.black26;
        case ThemeBrightness.dark:
          return Colors.white30;
      }
    }
  }

  void _handleHighlightChanged(bool value) {
    setState(() {
      _highlight = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final Color textColor = _textColor;
    final TextStyle style = Theme.of(context).textTheme.button.copyWith(color: textColor);
    final ButtonTheme buttonTheme = ButtonTheme.of(context);
    final double height = config.height ?? buttonTheme.height;
    final int elevation = (_highlight ? config.highlightElevation : config.elevation) ?? 0;
    Widget contents = new IconTheme(
      data: new IconThemeData(
        color: textColor
      ),
      child: new InkWell(
        onTap: config.onPressed,
        onHighlightChanged: _handleHighlightChanged,
        child: new Container(
          padding: config.padding ?? ButtonTheme.of(context).padding,
          child: new Center(
            widthFactor: 1.0,
            child: config.child
          )
        )
      )
    );
    if (elevation > 0 || config.color != null) {
      contents = new Material(
        type: MaterialType.button,
        color: config.color,
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
        minWidth: config.minWidth ?? buttonTheme.minWidth,
        minHeight: height,
        maxHeight: height
      ),
      child: contents
    );
  }
}
