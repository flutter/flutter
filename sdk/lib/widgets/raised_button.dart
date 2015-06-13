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

  RaisedButton({ Object key, this.child, this.onPressed, this.theme: RaisedButtonTheme.light }) : super(key: key);

  UINode child;
  int level;
  Function onPressed;
  RaisedButtonTheme theme;

  void syncFields(RaisedButton source) {
    child = source.child;
    level = source.level;
    onPressed = source.onPressed;
    super.syncFields(source);
  }

  UINode buildContent() {
    return new EventListenerNode(
      new Container(
        height: 36.0,
        constraints: new BoxConstraints(minWidth: 88.0),
        margin: new EdgeDims.all(4.0),
        child: new Material(
          edge: MaterialEdge.card,
          child: new InkWell(
            child: new Container(
              padding: new EdgeDims.symmetric(horizontal: 8.0),
              child: new Center(child: child)
            )
          ),
          level: highlight ? 2 : 1,
          color: theme == RaisedButtonTheme.light
                               ? (highlight ? Grey[350] : Grey[300])
                               : (highlight ? Blue[700] : Blue[600])
        )
      ),
      onGestureTap: (_) { if (onPressed != null) onPressed(); }
    );
  }

}
