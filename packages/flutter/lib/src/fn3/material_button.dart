// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/button_state.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/gesture_detector.dart';
import 'package:sky/src/fn3/ink_well.dart';
import 'package:sky/src/fn3/material.dart';

// Rather than using this class directly, please use FlatButton or RaisedButton.
abstract class MaterialButton extends StatefulComponent {
  MaterialButton({
    Key key,
    this.child,
    this.enabled: true,
    this.onPressed
  }) : super(key: key) {
    assert(enabled != null);
  }

  final Widget child;
  final bool enabled;
  final Function onPressed;
}

abstract class MaterialButtonState<T extends MaterialButton> extends ButtonState<T> {
  MaterialButtonState(T config) : super(config);

  Color getColor(BuildContext context);
  int get level;

  Widget buildContent(BuildContext context) {
    Widget contents = new Container(
      padding: new EdgeDims.symmetric(horizontal: 8.0),
      child: new Center(
        shrinkWrap: ShrinkWrap.width,
        child: config.child // TODO(ianh): figure out a way to compell the child to have gray text when disabled...
      )
    );
    return new GestureDetector(
      onTap: config.enabled ? config.onPressed : null,
      child: new Container(
        height: 36.0,
        constraints: new BoxConstraints(minWidth: 88.0),
        margin: new EdgeDims.all(8.0),
        child: new Material(
          type: MaterialType.button,
          child: config.enabled ? new InkWell(child: contents) : contents,
          level: level,
          color: getColor(context)
        )
      )
    );
  }
}
