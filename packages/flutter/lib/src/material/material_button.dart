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
    this.textColor,
    this.onPressed
  }) : super(key: key);

  final Widget child;
  final ButtonColor textColor;
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
  Color getColor(BuildContext context, { bool highlight });
  ThemeBrightness getColorBrightness(BuildContext context);

  Color getTextColor(BuildContext context) {
    if (config.enabled) {
      switch (config.textColor ?? ButtonTheme.of(context)) {
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
    switch (getColorBrightness(context)) {
      case ThemeBrightness.light:
        return Colors.black26;
      case ThemeBrightness.dark:
        return Colors.white30;
    }
  }

  void _handleHighlightChanged(bool value) {
    setState(() {
      highlight = value;
    });
  }

  Widget build(BuildContext context) {
    Widget contents = new Container(
      padding: new EdgeDims.symmetric(horizontal: 8.0),
      child: new Center(
        widthFactor: 1.0,
        child: config.child
      )
    );
    return new Container(
      height: 36.0,
      constraints: new BoxConstraints(minWidth: 88.0),
      margin: new EdgeDims.all(8.0),
      child: new Material(
        type: MaterialType.button,
        elevation: elevation,
        textStyle: Theme.of(context).text.button.copyWith(color: getTextColor(context)),
        child: new InkWell(
          onTap: config.enabled ? config.onPressed : null,
          defaultColor: getColor(context, highlight: false),
          highlightColor: getColor(context, highlight: true),
          onHighlightChanged: _handleHighlightChanged,
          child: contents
        )
      )
    );
  }
}
