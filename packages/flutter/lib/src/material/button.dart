// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'icon_theme_data.dart';
import 'icon_theme.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

/// Whether a button should use the accent color for its text.
///
/// See also:
///
///  * [ButtonTheme]
///  * [RaisedButton]
///  * [FlatButton]
enum ButtonColor {
  /// The button should use the normal color (e.g., black or white depending on the [ThemeData.brightness]) for its text.
  normal,

  /// The button should use the accent color (e.g., [ThemeData.accentColor]) for its text.
  accent,
}

/// Defines the button color used by a widget subtree.
///
/// See also:
///
///  * [ButtonColor]
///  * [RaisedButton]
///  * [FlatButton]
class ButtonTheme extends InheritedWidget {
  ButtonTheme({
    Key key,
    this.color,
    Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
  }

  /// The button color that this subtree should use.
  final ButtonColor color;

  /// The color from the closest instance of this class that encloses the given context.
  ///
  /// Defaults to [ButtonColor.normal] if none exists.
  static ButtonColor of(BuildContext context) {
    ButtonTheme result = context.inheritFromWidgetOfExactType(ButtonTheme);
    return result?.color ?? ButtonColor.normal;
  }

  @override
  bool updateShouldNotify(ButtonTheme old) => color != old.color;
}

/// Base class for material design buttons.
///
/// Rather than using this class directly, please use [FlatButton] or [RaisedButton].
///
/// MaterialButtons whose [onPressed] handler is null will be disabled. To have
/// an enabled button, make sure to pass a non-null value for onPressed.
abstract class MaterialButton extends StatefulWidget {
  MaterialButton({
    Key key,
    this.child,
    this.colorBrightness,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.onPressed
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The theme brightness to use for this button.
  ///
  /// Defaults to the brightness from [ThemeData.brightness].
  final ThemeBrightness colorBrightness;

  /// The color scheme to use for this button's text.
  ///
  /// Defaults to the button color from [ButtonTheme].
  final ButtonColor textTheme;

  /// The color to use for this button's text.
  ///
  /// Defaults to the color determined by the [textTheme].
  final Color textColor;

  /// The color to use for this button's text when the button cannot be pressed.
  ///
  /// Defaults to a color derived from the [Theme].
  final Color disabledTextColor;

  /// The callback that is invoked when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (!enabled)
      description.add('disabled');
  }
}

/// A state object for [MaterialButton].
///
/// Subclasses of [MaterialButton] should use a subclass of
/// [MaterialButtonState] for their state objects.
abstract class MaterialButtonState<T extends MaterialButton> extends State<T> {
  /// Whether this button is in the process of potentially being pressed.
  bool highlight = false;

  /// The z-coordinate at which to place this button.
  int get elevation;

  /// The color to use for the button's material.
  Color getColor(BuildContext context);

  ThemeBrightness _getColorBrightness(BuildContext context) {
    return config.colorBrightness ?? Theme.of(context).brightness;
  }

  Color _getTextColor(BuildContext context) {
    if (config.enabled) {
      if (config.textColor != null)
        return config.textColor;
      switch (config.textTheme ?? ButtonTheme.of(context)) {
        case ButtonColor.accent:
          return Theme.of(context).accentColor;
        case ButtonColor.normal:
          switch (_getColorBrightness(context)) {
            case ThemeBrightness.light:
              return Colors.black87;
            case ThemeBrightness.dark:
              return Colors.white;
          }
      }
    }
    if (config.disabledTextColor != null)
      return config.disabledTextColor;
    switch (_getColorBrightness(context)) {
      case ThemeBrightness.light:
        return Colors.black26;
      case ThemeBrightness.dark:
        return Colors.white30;
    }
  }

  void _handleHighlightChanged(bool value) {
    setState(() {
      // mostly just used by the RaisedButton subclass to change the elevation
      highlight = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final Color textColor = _getTextColor(context);
    Widget contents = new IconTheme(
      data: new IconThemeData(
        color: textColor
      ),
      child: new InkWell(
        onTap: config.onPressed,
        onHighlightChanged: _handleHighlightChanged,
        child: new Container(
          padding: new EdgeInsets.symmetric(horizontal: 8.0),
          child: new Center(
            widthFactor: 1.0,
            child: config.child
          )
        )
      )
    );
    final TextStyle style = Theme.of(context).textTheme.button.copyWith(color: textColor);
    final int elevation = this.elevation;
    final Color color = getColor(context);
    if (elevation > 0 || color != null) {
      contents = new Material(
        type: MaterialType.button,
        color: color,
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
    return new Container(
      height: 36.0,
      constraints: new BoxConstraints(minWidth: 88.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      margin: const EdgeInsets.all(8.0),
      child: contents
    );
  }
}
