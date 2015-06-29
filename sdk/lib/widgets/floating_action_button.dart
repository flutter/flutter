// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'button_base.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

// TODO(eseidel): This needs to change based on device size?
// http://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double _kSize = 56.0;

class FloatingActionButton extends ButtonBase {

  FloatingActionButton({
    String key,
    this.child,
    Function onPressed
  }) : super(key: key);

  Widget child;
  Function onPressed;

  void syncFields(FloatingActionButton source) {
    super.syncFields(source);
    child = source.child;
    onPressed = source.onPressed;
  }

  Widget buildContent() {
    return new Material(
      color: Theme.of(this).accent[200],
      edge: MaterialEdge.circle,
      level: highlight ? 3 : 2,
      child: new ClipOval(
        child: new Listener(
          onGestureTap: (_) {
            if (onPressed != null)
              onPressed();
          },
          child: new Container(
            width: _kSize,
            height: _kSize,
            child: new InkWell(child: new Center(child: child))
          )
        )
      )
    );
  }

}
