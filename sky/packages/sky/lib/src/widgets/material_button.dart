// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/gestures.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/button_state.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/ink_well.dart';
import 'package:sky/src/widgets/material.dart';

/// Rather than using this class directly, please use FlatButton or RaisedButton.
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
  final GestureTapCallback onPressed;
}

abstract class MaterialButtonState<T extends MaterialButton> extends ButtonState<T> {
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
    return new Container(
      height: 36.0,
      constraints: new BoxConstraints(minWidth: 88.0),
      margin: new EdgeDims.all(8.0),
      child: new Material(
        type: MaterialType.button,
        level: level,
        color: getColor(context),
        child: new InkWell(
          onTap: config.enabled ? config.onPressed : null,
          child: contents
        )
      )
    );
  }
}
