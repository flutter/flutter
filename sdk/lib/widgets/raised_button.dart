// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../theme2/colors.dart';
import '../theme2/edges.dart';
import 'basic.dart';
import 'button_base.dart';
import 'ink_well.dart';
import 'material.dart';

enum RaisedButtonTheme { light, dark }

class RaisedButton extends ButtonBase {

  RaisedButton({
    Object key,
    this.child,
    this.enabled: true,
    this.onPressed,
    this.theme: RaisedButtonTheme.light
  }) : super(key: key);

  UINode child;
  bool enabled;
  Function onPressed;
  RaisedButtonTheme theme;

  void syncFields(RaisedButton source) {
    child = source.child;
    enabled = source.enabled;
    onPressed = source.onPressed;
    theme = source.theme;
    super.syncFields(source);
  }

  UINode buildContent() {
    UINode contents = new Container(
      padding: new EdgeDims.symmetric(horizontal: 8.0),
      child: new Center(child: child) // TODO(ianh): figure out a way to compell the child to have gray text when disabled...
    );
    Color color;
    if (enabled) {
      switch (theme) {
        case RaisedButtonTheme.light:
          if (highlight)
            color = Grey[350];
          else
            color = Grey[300];
          break;
        case RaisedButtonTheme.dark:
          if (highlight)
            color = Blue[700];
          else
            color = Blue[600];
          break;
      }
    } else {
      color = Grey[350];
    }
    return new EventListenerNode(
      new Container(
        height: 36.0,
        constraints: new BoxConstraints(minWidth: 88.0),
        margin: new EdgeDims.all(4.0),
        child: new Material(
          edge: MaterialEdge.card,
          child: enabled ? new InkWell(child: contents) : contents,
          level: enabled ? (highlight ? 2 : 1) : 0,
          color: color
        )
      ),
      onGestureTap: (_) { if (onPressed != null && enabled) onPressed(); }
    );
  }

}
