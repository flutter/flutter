// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

enum ButtonColor { normal, accent }

class ButtonTheme extends InheritedWidget {
  ButtonTheme({
    Key key,
    this.color,
    Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
  }

  final ButtonColor color;

  static ButtonColor of(BuildContext context) {
    ButtonTheme result = context.inheritFromWidgetOfType(ButtonTheme);
    return result?.color ?? ButtonColor.normal;
  }

  bool updateShouldNotify(ButtonTheme old) => color != old.color;
}

/// Base class for buttons in the Material theme.
/// Rather than using this class directly, please use FlatButton or RaisedButton.
abstract class MaterialButton extends StatefulComponent {
  MaterialButton({
    Key key,
    this.child,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.onPressed
  }) : super(key: key);

  final Widget child;
  final ButtonColor textTheme;
  final Color textColor;
  final Color disabledTextColor;
  final VoidCallback onPressed;

  bool get enabled => onPressed != null;

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (!enabled)
      description.add('disabled');
  }
}

abstract class MaterialButtonState<T extends MaterialButton> extends State<T> {
  bool highlight = false;

  int get elevation;
  Color getColor(BuildContext context);
  ThemeBrightness getColorBrightness(BuildContext context);

  Color getTextColor(BuildContext context) {
    if (config.enabled) {
      if (config.textColor != null)
        return config.textColor;
      switch (config.textTheme ?? ButtonTheme.of(context)) {
        case ButtonColor.accent:
          return Theme.of(context).accentColor;
        case ButtonColor.normal:
          switch (getColorBrightness(context)) {
            case ThemeBrightness.light:
              return Colors.black87;
            case ThemeBrightness.dark:
              return Colors.white;
          }
      }
    }
    if (config.disabledTextColor != null)
      return config.disabledTextColor;
    switch (getColorBrightness(context)) {
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

  Widget build(BuildContext context) {
    Widget contents = new InkWell(
      onTap: config.onPressed,
      onHighlightChanged: _handleHighlightChanged,
      child: new Container(
        padding: new EdgeDims.symmetric(horizontal: 8.0),
        child: new Center(
          widthFactor: 1.0,
          child: config.child
        )
      )
    );
    TextStyle style = Theme.of(context).text.button.copyWith(color: getTextColor(context));
    int elevation = this.elevation;
    Color color = getColor(context);
    if (elevation > 0 || color != null) {
      contents = new Material(
        type: MaterialType.button,
        color: getColor(context),
        elevation: elevation,
        textStyle: style,
        child: contents
      );
    } else {
      contents = new DefaultTextStyle(
        style: style,
        child: contents
      );
    }
    return new Container(
      height: 36.0,
      constraints: new BoxConstraints(minWidth: 88.0),
      margin: new EdgeDims.all(8.0),
      child: contents
    );
  }
}
